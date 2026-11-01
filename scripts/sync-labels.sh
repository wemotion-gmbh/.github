#!/usr/bin/env bash
# Creates or updates the labels from labels.json in every active, non-archived
# repository of the organization. Safe to run again; existing labels with
# other names are left alone. Tasks are grouped with GitHub Projects, not labels.
#
# The retired labels are not in labels.json, so a sync never creates them and
# leaves existing ones alone. With --delete-retired it deletes them instead, in
# every non-archived repository. That run belongs after T2 of the PR rules and
# needs T2_PASSED=yes; without it the script stops with exit 2 before touching
# anything. A retired stop label that an open PR still carries is kept and
# reported, so a stop set only as a label never disappears silently; the run then
# exits with 3. Any exit code other than 0 and 3 means the run was aborted, for
# example because gh is not logged in or reported an error.
#
# Usage: scripts/sync-labels.sh [repo ...]                                (default: all repos pushed in the last 90 days)
#        T2_PASSED=yes scripts/sync-labels.sh --delete-retired [repo ...]  (default: all non-archived repos)
# Needs gh, and node for the sync.
set -euo pipefail
ORG="${ORG:-wemotion-gmbh}"
here="$(cd "$(dirname "$0")/.." && pwd)"
labels="$here/labels.json"
retired=("✅ Bereit zum Review" "🚧 Überarbeiten" "⛔ Nicht mergen")
# Retired labels that stop a merge; the ready label stops nothing and is always deleted.
stops=("🚧 Überarbeiten" "⛔ Nicht mergen")

mode=sync
if [ "${1:-}" = "--delete-retired" ]; then
  if [ "${T2_PASSED:-}" != yes ]; then
    echo "--delete-retired runs only after T2 of the PR rules; confirm with T2_PASSED=yes" >&2
    exit 2
  fi
  mode=delete
  shift
fi

if [ "$#" -gt 0 ]; then
  repos="$*"
elif [ "$mode" = delete ]; then
  # Repositories without recent pushes can still carry a retired label.
  repos="$(gh repo list "$ORG" --limit 500 --no-archived --json name -q '.[].name')"
else
  since="$(date -u -v-90d +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date -u -d '90 days ago' +%Y-%m-%dT%H:%M:%SZ)"
  repos="$(gh repo list "$ORG" --limit 500 --json name,pushedAt,isArchived \
    -q ".[] | select(.isArchived | not) | select(.pushedAt > \"$since\") | .name")"
fi

if [ "$mode" = sync ]; then
  # One label per line as name, color and description, separated by tabs; node instead of jq, which is often missing.
  rows="$(node -e 'for (const l of JSON.parse(require("fs").readFileSync(0, "utf8"))) console.log([l.name, l.color, l.description].join("\t"))' <"$labels")"
fi

kept=0
for repo in $repos; do
  if [ "$mode" = delete ]; then
    existing="$(gh label list -R "$ORG/$repo" --limit 500 --json name -q '.[].name')"
    for name in "${retired[@]}"; do
      if grep -Fxq -- "$name" <<<"$existing"; then
        open=""
        stop=no
        for s in "${stops[@]}"; do
          if [ "$s" = "$name" ]; then stop=yes; fi
        done
        if [ "$stop" = yes ]; then
          # Filter the open PRs here instead of with --label, which goes through the search index and can lag behind.
          open="$(gh pr list -R "$ORG/$repo" --state open --limit 500 --json number,labels \
            -q "[.[] | select(any(.labels[]; .name == \"$name\")) | .number | tostring] | join(\" \")")"
        fi
        if [ -n "$open" ]; then
          echo "label kept: $repo $name (open PRs: $open)"
          kept=3
          continue
        fi
        gh label delete "$name" -R "$ORG/$repo" --yes >/dev/null
        echo "label deleted: $repo $name"
      fi
    done
    continue
  fi
  while IFS=$'\t' read -r name color description; do
    gh label create "$name" -R "$ORG/$repo" --force --color "$color" --description "$description" >/dev/null
  done <<<"$rows"
  echo "labels synced: $repo"
done
exit "$kept"
