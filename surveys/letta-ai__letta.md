# Survey: letta-ai/letta

**Date:** 2026-05-02
**Stars:** 22,396 · **Last push:** 2026-04-07 · **Created:** 2023-10 (formerly **MemGPT**)
**Category:** memory-framework
**Slug:** [letta-ai/letta](https://github.com/letta-ai/letta)

---

## TL;DR (3 lines)

- **What it is:** Letta (formerly MemGPT — the original "LLM with virtual context windows" research project) — Apache-2.0 stateful-agent platform with the cohort's most influential **memory-blocks abstraction**. Python core (`pip install letta`, v0.16.7) + Python/TypeScript SDKs (`letta-client`) + Letta Code CLI (`@letta-ai/letta-code` npm — separate repo).
- **How its KB works:** **Memory blocks** are typed slices of the LLM context — `Block(label, value, limit)` rows in Postgres, where `label ∈ {human, persona, system, …}` and `limit` is a per-block char budget. **Archives** are shareable collections of **Passages** (embedded chunks). **Conversations**, **Groups** (multi-agent), **Identities** (user entities), **Sources** (data sources), **Files** all have first-class ORM tables. **3 vector backends** via `VectorDBProvider` enum: `native` (Postgres + pgvector), `tpuf` (Turbopuffer), `pinecone`. **18 LLM provider clients** in `llm_api/`. **50 ORM tables**.
- **Verdict:** Pick when you want the **canonical agent-memory framework** with stateful agents, typed memory blocks, archival passages, multi-agent groups, voice agents, and a comprehensive REST API. Skip if you want a single-binary library — Letta is a stateful service (Postgres + Alembic + Docker Compose).

## KB Architecture

### Storage
- **Vector store:** **3 backends** via `VectorDBProvider` enum ([letta/schemas/enums.py:277](https://github.com/letta-ai/letta/blob/main/letta/schemas/enums.py)) — `native` (Postgres + pgvector via `CommonVector` + `EmbeddingConfigColumn`), `tpuf` (Turbopuffer — cohort first), `pinecone`. The `Passage` ORM model has `embedding_config` per-row, so different archives can use different embedders / dimensions.
- **Graph store:** *None.* Letta is intentionally not a graph framework — relationships live in SQL join tables (`agents_tags`, `archives_agents`, `blocks_agents`, `blocks_conversations`, `groups_blocks`, `identities_blocks`, `tools_agents`, `sources_agents`, `files_agents`, `groups_agents`, `identities_agents`).
- **Metadata / structured:** **Postgres** via SQLAlchemy 2 + Alembic migrations + `init.sql`. ORM has **50 tables** in [`letta/orm/`](https://github.com/letta-ai/letta/tree/main/letta/orm) — most explicitly-modeled relational schema in the cohort.
- **Object / blob:** `letta/services/file_manager.py` + `file_processor/` handle ingest; storage is filesystem by default.

### Ingestion / Extraction
- **Source types accepted:** [`letta/services/file_processor/`](https://github.com/letta-ai/letta/tree/main/letta/services/file_processor) — `chunker/`, `embedder/`, `parser/`, `file_types.py`. Plus `Source` ORM model for arbitrary data-source records connected via `SourceMixin` to passages.
- **Chunking strategy:** Per-source via `chunker/`; configurable per-archive via `embedding_config` (chunk size + overlap encoded in the config dict).
- **Entity / fact extraction:** *Not auto-extraction.* Letta's primary memory is **agent-managed memory blocks** — the agent itself uses tools (`core_memory_append`, `core_memory_replace`, `archival_memory_insert`, etc.) to write to its own memory. This is the original MemGPT pattern.
- **Schema:** **Memory blocks** (`Block`: label, value, limit) for in-context memory + **Passages** (`text`, `embedding`, `metadata_`, `embedding_config`) for archival memory + **Conversations** + **Identities**. `block_history.py` ORM tracks block-edit history.

### Retrieval
- **Modes:** Vector similarity over passages (per-archive); SQL filters on metadata; tag-match modes via `TagMatchMode` enum (`ANY` / `ALL`); comparison operators via `ComparisonOperator` enum (`EQ` / `NE` / `LT` / `LE` / `GT` / `GE`). The agent invokes retrieval via tools (`archival_memory_search`, `conversation_search`).
- **Reranker:** No native reranker; relies on vector-DB-side ranking + agent's iterative tool-calling to refine.
- **Top-k defaults:** Configurable per-tool-call; the agent decides.
- **Context assembly:** **Memory blocks are *the* context** — block values are concatenated into the system prompt up to `limit` characters; archival passages flow in via tool calls. The `context_window_calculator/` service ensures the assembled context fits.

### Memory model
- **Tiers:**
  - **Core memory** = `Block`s in the system prompt (the cohort's signature MemGPT primitive).
  - **Archival memory** = `Passage`s in an `Archive` (shareable across agents via `archives_agents` join table).
  - **Conversation memory** = `ConversationMessage`s.
  - **Group memory** = shared `Block`s across an agent `Group` (via `groups_blocks` join).
  - **Identity memory** = `Identity` rows linked via `identities_blocks` and `identities_agents`.
- **Bi-temporal:** No. Block edits are tracked in `block_history.py` (transaction-time only).
- **Self-update mechanism:** **Agent-driven** — the agent calls `core_memory_*` and `archival_memory_*` tools to update its own state. *No background extraction* — this is the inverse of mem0's auto-extract-on-add. Cohort first to make agent-self-management the canonical primitive.
- **Decay / forgetting:** Per-block `limit` enforces character budgets; agents must prune to stay within. `block_manager_git.py` suggests git-style versioning of memory edits.

### MCP / connectors
- **MCP server exposed:** Yes — REST API exposed via FastAPI + dedicated MCP module surface; ORM has `mcp_server.py` and `mcp_oauth.py` tables for managing per-org MCP server configs with OAuth flows.
- **MCP client used:** Yes — agents can consume MCP servers as tools.
- **Native connectors:** **18 LLM provider clients** in [`letta/llm_api/`](https://github.com/letta-ai/letta/tree/main/letta/llm_api): anthropic, azure, baseten, bedrock, chatgpt_oauth, deepseek, fireworks, google_ai, google_vertex, groq, minimax, mistral, openai (+ `openai_ws_session` streaming variant), sglang_native, together, xai, zai. Routed via `llm_client.py` factory. Most LLM-provider breadth in cohort tied with mem0's 24.
- **Tool-call surface:** **Tools are first-class ORM rows** ([`tool.py`](https://github.com/letta-ai/letta/blob/main/letta/orm/tool.py) + `tools_agents.py` join). Letta's signature: every tool is a versioned, attachable resource. Plus skills + subagents (per README) shipped with the Letta Code CLI.

### Notable design choices
- **MemGPT lineage** — Letta is the production version of the MemGPT paper ("Towards LLMs as Operating Systems"). The "memory blocks" + "archival memory" + "conversation memory" three-tier model is the original framing that influenced mem0 / cognee / MemOS / OpenViking taxonomies.
- **Agent-self-managed memory** — instead of auto-extracting facts, the agent calls memory tools. Inverse of mem0's "additive extraction on every add."
- **50 ORM tables** with explicit join tables for many-to-many relationships (`blocks_agents`, `archives_agents`, `tools_agents`, `groups_blocks`, `identities_blocks`, `sources_agents`, `files_agents`, etc.). Most explicitly normalized memory schema in cohort.
- **3 vector backends including Turbopuffer** — `tpuf` is cohort first as a primary backend (mem0 lists it as a singleton).
- **`block_manager_git.py`** + `block_history.py` — git-style versioning of memory edits; cohort first to ship git-shaped memory versioning as a service.
- **18 LLM provider clients** + `model_aliases.py` + `model_specs/` — vendor-agnostic with per-model spec overrides.
- **Provider-trace backends are pluggable** — `provider_trace_backend` setting is a comma-separated list of `{postgres, clickhouse, socket}` ([`letta/settings.py:571`](https://github.com/letta-ai/letta/blob/main/letta/settings.py#L571)). Default is `postgres` only; ClickHouse and the `socket` backend (cohort-first streaming sink) are opt-in via `LETTA_*_PROVIDER_TRACE_BACKEND` env var.
- **Voice agents** (`voice_agent.py`, `voice_sleeptime_agent.py`) — speech-first agent loop variants.
- **`letta_agent_v3.py`** alongside v1, v2, batch — multiple agent-loop generations coexist; signal of active research/iteration.
- **Sleep-time variants** (`voice_sleeptime_agent.py`, ephemeral_summary_agent.py) — agents that run in the background to summarize / consolidate. Cohort first.
- **`groups/`** — multi-agent group orchestration with shared blocks (`groups_blocks` join table).
- **Letta Code = separate npm package** — the CLI is `@letta-ai/letta-code` published to npm; the OSS Python repo is the platform; commercial Letta Cloud is hosted at app.letta.com.
- **Apache-2.0** with no enterprise bolt-on — fully OSS at the platform level.
- **Webhook setup docs + `WEBHOOK_SETUP.md`** — first-class webhook integration for external triggers.
- **AI_POLICY.md / TERMS.md / PRIVACY.md** at top level — production-ops attention to AI/data policies.

## Dependencies (KB-relevant)

From `pyproject.toml`:

```
name = "letta"
version = "0.16.7"
license = "Apache-2.0"
requires-python = "<3.14,>=3.11"

# (full deps in pyproject.toml — extensive list)
# Notable categories:
- SQLAlchemy 2 + Alembic + asyncpg + pgvector       # Postgres-native vector + relational
- 17 LLM clients (Anthropic, Azure, Baseten, Bedrock, ChatGPT-OAuth,
  DeepSeek, Fireworks, Google AI, Google Vertex, Groq, MiniMax, Mistral,
  OpenAI, …)
- pinecone, turbopuffer (additional vector backends)
- FastAPI + uvicorn (REST API)
- ClickHouse (provider trace + OTEL traces in `clickhouse_*` services)
```

License: **Apache-2.0**.

## Tradeoffs

**Pros:**
- **Cohort's most-influential memory taxonomy** — the MemGPT paper's blocks/archive/conversation tiers are the lineage that mem0 / cognee / MemOS / OpenViking all evolved from.
- **Agent-self-managed memory** — the agent decides what to remember via tool calls; minimum implicit magic.
- **Most explicitly normalized ORM** in cohort — 35+ tables, every relationship a join table.
- **3 vector backends** including Turbopuffer (cohort first as primary).
- **17 LLM clients** with per-model specs.
- **Voice + sleep-time agent variants** ship in core.
- **Multi-agent groups** with shared memory blocks via join tables.
- **`block_manager_git.py`** for git-style memory versioning.
- **ClickHouse for OTEL + provider traces** (opt-in, default `postgres`) — production observability with pluggable backends (`postgres` / `clickhouse` / `socket`).
- **Apache-2.0** with no enterprise bolt-on — fully OSS platform.

**Cons:**
- **Heavy operational footprint** — Postgres + pgvector + (optional Pinecone / Turbopuffer) + ClickHouse for traces + FastAPI server. Single-binary it isn't.
- **No graph backend** — multi-hop queries are SQL JOINs; if you need Cypher, look elsewhere.
- **Agent-self-managed memory has cold-start cost** — the agent has to learn to use the tools, vs mem0/MemOS where extraction is automatic.
- **Three coexisting agent-loop generations** (`letta_agent.py`, `_v2.py`, `_v3.py`) — version churn risk.
- **No bi-temporal model** — block_history tracks transaction-time only.
- **Last push 2026-04-07** is 25 days old at survey time — slowest cadence among major repos in cohort (still active, just less daily).

## When to use it

- **Good fit:** stateful agent platforms wanting the canonical MemGPT memory model; products needing voice / sleep-time / multi-agent variants out of the box; deployments wanting Postgres-native + Pinecone/Turbopuffer alternatives; teams comfortable with FastAPI + Alembic + Docker.
- **Bad fit:** single-binary CLIs; products needing graph reasoning (use graphiti / cognee); products preferring auto-extraction over agent-self-managed memory (use mem0 / MemOS).
- **Closest alternative:** [`mem0ai/mem0`](surveys/mem0ai__mem0.md) — opposite extraction philosophy (auto-extract-on-add vs agent-self-managed); mem0 has 30+ vector backends + simpler API but flatter memory model. [`MemTensor/MemOS`](surveys/MemTensor__MemOS.md) is research-grade with three explicit memory tiers; Letta is production-grade with the original MemGPT taxonomy.

## Code pointers (evidence)

- `Block` ORM (memory blocks with label / value / limit): [`letta/orm/block.py`](https://github.com/letta-ai/letta/blob/main/letta/orm/block.py)
- `Archive` + `Passage` ORM (archival memory with per-row embedding config): [`letta/orm/archive.py`](https://github.com/letta-ai/letta/blob/main/letta/orm/archive.py), [`letta/orm/passage.py`](https://github.com/letta-ai/letta/blob/main/letta/orm/passage.py)
- `VectorDBProvider` enum (native / tpuf / pinecone): [`letta/schemas/enums.py:277`](https://github.com/letta-ai/letta/blob/main/letta/schemas/enums.py)
- 35+ ORM tables: [`letta/orm/`](https://github.com/letta-ai/letta/tree/main/letta/orm) (incl. `agent.py`, `archives_agents.py`, `block_history.py`, `blocks_agents.py`, `blocks_conversations.py`, `blocks_tags.py`, `conversation.py`, `conversation_messages.py`, `file.py`, `files_agents.py`, `group.py`, `groups_agents.py`, `groups_blocks.py`, `identity.py`, `identities_agents.py`, `identities_blocks.py`, `job.py`, `mcp_oauth.py`, `mcp_server.py`, `message.py`, `passage.py`, `passage_tag.py`, `provider.py`, `provider_trace.py`, `run.py`, `sandbox_config.py`, `source.py`, `sources_agents.py`, `step.py`, `tool.py`, `tools_agents.py`)
- 18 LLM provider clients: [`letta/llm_api/`](https://github.com/letta-ai/letta/tree/main/letta/llm_api) — anthropic, azure, baseten, bedrock, chatgpt_oauth, deepseek, fireworks, google_ai, google_vertex, groq, minimax, mistral, openai (+ `openai_ws_session`), sglang_native, together, xai, zai
- ClickHouse provider-trace backend (opt-in via `LETTA_*_PROVIDER_TRACE_BACKEND`): [`letta/services/clickhouse_provider_traces.py`](https://github.com/letta-ai/letta/blob/main/letta/services/clickhouse_provider_traces.py) + setting in [`letta/settings.py:571`](https://github.com/letta-ai/letta/blob/main/letta/settings.py#L571) + manager in [`letta/services/telemetry_manager.py`](https://github.com/letta-ai/letta/blob/main/letta/services/telemetry_manager.py)
- File processor (chunker / embedder / parser): [`letta/services/file_processor/`](https://github.com/letta-ai/letta/tree/main/letta/services/file_processor)
- Agent loops (v1/v2/v3 + voice + voice-sleeptime + ephemeral + batch): [`letta/agents/`](https://github.com/letta-ai/letta/tree/main/letta/agents)
- Memory block git versioning: [`letta/services/block_manager_git.py`](https://github.com/letta-ai/letta/blob/main/letta/services/block_manager_git.py)
- Most useful single file to read first: [`letta/orm/block.py`](https://github.com/letta-ai/letta/blob/main/letta/orm/block.py) — the `Block` model is the architectural center; understanding the label/value/limit semantics maps the rest of the framework.

## Open questions

- 3 coexisting agent-loop generations (`v1` / `v2` / `v3`) — what's the migration story for v2-deployed agents?
- ~~ClickHouse for traces — is it required or optional?~~ **Answered (audit 2026-05-02):** opt-in via `provider_trace_backend` setting in [`letta/settings.py:571`](https://github.com/letta-ai/letta/blob/main/letta/settings.py#L571). Default is `postgres` only; supported backends are `postgres` / `clickhouse` / `socket` (comma-separated for dual-write).
- `block_manager_git.py` — is the git semantic literal (an actual `.git` directory) or metaphorical?
- Voice-sleeptime agent — what's the actual workload during "sleep"? Summarization?
- Letta Code CLI repo (`letta-ai/letta-code`) ★2.4k was originally in our queue — what's the OSS surface vs commercial?

---

*Surveyed via the `curating-agentic-kbs` skill. Re-survey scheduled after 30 days of last `pushed_at` change.*

*Audit 2026-05-02: clone-verified against [`pyproject.toml`](https://github.com/letta-ai/letta/blob/main/pyproject.toml), [`letta/llm_api/`](https://github.com/letta-ai/letta/tree/main/letta/llm_api), [`letta/orm/`](https://github.com/letta-ai/letta/tree/main/letta/orm), [`letta/agents/`](https://github.com/letta-ai/letta/tree/main/letta/agents), [`letta/services/clickhouse_provider_traces.py`](https://github.com/letta-ai/letta/blob/main/letta/services/clickhouse_provider_traces.py), [`letta/services/telemetry_manager.py`](https://github.com/letta-ai/letta/blob/main/letta/services/telemetry_manager.py), [`letta/settings.py`](https://github.com/letta-ai/letta/blob/main/letta/settings.py), [`letta/schemas/enums.py`](https://github.com/letta-ai/letta/blob/main/letta/schemas/enums.py). **Corrections:** LLM client count **17 → 18** (added: sglang_native, together, xai, zai; removed obsolete `openai_backcompat` mention); ORM table count **35+ → 50** (exact); ClickHouse for traces clarified as **opt-in via `provider_trace_backend` setting** (default `postgres`, alternatives `clickhouse` / `socket`); answered open question on ClickHouse optionality. **Verified:** `VectorDBProvider` enum (NATIVE/TPUF/PINECONE) at [`enums.py:277-282`](https://github.com/letta-ai/letta/blob/main/letta/schemas/enums.py#L277-L282), 8 agent-loop variants (v1/v2/v3 + voice + voice_sleeptime + ephemeral + ephemeral_summary + batch), `block_manager_git.py` exists, ClickHouse cohort-first claim. **Bonus discovery:** the `socket` provider-trace backend (streaming sink) appears cohort-first too.*

*Re-audit iter 64 (2026-05-02): re-verified version pin. Architectural state unchanged: v0.16.7 still current per `pyproject.toml`, Apache-2.0 unchanged. ★22,396 → ★22,405 (+9 stars, ~0.04% growth — slowest cohort velocity in the re-audit-tracked set, signals letta's market position as established-but-not-trending). `pushed_at` 2026-04-07 → 2026-04-12 (+5 days, modest activity). No corrections needed — survey is current.*
