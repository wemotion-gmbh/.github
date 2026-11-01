#!/usr/bin/env bash
# Runs scripts/sync-labels.sh against a stub gh that answers from files and logs
# every call, so nothing reaches GitHub. Exits with 1 if a check fails.
#
# Usage: scripts/test/sync-labels-test.sh [script]   (default: scripts/sync-labels.sh)
set -u
here="$(cd "$(dirname "$0")/../.." && pwd)"
script="${1:-$here/scripts/sync-labels.sh}"
stub="$(mktemp -d)"
trap 'rm -rf "$stub"' EXIT
mkdir -p "$stub/bin"
cat >"$stub/bin/gh" <<'EOF'
#!/usr/bin/env bash
# Answers from the files in $STUB: recent and old list the repositories,
# labels-<repo> the labels of a repository, prs-<repo> the open PRs per label as
# "<label>=<numbers>". The file fail makes the PR query fail.
printf '%s\n' "$*" >>"$STUB/calls"
case "$1 $2" in
  "repo list")
    case "$*" in
      *pushedAt*) cat "$STUB/recent" ;;
      *--no-archived*) cat "$STUB/recent" "$STUB/old" ;;
      *) exit 9 ;;
    esac ;;
  "label list") cat "$STUB/labels-${4#*/}" ;;
  "pr list")
    if [ -e "$STUB/fail" ]; then echo "HTTP 403" >&2; exit 1; fi
    while IFS='=' read -r label numbers; do
      case "$*" in *"\"$label\""*) echo "$numbers" ;; esac
    done <"$STUB/prs-${4#*/}" ;;
  "label delete") echo "${5#*/} $3" >>"$STUB/deleted" ;;
  "label create") ;;
  *) exit 9 ;;
esac
EOF
chmod +x "$stub/bin/gh"
export STUB="$stub"
failed=0

# Starts a case: alpha was pushed recently, oldie not; no labels, no open PRs, no T2_PASSED.
start() {
  case="$1"
  t2=""
  rm -f "$stub"/labels-* "$stub"/prs-* "$stub/fail"
  printf 'alpha\n' >"$stub/recent"
  printf 'oldie\n' >"$stub/old"
  for r in alpha oldie; do : >"$stub/labels-$r"; : >"$stub/prs-$r"; done
  : >"$stub/calls"
  : >"$stub/deleted"
}

# Runs the script with the stub first on PATH; sets out and code.
run() {
  out="$(PATH="$stub/bin:$PATH" ORG=x T2_PASSED="$t2" bash "$script" "$@" 2>&1)"
  code=$?
}

# expect <what> <command ...>: the check passes if the command succeeds.
expect() {
  local what="$1"
  shift
  if "$@"; then
    echo "ok   $case: $what"
  else
    echo "FAIL $case: $what (exit $code, output: $out)"
    failed=1
  fi
}

deleted() { grep -Fxq -- "$1" "$stub/deleted"; }
not() { ! "$@"; }

start "delete without T2_PASSED"
run --delete-retired alpha
expect "exit 2" [ "$code" = 2 ]
expect "no gh call" [ ! -s "$stub/calls" ]
expect "names T2_PASSED" grep -q T2_PASSED <<<"$out"

start "stop label on an open PR"
printf '%s\n' "✅ Bereit zum Review" "🚧 Überarbeiten" "⛔ Nicht mergen" "🔧 Wartung" >"$stub/labels-alpha"
echo "⛔ Nicht mergen=12 15" >"$stub/prs-alpha"
t2=yes
run --delete-retired alpha
expect "exit 3" [ "$code" = 3 ]
expect "ready label deleted" deleted "alpha ✅ Bereit zum Review"
expect "unused stop label deleted" deleted "alpha 🚧 Überarbeiten"
expect "used stop label kept" not deleted "alpha ⛔ Nicht mergen"
expect "kept label reported" grep -Fxq "label kept: alpha ⛔ Nicht mergen (open PRs: 12 15)" <<<"$out"
expect "other labels untouched" not deleted "alpha 🔧 Wartung"

start "PR query fails"
printf '%s\n' "✅ Bereit zum Review" "🚧 Überarbeiten" "⛔ Nicht mergen" >"$stub/labels-alpha"
touch "$stub/fail"
t2=yes
run --delete-retired alpha
expect "exit neither 0 nor 3" [ "$code" != 0 -a "$code" != 3 ]
expect "stop labels kept" not grep -q -e "🚧" -e "⛔" "$stub/deleted"

start "second run after the PRs dropped the label"
printf '%s\n' "⛔ Nicht mergen" "🔧 Wartung" >"$stub/labels-alpha"
t2=yes
run --delete-retired alpha
expect "exit 0" [ "$code" = 0 ]
expect "rest deleted" deleted "alpha ⛔ Nicht mergen"

start "delete without repo names"
printf '%s\n' "🚧 Überarbeiten" >"$stub/labels-oldie"
t2=yes
run --delete-retired
expect "exit 0" [ "$code" = 0 ]
expect "repo without recent pushes covered" deleted "oldie 🚧 Überarbeiten"

start "sync without repo names"
run
expect "exit 0" [ "$code" = 0 ]
expect "six labels created" [ "$(grep -c '^label create .* -R x/alpha --force ' "$stub/calls")" = 6 ]
expect "repo without recent pushes left alone" not grep -q "x/oldie" "$stub/calls"
expect "no retired label created" not grep -q -e "^label create ✅" -e "^label create 🚧" -e "^label create ⛔" "$stub/calls"
expect "name, color and description passed" grep -Fxq "label create 🔑 Marcs Ja fehlt -R x/alpha --force --color b60205 --description Eine Migration löscht Daten – wartet auf Marcs Ja im Cockpit" "$stub/calls"
expect "reported" grep -Fxq "labels synced: alpha" <<<"$out"

exit "$failed"
