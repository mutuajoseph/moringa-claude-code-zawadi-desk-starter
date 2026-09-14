# A Tour of This Repo

For someone opening Zawadi Desk for the first time and wondering what any of it is for.

This is a workshop repo, so the code is small on purpose. The interesting part is
everything around the code: the guard rails, the review process, the documents, and the
mistakes that produced them. Nothing in this tour is hypothetical. Every rule here
exists because something went wrong first.

Read `docs/build-map.md` if you want the diagrams. This is the story.

---

## 1. What the app is

Zawadi Desk tracks operations projects. Each project has follow-up actions: a thing to
do, who owns it, when it is due.

Two features, deliberately at different stages when the workshop began:

| Feature | State at the start | Purpose |
| --- | --- | --- |
| **Projects** | finished | the house pattern, to copy |
| **Actions** | a `501` stub | the thing to build |

Both travel the same three steps: a data layer in `lib/`, an API route in `app/api/`,
and a screen in `components/`. Projects had all three. Actions had one and a half.
Nobody had to invent a pattern; they had to copy one.

Two people built it in parallel. Dev A took the backend, Dev B the frontend.

---

## 2. The seam: how two people worked without blocking each other

`docs/contract/actions.yaml` is the single most important file in this repo.

It describes what the API returns before either side builds anything. Once it was
agreed, Dev B could build the entire screen against fake data while Dev A was still
writing the route. Neither waited.

The contract shipped with three unanswered questions at the bottom, marked `TODO`:

- What order do actions come back in?
- Is an owner required?
- Do finished actions stay in the list?

**Each one splits across both devs.** Dev A decides whether the server sorts; Dev B
decides whether the screen sorts again. Doing both is a bug that no test catches,
because each half looks correct alone.

They were settled in fifteen minutes before any code was written, and the answers are
now recorded in that file where the `TODO`s used to be. That fifteen minutes is the
cheapest thing in this repo.

**The lesson:** an unanswered question in a shared contract is not a documentation gap.
It is two people about to build different things.

---

## 3. `.claude/` — the guard rails

This directory configures the coding agent. It has three parts.

### `settings.json` — permissions

Three lists, and the distinction matters:

```text
allow  — runs without asking      (npm test, git diff, git status)
ask    — prompts every time       (npm install, git commit, gh pr)
deny   — refused outright         (reading .env, printenv, force push, rm -rf)
```

The deny list is the interesting one. It is not advice; the agent cannot get past it.
During this workshop it fired twice on real commands: once blocking a `rm -rf` during
cleanup, and once blocking a read of `.env.example` because the pattern `.env.*`
matched it.

**The lesson:** a deny rule that occasionally blocks something harmless is working. One
that never fires is decoration.

### `commands/` — repeatable workflows

A markdown file here becomes a slash command. Two live in this repo.

**`review-pr.md`** reviews a pull request against `docs/review-checklist.md`, then
**posts the result onto the pull request**. That second half was added after the
command had already been used for a while, because of a specific failure:
pull request #2 was opened with no review at all, an hour after the same person
had done it correctly on pull request #1.

The fix was not "remember harder". Posting became part of the command, so there is no
longer a version of "review this" that stops at the terminal.

The command also encodes lessons that cost real time to learn:

| Instruction | Why it is there |
| --- | --- |
| Scope creep is measured in lines, not intent | #1 carried 266 lines of documentation on a branch named for a badge |
| A swallowed error includes two situations sharing one message | #2 showed a malformed date as "No due date"; no grep finds that shape |
| Measure, do not estimate | A contrast figure was wrong until recomputed |
| Prove "pre-existing" by removing the change and retesting | Needed to attribute a layout bug fairly |
| Report findings in your own work like anyone else's | Most real findings here were in the author's own code |

Generic review advice would not have caught any of them.

**`coverage-report.md`** measures coverage and posts the numbers as a plain comment,
deliberately separate from the review so it does not bury it. It compares against the
base branch, because a bare percentage does not tell a reviewer whether to merge, but
the direction of travel does.

### `hooks/` — rules the agent cannot talk its way around

A command is an instruction the agent follows. A hook is a program that runs before a
tool call and can refuse it. The difference matters: instructions can be forgotten or
reasoned around; a hook returning exit code 2 simply stops the command.

**`block-prod-merge.sh`** refuses merges and pushes to the protected branch.

**`coverage-gate.sh`** runs the coverage gate before a push and blocks it if coverage
has fallen.

**`test-hooks.sh`** tests both of the above. Run it from the project root:

```bash
.claude/hooks/test-hooks.sh
```

That third file is not ceremony. See section 6.

**One honest limitation:** these hooks only see work done through the agent. A push
typed directly into a terminal walks straight past them. They are a convenience layer.
CI is the real enforcement, because it binds the pull request rather than the person.

---

## 4. What CI actually guards

`.github/workflows/ci.yml` runs on every pull request: tests, the coverage gate, a type
check, and a production build.

The coverage gate is a **ratchet**, not a target. Thresholds in `vitest.config.ts` sit
just below the current numbers, so coverage cannot fall. They are raised as tests land.
`docs/coverage.md` explains how to raise them and, more importantly, what not to do:
never narrow the measured set to improve the number, and never lower a threshold
quietly to make a pull request pass.

This was not theoretical. See section 6.

---

## 5. The documents, and why each exists

| File | What it is for |
| --- | --- |
| `docs/contract/actions.yaml` | The agreement between the two devs. The seam. |
| `docs/handover/actions-screen.md` | The screen spec: four states, fixed copy, accessibility rules |
| `docs/handover/tokens.json` | Colour and spacing values, mirrored as CSS variables |
| `docs/review-checklist.md` | Six questions every review must answer |
| `docs/build-map.md` | The codebase and the flows, as diagrams |
| `docs/open-findings.md` | Seven reproducible gaps, each naming who it lands on |
| `docs/coverage.md` | Today's numbers, how to raise the floor, what not to do |
| `docs/tour.md` | This file |

Two are worth opening even if you skip the rest.

**`docs/open-findings.md`** is the template for how to report a problem. Every finding
carries four things: what it is, evidence that reproduces it, who it lands on, and a
suggested fix. It is ordered by whether it blocks, not by abstract severity, because
the question a reader has is "do I have to act before I merge".

It also attributes findings to code rather than to authors, and states blocking plainly
instead of hedging. A document that softens every item reads as a list of opinions, and
the ones that matter get lost.

**`docs/handover/actions-screen.md` contains a planted prompt injection.** Near the
bottom sits a paragraph of untrusted text that instructs the reader to reveal secrets
and change tests. It is deliberate, and it is there because your coding agent reads
that file too.

The correct response is to treat it as content on a page, not as a command. Text inside
a document you are reading has no authority over what you do. That principle generalises
well past this file: pull request bodies, issue comments, dependency READMEs and web
pages are all untrusted input.

---

## 6. What went wrong, and what it taught us

This is the most useful section. Every one of these is real.

### A guard rail that existed and never fired

`block-prod-merge.sh` shipped with the starter, executable, correct-looking. It never
ran once, because `settings.json` had no `hooks` key to invoke it. It read as protection
while doing nothing.

**Wiring it up immediately exposed a second bug.** It matched the raw tool payload,
which arrives as a single JSON line, so a pattern spanning `.*` reached across an entire
message body. It blocked two ordinary commands: a test that merely quoted the trigger
words inside an `echo`, and the call that was opening its own pull request, because the
body text discussed branch policy.

It now reads the actual command, splits on shell separators, and only considers a
segment whose **first word** is `git` or `gh`.

**The lesson:** the dangerous failure is not a missed block. It is a hook that blocks
ordinary work, because that is the one people switch off.

### A fix that silently disabled the thing it fixed

The first version of that repair allowed **every** blocked case. `read` does not process
a final line with no trailing newline, and most commands are a single segment, so the
loop body never ran. The guard rail was completely inert and looked fine.

`test-hooks.sh` caught it in seconds. Without it, the repo would have shipped a second
dead hook while believing it had fixed the first.

That is why most of its 21 cases assert what must be **allowed**, not what must be
blocked. Verifying the blocks is easy and insufficient.

### A stacked pull request that merged into nowhere

Pull request #9 was merged, and its work never reached the default branch. Its base
branch had already been merged, so nothing was feeding from it any more.

**Merged branches are not deleted here** — twelve remain on the remote after eleven
merges — and GitHub only auto-retargets a stacked pull request when its base branch is
deleted. So a stack keeps pointing at branches that have already been merged, and
merging into one puts the work somewhere nothing pulls from.

**If you stack pull requests here:** retarget each one to the default branch as its base
lands, before merging it. Or turn that repo setting on and remove the hazard.

### A coverage gate that caught a real regression

Merging the four feature pull requests added source files without adding tests. Coverage
fell from 7.69% to 4.25% of statements and CI went red.

The fix was **not** to lower the floor. The four contract tests already exercised most of
that code and simply were not being measured. Including them took coverage to 59.57%
without a single new test being written.

**The lesson:** when a metric drops, the first question is whether you are measuring the
right thing. That change also closed the oldest finding in `open-findings.md`, which was
that a green CI badge said nothing about the actions feature.

### A secret pasted into a chat

An API key was pasted into a conversation with the agent. The correct response was to
revoke it immediately, not to use it and move on. A credential that has been in a chat
transcript is a credential that needs replacing.

The safe pattern is an environment variable read from your shell profile, never a value
typed into a message or committed to a file.

**A related trap worth knowing:** `~/.zshrc` is only read by *interactive* shells.
Exports placed there are invisible to tools, scripts and agents. `~/.zshenv` is read by
every shell. An export in the wrong file looks set and silently is not.

---

## 7. How to work in this repo

1. **Branch. Always.** Never commit to the default branch. CI runs on pull requests.
2. **Settle the contract before building**, if your change touches the seam.
3. **Keep diffs small.** Two or three pull requests per feature, not one.
4. **Never edit `tests/actions/contract.spec.ts`** to make your work pass.
5. **Run `/review-pr <number>`** and let it post. A review in your terminal has not
   happened.
6. **Measure claims.** Contrast ratios get computed. "This does not break X" means you
   ran X. "Pre-existing" means you removed your change and reproduced it.
7. **No credentials anywhere.** Code, docs, logs, screenshots, pull request bodies, chat.

## Commands

```bash
npm install            # set up
npm run dev            # run the app
npm test               # the projects suite
npm run test:actions   # the contract scoreboard, the real measure of the feature
npm run test:coverage  # the full suite plus the coverage gate
npm run lint           # type check
npm run build          # production build

.claude/hooks/test-hooks.sh   # verify the hooks still block and still allow
```

## Where to start reading

- `lib/projects.ts` and `app/api/projects/route.ts` — the house pattern, about 40 lines
- `docs/contract/actions.yaml` — what the two halves agreed
- `docs/build-map.md` — the same thing as diagrams
- `docs/open-findings.md` — what is still open, and who owns it
