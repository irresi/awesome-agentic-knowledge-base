# Survey: Lum1104/Understand-Anything

**Date:** 2026-05-01
**Stars:** 9,565 · **Last push:** 2026-05-01 · **Created:** 2025 · **Version:** `@understand-anything/skill 2.4.0` · **License:** MIT
**Category:** wiki-compiler
**Slug:** [Lum1104/Understand-Anything](https://github.com/Lum1104/Understand-Anything)

---

## TL;DR (3 lines)

- **What it is:** First wiki-compiler in this cohort. A **Claude Code plugin** (also runs on Codex / Cursor / Copilot / Gemini CLI / OpenCode via `model: inherit`) that analyzes a codebase with a multi-agent pipeline and produces an interactive knowledge graph + React/React-Flow dashboard. TypeScript pnpm monorepo, MIT licensed.
- **How its KB works:** **No database, no vector backend, no MCP.** Everything lives in the analyzed project's `.understand-anything/` directory: `knowledge-graph.json` (the KG), `meta.json` (analysis metadata + git commit hash), `fingerprints.json` (incremental change detection), `config.json`. Tree-sitter (via `web-tree-sitter` WASM) extracts per-language structure; LLM agents add semantic edges; `embedding-search.ts` does pure-JavaScript cosine similarity over embeddings stored on graph nodes.
- **Verdict:** Pick when you want a **single-command codebase wiki** that runs inside any LLM coding harness, ships a beautiful React dashboard, and never asks you to spin up a vector DB or a server. Skip if you need a long-running KB service, conversational memory, or non-codebase content (the schema is code-shaped — 35 edge types include `imports`, `calls`, `inherits`, `tested_by`, `routes`, `migrates`, etc.).

## KB Architecture

### Storage
- **Vector store:** *None.* Embeddings are stored as `number[]` arrays directly on `GraphNode` records inside `knowledge-graph.json`. [`embedding-search.ts`](https://github.com/Lum1104/Understand-Anything/blob/main/understand-anything-plugin/packages/core/src/embedding-search.ts) implements `cosineSimilarity` in 15 lines of vanilla JS — no Faiss / HNSW / sqlite-vec dependency.
- **Graph store:** *None external.* The KG is a plain JSON document with `nodes` + `edges` arrays validated against a Zod schema ([`schema.ts`](https://github.com/Lum1104/Understand-Anything/blob/main/understand-anything-plugin/packages/core/src/schema.ts)) — **35 edge types in 9 categories**: Structural (`imports`/`exports`/`contains`/`inherits`/`implements` — 5), Behavioral (`calls`/`subscribes`/`publishes`/`middleware` — 4), Data flow (`reads_from`/`writes_to`/`transforms`/`validates` — 4), Dependencies (`depends_on`/`tested_by`/`configures` — 3), Semantic (`related`/`similar_to` — 2), Infrastructure (`deploys`/`serves`/`provisions`/`triggers` — 4), Schema/Data (`migrates`/`documents`/`routes`/`defines_schema` — 4), Domain (`contains_flow`/`flow_step`/`cross_domain` — 3), Knowledge (`cites`/`contradicts`/`builds_on`/`exemplifies`/`categorized_under`/`authored_by` — 6).
- **Metadata / structured:** Four JSON files in the project's `.understand-anything/` directory. No DB.
- **Object / blob:** *None.* Source content is fetched on demand by the dashboard's dev server from a `/file-content.json` endpoint, gated by an access token plus a graph-derived path allowlist.

### Ingestion / Extraction
- **Source types accepted:** **Source code in 39 languages and formats** — [`languages/configs/`](https://github.com/Lum1104/Understand-Anything/tree/main/understand-anything-plugin/packages/core/src/languages/configs) contains: c, cpp, csharp, css, csv, docker-compose, dockerfile, env, github-actions, go, graphql, html, java, javascript, jenkinsfile, json-config, json-schema, kotlin, kubernetes, lua, makefile, markdown, openapi, php, plaintext, powershell, protobuf, python, restructuredtext, ruby, rust, shell, sql, swift, terraform, toml, typescript, xml, yaml. **Per-framework metadata** for django, express, fastapi, flask, gin, nextjs, rails, react, spring, vue.
- **Chunking strategy:** **File-as-unit** (no token-based chunking). Per-language tree-sitter extractors in [`plugins/extractors/`](https://github.com/Lum1104/Understand-Anything/tree/main/understand-anything-plugin/packages/core/src/plugins/extractors) (cpp, csharp, go, java, php, python, ruby, rust, typescript) emit structural nodes (functions, classes, modules); non-code parsers in [`plugins/parsers/`](https://github.com/Lum1104/Understand-Anything/tree/main/understand-anything-plugin/packages/core/src/plugins/parsers) (dockerfile, env, graphql, json, makefile, markdown, protobuf, shell, sql, terraform, toml, yaml) emit metadata nodes.
- **Entity / fact extraction:** **Two-phase**: (1) deterministic structural extraction via tree-sitter scripts (`extract-structure.mjs` bundled in the `understand` skill), (2) LLM semantic enrichment by 9 agent definitions in [`agents/*.md`](https://github.com/Lum1104/Understand-Anything/tree/main/understand-anything-plugin/agents) — `project-scanner`, `file-analyzer`, `architecture-analyzer`, `domain-analyzer`, `article-analyzer`, `knowledge-graph-guide`, `tour-builder`, `graph-reviewer`, `assemble-reviewer`. Agents write intermediate results to `.understand-anything/intermediate/` on disk (not returned to the calling agent's context — keeps token budget small) and the orchestrator merges via `merge-batch-graphs.py` / `merge-subdomain-graphs.py`.
- **Schema:** Strongly typed via Zod. **Node-type aliases** (`func`/`fn`/`method` → `function`; `interface`/`struct` → `class`; `mod`/`pkg`/`package` → `module`; `container`/`deployment`/`pod` → `service`) auto-normalize what LLMs commonly emit.

### Retrieval
- **Modes:** Cosine semantic search ([`embedding-search.ts`](https://github.com/Lum1104/Understand-Anything/blob/main/understand-anything-plugin/packages/core/src/embedding-search.ts)) + structural traversal ([`search.ts`](https://github.com/Lum1104/Understand-Anything/blob/main/understand-anything-plugin/packages/core/src/search.ts)) + dashboard-side React Flow visual exploration. The dashboard ships a 75 % graph + 360 px sidebar layout; sidebar tabs are `Info` and `Files`; node click slides up a prism-react-renderer source viewer.
- **Reranker:** *None.* Schema validation on graph load surfaces invalid nodes/edges via an error banner; otherwise raw cosine ranking.
- **Top-k defaults:** Configured per `SemanticSearchOptions` (`limit`, `threshold`, `types` filter); no global default.
- **Context assembly:** `context-builder.ts` composes node + neighbor context for the `understand-chat` skill. The chat is graph-aware — selecting a node in the dashboard scopes follow-up questions to that node's neighborhood.

### Memory model
- **Tiers:** Just one — the knowledge graph. No conversational memory, no atomic-fact tier, no user/session model. **Cohort first**: a wiki-compiler is *not* a memory framework.
- **Bi-temporal:** No.
- **Self-update mechanism:** **Two hooks in [`hooks/hooks.json`](https://github.com/Lum1104/Understand-Anything/blob/main/understand-anything-plugin/hooks/hooks.json)**:
  - **`PostToolUse`** — runs after every Bash invocation; if the command matches `git (commit|merge|cherry-pick|rebase)` AND `.understand-anything/config.json:autoUpdate==true` AND `knowledge-graph.json` exists, prints a stop-message to the LLM telling it to read `${CLAUDE_PLUGIN_ROOT}/hooks/auto-update-prompt.md` and incrementally update the graph **without asking the user**.
  - **`SessionStart`** — checks if `meta.json:gitCommitHash` differs from current `git rev-parse HEAD`; if stale, the same auto-update prompt fires.
  - Both use shell `&&` chains and `|| true` to silently no-op when conditions aren't met. Cohort first — most repos that ship hooks (claude-mem) hook lifecycle events; this one hooks *agent tool use* + session start to keep the graph fresh against git.
- **Decay / forgetting:** None. Graph is per-project, persisted alongside the code.

### MCP / connectors
- **MCP server exposed:** **No.**
- **MCP client used:** **No.** The plugin runs as a *Claude Code* / Codex / Cursor / Copilot / Gemini-CLI / OpenCode plugin — agents are dispatched via the host's Task tool, not MCP. Cohort first for "I'm a tool that runs inside agent harnesses, not a service that agents call."
- **Native connectors:** None — input is the local filesystem.
- **Tool-call surface:** **8 slash-command skills** in [`skills/`](https://github.com/Lum1104/Understand-Anything/tree/main/understand-anything-plugin/skills) — each is a directory with a `SKILL.md` (Claude Code skill format with `name` / `description` / `argument-hint` frontmatter):
  - `/understand` — full analysis (auto-triggers `/understand-dashboard` after completion).
  - `/understand-chat` — chat over the graph.
  - `/understand-diff` — analyze changes.
  - `/understand-domain` — domain-level analyses.
  - `/understand-explain` — explain a node.
  - `/understand-knowledge` — knowledge graph for arbitrary content.
  - `/understand-onboard` — onboarding tour generation.
  - `/understand-dashboard` — open the React dashboard.
- **Privacy guard:** [`persistence/index.ts`](https://github.com/Lum1104/Understand-Anything/blob/main/understand-anything-plugin/packages/core/src/persistence/index.ts) sanitizes every node's `filePath` on write — paths inside `projectRoot` become relative; absolute paths *outside* `projectRoot` are reduced to filename only; relative paths pass through unchanged. Username, home-directory, and company-directory layouts never enter `knowledge-graph.json`.

### Notable design choices
- **`.claude-plugin/plugin.json` distribution** — installs as a Claude Code plugin and rides Anthropic's plugin loader; cross-platform via `model: inherit` so Codex / Cursor / Copilot / Gemini CLI / OpenCode all work.
- **Multi-agent extraction with on-disk intermediates** — agents write to `.understand-anything/intermediate/` rather than returning megabytes of structured data through the host's tool-call channel. Orchestrator merges with `merge-batch-graphs.py` / `merge-subdomain-graphs.py`. Keeps the host's context window unpolluted.
- **Pure-JS cosine search** — no FFI, no native modules, no WASM (other than tree-sitter). Browser-safe core via subpath exports (`./search`, `./types`, `./schema`) so the dashboard can import without dragging Node.js modules into the browser bundle.
- **`web-tree-sitter` (WASM) instead of native bindings** — explicitly cited in `CLAUDE.md` as a workaround for darwin/arm64 + Node 24 build failures. Cohort first.
- **35-edge-type schema in 9 categories** spanning code structure, dependencies, infra, schema, domain, AND knowledge ontology — designed for code *and* docs.
- **Node-type aliasing layer** that absorbs LLM variability — `func`/`fn`/`method` → `function` etc. Most explicit "LLM output normalization" in cohort.
- **Two-hook auto-update** — `PostToolUse` on git commits + `SessionStart` staleness check. Other repos with hooks (claude-mem) hook conversation lifecycle; this one hooks **tool use + session start** to track the user's git activity.
- **Dashboard is graph-first** — 75 % React-Flow + 360 px Info/Files sidebar; "dark luxury theme" with `#0a0a0a` and `#d4a574` (gold) + DM Serif Display typography. Source viewer slides up from the bottom on file-node click; access-token + path-allowlist gate file content fetches in the dev server.
- **`knowledge-graph-guide` agent** — explicit prompt-engineering for "how to grow the graph well" — the cohort's only agent that documents *graph hygiene* as a first-class concern.
- **`scripts/generate-large-graph.mjs`** — synthetic-graph generator (default 3000 nodes) for performance-testing the dashboard. Layout / pan / zoom is benchmarked separately from analysis.

## Dependencies (KB-relevant)

From `understand-anything-plugin/package.json` (root) + `packages/core/package.json`:

```
# Plugin meta
"name": "@understand-anything/skill"
"version": "2.4.0"
"type": "module"
Node ≥ 22 (developed on v24)
pnpm ≥ 10 (pinned via packageManager)

# Core
"@understand-anything/core": "workspace:*"
zod                                    # schema validation
web-tree-sitter (WASM)                 # tree-sitter via WASM
typescript ^5.7.0
vitest ^3.1.0

# Dashboard (packages/dashboard)
react, react-flow, zustand, tailwindcss v4
prism-react-renderer                    # source viewer
vite

# Schema (35 edge types in 8 categories)
EdgeTypeSchema = z.enum([
  "imports","exports","contains","inherits","implements",
  "calls","subscribes","publishes","middleware",
  "reads_from","writes_to","transforms","validates",
  "depends_on","tested_by","configures",
  "related","similar_to",
  "deploys","serves","provisions","triggers",
  "migrates","documents","routes","defines_schema",
  "contains_flow","flow_step","cross_domain",
  "cites","contradicts","builds_on","exemplifies","categorized_under","authored_by",
])
```

License: **MIT**.

## Tradeoffs

**Pros:**
- **Zero infrastructure** — no DB, no vector store, no server, no MCP. The KB is JSON files in a `.understand-anything/` directory.
- **Cross-harness portability** — works on Claude Code, Codex, Cursor, Copilot (CLI + VS Code), Gemini CLI, OpenCode out of the box (`model: inherit`).
- **35-edge-type schema with node-type aliasing** — explicit LLM-output normalization that other graph-extracting repos (graphrag, mem0) leave to the prompt.
- **Two well-targeted hooks** — `PostToolUse` (on git commit) + `SessionStart` (staleness check) keep the graph fresh without daemons or cron.
- **Dashboard is genuinely interactive** — React Flow + Zustand + access-token-gated source viewer with prism syntax highlighting.
- **Privacy guard on every write** — `filePath` sanitization protects user/company directory layouts before serialization.
- **Multi-agent extraction with on-disk intermediates** — keeps host's context budget small even on huge codebases.
- **Pure-JS cosine + browser-safe subpath exports** — dashboard can import core without Node modules sneaking into the bundle.

**Cons:**
- **No conversation memory, no MCP, no service mode** — this is a per-project compiler, not a runtime KB. If you need agent memory or a long-running service, this isn't it.
- **Schema is code-shaped** — 35 edge types skew code/infra/schema-heavy; non-code KGs (e.g., literature, business processes) would map awkwardly to `imports`/`calls`/`tested_by`/`routes`/`migrates`.
- **No reranker, no hybrid retrieval** — cosine on JSON-stored embeddings is good enough for graph navigation, but won't beat OpenSearch/Vespa on large corpora.
- **Single vector implementation (cosine in JS)** — no FAISS/HNSW path; for very large graphs (10k+ nodes) the dashboard's `generate-large-graph.mjs` test exists for a reason.
- **Plugin model couples lifecycle to the host harness** — if Claude Code changes its plugin spec, the loader needs to follow.
- **Heavy reliance on `model: inherit`** — non-Claude harnesses get whatever model the user has configured; behavior varies.
- **Auto-update hook fires on every Bash tool use** — small constant cost in agent loops even when no commit happens (`grep -qE 'git\\s+(commit|merge|...)'` runs each time).

## When to use it

- **Good fit:** new-team onboarding ("the codebase is 200k LoC, where do I start?"); periodic architecture reviews; up-to-date code wikis that don't need a service to host them; multi-language monorepos where polyglot extractors matter; any LLM-harness workflow where you want one slash command to materialize and refresh a wiki.
- **Bad fit:** chat-memory frameworks; long-running KB services; non-code knowledge (use [`getzep/graphiti`](surveys/getzep__graphiti.md) or [`topoteretes/cognee`](surveys/topoteretes__cognee.md) instead); products that need an MCP server interface.
- **Closest alternative:** [`microsoft/graphrag`](surveys/microsoft__graphrag.md) — same "extract a graph and query it" thesis but for unstructured documents (CSV/JSON/MD/Parquet) rather than codebases, and Python pipeline rather than TypeScript plugin. Tencent's [`Auto-Wiki`](surveys/Tencent__WeKnora.md) feature inside WeKnora overlaps on the "build a navigable wiki" outcome but is server-shaped + KB-content-shaped rather than codebase-shaped. The other wiki-compiler candidates queued in this curation (`atomicmemory/llm-wiki-compiler`, `lucasastorian/llmwiki`) are smaller-star — to be surveyed for direct comparison.

## Code pointers (evidence)

- Schema (35 edge types + node aliases): [`packages/core/src/schema.ts`](https://github.com/Lum1104/Understand-Anything/blob/main/understand-anything-plugin/packages/core/src/schema.ts)
- Persistence layer with privacy-preserving path sanitization: [`packages/core/src/persistence/index.ts`](https://github.com/Lum1104/Understand-Anything/blob/main/understand-anything-plugin/packages/core/src/persistence/index.ts)
- Pure-JS cosine semantic search: [`packages/core/src/embedding-search.ts`](https://github.com/Lum1104/Understand-Anything/blob/main/understand-anything-plugin/packages/core/src/embedding-search.ts)
- Tree-sitter (WASM) plugin orchestration: [`packages/core/src/plugins/`](https://github.com/Lum1104/Understand-Anything/tree/main/understand-anything-plugin/packages/core/src/plugins) (`tree-sitter-plugin.ts`, `discovery.ts`, `registry.ts`, `extractors/`, `parsers/`)
- Per-language language-registry + per-framework registries: [`packages/core/src/languages/`](https://github.com/Lum1104/Understand-Anything/tree/main/understand-anything-plugin/packages/core/src/languages) (`configs/`, `frameworks/`, `language-registry.ts`, `framework-registry.ts`)
- 9 agent definitions: [`agents/`](https://github.com/Lum1104/Understand-Anything/tree/main/understand-anything-plugin/agents) (`project-scanner.md`, `file-analyzer.md`, `architecture-analyzer.md`, `domain-analyzer.md`, `article-analyzer.md`, `knowledge-graph-guide.md`, `tour-builder.md`, `graph-reviewer.md`, `assemble-reviewer.md`)
- 8 slash-command skills: [`skills/`](https://github.com/Lum1104/Understand-Anything/tree/main/understand-anything-plugin/skills) — each with a `SKILL.md` (`name`/`description`/`argument-hint` frontmatter)
- Two hooks (`PostToolUse` on git commits + `SessionStart` staleness check): [`hooks/hooks.json`](https://github.com/Lum1104/Understand-Anything/blob/main/understand-anything-plugin/hooks/hooks.json) + [`hooks/auto-update-prompt.md`](https://github.com/Lum1104/Understand-Anything/blob/main/understand-anything-plugin/hooks/auto-update-prompt.md)
- Dashboard (React + Vite + React Flow + Zustand): [`packages/dashboard/`](https://github.com/Lum1104/Understand-Anything/tree/main/understand-anything-plugin/packages/dashboard)
- Skill TS source for chat / diff / explain / onboard: [`src/`](https://github.com/Lum1104/Understand-Anything/tree/main/understand-anything-plugin/src) (`context-builder.ts`, `diff-analyzer.ts`, `explain-builder.ts`, `onboard-builder.ts`, `understand-chat.ts`)
- Most useful single file to read first: [`CLAUDE.md`](https://github.com/Lum1104/Understand-Anything/blob/main/CLAUDE.md) — concise architecture overview written for AI agents, explains both the monorepo layout and the gotchas (web-tree-sitter, browser-safe subpath exports).

## Open questions

- The `assemble-reviewer` + `graph-reviewer` agents are described as quality gates; how do they handle disagreements between batch-level file-analyzer outputs and the architecture-level summary?
- What's the ceiling on graph size before the dashboard's React Flow layout becomes unusable? `generate-large-graph.mjs` defaults to 3000 nodes — what's the empirical UX limit?
- The `understand-knowledge` skill suggests "knowledge graph for arbitrary content" — does it use a different schema variant for non-code KGs, or do code-shaped edge types map awkwardly?
- Auto-update hook fires on every Bash invocation; have they considered `pre-push` git-hook integration as an alternative trigger to reduce constant overhead?
- Cosine-in-JS is fine for under 10k nodes; is there a planned path to HNSW or sqlite-vec for very large repos, or is the dashboard's interaction model intentionally bounded?

---

*Surveyed via the `curating-agentic-kbs` skill. Re-survey scheduled after 30 days of last `pushed_at` change.*

*Audit 2026-05-02: clone-verified against [`understand-anything-plugin/packages/core/src/schema.ts`](https://github.com/Lum1104/Understand-Anything/blob/main/understand-anything-plugin/packages/core/src/schema.ts) (35 edge types in **9 categories** — survey originally said 8), [`packages/core/src/languages/configs/`](https://github.com/Lum1104/Understand-Anything/tree/main/understand-anything-plugin/packages/core/src/languages/configs) (**39 language files**, not "30+"), [`agents/`](https://github.com/Lum1104/Understand-Anything/tree/main/understand-anything-plugin/agents) (9 agents), [`skills/`](https://github.com/Lum1104/Understand-Anything/tree/main/understand-anything-plugin/skills) (8 slash commands), [`hooks/hooks.json`](https://github.com/Lum1104/Understand-Anything/blob/main/understand-anything-plugin/hooks/hooks.json) (PostToolUse + SessionStart), [`package.json`](https://github.com/Lum1104/Understand-Anything/blob/main/understand-anything-plugin/package.json) (v2.4.0). **Corrections:** edge categories **8 → 9** (Knowledge was missed as a separate category — survey grouped 9 categories under 8 in the count); language list — **removed `scala`** (not present in actual configs/), **added `restructuredtext` + `xml`** (present but missing from survey); language count "30+" → **39 actual files** (excluding `batch.ts` and `index.ts` helpers). **Verified verbatim:** 35 edge types (exact list), 9 agents (architecture-analyzer / article-analyzer / assemble-reviewer / domain-analyzer / file-analyzer / graph-reviewer / knowledge-graph-guide / project-scanner / tour-builder), 8 slash commands, 2 hooks (PostToolUse on `git (commit|merge|cherry-pick|rebase)` + SessionStart staleness check via `meta.json:gitCommitHash` vs `git rev-parse HEAD`), node-type aliases for `func/fn/method/interface/struct/...`, version 2.4.0, MIT license.*
