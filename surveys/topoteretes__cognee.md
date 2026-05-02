# Survey: topoteretes/cognee

**Date:** 2026-05-01
**Stars:** 16,951 · **Last push:** 2026-05-01 · **Created:** 2023-08-16 · **Version:** `1.0.3`
**Category:** memory-framework
**Slug:** [topoteretes/cognee](https://github.com/topoteretes/cognee)

---

## TL;DR (3 lines)

- **What it is:** Open-source memory platform that explicitly **replaces RAG with an "ECL" (Extract, Cognify, Load) pipeline** — combines vector search, graph databases, and LLM-powered ontology-driven entity extraction into one library you can embed.
- **How its KB works:** Sources (docs, web scrapes, agent traces, sessions) → loaders → ECL tasks (chunk, extract, summarize, ontology-link with **rdflib/OWL**) → stored across **vector** (LanceDB default · Chroma · pgvector) + **graph** (Kuzu · Neo4j · Neptune · Postgres+AGE) + **hybrid** (Neptune Analytics, Postgres) backends; "memify" pipelines consolidate descriptions, weight feedback, and persist agent trace feedback as graph nodes.
- **Verdict:** Pick when you want **a memory library that thinks in ontologies + RDF/OWL**, has **named pipelines** for memory operations (consolidate / weigh feedback / persist sessions), and is OK with a heavier dependency tree (30+ extras). Skip if you want a small SDK like mem0 or just a graph backend like graphiti.

## KB Architecture

### Storage
- **Vector store:** **3 backends** under `cognee/infrastructure/databases/vector/`: **LanceDB** (default, in core deps), **ChromaDB**, **pgvector**
- **Graph store:** **4 backends** under `cognee/infrastructure/databases/graph/`: **Kuzu** (default, in core deps), **Neo4j**, **AWS Neptune**, **Postgres** (likely Apache AGE)
- **Hybrid store:** **2 backends** under `cognee/infrastructure/databases/hybrid/`: **Neptune Analytics**, **Postgres** — single backend serving both vector + graph for ops simplicity
- **Metadata / structured:** **SQLAlchemy** + **Alembic migrations** (relational/sqlalchemy/, alembic/)
- **Cache:** **Redis** (extra) with **fakeredis** fallback; **diskcache** for local
- **Object / blob:** S3 via aws extra; local file-system loaders

### Ingestion / Extraction
- **Source types accepted:** files (pypdf, docling extra), web scrapes (tavily / BeautifulSoup / Playwright via `scraping` extra), agent traces, sessions, codebases (codegraph extra), notebooks (nbformat)
- **Chunking strategy:** task-based (`cognee/tasks/chunks/`) + dataset queue + alembic-tracked
- **Entity / fact extraction:** **LLM-based with structured output** — `instructor>=1.9.1` in core; **BAML** extra for advanced structured generation; LiteLLM>=1.83 wraps the LLM call
- **Schema:** **ontology-aware** — `rdflib>=7.1.4` in core deps for RDF/OWL; entities + relations live in named ontologies, not just raw triples
- **Notable input pipelines:** `tasks/temporal_awareness/`, `tasks/temporal_graph/`, `tasks/codingagents/`, `tasks/translation/`, `tasks/web_scraper/`

### Retrieval
- **Modes:** **vector + graph hybrid** — graph traversal combined with vector similarity; `tasks/completion/` and `tasks/entity_completion/` for query-time augmentation
- **Reranker:** not a first-class category in this codebase — relies on graph-distance + vector score; rerank if needed comes through `langchain` extra
- **Top-k defaults:** configurable per task
- **Schema-aware retrieval:** `tasks/schema/` — query the KG with awareness of the ontology

### Memory model
- **Tiers:** raw episodic (sessions, agent traces) + extracted semantic (entities + relations in graph) + ontology layer (RDF/OWL) + feedback-weighted memories
- **Memify pipelines (named memory operations):**
  - `consolidate_entity_descriptions.py` — dedup + summarize duplicate entity records
  - `apply_feedback_weights.py` — adjust memory salience based on agent feedback
  - `persist_agent_trace_feedbacks_in_knowledge_graph.py` — feedback signals become graph nodes
  - `persist_sessions_in_knowledge_graph.py` — chat sessions become first-class graph subgraphs
  - `create_triplet_embeddings.py` — embed triples (S, P, O) jointly
- **Bi-temporal:** **partial** — `tasks/temporal_awareness/` and `tasks/temporal_graph/` add time-aware reasoning, but not a full `valid_at` / `invalid_at` schema like graphiti
- **Self-update mechanism:** ECL pipeline runs idempotently per source; memify pipelines run on schedule for consolidation
- **Decay / forgetting:** feedback weights modulate salience; no time-based TTL

### MCP / connectors
- **MCP server exposed:** **yes** — dedicated `cognee-mcp/` project (Dockerized, with own `pyproject.toml`)
- **MCP client used:** indirect via langchain / llama-index integrations
- **Native connectors:** Tavily, Playwright (web scrape); LangChain + LlamaIndex extras; PostHog telemetry; Sentry + Langfuse via `monitoring` extra
- **Tool-call surface:** Python pipeline tasks; can be exposed via FastAPI server
- **Skill bundle:** ships a `cognee/skill.md` — Claude Skills-compatible

### Notable design choices
- **ECL > RAG branding** — explicit anti-RAG framing (Extract, Cognify, Load); RAG is treated as the obsolete predecessor
- **rdflib + OWL ontologies** — only surveyed repo with first-class semantic-web stack; entities can carry typed predicates and inheritance
- **graphiti as a backend extra** — `graphiti` extra means cognee can use graphiti's bi-temporal KG as one of its graph backends (cross-pollination!)
- **33 optional extras** in [`pyproject.toml`](https://github.com/topoteretes/cognee/blob/main/pyproject.toml) — most pluggable surface in this cohort (api, distributed, scraping, fastembed, neptune, postgres, postgres-binary, notebook, langchain, llama-index, huggingface, ollama, mistral, anthropic, azure, deepeval, posthog, groq, llama-cpp, chromadb, docs, codegraph, evals, **graphiti**, aws, dlt, baml, dev, debug, redis, tracing, monitoring, docling)
- **Hybrid stores get their own slot** — Neptune Analytics + Postgres treated as a separate category from "vector" or "graph", reducing ops surface
- **memify_pipelines as named operations** — `consolidate_entity_descriptions`, `apply_feedback_weights`, `persist_sessions_in_knowledge_graph` — memory operations are *first-class*, not buried in `add()` like mem0
- **Frontend included** — `cognee-frontend/` (Next.js); end-user-facing UI shipped with the library
- **Distributed extra (Modal)** — opt-in to Modal serverless for big-corpus ECL runs

## Dependencies (KB-relevant)

From `pyproject.toml` core:

```
openai>=1.80.1            litellm>=1.83.7
pydantic>=2.10.5          instructor>=1.9.1   # structured output
sqlalchemy>=2.0.39        alembic>=1.13.3     # metadata + migrations
lancedb>=0.24.0           # default vector
pylance>=0.22.0
kuzu==0.11.3              # default graph
networkx>=3.4.2
rdflib>=7.1.4             # ontology / RDF
fastapi>=0.116            uvicorn>=0.34
fakeredis>=2.32           diskcache>=5.6      # cache fallback
pypdf>=6.6                tiktoken>=0.8

extras (selected):
  postgres / postgres-binary  -> psycopg2 + pgvector + asyncpg
  neo4j        -> neo4j>=5.28
  neptune      -> langchain_aws
  chromadb     -> chromadb
  scraping     -> tavily-python + beautifulsoup4 + playwright + lxml
  baml         -> baml structured-output
  graphiti     -> graphiti-core
  langchain / llama-index / docling / codegraph / dlt
  redis · monitoring (sentry + langfuse) · evals (deepeval)
```

## Tradeoffs

**Pros:**
- Only repo in this cohort with **first-class ontologies via RDF/OWL** — typed memory at the schema layer, not just at extract time
- **Memify pipelines are explicit** — `consolidate_entity_descriptions`, `apply_feedback_weights`, etc. — operations you can name and schedule, vs. mem0's implicit `add()` magic
- 4 graph + 3 vector + 2 hybrid backends — broadest storage matrix
- Can plug in **graphiti** as a backend — interop with the bi-temporal cohort entry
- Distributed-first option (Modal) for big-corpus ingest

**Cons:**
- Heavy dependency surface — 30+ extras can pull conflicting versions (rdflib pinned `<7.2.0`, kuzu pinned `==0.11.3`)
- ECL framing is opinionated — if you want a thin wrapper over a vector store, mem0 is closer
- BM25 retrieval not native — relies on graph distance + vector score; weaker for keyword-heavy queries unless you wire OpenSearch yourself
- No bi-temporal `valid_at` / `invalid_at` like graphiti — temporal_awareness tasks help but aren't the same primitive
- Less polished docs site than mem0/graphiti — main entry is the README + Mintlify-style docs

## When to use it

- **Good fit:** ontology-heavy domains (legal, healthcare, scientific corpora); teams willing to invest in schema design upfront; need explicit named memory operations (consolidation, feedback)
- **Bad fit:** "give me memory in 5 lines" use cases (mem0 is faster); pure-graph audit trails (graphiti is the right tool); minimal-dep deployments
- **Closest alternative (in this cohort):** graphiti for bi-temporal audit (smaller, sharper); mem0 for thin SDK feel. Cognee is the *most opinionated and most extensible* of the three. **Consumed by [`run-llama/llama_index`](surveys/run-llama__llama_index.md)** as `llama-index-graph-rag-cognee` (the *only* graph-RAG adapter in llama_index's 571-package monorepo) — pinned `cognee[neo4j, postgres, qdrant]`, signaling cognee as the canonical graph-RAG backend in the LlamaIndex ecosystem.

## Code pointers (evidence)

- ECL pipeline orchestrator: `cognee/pipelines/`
- Memify named operations: [`cognee/memify_pipelines/`](https://github.com/topoteretes/cognee/tree/main/cognee/memify_pipelines) — 5 named pipelines (`consolidate_entity_descriptions`, `apply_feedback_weights`, `persist_agent_trace_feedbacks_in_knowledge_graph`, `persist_sessions_in_knowledge_graph`, `create_triplet_embeddings`) + orchestrator `memify_default_tasks.py`
- Storage adapters: `cognee/infrastructure/databases/{vector,graph,hybrid,relational}/`
- Tasks: `cognee/tasks/{chunks,documents,summarization,temporal_awareness,temporal_graph,codingagents,entity_completion,schema,translation,web_scraper}/`
- LLM stack: `cognee/infrastructure/llm/{structured_output_framework,prompts,extraction,tokenizer}/`
- MCP server: `cognee-mcp/`
- Skill bundle: `cognee/skill.md`
- Most useful single file to read first: `cognee/CLAUDE.md` and `cognee/memify_pipelines/persist_sessions_in_knowledge_graph.py`

## Open questions

- The `graphiti` extra suggests cognee can use graphiti as a graph backend — does that compose cleanly, or does cognee bypass graphiti's bi-temporal model?
- `tasks/temporal_awareness/` vs `tasks/temporal_graph/` — what's the distinction?
- Memify is mentioned in skill.md and pipelines, but the consolidation cadence (when does `consolidate_entity_descriptions` run?) isn't documented in the skim — likely orchestrated via the API but worth a closer look.

---

*Surveyed via the `curating-agentic-kbs` skill. Re-survey scheduled after 30 days of last `pushed_at` change.*

*Audit 2026-05-02: clone-verified against [`pyproject.toml`](https://github.com/topoteretes/cognee/blob/main/pyproject.toml) (v1.0.3), [`cognee/infrastructure/databases/{vector,graph,hybrid}/`](https://github.com/topoteretes/cognee/tree/main/cognee/infrastructure/databases), [`cognee/memify_pipelines/`](https://github.com/topoteretes/cognee/tree/main/cognee/memify_pipelines), [`cognee-mcp/`](https://github.com/topoteretes/cognee/tree/main/cognee-mcp). **All major cohort-first claims verified verbatim:** 3 vector / 4 graph / 2 hybrid backend dirs (counts exact); core deps (rdflib `>=7.1.4`, kuzu `==0.11.3`, lancedb `>=0.24.0`, instructor `>=1.9.1`, litellm `>=1.83.7`); all 5 memify pipelines + orchestrator; graphiti extra (`graphiti-core>=0.28.0`); MCP server in dedicated `cognee-mcp/` Dockerized project; `cognee/skill.md` Claude-Skills bundle. **Minor enhancements:** added version `1.0.3`, exact extras count `33` (was "30+"), bonus `memify_default_tasks.py` orchestrator.*

*Re-audit iter 64 (2026-05-02): re-verified version pin. Architectural state unchanged: v1.0.3 still current per `pyproject.toml`. ★16,951 → ★16,972 (+21 stars, ~0.12% growth in 2 days — moderate trending velocity for the memory-framework category). `pushed_at` 2026-05-01 → 2026-05-02 (+1 day, very active). No corrections needed — survey is current. Note: graphiti dep pin still `>=0.28.0`; current graphiti is v0.29.0, so cognee's pin remains forward-compatible without forcing an upgrade.*
