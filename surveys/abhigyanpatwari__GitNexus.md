# abhigyanpatwari/GitNexus

- **Stars:** 34,239 · **Last push:** 2026-05-02 · **Created:** 2025-08-02 (9 months old) · **License:** **PolyForm Noncommercial 1.0.0** (cohort first) · **Lang:** TypeScript (Node ≥20.19) · **Versions:** `gitnexus 1.6.3` (CLI/MCP); `gitnexus-web 0.0.0` (browser app, Vite)
- **Category:** wiki-compiler (6th cohort entry; "Zero-Server Code Intelligence Engine")
- **Author:** Abhigyan Patwari (single-author) · Commercial: [akonlabs.com](https://akonlabs.com) (SaaS + self-hosted Enterprise tier)
- **Tagline:** "Building nervous system for agent context. Like DeepWiki, but deeper. DeepWiki helps you *understand* code. GitNexus lets you *analyze* it — because a knowledge graph tracks every relationship, not just descriptions."

## TL;DR

A 3-package monorepo (`gitnexus/` CLI+MCP + `gitnexus-shared/` + `gitnexus-web/` browser viewer) that turns any GitHub repo or ZIP file into a code knowledge graph. **Two distinct deployment shapes** in one repo:
1. **CLI + MCP** — `gitnexus 1.6.3` npm package + 22 MCP tools (`list_repos` / `query` / etc.); the production-grade integration path for Cursor / Claude Code / Codex.
2. **Web UI** — Vite-built `gitnexus-web` that runs entirely in the browser (zero-server). Drop a GitHub URL or ZIP file in, get an interactive KG out.

**11 language extractors via config files** (c-cpp / csharp / dart / go / jvm / php / python / ruby / rust / swift / typescript-javascript) plus a **dedicated COBOL processor** (cohort first to ship COBOL — legacy-system code-modernization use case). **Vendored Leiden** community detection (cohort-novel — most cohort entries pull Leiden via graspologic). **Adaptive tree-sitter buffer sizing** (512 KB → 32 MB based on UTF-8 byte length × 2). **PolyForm Noncommercial 1.0.0** is the cohort's first restrictive non-commercial license (use freely for non-commercial; commercial requires akonlabs.com license).

## KB Architecture

### Two deployment shapes from one repo
- [`gitnexus/`](https://github.com/abhigyanpatwari/GitNexus/tree/main/gitnexus) — npm-distributed CLI + MCP server (`gitnexus 1.6.3`). PolyForm-Noncommercial. Subdirs: `cli/` + `config/` + `core/` + `lib/` + `mcp/` + `server/` + `storage/` + `types/` + `vendor/` (3 tree-sitter forks: dart / proto / swift) + `vendor/leiden/` (vendored Leiden).
- [`gitnexus-web/`](https://github.com/abhigyanpatwari/GitNexus/tree/main/gitnexus-web) — Vite + React browser app, runs **entirely client-side** (zero-server). Engines `node ^20.19 || >=22.12`. Playwright + Vitest test stack.
- [`gitnexus-shared/`](https://github.com/abhigyanpatwari/GitNexus/tree/main/gitnexus-shared) — shared types + utilities.
- Cohort first to ship a code-KG that runs entirely in the browser (vs server-shaped deepwiki-open, CLI-shaped code-review-graph, library-shaped graphify, plugin-shaped Understand-Anything / claude-obsidian).

### MCP server (22 tools)
- [`gitnexus/src/mcp/`](https://github.com/abhigyanpatwari/GitNexus/tree/main/gitnexus/src/mcp): `compatible-stdio-transport.ts` + `core/` + `local/` + `resources.ts` + `server.ts` + `staleness.ts` + `tools.ts`.
- [`tools.ts`](https://github.com/abhigyanpatwari/GitNexus/blob/main/gitnexus/src/mcp/tools.ts) defines **22 MCP tools** in `GITNEXUS_TOOLS: ToolDefinition[]` — each with `name`, `description`, and JSON Schema `inputSchema`. Tools include `list_repos`, `query` (execution-flow query), and 20 more (`context`, `impact`, etc. per the tool descriptions).
- Tool descriptions follow a structured 3-part contract: `WHEN TO USE: ...` + `AFTER THIS: ...` + situational context — cohort first to formalize the "what to do next" hint at the tool-description layer.
- Both **stdio MCP** (for Cursor / Claude Code / Codex) AND **HTTP MCP** (`server/mcp-http.ts`) — cohort second after sim's MCP-with-dual-transport for serving both transports out of one codebase.
- `.mcp.json` config at repo root for self-installation.
- `mcp/staleness.ts` — explicit MCP-tool staleness tracking (cohort first to surface "this tool's underlying data is stale" as MCP metadata).

### Core ingestion
- [`gitnexus/src/core/`](https://github.com/abhigyanpatwari/GitNexus/tree/main/gitnexus/src/core): `augmentation/` + `embedding-mode.ts` + `embeddings/` + `git-staleness.ts` + `graph/{graph,types}.ts` + `group/` + `ingestion/` + `lbug/` + `platform/` + `run-analyze.ts` + `search/` + `tree-sitter/parser-loader.ts` + `wiki/`.
- **11 language config files** for both call-extractors and class-extractors:
  - `gitnexus/src/core/ingestion/call-extractors/configs/` — `c-cpp.ts` / `csharp.ts` / `dart.ts` / `go.ts` / `jvm.ts` / `php.ts` / `python.ts` / `ruby.ts` / `rust.ts` / `swift.ts` / `typescript-javascript.ts`
  - `gitnexus/src/core/ingestion/class-extractors/configs/` — same 11 languages
  - **Cohort-novel "extractor as config file" pattern** — vs graphify's per-language Python functions (21 langs) and code-review-graph's centralized `EXTENSION_TO_LANGUAGE` table (32 langs). GitNexus's config-driven shape lets users add languages via TypeScript config without touching extractor code.
- **COBOL processor** at `gitnexus/src/core/ingestion/cobol/` + `cobol-processor.ts` — cohort first to ship COBOL support (legacy-system code-modernization use case; akonlabs.com may target enterprise mainframe migrations).
- `cluster-enricher.ts` + `community-processor.ts` + `entry-point-scoring.ts` — community-detection + ranking pipeline.
- `binding-accumulator.ts` + `call-processor.ts` + `call-routing.ts` + `call-types.ts` + `class-types.ts` + `emit-references.ts` — call-graph + reference resolution stack.
- `ast-cache.ts` — caches per-file AST for incremental re-runs.
- **Adaptive tree-sitter buffer sizing** (`constants.ts`):
  ```typescript
  TREE_SITTER_BUFFER_SIZE = 512 * 1024     // 512 KB minimum
  TREE_SITTER_MAX_BUFFER  = 32 * 1024 * 1024  // 32 MB cap
  getTreeSitterBufferSize(text) = clamp(byteLength * 2, 512KB, 32MB)
  ```
  Cohort first to ship adaptive buffer sizing for tree-sitter (handles large multibyte sources without OOM and without underbuffering ASCII).

### Vendored deps
- **`gitnexus/vendor/leiden/`** — bundled Leiden community detection. Cohort-novel: most cohort entries pull Leiden via graspologic (microsoft/graphrag, code-review-graph, graphify). GitNexus ships its own.
- **`tree-sitter-dart`**, **`tree-sitter-proto`**, **`tree-sitter-swift`** vendored — 3 in-house tree-sitter forks (dart / proto / swift were either too slow upstream or had bugs requiring patches).

### Wiki generation
- [`gitnexus/src/core/wiki/`](https://github.com/abhigyanpatwari/GitNexus/tree/main/gitnexus/src/core/wiki): `cursor-client.ts` + `generator.ts` + `graph-queries.ts` + `html-viewer.ts` + `llm-client.ts` + `prompts.ts`.
- Generates a navigable HTML wiki from the KG, queryable via Cursor's MCP client.

### Embeddings + augmentation
- [`gitnexus/src/core/embeddings/`](https://github.com/abhigyanpatwari/GitNexus/tree/main/gitnexus/src/core/embeddings) + `embedding-mode.ts` — embedding-config drift detection at ingest.
- [`gitnexus/src/core/augmentation/engine.ts`](https://github.com/abhigyanpatwari/GitNexus/blob/main/gitnexus/src/core/augmentation/engine.ts) — cross-language + cross-file augmentation pass.
- [`gitnexus/src/core/git-staleness.ts`](https://github.com/abhigyanpatwari/GitNexus/blob/main/gitnexus/src/core/git-staleness.ts) — git-commit-hash-based staleness detection (incremental re-analysis).

### Eval framework
- [`eval/`](https://github.com/abhigyanpatwari/GitNexus/tree/main/eval) — dedicated eval harness with `agents/` + `bridge/` + `environments/` + `tests/` + `utils/` + `configs/{modes,models}/` + `prompts/` + `analysis/`. Cohort second to ship a first-party eval framework (after deepset-ai/haystack's `evaluators` component category).

### Plugin / IDE distribution
- `.claude-plugin/` — Claude Code plugin manifest. Cohort second after claude-obsidian / claude-mem to be distributable as a Claude Code plugin.
- `.cursorrules`, `.windsurfrules` — Cursor + Windsurf integration hints at repo root.

### Specs / drafts (`.sisyphus/`)
- `.sisyphus/drafts/` directory — appears to be a spec/proposal system (named after Sisyphus = mythological figure pushing boulder uphill, suggests "long-running specs"). **Cohort-novel design-discipline pattern** — worth tracking if other cohort entries adopt similar persistent-spec storage.

### Anti-crypto disclaimer
- README opens with a prominent disclaimer: "GitNexus has NO official cryptocurrency, token, or coin. Any token/coin using the GitNexus name on Pump.fun or any other platform is **not affiliated with, endorsed by, or created by** this project". Cohort first; signals the project has attracted scam-token impersonation attempts.

## Notable design choices

- **Two deployment shapes from one repo (CLI+MCP and browser zero-server)** — cohort first to ship a wiki-compiler that BOTH runs as an MCP server for AI agents AND runs entirely in the browser. Different distribution channels (npm + Vite-built static site).
- **Browser-side / zero-server execution** (`gitnexus-web/`) — cohort first for a code-KG. Distinct shape vs deepwiki-open (FastAPI server), code-review-graph (PyPI CLI + MCP), graphify (Python skill bundle), Understand-Anything (TS Claude Code plugin), claude-obsidian (Obsidian-vault plugin).
- **Config-as-extractor pattern** — `call-extractors/configs/python.ts` etc. lets users add language support via TypeScript config rather than per-language Python/JS code. Cohort-novel approach to the language-extension problem (vs graphify's per-language functions, code-review-graph's centralized table).
- **COBOL processor** — cohort first. Targets the enterprise legacy-system code-modernization use case, fitting akonlabs.com's commercial positioning.
- **Vendored Leiden** instead of graspologic dep — cohort-novel. Suggests the team needed Leiden behavior that graspologic didn't provide, or wanted to avoid the Python dep in a TypeScript codebase.
- **Adaptive tree-sitter buffer sizing** (512 KB → 32 MB based on `byteLength × 2`) — cohort first explicit adaptive sizing logic to balance OOM-avoidance against underbuffering.
- **PolyForm Noncommercial 1.0.0 license** — cohort first restrictive non-commercial license. Different model from cohort's existing commercial-restriction licenses (ELv2 = host-as-SaaS-restricted, SSPL = host-as-SaaS-must-open-source-everything-around-it, AGPL = derivative-must-also-be-AGPL). PolyForm Noncommercial says "use freely for non-commercial; pay for commercial" — explicitly tier-pricing model. **Net cohort license tiers grow 8 → 9** with PolyForm Noncommercial added (after iter 61's tier count of 8).
- **Structured tool descriptions** with `WHEN TO USE / AFTER THIS / situational context` — cohort first formalization of next-action hints at MCP tool description layer.
- **MCP staleness tracking** (`mcp/staleness.ts`) — cohort first to surface "this tool's underlying data is stale" as MCP metadata.
- **Anti-crypto disclaimer** at README top — cohort first; reflects the reality that 34k-star projects attract scam-token impersonation.
- **Sisyphus-named spec system** (`.sisyphus/drafts/`) — cohort-novel design-discipline pattern.

## Dependencies

TS / Node ≥20.19. Workspace = monorepo with husky + lint-staged + prettier + eslint v9. CLI: tree-sitter (multiple language packs + 3 in-house forks) + commander/yargs (likely; not verified) + Vendored Leiden. Web: Vite + React + Playwright + Vitest. Shared utilities in `gitnexus-shared/`. PolyForm Noncommercial 1.0.0.

## Tradeoffs

- **For**: cohort-first **dual-deployment** (CLI+MCP for production AI integration, browser-side for zero-server exploration); cohort-first **COBOL processor** for legacy-system code modernization; cohort-first **config-as-extractor** pattern for language extension; cohort-first **adaptive tree-sitter buffer sizing**; cohort-first **MCP staleness tracking**; cohort-first **structured WHEN TO USE / AFTER THIS** tool descriptions; vendored Leiden (no graspologic dep); 22 MCP tools (broad MCP surface); active dev (commercial offering at akonlabs.com fundraises maintenance); 9-month-old project with ★34k = high traction; explicit eval framework (`eval/`); Claude Code plugin distribution.
- **Against**: **PolyForm Noncommercial 1.0.0** restricts commercial use — must purchase commercial license from akonlabs.com (most restrictive cohort license; even ELv2 / SSPL allow some commercial deployments). Single-author project (sustainability + bus-factor); 11-language extractor coverage narrower than graphify's 21 or code-review-graph's 32; vendored Leiden = team owns the maintenance cost; web app `version 0.0.0` = explicitly pre-release; no stable Python SDK; the structured tool descriptions are a step forward for AI-agent UX but not yet a documented standard cohort-wide.

## When to use vs. cohort

- vs. **AsyncFuncAI/deepwiki-open** ([survey](AsyncFuncAI__deepwiki-open.md)) — README explicitly positions: "Like DeepWiki, but deeper. DeepWiki helps you *understand* code. GitNexus lets you *analyze* it — because a knowledge graph tracks every relationship, not just descriptions." deepwiki-open is server-shaped wiki-compiler with FastAPI + adalflow + FAISS for any GitHub/GitLab/BitBucket repo. GitNexus is dual-deployment (CLI+MCP + browser) with code-KG tracking call/dependency relationships. Pick deepwiki-open when you want a hosted explainer wiki; pick GitNexus when you want an MCP-shaped code-graph for AI-agent integration or a zero-server browser exploration.
- vs. **tirth8205/code-review-graph** ([survey](tirth8205__code-review-graph.md)) — both are tree-sitter + MCP code-KGs. code-review-graph: 32 languages + SQLite + FTS5 + 22 MCP tools + auto-install into 11 AI tools. GitNexus: 11 languages via config + COBOL + browser zero-server + 22 MCP tools + dual transport. code-review-graph for "PyPI CLI you install per-AI-tool"; GitNexus for "browser zero-server OR npm CLI".
- vs. **safishamsi/graphify** ([survey](safishamsi__graphify.md)) — both are wiki-compilers with community detection (Leiden). graphify: Python library + 21 tree-sitter languages + 11 per-IDE skill bundles + typed edge confidence. GitNexus: TypeScript + 11 config-driven extractors + COBOL + browser-side. graphify for "skill-distributed Python pipeline"; GitNexus for "MCP-distributed TS dual-deployment".
- vs. **Lum1104/Understand-Anything** ([survey](Lum1104__Understand-Anything.md)) — Understand-Anything is TS Claude Code plugin with `.understand-anything/{knowledge-graph,meta,fingerprints,config}.json` filesystem layout. GitNexus is TS dual-deployment npm CLI + Vite browser app. Different distribution shapes within the wiki-compiler camp.
- vs. **claude-obsidian** ([survey](AgriciDaniel__claude-obsidian.md)) — Obsidian vault distributed as Claude Code plugin. GitNexus is npm + browser. claude-obsidian for personal-knowledge-graphs with Obsidian's editing UX; GitNexus for code-graphs with MCP integration.

## Code pointers

- 22 MCP tool definitions: [`gitnexus/src/mcp/tools.ts`](https://github.com/abhigyanpatwari/GitNexus/blob/main/gitnexus/src/mcp/tools.ts) (`GITNEXUS_TOOLS: ToolDefinition[]`).
- 11 language extractor configs (call): [`gitnexus/src/core/ingestion/call-extractors/configs/`](https://github.com/abhigyanpatwari/GitNexus/tree/main/gitnexus/src/core/ingestion/call-extractors/configs).
- 11 language extractor configs (class): [`gitnexus/src/core/ingestion/class-extractors/configs/`](https://github.com/abhigyanpatwari/GitNexus/tree/main/gitnexus/src/core/ingestion/class-extractors/configs).
- COBOL processor: [`gitnexus/src/core/ingestion/cobol/`](https://github.com/abhigyanpatwari/GitNexus/tree/main/gitnexus/src/core/ingestion/cobol) + [`cobol-processor.ts`](https://github.com/abhigyanpatwari/GitNexus/blob/main/gitnexus/src/core/ingestion/cobol-processor.ts).
- Vendored Leiden: [`gitnexus/vendor/leiden/`](https://github.com/abhigyanpatwari/GitNexus/tree/main/gitnexus/vendor/leiden).
- Adaptive tree-sitter buffer sizing: [`gitnexus/src/core/ingestion/constants.ts`](https://github.com/abhigyanpatwari/GitNexus/blob/main/gitnexus/src/core/ingestion/constants.ts) (`getTreeSitterBufferSize`).
- MCP server entry + dual transport: [`gitnexus/src/mcp/server.ts`](https://github.com/abhigyanpatwari/GitNexus/blob/main/gitnexus/src/mcp/server.ts) + [`server/mcp-http.ts`](https://github.com/abhigyanpatwari/GitNexus/blob/main/gitnexus/src/server/mcp-http.ts) + [`mcp/compatible-stdio-transport.ts`](https://github.com/abhigyanpatwari/GitNexus/blob/main/gitnexus/src/mcp/compatible-stdio-transport.ts).
- MCP staleness tracking: [`gitnexus/src/mcp/staleness.ts`](https://github.com/abhigyanpatwari/GitNexus/blob/main/gitnexus/src/mcp/staleness.ts).
- Wiki generator: [`gitnexus/src/core/wiki/{generator,graph-queries,html-viewer,llm-client,prompts,cursor-client}.ts`](https://github.com/abhigyanpatwari/GitNexus/tree/main/gitnexus/src/core/wiki).
- Augmentation engine: [`gitnexus/src/core/augmentation/engine.ts`](https://github.com/abhigyanpatwari/GitNexus/blob/main/gitnexus/src/core/augmentation/engine.ts).
- Browser app entry: [`gitnexus-web/`](https://github.com/abhigyanpatwari/GitNexus/tree/main/gitnexus-web) (Vite + React + Playwright/Vitest).
- Eval framework: [`eval/`](https://github.com/abhigyanpatwari/GitNexus/tree/main/eval).
- Architecture: [`ARCHITECTURE.md`](https://github.com/abhigyanpatwari/GitNexus/blob/main/ARCHITECTURE.md) (32K — substantial doc).
- Sisyphus drafts (specs): [`.sisyphus/drafts/`](https://github.com/abhigyanpatwari/GitNexus/tree/main/.sisyphus/drafts).
- Claude Code plugin manifest: [`.claude-plugin/`](https://github.com/abhigyanpatwari/GitNexus/tree/main/.claude-plugin).

## Open questions

- **PolyForm Noncommercial vs cohort license tiers** — does PolyForm Noncommercial pair with akonlabs.com's commercial license model in a way that's distinct from FastGPT's hybrid Apache+SaaS-restriction or onyx's MIT+EE pattern? Specifically: can a non-commercial researcher use GitNexus self-hosted, or does PolyForm Noncommercial define "non-commercial" narrowly?
- **Web app version `0.0.0`** — pre-release vs intentional. What's the path to web-app v1?
- **COBOL processor maturity** — single-author shipped COBOL = ambitious. What's the language-feature coverage vs e.g. `tree-sitter-cobol` upstream?
- **Sisyphus drafts** — what's the spec-storage schema? Is this an internal-only system or could it become a cohort design-discipline pattern (like memgraph's ADRs)?
- **Tool description's `WHEN TO USE / AFTER THIS` structure** — is there a documented spec, or is it a convention?
- **Anti-crypto disclaimer** — what triggered it? Worth tracking if other cohort entries add similar disclaimers as the AI-agent space matures.

---

*Audit 2026-05-02: clone-verified against [abhigyanpatwari/GitNexus@main](https://github.com/abhigyanpatwari/GitNexus) (last commit 2026-05-02 07:32). License confirmed `PolyForm Noncommercial 1.0.0` per `LICENSE` first line. Versions: `gitnexus 1.6.3` per `gitnexus/package.json`, `gitnexus-web 0.0.0` per `gitnexus-web/package.json`. 22 MCP tools verified by `grep -c "name:" gitnexus/src/mcp/tools.ts`. 11 language extractor configs verified by `ls gitnexus/src/core/ingestion/call-extractors/configs/` (c-cpp / csharp / dart / go / jvm / php / python / ruby / rust / swift / typescript-javascript). COBOL processor verified at `gitnexus/src/core/ingestion/cobol/` + `cobol-processor.ts`. Vendored Leiden + 3 tree-sitter forks (dart / proto / swift) verified by `ls gitnexus/vendor/`. Adaptive tree-sitter buffer sizing verified at `gitnexus/src/core/ingestion/constants.ts:1-30`. Tool description structure (`WHEN TO USE` / `AFTER THIS`) verified verbatim from `tools.ts:30-50`. Browser-side execution verified at `gitnexus-web/package.json` (Vite + Playwright + Vitest). Anti-crypto disclaimer verified verbatim from README.md line 1-2. Akonlabs commercial offering referenced at README.md ("Enterprise (SaaS & Self-hosted) - akonlabs.com"). Eval framework verified by `ls eval/`. ARCHITECTURE.md size verified (32465 bytes). Corrections: none (first-pass survey).*
