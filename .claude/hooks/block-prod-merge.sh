#!/usr/bin/env bash
# Blocks merges and pushes to the protected branch, which need human review.
#
# Runs as a PreToolUse hook on Bash. Exit 0 allows the command, exit 2 blocks it
# and shows stderr to Claude.
#
# Matching is done on the command itself, and only where a segment *begins* with
# git or gh. Text that merely mentions these words, for example inside an echo, a
# here-document or a pull request body, is not a command and is not blocked.

set -uo pipefail

PROTECTED="main"

payload="$(cat)"

# Read the command rather than the whole payload. Matching raw JSON also matches
# unrelated fields, and because the payload is a single line, a pattern spanning
# ".*" reaches across the entire body.
command="$(printf '%s' "$payload" |
  python3 -c 'import json,sys
try: print(json.load(sys.stdin).get("tool_input", {}).get("command", ""))
except Exception: pass' 2>/dev/null)"

if [ -z "$command" ]; then
  # Could not parse, for example if python3 is missing. Fall back to the older,
  # broader match rather than allowing the command through unchecked. This is
  # imprecise and may block text that only mentions these words, which is the
  # right way round to fail for a guard rail.
  if printf '%s' "$payload" | grep -Eq "git +(push|merge).*${PROTECTED}|gh +pr +merge"; then
    echo "Blocked: this looks like a merge or push to ${PROTECTED}." >&2
    echo "The command could not be parsed, so the broader check was used and may" >&2
    echo "have matched text rather than a command. Run it yourself if so." >&2
    exit 2
  fi
  exit 0
fi

reason=""

# Split on shell separators so words in one segment cannot leak into another.
while IFS= read -r segment; do
  # Strip leading whitespace.
  segment="${segment#"${segment%%[![:space:]]*}"}"

  # Only a segment that STARTS with git or gh is a command being run. This is
  # the whole fix: `echo "... git push ... main"` starts with echo, so it is
  # text and is left alone.
  case "$segment" in
    git[[:space:]]* | gh[[:space:]]*) ;;
    *) continue ;;
  esac

  # Two checks rather than one clever pattern: is this a push or a merge, and
  # does it name the protected branch as a whole word? Combining them into a
  # single regex silently failed on "git merge main", where the separator after
  # the verb is the same space that has to precede the branch name.
  if printf '%s' "$segment" | grep -Eq "^git[[:space:]]+(push|merge)([[:space:]]|$)" &&
    printf '%s' "$segment" | grep -Eq "(^|[^A-Za-z0-9_.-])${PROTECTED}([^A-Za-z0-9_.-]|$)"; then
    reason="a git command targeting ${PROTECTED}"
    break
  fi

  if printf '%s' "$segment" | grep -Eq "^gh[[:space:]]+pr[[:space:]]+merge([[:space:]]|$)"; then
    reason="a pull request merge"
    break
  fi
# The trailing newline matters: `read` does not process a final line that has
# none, so a single-segment command would be skipped entirely.
done < <(printf '%s\n' "$command" | tr ';&|\n' '\n')

if [ -n "$reason" ]; then
  echo "Blocked: ${reason}." >&2
  echo "Merges and pushes to ${PROTECTED} need human review in this workshop." >&2
  echo "Open a pull request instead, or run the command yourself to bypass this." >&2
  exit 2
fi

exit 0
