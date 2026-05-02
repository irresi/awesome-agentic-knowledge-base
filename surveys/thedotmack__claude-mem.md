# Survey: thedotmack/claude-mem

**Date:** 2026-05-01
**Stars:** 70,480 · **Last push:** 2026-05-01 · **Created:** 2025-08-15 · v12.4.9
**Category:** coding-agent (memory plugin)
**Slug:** [thedotmack/claude-mem](https://github.com/thedotmack/claude-mem)

---

## TL;DR (3 lines)

- **What it is:** Claude Code plugin (also Cursor / OpenCode / OpenClaw) that **persists context across sessions** — hooks into the 5 Claude Code lifecycle events, runs a Bun-managed Express worker on `:37777`, and captures every tool use into a structured **SQLite + ChromaDB** memory.
- **How its KB works:** SessionStart → UserPromptSubmit → PostToolUse → Summary → SessionEnd hooks ship transcripts to the worker; the worker uses **Claude Agent SDK** to extract `observations` (typed: `facts`, `narrative`, `concepts`, `files_read`, `files_modified`); SQLite stores them, **chroma-mcp** (over stdio MCP, no npm chromadb dep!) stores embeddings; the **mem-search skill** is an HTTP API that future Claude sessions auto-invoke when the user asks about past work.
- **Verdict:** Pick when you want **Claude Code with real cross-session memory** — drop-in plugin install via Anthropic's marketplace; supports privacy tags, multi-account profiles, multi-platform. Skip if you want a framework-grade memory library to embed in your own code (use mem0/graphiti); claude-mem is opinionated for the Claude Code workflow.

## KB Architecture

### Storage
- **Vector store:** **ChromaDB via stdio MCP** (`chroma-mcp` server) — `src/services/sync/ChromaSync.ts`. No npm `chromadb` dep — communicates over MCP protocol. Embedding + persistence handled by the chroma-mcp server.
- **Graph store:** none
- **Metadata / structured:** **SQLite3** at `~/.claude-mem/claude-mem.db`; **10 migrations** as `migration001`–`migration010` exports in [`src/services/sqlite/migrations.ts`](https://github.com/thedotmack/claude-mem/blob/main/src/services/sqlite/migrations.ts) (with `MigrationRunner` in `migrations/runner.ts`); canonical `schema.sql` with tables `sdk_sessions`, `observations`, `summaries`, `prompts`, `pending_messages`, `timeline`
- **Object / blob:** transcripts on local disk under `$CLAUDE_MEM_DATA_DIR`
- **Cache:** in-process worker queue (Bun)

### Ingestion / Extraction
- **Source types accepted:** **Claude Code session events** captured via 5 lifecycle hooks (SessionStart / UserPromptSubmit / PostToolUse / Summary / SessionEnd). Also Cursor (via `cursor:install`), OpenCode, OpenClaw.
- **Chunking strategy:** **per-session** — each session's transcript is one ingestion unit; observations within are the dedup unit (`UNIQUE(memory_session_id, content_hash)`)
- **Entity / fact extraction:** **LLM-based via `@anthropic-ai/claude-agent-sdk`** — the worker spawns an Agent SDK call with a compression prompt → typed observation rows
- **Schema (observation row):**
  ```
  id, memory_session_id, project, text, type,
  title, subtitle, facts (JSON), narrative, concepts (JSON),
  files_read (JSON), files_modified (JSON),
  prompt_number, discovery_tokens, content_hash,
  agent_type, agent_id, merged_into_project,
  generated_by_model, metadata, created_at
  ```
- **Privacy tags:** `<private>content</private>` — stripped at the hook layer before reaching worker / DB (`src/utils/tag-stripping.ts`)
- **Tree-sitter:** dev-dep includes parsers for SQL, Lua, Markdown, TOML, YAML, Zig, Bash, C, C++, etc. — used for **code-aware ingest**

### Retrieval
- **Modes:** **hybrid** — SQLite FTS (text + structured filters by project, files, type) + ChromaDB vector search; combined in `mem-search` skill
- **Reranker:** none in this codebase; relies on Chroma scores + SQLite ranking
- **mem-search skill:** HTTP API (`POST /search`); auto-invoked when user asks about history. Skill metadata in `plugin/skills/mem-search/SKILL.md`
- **Top-k defaults:** configurable per query
- **Other skills (KB-related):** `make-plan`, `do`, `pathfinder`, `smart-explore`, `timeline-report`, `knowledge-agent`, `version-bump` — eight skills bundled with the plugin

### Memory model
- **Tiers:** raw transcripts (filesystem) + observations (structured SQL rows) + summaries (LLM-compressed per session) + timeline (ordered cross-session events)
- **Bi-temporal:** no
- **Self-update mechanism:** **automatic on every PostToolUse** — async worker processes events without blocking the Claude session
- **Cross-session injection:** SessionStart hook queries past observations relevant to the new project / prompt and injects context
- **Decay / forgetting:** none built-in; user can delete via privacy tags or manual purge
- **Multi-account:** `CLAUDE_MEM_DATA_DIR` env var isolates profiles; auto-derived port `37700 + (uid % 100)` prevents collisions

### MCP / connectors
- **MCP server exposed:** **yes** — `src/servers/mcp-server.ts`; uses `@modelcontextprotocol/sdk`. mem-search and other tools are exposed.
- **MCP client used:** **yes** — `chroma-mcp` is consumed over stdio MCP for vector ops
- **Native connectors:** Cursor (custom installer), OpenCode (plugin), OpenClaw (separate top-level dir)
- **Tool-call surface:** mem-search HTTP API + 8 skills + MCP tools

### Notable design choices
- **Worker daemon, not in-process** — async processing on port `:37777`; Claude session never blocks on extraction
- **Stdio-MCP for ChromaDB** — no npm `chromadb` dep, no ONNX/WASM model download — chroma-mcp handles embeddings
- **`@anthropic-ai/claude-agent-sdk` for compression** — uses the same SDK that powers Claude Code itself for memory compression
- **Skills are first-class** — 8 bundled skills, plus `make-plan`/`do` orchestration that turn the plugin into a planning + execution loop
- **Tree-sitter for code awareness** — observations can be code-language-aware (SQL, Lua, etc.)
- **Privacy tags** — `<private>...</private>` for user-level exclusion, stripped at edge before processing
- **Marketplace distribution** — Anthropic Claude Code plugin marketplace listing; `npm run sync-marketplace`
- **Multi-platform from one codebase** — Claude Code, Cursor, OpenCode, OpenClaw share the worker
- **AGPL-3.0** — same license as basic-memory and OpenHands

## Dependencies (KB-relevant)

From `package.json`:

```
"@anthropic-ai/claude-agent-sdk": "^0.2.119"   # extraction LLM
"@modelcontextprotocol/sdk": "^1.29.0"
"express": "^5.2.1"                            # worker HTTP server
"react": "^19.2.5"  "react-dom": "^19.2.5"     # viewer UI
"yaml" "zod" "zod-to-json-schema"

# devDeps include 10+ tree-sitter language parsers
"@derekstride/tree-sitter-sql"  "@tree-sitter-grammars/tree-sitter-{lua,markdown,toml,yaml,zig}"
"tree-sitter-{bash,c,cpp,...}"

# Engines: Node ≥20, Bun ≥1.0
```

ChromaDB is consumed over stdio MCP (`chroma-mcp` external server), not as an npm package — keeps the bundle slim.

## Tradeoffs

**Pros:**
- ★70k+ stars and 2026-05-01 push date make it the most-deployed Claude Code KB plugin in the cohort
- Asynchronous worker means zero latency in the Claude Code session itself
- 8 bundled skills (mem-search, make-plan, do, pathfinder, smart-explore, timeline-report, knowledge-agent, version-bump) — a full planning + execution loop, not just memory
- Privacy tags + multi-account profiles solve real concerns missing in mem0/graphiti
- Multi-platform support (Claude / Cursor / OpenCode / OpenClaw) from a single worker
- Tree-sitter language coverage for code-aware observations
- Stdio-MCP architecture for ChromaDB avoids the ONNX/WASM dependency rabbit-hole

**Cons:**
- **Tightly coupled to Claude Code's lifecycle hooks** — not a general-purpose memory framework you can drop into a different agent
- Single-user single-machine by default (Postgres mode is not built in)
- AGPL-3.0 license — fine for personal/OSS use, awkward for closed-source enterprise
- No bi-temporal model (graphiti is the cohort's only entry there)
- 10 schema migrations and a complex worker daemon (Express + PM2 + multi-agent search/session/branch managers) mean ops surface is non-trivial for what looks like a "plugin"

## When to use it

- **Good fit:** Claude Code daily-driver users who want their agent to *remember*; teams using Claude Code on shared codebases; researchers who need timelines and structured observations of agent runs
- **Bad fit:** non-Claude-Code agents (use OpenHands microagents or mem0); teams blocked by AGPL; multi-tenant SaaS deployments
- **Closest alternative (in this cohort):** OpenHands microagents (also coding-agent KB, but trigger-based, not extraction-based) — claude-mem is the *extraction* sibling

## Code pointers (evidence)

- 5 lifecycle-hook events (`SessionStart` / `UserPromptSubmit` / `PostToolUse` / `Summary` / `SessionEnd`) dispatched via the unified [`src/cli/hook-command.ts`](https://github.com/thedotmack/claude-mem/blob/main/src/cli/hook-command.ts) CLI subcommand; event constants in [`src/shared/hook-constants.ts`](https://github.com/thedotmack/claude-mem/blob/main/src/shared/hook-constants.ts); response helpers in [`src/hooks/hook-response.ts`](https://github.com/thedotmack/claude-mem/blob/main/src/hooks/hook-response.ts)
- Worker service: [`src/services/worker/`](https://github.com/thedotmack/claude-mem/tree/main/src/services/worker) — Express on `:37777` (built to [`plugin/scripts/worker-service.cjs`](https://github.com/thedotmack/claude-mem/blob/main/plugin/scripts/worker-service.cjs)); managed by PM2; sub-modules incl. `SDKAgent`, `SearchManager`, `SessionManager`, `BranchManager`, `http/`, `agents/`, `events/`, `knowledge/`
- SQLite schema (canonical): [`src/services/sqlite/schema.sql`](https://github.com/thedotmack/claude-mem/blob/main/src/services/sqlite/schema.sql)
- Migrations: [`src/services/sqlite/migrations.ts`](https://github.com/thedotmack/claude-mem/blob/main/src/services/sqlite/migrations.ts) — **10 named migrations** (`migration001`–`migration010`) + runner
- Chroma sync over MCP: `src/services/sync/ChromaSync.ts` + `ChromaMcpManager.ts`
- MCP server: `src/servers/mcp-server.ts`
- Skills: `plugin/skills/{do,knowledge-agent,make-plan,mem-search,pathfinder,smart-explore,timeline-report,version-bump}/SKILL.md`
- Privacy tag stripping: `src/utils/tag-stripping.ts`
- RAGTIME (email-investigation mode): top-level `ragtime/ragtime.ts` — domain-specific bulk processor that uses claude-mem's pipeline
- Most useful single file to read first: `CLAUDE.md` — concise architecture overview

## Open questions

- Worker port collision policy is `37700 + (uid % 100)` — what's the failure mode if two profiles on the same uid both run without explicit `CLAUDE_MEM_WORKER_PORT`? Documented but not test-covered visibly.
- ChromaSync says "fail-fast with no fallbacks — if Chroma is unavailable, syncing fails." Does the SQLite layer continue to accept writes when Chroma is down (graceful degradation), or does the whole worker block?
- 10 migrations on a `~/.claude-mem/` SQLite DB suggests an evolving schema — what's the rollback story if a user is on plugin v12.4.9 but their DB was last touched by v8.x?

---

*Surveyed via the `curating-agentic-kbs` skill. Re-survey scheduled after 30 days of last `pushed_at` change.*

*Audit 2026-05-02: clone-verified against [`package.json`](https://github.com/thedotmack/claude-mem/blob/main/package.json) (v12.4.9, AGPL-3.0), [`src/cli/hook-command.ts`](https://github.com/thedotmack/claude-mem/blob/main/src/cli/hook-command.ts), [`src/services/worker/`](https://github.com/thedotmack/claude-mem/tree/main/src/services/worker), [`src/services/sqlite/migrations.ts`](https://github.com/thedotmack/claude-mem/blob/main/src/services/sqlite/migrations.ts), [`src/services/sync/Chroma*.ts`](https://github.com/thedotmack/claude-mem/tree/main/src/services/sync), [`plugin/skills/`](https://github.com/thedotmack/claude-mem/tree/main/plugin/skills), [`src/utils/tag-stripping.ts`](https://github.com/thedotmack/claude-mem/blob/main/src/utils/tag-stripping.ts). **Corrections:** migration count **29 → 10** (actual: `migration001`–`migration010` exports); hook implementation path corrected (no per-event hook files in `src/hooks/`; hooks dispatched via unified `src/cli/hook-command.ts` with event constants in `src/shared/hook-constants.ts`); worker path **`src/services/worker-service.ts` → `src/services/worker/` directory** (multi-module structure, built to `plugin/scripts/worker-service.cjs`). **Verified:** AGPL-3.0, v12.4.9, 8 bundled skills (do / knowledge-agent / make-plan / mem-search / pathfinder / smart-explore / timeline-report / version-bump), `@anthropic-ai/claude-agent-sdk ^0.2.119`, `@modelcontextprotocol/sdk ^1.29.0`, port 37777 default (configurable via `CLAUDE_MEM_WORKER_PORT`), Chroma over stdio MCP via `ChromaMcpManager` + `ChromaSync` + `ChromaSyncState`, privacy-tag stripping at `src/utils/tag-stripping.ts`. **Bonus discovery:** worker has graceful-degradation classification (`isWorkerUnavailableError`) — transport failures + timeouts + 5xx exit 0; 4xx + programming errors exit 2.*

*Re-audit iter 55 (2026-05-02): re-verified version + key paths against `main@2026-05-01`. Architectural state unchanged: v12.4.9 still current per `package.json`, AGPL-3.0 unchanged, `pushed_at` 2026-05-01 unchanged. ★70,480 → ★70,814 (+334 stars, ~0.47% growth in 2 days — typical trending-tier velocity for the coding-agent category). No corrections needed — survey is current.*
