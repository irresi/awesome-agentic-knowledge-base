# mksglu/context-mode

- **Stars:** 11,882 · **Last push:** 2026-05-02 · **Created:** 2026-02-23 (~2.5 months — exceptional traction; **Hacker News #1 with 570+ points**) · **License:** **Elastic License 2.0** (3rd ELv2 cohort entry after byterover-cli + mindsdb) · **Lang:** TypeScript (Bun) · **Version:** `context-mode 1.0.103`
- **Category:** kb-app (MCP server for **context-window optimization** + tool-output sandboxing + session continuity)
- **Author:** Mert Köseoğlu

## TL;DR

A TypeScript / Bun MCP server that addresses **"the other half of the context problem"**: every MCP tool call dumps raw data into the context window (Playwright snapshot 56 KB, 20 GitHub issues 59 KB, one access log 45 KB → 40% of context gone in 30 minutes). context-mode solves it via **3 architectural primitives**:

1. **Tool-output sandboxing** — raw data stays in a sandbox, only summaries return to context. **315 KB → 5.4 KB = 98% reduction**.
2. **Session continuity** via SQLite + **FTS5 + BM25** retrieval — file edits / git ops / tasks / errors / user decisions tracked as events; on conversation compaction, retrieves only relevant events via search rather than dumping all data back.
3. **"Think in Code" paradigm** — `ctx_execute("javascript", ...)` lets the agent write a script and `console.log()` only the result, vs reading 50 files into context: *"47 × Read() = 700 KB. After: 1 × ctx_execute() = 3.6 KB."*

Ships **12 platform adapters** (`antigravity` / `claude-code` / `codex` / `cursor` / `gemini-cli` / `jetbrains-copilot` / `kiro` / `openclaw` / `opencode` / `qwen-code` / `vscode-copilot` / `zed`) + **14 platform configs** + per-platform **hooks** for `cursor` / `codex` / `vscode-copilot` / `jetbrains-copilot` / `kiro` / `gemini-cli`. **Cohort first to ship a context-engineering-as-MCP-server primitive** — distinct from cohort entries that treat context optimization as a side-effect of memory consolidation. Used at Microsoft / Google / Meta / Amazon / IBM / NVIDIA / ByteDance / Stripe / Datadog / Salesforce / GitHub / Red Hat / Supabase / Canva / Notion / Hasura / Framer / Cursor (per README badges, marketing claim). ELv2.

## KB Architecture

### Storage
- **SQLite** as the canonical event store (`session/db.ts`).
- **FTS5** full-text index (cohort-second after tirth8205/code-review-graph) for session-event retrieval.
- **BM25 ranking** at the search layer (`search/unified.ts`) — picks "only what's relevant" from the event log instead of dumping everything back into context.
- All session state ephemeral by default — *"If you don't `--continue`, previous session data is deleted immediately — a fresh session means a clean slate"*. Cohort first explicit "fresh session = clean slate" semantics.

### MCP server
- Single MCP server in TypeScript (`src/server.ts` + `src/cli.ts` entry).
- `ctx_execute(language, code)` — the "Think in Code" tool — agent writes a script, sandbox runs it, only `console.log()` output returns to context.
- 12 adapter implementations in `src/adapters/{antigravity,claude-code,codex,cursor,gemini-cli,jetbrains-copilot,kiro,openclaw,opencode,qwen-code,vscode-copilot,zed}/` + base classes (`base.ts` / `claude-code-base.ts` / `copilot-base.ts`) + `client-map.ts` + `detect.ts` (per-platform auto-detection).
- 14 platform configs in `configs/{antigravity,claude-code,codex,cursor,gemini-cli,jetbrains-copilot,kilo,kiro,openclaw,opencode,...}/` — config-as-platform-instance pattern.
- **Cohort widest agent-platform coverage**: 12 adapters + 14 configs span Claude Code / Codex / Cursor / Copilot (VS Code + JetBrains) / Gemini CLI / Kiro / OpenClaw / OpenCode / Qwen Code / Zed / Antigravity. (Compare graphify's 11 per-IDE skill files; sim's 14 self-modifying agent skills; code-review-graph's 11-tool auto-install.)

### Per-platform hooks
- `hooks/{core,codex,cursor,vscode-copilot,jetbrains-copilot,kiro,gemini-cli,formatters}/` plus standalone hook scripts at `hooks/`:
  - `pretooluse.mjs` / `posttooluse.mjs` / `precompact.mjs` / `sessionstart.mjs` / `userpromptsubmit.mjs` — Claude Code lifecycle hooks (cohort second after claude-mem to ship full Claude Code hooks suite).
  - `auto-injection.mjs` — automatic context injection on session boundaries.
  - `routing-block.mjs` — blocks tool routing under certain conditions.
  - `session-attribution.bundle.mjs` / `session-db.bundle.mjs` / `session-extract.bundle.mjs` / `session-snapshot.bundle.mjs` — bundled session-management modules.
  - `session-directive.mjs` / `session-helpers.mjs` / `session-loaders.mjs` — composable session utilities.
  - `suppress-stderr.mjs` + `ensure-deps.mjs` — defensive hooks.

### Session subsystem
- [`src/session/`](https://github.com/mksglu/context-mode/tree/main/src/session): `analytics.ts` + `db.ts` + `extract.ts` + `project-attribution.ts` + `snapshot.ts`.
- **Project-attribution** — events are tagged by which project they belong to (cohort first explicit project-attribution at the session-event layer).
- **Session snapshots** — point-in-time event-graph snapshots for replay / debugging.

### Search
- [`src/search/`](https://github.com/mksglu/context-mode/tree/main/src/search): `auto-memory.ts` + `unified.ts`.
- `unified.ts` is the BM25-over-FTS5 retriever.
- `auto-memory.ts` is automatic memory injection (likely runs on every prompt or per `userpromptsubmit.mjs` hook).

### "Think in Code" paradigm
- README: *"The LLM should program the analysis, not compute it. Instead of reading 50 files into context to count functions, the agent writes a script that does the counting and `console.log()`s only the result. One script replaces ten tool calls and saves 100x context. This is a mandatory paradigm across all 14 platforms: stop treating the LLM as a data processor, treat it as a code generator."*
- Cohort-novel framing — most cohort entries focus on memory storage / retrieval; context-mode focuses on **avoiding context allocation in the first place** by routing data-processing through code execution.

### Integration extensions
- `.openclaw-plugin/` — OpenClaw integration (cohort second after MemOS to ship explicit OpenClaw integration).
- `.claude-plugin/` — Claude Code plugin manifest.
- `.pi/` — pi-agent integration (cohort first).
- `.mcp.json` — MCP server config at repo root.
- `web/` — companion web UI.
- `insight/` — analytics dashboard module.

### Testing
- Test categories in `tests/`: `core` / `plugins` / `shared` / `adapters` / `hooks` / `fixtures` / `analytics` / `session`. 8 test categories — 2nd most decomposed after DocsGPT's 14.

### Documentation
- **64 KB README** — substantial doc with 4-phase problem framing.
- **`BENCHMARK.md`** — explicit benchmarking (98% reduction claim documented).
- **3 PRD docs** at repo root (`PR327-adapter-comparison.md` / `PRD-adapter-refactoring.md` / `PRD-base-adapter-extraction.md`) — cohort-novel public PRD-as-source-of-truth pattern (worth tracking).
- `CLAUDE.md` + `CONTRIBUTING.md`.

## Notable design choices

- **Context-engineering-as-MCP-server primitive** — context-mode reframes the cohort's typical "memory framework" question from "what do we store and retrieve?" to "what do we *avoid putting into context in the first place*?". Cohort first to make context-window optimization the headline architectural goal (vs cohort entries that treat context efficiency as a side-effect of memory consolidation).
- **"Think in Code" paradigm** — `ctx_execute(language, code)` as core MCP tool. Cohort first; reframes RAG as "agent programs the analysis" rather than "system fetches data". Pattern: when a workflow needs to process N files / records, generate a script and pipe only the result.
- **Tool-output sandboxing with 98% reduction claim** — backed by `BENCHMARK.md`. Cohort first concrete benchmark for tool-output context savings.
- **SQLite + FTS5 + BM25 session-event retrieval** — instead of dumping previous-session state on `--continue`, indexes events and retrieves only relevant ones per query. Cohort first event-indexed session-continuity pattern.
- **Fresh-session-as-clean-slate** semantics — without `--continue`, all previous session data is *deleted immediately*. Cohort first explicit fresh-session semantics (most cohort entries persist by default).
- **12 adapters + 14 configs spanning agent-platform ecosystem** — broadest agent-platform coverage in cohort (vs graphify's 11 skill bundles, sim's 14 self-modifying skills). Adapter + config split lets one adapter support multiple config flavors.
- **Per-platform Claude Code hooks suite** — full lifecycle (`pretooluse` / `posttooluse` / `precompact` / `sessionstart` / `userpromptsubmit`) + bundled session modules (`session-{attribution,db,extract,snapshot}.bundle.mjs`). Cohort second to ship full Claude Code hooks (after claude-mem); cohort first to ship per-platform-flavored hooks.
- **PRD-as-source-of-truth** pattern — 3 PRD documents at repo root (`PR327-adapter-comparison.md` + 2 PRDs) — explicit product-requirements docs in the repo. Cohort-novel design-discipline pattern — closest analogue is memgraph's 9 ADRs (architecture decision records); context-mode's PRDs are forward-looking product specs vs ADRs' backward-looking architecture decisions.
- **Hacker News #1 with 570+ points** — README explicitly badges this; cohort first to badge HN traction.
- **3rd ELv2 cohort entry** — joins byterover-cli + mindsdb. ELv2 cluster now spans memory-router (byterover-cli) + federated-data-engine (mindsdb) + context-engineering-MCP (context-mode). Pattern hardening: ELv2 = "MCP-shaped infra-layer agent tools wanting to block hosted-SaaS competitors".

## Dependencies

TypeScript / Node ≥18 (Bun preferred), `@modelcontextprotocol/sdk` (MCP SDK), SQLite (with FTS5 extension), Bun for build/runtime. Per-platform adapters depend on each platform's plugin/extension SDK. Single 552 KB pre-built `cli.bundle.mjs` for fast install.

## Tradeoffs

- **For**: cohort-first **context-engineering-as-MCP-server primitive**; cohort-first **"Think in Code" paradigm** (`ctx_execute`); cohort-first **98% context reduction** with `BENCHMARK.md`; cohort-first **SQLite + FTS5 + BM25 session-event retrieval**; cohort-first **fresh-session-as-clean-slate** semantics; cohort-widest **12 adapters + 14 platform configs**; cohort-first **per-platform-flavored Claude Code hooks**; cohort-novel **PRD-as-source-of-truth** doc pattern; **Hacker News #1**; ELv2 (3rd cohort entry); pre-built CLI bundle (fast install); 8-category test suite.
- **Against**: **ELv2 restricts SaaS hosting** without commercial license; very young project (2.5 months at ★11.9k) — sustainability + bus-factor risk; single-author project (Mert Köseoğlu); v1.0.103 patch-release cadence signals frequent micro-changes (fast moving target for production); per-platform hooks = 12-platform maintenance surface (each platform's plugin spec changes independently); the "98% reduction" claim depends on workload (large tool outputs benefit; small ones don't); the "Think in Code" paradigm requires sandbox runtime (`ctx_execute`) — adds JS/TS execution dependency; docs-heavy approach (64 KB README) suggests config complexity for self-hosters.

## When to use vs. cohort

- vs. **byterover-cli** ([survey](campfirein__byterover-cli.md)) — both are router-as-product (memory router vs context-engineering router); both ELv2; both target Claude Code + multi-platform AI coding agents. byterover-cli routes *memory backends* by `QueryType`; context-mode routes *tool output* through sandboxes + session-continuity FTS5/BM25.
- vs. **claude-mem** ([survey](thedotmack__claude-mem.md)) — claude-mem is Chroma+SQLite memory plugin for Claude Code with 8 SKILL.md skills + lifecycle hooks. context-mode is broader-scope context-engineering MCP for 12 platforms with sandboxing + "Think in Code" paradigm. claude-mem for "long-term memory across Claude Code sessions"; context-mode for "context-window optimization across the entire agent-platform ecosystem".
- vs. **anything-llm / sim / DocsGPT** (kb-apps with MCP) — anything-llm/sim/DocsGPT bundle MCP as one of many features; context-mode is MCP-as-product (context-engineering is THE feature). Different positioning: kb-apps for "deploy a knowledge base"; context-mode for "make any agent platform's context window 98% more efficient".
- vs. **MemTensor/MemOS** ([survey](MemTensor__MemOS.md)) — MemOS targets "research-grade memory framework" with ActivationMemory / ParametricMemory / TextualMemory tiers + MemCube abstractions. context-mode targets "production-grade context-engineering" with sandboxing + FTS5 + Think-in-Code. Adjacent niches: MemOS is research/academic; context-mode is enterprise/production with explicit benchmark claims.

## Code pointers

- MCP server entry: [`src/server.ts`](https://github.com/mksglu/context-mode/blob/main/src/server.ts).
- CLI entry: [`src/cli.ts`](https://github.com/mksglu/context-mode/blob/main/src/cli.ts) (built to `cli.bundle.mjs`).
- 12 platform adapters: [`src/adapters/`](https://github.com/mksglu/context-mode/tree/main/src/adapters) (antigravity / claude-code / codex / cursor / gemini-cli / jetbrains-copilot / kiro / openclaw / opencode / qwen-code / vscode-copilot / zed).
- 14 platform configs: [`configs/`](https://github.com/mksglu/context-mode/tree/main/configs).
- Per-platform Claude Code hooks: [`hooks/`](https://github.com/mksglu/context-mode/tree/main/hooks) (`pretooluse` / `posttooluse` / `precompact` / `sessionstart` / `userpromptsubmit` + bundled session modules).
- SQLite + FTS5 session DB: [`src/session/db.ts`](https://github.com/mksglu/context-mode/blob/main/src/session/db.ts).
- BM25 unified search: [`src/search/unified.ts`](https://github.com/mksglu/context-mode/blob/main/src/search/unified.ts).
- Auto-memory injection: [`src/search/auto-memory.ts`](https://github.com/mksglu/context-mode/blob/main/src/search/auto-memory.ts).
- Session subsystems: [`src/session/{analytics,db,extract,project-attribution,snapshot}.ts`](https://github.com/mksglu/context-mode/tree/main/src/session).
- Sandbox executor: [`src/executor.ts`](https://github.com/mksglu/context-mode/blob/main/src/executor.ts) + [`src/security.ts`](https://github.com/mksglu/context-mode/blob/main/src/security.ts).
- BENCHMARK.md (98% reduction claim): [`BENCHMARK.md`](https://github.com/mksglu/context-mode/blob/main/BENCHMARK.md).
- 3 PRD documents: [`PR327-adapter-comparison.md`](https://github.com/mksglu/context-mode/blob/main/PR327-adapter-comparison.md) + [`PRD-adapter-refactoring.md`](https://github.com/mksglu/context-mode/blob/main/PRD-adapter-refactoring.md) + [`PRD-base-adapter-extraction.md`](https://github.com/mksglu/context-mode/blob/main/PRD-base-adapter-extraction.md).
- Plugin manifests: [`.claude-plugin/`](https://github.com/mksglu/context-mode/tree/main/.claude-plugin) + [`.openclaw-plugin/`](https://github.com/mksglu/context-mode/tree/main/.openclaw-plugin) + [`.pi/`](https://github.com/mksglu/context-mode/tree/main/.pi).

## Open questions

- **`ctx_execute` security model** — what's the sandbox isolation mechanism? `src/security.ts` exists but the README doesn't detail the threat model. Is this Node `vm` module / Deno-style / Wasmtime?
- **98% reduction claim methodology** — `BENCHMARK.md` documents the claim but what's the baseline workload? Is it representative or cherry-picked?
- **Per-platform adapter divergence** — 12 platforms × N hook-spec versions = combinatorial maintenance. How does the team prevent drift?
- **PRD-as-source-of-truth maturity** — 3 PRDs at repo root (vs memgraph's 9 ADRs). Is this an emerging cohort design-discipline pattern, or a one-off?
- **HN #1 longevity** — Hacker News #1 with 570+ points (per README badge). When? Will the traction sustain?

---

*Audit 2026-05-03: clone-verified against [mksglu/context-mode@main](https://github.com/mksglu/context-mode) (last commit 2026-05-02 06:36). License confirmed: **Elastic License 2.0** per `LICENSE` first line + `package.json` (`"license": "Elastic-2.0"`). Version `context-mode 1.0.103` per `package.json`. 12 platform adapters verified by `ls src/adapters/` excluding `.ts` files (antigravity / claude-code / codex / cursor / gemini-cli / jetbrains-copilot / kiro / openclaw / opencode / qwen-code / vscode-copilot / zed). 14 platform configs verified by `ls configs/`. Per-platform hooks verified by `ls hooks/` (codex / cursor / vscode-copilot / jetbrains-copilot / kiro / gemini-cli + core + formatters). SQLite + FTS5 + BM25 verified by `ls src/{search,session}/` + `package.json` keywords (`fts5`, `bm25`). 98% reduction claim verified verbatim from README "Context Saving" section. "Think in Code" paradigm + `ctx_execute("javascript", ...)` example verified verbatim from README. Hacker News #1 + 570+ points verified verbatim from README badge. 3 PRD docs verified by `ls *.md`. Pre-built `cli.bundle.mjs` (552 KB) verified by `ls -la`. Session subsystem (analytics / db / extract / project-attribution / snapshot) verified by `ls src/session/`. Plugin manifests (.claude-plugin / .openclaw-plugin / .pi) verified by `ls -la`. Corrections: none (first-pass survey).*
