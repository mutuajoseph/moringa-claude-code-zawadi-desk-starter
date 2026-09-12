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

Measured on `main` with the suite CI currently runs:

| Metric | Coverage | Threshold |
| --- | --- | --- |
| statements | 7.69% | 7% |
| branches | 0% | 0% |
| functions | 6.66% | 6% |
| lines | 8% | 7% |

Only `lib/projects.ts` has any coverage, because `npm test` runs only `tests/projects`.

## Why it is so low, and the one change that fixes most of it

The four contract tests in `tests/actions/` exercise the actions route, `lib/actions.ts`
and `lib/errors.ts`. Together those are more than half the source lines being measured.

**They do not run in CI.** `npm test` is `vitest run tests/projects`, and nothing calls
`npm run test:actions`. This is finding 1 in `docs/open-findings.md`.

Once the actions stack is merged and those tests run as part of the measured suite,
coverage rises sharply without anyone writing a new test. That is the moment to raise
the thresholds, and it is a much bigger step than any single ticket will give.

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
