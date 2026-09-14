# graft

A local index of this repo that answers "where does X live" and "what breaks if I change
it" without reading source files.

It is optional. Nothing in the build, the tests or CI depends on it. It exists because
finding your way around a codebase by reading it is slow for a person and expensive for
an agent, and most of that cost is avoidable.

---

## Why it matters

The obvious benefit is token cost, and that is the smaller half.

**The real benefit is edges.** `grep` searches text. graft knows what calls what, because
it parses the code into a graph. That distinction shows up the moment you ask a question
text search cannot answer:

> "If I change `listActions`, what breaks?"

`grep listActions` returns lines containing that string. It cannot tell you that a
contract test depends on it *transitively*, through a helper that calls the route that
calls the function. graft can, because it walks the edges:

```bash
graft callers listActions --depth 2
```

That is the class of question worth reaching for graft on. Rename safety, blast radius,
"what does this actually depend on" — all of them are edge questions, and all of them
are ones `grep` answers confidently and incompletely.

The token savings are real too, and larger than they look, because the baseline is not
"a smaller answer" but "reading whole files to reconstruct the same understanding".

---

## Getting started

```bash
graft build
```

That is the whole setup. It takes under a second on this repo, needs no API key, costs
nothing, and writes to `graft/`.

**The index is not committed.** `graft/` is in `.gitignore` because it is a regenerable
local cache. Each person runs `graft build` once and gets their own. It is about 208K
here.

You do not need to re-run `build` after editing. Every query command refreshes the graph
before answering, so results describe the code as it is now, including uncommitted
changes.

---

## The commands

Six, and the skill is picking the right one rather than chaining several.

| Command | Use it when | Cost on this repo |
| --- | --- | --- |
| `graft ask "<question>" --source` | You do not know where the code lives. Conceptual or locational questions. | 45% saved |
| `graft grep "<pattern>"` | You need **every** occurrence, not the top matches. Results grouped by enclosing symbol. | 70% saved |
| `graft skeleton <file>` | "What's in this file / what can I call here" before editing it. | 32% saved |
| `graft callers <symbol>` | Before you rename, delete, or change a signature. `--depth 2` for blast radius. | 93% saved |
| `graft map` | You landed cold and want the architecture. | 91% saved |
| `graft build` / `check` | Build the index; `check` fails when stale, for CI. | n/a |

Two worth knowing properly:

**`ask` is ranked and returns the top N.** It will miss occurrences. When you need
exhaustive, that is `grep`, not `ask`.

**`grep` takes a short symbol name, not a guessed signature.** An over-specific pattern
returns nothing even when the code is indexed. If a search misses, loosen it rather than
falling back to `grep -rn`, which is slower and unranked.

---

## Measured on this repo

Not estimates. These are the figures graft reported on real calls here:

| Call | Output | Instead of reading | Saved |
| --- | --- | --- | --- |
| `graft map` | 277 tok | 3,194 tok (17 files) | **91%** |
| `graft callers listActions --depth 2` | 47 tok | 638 tok (2 files) | **93%** |
| `graft grep "validationFailed"` | 167 tok | 555 tok (2 files) | **70%** |
| `graft ask "how are validation errors shaped"` | 739 tok | 1,351 tok (4 files) | **45%** |
| `graft skeleton lib/actions.ts` | 128 tok | 188 tok (1 file) | **32%** |

The ratio is the part that matters. Seventeen small files make the absolute numbers
trivial; the same ratios on a repo with a thousand files are the difference between a
question you can ask and one you cannot afford to.

Note the bottom row. On a single small file, the pointers cost nearly as much as the
source. **graft is not always the cheaper move**, and the savings line tells you when it
was not.

---

## The visualisation

```bash
graft viz
```

Serves an interactive view of the graph at `http://127.0.0.1:4400` with context, code
and outline tabs. `--export <dir>` writes a self-contained page instead, for CI or a
build artifact.

---

## What it does not do

**It does not replace reading code.** It tells you *where* to read, precisely, so you
open a 20-line span instead of a 200-line file.

**It is not a search index for prose.** Documentation, configuration and brand-new files
are not parsed. Plain `grep` is correct for those.

**The deep layer is optional and unnecessary here.** `graft build --deep` adds prose
summaries via an LLM API, which needs a paid API key. It improves ranking on large
unfamiliar codebases. On seventeen files you wrote yourself, the structural graph does
everything useful, and it is what produced every number in the table above.

> A Claude subscription does not pay for API calls. The Developer Platform bills
> separately on prepaid credits. If `--deep` reports an exhausted balance, that is why.

---

## Practical notes

**The `.ignore` file is committed on purpose.** `graft/` is gitignored, and ripgrep
respects `.gitignore`, so the cards would be invisible to search. `.ignore` is read
first and re-admits the directory to search without un-ignoring it for git.

**If graft names a path that is not on disk**, its index is ahead of your checkout after
a branch switch. Run `graft build` to refresh.

**Do not pipe graft through `head` or `tail`.** Every command is already capped and
states what it dropped. Clipping it loses hits you asked for.

---

## Cheat sheet

```bash
graft build                              # once per checkout
graft map                                # orient
graft ask "where is X handled" --source  # locate + read in one call
graft grep "symbolName"                  # every occurrence
graft skeleton path/to/file.ts           # that file's API
graft callers doThing --depth 2          # what breaks if I change it
graft viz                                # the interactive graph
```
