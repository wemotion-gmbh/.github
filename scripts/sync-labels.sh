#!/usr/bin/env bash
# Creates or updates the labels from labels.json in every active, non-archived
# repository of the organization. Safe to run again; existing labels with
# other names are left alone. Task labels ("📁 <task>") are created on demand
# by whoever opens the first PR of a task: gh label create "📁 <task>" --color 1d76db.
#
# Usage: scripts/sync-labels.sh [repo ...]   (default: all repos pushed in the last 90 days)
set -euo pipefail
ORG="${ORG:-wemotion-gmbh}"
here="$(cd "$(dirname "$0")/.." && pwd)"
labels="$here/labels.json"

if [ "$#" -gt 0 ]; then
  repos="$*"
else
  since="$(date -u -v-90d +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date -u -d '90 days ago' +%Y-%m-%dT%H:%M:%SZ)"
  repos="$(gh repo list "$ORG" --limit 500 --json name,pushedAt,isArchived \
    -q ".[] | select(.isArchived | not) | select(.pushedAt > \"$since\") | .name")"
fi

for repo in $repos; do
  jq -c '.[]' "$labels" | while read -r l; do
    gh label create "$(jq -r .name <<<"$l")" -R "$ORG/$repo" --force \
      --color "$(jq -r .color <<<"$l")" --description "$(jq -r .description <<<"$l")" >/dev/null
  done
  echo "labels synced: $repo"
done
