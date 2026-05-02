# Survey: infiniflow/ragflow

**Date:** 2026-05-01
**Stars:** 79,329 · **Last push:** 2026-04-30 · **Created:** 2023-12-12 · **Version:** `0.25.1`
**Category:** kb-app
**Slug:** [infiniflow/ragflow](https://github.com/infiniflow/ragflow)

---

## TL;DR (3 lines)

- **What it is:** Production RAG engine — Flask + React monolith with deep document understanding (PDF/OCR/layout) and a visual agent canvas on top.
- **How its KB works:** Documents → specialized chunkers per type (paper/book/manual/qa/...) → MySQL metadata + MinIO blobs + a **swappable doc engine** (Elasticsearch default · Infinity · OpenSearch) for hybrid BM25+dense; GraphRAG layer derives a NetworkX KG with Leiden communities on top of those chunks. A separate per-tenant agent **memory** layer with `forgetting_policy` and `memory_size` is distinct from the document KB.
- **Verdict:** Pick when document quality matters more than ops simplicity — heavy stack (5+ services), but the per-format chunkers and the swappable retrieval engine are hard to match elsewhere. Skip if you want a single Postgres or local-first KB.

## KB Architecture

### Storage
- **Vector store:** **Elasticsearch (default)** OR **Infinity** (`DOC_ENGINE=infinity`) OR **OpenSearch** — swappable via env var; `rag/utils/{es_conn,infinity_conn,opensearch_conn}.py`
- **Graph store:** **NetworkX in-memory**, derived from chunks; not persisted in a dedicated graph DB
- **Metadata / structured:** **MySQL** via Peewee ORM (`api/db/db_models.py`)
- **Object / blob:** **MinIO** primary, plus S3, Azure (SAS + SPN — 2 auth variants), GCS, OSS, OpenDAL, **OceanBase (`ob_conn`)** — via `rag/utils/storage_factory.py` (8 storage connectors total in `rag/utils/*_conn.py`, excluding `es_conn` / `infinity_conn` / `opensearch_conn` doc engines, `redis_conn` cache, and `tavily_conn` search)
- **Cache:** **Redis / Valkey** (`rag/utils/redis_conn.py`)

### Ingestion / Extraction
- **Source types accepted:** PDF, DOCX, PPTX, XLSX, HTML, email (.msg/.eml), images (OCR), audio (Whisper), book, paper, manual, qa, resume, laws, table — separate parser per type in `rag/app/`
- **Chunking strategy:** **14 specialized chunkers per document type** in [`rag/app/`](https://github.com/infiniflow/ragflow/tree/main/rag/app): `audio`, `book`, `email`, `laws`, `manual`, `naive` (fallback), `one`, `paper` (academic structure-aware), `picture`, `presentation`, `qa`, `resume`, `table`, `tag`. Far beyond fixed-size.
- **Entity / fact extraction:** **LLM-based**; two flavors: `rag/graphrag/general/extractor.py` (MS GraphRAG style with multi-gleaning) and `rag/graphrag/light/` (LightRAG style)
- **Schema:** chunks tagged with positional + structural metadata; KG schema is `entity_types = [organization, person, geo, event, category]` plus relation triples
- **OCR / layout:** `deepdoc/` — own deep-learning layout analysis, runs ONNX (CPU + GPU)

### Retrieval
- **Modes:** **hybrid** — BM25 (from doc engine) + dense vector + structural filters; GraphRAG path adds community-summary retrieval
- **Reranker:** **20 backend classes** in [`rag/llm/rerank_model.py`](https://github.com/infiniflow/ragflow/blob/main/rag/llm/rerank_model.py): `Jina`, `XInference`, `LocalAI`, `Nvidia`, `LmStudio`, `OpenAI_API`, `CoHere`, `TogetherAI`, `SILICONFLOW`, `BaiduYiyan`, `Voyage`, `QWen`, `Huggingface`, `GPUStack`, `Novita` (extends Jina), `Gitee` (extends Jina), `Ai302`, `JiekouAI` (extends Jina), `FuturMix` (extends OpenAI_API), `RAGcon`. Largest reranker surface in cohort.
- **Top-k defaults:** configurable per knowledge-base; runtime default not hard-coded
- **Context assembly:** RAPTOR (`rag/raptor.py`) for hierarchical summarization; chunk metadata-aware citations

### Memory model
- **Tiers:** **document KB** (long-term, document-derived) and **agent memory** (`memory/` + `api/db/services/memory_service.py`) — two distinct stores
- **Per-tenant memory fields:** `memory_size`, `forgetting_policy`, `memory_type`, `storage_type`, `embd_id`, `system_prompt`, `user_prompt`
- **Bi-temporal:** no
- **Self-update mechanism:** agent memory auto-extracts from conversations via `memory/services/messages.py` + `query.py`
- **Decay / forgetting:** explicit `forgetting_policy` field per memory namespace

### MCP / connectors
- **MCP server exposed:** **yes** — `mcp/server/` exposes ragflow KBs as MCP server; `api/db/services/mcp_server_service.py` for management
- **MCP client used:** **yes** — `mcp/client/` for outbound tool use from agents
- **Native connectors:** Slack, Discord, GitHub, GitLab, Jira, Asana, Airtable, Wikipedia, ArXiv, Tavily, DuckDuckGo, Crawl4AI, Google Drive, Atlassian, Dropbox, Box, Notion (via Office365 client), DingTalk, Feishu (Volcengine), WeChat (chatgpt-on-wechat plugin), Moodle — broadest set among surveyed kb-apps
- **Tool-call surface:** dozens — `agent/tools/`

### Notable design choices
- **Swappable doc engine** (Elasticsearch / Infinity / OpenSearch) chosen at deploy time via `DOC_ENGINE` env var — the only repo so far that treats the vector backend as an interchangeable plug-in
- **Per-format specialized chunkers** — `rag/app/{paper,book,manual,qa,resume,laws,table,...}.py` — chunks aware of academic-paper sections, Q&A pairs, table structure, etc.
- **GraphRAG layer is computed, not persisted** — graphs live in NetworkX, summaries cached as chunks in the doc engine; no Neo4j/AGE in the stack
- **Memory layer is separate from KB layer** — most other surveyed memory frameworks blur the two; ragflow keeps tenant agent memory and the document KB as different services

## Dependencies (KB-relevant)

From `pyproject.toml`:

```
elasticsearch-dsl==8.12.0
infinity-sdk==0.7.0-dev5
infinity-emb>=0.0.66,<0.0.67
opensearch-py==2.7.1
mysql-connector-python>=9.0.0,<10.0.0
peewee>=3.17.1,<4.0.0
minio==7.2.4
valkey==6.0.2
mcp>=1.19.0
graspologic @ git+...   # Leiden community detection
cohere==5.6.2  voyageai==0.2.3   # rerank/embed APIs
ollama>=0.5.0  litellm~=1.82
crawl4ai  tavily-python  duckduckgo-search  wikipedia
```

## Tradeoffs

**Pros:**
- Strongest document understanding among trending RAG OSS — per-format chunkers + own OCR
- Swappable doc engine means same code runs on ES, Infinity, or OpenSearch
- MCP server + client both first-class — KBs can be both consumed *and* exposed as tools
- 20 reranker backend classes (largest in cohort) cover virtually any deployment

**Cons:**
- Heaviest stack in this cohort: MySQL + ES/Infinity + Redis + MinIO + Flask + React, all containerized
- 16GB RAM / 50GB disk minimum (per CLAUDE.md) — non-trivial for self-host
- Graph layer is in-memory NetworkX — won't survive process restart, won't scale past one box
- Python 3.12 only; tight version pins everywhere (e.g. `cohere==5.6.2`, `voyageai==0.2.3`) make integration into another project painful

## When to use it

- **Good fit:** team wants a **drop-in self-hosted RAG product** with strong document handling; lots of source format variety (PDF/email/docx/audio); want MCP exposure for free
- **Bad fit:** local-first / single-box deploys; teams that want to compose libraries rather than run a product; latency-critical paths (doc-engine round-trips dominate)
- **Closest alternative:** `labring/FastGPT` (also kb-app, not yet surveyed) — typically reported as more workflow-focused and lighter; ragflow leans deeper on document parsing

## Code pointers (evidence)

- Storage abstraction: `rag/utils/storage_factory.py`, `rag/utils/{es_conn,infinity_conn,opensearch_conn}.py`
- 14 chunkers: [`rag/app/`](https://github.com/infiniflow/ragflow/tree/main/rag/app) — `naive.py`, `paper.py`, `book.py`, `manual.py`, `qa.py`, `resume.py`, `laws.py`, `table.py`, `presentation.py`, `picture.py`, `email.py`, `audio.py`, `one.py`, `tag.py`
- GraphRAG extractor: `rag/graphrag/general/extractor.py`, `rag/graphrag/light/graph_extractor.py`
- Reranker zoo: `rag/llm/rerank_model.py`
- Agent memory: `memory/services/{messages,query}.py`, `api/db/services/memory_service.py`
- MCP: `mcp/server/`, `mcp/client/`, `api/db/services/mcp_server_service.py`
- Most useful single file to read first: `CLAUDE.md` (top level) — concise architecture overview by the maintainers

## Open questions

- How does the GraphRAG layer perform with concurrent writers if the graph lives in NetworkX in-memory? Sharding strategy unclear from a 30-min skim.
- The `memory_size` and `forgetting_policy` fields suggest something more than naive append — would need to read `memory/services/query.py` end-to-end to understand the decay model.
- Infinity vs Elasticsearch performance trade — claimed but not benchmarked in-tree.

---

*Surveyed via the `curating-agentic-kbs` skill. Re-survey scheduled after 30 days of last `pushed_at` change.*

*Audit 2026-05-02: clone-verified against [`pyproject.toml`](https://github.com/infiniflow/ragflow/blob/main/pyproject.toml) (v0.25.1), [`rag/app/`](https://github.com/infiniflow/ragflow/tree/main/rag/app) (14 chunkers), [`rag/llm/rerank_model.py`](https://github.com/infiniflow/ragflow/blob/main/rag/llm/rerank_model.py) (20 reranker classes via `^class.*Rerank` grep), [`rag/utils/`](https://github.com/infiniflow/ragflow/tree/main/rag/utils) (`*_conn.py` files: 3 doc engines + 8 storage backends + 1 cache + 1 search), [`mcp/`](https://github.com/infiniflow/ragflow/tree/main/mcp) (server + client). **Corrections:** reranker count **"~14" → 20** (off-by-6; survey listed 12 examples but said ~14); chunker count **12 → 14** (added `one.py` and `tag.py`); storage backends — added missing **OceanBase (`ob_conn`)** + clarified Azure has 2 auth variants (SAS + SPN). **Verified verbatim:** swappable doc engine via `DOC_ENGINE` env (es / infinity / opensearch), MCP both server + client (`mcp/server/` + `mcp/client/`), per-format chunkers, `forgetting_policy` field per memory namespace. Added version `0.25.1` to header.*

*Re-audit iter 55 (2026-05-02): re-verified against `main@2026-05-01` (latest commit `24af087`, "Feat/configurable metadata display #13464"). Architectural state unchanged: v0.25.1 still current, chunker count still 14 (`rag/app/` minus `__init__.py`), reranker count still 20, 13 `*_conn.py` files unchanged. ★79,329 → ★79,379 (+50 stars, ~0.06% growth in 2 days). No corrections needed — survey is current.*
