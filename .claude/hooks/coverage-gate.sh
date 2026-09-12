#!/usr/bin/env bash
# Blocks a push when test coverage is under the threshold in vitest.config.ts.
#
# Runs as a PreToolUse hook on Bash. Anything that is not a push passes straight
# through untouched, so this costs nothing on ordinary commands.
#
# Exit 0 allows the command. Exit 2 blocks it and shows stderr to Claude.

set -uo pipefail

payload="$(cat)"

# Read the command itself rather than grepping the whole payload. Matching raw
# JSON also matches a command that merely *mentions* pushing, for example one
# writing these words into a file, and gates something that is not a push.
command="$(printf '%s' "$payload" |
  python3 -c 'import json,sys
try: print(json.load(sys.stdin).get("tool_input", {}).get("command", ""))
except Exception: pass' 2>/dev/null)"

# If the payload could not be parsed, fall back to the whole thing. Better to
# run the check unnecessarily than to let a push past unchecked.
[ -n "$command" ] || command="$payload"

# Only a push is gated. Everything else, including pulls and fetches, passes.
printf '%s' "$command" | grep -Eq '(^|[;&|[:space:]])git[[:space:]]+push' || exit 0

cd "${CLAUDE_PROJECT_DIR:-.}" 2>/dev/null || exit 0

# Nothing to enforce if the project has no coverage script. Fail open rather
# than blocking every push in a repo that never opted in.
node -e 'process.exit(require("./package.json").scripts?.["test:coverage"] ? 0 : 1)' 2>/dev/null || exit 0

if output="$(npm run test:coverage 2>&1)"; then
  exit 0
fi

# Distinguish a coverage shortfall from a plain test failure. Both should stop a
# push, but telling someone "coverage is low" when a test is red wastes their time.
if printf '%s' "$output" | grep -q "ERROR: Coverage"; then
  echo "Blocked: test coverage is below the agreed floor." >&2
  printf '%s\n' "$output" | grep "ERROR: Coverage" >&2
  echo "" >&2
  echo "Raise coverage, or if the drop is deliberate agree a new floor in vitest.config.ts" >&2
  echo "and say why in the pull request. See docs/coverage.md." >&2
else
  echo "Blocked: 'npm run test:coverage' failed, so coverage could not be checked." >&2
  printf '%s\n' "$output" | tail -15 >&2
fi

exit 2
