# Open Findings

Gaps found while building the actions feature. Each one is reproducible, and
each one names who it lands on. Nothing here is a matter of taste.

Raised for review by both devs. Items 1 and 2 affect the backend directly and
are the reason this document exists rather than a chat message.

**Status:** findings 1 and 6 are resolved. The rest are open.

| # | Finding | Lands on | Blocks | Status |
| --- | --- | --- | --- | --- |
| 1 | CI never runs the contract tests | Dev A | Yes | **Resolved** |
| 2 | Due date validation is stricter than the contract | Dev A and Dev B | Yes, at the seam | Open |
| 3 | Page overflows at phone width | Both | Before demo | Open |
| 4 | Project status badges fail the contrast bar | Dev B | No | Open |
| 5 | A malformed due date reads as "no deadline" | Dev B | No | Open |
| 6 | The merge guard rail never fires | Lead | No | **Resolved** |
| 7 | Stored actions vanish on restart | Dev A | No, by design | Open, by design |

---

## 1. CI never runs the contract tests — RESOLVED

> **Resolved.** `test:coverage` now runs the whole suite with
> `INCLUDE_ACTION_CONTRACTS=1`, and CI runs that command, so the contract tests run on
> every pull request. Kept here because the reasoning below explains why a green badge
> can mean nothing, which is worth reading before trusting the next one.

**A green CI badge does not mean the actions feature works.**

`.github/workflows/ci.yml` runs four steps:

```
npm ci
npm test
npm run lint
npm run build
```

And `npm test` is defined as:

```
"test": "vitest run tests/projects"
```

The contract tests live in `tests/actions/` and only run under
`npm run test:actions`, which nothing in CI calls. They are also skipped
entirely unless `INCLUDE_ACTION_CONTRACTS=1` is set.

**Evidence.** Pull requests 1 and 2 both passed CI while the actions route on
`main` still answered every request with `501 NOT_IMPLEMENTED`. The scoreboard
that measures the actual feature was never consulted.

**Why it matters to Dev A.** The four contract tests are the definition of done
for the backend ticket. If they do not run on every pull request, a later change
can quietly break the endpoint and nothing will say so. The person who finds out
is whoever demos it.

**Suggested fix.** Add one line to the workflow, after `npm test`:

```yaml
      - run: npm run test:actions
```

Small, and it turns the contract into an enforced agreement rather than a
document. Worth doing before the actions branch merges, not after.

---

## 2. Due date validation is stricter than the contract says

`docs/contract/actions.yaml` describes the field as:

```
dueDate: string ISO 8601 | null
```

The implementation in pull request 5 (`feat/actions-create-endpoint`) validates it as:

```ts
dueDate: z.string().datetime().nullish()
```

Zod's `.datetime()` accepts only UTC datetimes ending in `Z`. ISO 8601 is a much
wider standard, so the code is narrower than the contract it implements.

**Evidence.** Running each candidate through that exact schema:

| Value | Result | What produces it |
| --- | --- | --- |
| `2026-09-15T00:00:00.000Z` | accept | a server, or another API |
| `2026-09-15` | **reject** | `<input type="date">`, the obvious UI control |
| `2026-09-15T00:00:00` | **reject** | a datetime with no timezone |
| `2026-09-15T00:00:00+03:00` | **reject** | **a datetime in Nairobi time** |
| `null` | accept | the contract's explicit "no deadline" |

**Why it matters at the seam.** The empty state in
`docs/handover/actions-screen.md` specifies a button reading
`Add the first one`. The natural way to build that form is a date input, and a
date input produces `2026-09-15`. Every submission would come back `400`, and it
would look like a frontend bug rather than a validation mismatch.

The Nairobi offset row is worth a second look. A user in the workshop's own
timezone sending a local datetime is rejected.

**Suggested fix.** Decide which one is true and make both sides agree:

- **Narrow the contract** to say `dueDate: string, ISO 8601 datetime in UTC | null`,
  and Dev B converts before sending. Honest, and no backend change.
- **Widen the validation** to accept what the contract already promises, using
  `z.string().datetime({ offset: true })` for offsets, or accepting a date-only
  string and normalising it server-side.

Either is fine. Silently disagreeing is not. This one needs a decision before
the create form is built.

---

## 3. The page overflows at phone width

At a 400px viewport the page scrolls sideways and content is clipped on the
right, including the status badge on the project cards and the record count in
the panel header.

**This is pre-existing and not caused by the actions work.** Verified by
removing every action row from the page and reproducing the same clipping with
only the original projects feature rendered.

**Why it matters.** `docs/handover/actions-screen.md` asks for rows capped at
720px and centred, which implies the screen is meant to be usable at smaller
sizes. Whoever picks up B6 will meet this bug and may assume they caused it.

**Suggested fix.** Its own small ticket against the shared layout, not folded
into an actions branch. Starting point is `.shell` and `.panelHeader` in
`app/globals.css`.

---

## 4. Project status badges fail the contrast bar

`app/globals.css` styles `.status` as white text on a filled background. Against
the accent colour that measures **3.80:1**, below the 4.5:1 that
`docs/handover/actions-screen.md` requires.

| Badge | Ratio | Verdict |
| --- | --- | --- |
| `.status-active` on `--accent` | 3.80:1 | fail |
| `.status-complete` on `--ok` | 4.98:1 | pass |
| `.status-paused` on `--muted` | 5.99:1 | pass |

The action badges added in B1 avoid this by using dark ink on a light tint, and
measure between 9.39:1 and 9.93:1. The projects feature still carries the
original pattern.

**Why it was not fixed in B1.** `.status` belongs to the finished reference
feature. Changing it from inside a Dev B ticket would have put a projects
regression in a pull request about actions, which `docs/review-checklist.md`
asks reviewers to reject.

**Suggested fix.** Its own ticket. The natural moment is after the actions
feature lands, when both badge systems can be unified into one.

---

## 5. A malformed due date reads as "no deadline"

In `components/action-row.tsx`, `formatDueDate` returns the same string for two
different situations:

- `dueDate` is `null`, meaning no deadline was ever set
- `dueDate` is present but unparseable, meaning the data is wrong

Both display `No due date`. Confirmed by rendering a row with an invalid date
value.

**Why it matters.** In an operations tool those readings are opposite. One says
nobody set a deadline. The other says a deadline exists but could not be read.
Showing a data fault as "no deadline" is how a deadline gets missed.

The guard itself is correct and should stay. `Intl.DateTimeFormat` throws on an
invalid date, and an uncaught throw inside a row would take down the whole list.
Only the shared wording is wrong.

**Suggested fix.** Separate the two messages, for example
`Due date unavailable` for the malformed case. The wording is a product
decision, which is why it is here rather than already changed.

Note this becomes much less likely if finding 2 is resolved, since the backend
would then be the only source of due dates and it validates them.

---

## 6. The merge guard rail never fires — RESOLVED

> **Resolved.** `.claude/settings.json` now has a `hooks` key wiring both hooks, and
> `.claude/hooks/test-hooks.sh` covers them. Enabling it exposed a second bug in the
> matcher, which is written up in `docs/tour.md` section 6.

`.claude/hooks/block-prod-merge.sh` exists and is executable. It refuses merges
and pushes to `main`.

Nothing invokes it. `.claude/settings.json` contains only a `permissions` key
and no `hooks` key, so the script is never called.

**Why it matters.** The protection reads as active when it is not. Anyone
relying on it to catch a direct push to `main` is relying on nothing.

**Suggested fix.** Either wire the hook up in `.claude/settings.json`, or add a
branch protection rule on `main` in GitHub, which is enforced server-side and
therefore applies to everyone rather than only to people running this tooling.
Branch protection is the stronger of the two.

---

## 7. Stored actions vanish on restart

`lib/actions.ts` keeps actions in a module-level `Map`. That resets whenever the
process restarts, and on Vercel it is not shared between serverless invocations,
so two requests can see different data.

**This is by design for the workshop** and matches how `lib/projects.ts` holds
its records. It is listed here only so nobody discovers it during a demo and
treats it as a bug.

**No action needed.** Worth one sentence in the README if this repo outlives
the workshop.
