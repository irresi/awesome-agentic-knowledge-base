# Survey: mem0ai/mem0

**Date:** 2026-05-01
**Stars:** 54,508 · **Last push:** 2026-04-30 · **Created:** 2023-06-20 · **Version:** `mem0ai 2.0.1` (OSS Python SDK; Platform docs reference v3 architecture)
**Category:** memory-framework
**Slug:** [mem0ai/mem0](https://github.com/mem0ai/mem0)

---

## TL;DR (3 lines)

- **What it is:** Polyglot SDK ("mem0ai" Python `2.0.1` + TypeScript) that turns conversation messages into a self-managing fact memory for AI agents — both hosted (`MemoryClient`) and self-hosted (`Memory`) modes.
- **How its KB works:** Each `add()` call routes messages through an LLM that **extracts atomic facts**, dedups against existing memories, then writes to a vector store (default: Qdrant; default OSS server: **Postgres+pgvector only** — Neo4j was removed in v3) — scoped by `user_id` / `agent_id` / `run_id`. **v3 default retrieval is multi-signal hybrid** (semantic + BM25 + entity matching) with optional Cohere/HuggingFace/LLM/Sentence-Transformer/Zero-Entropy reranker. MCP server everywhere (hosted, openmemory local, mem0-plugin for Claude/Cursor/Codex).
- **Verdict:** Pick when you want **one-week ship time** for agent memory and the conversation-as-input shape fits. Skip when you have documents (it ingests messages, not files), want bi-temporal audit, or want to avoid the LLM-extraction cost on every turn.

## KB Architecture

### Storage
- **Vector store:** **24 backends** via provider pattern ([`mem0/vector_stores/`](https://github.com/mem0ai/mem0/tree/main/mem0/vector_stores)); default is **Qdrant**, default OSS server runs **Postgres+pgvector**. Full list: azure_ai_search, azure_mysql, baidu, cassandra, chroma, databricks, elasticsearch, faiss, langchain, milvus, mongodb, neptune_analytics, opensearch, pgvector, pinecone, qdrant, redis, s3_vectors, supabase, turbopuffer, upstash_vector, valkey, vertex_ai_vector_search, weaviate.
- **Graph store:** **REMOVED in v3** — `graph_store` configuration is no longer supported. Per [`skills/mem0/references/features.md`](https://github.com/mem0ai/mem0/blob/main/skills/mem0/references/features.md): "v3 replaces graph memory with built-in entity linking. Entities (proper nouns, quoted text, compound noun phrases) are automatically extracted and linked across memories." Entity relationships are now consumed via retrieval ranking (entity-match boost), not exposed as a separate `relations` array. Previous v2 backends (Neo4j, Memgraph, Kuzu, Apache AGE) no longer ship in `mem0/graphs/`.
- **Metadata / structured:** SQLAlchemy by default; SQLite (`SQLiteManager`) for local mode without configuring a backend
- **Object / blob:** N/A — mem0 stores facts, not source documents
- **Cache:** redis / valkey listed as optional vector_stores

### Ingestion / Extraction
- **Source types accepted:** **conversation messages** (OpenAI-style chat lists). Not documents. This is the design point: `add(messages, user_id=..., agent_id=..., run_id=...)`
- **Chunking strategy:** **none** — operates at the fact level
- **Entity / fact extraction:** **LLM-based and automatic** — every `add()` runs `ADDITIVE_EXTRACTION_PROMPT` to produce atomic memories, then dedups/updates vs. existing scope. Entity extraction utility at `mem0/utils/entity_extraction.py`
- **Schema:** flat memory items with `id`, `memory` text, `metadata`, scope keys (`user_id`/`agent_id`/`run_id`)
- **Memory types:** factual, episodic, procedural (`PROCEDURAL_MEMORY_SYSTEM_PROMPT` distinct from default factual extraction)

### Retrieval
- **Modes:** **v3 default: multi-signal hybrid** — semantic (vector) + BM25 keyword (built-in lemmatization in `mem0/utils/lemmatization.py`) + entity matching (entity-graph boost). Scoring in `mem0/utils/scoring.py` with `ENTITY_BOOST_WEIGHT`. Optional `rerank=True` flag adds deep semantic reordering (+150-200ms latency, default `False` — was `True` in v2).
- **Reranker:** 5 backends — **Cohere**, **HuggingFace**, **LLM-as-reranker**, **Sentence Transformer**, **Zero Entropy**
- **Top-k defaults:** configurable per-call
- **Context assembly:** filtered by scope; `score_and_rank` combines BM25 + dense + entity boost

### Memory model
- **Tiers:** **single tier of facts** with **scope** (user / agent / run) — no archival/working/episodic separation by default
- **Bi-temporal:** **no** — `history(memory_id)` tracks change history but isn't full bi-temporal (no validity-time vs recorded-time distinction)
- **Self-update mechanism:** **yes — automatic** on each `add()`: LLM proposes new facts → dedup/update against existing scope → write
- **Decay / forgetting:** none built-in (no TTL, no score-based forgetting)

### MCP / connectors
- **MCP server exposed:** **yes — three flavors**: hosted at `mcp.mem0.ai`; local `openmemory/api/` (FastAPI); and `mem0-plugin/` MCP server for Claude Code / Cursor / Codex
- **MCP tools (9):** `add_memory`, `search_memories`, `get_memories`, `get_memory`, `update_memory`, `delete_memory`, `delete_all_memories`, `delete_entities`, `list_entities`
- **MCP client used:** indirectly via mem0-plugin lifecycle hooks
- **Native connectors:** N/A — connects via the agents using it (Vercel AI SDK provider, OpenClaw plugin, Claude Code skill, Cursor/Codex plugins) rather than fetching from external sources itself
- **Tool-call surface:** 9 MCP tools

### Notable design choices
- **Message-shaped input, not document-shaped** — fundamentally different from ragflow / FastGPT; ingests `messages=[...]`, not files
- **Provider pattern across 4 categories (v3)** — **24 vector stores, 18 LLMs, 11 embeddings, 5 rerankers**. Graph stores were removed in v3 (entity linking is now built-in across all backends). Still the most pluggable surface in this cohort.
- **v3 architectural shift** — `graph_store` removed from OSS configuration; entities (proper nouns, quoted text, compound noun phrases) are auto-extracted at ingest and used as a retrieval boost signal rather than as a separate graph traversal layer.
- **Two execution modes** — hosted (`MemoryClient`) and self-hosted (`Memory`); same Python *and* TypeScript SDK
- **Coding-agent integration is first-class** — `mem0-plugin/` ships pre-wired hooks for Claude Code, Cursor, Codex; `skills/` has Claude Code Agent Skills bundled
- **OpenMemory companion** — a separate Next.js 15 + FastAPI app under `openmemory/` for users who want a UI on top of the local memory
- **Two `__init__.py` exports tell the architecture story:** `Memory` (self-hosted) + `MemoryClient` (hosted) — never combine

## Dependencies (KB-relevant)

From `pyproject.toml` (core + optional groups):

```
qdrant-client>=1.12.0           # default vector store, in core deps
pgvector via psycopg            # default OSS server (Docker compose)
sqlalchemy>=2.0.31              # metadata layer
spacy                           # NLP (lemmatization for BM25)

vector_stores extra: chromadb, weaviate-client, pinecone, faiss-cpu,
  cassandra-driver, pymilvus, elasticsearch, opensearch-py, redis, redisvl,
  upstash-vector, azure-search-documents, pymongo, langchain-aws, ...
llms extra: groq, together, litellm, ollama, vertexai, google-generativeai
extras: langchain, sentence-transformers, fastembed
```

Default OSS server ([`server/docker-compose.yaml`](https://github.com/mem0ai/mem0/blob/main/server/docker-compose.yaml)): **FastAPI + `ankane/pgvector:v0.5.1`**. (Neo4j was removed in v3 alongside `graph_store`.) `openmemory/docker-compose.yml` adds Qdrant + `mem0/openmemory-mcp` + `mem0/openmemory-ui` for the local-UI variant.

## Tradeoffs

**Pros:**
- Fastest path to "agent has memory" — `pip install mem0ai` + 3 lines of code
- Both Python and TypeScript SDKs maintained in lockstep — rare in this space
- 24 vector stores + 18 LLMs + 11 embedders + 5 rerankers = will plug into any existing infra (graph stores removed in v3 — entity linking built-in instead)
- MCP integration in three places (hosted, openmemory, plugin) means coding agents pick it up natively
- Has a real evaluation harness (`evaluation/`) running LOCOMO benchmarks against LangMem / RAG / full-context baselines

**Cons:**
- Document workflows don't fit — you must convert PDFs/markdown to messages yourself
- LLM extraction cost on every `add()` — can dominate budget for chatty workloads
- No bi-temporal model — `history()` gives change log but no "what did we know on date X" query
- Single tier; if you need archival vs working separation, look at Letta instead
- 5 rerankers but no native BGE / Voyage / Jina (must wire via langchain extra)

## When to use it

- **Good fit:** chatbot / personal-assistant / customer-support agents where the input is conversation; teams that want one drop-in SDK across Python and TypeScript; anyone needing an MCP-shaped memory tool for Claude Code / Cursor / Codex
- **Bad fit:** document-heavy KBs (use ragflow/FastGPT); workloads that need bi-temporal audit (Graphiti); workloads that need explicit episodic vs semantic vs working tiers (Letta)
- **Closest alternative (in this cohort):** Letta (memory-OS, multi-tier) on the rich-memory end; Graphiti (bi-temporal KG memory) on the audit-heavy end. ragflow is *complementary* not alternative — different input shape. Also **consumed by [`run-llama/llama_index`](surveys/run-llama__llama_index.md)** as `llama-index-memory-mem0` — one of only 2 external memory adapters llama_index ships, signaling that mem0 is the canonical "thin SDK" memory pick when you're already in the LlamaIndex ecosystem.

## Code pointers (evidence)

- Core memory loop: `mem0/memory/main.py` — entry point for `add` / `search` / `get_all` / `update` / `delete`
- Provider factory: `mem0/utils/factory.py` — `EmbedderFactory`, `LlmFactory`, `RerankerFactory`, `VectorStoreFactory`
- Hybrid retrieval: `mem0/utils/scoring.py` (`get_bm25_params`, `normalize_bm25`, `score_and_rank`, `ENTITY_BOOST_WEIGHT`); `mem0/utils/lemmatization.py`
- Extraction prompts: `mem0/configs/prompts.py` — `ADDITIVE_EXTRACTION_PROMPT`, `PROCEDURAL_MEMORY_SYSTEM_PROMPT`
- Vector stores zoo: [`mem0/vector_stores/`](https://github.com/mem0ai/mem0/tree/main/mem0/vector_stores) — 24 backend files
- LLM clients: [`mem0/llms/`](https://github.com/mem0ai/mem0/tree/main/mem0/llms) — 18 provider files (anthropic, aws_bedrock, azure_openai (+_structured), deepseek, gemini, groq, langchain, litellm, lmstudio, minimax, ollama, openai (+_structured), sarvam, together, vllm, xai)
- v3 entity-linking spec: [`skills/mem0/references/features.md`](https://github.com/mem0ai/mem0/blob/main/skills/mem0/references/features.md) — "v3 replaces graph memory with built-in entity linking" + v2→v3 migration notes
- MCP plugin: `mem0-plugin/` — 9 tools for Claude Code / Cursor / Codex
- Most useful single file to read first: `CLAUDE.md` (top-level) — comprehensive architecture index by maintainers

## Open questions

- ~~The default OSS server uses **both** pgvector *and* Neo4j~~ **Answered (audit 2026-05-02):** Neo4j was removed in v3. Only `ankane/pgvector` ships in the default `server/docker-compose.yaml` now. The graph layer is gone, not opt-in.
- BM25 implementation looks custom (`scoring.py` + `lemmatization.py`) — why not delegate to vector-store-native BM25 like Elasticsearch?
- ~~`delete_entities` / `list_entities` MCP tools imply the graph layer is the source of truth for entities~~ **Answered (audit 2026-05-02):** these tools now operate on the **built-in entity-linking layer** — entities are auto-extracted from memories at ingest time (proper nouns, quoted text, compound noun phrases) and used as a retrieval-ranking boost signal rather than a separate graph store.

---

*Surveyed via the `curating-agentic-kbs` skill. Re-survey scheduled after 30 days of last `pushed_at` change.*

*Audit 2026-05-02: clone-verified against [`pyproject.toml`](https://github.com/mem0ai/mem0/blob/main/pyproject.toml) (v2.0.1), [`mem0/vector_stores/`](https://github.com/mem0ai/mem0/tree/main/mem0/vector_stores), [`mem0/llms/`](https://github.com/mem0ai/mem0/tree/main/mem0/llms), [`mem0/embeddings/`](https://github.com/mem0ai/mem0/tree/main/mem0/embeddings), [`mem0/reranker/`](https://github.com/mem0ai/mem0/tree/main/mem0/reranker), [`mem0/utils/factory.py`](https://github.com/mem0ai/mem0/blob/main/mem0/utils/factory.py), [`server/docker-compose.yaml`](https://github.com/mem0ai/mem0/blob/main/server/docker-compose.yaml), [`skills/mem0/references/features.md`](https://github.com/mem0ai/mem0/blob/main/skills/mem0/references/features.md). **Major correction — v3 architectural shift:** `graph_store` REMOVED in v3; replaced by built-in entity linking (auto-extracted entities used as retrieval boost). Counts updated: vector backends **30 → 24** (now exact list), LLM providers **24 → 18**, graph backends **4 → 0** (REMOVED). Default OSS Docker compose no longer ships Neo4j (only `ankane/pgvector`). Hybrid retrieval is now multi-signal (semantic + BM25 + entity matching) by default, with optional `rerank=True` flag. **Verified:** 5 rerankers (cohere / huggingface / llm / zero_entropy / sentence_transformer), 11 embedders, MCP server (3 flavors), Qdrant default. Two open questions answered.*
