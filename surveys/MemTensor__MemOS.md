# Survey: MemTensor/MemOS

**Date:** 2026-05-02
**Stars:** 8,845 · **Last push:** 2026-04-29 · **Created:** 2025 · **Version:** `2.0.14` (codename "Stardust")
**Category:** memory-framework
**Slug:** [MemTensor/MemOS](https://github.com/MemTensor/MemOS)

---

## TL;DR (3 lines)

- **What it is:** Research-grade memory framework from MemTensor (PyPI: `MemoryOS`, v2.0.14, Apache-2.0). Backed by an arXiv paper ([2507.03724](https://arxiv.org/abs/2507.03724)) and benchmark claims of "+43.70% Accuracy vs. OpenAI Memory" / "LoCoMo 75.80" / "LongMemEval +40.43%". The codename "Stardust" tracks v2.0.
- **How its KB works:** **Three explicitly-typed memory tiers wrapped in a `MemCube`** — `ActivationMemory` (transformer KV-cache via `transformers.DynamicCache` + vLLM variant), `ParametricMemory` (LoRA-as-memory, currently a placeholder), `TextualMemory` (5+ implementations: `simple`, `naive`, `tree`, `tree_text_memory`, `prefer_text_memory`). Three graph backends (Neo4j community/enterprise, **PolarDB** — Alibaba's Postgres fork, Postgres) + Milvus / Qdrant for vectors + sentence-transformers / OpenAI / Ollama for embeddings. **Cohort first**: KV-cache and parametric (LoRA) tiers are explicit memory types alongside the textual one.
- **Verdict:** Pick when you need a **research-shaped multi-tier memory framework** that distinguishes activation / parametric / textual memories, scales across multiple "MemCubes" (multi-tenant memory containers), and ships a FastMCP server out of the box. Skip if you want a single-binary library or a simple write-through KV — MemOS is heavier and more research-paper-shaped than mem0 / graphiti.

## KB Architecture

### Storage
- **Vector store:** **Milvus** (`pymilvus`) and **Qdrant** (`qdrant-client`) shipped as first-class extras. Embeddings come from sentence-transformers locally or OpenAI / Ollama remotely via the `embedders/` factory.
- **Graph store:** [`src/memos/graph_dbs/`](https://github.com/MemTensor/MemOS/tree/main/src/memos/graph_dbs) — pluggable factory with **Neo4j** (separate `neo4j.py` + `neo4j_community.py` to handle Community Edition's lack of `CREATE DATABASE` admin commands), **PolarDB** (Alibaba's Postgres fork — cohort first), and **Postgres** (with Apache AGE for graph). The Postgres + PolarDB integration treats relational rows as graph nodes, similar to onyx but exposed through a graph_db interface rather than as KG schema.
- **Metadata / structured:** Postgres / MySQL / SQLite via SQLAlchemy 2 — `pymysql` is a hard dep (suggesting MySQL is a primary deployment target alongside Postgres). Multi-MemCube state lives in `multi_mem_cube/`.
- **Object / blob:** Local filesystem; `download_repo` utility in `mem_cube/utils.py` fetches MemCubes from remote sources (memcube-as-distributable-artifact, like a Docker image for memory).

### Ingestion / Extraction
- **Source types accepted:** Conversational turns + documents + multi-modal inputs. [`mem_reader/`](https://github.com/MemTensor/MemOS/tree/main/src/memos/mem_reader) splits ingestion across `read_multi_modal`, `read_pref_memory`, `read_skill_memory`, `simple_struct`, `strategy_struct`, plus `multi_modal_struct.py`. `parsers/` handles file format dispatch.
- **Chunking strategy:** [`chunkers/`](https://github.com/MemTensor/MemOS/tree/main/src/memos/chunkers) module with multiple strategies; tree-text-memory variants implement hierarchical structuring at write time rather than chunking at read time.
- **Entity / fact extraction:** **LLM-based** — preference extractor at [`src/memos/memories/textual/prefer_text_memory/extractor.py`](https://github.com/MemTensor/MemOS/blob/main/src/memos/memories/textual/prefer_text_memory/extractor.py); tree-memory organize/retrieve split. The `mem_feedback/` module learns from explicit user feedback signals on retrieved memories.
- **Schema:** **Three-tier explicit memory taxonomy** — `BaseActMemory` (KV cache items), `BaseParaMemory` (parametric/LoRA items), `BaseTextMemory` (textual items). Within textual: simple, naive, tree, tree_text_memory, prefer_text_memory, simple_preference variants — most internal-implementation diversity in cohort.

### Retrieval
- **Modes:** Tree-text-memory has its own `retrieve/` subpackage; preference-text-memory has dedicated `retrievers.py`. The [`search/`](https://github.com/MemTensor/MemOS/tree/main/src/memos/search) module composes vector + graph + structured retrieval per memory type. `mem_agent/deepsearch_agent.py` provides agent-driven multi-step retrieval (cohort first calling it explicitly *deep search* in a memory framework — onyx has Deep Research but as a separate orchestration layer).
- **Reranker:** Dedicated `reranker/` module; sentence-transformers integration suggests local cross-encoder support, plus pluggable LLM-as-reranker.
- **Top-k defaults:** Per memory-tier configurable; not a single global k.
- **Context assembly:** `context/` + `multi_mem_cube/` compose retrieval results across cubes; the `mem_chat/` module wires retrieval into chat orchestration.

### Memory model
- **Tiers:** **Three-tier explicit taxonomy** — the cohort's most ambitious memory typing.
  - **`ActivationMemory`** ([memories/activation/](https://github.com/MemTensor/MemOS/tree/main/src/memos/memories/activation)) — KV-cache as memory. `kv.py` uses `transformers.DynamicCache`; `vllmkv.py` integrates with vLLM; items are pickled to disk as `KVCacheItem`. **First cohort entry treating transformer KV-cache as a persisted memory tier**.
  - **`ParametricMemory`** ([memories/parametric/](https://github.com/MemTensor/MemOS/tree/main/src/memos/memories/parametric)) — LoRA weights as memory. Currently a placeholder (`lora.py` is `TODO: This file currently serves as a placeholder. The actual implementation will be added here in the future.`), but the *typing* is in place. **First cohort entry treating fine-tuned weights as a memory tier**.
  - **`TextualMemory`** ([memories/textual/](https://github.com/MemTensor/MemOS/tree/main/src/memos/memories/textual)) — five variants: `simple`, `naive`, `tree`, `tree_text_memory` (with organize/retrieve subpackages), `prefer_text_memory` (preference extractor + adder + retrievers + spliter + factory). Plus `simple_preference.py` and a top-level `preference.py`.
  - **`MemCube`** ([mem_cube/general.py](https://github.com/MemTensor/MemOS/blob/main/src/memos/mem_cube/general.py)) — a "box" that loads all three memory types from a unified config. `BaseMemCube` ABC with `general` and `naive` (`navie.py`) implementations. **Multi-MemCube support** in [`multi_mem_cube/`](https://github.com/MemTensor/MemOS/tree/main/src/memos/multi_mem_cube) for multi-tenant memory.
- **Bi-temporal:** No formal bi-temporal model; tree-text-memory has hierarchical structure but not `valid_at`/`invalid_at`.
- **Self-update mechanism:** [`mem_scheduler/`](https://github.com/MemTensor/MemOS/tree/main/src/memos/mem_scheduler) — sophisticated scheduler with `analyzer/`, `monitors/`, `task_schedule_modules/`, `webservice_modules/`, `orm_modules/`, `general_modules/`, `memory_manage_modules/` + base/general/optimized scheduler variants. Schedules consolidation, eviction, and re-embedding tasks. Cohort first to ship a *named scheduler subsystem* for memory.
- **Decay / forgetting:** `mem_feedback/` learns from feedback signals to weight retention; `tree_text_memory/organize/` organizes/reorganizes tree structure over time. No explicit TTL.

### MCP / connectors
- **MCP server exposed:** **Yes — `src/memos/api/mcp_serve.py`** ([source](https://github.com/MemTensor/MemOS/blob/main/src/memos/api/mcp_serve.py)) wraps the `MOS` (Memory OS) class as a `FastMCP` server. Explicit guidance for Neo4j Community Edition deployment baked into the loader (`NEO4J_DB_NAME=neo4j`, `NEO4J_AUTO_CREATE=false`, `NEO4J_USE_MULTI_DB=false`).
- **MCP client used:** Implicit through the deepsearch agent and tool-call surface; the `memos_tools/` module exposes capabilities for downstream MCP clients to consume.
- **Native connectors:** Four shipped apps in [`apps/`](https://github.com/MemTensor/MemOS/tree/main/apps) — `MemOS-Cloud-OpenClaw-Plugin`, `memos-local-openclaw`, `memos-local-plugin`, `openwork-memos-integration`. The "OpenClaw" naming suggests integration with a parent platform; the local-plugin variants are self-hosted equivalents.
- **Tool-call surface:** [`memos_tools/`](https://github.com/MemTensor/MemOS/tree/main/src/memos/memos_tools) + `mem_agent/` + the deepsearch agent. Plugin/hooks system at [`plugins/`](https://github.com/MemTensor/MemOS/tree/main/src/memos/plugins) — explicit `register_hook(name, callback)` API + `@hookable` decorator + hook-spec registry (`hook_defs.py`).

### Notable design choices
- **Three-tier explicit memory typing (Activation / Parametric / Textual)** — cohort first. KV-cache memory and LoRA-as-memory have well-known research lineage; MemOS exposes them as plain ABCs with concrete implementations alongside textual memory.
- **MemCube as the primary distributable** — `download_repo` utility in `mem_cube/utils.py` suggests "memory cubes" can be fetched from remote repos like model weights or container images. Multi-MemCube extends this to multi-tenant.
- **PolarDB graph backend** — only repo in cohort with explicit Alibaba PolarDB support; signals CN-cloud-friendly distribution.
- **Sophisticated scheduler subsystem** — analyzer / monitors / task / webservice / ORM modules with base/general/optimized scheduler variants. No other memory framework in the cohort gives the scheduler this much surface area.
- **Hookable plugin system** ([`src/memos/plugins/hooks.py`](https://github.com/MemTensor/MemOS/blob/main/src/memos/plugins/hooks.py)) — 4-function API: `register_hook(name, callback)` (single), `register_hooks(...)` (multi), `trigger_hook(...)` (manual fire), and the `@hookable` decorator (`hooks.py:103`) that auto-declares before/after Hooks for the wrapped method. `hook_defs.py` is the registry for typed hook specs. Closer to a runtime plugin framework than mem0's lifecycle hooks or claude-mem's lifecycle events.
- **Multi-modal mem_reader** — `read_multi_modal`, `read_pref_memory`, `read_skill_memory` have separate implementations. Skills as a memory type is an interesting framing.
- **DeepSearch agent** — explicit naming alongside onyx's Deep Research and graphrag's DRIFT search. Three repos converging on "agent-driven multi-step retrieval as a named feature."
- **Neo4j Community-Edition guidance baked in** — the MCP loader documents the env vars needed to avoid `CREATE DATABASE` errors, suggesting CE is an expected deployment target.
- **Apache-2.0** — permissive, MIT-equivalent for redistribution.

## Dependencies (KB-relevant)

From `pyproject.toml`:

```
name = "MemoryOS"
version = "2.0.14"
license = "Apache-2.0"
requires-python = ">=3.10"

# Core
openai (>=1.77.0,<2.0.0)
ollama (>=0.5.0,<0.5.1)
transformers (>=4.51.3,<5.0.0)         # KV-cache memory
fastapi[all]                            # web API
sqlalchemy (>=2.0.41,<3.0.0)
pymysql                                 # MySQL driver
fastmcp (>=2.10.5,<3.0.0)               # MCP server

# Vector / Graph (extras)
neo4j (>=5.28.1,<6.0.0)
pymilvus (>=2.5.12,<3.0.0)
qdrant-client (>=1.16.0,<2.0.0)
sentence-transformers (>=4.1.0,<5.0.0)

# ML / Observability
scikit-learn (>=1.7.0,<2.0.0)
prometheus-client (>=0.23.1,<0.24.0)
tenacity                                # retry
concurrent-log-handler                  # process-safe rotating logs
```

License: **Apache-2.0**.

## Tradeoffs

**Pros:**
- **Three-tier memory typing** — KV-cache + LoRA + textual is the most research-faithful taxonomy in cohort; if you're building research/eval pipelines, this matches the literature.
- **MemCube + Multi-MemCube** — distributable memory containers with a clean per-cube ABC and multi-tenant variant.
- **Sophisticated scheduler** — analyzer/monitors/task/webservice/ORM modules give you observability + persistence + retry semantics for memory operations.
- **Hookable plugin system** — 4-function API (`register_hook` / `register_hooks` / `trigger_hook` + `@hookable` decorator) is closer to a real runtime extension API than the lifecycle hooks most repos ship.
- **Three graph backends** including the cohort's only PolarDB integration.
- **FastMCP server with environment-aware Neo4j-Community guidance** — you can drop-in to Claude Code / Cursor and the loader handles common CE pitfalls.
- **Strong benchmark claims** with linked paper and reproducible eval harness in [`evaluation/`](https://github.com/MemTensor/MemOS/tree/main/evaluation).

**Cons:**
- **LoRA memory is a placeholder** — `parametric/lora.py` explicitly says "do not use this as a functional module yet". The typing is there but the implementation isn't.
- **Three-tier abstraction has overhead** — for projects that just want write-through atomic facts (mem0's shape), MemOS asks you to set up a `MemCube` config, choose backends for three tiers, and run a scheduler.
- **`MemoryOS` PyPI name vs `MemOS` repo name** — confusion-prone. PyPI `pip install MemoryOS` while the GitHub project is "MemOS". 
- **Heavy dependency surface** — Milvus + Qdrant + Neo4j + PolarDB + Postgres + sentence-transformers + transformers + vLLM + sklearn + Prometheus + FastAPI all coexist.
- **Research-paper-shaped, not always production-shaped** — benchmark numbers are loud, but "MemOS 2.0 Stardust" naming and the rapid major-version pace suggest fast-moving research, not a stable LTS.
- **MCP client surface is implicit** — there's a tool-call surface but the way an external MCP client integrates with the MemOS plugin system isn't as explicit as ragflow / mem0.
- **No native bi-temporal model** — tree-text-memory has structure, but no `valid_at`/`invalid_at` like graphiti.

## When to use it

- **Good fit:** research projects benchmarking against LoCoMo / LongMemEval / PrefEval; teams that need transformer KV-cache as a persisted memory tier; deployments wanting MemCube-as-distributable artifacts (think "memory image" the way Docker is "filesystem image"); CN-cloud deployments needing PolarDB graph storage; products that want a typed scheduler subsystem with analyzer/monitors/ORM out of the box.
- **Bad fit:** simple agent-memory needs (use [`mem0ai/mem0`](surveys/mem0ai__mem0.md)); products needing bi-temporal `valid_at` / `invalid_at` (use [`getzep/graphiti`](surveys/getzep__graphiti.md)); single-binary or laptop-grade deployments (use [`memvid/memvid`](surveys/memvid__memvid.md) or [`basicmachines-co/basic-memory`](surveys/basicmachines-co__basic-memory.md)); strict Apache-2.0 envelopes that won't accept the dependency surface.
- **Closest alternative:** [`mem0ai/mem0`](surveys/mem0ai__mem0.md) — same "agent memory framework" category, but mem0 is flat-fact-only with 30+ vector backends and a single-LLM-extraction prompt; MemOS is three-tier-typed with KV-cache + parametric + textual + a scheduler. [`topoteretes/cognee`](surveys/topoteretes__cognee.md) overlaps on "research-shaped memory framework with multiple stores" but cognee leans more on RDF/OWL ontologies and "memify" pipelines; MemOS leans on transformer-tier memory abstractions.

## Code pointers (evidence)

- Three-tier memory ABCs + factory: [`src/memos/memories/`](https://github.com/MemTensor/MemOS/tree/main/src/memos/memories) (`activation/base.py`, `parametric/base.py`, `textual/base.py`, `factory.py`)
- KV-cache memory (`transformers.DynamicCache` + vLLM variant): [`src/memos/memories/activation/kv.py`](https://github.com/MemTensor/MemOS/blob/main/src/memos/memories/activation/kv.py), [`vllmkv.py`](https://github.com/MemTensor/MemOS/blob/main/src/memos/memories/activation/vllmkv.py)
- LoRA memory (placeholder): [`src/memos/memories/parametric/lora.py`](https://github.com/MemTensor/MemOS/blob/main/src/memos/memories/parametric/lora.py)
- Tree-text-memory + preference-text-memory: [`src/memos/memories/textual/tree_text_memory/`](https://github.com/MemTensor/MemOS/tree/main/src/memos/memories/textual/tree_text_memory) (organize/retrieve), [`prefer_text_memory/`](https://github.com/MemTensor/MemOS/tree/main/src/memos/memories/textual/prefer_text_memory) (extractor/adder/retrievers/spliter/factory)
- MemCube ABC + general/naive impls: [`src/memos/mem_cube/general.py`](https://github.com/MemTensor/MemOS/blob/main/src/memos/mem_cube/general.py)
- Multi-MemCube: [`src/memos/multi_mem_cube/`](https://github.com/MemTensor/MemOS/tree/main/src/memos/multi_mem_cube)
- Graph DB factory (Neo4j community/enterprise + PolarDB + Postgres): [`src/memos/graph_dbs/`](https://github.com/MemTensor/MemOS/tree/main/src/memos/graph_dbs) (`neo4j.py`, `neo4j_community.py`, `polardb.py`, `postgres.py`, `factory.py`)
- Scheduler (analyzer / monitors / task / webservice / ORM): [`src/memos/mem_scheduler/`](https://github.com/MemTensor/MemOS/tree/main/src/memos/mem_scheduler)
- DeepSearch agent: [`src/memos/mem_agent/deepsearch_agent.py`](https://github.com/MemTensor/MemOS/blob/main/src/memos/mem_agent/deepsearch_agent.py)
- FastMCP server with Neo4j-CE guidance: [`src/memos/api/mcp_serve.py`](https://github.com/MemTensor/MemOS/blob/main/src/memos/api/mcp_serve.py)
- Hookable plugin system: [`src/memos/plugins/`](https://github.com/MemTensor/MemOS/tree/main/src/memos/plugins) (`hooks.py`, `hook_defs.py`, `manager.py`, `component_bootstrap.py`)
- Apps shipped: [`apps/`](https://github.com/MemTensor/MemOS/tree/main/apps) (MemOS-Cloud-OpenClaw-Plugin / memos-local-openclaw / memos-local-plugin / openwork-memos-integration)
- Most useful single file to read first: [`src/memos/mem_cube/general.py`](https://github.com/MemTensor/MemOS/blob/main/src/memos/mem_cube/general.py) — the MemCube is the architectural center; understanding how it composes the three memory tiers maps the entire framework.

## Open questions

- LoRA memory is explicitly a placeholder — what's the timeline for actual implementation? The arXiv paper presumably describes the design; the code lags.
- MemCube `download_repo` semantics — is there a registry for distributable MemCubes (analogous to Docker Hub)? Or is it just `git clone`-shaped?
- The benchmark gains (+43.70% vs OpenAI Memory) — what eval methodology and which OpenAI memory variant? The README links a paper but the comparative setup matters for replication.
- DeepSearch agent vs onyx Deep Research vs graphrag DRIFT — three independent implementations of "multi-step agent retrieval"; convergent design, but how do they compare empirically?
- The OpenClaw integration — is this MemTensor's parent company's platform, or a third-party? Worth a deeper read of `apps/MemOS-Cloud-OpenClaw-Plugin`.

---

*Surveyed via the `curating-agentic-kbs` skill. Re-survey scheduled after 30 days of last `pushed_at` change.*

*Audit 2026-05-02: clone-verified against [`pyproject.toml`](https://github.com/MemTensor/MemOS/blob/main/pyproject.toml) (v2.0.14, Apache-2.0), [`src/memos/memories/`](https://github.com/MemTensor/MemOS/tree/main/src/memos/memories) (3-tier subdirs: `activation` / `parametric` / `textual`), [`src/memos/memories/textual/tree_text_memory/`](https://github.com/MemTensor/MemOS/tree/main/src/memos/memories/textual/tree_text_memory), [`src/memos/graph_dbs/`](https://github.com/MemTensor/MemOS/tree/main/src/memos/graph_dbs) (incl. `polardb.py`), [`src/memos/mem_agent/deepsearch_agent.py`](https://github.com/MemTensor/MemOS/blob/main/src/memos/mem_agent/deepsearch_agent.py), [`src/memos/plugins/hooks.py`](https://github.com/MemTensor/MemOS/blob/main/src/memos/plugins/hooks.py), [`apps/`](https://github.com/MemTensor/MemOS/tree/main/apps) (4 first-party apps). **All major cohort-first claims verified verbatim:** 3-tier cross-modality memory taxonomy (ActivationMemory / ParametricMemory / TextualMemory), MemCube + Multi-MemCube + GeneralMemCube, PolarDB graph backend, deepsearch_agent, tree-text-memory, 4 shipped apps (`MemOS-Cloud-OpenClaw-Plugin` / `memos-local-openclaw` / `memos-local-plugin` / `openwork-memos-integration`), `prometheus-client>=0.23.1` + `concurrent-log-handler>=0.9.28` deps, hookable plugin system. **Minor enhancement:** hookable API surface clarified — 4 functions (`register_hook` + `register_hooks` (plural) + `trigger_hook` + `@hookable` decorator), survey originally listed only 2 of the 4. Added version `2.0.14`. **No corrections needed** — survey quality matches cognee / microsoft-graphrag / deepwiki-open tier.*

*Re-audit iter 78 (2026-05-03): re-verified version pin. Architectural state unchanged: v2.0.14 (codename "Stardust") still current, Apache-2.0 unchanged, PolarDB graph backend still listed. ★8,845 → ★8,862 (+17 stars, ~0.19% growth in 2 days — moderate velocity). `pushed_at` 2026-04-29 → 2026-05-01 (+2 days, modest activity). No corrections needed.*
