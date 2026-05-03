# Survey re-audit playbook

One iteration = re-verify exactly **one** cohort survey by reading its
source code with intent — not just grepping for names and counts.
Pick the stalest, walk the actual call path of a representative user
flow through the clone, fix anything the survey gets wrong, fill
anything important it misses, append a `*Re-audit YYYY-MM-DD ...*`
footer, commit, push.

The whole point of this map is "code-verified, not vendor-described".
A re-audit pass that just confirms file paths exist defeats that. Read
the code.

## /loop invocation

```bash
/loop scripts/re-audit.md
```

Each tick of the loop runs the full pass below; the next tick picks
the next stalest survey.

## Per-iteration steps

### 1. Pick

```bash
slug=$(scripts/pick-stale-survey.sh)
echo "$slug"
```

Outputs the survey with the oldest `*Audit ...*` / `*Re-audit ...*`
footer. Override manually if a particular repo had a known major
release recently and skipped to head of queue.

### 2. Refresh clone

```bash
scripts/clone-cohort.sh "$slug"
git -C "surveys/_clones/$slug" log -1 --format='%h %ad %s' --date=short
```

Note the commit SHA + date for the audit footer.

### 3. Sanity grep (cheap, first)

Quick sanity sweep before the deep read. Each must pass; flag any miss
for correction in step 5.

| Check | Command |
|---|---|
| Star count | `gh api "repos/${slug//__//}" --jq .stargazers_count` |
| Last push | `gh api "repos/${slug//__//}" --jq .pushed_at` |
| Version pin | grep `version =` in `pyproject.toml` / `package.json` / `Cargo.toml` |
| License | `head -2 surveys/_clones/$slug/LICENSE*` |
| Top-level dirs | `ls surveys/_clones/$slug/` — any new top-level subsystem? |
| Files referenced in survey | `ls` each one in the clone |

### 4. Deep read — the actual audit

This is the load-bearing step. Pick **one user-facing flow** the
survey claims something about, and trace it end-to-end through the
code. Don't just grep for class names — open the file and read
sequentially. The point is to confirm the survey's *story* matches
the code's *reality*, not just that vocabulary tokens appear.

**Step 4a — Identify the architectural center.** What's the entry
point that an actual user / agent hits? Common shapes:

- **kb-app**: REST handler, GraphQL resolver, or chat endpoint
- **memory-framework**: `MemoryClient.add()` / `add_memory()` / `Memory.write()`
- **wiki-compiler**: CLI command (e.g. `understand-anything analyze`)
- **coding-agent**: tool dispatch / message handler
- **graphrag**: `index()` and `query()` top-level callables
- **infra-layer**: connection / query handler
- **kb-framework**: Pipeline / Workflow execution kernel

For ragflow the center is `agentic_reasoning/` orchestrator + the
`api/` HTTP layer. For mem0 it's `mem0/memory/main.py`'s `Memory.add` →
`_extract` → `_save`. For aider it's `aider/repomap.py`'s `RepoMap.get_repo_map`.
The survey usually names the center already — start there.

**Step 4b — Trace one flow end-to-end.** Pick whichever flow the
survey makes the strongest claim about (often retrieval or extraction).
Open the entry point and read forward through every call. Confirm:

- Each named step in the survey corresponds to a real call site
- The order of operations matches the survey's description
- Conditional branches (e.g. "if vector store present, do X; else Y")
  actually exist as written
- Numbers attached to claims ("8.2× reduction", "4-tier schema", "16
  pre-baked recipes") map to specific data structures or table sizes
  you can count in the source

If the survey says "X happens before Y, then Z reranks", the code
should follow that order. If it doesn't, that's a correction.

**Step 4c — Read at least one test.** Tests document what the authors
believe the system *should* do. Find a test that exercises the flow
from 4b:

```bash
grep -rln "test_<flow_name>\|test_<entry_point>" surveys/_clones/$slug/tests/
```

Read it. Compare what the test asserts against what the survey
describes. Tests often expose constraints the survey missed (default
batch sizes, retry counts, fallback paths, error semantics).

**Step 4d — Read the CHANGELOG and recent commit log.** What's been
added since the last audit? New behavior the survey should mention?

```bash
git -C "surveys/_clones/$slug" log --since="$(date -v-90d +%Y-%m-%d)" \
    --pretty=format:'%h %ad %s' --date=short | head -30
head -100 surveys/_clones/$slug/CHANGELOG.md 2>/dev/null
```

### 5. Edit + footer

If the deep read surfaced corrections — wrong order of operations,
incorrect numbers, missing key concepts, an entire subsystem the
survey didn't mention — fix the survey body inline. Don't just stash
the finding in the footer.

Then append a footer line with:

- The commit SHA you audited against (so the next iteration knows
  what's already covered)
- What you actually read (file paths + line ranges, not just dir
  names — proves you read code, not summaries)
- What you verified, corrected, and added
- Star count delta and last-push date

Format:

```markdown
*Re-audit YYYY-MM-DD iter N (against [<slug>@<sha>](https://github.com/<slug>/tree/<sha>)): traced <flow> through <file:lines>, <file:lines>; read tests/<test_path>. Verified — <claim 1>, <claim 2>. Corrections — <change 1: wrong → right>. Added — <new fact + where in code>. Star count <old> → <new> (<delta>%); pushed_at <date>.*
```

If the deep read produced no corrections, still record what you read:

```markdown
*Re-audit YYYY-MM-DD iter N: traced <flow> through <file:lines>; tests/<path> still asserts <behavior>. No corrections; survey current. Star count <old> → <new>; pushed_at <date>.*
```

The iteration counter (`iter N`) is per-survey: read the previous
footer to find N (graphiti is at iter 64, MaxKB at iter 1).

### 6. Commit + push

```bash
git add "surveys/$slug.md"
git commit -m "Re-audit $slug (iter N): <one-line summary of changes>"
git push
```

If the audit changed cohort-wide aggregates (e.g. graph-store count,
license enum, reranker subset size), flag this in the commit body so a
human can update the README's Adoption tables — don't try to update
README aggregates inside a per-survey iteration.

### 7. Stop

One survey per iteration. The loop's next tick picks the new stalest
entry. The full cohort cycles every 46 ticks.

## What this loop is *not* for

- **Adding new repos** — that's the `curating-agentic-kbs` skill.
- **Restructuring surveys** — bigger refactors should be separate PRs.
- **Hands-on / dogfooding verification** — actually running the code
  is what `recipes/` captures. A recipe build log (which 🟢 stages
  assembled cleanly, where 🟡 / 🔴 stages broke) is the strongest
  evidence type and lives in [`recipes/`](../recipes/), not here.
- **Updating README aggregates** — flag impact, don't edit.

## Static vs. hands-on, briefly

This loop is the **static deep-read** verification axis: read the
code, follow the calls, compare against the survey. It's repeatable
and fits a /loop iteration.

The **hands-on use** axis is recipe-driven: pick a recipe from
`recipes/`, build it, log what worked and what didn't, file as a PR
or recipe verification report (see `Contributing` in main README).
That's where claims like "ships in a weekend" or "8.2× token
reduction" get tested for real. Don't try to do that inside this loop —
recipe builds take hours to days, not loop iterations.
