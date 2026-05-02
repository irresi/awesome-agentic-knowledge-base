# Survey: NevaMind-AI/memU

**Date:** 2026-05-02
**Stars:** 13,503 · **Last push:** 2026-04-22 · **Created:** 2025-07 · **Version:** `memu-py 1.5.1` (Python ≥3.13, Apache-2.0; Rust core via PyO3 0.27.1 with abi3-py313)
**Category:** memory-framework
**Slug:** [NevaMind-AI/memU](https://github.com/NevaMind-AI/memU)

---

## TL;DR (3 lines)

- **What it is:** "24/7 Always-On Proactive Memory for AI Agents" — memU is a Python (3.13+) memory framework with a **Rust core via PyO3** (maturin build, `_core.pyi`). PyPI: `memu-py` v1.5.1. Apache-2.0. By NevaMind-AI; positioned as "the enterprise-ready OpenClaw" — a commercial product (memU Bot at memu.bot) sits alongside the OSS framework.
- **How its KB works:** **"Memory as File System, File System as Memory"** — same architectural metaphor as OpenViking but framed without an explicit ragfs/Rust-FS layer. **Categories = folders** (auto-organized topics), **MemoryItems = files** (extracted facts/preferences/skills). 3 storage backends (in-memory / SQLite / Postgres) behind a `factory.py` + `interfaces.py` abstraction. **Workflow pipeline** with `interceptor.py` + `step.py` + `pipeline.py` + `runner.py`.
- **Verdict:** Pick when you want the **filesystem-paradigm memory model** with a Python API, Rust core for hot paths, Apache-2.0 licensing, and LangGraph integration. Skip if you want a server-shaped product (use memU Bot or onyx) or the explicit Rust-FS-plugin abstraction (use OpenViking).

## KB Architecture

### Storage
- **Vector store:** *Not native* — embeddings via `embedding/` module; vector storage is whatever the backend provides (Postgres + pgvector likely; in-memory uses Python structures).
- **Graph store:** *None.*
- **Metadata / structured:** **3 backends** at [`src/memu/database/`](https://github.com/NevaMind-AI/memU/tree/main/src/memu/database) — `inmemory/`, `sqlite/`, `postgres/` behind a unified `factory.py` + `interfaces.py` + `state.py`. SQLModel + Alembic for migrations.
- **Object / blob:** [`src/memu/blob/`](https://github.com/NevaMind-AI/memU/tree/main/src/memu/blob) — local blob storage abstraction.

### Ingestion / Extraction
- **Source types accepted:** Conversational messages (primary), plus tool-call results (`ToolCallResult` Pydantic model with hash-tracked content).
- **Chunking strategy:** Implicit — memory items are extracted at the granularity of "a fact / preference / skill," not chunked by tokens.
- **Entity / fact extraction:** **LLM-driven** via `app/memorize.py`. Categories are auto-organized topics; the LLM decides what to put in each.
- **Schema:** **Pydantic models** at [`src/memu/database/models.py`](https://github.com/NevaMind-AI/memU/blob/main/src/memu/database/models.py) — `BaseRecord` → `Resource`, `MemoryItem`, `MemoryCategory`, `CategoryItem`. `compute_content_hash` for deduplication.

### Retrieval
- **Modes:** Vector + structured retrieval via `app/retrieve.py`. Workflow pipeline can compose retrieval steps.
- **Reranker:** Not native; relies on embedding-similarity ordering.
- **Top-k defaults:** Per call.
- **Context assembly:** Workflow pipeline composes retrieve → memorize → patch → CRUD steps. The `app/service.py` is the high-level orchestrator.

### Memory model
- **Tiers:** Memory items + memory categories — flat-with-folder hierarchy; the "filesystem" metaphor frames everything as a file in a folder.
- **Bi-temporal:** No.
- **Self-update mechanism:** Workflow pipeline ([`workflow/pipeline.py`](https://github.com/NevaMind-AI/memU/blob/main/src/memu/workflow/pipeline.py) + `runner.py` + `step.py`) executes consolidation steps; `interceptor.py` for cross-cutting concerns. **24/7 always-on** framing implies background workers consuming events without explicit triggers.
- **Decay / forgetting:** Not explicit; workflow steps can implement custom logic.

### MCP / connectors
- **MCP server exposed:** Likely via `app/service.py` HTTP layer (not explicitly verified).
- **MCP client used:** Not in core deps.
- **Native connectors:** **LangGraph integration** ([`integrations/langgraph.py`](https://github.com/NevaMind-AI/memU/blob/main/src/memu/integrations/langgraph.py)). Cohort-second LangGraph integration after deer-flow (built on LangGraph) and MaxKB (uses LangGraph).
- **Tool-call surface:** `ToolCallResult` is a first-class memory record type with hash-based dedup. `BaseRecord.generate_hash` + `ensure_hash` baked into the schema.

### Notable design choices
- **Rust core via PyO3** ([`Cargo.toml`](https://github.com/NevaMind-AI/memU/blob/main/Cargo.toml) + `lib.rs` + maturin build) — Python is the surface, Rust handles hot paths via `_core.pyi` extension module. abi3-py313 stable ABI. Cohort second after memvid for Python-with-Rust-core (memvid is Rust-with-Python-wrapper; memU is Python-with-Rust-extension).
- **Filesystem metaphor** — same architectural framing as OpenViking but without the explicit virtual-FS abstraction. Categories = folders, MemoryItems = files.
- **3-backend factory** (in-memory / SQLite / Postgres) — reasonable spread; Postgres is the production target.
- **`compute_content_hash` deduplication** baked into `BaseRecord` — every record has `generate_hash` + `ensure_hash`. Cohort first to make hash-dedup a base-class concern.
- **Workflow pipeline with `interceptor`** — workflow primitive separates step logic from cross-cutting concerns (logging, retry, etc.). Closer to a real orchestration runtime than a simple chain-of-functions.
- **`memU Bot` commercial offering** — at memu.bot; positioned as "OpenClaw alternative". OSS framework + commercial assistant pattern (cohort precedents: Letta + Letta Cloud, OpenViking + Volcengine hosting).
- **Python 3.13+ requirement** — bleeding-edge Python; cohort highest minimum version (most other repos target 3.10 or 3.11).
- **6 README languages** — EN / 中文 / 日本語 / 한국어 / Español / Français.
- **`lazyllm`** as a dep — a lazy-evaluation LLM framework (a less-common choice; signals "evaluate prompts lazily" pattern).
- **`pendulum>=3.1.0`** for time handling — high-quality datetime library; signals attention to time-zone correctness.
- **`langchain-core>=1.2.7`** as a hard dep, but no other langchain-* packages in core — minimal LangChain coupling.
- **Apache-2.0** with no enterprise bolt-on; commercial offering is hosted, not source-restricted.

## Dependencies (KB-relevant)

From `pyproject.toml`:

```
name = "memu-py"
version = "1.5.1"
license = "Apache-2.0"
requires-python = ">=3.13"

# Core
sqlmodel >= 0.0.27
alembic >= 1.14.0
pydantic >= 2.12.4
openai >= 2.8.0
httpx >= 0.28.1
numpy >= 2.3.4
defusedxml >= 0.7.1                # safe XML parsing

# Time
pendulum >= 3.1.0

# LLM-side
langchain-core >= 1.2.7            # minimal LangChain coupling
lazyllm >= 0.7.3                   # lazy-evaluation LLM framework

# Build
maturin >= 1.0,<2.0                # PyO3 Rust extension build
```

`Cargo.toml`:

```
[package] name = "memu", edition = "2024"
[lib] crate-type = ["cdylib"]
[dependencies]
pyo3 = { version = "0.27.1", features = ["extension-module", "abi3-py313"] }
```

License: **Apache-2.0**.

## Tradeoffs

**Pros:**
- **Rust core via PyO3** — Python ergonomics + Rust performance for hot paths.
- **3-backend factory** with clean ABC — production-grade Postgres + dev-friendly in-memory/SQLite.
- **Hash-dedup as a base-class concern** — `compute_content_hash` + `generate_hash` + `ensure_hash` ensure no duplicate records by design.
- **Workflow pipeline with interceptors** — cross-cutting concerns are first-class.
- **LangGraph integration** in `integrations/` — drops into LangGraph workflows.
- **Filesystem metaphor** — clear conceptual mapping for folks coming from OpenViking / file-shaped mental models.
- **Apache-2.0** with no enterprise bolt-on.
- **Active development** — last push 10 days before survey.

**Cons:**
- **Python 3.13+ requirement** — bleeding-edge; some deployments still on 3.11/3.12.
- **`maturin` build complexity** — Rust toolchain required to install from source (PyPI wheels mitigate).
- **Memory model less explicit than competitors** — categories + items but no MaxKB-style 4-category enum or memvid-style 6-kind taxonomy.
- **Bi-temporal not supported** — no time-aware queries.
- **Recent-ish project** (~10 months at survey time) — production maturity unproven.
- **Single integration (LangGraph)** — no MCP, no claude-agent-sdk in core; users wire integrations themselves.
- **`lazyllm` is a less-common framework** — adds a long-tail dependency.
- **OpenClaw / memU Bot framing** — promotional README language is dense; OSS vs commercial line worth reading carefully.

## When to use it

- **Good fit:** teams wanting filesystem-paradigm memory with Python ergonomics + Rust hot paths; LangGraph deployments needing a memory framework integration; Apache-2.0 envelopes; production targets where 3-backend pluggability + hash-dedup matter.
- **Bad fit:** Python <3.13 deployments; teams wanting comprehensive memory taxonomies (use MemOS / memvid / MaxKB); products needing graph reasoning (use graphiti / cognee); single-binary deployments (use memvid).
- **Closest alternative:** [`volcengine/OpenViking`](surveys/volcengine__OpenViking.md) — same filesystem-paradigm framing but with explicit ragfs Rust crate + L0/L1/L2 tiered loading + AGPL. memU is Apache-2.0 + cleaner Python API + Rust extension. [`MemTensor/MemOS`](surveys/MemTensor__MemOS.md) is the research-shaped peer (3-tier memory + MemCube). [`mem0ai/mem0`](surveys/mem0ai__mem0.md) is the older flat-fact-with-30-backends alternative.

## Code pointers (evidence)

- 3-backend database factory: [`src/memu/database/`](https://github.com/NevaMind-AI/memU/tree/main/src/memu/database) (`inmemory/`, `sqlite/`, `postgres/`, `factory.py`, `interfaces.py`, `state.py`, `repositories/`)
- Pydantic data model: [`src/memu/database/models.py`](https://github.com/NevaMind-AI/memU/blob/main/src/memu/database/models.py) — `BaseRecord` / `Resource` / `MemoryItem` / `MemoryCategory` / `CategoryItem` / `ToolCallResult`
- Workflow pipeline (interceptor + pipeline + runner + step): [`src/memu/workflow/`](https://github.com/NevaMind-AI/memU/tree/main/src/memu/workflow)
- LangGraph integration: [`src/memu/integrations/langgraph.py`](https://github.com/NevaMind-AI/memU/blob/main/src/memu/integrations/langgraph.py)
- App layer (CRUD / memorize / patch / retrieve / service / settings): [`src/memu/app/`](https://github.com/NevaMind-AI/memU/tree/main/src/memu/app)
- Rust extension entry: [`src/lib.rs`](https://github.com/NevaMind-AI/memU/blob/main/src/lib.rs) + [`Cargo.toml`](https://github.com/NevaMind-AI/memU/blob/main/Cargo.toml) (PyO3 0.27.1, abi3-py313)
- LLM + embedding modules: [`src/memu/llm/`](https://github.com/NevaMind-AI/memU/tree/main/src/memu/llm), [`src/memu/embedding/`](https://github.com/NevaMind-AI/memU/tree/main/src/memu/embedding)
- Most useful single file to read first: [`src/memu/database/models.py`](https://github.com/NevaMind-AI/memU/blob/main/src/memu/database/models.py) — Pydantic schemas map the entire data model.

## Open questions

- "OpenClaw alternative" is mentioned repeatedly in README — what specifically is OpenClaw? (Possibly a closed-source enterprise memory product the team is targeting.)
- The Rust `_core` extension surface — what hot paths actually live in Rust?
- LangGraph integration is the only one shipped — is MCP / claude-agent-sdk integration on the roadmap?
- Memory model (`MemoryItem` + `MemoryCategory`) — closer to a flat KV store with categorical labels than a typed taxonomy. Is there a richer schema in `lazyllm`?
- "24/7 always-on" framing — is there a daemon / scheduler shipped, or is it a pattern users implement?

---

*Surveyed via the `curating-agentic-kbs` skill. Re-survey scheduled after 30 days of last `pushed_at` change.*

*Audit 2026-05-02: clone-verified against [`pyproject.toml`](https://github.com/NevaMind-AI/memU/blob/main/pyproject.toml) (`memu-py` v1.5.1, Apache-2.0, requires-python `>=3.13`), [`Cargo.toml`](https://github.com/NevaMind-AI/memU/blob/main/Cargo.toml) (`pyo3 = { version = "0.27.1", features = ["extension-module", "abi3-py313"] }`), [`src/memu/database/`](https://github.com/NevaMind-AI/memU/tree/main/src/memu/database) (3 backends: `inmemory` / `sqlite` / `postgres` + `factory.py` + `interfaces.py` + `state.py` + `models.py` + `repositories/`), [`LICENSE.txt`](https://github.com/NevaMind-AI/memU/blob/main/LICENSE.txt) (Apache License). **All major cohort-first claims verified verbatim:** PyO3 0.27.1 with abi3-py313 stable ABI, `memu-py 1.5.1`, Python `>=3.13` requirement (cohort highest minimum), 3-backend factory, Apache-2.0 license. **No corrections needed** — survey quality matches cognee / microsoft-graphrag / deepwiki-open / MemOS / OpenHands / khoj / AstrBot / OpenViking tier.*

*Re-audit iter 78 (2026-05-03): re-verified version pin. Architectural state unchanged: `memu-py` v1.5.1 still current, Apache-2.0 unchanged, Python ≥3.13 + PyO3 0.27.1 abi3-py313 unchanged. ★13,503 → ★13,511 (+8 stars, ~0.06% growth — slowest velocity in the iter-78 re-audit set). `pushed_at` 2026-04-22 unchanged (10+ days since last push — moderate-low activity). No corrections needed.*
