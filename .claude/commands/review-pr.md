---
description: Review a pull request against the workshop checklist, then post the findings, architecture and design intent onto the pull request
argument-hint: <pr-number>
allowed-tools: Bash(gh pr view:*), Bash(gh pr diff:*), Bash(gh pr list:*), Bash(gh pr checks:*), Bash(gh api:*), Bash(git log:*), Bash(git diff:*), Bash(git show:*)
---

Review PR $ARGUMENTS against `docs/review-checklist.md`, then post the result onto the
pull request.

Both halves are required. A review that stays in the terminal has not been done: the
other dev cannot read it, and the reasoning is lost by the time they open the diff.

## 1. Read the change

Fetch the diff and the list of files. Read enough of the surrounding code to judge
whether each hunk belongs, not just whether it compiles.

## 2. Review against the checklist

Report on every item, quoting file and line for each finding:

- scope creep
- edited tests
- new dependencies
- swallowed errors
- secrets or generated credentials

Say clearly when an item is clean. "Nothing found" is a result, not a gap.

Two of these hide from a naive search:

- **Scope creep** is measured in lines, not intent. A branch named for one ticket
  carrying 260 lines of something else is scope creep even when it was deliberate and
  even when it is useful.
- **A swallowed error** is not only an empty `catch`. Two different situations collapsed
  into one message is swallowing too, and no grep will find it. Ask what the user is
  told when something is wrong, and whether that differs from when nothing is wrong.

## 3. Check the claims before making them

Do not assert what you can measure.

- Contrast ratios: compute them, do not estimate.
- "This does not break X": run X.
- "This is pre-existing": prove it. Remove the change, reproduce the problem, say so.
- Quoting another branch: confirm that branch is the one actually under review, not an
  older copy with the same code.

If a number you already stated turns out wrong, correct it in the review rather than
quietly dropping it.

## 4. Post it to the pull request

One review, `event: "COMMENT"`, posted with
`gh api --method POST /repos/{owner}/{repo}/pulls/$ARGUMENTS/reviews --input <file>`.

Build the payload as JSON in a file rather than inline, so quoting and markdown survive.

**The body** carries the checklist result: each item, the findings, and a plain verdict.

**Inline comments** carry the reasoning, anchored to the lines they describe. Keep these
two kinds separate, because they answer different questions:

- **Architecture** — why the code is shaped this way. What it reuses instead of
  restating. What it deliberately does not touch, and what would have gone wrong if it
  had. Where the type or the contract comes from.
- **Design intent** — why these colours, spacing, states and words. The measured numbers
  behind them. What a later change would break.

Anchor each comment to the line a reader needs to be looking at. An architecture comment
belongs on the import or the signature; a design comment belongs on the rule it explains.

## 5. Confirm it landed

Re-read the posted comments and check each one is attached to the file and line you
intended. A review that failed to post is worse than none, because you will believe it
is there.

## Rules

- Never open a pull request without doing this. If the pull request has to exist first
  so the review has something to attach to, review the branch diff, open it, then post.
- Report findings in your own work exactly as you would in anyone else's. A review that
  only ever finds other people's problems is not being read carefully.
- Suggest the fix, do not apply it. If the fix belongs to the other dev's layer, say so
  and say why it is not being done here.
- Distinguish "this pull request caused it" from "this already existed". They lead to
  different tickets and different people.
