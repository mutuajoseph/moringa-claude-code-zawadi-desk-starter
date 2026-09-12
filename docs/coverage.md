# Coverage

Coverage is a ratchet, not a target. The thresholds in `vitest.config.ts` sit just below
the current numbers, so coverage cannot fall. They are raised as tests land.

The destination is 50%. We are not there, and pretending otherwise by setting the gate
at 50% today would just block every push.

## Where it comes from

`npm run test:coverage` runs the test suite and measures it with `@vitest/coverage-v8`.
CI runs the same command, so the gate is identical locally and on a pull request.

Three reporters are written. `text-summary` is for reading, `json-summary` holds the
totals the gate checks, and `json` holds per-line data. Only the last of those can say
*which* lines are uncovered, which is what `/coverage-report` needs.

`coverage.include` decides what is counted, and every file it matches appears in the
report whether or not a test imported it. That matters: without it, an untested file is
simply absent and the number flatters us. Vitest 4 made this the default for whatever
`include` matches, replacing the older `all` flag.

## Today's numbers

| Metric | Coverage | Threshold |
| --- | --- | --- |
| statements | 59.57% | 59% |
| branches | 66.66% | 66% |
| functions | 50% | 49% |
| lines | 60.46% | 60% |

**The 50% destination has been reached.** Not by writing new tests, but by measuring
the ones that already existed.

## How it got there

For a while coverage sat at 7.69% of statements, and only `lib/projects.ts` had any at
all, because the measured suite was `vitest run tests/projects`.

The four contract tests in `tests/actions/` exercise the actions route, `lib/actions.ts`
and `lib/errors.ts`, which are most of the source lines. They simply were not being run.
That was finding 1 in `docs/open-findings.md`.

`test:coverage` now runs the whole suite with `INCLUDE_ACTION_CONTRACTS=1`, so those
four tests count. Coverage went from 4.25% to 59.57% of statements without a single new
test being written.

**This also closes finding 1.** The contract tests are now part of what CI runs, so the
agreement in `docs/contract/actions.yaml` is enforced on every pull request rather than
only when someone remembers to run it.

The next real gains need component tests, which need a DOM environment. See below.

## Raising the thresholds

When coverage goes up, raise the floor **in the same pull request**. A floor that drifts
below reality stops protecting anything.

1. Run `npm run test:coverage`.
2. Read the summary, or `coverage/coverage-summary.json` for exact figures.
3. Set each threshold in `vitest.config.ts` just below the achieved number.
4. Say in the pull request description what moved and why.

## What not to do

- **Do not narrow `coverage.include` to raise the number.** Removing an untested file
  from the report does not test it. It only hides it.
- **Do not add a test purely to move the percentage.** A test that asserts nothing
  useful costs maintenance forever and buys one number once.
- **Do not lower a threshold to make a pull request pass.** If coverage genuinely
  should drop, for example because the pull request adds a large file a later ticket
  will test, say so in the description and get it agreed rather than quietly editing
  the floor.

## Components are at 0%

`components/` has no coverage and cannot get any today: `vitest.config.ts` sets no DOM
environment and `@testing-library` is not installed. Rendering tests would need both.

They are deliberately still counted rather than excluded, because excluding them would
make the number look better while testing nothing. The gap is real and the report
should show it.

## The push hook

`.claude/hooks/coverage-gate.sh` runs the same command before a push made through
Claude and blocks the push if the gate fails. It is wired up in
`.claude/settings.json` as a `PreToolUse` hook on `Bash`.

It is a convenience, not a guarantee. It only sees work done through Claude, so a push
typed directly into a terminal walks straight past it. **CI is the real enforcement**,
because it binds the pull request rather than the person.

Anything that is not a push passes through in a few milliseconds, so ordinary commands
are unaffected. A push costs roughly a second while the suite runs.

If the check cannot run at all, for example in a checkout with no `test:coverage`
script, the hook allows the push rather than blocking every command in a project that
never opted in.
