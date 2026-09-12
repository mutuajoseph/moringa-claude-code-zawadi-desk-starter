---
description: Run the test suite with coverage and post the numbers, and what changed, as a comment on a pull request
argument-hint: <pr-number>
allowed-tools: Bash(npm run test:coverage), Bash(npm test), Bash(node:*), Bash(git stash:*), Bash(git checkout:*), Bash(git merge-base:*), Bash(gh pr view:*), Bash(gh pr diff:*), Bash(gh api /repos/:*), Bash(gh api --method POST /repos/:*)
---

Measure coverage for PR $ARGUMENTS and post the result onto the pull request.

Run this after `/review-pr`, so the review and the numbers arrive together rather than
as two unrelated notifications.

## 1. Measure

Run `npm run test:coverage`. It writes `coverage/coverage-summary.json`, which is the
machine-readable source for everything below. Read the totals from that file rather
than scraping the printed summary.

If the command exits non-zero, say so first and report which metric fell under its
threshold. A failed gate is the headline, not a footnote.

## 2. Compare against the base branch

A bare percentage does not tell a reviewer whether to merge. The useful number is the
direction of travel.

Measure the base branch the same way, then report both and the delta. Restore the
working tree afterwards, and confirm it is restored before moving on.

If the base cannot be measured, say that instead of implying the number is new.

## 3. Say which files the pull request left uncovered

List only files this pull request touches. Coverage on files it did not touch is noise
and makes the comment too long to read.

For each, give the percentage and the uncovered line numbers. A reviewer can act on
"lines 12 to 17 are untested"; they cannot act on "62%".

## 4. Post it

One comment, via
`gh api --method POST /repos/{owner}/{repo}/issues/$ARGUMENTS/comments`.

Note this is `issues/`, not `pulls/`. A plain pull request comment is an issue comment.
It deliberately does not go through the review endpoint, so it sits separately from the
`/review-pr` findings rather than burying them.

Lead with the verdict: passing or failing, and the delta. Then the table. Then the
uncovered lines. A reviewer who reads one line should learn whether coverage went up or
down.

## 5. Confirm it landed

Re-read the posted comment. A comment that failed to post is worse than none, because
you will believe it is there.

## Rules

- **Report the number, do not chase it.** Never add a test purely to move the
  percentage, and never narrow `coverage.include` to hide an untested file. Both make
  the metric lie, and the metric is the only thing anyone will look at later.
- **A drop is a finding, not a failure.** Say which file caused it and by how much.
  Sometimes a drop is correct, for example when a pull request adds a large file that a
  later ticket will test. Say that rather than treating every dip as a defect.
- **Thresholds are a ratchet.** They sit just below the current number so coverage
  cannot fall. When coverage rises, raise them in `vitest.config.ts` in the same pull
  request that raised it, otherwise the floor drifts away from reality and stops
  protecting anything. Destination is 50%.
- **Do not post a number you did not measure.** If the run failed, say it failed.
