# Survey: HKUDS/LightRAG

**Date:** 2026-05-01
**Stars:** 34,634 · **Last push:** 2026-05-01 · **Created:** 2024-10-02
**Category:** graphrag (RAG framework)
**Slug:** [HKUDS/LightRAG](https://github.com/HKUDS/LightRAG)

---

## TL;DR (3 lines)

- **What it is:** EMNLP 2025 paper implementation — a RAG framework that uses **graph-based knowledge representation + 6 query modes** for retrieval (local / global / hybrid / mix / naive / **bypass**). Pure-Python core with optional FastAPI server + React 19 WebUI.
- **How its KB works:** Documents → LLM-extracted entities + relations → 4 typed storages (KV / vector / graph / doc-status), each with pluggable backends. Default stack is **nano-vectordb (vector) + NetworkX (graph) + JSON files (KV/status)** — boots with zero infrastructure. Production swap-ins: PostgreSQL (with AGE), Neo4j, Memgraph, Milvus, Qdrant, Faiss, Redis, MongoDB, OpenSearch.
- **Verdict:** Pick when you want **a clean GraphRAG library** to embed (MIT licensed) with a clear "boots-on-laptop, scales to prod" story and 5 retrieval modes to tune. Skip if you need agent-memory primitives (mem0/graphiti/cognee), MCP integration (LightRAG has none), or a turnkey product UI (FastGPT/ragflow).

## KB Architecture

### Storage
LightRAG abstracts **4 typed storages** behind base classes (`base.py: BaseKVStorage`, `BaseVectorStorage`, `BaseGraphStorage`, `BaseDocStatusStorage`); each accepts pluggable backends.

| Storage type | Default | Pluggable backends |
|---|---|---|
| **Vector** | `nano-vectordb` (in-process) | Faiss, Milvus, Qdrant, OpenSearch (via `kg/{faiss,milvus,qdrant,opensearch}_impl.py`) |
| **Graph** | NetworkX (in-process) | Neo4j, Memgraph, PostgreSQL+AGE (via `kg/{networkx,neo4j,memgraph,postgres}_impl.py`) |
| **KV** (LLM cache, chunks, doc info) | JSON file | PostgreSQL, MongoDB, Redis (via `kg/{json_kv,postgres,mongo,redis}_impl.py`) |
| **Doc-status** | JSON file | PostgreSQL |

- **Workspace isolation:** subdirectories for file-based; prefixes for collections; fields for relational DBs
- **Cache:** built into KV storage — LLM response cache lives there

### Ingestion / Extraction
- **Source types accepted:** PDF (`pypdf`), DOCX (`python-docx`), PPTX (`python-pptx`), XLSX (`openpyxl`), text/markdown; optional **Docling** integration for advanced doc parsing
- **Chunking strategy:** in `operate.py` — token-aware with overlap; defaults around 1200/100 tokens
- **Entity / fact extraction:** **LLM-based** — `operate.py` has the entity-and-relation extraction prompts; uses `prompt.py` template
- **Schema:** entity nodes + relation edges in the graph store; vector embeddings of entity, relation, and chunk text in vector store
- **Document processing engine:** `docling` extra adds layout-aware PDF / OCR / table extraction

### Retrieval
- **6 query modes** — defined as `Literal["local", "global", "hybrid", "naive", "mix", "bypass"]` in [`lightrag/base.py:88`](https://github.com/HKUDS/LightRAG/blob/main/lightrag/base.py#L88) (default `mix`):
  - **`local`** — context-dependent, focused on specific entities (entity-centric retrieval)
  - **`global`** — community/summary-based broad knowledge
  - **`hybrid`** — combines `local` + `global`
  - **`naive`** — direct vector search without graph (RAG baseline)
  - **`mix`** — integrates KG + vector retrieval; recommended with reranker
  - **`bypass`** — direct LLM queries with empty data arrays (skip retrieval entirely)
- **Reranker:** custom REST-API client in `lightrag/rerank.py` — model-agnostic Cohere-compatible wire format; `chunk_documents_for_rerank` for token-budget aware chunking
- **Multi-mode retrieval is the core paper contribution** — most surveyed repos do "hybrid" as one thing; LightRAG names and ships five distinct modes
- **Top-k defaults:** mode-specific; configurable per-call

### Memory model
- LightRAG is a **RAG library**, not an agent-memory framework — doesn't have separate "agent memory" tier
- Per-document and per-chunk versioning via doc-status storage; LLM response cache reduces cost
- No bi-temporal model
- Self-update: re-running insert on the same source dedups entities + relations
- No decay / forgetting

### MCP / connectors
- **MCP server exposed:** **NO**
- **MCP client used:** **NO** — `grep -r modelcontextprotocol lightrag/` returns zero hits
- **API:** FastAPI server in `lightrag/api/lightrag_server.py` with REST endpoints + **Ollama-compatible API** (so any Ollama-aware client just works) + JWT auth (`bcrypt`, `PyJWT`)
- **WebUI:** `lightrag_webui/` (React 19 + TypeScript)

### Notable design choices
- **6 named query modes** is the LightRAG signature — most cohort entries treat retrieval as "hybrid" and tune; LightRAG names the recipes (incl. `bypass` for direct LLM queries that skip retrieval)
- **4-storage abstraction** is the cleanest seen so far — orthogonal to provider choice; you swap a single backend without touching the others
- **Default stack = zero infrastructure** — nano-vectordb + NetworkX + JSON files, all in-process
- **MIT license** — most permissive in cohort
- **No MCP integration** — same as aider; LightRAG positions as a *library*, not a tool to be called from coding agents
- **Ollama-compatible API** — clever choice; clients that talk to Ollama see LightRAG as a drop-in upgrade
- **Workspace isolation per storage type** — a single LightRAG instance can host multiple isolated workspaces
- **`pipmaster` for runtime dep management** — installs missing optional deps on-demand at first use

## Dependencies (KB-relevant)

From `pyproject.toml` (core):

```
nano-vectordb       networkx        # default vector + graph (in-process)
tiktoken            json_repair     # tokenization + JSON repair for LLM output
pydantic            pandas          # schemas + data
google-genai        # default Gemini binding (in core, not extra — interesting)
tenacity            # retry on LLM/storage errors
pypinyin            # CJK normalization

# api extra:
fastapi  uvicorn  gunicorn  python-jose  PyJWT  bcrypt
pypdf    python-docx    python-pptx    openpyxl   pycryptodome

# storage extras:
neo4j  pymongo  redis  qdrant-client  pymilvus  faiss-cpu

# docling (optional, advanced doc processing):
docling   # has macOS multi-worker compatibility caveat per CLAUDE.md
```

## Tradeoffs

**Pros:**
- 5 named retrieval modes give immediate tuning vocabulary (`mode="hybrid"` vs `"local"` etc.)
- Default stack runs entirely in-process — fastest possible "hello world" for GraphRAG
- 4-way storage abstraction is genuinely elegant; production swap-out is one config change
- MIT license is enterprise-friendly
- Ollama-compatible API broadens client compatibility for free
- React 19 WebUI ships with the API extra

**Cons:**
- **No MCP integration** — won't slot into Claude Code / Cursor / Codex without a wrapper
- **No agent-memory primitives** — pair with mem0/graphiti/cognee if you need that
- LLM-based extraction cost on every insert; cached but still O(documents) on first ingest
- The 5-mode taxonomy is *opinionated* — if your task doesn't fit one of them, you write the code yourself
- Optional `pipmaster` runtime install is convenient but bypasses your environment manifest

## When to use it

- **Good fit:** teams building a GraphRAG product with a clear "swap nano-vectordb→Milvus, NetworkX→Neo4j" upgrade path; researchers wanting a clean reference for the LightRAG paper; pair with a memory framework for a fuller stack
- **Bad fit:** workflows needing MCP (use FastGPT, ragflow, or a wrapper); chat memory (use mem0); coding-agent context (use Cline/aider/claude-mem)
- **Closest alternatives (in this cohort):**
  - **microsoft/graphrag** (next survey candidate) — the original paper LightRAG simplifies
  - **circlemind-ai/fast-graphrag** — same family, different speed/cost tradeoff
  - **ragflow** — kb-app version with full UI + connectors

## Code pointers (evidence)

- Main orchestrator: `lightrag/lightrag.py` — `LightRAG` class; **call `await rag.initialize_storages()` after instantiation** (per CLAUDE.md)
- Core operations: `lightrag/operate.py` — entity/relation extraction, chunking, multi-mode retrieval logic
- Base abstractions: `lightrag/base.py` — `Base{KV,Vector,Graph,DocStatus}Storage`
- 13 storage backend impls: [`lightrag/kg/`](https://github.com/HKUDS/LightRAG/tree/main/lightrag/kg) — `nano_vector_db_impl`, `faiss_impl`, `milvus_impl`, `qdrant_impl`, `opensearch_impl` (vector); `networkx_impl`, `neo4j_impl`, `memgraph_impl`, `postgres_impl` (graph); `json_kv_impl`, `mongo_impl`, `redis_impl` (KV); `json_doc_status_impl` (doc-status)
- 14 LLM bindings: [`lightrag/llm/`](https://github.com/HKUDS/LightRAG/tree/main/lightrag/llm) — anthropic, azure_openai, bedrock, gemini, hf, jina, llama_index_impl, lmdeploy, lollms, nvidia_openai, ollama, openai, voyageai, zhipu
- Reranker: `lightrag/rerank.py`
- Prompts: `lightrag/prompt.py`
- API: `lightrag/api/lightrag_server.py` (FastAPI + Ollama-compatible + JWT)
- WebUI: `lightrag_webui/` (React 19)
- Most useful single file to read first: `CLAUDE.md` (top level) — concise architecture overview

## Open questions

- The PostgreSQL graph backend uses Apache AGE under the hood (cohort overlap with cognee). Does it benchmark comparably to Neo4j on the LightRAG test suite?
- `docling` is the recommended advanced parser but has a macOS multi-worker caveat (per CLAUDE.md). What's the workaround for hosted production?
- The `mix` mode requires a reranker — is there documented evidence on which reranker (BGE? Cohere? Voyage?) gives the best results on the paper benchmarks?

---

*Surveyed via the `curating-agentic-kbs` skill. Re-survey scheduled after 30 days of last `pushed_at` change.*

*Audit 2026-05-02: clone-verified against [`lightrag/base.py`](https://github.com/HKUDS/LightRAG/blob/main/lightrag/base.py), [`lightrag/operate.py`](https://github.com/HKUDS/LightRAG/blob/main/lightrag/operate.py), [`lightrag/lightrag.py`](https://github.com/HKUDS/LightRAG/blob/main/lightrag/lightrag.py), [`lightrag/kg/`](https://github.com/HKUDS/LightRAG/tree/main/lightrag/kg), [`lightrag/llm/`](https://github.com/HKUDS/LightRAG/tree/main/lightrag/llm). **Corrections:** query mode count **5 → 6** (added **`bypass`** — direct LLM queries with empty data arrays, skip retrieval); storage backend impl count **12 → 13** (had been counting only 12 of 13 `*_impl.py` files); LLM binding count **13 → 14**. **Verified:** 4 typed storage abstractions (`BaseKVStorage`, `BaseVectorStorage`, `BaseGraphStorage`, `DocStatusStorage`/extends KV), MIT license, no MCP at all (grep across `lightrag/` returns 0 hits for `modelcontextprotocol|FastMCP`), default mode `mix`. **Bonus discovery:** `bypass` mode is cohort-first as a *named* "skip retrieval" primitive — useful when the agent decides RAG isn't needed for a given query.*

*Re-audit iter 72 (2026-05-03): re-verified version pin + key paths. Architectural state unchanged: `lightrag-hku` v1.4.16 still current per `lightrag/_version.py`, 13 storage backend impls still match (`ls lightrag/kg/ | grep "_impl.py" | wc -l` = 13: faiss / json_doc_status / json_kv / memgraph / milvus / mongo / nano_vector_db / neo4j / networkx / opensearch / postgres / qdrant / redis). MIT unchanged. ★34,634 → ★34,662 (+28 stars, ~0.08% growth in 2 days — modest velocity). `pushed_at` 2026-05-01 unchanged. No corrections needed — survey is current. **Cohort cross-link still holds**: same HKUDS lab as [`DeepTutor`](HKUDS__DeepTutor.md) (iter 68 promotion). [`xerrors/Yuxi (语析)`](xerrors__Yuxi.md) (now-surveyed iter 73) **explicitly consumes LightRAG as headline architecture pillar** per its pyproject description, and ships an upstream-fix for [LightRAG #580](https://github.com/HKUDS/LightRAG/issues/580) in its `knowledge/implementations/lightrag.py` adapter — cohort first downstream-fix-loop where a cohort consumer carries a fix for an upstream cohort entry.*
