# Survey: campfirein/byterover-cli

**Date:** 2026-05-02
**Stars:** 4,675 · **Last push:** 2026-04-30 · **Created:** 2025 · **Version:** `byterover-cli 3.10.1` · **License:** Elastic-2.0 (cohort first)
**Category:** memory-framework
**Slug:** [campfirein/byterover-cli](https://github.com/campfirein/byterover-cli)

---

## TL;DR (3 lines)

- **What it is:** ByteRover CLI (`brv`) — a TypeScript REPL/TUI (React/Ink) + oclif CLI + Vite Web UI that gives AI coding agents persistent, structured memory. Distributed via npm (`byterover-cli`, v3.10.1), backed by an arXiv paper, **Elastic License 2.0** (cohort first).
- **How its KB works:** **Memory swarm** — `brv` is fundamentally a *router* across **7 memory backends** in [`PROVIDER_TYPES`](https://github.com/campfirein/byterover-cli/blob/main/src/agent/core/domain/swarm/types.ts) (`byterover`, `honcho`, `hindsight`, `obsidian`, `local-markdown`, `gbrain`, `memory-wiki`) split into **4 local** (`byterover`, `local-markdown`, `memory-wiki`, `obsidian`) + **3 cloud** (`honcho`, `hindsight`, `gbrain`). Queries are typed (`factual` / `personal` / `relational` / `temporal`) for routing. Context lives in a **git-like context tree** with branch/commit/merge/push/pull, hash-based change detection, snapshot/diff/manifest services, and remote sync. Plus a connector ecosystem (skill / mcp / hook / rules) and **26 built-in agent tools**.
- **Verdict:** Pick when you want to **standardize across many memory frameworks** without committing to one — `brv` treats mem0/letta/zep/Honcho/etc. as interchangeable backends behind a single REPL. Skip if you want a single concrete memory implementation (use mem0/graphiti/MemOS directly), or if Elastic-License-2.0 restrictions (no hosted-service offering, no license-key bypass) block your business model.

## KB Architecture

### Storage
- **Vector store:** *None native* — ByteRover delegates vector storage to whichever `MemoryProvider` is configured. The `byterover` (in-house, cloud API), `honcho`, `hindsight`, and `gbrain` cloud backends each handle their own vector storage; the local backends (`obsidian`, `local-markdown`, `memory-wiki`) are markdown-shaped.
- **Graph store:** Same model — delegated to the chosen provider.
- **Metadata / structured:** Local-side: `.brv/` directory in the working project (analogous to `.git/`) holds the context tree, manifests, snapshots, daemon state, dream cache. Server-side `infra/` modules: `auth`, `browser`, `client`, `cogit`, `config`, `connectors`, `context-tree`, `daemon`, `dream`, `executor`.
- **Object / blob:** `agent/core/domain/blob/` — pluggable blob storage; cloud sync via `@campfirein/brv-transport-client`.

### Ingestion / Extraction
- **Source types accepted:** Source files (read/write/edit via tools), markdown notes (curate / write_memory / write_todos), conversation messages (auto-extracted into the context tree), web content (browser tool), shell output (bash_exec/output).
- **Chunking strategy:** Provider-dependent — when routing to mem0/letta/zep/etc., chunking is whatever that backend uses. ByteRover's local `local-markdown` and `memory-wiki` providers likely use file-as-chunk.
- **Entity / fact extraction:** **26 named tools** in [`src/agent/resources/tools/`](https://github.com/campfirein/byterover-cli/tree/main/src/agent/resources/tools) (each is a `.txt` prompt file): `bash_exec`, `bash_output`, `batch`, `code_exec`, `create_knowledge_topic`, `curate`, `delete_memory`, `detect_domains`, `edit_file`, `edit_memory`, `expand_knowledge`, `glob_files`, `grep_content`, `kill_process`, `list_directory`, `list_memories`, `read_file`, `read_memory`, `read_todos`, `search_history`, `search_knowledge`, `swarm_query`, `swarm_store`, `write_file`, `write_memory`, `write_todos`. The `swarm_query` / `swarm_store` tools are the multi-backend memory primitives.
- **Schema:** `Memory` interface with `MemorySource` enum (`agent` / `system` / `user`), attachments, plus `MemoryEntry` for swarm interop and `QueryRequest` / `QueryResult` / `StoreResult` types in [`agent/core/domain/swarm/types.ts`](https://github.com/campfirein/byterover-cli/blob/main/src/agent/core/domain/swarm/types.ts).

### Retrieval
- **Modes:** **Query-type-driven routing** — `QueryType = 'factual' | 'personal' | 'relational' | 'temporal'` selects which backend(s) to consult. `ProviderCapabilities` (with `createDefaultCapabilities(type)` per provider) describes what each backend can answer; `isLocalProvider` / `isCloudProvider` gates network access.
- **Reranker:** Per-provider — ByteRover doesn't ship its own; `swarm_query` aggregates `QueryResult`s from multiple providers.
- **Top-k defaults:** Per-provider; `QueryRequest` carries the parameters.
- **Context assembly:** `agent/core/domain/system-prompt/` builds the system prompt from the **context tree** (a git-like structure of context files) plus retrieved memory fragments. Context-tree services (`children-hash`, `derived-artifact`, `file-context-tree-merger`, `propagate-summaries`, `snapshot-diff`, `summary-frontmatter`) maintain incremental, summarized views of the project.

### Memory model
- **Tiers:**
  - **Context tree** — the git-like project context (`server/infra/context-tree/`).
  - **Local memory** — `read_memory` / `write_memory` / `edit_memory` / `delete_memory` / `list_memories` tools backed by the chosen provider.
  - **Knowledge topics** — `create_knowledge_topic` / `expand_knowledge` / `search_knowledge` tools — separate "topical" tier from raw memories.
  - **Todos** — `read_todos` / `write_todos` first-class.
  - **Swarm memory** — `swarm_query` / `swarm_store` route across the 12 providers above.
  - **Search history** — `search_history` searches prior queries.
- **Bi-temporal:** Inherited from the chosen provider (Zep/graphiti yes, mem0 no).
- **Self-update mechanism:** **Curate workflow** — `curate` tool with explicit approve/reject review flow for pending changes (mentioned in README as "Review workflow for curate operations"). Cloud sync via `transport-client` push/pull.
- **Decay / forgetting:** Per-provider; `delete_memory` is explicit.

### MCP / connectors
- **MCP server exposed:** Implicit via the connector framework — [`server/infra/connectors/mcp/`](https://github.com/campfirein/byterover-cli/tree/main/src/server/infra/connectors/mcp) ships `claude-desktop-config-path.ts`, `json-mcp-config-writer.ts`, `toml-mcp-config-writer.ts`, `mcp-connector.ts`, `mcp-connector-config.ts`. ByteRover **writes config files for Claude Desktop / Cursor / etc.** so they connect to `brv` as an MCP server. Cohort first for the *config-writer* angle.
- **MCP client used:** Yes — `@modelcontextprotocol/sdk` 1.26.0 as a hard dep; `mcp-connector` consumes external MCP servers.
- **Native connectors:** **Connector ecosystem** at `server/infra/connectors/` with four kinds — `skill` (skill bundles), `mcp` (MCP servers), `hook` (lifecycle hooks), `rules` (rule sets). `connector-manager.ts` orchestrates loading/unloading/health. The README claims "22+ AI coding agents" supported (Cursor, Claude Code, Windsurf, Cline, etc.) — likely via the MCP config-writers + skill connectors.
- **Tool-call surface:** 24 built-in tools (above) + arbitrary MCP tools + skill connectors. **18 LLM providers** via `@ai-sdk/*` packages — Anthropic, OpenAI, Google, Cerebras, Cohere, DeepInfra, Groq, Mistral, OpenAI-compatible, Perplexity, TogetherAI, Vercel, xAI, Anthropic SDK, Google GenAI, OpenRouter, plus an `ai` core. Largest LLM-provider surface in cohort.

### Notable design choices
- **Memory router as the product** — ByteRover provides a polyglot client *interface* over multiple memory backends. The actual `PROVIDER_TYPES` enum currently ships **7 backends** (4 local + 3 cloud); earlier survey drafts mentioned mem0/letta/zep/supermemory/redis-vector but those names are NOT in the current code — likely roadmap targets that haven't landed. The hard-coded 7-provider enum is clean but means new backends require a fork.
- **Query-type routing** — `factual` / `personal` / `relational` / `temporal` query classification routes to backends with the right `ProviderCapabilities`. Implies the agent (or a heuristic) classifies queries before retrieval.
- **Git-like context tree** — separate from memory. The project's working context (files, summaries, snapshots) lives in `.brv/` with branch/commit/merge/push/pull semantics. Closest cohort analogue: cline's git checkpoints, but ByteRover treats the tree as a first-class versioned artifact with hash-based diff.
- **MCP config-writers for downstream clients** — instead of just exposing an MCP server, ByteRover *writes config files* for Claude Desktop (`claude-desktop-config-path.ts`), JSON-format MCP configs, and TOML-format MCP configs. Reduces "how do I connect Cursor to this?" to a one-time setup command.
- **Connector ecosystem with 4 kinds** — skill, MCP, hook, rules — each with config + loader + manager. Closer to a real plugin runtime than mem0/cline/etc.
- **Curate workflow with explicit review** — "Review workflow for curate operations (approve/reject pending changes)" per README. Memory writes go through a queue rather than auto-committing. Cohort first for "human-in-the-loop memory write".
- **18 LLM providers via @ai-sdk** — Vercel's AI SDK ecosystem. Most LLM-provider breadth in cohort (mem0 has 24 providers but via its own factory; ByteRover uses the @ai-sdk standard).
- **`paper/` directory** — LaTeX source + references.bib + Makefile + build.sh — paper is part of the repo, not just linked. Suggests research-driven development.
- **Strict TDD requirement** — the CLAUDE.md states "MANDATORY" 5-step TDD process with 80% coverage minimum. Cohort first to make TDD a hard requirement in agent guidance.
- **Outside-In feature development** — explicit requirement in CLAUDE.md to start from the consumer (oclif command, REPL command, or TUI component) and define the minimal interface. Counter to bottom-up design.
- **Elastic License 2.0** — cohort first. Non-commercial-hosting + no-license-bypass restrictions; you can fork and redistribute, but cannot offer ByteRover-as-a-service.

## Dependencies (KB-relevant)

From `package.json`:

```
"name": "byterover-cli"
"version": "3.10.1"
"bin": { "brv": "./bin/run.js" }

# LLM providers (18) via @ai-sdk
"@ai-sdk/anthropic", "@ai-sdk/cerebras", "@ai-sdk/cohere",
"@ai-sdk/deepinfra", "@ai-sdk/google", "@ai-sdk/groq",
"@ai-sdk/mistral", "@ai-sdk/openai", "@ai-sdk/openai-compatible",
"@ai-sdk/perplexity", "@ai-sdk/togetherai", "@ai-sdk/vercel",
"@ai-sdk/xai"
"@anthropic-ai/sdk"
"@google/genai"
"@openrouter/ai-sdk-provider"
"ai" (core)

# MCP
"@modelcontextprotocol/sdk": "1.26.0"

# CLI / TUI / Web UI
"@oclif/core", "@oclif/plugin-help", "@oclif/plugin-update"
"@inkjs/ui", "@inquirer/prompts"   # Ink TUI
"@tanstack/react-query"
"@types/react-syntax-highlighter"

# Sync
"@campfirein/brv-transport-client" (GitHub-pinned)
"@campfirein/byterover-packages" (GitHub-pinned)
"@socket.io/admin-ui"
```

License: **Elastic License 2.0**.

## Tradeoffs

**Pros:**
- **Memory-router-as-product** is genuinely novel in this cohort — let users keep their existing mem0/letta/zep deployments, but standardize the *agent-side* API.
- **7 memory backends (3 cloud + 4 local) with capability-based routing** — most-polyglot memory client in cohort.
- **MCP config-writers for 22+ AI coding agents** — drops the friction of "how do I wire Cursor to this?" to a single command.
- **Git-like context tree with branch/merge/push/pull** — most sophisticated *project context versioning* in cohort.
- **Curate workflow** — human-in-the-loop memory writes are a useful default for code agents.
- **Strict TDD + Outside-In + 80% coverage** — most disciplined contribution guidance in cohort, baked into CLAUDE.md.
- **Connector ecosystem** (skill/MCP/hook/rules) — real plugin runtime, not just config files.
- **18 LLM providers via @ai-sdk** — broad LLM coverage with Vercel's SDK conventions.

**Cons:**
- **Elastic License 2.0** restricts redistribution as a hosted service. Read carefully if your business model includes SaaS/managed offerings.
- **Memory backends are a hard-coded enum** (`PROVIDER_TYPES` array) — adding a new provider requires forking; not extensible at runtime. Currently 7 entries.
- **Heavy dependency surface** — 30+ npm deps including Ink + React Query + oclif + 18 LLM SDKs + Socket.IO + MCP SDK.
- **Server-side complexity** — `infra/` has 10+ subsystems (auth, browser, cogit, daemon, dream, executor, …). Not a "single-file library".
- **No native bi-temporal model** — relies on the chosen backend.
- **Documentation is in the paper + product docs site** — code-only readers will have to read source files.
- **GitHub-pinned internal dependencies** (`@campfirein/byterover-packages`, `@campfirein/brv-transport-client`) suggest a closed-source companion package set; the OSS picture isn't fully self-contained.

## When to use it

- **Good fit:** teams already using mem0 / letta / zep / Honcho who want to unify how their AI coding agents talk to memory; codebases where you want a *git-like* project context separate from per-developer git; setups where Claude Desktop / Cursor / Windsurf / Cline all need to share the same memory; Vercel `ai` SDK shops; teams with strict TDD culture.
- **Bad fit:** SaaS products that need redistribution rights (ELv2 blocks hosted offerings); single-binary deployments without npm; products that want one concrete memory engine, not a router; light-touch CLIs (24 tools + 18 LLM providers + 4 connector types is a heavy harness).
- **Closest alternative:** [`mem0ai/mem0`](surveys/mem0ai__mem0.md) — also a memory framework, but mem0 is a *concrete* memory engine (one extraction prompt, one schema, many backends); ByteRover *delegates to* mem0 alongside 11 other backends. [`MemTensor/MemOS`](surveys/MemTensor__MemOS.md) is a research-grade memory framework with three explicit memory tiers; ByteRover is a router that doesn't impose a memory taxonomy. For coding-agent context specifically, [`thedotmack/claude-mem`](surveys/thedotmack__claude-mem.md) (Claude Code plugin) and [`Lum1104/Understand-Anything`](surveys/Lum1104__Understand-Anything.md) (Claude Code plugin for codebases) are nearby; ByteRover stands out by being *cross-tool* (22+ agents) rather than tied to one host.

## Code pointers (evidence)

- 7-provider memory swarm enum (`PROVIDER_TYPES`) + 4 local / 3 cloud split + capability-based routing: [`src/agent/core/domain/swarm/types.ts`](https://github.com/campfirein/byterover-cli/blob/main/src/agent/core/domain/swarm/types.ts)
- 26 agent tools as `.txt` prompt files: [`src/agent/resources/tools/`](https://github.com/campfirein/byterover-cli/tree/main/src/agent/resources/tools) (incl. `swarm_query.txt`, `swarm_store.txt`, `curate.txt`, `expand_knowledge.txt`)
- Memory schema: [`src/agent/core/domain/memory/types.ts`](https://github.com/campfirein/byterover-cli/blob/main/src/agent/core/domain/memory/types.ts) — `Memory`, `MemorySource`, `Attachment`, `CreateMemoryInput`, `UpdateMemoryInput`, `ListMemoriesOptions`, `MemoryConfig`
- Git-like context tree services: [`src/server/infra/context-tree/`](https://github.com/campfirein/byterover-cli/tree/main/src/server/infra/context-tree) (`children-hash.ts`, `derived-artifact.ts`, `file-context-tree-merger.ts`, `propagate-summaries.ts`, `snapshot-diff.ts`, `read-context-tree-remote.ts`, `runtime-signal-store.ts`, `summary-frontmatter.ts`)
- Connector ecosystem (skill/MCP/hook/rules) + manager: [`src/server/infra/connectors/`](https://github.com/campfirein/byterover-cli/tree/main/src/server/infra/connectors)
- MCP config-writers (Claude Desktop / JSON / TOML): [`src/server/infra/connectors/mcp/`](https://github.com/campfirein/byterover-cli/tree/main/src/server/infra/connectors/mcp) (`claude-desktop-config-path.ts`, `json-mcp-config-writer.ts`, `toml-mcp-config-writer.ts`)
- 18 LLM providers via @ai-sdk: see `package.json` dependencies — `@ai-sdk/{anthropic,cerebras,cohere,deepinfra,google,groq,mistral,openai,openai-compatible,perplexity,togetherai,vercel,xai}` + `@anthropic-ai/sdk` + `@google/genai` + `@openrouter/ai-sdk-provider` + `ai`
- Strict-TDD + Outside-In CLAUDE.md guidance: [`CLAUDE.md`](https://github.com/campfirein/byterover-cli/blob/main/CLAUDE.md)
- Paper LaTeX source: [`paper/main.tex`](https://github.com/campfirein/byterover-cli/blob/main/paper/main.tex), [`paper/references.bib`](https://github.com/campfirein/byterover-cli/blob/main/paper/references.bib)
- Most useful single file to read first: [`src/agent/core/domain/swarm/types.ts`](https://github.com/campfirein/byterover-cli/blob/main/src/agent/core/domain/swarm/types.ts) — the memory-router design surface is the architectural center.

## Open questions

- ~~The 12 providers in the swarm enum~~ **Answered (audit 2026-05-02):** the current enum has **7** providers (`byterover` / `honcho` / `hindsight` / `obsidian` / `local-markdown` / `gbrain` / `memory-wiki`); the 5 names previously listed (mem0, letta, zep, supermemory, redis-vector) are not in the current code — likely roadmap aspirations.
- "Hindsight" and "gbrain" are unfamiliar memory backends — what are they? (Possibly proprietary or pre-release projects. Hindsight is now a known cohort entry — see `vectorize-io/hindsight` in candidates.)
- The `cogit` and `dream` server-side subsystems — what do they do? (Names suggest cognitive / consolidation processes during idle time.)
- The internal `@campfirein/byterover-packages` dependency is GitHub-pinned (`#1.0.2`) — is it an OSS package with public tags or a private one? Affects vendor lock-in assessment.
- The paper at `arxiv.org/abs/2604.01599` looks like a placeholder ID (year 2604 in the future) — what's the actual paper reference?
- ELv2 legal envelope — what specifically counts as "offering as a hosted service" for a CLI? The line is fuzzy in CLI/REPL contexts.

---

*Surveyed via the `curating-agentic-kbs` skill. Re-survey scheduled after 30 days of last `pushed_at` change.*

*Audit 2026-05-02: clone-verified against [`src/agent/core/domain/swarm/types.ts`](https://github.com/campfirein/byterover-cli/blob/main/src/agent/core/domain/swarm/types.ts), [`src/agent/resources/tools/`](https://github.com/campfirein/byterover-cli/tree/main/src/agent/resources/tools) (26 `.txt` files), [`src/server/infra/connectors/`](https://github.com/campfirein/byterover-cli/tree/main/src/server/infra/connectors) (4 connector kinds: hook/mcp/rules/skill + connector-manager + shared), [`package.json`](https://github.com/campfirein/byterover-cli/blob/main/package.json) (v3.10.1, Elastic-2.0). **Major corrections:** memory backends **12 → 7** (actual `PROVIDER_TYPES = [byterover, honcho, hindsight, obsidian, local-markdown, gbrain, memory-wiki]`; the 5 earlier-listed names mem0/letta/zep/supermemory/redis-vector are NOT in the current code — likely roadmap aspirations); cloud/local breakdown corrected to **3 cloud + 4 local** (was "8 cloud + 4 local"); agent tools **24 → 26** (off-by-2). **Verified verbatim:** `QueryType = 'factual' | 'personal' | 'relational' | 'temporal'` exact, `LOCAL_PROVIDERS = {byterover, local-markdown, memory-wiki, obsidian}` exact 4, `isLocalProvider`/`isCloudProvider` (cloud is `!local`), 4 connector kinds (hook / mcp / rules / skill), Elastic-2.0 license cohort-first. **Cohort cascade:** every README mention of "12 backends" / "12 memory backends" needs to drop to **7**.*
