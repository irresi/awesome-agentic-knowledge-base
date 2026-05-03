# Survey re-audit playbook

One iteration = re-verify exactly **one** cohort survey against the
current state of its cloned source. Pick the stalest, walk every
quantified claim through the clone, edit corrections inline, append a
`*Re-audit YYYY-MM-DD ...*` footer, commit, push.

## /loop invocation

```bash
/loop scripts/re-audit.md
```

Each tick of the loop runs one full pass below; the next tick picks
the next stalest survey.

## Per-iteration steps

### 1. Pick

```bash
slug=$(scripts/pick-stale-survey.sh)
echo "$slug"
```

This prints the survey with the oldest `*Audit YYYY-MM-DD*` or
`*Re-audit ... YYYY-MM-DD*` footer date. If the loop already ran today
and you want to skip already-audited entries, manually pick a different
slug.

### 2. Refresh clone

```bash
scripts/clone-cohort.sh "$slug"
```

Idempotent: existing clones get `git fetch + reset --hard` to current
HEAD; missing ones get a shallow clone.

### 3. Walk the survey claim-by-claim

Read `surveys/$slug.md` top-to-bottom and verify every quantified or
named claim against `surveys/_clones/$slug/`. The categories worth
checking, in priority order:

| Claim type | How to verify |
|---|---|
| Star count | `gh api "repos/${slug//__//}" --jq .stargazers_count` |
| Last push date | `gh api "repos/${slug//__//}" --jq .pushed_at` |
| Version pin | read `pyproject.toml` / `package.json` / `Cargo.toml` / `*.toml` |
| License | `head -1 surveys/_clones/$slug/LICENSE*` |
| Specific file path | `ls surveys/_clones/$slug/<path>` |
| Class / function name | `grep -rn "class <Name>" surveys/_clones/$slug/` |
| Integration count (e.g. "78 vector stores") | `ls surveys/_clones/$slug/<integrations-dir>/ \| wc -l` |
| Dependency claim | `grep '<dep>' surveys/_clones/$slug/pyproject.toml` |
| Architecture detail (event names, table counts, ORM rows) | `grep -rn` for the exact identifier |

Anything quantitative ("**21 tree-sitter language deps baked in**",
"**4 KB header + WAL + zstd/lz4 segments**") MUST be re-verified — that
specificity is the survey's value proposition. Vague qualitative claims
("mature ecosystem", "production-shaped") can be skipped.

### 4. Look for missing key facts

After verifying existing claims, scan briefly for things the survey
*should* mention but doesn't:

- Top-level `README.md` headers — any major capability not in the survey?
- `CHANGELOG.md` — recent major version with new architecture?
- New top-level directories — new subsystem since last audit?
- New first-party adapters / integrations — added since last audit?

Add as a "newly noticed" line in the footer rather than rewriting the
body, unless the omission is a structural miss.

### 5. Edit + footer

If anything is wrong, fix it inline in the survey body (correct
numbers, update file paths, fix names).

Then append a footer line. Format:

```markdown
*Re-audit YYYY-MM-DD iter N (against [<slug>@<short-sha>](https://github.com/<slug>/tree/<sha>)): Verified — <key claim 1>, <key claim 2>, ... · Corrections — <change 1>, <change 2>. Added — <new fact>. Star count <old> → <new>.*
```

If nothing needed correction, still append a confirmation footer:

```markdown
*Re-audit YYYY-MM-DD iter N: no corrections needed; <key claims> re-verified against current main. Star count <old> → <new>.*
```

The iteration counter (`iter N`) is per-survey — count up by reading
the previous footer (graphiti is at iter 64, llama_index at iter 1).

### 6. Commit

If the survey changed:

```bash
git add "surveys/$slug.md"
git commit -m "Re-audit $slug (iter N): <one-line summary of changes>"
git push
```

If only the audit timestamp / iter counter changed and nothing
substantive:

```bash
git commit -m "Re-audit $slug (iter N): no corrections, claims re-verified"
git push
```

### 7. Stop

One survey per iteration. The loop's next tick picks the new stalest
entry.

## What this loop is *not* for

- **Adding new repos** — that's the `curating-agentic-kbs` skill's job.
- **Restructuring surveys** — bigger refactors should be separate PRs,
  not loop output.
- **Updating the main README aggregates** (TL;DR, Adoption tables) —
  if a re-audit invalidates a cohort-wide claim (e.g. a graph store
  count), flag it in the footer with `Cohort-aggregate impact: ...`
  and let a human do the README pass.
