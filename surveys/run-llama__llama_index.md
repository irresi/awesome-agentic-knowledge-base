# run-llama/llama_index

- **Stars:** 49,088 · **Last push:** 2026-05-01 · **License:** MIT · **Lang:** Python (≥3.10)
- **Category:** kb-framework (RAG/agent toolkit; foundational Python framework)

## TL;DR

LlamaIndex is a hub-and-spoke monorepo: a small `llama-index-core` (v0.14.21) + **571 separately versioned integration packages** under `llama-index-integrations/` (78 vector stores, 104 LLMs, 159 readers, 68 tools, 26 rerankers, 7 graph stores, …). The core ships the abstractions — `Memory` waterfall + `BaseMemoryBlock`, `IngestionPipeline`, `PropertyGraphIndex`, `Workflow`, `StorageContext` — and integrations are pulled in à-la-carte. MCP is **not in core**; it lives in `llama-index-tools-mcp` (v0.4.8) which both consumes external MCP servers (`BasicMCPClient`, `McpToolSpec`) and exposes any `Workflow` as an MCP server (`workflow_as_mcp`).

## KB Architecture

### Storage abstractions
- `StorageContext` composes four KV-shaped stores: `docstore`, `index_store`, `kvstore`, `chat_store`.
- Default backings: `SimpleDocumentStore` (in-memory dict, JSON-serializable), `SQLAlchemyChatStore` (table `llama_index_memory`).
- All four are interfaces — pluggable via the `storage/` integration packages (4 adapters: redis, postgres, mongodb, gel).

### Vector / graph layer
- **Vector stores**: 78 adapters in `llama-index-integrations/vector_stores/` (pgvector, Milvus, Qdrant, OpenSearch, Chroma, Faiss, Pinecone, Weaviate, LanceDB, Azure AI Search, Astra DB, Couchbase, ClickHouse, BigQuery, … — broadest cohort coverage).
- **Graph stores**: 7 (`ApertureDB`, `falkordb`, `memgraph`, `nebula`, `neo4j`, `neptune`, `tidb`). Note FalkorDB and Neo4j are also separate cohort members — llama_index is downstream consumer.
- **Graph-RAG adapter**: 1 (`llama-index-graph-rag-cognee` v0.3.1, dep `cognee[neo4j, postgres, qdrant]`). Direct cohort cross-link to topoteretes/cognee.
- **PropertyGraphIndex** (newer KG primitive): pluggable extractor pipeline (`SchemaLLMPathExtractor`, `DynamicLLMPathExtractor`, `SimpleLLMPathExtractor`, `ImplicitPathExtractor`) + four sub-retrievers (`VectorContextRetriever`, `CypherTemplateRetriever`, `TextToCypherRetriever`, `LLMSynonymRetriever`). The older `KnowledgeGraphIndex` (`KGTableRetriever`, `KnowledgeGraphRAGRetriever`) is still shipped for back-compat.

### Ingestion
- `IngestionPipeline` (in `core/ingestion/pipeline.py`): ordered `transformations`, optional `data_sources`/`data_sinks`, content-hash `IngestionCache` (sha256-keyed), `ProcessPoolExecutor`-based parallelism.
- 159 reader adapters in `llama-index-integrations/readers/` (the largest category) — ranges from filesystem/PDF/DOCX to GitHub, Confluence, Notion, Slack, Discord, Salesforce, Jira, S3, Snowflake, web crawlers.
- 6 node parsers + 3 extractors + 1 sparse-embedding adapter; 26 postprocessors (rerankers, redaction via Presidio, LongLLMLingua compression, ColBERT/Cohere/Jina/Voyage/NVIDIA/MixedBread/FlagEmbedding/Pinecone-native rerankers).

### Retrieval / query
- `BaseRetriever` → 14 standalone retriever adapters (BM25, Bedrock, Kendra, Pathway, Vertex AI Search, You.com, Vectorize, …) plus per-index retrievers.
- `query_engine/`, `response_synthesizers/`, `chat_engine/` compose retrievers + LLMs + postprocessors.
- `selectors/`, `question_gen/`, `program/`, `output_parsers/` provide structured-output and routing primitives.

### Memory model — "waterfall" with composable blocks
- `core/memory/memory.py` defines `Memory(BaseMemory)` and `BaseMemoryBlock[T]` (`T` = `str | List[ContentBlock] | List[ChatMessage]`).
- A `Memory` orchestrates a FIFO message queue (default `token_limit=30000`, `flush_size=10%`) plus an ordered list of memory blocks. When the queue exceeds `token_limit`, the oldest pressure-window of messages is **ejected and waterfalled into each block**.
- Built-in block types in `core/memory/memory_blocks/`:
  - `StaticMemoryBlock` — fixed text/content (system prompts, persona).
  - `VectorMemoryBlock` — embed-and-retrieve from a vector store.
  - `FactExtractionMemoryBlock` — LLM-extracts XML `<fact>` tags from ejected messages, with a separate `DEFAULT_FACT_CONDENSE_PROMPT` that compacts the running fact list when it grows past `max_facts`.
- Block-level `priority: int` (0 = never truncate) and `accept_short_term_memory: bool` knobs control which blocks consume the waterfall and which survive truncation pressure.
- External-system memory adapters in `llama-index-integrations/memory/`: only **2** — `llama-index-memory-mem0` (bridges to mem0; cohort cross-link) and `llama-index-memory-bedrock-agentcore`.

### Agent / orchestration
- `core/workflow/workflow.py` re-exports from the standalone `workflows` package (event-driven async DAG with `@step`, `Context`, `Event` types).
- `core/agent/`: `react/` agent + `workflow/` agent. `FunctionAgent` (the `agent.workflow` entry point shown in MCP docs) is a workflow-based tool-calling agent.
- `voice_agents/` — 3 adapters (real-time voice loop integrations).

### MCP (Model Context Protocol)
- **Not in core.** Lives in `llama-index-integrations/tools/llama-index-tools-mcp` (v0.4.8, dep `mcp>=1.24.0,<2`) and a separate `llama-index-tools-mcp-discovery`.
- Two directions:
  1. **Consume**: `BasicMCPClient("http://…/sse")` → `McpToolSpec(client=…, allowed_tools=[…], include_resources=True)` → `.to_tool_list()` returns `FunctionTool`s usable by any agent.
  2. **Expose**: `workflow_as_mcp(workflow)` adapts any `Workflow` into an MCP server endpoint.

## Notable design choices

- **Hub-and-spoke monorepo at extreme scale** — 571 separately versioned packages on PyPI, all under one git tree, each with its own `pyproject.toml`/version/README. Core is intentionally minimal (the README emphasises that the "starter" `llama-index` package is just core + a curated subset of integrations). Closest cohort analogue is haystack-style monorepos, but at far smaller integration count.
- **Memory is a queue + plug-in blocks, not a single store** — orthogonal to mem0's "facts auto-extracted from every message" model: in LlamaIndex, fact extraction is *one* memory-block strategy among Static/Vector and is gated by token-pressure ejection rather than per-message.
- **Two KG primitives ship side-by-side** — `KnowledgeGraphIndex` (legacy, triple-table style) and `PropertyGraphIndex` (current, with extractor + sub-retriever decomposition). The latter's `SchemaLLMPathExtractor`/`DynamicLLMPathExtractor` split mirrors the schema-locked vs. open-world extraction tradeoff that graphiti also surfaces, but as composable transformations rather than a temporal-bitemporal model.
- **Workflows ↔ MCP bidirectional bridge** — `workflow_as_mcp` plus `McpToolSpec` means a LlamaIndex agent can be both an MCP client and an MCP server with the same `Workflow` definition. Cohort-novel: most members are MCP clients only, or expose a single curated server (basic-memory, claude-mem).
- **Cognee + mem0 + FalkorDB as first-party adapters** — three other cohort members ship as named integration packages, making LlamaIndex a downstream aggregator of the broader KB ecosystem rather than a competitor to it.

## Dependencies

Core (`llama-index-core` 0.14.21) — hard deps only:
`SQLAlchemy[asyncio]`, `dataclasses-json`, `deprecated`, `fsspec`, `httpx`, `nest-asyncio`, `nltk`, `numpy`, `tenacity`, `tiktoken`, `typing-extensions`, `typing-inspect`, `requests`, `aiohttp`, `networkx`, `dirtyjson`, `tqdm`, `pillow`, `PyYAML`, `wrapt`, `pydantic≥2.8`, `filetype`. **No vendor SDKs** — every LLM/embedder/store is a separate optional integration package.

## Tradeoffs

- **For**: widest backend selection in the cohort (78 vector / 104 LLM / 159 reader / 68 tool / 26 reranker adapters); minimal core install; mature workflow runtime; MCP-bidirectional; production-grade `SQLAlchemyChatStore`; explicit `IngestionCache` with content hashing; Property/Knowledge graph indices ship side-by-side; first-party adapters for cognee/mem0/FalkorDB tighten cohort interop.
- **Against**: deep abstraction stack (Memory→BaseMemoryBlock→ContentBlock→ChatMessage); 571 packages means version-skew matrix risk (every integration pins `llama-index-core>=X,<Y` independently); `core` only contains in-memory `SimpleDocumentStore` by default — productionizing requires picking a `storage/` adapter explicitly; documentation lags code (README itself notes "this README is not updated as frequently").

## When to use vs. cohort

- vs. **mem0** — mem0 is one memory model (auto-extracted facts → vector store). LlamaIndex Memory is a framework where mem0-style fact extraction is *one* `MemoryBlock` among several, alongside vector recall and static blocks. Use mem0 when you want a turnkey memory service; LlamaIndex Memory when you need to compose extraction + retrieval + static priming with explicit truncation priorities.
- vs. **haystack** — both are hub-and-spoke RAG frameworks; haystack centers on Pipeline/Component DAG, LlamaIndex on Workflow + Index types. LlamaIndex has ~3× more integration packages.
- vs. **letta / OpenViking / MemOS** — those are memory *services* (own DBs, REST APIs, agent runtimes). LlamaIndex is a *library* — runs in-process, BYO storage backends.
- vs. **graphiti / cognee** — graphiti is bitemporal-KG-as-a-service, cognee is ECL pipeline. PropertyGraphIndex covers the in-process KG-construction case with composable extractors; the cognee adapter (`llama-index-graph-rag-cognee`) lets you use cognee as the KG backend instead.

## Code pointers

- Memory waterfall: [llama-index-core/llama_index/core/memory/memory.py:179-…](https://github.com/run-llama/llama_index/blob/main/llama-index-core/llama_index/core/memory/memory.py) (`class Memory`); blocks at [llama-index-core/llama_index/core/memory/memory_blocks/](https://github.com/run-llama/llama_index/tree/main/llama-index-core/llama_index/core/memory/memory_blocks).
- Property graph: [llama-index-core/llama_index/core/indices/property_graph/](https://github.com/run-llama/llama_index/tree/main/llama-index-core/llama_index/core/indices/property_graph) — `base.py` (PropertyGraphIndex), `sub_retrievers/`, `transformations/`.
- Ingestion pipeline: [llama-index-core/llama_index/core/ingestion/pipeline.py](https://github.com/run-llama/llama_index/blob/main/llama-index-core/llama_index/core/ingestion/pipeline.py).
- Workflow shim: [llama-index-core/llama_index/core/workflow/workflow.py](https://github.com/run-llama/llama_index/blob/main/llama-index-core/llama_index/core/workflow/workflow.py) (re-exports from external `workflows` package).
- MCP integration: [llama-index-integrations/tools/llama-index-tools-mcp/](https://github.com/run-llama/llama_index/tree/main/llama-index-integrations/tools/llama-index-tools-mcp) — `client.py`, `base.py`, `tool_spec_mixins.py`.
- Cognee bridge: [llama-index-integrations/graph_rag/llama-index-graph-rag-cognee/](https://github.com/run-llama/llama_index/tree/main/llama-index-integrations/graph_rag/llama-index-graph-rag-cognee).

## Open questions

- The cognee adapter pins `llama-index-core>=0.13.0,<0.15` — does the upcoming v0.15 break the graph-RAG protocol surface?
- 571 packages × independent semver = real cost. Is there a published compatibility matrix or is `uv.lock` (687 KB at repo root) the de-facto answer?
- `core/memory/` only ships 3 block types — is the expectation that users subclass `BaseMemoryBlock`, or are richer blocks (entity-memory, summary-memory) coming as integration packages similar to how `llama-index-memory-mem0` exists?

---

*Audit 2026-05-02: clone-verified against [run-llama/llama_index@main](https://github.com/run-llama/llama_index) (last commit 2026-05-01 09:56). Core version 0.14.21 / MIT. Integration counts (vector_stores=78, llms=104, embeddings=66, readers=159, tools=68, postprocessor=26, memory=2, graph_stores=7, graph_rag=1, retrievers=14, indices=9; total integration packages=571) verified by enumerating `llama-index-integrations/<category>/` directly. Memory class hierarchy (`Memory`, `BaseMemoryBlock`, `FactExtractionMemoryBlock`, `StaticMemoryBlock`, `VectorMemoryBlock`) verified in `core/memory/memory.py` lines 94/179 and `core/memory/memory_blocks/{fact,static,vector}.py`. PropertyGraphIndex sub-retriever and transformation lists verified verbatim from `core/indices/property_graph/__init__.py`. MCP integration confirmed at `llama-index-integrations/tools/llama-index-tools-mcp/pyproject.toml` v0.4.8 (`mcp>=1.24.0,<2`); `workflow_as_mcp` confirmed in package README. Cognee dep `cognee[neo4j, postgres, qdrant]` verified in `llama-index-graph-rag-cognee/pyproject.toml`. Graph stores enumerated: ApertureDB, falkordb, memgraph, nebula, neo4j, neptune, tidb. Memory adapters enumerated: mem0, bedrock-agentcore. Corrections: none (first-pass survey).*
