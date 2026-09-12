#!/usr/bin/env bash
# Checks that the PreToolUse hooks block what they should and, just as
# importantly, allow what they should.
#
# Run from the project root:  .claude/hooks/test-hooks.sh
#
# Both hooks in this directory have shipped with a matching bug at some point.
# The dangerous failure is not a missed block, it is a hook that blocks ordinary
# work, because that is the one people switch off.

set -uo pipefail

cd "$(dirname "$0")/../.." || exit 1
export CLAUDE_PROJECT_DIR="$PWD"

pass=0
fail=0

# check <hook> <expected: block|allow> <description> <command>
check() {
  local hook="$1" expect="$2" desc="$3" cmd="$4"
  local payload rc
  payload="$(python3 -c 'import json,sys; print(json.dumps({"tool_name":"Bash","tool_input":{"command":sys.argv[1]}}))' "$cmd")"
  printf '%s' "$payload" | ".claude/hooks/${hook}" >/dev/null 2>&1
  rc=$?
  local got="allow"
  [ "$rc" -eq 2 ] && got="block"
  if [ "$got" = "$expect" ]; then
    printf '  ok    %-8s %s\n' "$expect" "$desc"
    pass=$((pass + 1))
  else
    printf '  FAIL  expected %-5s got %-5s  %s\n      command: %s\n' "$expect" "$got" "$desc" "$cmd"
    fail=$((fail + 1))
  fi
}

echo "block-prod-merge.sh"

# Things that must be stopped.
check block-prod-merge.sh block "push to the protected branch"      "git push origin main"
check block-prod-merge.sh block "push with -u to the protected branch" "git push -u origin main"
check block-prod-merge.sh block "push to a remote-qualified ref"    "git push origin HEAD:main"
check block-prod-merge.sh block "merging the protected branch"      "git merge main"
check block-prod-merge.sh block "merging a pull request"            "gh pr merge 5"
check block-prod-merge.sh block "a push hidden behind a chain"      "npm test && git push origin main"

# Things that must NOT be stopped. These are the regressions that matter.
check block-prod-merge.sh allow "push to a feature branch"          "git push -u origin feat/action-row"
check block-prod-merge.sh allow "pulling the protected branch"      "git pull origin main"
check block-prod-merge.sh allow "fetching"                          "git fetch origin --prune"
check block-prod-merge.sh allow "text that only mentions a push"    'echo "remember to git push origin main later"'
check block-prod-merge.sh allow "a pull request body discussing it" 'gh pr create --title x --body "we git push origin main only via review"'
check block-prod-merge.sh allow "opening a pull request"            "gh pr create --base main --head feat/x"
check block-prod-merge.sh allow "a branch merely named for it"      "git push origin docs/maintenance"
check block-prod-merge.sh allow "ordinary commands"                 "ls -la"
check block-prod-merge.sh allow "checking status"                   "git status --short"

echo ""
echo "coverage-gate.sh"

check coverage-gate.sh allow "ordinary commands"                    "ls -la"
check coverage-gate.sh allow "running tests"                        "npm test"
check coverage-gate.sh allow "pulling"                              "git pull origin trunk"
check coverage-gate.sh allow "a word that merely contains it"       "echo gitpush"
check coverage-gate.sh allow "similar looking prose"                "echo legit pushing code"
check coverage-gate.sh allow "a push while coverage passes"         "git push origin feat/x"

echo ""
if [ "$fail" -eq 0 ]; then
  echo "All ${pass} checks passed."
  exit 0
fi
echo "${pass} passed, ${fail} FAILED."
exit 1
