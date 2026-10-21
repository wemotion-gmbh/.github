# Organization defaults

This repository holds the defaults for all repositories of the organization.
It has to be public for GitHub to apply them; it contains no code and no secrets.

- `pull_request_template.md`: the pull request template for every repository
  that has no template of its own.
- `labels.json` and `scripts/sync-labels.sh`: the shared pull request labels.

## Pull request labels

Every pull request gets exactly one `kind/*` label:

| Label | Meaning | In the review filter |
|---|---|---|
| `kind/feature` | a finished change, ready for review | shown |
| `kind/release` | beta to live, or a hotfix for live | shown |
| `kind/part` | one step of a larger task | hidden |
| `kind/fallback` | a prepared revert, merge only in an emergency | hidden |
| `kind/chore` | maintenance or automation | hidden |

`task/<name>` groups the pull requests of one task across repositories.
`ai` marks a pull request written by an AI agent.

A pull request without a `kind/*` label stays visible in the review filter.

## Review filter

All open pull requests that need a human, across the organization (drafts hidden):

https://github.com/pulls?q=is%3Apr+is%3Aopen+draft%3Afalse+org%3Awemotion-gmbh+-label%3Akind%2Fpart+-label%3Akind%2Ffallback+-label%3Akind%2Fchore

One task across all repositories: the same link with `label:task/<name>`:

https://github.com/pulls?q=is%3Apr+org%3Awemotion-gmbh+label%3Atask%2F<name>

## For agents

Open a pull request with its labels set from the start, for example:

```
gh label create "task/<task>" -R <org>/<repo> --color 1d76db 2>/dev/null || true
gh pr create ... --label kind/part --label task/<task> --label ai
```
