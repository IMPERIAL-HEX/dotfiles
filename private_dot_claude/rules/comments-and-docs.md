# Comments & docs

Applies to every project, every language. Covers comments, docstrings, READMEs, and every other `.md` in the repo. This file is written the way it asks you to write.

## Language

Plain words, plain sentences — the way you would say it to the person at the next desk. Say what the thing is and what it does, then stop.

- Short common words: "use" not "utilise", "so" not "hence", "before" not "prior to", "about" not "regarding".
- One idea per sentence. If two halves need a semicolon or a dash to hold them together, write two sentences.
- Active verbs, concrete nouns: "the parser rejects duplicate ids", not "duplicate id handling is performed".
- No throat-clearing — "Note that", "It is worth mentioning", "In order to". Cut it and start at the point.
- No selling: robust, seamless, powerful, comprehensive, elegant, cleanly, simply. If the claim matters, give the fact instead.
- No metaphor, no wordplay, no rhetorical questions where a literal sentence exists.
- No emoji. Bold marks a term, not a mood.
- Say a limit or an unknown once, plainly, then move on. Don't hedge around it in every sentence.

This is the other half of writing less: brevity sets how much you write, this sets how it reads. Short but ornate still fails.

## Comments

**Default: no comment.** Code that needs prose to be understood needs better code — a truer name, a smaller function, an early return, a named constant instead of a literal. Fix the code first. Write a comment only when that genuinely can't work.

When one is warranted, it takes one of two shapes. The first is the common one.

**A docstring on an exported symbol** — JSDoc, or whatever the language uses. One line naming what the thing *is*, only where the name doesn't already say it. Skip parameter and return listings the signature carries. This is what "commented code" should look like: a file's comments read as an index of its public surface, not as a narration of its interior.

**A one-line note on a fact that lives *outside* the code** and cannot be moved into it:

- a constraint from something external — a protocol, an API's real (not documented) behaviour, hardware, a spec clause
- a "why not the obvious thing", where a reader would otherwise undo the work
- a safety, licensing, or security note that must travel with the file

One line. Two only if the constraint truly needs it. Then stop.

### How far a comment may reach

A comment describes the line it sits on. When it reaches past that — another layer, the request lifecycle, what a second consumer does with the result, why the system is shaped this way — it has stopped being a comment. It is a paragraph of the layer's doc that ended up in the wrong file. Move it, and leave no pointer behind.

Two tests, before writing any comment:

1. Could this sentence stand as a line in the README of this directory? Then it belongs there, not here.
2. Does it name a file, package, or layer other than this one? Then it belongs in a README, not here.

A docstring says what a thing is; it does not argue for it. "Resolves the tenant once per request, so every query below is scoped and cross-tenant rows are unreachable" is two sentences wearing one coat — write the first, and put the second in the layer's README where the rest of the isolation story is.

Never write:

- narration of what the next line plainly does
- architecture or flow — what calls this, what runs next, which layer owns what, how two components stay in step. That is the directory's README.
- rationale essays — alternatives considered, trade-offs weighed, consequences enumerated. That is the PR description or a design doc.
- restatements of a type, signature, or default the language already declares
- boxed/ASCII banners, decorative section dividers
- plan-scaffolding labels ("Slice D", "Phase 2", "lands in G4") — plans get rewritten and the label ends up pointing at nothing
- changelog-in-code ("previously we did X, changed on <date>") — that is git
- the old behaviour in any form — "this used to fall back to…", "previously", a before/after. State only what is true now. A reader should never have to hold two versions in their head to understand one.
- the provenance of a decision — who chose it, when, what the alternative was, what evidence settled it. The fact stands on its own; the argument for it does not belong in the file.
- measurements and counts — "54 of 269 records", "fixes 80% of cases", benchmark numbers. They are true on the day they are written and stale by the next change. If a number is load-bearing, assert it in a test.
- TODOs without a concrete owner or condition

Match the surrounding file's density and idiom. If the file has few comments, add few.

```
// Stripe sends the webhook before the charge settles, so the row may not exist yet.
```

not

```
// NOTE: There is an important subtlety here regarding the ordering of events.
// Stripe's webhook delivery is not guaranteed to happen after the charge has
// settled in our own database. We considered polling instead, but that would
// have added latency and cost. We also considered a queue, but ...
```

and

```
/** One page of results plus the cursor for the next. */
```

not

```
/**
 * Pages on (sortColumn, id) rather than an offset, so rows inserted mid-scroll
 * cannot shift a boundary and the query stays index-backed at any depth. The
 * browser and the server build this input from the same helper, or the cache
 * keys drift and the prefetch is discarded on mount.
 */
```

## Docs

A doc carries **direction and purpose** — what this exists for, how the parts relate, which way to go when extending it. It carries what a reader cannot recover from the code. Everything the comment rules above turn away lands here.

It is not a mirror of the code. No exhaustive option tables, no file-by-file inventories, no step-by-step restatement of a function, no pasted code that will drift out of date.

Be complete on what only the doc can hold:

- the purpose, and the problem it solves
- boundaries — what is in scope and what is deliberately not
- how components relate, and the flow between them
- constraints, invariants, and decisions that are expensive to reverse
- how to run or use it, and where the sharp edges are

### One doc per layer

A layer is what a reader holds in their head at once: an app, a package, a top-level module directory. Each one carries a `README.md`, and that is where the list above gets answered for that layer — including how it meets the layers either side of it.

The root README is the map: what the layers are, how they meet, how to run the thing. It links to the layer docs instead of restating them. Each fact lives in exactly one of them.

Write the layer's README when you create the layer, not after. In an existing tree without them, add the one covering the code you are touching rather than back-filling the whole repo.

State a decision as the rule it produced, not as the argument that produced it: "`street` is `thoroughfare`, or empty" — not the survey of what else was considered, not the measurement that justified it, not the defect it replaced. A findings or defect doc is no exception: when an item is fixed, it stops being an item and becomes a line in the list of what now holds.

Test each sentence: if a reader could get it from the code in thirty seconds, cut it. Then test it again: if it is only true of a past version, or only true until someone re-measures, cut it.

Open with what the thing is, in one sentence, in the plain language above. No product pitch, no history of how it came to be, no promises about what it will do later.

Within a layer, extend its README rather than adding a second file beside it. Never write a doc to explain code that explains itself, and never write a summary, status, migration-complete, or hand-off document unless it was asked for — that report goes in the reply, not the repo.

## Keeping them in sync

When changing code, the surrounding comments and the docs describing it are part of the change. Update them in the same pass, without asking.

1. Re-read the comments in and around what you touched. A wrong comment is worse than no comment — delete or correct anything the change invalidated, including comments that now only repeat the code.
2. A comment you delete for reaching too far is not dropped — its content moves into the layer's README in the same pass, merged into the section that already covers that ground.
3. Grep the changed symbol, field, flag, route, or filename across `*.md` (README, guides, `*_ref.md`, architecture notes, `CLAUDE.md`) and bring hits in line.
4. Match the form of the doc you are editing. A bare type listing gets a terse inline note, not a new prose section.
5. Name the docs you updated in your summary, so the change is reviewable.

Trim within the blast radius of your change. Don't sweep unrelated files.
