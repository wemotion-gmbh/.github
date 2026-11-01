#!/usr/bin/env bash
# Creates or updates the labels from labels.json in every active, non-archived
# repository of the organization. Safe to run again; existing labels with
# other names are left alone. Tasks are grouped with GitHub Projects, not labels.
#
# The retired labels are not in labels.json, so a sync never creates them and
# leaves existing ones alone. With --delete-retired it deletes them instead (only
# after T2 of the PR rules). A retired label that an open PR still carries is kept
# and reported, so a stop set only as a label never disappears silently; the run
# then exits with 1.
#
# Usage: scripts/sync-labels.sh [--delete-retired] [repo ...]   (default: all repos pushed in the last 90 days)
set -euo pipefail
ORG="${ORG:-wemotion-gmbh}"
here="$(cd "$(dirname "$0")/.." && pwd)"
labels="$here/labels.json"
retired=("✅ Bereit zum Review" "🚧 Überarbeiten" "⛔ Nicht mergen")

mode=sync
if [ "${1:-}" = "--delete-retired" ]; then
  mode=delete
  shift
fi

if [ "$#" -gt 0 ]; then
  repos="$*"
else
  since="$(date -u -v-90d +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date -u -d '90 days ago' +%Y-%m-%dT%H:%M:%SZ)"
  repos="$(gh repo list "$ORG" --limit 500 --json name,pushedAt,isArchived \
    -q ".[] | select(.isArchived | not) | select(.pushedAt > \"$since\") | .name")"
fi

kept=0
for repo in $repos; do
  if [ "$mode" = delete ]; then
    existing="$(gh label list -R "$ORG/$repo" --limit 500 --json name -q '.[].name')"
    for name in "${retired[@]}"; do
      if grep -Fxq -- "$name" <<<"$existing"; then
        open="$(gh pr list -R "$ORG/$repo" --label "$name" --state open --limit 500 --json number -q '.[].number' | tr '\n' ' ')"
        if [ -n "$open" ]; then
          echo "label kept: $repo $name (open PRs: $open)"
          kept=1
          continue
        fi
        gh label delete "$name" -R "$ORG/$repo" --yes >/dev/null
        echo "label deleted: $repo $name"
      fi
    done
    continue
  fi
  jq -c '.[]' "$labels" | while read -r l; do
    gh label create "$(jq -r .name <<<"$l")" -R "$ORG/$repo" --force \
      --color "$(jq -r .color <<<"$l")" --description "$(jq -r .description <<<"$l")" >/dev/null
  done
  echo "labels synced: $repo"
done
exit "$kept"
