# Survey: vectorize-io/hindsight

**Date:** 2026-05-02
**Stars:** 11,659 · **Last push:** 2026-05-01 · **Created:** 2025-10-30 · **Version:** `hindsight-api-slim 0.5.6` · **License:** MIT
**Category:** memory-framework
**Slug:** [vectorize-io/hindsight](https://github.com/vectorize-io/hindsight)

---

## TL;DR (3 lines)

- **What it is:** Vectorize's open-source agent memory system — pitched as "smarter agents that learn over time, not just remember." MIT, paper [arXiv 2512.12818](https://arxiv.org/abs/2512.12818). Massive monorepo (~17 sub-projects) with FastAPI + Python core + Next.js control-plane UI + npm/PyPI/Helm distribution + commercial Hindsight Cloud (`ui.hindsight.vectorize.io`).
- **How its KB works:** **Biomimetic 3-tier memory** — `World facts` (general knowledge) + `Experience facts` (personal events) + `Mental models` (LLM-consolidated knowledge synthesized from facts). Backed by Postgres + pgvector; engine modules cover `consolidation/`, `entity_resolver`, `query_analyzer`, `reflect/`, `retain/`, `search/`. Cross-encoder rerank including a custom **Jina-MLX reranker** (`jina_mlx_reranker.py`). MCP server via FastMCP (with 2.x/3.x compat layer). **23 integrations** in `hindsight-integrations/` covering every major agent framework.
- **Verdict:** Pick when you want a **biomimetic-taxonomy memory framework** with first-class consolidation (`Mental models` are LLM-synthesized) and the broadest integration surface in cohort. Skip if you want a single-binary library or AGPL/restrictive license.

## KB Architecture

### Storage
- **Vector store:** **Postgres + pgvector** (`pgvector>=0.4.1`, `psycopg2-binary>=2.9.11`); cohort-most-pgvector-native after khoj.
- **Graph store:** *None.* Entity relationships handled via `entity_resolver.py` over relational schema (similar to onyx's Postgres-as-graph approach but lighter).
- **Metadata / structured:** Postgres only; Alembic migrations under `hindsight-api-slim/hindsight_api/alembic/`.
- **Object / blob:** N/A — memory is structured rows, not document blobs.
- **Cache:** in-process; daemon worker for background tasks (`daemon.py`, `worker/`).

### Ingestion / Extraction
- **Source types accepted:** Conversational events + tool-call observations via API. Each event is processed by the consolidation pipeline.
- **Chunking strategy:** None at the input layer; memories are stored at the fact-granularity (atomic). Mental models consolidate across many facts.
- **Entity / fact extraction:** **LLM-based** via `engine/parsers/` and `engine/llm_interface.py` (OpenAI + Anthropic providers). The `entity_resolver.py` deduplicates entities across new and existing facts.
- **Schema (3-tier biomimetic memory):**
  - **World facts** — general knowledge ("The sky is blue") — atomic factual statements.
  - **Experience facts** — personal/episodic events ("I visited Paris in 2023") — time-stamped personal observations.
  - **Mental models** — consolidated knowledge synthesized from many facts ("User prefers functional programming patterns") — LLM-generated higher-order patterns; user-defined focus areas the agent should track. Defined per-bank (multi-tenancy by memory bank).

### Retrieval
- **Modes:** Hybrid via `engine/search/` (vector + structured filters); query analyzed by `engine/query_analyzer.py` to choose retrieval shape.
- **Reranker:** Cross-encoder via `engine/cross_encoder.py`. **Cohort-first: a custom Jina-MLX reranker** (`engine/jina_mlx_reranker.py`) — uses Apple MLX framework for Jina rerank model, not the official cross-encoder. Useful on Apple Silicon dev machines.
- **Top-k defaults:** Per-call.
- **Context assembly:** `memory_engine.py` orchestrates retrieval + consolidation; mental models are NOT pre-loaded into the initial prompt to keep it small (per code comments) — they're included via `based_on["mental-models"]` chain when relevant.

### Memory model
- **Tiers (biomimetic 3):** World / Experience / Mental models (above). Cohort-first 3-tier taxonomy that explicitly separates "facts the agent learned" from "patterns the agent inferred."
- **Bi-temporal:** No formal `valid_at`/`invalid_at` (graphiti style). Experience facts carry timestamps; consolidation has its own temporal logic.
- **Self-update mechanism:** Two consolidation paths — `engine/consolidation/` runs background fact-consolidation; `engine/reflect/` adds reflective synthesis (mental-model generation). Both LLM-driven.
- **Decay / forgetting:** Mental models replace older mental models on re-consolidation; facts append-only.
- **Multi-tenancy:** "Banks" — every memory belongs to a bank; `_apply_bank_tool_filtering` in MCP layer scopes tools to bank.

### MCP / connectors
- **MCP server exposed:** **Yes** — via [`hindsight-api-slim/hindsight_api/mcp_tools.py`](https://github.com/vectorize-io/hindsight/blob/main/hindsight-api-slim/hindsight_api/mcp_tools.py) using FastMCP. Notable: explicit compat layer for **FastMCP 2.x (`_tool_manager` pattern) AND 3.x (provider pattern)** — cohort first to ship dual-API-version compat. Bank-tool filtering scopes which MCP tools each bank exposes.
- **MCP client used:** Indirectly via integrations (e.g., `hindsight-integrations/openclaw/`, `claude-code/`).
- **Native connectors / agent-framework integrations:** **23 integrations** in [`hindsight-integrations/`](https://github.com/vectorize-io/hindsight/tree/main/hindsight-integrations) — `ag2`, `agentcore`, `agno`, `ai-sdk`, `autogen`, `chat`, `claude-code`, `cloudflare-oauth-proxy`, `codex`, `crewai`, `langgraph`, `litellm`, `llamaindex`, `n8n`, `nemoclaw`, `openai-agents`, `openclaw`, `opencode`, `paperclip`, `pipecat`, `pydantic-ai`, `smolagents`, `strands`. **Cohort largest** by agent-framework breadth (mem0 has 30+ vector backends; hindsight has 23 agent-framework integrations).
- **Tool-call surface:** MCP tools (above) + API HTTP endpoints (`hindsight_api/api/http.py`).

### Notable design choices
- **Biomimetic 3-tier taxonomy** — World/Experience/Mental — distinct from cohort's other taxonomies (graphiti's saga/episodic/community/entity, MaxKB's 偏好/背景/约定/目标, memvid's 7-kind, MemOS's KV-cache/LoRA/textual). Cohort first to type at the *cognitive-process level* (facts vs. inferred patterns) rather than at the structural or modality level.
- **17 sub-project monorepo** — separate packages for api / api-slim / cli / clients / control-plane / dev / docs / embed / integration-tests / integrations / tools, plus 3 distribution variants (`hindsight-all`, `hindsight-all-slim`, `hindsight-all-npm`).
- **23 agent-framework integrations** — broadest cohort surface for "drop into your existing agent runtime."
- **Custom Jina-MLX reranker** (`jina_mlx_reranker.py`) — Apple MLX backend for Jina rerank; cohort first.
- **FastMCP 2.x AND 3.x compat layer** — explicit `_tool_manager` (2.x) vs `provider` (3.x) bridging — cohort first to handle FastMCP version split.
- **Full OpenTelemetry stack** — `opentelemetry-api`, `-sdk`, `-instrumentation-fastapi`, `-exporter-prometheus`, `-exporter-otlp-proto-http`, `-semantic-conventions` — production-grade observability built in.
- **Multi-tenant via memory "Banks"** — every memory is scoped to a bank; tool-filtering per bank.
- **Commercial Hindsight Cloud** at `ui.hindsight.vectorize.io` — OSS framework + hosted product (cohort precedents: Letta + Letta Cloud, MemOS + memU bot).
- **arXiv paper** ([2512.12818](https://arxiv.org/abs/2512.12818)) — research-backed, like graphiti, MemOS, byterover-cli, memU.
- **MIT license** — fully permissive, no enterprise-bolt-on.
- **Polyglot distribution** — PyPI (`hindsight-api`) + npm (`@vectorize-io/hindsight-client`) + Helm chart + Docker Compose + cookbook recipes.

## Dependencies (KB-relevant)

From `hindsight-api-slim/pyproject.toml`:

```
name = "hindsight-api-slim"
version = "0.5.6"
license = "MIT"

# Core
fastapi[standard]>=0.120.3        # API server
pgvector>=0.4.1                   # vector store
psycopg2-binary>=2.9.11           # Postgres driver

# LLM
openai>=1.0.0
anthropic>=0.40.0

# Embedding + rerank
sentence-transformers>=3.3.0
# (custom jina_mlx_reranker.py for Apple Silicon)

# MCP
fastmcp                           # 2.x and 3.x compat in mcp_tools.py

# Observability
opentelemetry-api>=1.20.0
opentelemetry-sdk>=1.20.0
opentelemetry-instrumentation-fastapi>=0.41b0
opentelemetry-exporter-prometheus>=0.41b0
opentelemetry-exporter-otlp-proto-http>=1.20.0
opentelemetry-semantic-conventions>=0.41b0
```

License: **MIT**.

## Tradeoffs

**Pros:**
- **Biomimetic 3-tier taxonomy** is novel — separates facts (learned) from mental models (inferred) explicitly.
- **23 agent-framework integrations** — broadest cohort coverage; drops into ag2 / agentcore / agno / ai-sdk / autogen / chat / claude-code / codex / crewai / langgraph / litellm / llamaindex / n8n / nemoclaw / openai-agents / openclaw / opencode / paperclip / pipecat / pydantic-ai / smolagents / strands without rewiring.
- **FastMCP 2.x AND 3.x compat** — won't break on FastMCP version churn.
- **Full OTEL stack** — production observability out of the box.
- **MIT** — fully permissive.
- **Custom Jina-MLX reranker** — Apple Silicon friendly.
- **Massive monorepo with clean splits** — api / api-slim / cli / clients / control-plane / dev / docs / embed / integrations.
- **Research-backed** (arXiv paper).
- **Active commercial vendor** (Vectorize) — sustained development likely.

**Cons:**
- **Heavy dependency surface** — Postgres + pgvector + FastAPI + worker daemon + control-plane UI + 23 integrations.
- **No graph backend** — multi-hop relationships are SQL JOINs via `entity_resolver`, not Cypher.
- **No bi-temporal** — mental-model versioning + experience-fact timestamps approximate but not formal.
- **Single vector backend (pgvector)** — no Qdrant/Milvus/Faiss path for ops preference.
- **`hindsight-api-slim` v0.5.6** — pre-1.0; API may shift.
- **OSS + commercial split** — Hindsight Cloud is the hosted product; OSS captures the engine but enterprise ops bits may live cloud-side.
- **Created 2025-10-30** — only ~6 months old at survey time. ★11.6k in 6 months is rapid; trajectory worth watching.

## When to use it

- **Good fit:** teams using one of the 23 supported agent frameworks (especially langgraph / ag2 / autogen / crewai / pydantic-ai / smolagents) who want drop-in memory with explicit "facts vs. inferred patterns" separation; products needing full OTEL observability; teams comfortable on Postgres+pgvector.
- **Bad fit:** single-binary deployments (use memvid / basic-memory); graph-reasoning workflows (use graphiti / cognee); teams allergic to commercial-vendor open-core models; AGPL/Apache-only legal envelopes (MIT is fine — but the "open core + commercial cloud" pattern may.) Skip if you want a research-grade single-tier flat-fact memory (mem0 is closer).
- **Closest alternatives (in this cohort):** [`mem0ai/mem0`](mem0ai__mem0.md) — also memory-framework, but mem0 is concrete-engine-with-many-backends; hindsight is biomimetic-taxonomy-with-many-integrations. [`MemTensor/MemOS`](MemTensor__MemOS.md) is research-shaped peer with 3-tier *cross-modality* taxonomy (KV-cache/LoRA/textual); hindsight's 3-tier is *cognitive-process* (facts/experience/mental-models). [`getzep/graphiti`](getzep__graphiti.md) is the bi-temporal alternative; hindsight has consolidation but not formal `valid_at`/`invalid_at`.

## Code pointers (evidence)

- 3-tier biomimetic memory definitions: [`CLAUDE.md`](https://github.com/vectorize-io/hindsight/blob/main/CLAUDE.md) (top-level overview)
- Memory engine orchestrator: [`hindsight-api-slim/hindsight_api/engine/memory_engine.py`](https://github.com/vectorize-io/hindsight/blob/main/hindsight-api-slim/hindsight_api/engine/memory_engine.py) (mental-model loading, `based_on["mental-models"]` chain)
- Engine modules: [`hindsight-api-slim/hindsight_api/engine/`](https://github.com/vectorize-io/hindsight/tree/main/hindsight-api-slim/hindsight_api/engine) — `consolidation/`, `cross_encoder.py`, `directives/`, `embeddings.py`, `entity_resolver.py`, `jina_mlx_reranker.py`, `parsers/`, `providers/`, `query_analyzer.py`, `reflect/`, `retain/`, `search/`, `sql/`, `storage/`
- MCP layer with FastMCP 2.x/3.x compat: [`hindsight-api-slim/hindsight_api/mcp_tools.py`](https://github.com/vectorize-io/hindsight/blob/main/hindsight-api-slim/hindsight_api/mcp_tools.py)
- 23 agent-framework integrations: [`hindsight-integrations/`](https://github.com/vectorize-io/hindsight/tree/main/hindsight-integrations)
- API entry: [`hindsight-api-slim/hindsight_api/main.py`](https://github.com/vectorize-io/hindsight/blob/main/hindsight-api-slim/hindsight_api/main.py)
- 17 sub-project layout: top-level `hindsight-*/` directories
- Most useful single file to read first: [`CLAUDE.md`](https://github.com/vectorize-io/hindsight/blob/main/CLAUDE.md) — concise project overview + bicommit memory taxonomy spec.

## Open questions

- The biomimetic 3-tier (World/Experience/Mental) maps loosely to MemOS's KV-cache/LoRA/textual but at a different layer (cognitive process vs. modality). Are both productive or does one subsume the other?
- Mental-model consolidation cost — how often does `engine/consolidation/` re-fire? Per-event, scheduled, or threshold-triggered?
- 23 integrations — what's the actual completeness per integration? Some likely have minimal stubs.
- FastMCP 2.x vs 3.x compat — once 3.x stabilizes, will the 2.x path be removed? Worth tracking.
- The arXiv paper number `2512.12818` (Dec 2025) is recent — has anyone reproduced the SOTA claims independently?

---

*Surveyed via the `curating-agentic-kbs` skill. Re-survey scheduled after 30 days of last `pushed_at` change.*

*Audit 2026-05-02: clone-verified against [`CLAUDE.md`](https://github.com/vectorize-io/hindsight/blob/main/CLAUDE.md), [`hindsight-api-slim/pyproject.toml`](https://github.com/vectorize-io/hindsight/blob/main/hindsight-api-slim/pyproject.toml) (v0.5.6, MIT), [`hindsight-api-slim/hindsight_api/engine/`](https://github.com/vectorize-io/hindsight/tree/main/hindsight-api-slim/hindsight_api/engine), [`hindsight-integrations/`](https://github.com/vectorize-io/hindsight/tree/main/hindsight-integrations) (23 integrations exact). Initial survey written from clone (no prior version to correct). **Verified verbatim:** biomimetic 3-tier taxonomy (World facts / Experience facts / Mental models — exact wording from CLAUDE.md and `engine/response_models.py`), 23 integrations exact list, FastMCP 2.x/3.x compat layer in `mcp_tools.py`, custom `jina_mlx_reranker.py` (Apple MLX), full OTEL stack (6 packages), `hindsight-api-slim 0.5.6` MIT.*

*This survey was promoted from `candidates` → first cohort survey added post-30 baseline. **N=30 cohort aggregate is NOT yet recomputed** (would require re-percentaging all adoption tables to N=31 + adding hindsight to applicable rows). Next iteration should fold this in via the L16 awk pass + cohort table append.*
