---
name: kb
description: Capture a concept learned in this session into the private knowledge-base repo as a PR.
disable-model-invocation: true
argument-hint: [topic]
allowed-tools: Read, Write, Edit, Glob, Grep, Bash(git -C * fetch *), Bash(git -C * show *), Bash(git -C * grep *), Bash(git -C * ls-tree *), Bash(mkdir -p /tmp/kb-stage*), Bash(rm -rf /tmp/kb-stage*), Bash(${CLAUDE_SKILL_DIR}/scripts/kb-pr.sh *)
---

Repo `$KB_REPO`, read from the clone at `$KB_LOCAL` on `origin/$KB_BASE` — always the
published state, never the local working tree.

## Routing index — llms.txt

```!
K="${KB_LOCAL:-$HOME/work/knowledge-extraction/knowledge-base}"; B="${KB_BASE:-main}"
git -C "$K" fetch -q origin "$B" 2>/dev/null || echo "(offline — may be stale)"
git -C "$K" show "origin/${B}:llms.txt" 2>/dev/null \
  || { echo "(not on origin/${B} yet — local working copy)"; cat "$K/llms.txt"; }
```

## Entry contract — CLAUDE.md

```!
K="${KB_LOCAL:-$HOME/work/knowledge-extraction/knowledge-base}"; B="${KB_BASE:-main}"
git -C "$K" show "origin/${B}:CLAUDE.md" 2>/dev/null || cat "$K/CLAUDE.md"
```

## Task

Capture **$ARGUMENTS** from this conversation into the knowledge base.

1. **Name the primitive.** What general thing is this an instance of? If you cannot
   state it in one sentence without this project's nouns, it is not ready — say so
   and stop. Do not file project trivia.

2. **Search the base first.** `git -C $KB_LOCAL grep -il "<term>" origin/$KB_BASE`.
   If the idea already has a home, **extend that entry** — a near-duplicate folder is
   worse than a thin one. Extending is the expected outcome, not the exception.

3. **Place it** using the routing index and the placement table above. `concepts/` is
   the default. If nothing fits, stop and ask — never invent a category or a new
   top-level dir.

4. **State the plan in one line before writing**, in CLAUDE.md's form:
   `→ concepts/B.E./<x>.ts — teaches <primitive>; not stacks/, because <reason>.`

5. **De-project the example** per the checklist above: strip project and domain nouns,
   business rules, internal helpers, real IDs. Keep the shape, drop the business. The
   incident that prompted this becomes a *gotcha* bullet, nothing more.

6. **Stage the change** under `/tmp/kb-stage/`, mirroring repo paths — clear it first
   with `rm -rf /tmp/kb-stage`. Write commented source as the lesson; `.md` is the map.
   Numbered lessons carry `↑ MAP: / ◀ BACK: / ▶ NEXT:` headers and a `▶ NEXT:` footer.
   Index updates land in the same change: read the current file with
   `git -C $KB_LOCAL show "origin/${KB_BASE}:<path>"` — brace the variable, zsh reads
   a bare `$KB_BASE:l...` as a modifier — edit it, stage the whole result.
   A new file that no README links to is a bug CI will reject.

7. **Show the plan line, the staged file list, and the draft. Wait for approval.**

8. On approval, run **in the background**:
   `${CLAUDE_SKILL_DIR}/scripts/kb-pr.sh /tmp/kb-stage "<title>"`

9. Report **only the URL it prints**. No git output, no summary of the entry.
