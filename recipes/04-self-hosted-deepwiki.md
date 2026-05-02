# Recipe 04 — Self-hosted DeepWiki for a private repo

> Drop a private repo, get a navigable wiki + chat agent that cites file/line.
> Regenerated on every merge so onboarding stays current.

## Data flow

| # | Input | Transform | Output | Status |
|---|---|---|---|---|
| 1 | Private git repo URL (or local clone) | deepwiki-open: LLM-driven analysis → `WikiPage` / `WikiSection` schema with Mermaid architecture diagrams + per-module summaries | Generated markdown wiki + Mermaid diagrams (~5–15 min for medium repos) | 🟢 |
| 2 | Generated wiki markdown + raw source files | LightRAG indexes the wiki markdown natively; raw source files are fed in as text/markdown (LightRAG's documented source types are PDF/DOCX/PPTX/XLSX/text/markdown — not a code-aware indexer, so source is treated as plain text) | Hybrid index: wiki passages (high-level "what does this module do") + source-code passages indexed as text (low-level "where is X called") | 🟡 |
| 3 | User question | aider in `/ask` mode (read-only; `--read` mounts wiki + source as context) consults LightRAG retriever | Answer with `path:line` citations rendered in deepwiki-open's Next.js chat panel | 🟢 |
| 4 | `push: main` event | GitHub Action: rerun deepwiki-open + reindex LightRAG. **deepwiki-open has no incremental update** (line 39 of survey) — for large repos a custom diff-rebuild script only re-summarizes changed modules | Updated wiki + index, fresh on every merge | 🟢 |

## Build path

1. **Generate wiki** — `deepwiki-open --repo <url> --output ./wiki`. UI ships as Next.js 15 + React 19 + Mermaid frontend with `Ask` and `DeepResearch` features built in.
2. **Index both layers** — `lightrag index ./wiki ./src` with separate collections; queries can scope to one or both.
3. **Q&A** — start aider with `--read ./wiki/**/*.md ./src` and use `/ask` (the canonical read-only mode); aider returns citation-rich answers without trying to edit.
4. **CI regeneration** — GitHub Action on `push: main` regenerates wiki + reindex. For large repos write a diff-rebuild that only re-summarizes changed modules — that's the meaningful glue.

## Why this combo

deepwiki-open is the closest one-repo match — it ships UI, generation, and Q&A. Picking GitNexus alone gives you the graph but not the readable narrative; picking just LightRAG gives you Q&A but no onboarding artifact for humans. The combo gives both audiences (new hire reads wiki, agent queries graph).

## Glue you write

- GitHub Action YAML (~30 LoC)
- Incremental rebuild script (only re-summarize changed modules) — required for large repos since deepwiki-open lacks incremental support

## Signal

`needs.md` Scenario 4 — Strong (Devin DeepWiki rebuild HN Show, Davia, CodeBoarding, Glean engineering-onboarding agent).
