# Survey: microsoft/graphrag

**Date:** 2026-05-01
**Stars:** 32,670 · **Last push:** 2026-04-13 · **Created:** 2024 (Microsoft Research blog post April 2024) · **Version:** `3.0.9`
**Category:** graphrag
**Slug:** [microsoft/graphrag](https://github.com/microsoft/graphrag)

---

## TL;DR (3 lines)

- **What it is:** Microsoft Research's reference implementation of GraphRAG — an LLM-driven indexing pipeline that turns unstructured text into a hierarchical knowledge graph + community-report summaries, then queries it through four named search modes.
- **How its KB works:** Pure batch pipeline, no online memory. Inputs (CSV/JSON/Markdown/Parquet) → token/sentence chunks → LLM `GraphExtractor` produces entities + relationships in a custom `<|>`-delimited format → Hierarchical Leiden communities (graspologic-native) → LLM community-report summaries → outputs land as Parquet tables; embeddings go to a pluggable vector store (LanceDB / Azure AI Search / Cosmos DB).
- **Verdict:** Pick when you have a static corpus and need *thematic* (global) and *entity-anchored* (local) Q&A — not when you need conversational memory, MCP integration, or incremental write-throughs. The repo is explicitly a "demonstration, not an officially supported Microsoft offering."

## KB Architecture

### Storage
- **Vector store:** Pluggable factory ([`vector_store_factory.py`](https://github.com/microsoft/graphrag/blob/main/packages/graphrag-vectors/graphrag_vectors/vector_store_factory.py)) — built-ins: **LanceDB** (default), **Azure AI Search**, **Cosmos DB**. Custom backends can be registered via `register_vector_store()`.
- **Graph store:** *None native.* The graph is held in-memory as a NetworkX `DiGraph`, then persisted as Parquet tables (`entities.parquet`, `relationships.parquet`, `communities.parquet`, `community_reports.parquet`). Hierarchical Leiden runs via `graspologic-native`.
- **Metadata / structured:** **Parquet files** on a pluggable storage backend ([`storage_factory.py`](https://github.com/microsoft/graphrag/blob/main/packages/graphrag-storage/graphrag_storage/)) — file / Azure Blob / Azure Cosmos / in-memory. There is no relational metadata DB.
- **Object / blob:** Same factory — file (default), Azure Blob, Cosmos DB containers, or in-memory.

### Ingestion / Extraction
- **Source types accepted:** CSV, JSON, JSONL, plain text, Markdown (via `markitdown`), Parquet. Selection through `input_reader_factory` ([packages/graphrag-input/graphrag_input/](https://github.com/microsoft/graphrag/tree/main/packages/graphrag-input/graphrag_input)).
- **Chunking strategy:** Token chunker (tiktoken) or sentence chunker (NLTK) — `graphrag-chunking` package, configured via `chunker_factory`.
- **Entity / fact extraction:** **LLM-based** `GraphExtractor` — a single prompt asks the model to return entities and relationships using delimiters `TUPLE_DELIMITER = "<|>"`, `RECORD_DELIMITER = "##"`, `COMPLETION_DELIMITER = "<|COMPLETE|>"`. Iterative *gleanings* loop ("did we miss any?") up to `max_gleanings`. Optional `extract_covariates` produces *claims* (covariates) with subject / object / type / status / period / description fields. Default model is configurable; OpenAI / Azure OpenAI common.
- **Schema:** **Triple + community-hierarchy** — `Entity` (with `description_embedding`, `name_embedding`, `community_ids`, `text_unit_ids`, `rank`, `attributes`) → `Relationship` → `Community` (Leiden cluster, hierarchical via `parent`/`children`/`level`) → `CommunityReport` (LLM-summarized findings + `rank` + `findings: dict`) → `TextUnit` → `Document`. Optional `Covariate` for claims.

### Retrieval
- **Modes:** Four named modes in [`packages/graphrag/graphrag/query/structured_search/`](https://github.com/microsoft/graphrag/tree/main/packages/graphrag/graphrag/query/structured_search):
  - **Basic Search** — vanilla vector RAG over text units (provided to make A/B comparison easy).
  - **Local Search** — entity-anchored: vector-search entities → pull their text units, relationships, and community reports → assemble context.
  - **Global Search** — map-reduce over *all* community reports for thematic / corpus-wide questions.
  - **DRIFT Search** — community-aware iterative local: a primer query produces follow-up questions that drill into communities (`primer.py` + `action.py` + `state.py`).
- **Reranker:** *None.* Retrieval relies on cosine similarity + community-rank ordering.
- **Top-k defaults:** Per-mode (configurable via context-builder params). No single global `k`.
- **Context assembly:** Mode-specific `LocalContextBuilder` / `community_context.py` / `drift_context.py` that fill a templated system prompt with entities + relationships + community summaries + raw text units.

### Memory model
- **Tiers:** *None.* This is an offline indexing + query library. No conversation history beyond an optional `ConversationHistory` passed at query time.
- **Bi-temporal:** No — communities/reports carry `period` (ISO8601 date of ingest) for incremental-update merges, but no `valid_at`/`invalid_at`.
- **Self-update mechanism:** Explicit batch via `graphrag update` CLI / `update_*` workflows ([`packages/graphrag/graphrag/index/workflows/update_*.py`](https://github.com/microsoft/graphrag/tree/main/packages/graphrag/graphrag/index/workflows)). Not online.
- **Decay / forgetting:** None.

### MCP / connectors
- **MCP server exposed:** **No.**
- **MCP client used:** **No.**
- **Native connectors:** None — input is files-on-disk only.
- **Tool-call surface:** N/A. Reading the code, `grep -rE 'mcp|FastMCP|model_context'` over the entire monorepo returns zero hits.

### Notable design choices
- **Parquet as the canonical KB output** — every persistent table (entities, relationships, communities, community_reports, text_units, documents, optional covariates) lives as a Parquet file. The vector store is a *separate* index built off `description_embedding` / `name_embedding` columns, not the source-of-truth.
- **Hierarchical Leiden + LLM community summaries** — the central architectural bet that distinguishes GraphRAG from naive RAG. Communities are recursively subdivided, each level gets its own LLM-generated `CommunityReport` with `findings` (top 5–10 insights). Global Search is map-reduce over *those* reports rather than over raw chunks.
- **Custom delimiter format for LLM extraction** — instead of JSON, the prompt asks for tuples like `("entity"<|>NAME<|>TYPE<|>DESCRIPTION)` separated by `##`. Designed to be robust to mid-token cutoff and easier to repair than malformed JSON.
- **Workflow-based pipeline** — every step (`create_base_text_units`, `extract_graph`, `create_communities`, `generate_text_embeddings`, `update_*`, …) is a discrete file in [`workflows/`](https://github.com/microsoft/graphrag/tree/main/packages/graphrag/graphrag/index/workflows), composable via `factory.py`. The `update_*` family parallels `create_*` — incremental update is a first-class concept.
- **Monorepo with 8 sub-packages** — `graphrag` (CLI + workflows), `graphrag-llm`, `graphrag-vectors`, `graphrag-storage`, `graphrag-input`, `graphrag-chunking`, `graphrag-cache`, `graphrag-common`. Each pins to the same version and ships independently to PyPI.
- **`unified-search-app/`** — a separate Streamlit demo app shipped in the monorepo for browsing indexed datasets.

## Dependencies (KB-relevant)

From `packages/graphrag/pyproject.toml` and sub-package pyprojects:

```
# Core (graphrag)
azure-identity~=1.25
azure-search-documents~=11.5     # Azure AI Search vector backend
azure-storage-blob~=12.24        # Azure Blob storage backend
graspologic-native~=1.2          # Hierarchical Leiden community detection
networkx~=3.4                    # In-process graph
nltk~=3.9                        # Sentence chunker
spacy~=3.8                       # NLP utilities
blis~=1.0                        # spacy backend
textblob~=0.18                   # NLP
pandas~=2.3, pyarrow~=22.0       # Parquet I/O is everywhere
pydantic~=2.10, typer~=0.16      # config + CLI

# graphrag-vectors
lancedb~=0.24.1                  # default vector backend
azure-cosmos~=4.9                # Cosmos DB vector backend

# graphrag-storage
aiofiles~=24.1, azure-storage-blob, azure-cosmos

# graphrag-llm  (not shown — wraps OpenAI/Azure for chat + embeddings)
```

License: **MIT** (file: `LICENSE`).

## Tradeoffs

**Pros:**
- **Best-in-class for thematic / corpus-wide Q&A** — Global Search over community reports is the only design in this cohort that natively answers "what are the dominant themes across this corpus?". Local + DRIFT cover entity-anchored questions on the same index.
- **Operationally minimal — no graph DB to run** — entire graph layer is NetworkX + Parquet. The only stateful service is the chosen vector backend (and even that defaults to embedded LanceDB).
- **Auditable outputs** — every artifact (entities, relationships, communities, reports) is a queryable Parquet table. Trivial to inspect, snapshot, version, or post-process with pandas / DuckDB / polars.
- **Pluggable factories everywhere** — vector store, blob storage, chunker, input reader. Swapping LanceDB→Azure AI Search→a custom Postgres backend is a registration call, not a fork.
- **Explicit incremental-update path** — `graphrag update` re-runs only the workflows touched by new documents; `period` columns make merge semantics deterministic.

**Cons:**
- **Indexing is expensive** — the README explicitly warns: "*GraphRAG indexing can be an expensive operation, please read all of the documentation to understand the process and costs involved, and start small.*" Two LLM passes per document (extract + community report) plus optional gleanings + covariates.
- **No memory / conversation primitives** — Q&A is one-shot per query. No write-back, no fact decay, no per-user scoping. This is a RAG library, not a memory framework.
- **No MCP, no native connectors** — files-on-disk in, files-on-disk + vector index out. No Slack / Notion / GitHub readers; no MCP-server wrapper for tool-using agents.
- **No reranker** — relies on community-rank ordering; cohort peers like khoj/ragflow ship explicit rerankers.
- **In-memory NetworkX has a corpus ceiling** — fine for thousands of documents, awkward for millions. No `Memgraph` / `Neo4j` substitution path is built in (you'd persist + re-load yourself).
- **"Demonstration, not officially supported"** — Microsoft's own positioning. Production users typically fork or vendor.

## When to use it

- **Good fit:** static / slow-changing corpora (research docs, regulatory archives, post-mortems) where you need both *thematic overviews* and *entity-anchored answers* on the same dataset; teams comfortable running batch indexing pipelines and willing to pay the LLM extraction cost up-front.
- **Bad fit:** conversational / agent memory; live ingestion of chat or events; deployments without an LLM budget; small corpora where naive RAG suffices; codebases where MCP / tool-use integration is the goal.
- **Closest alternative:** [`HKUDS/LightRAG`](surveys/HKUDS__LightRAG.md) — same "extract a graph, then query it" thesis but built around 4 storage abstractions with 13 swappable backend impls, 6 named retrieval modes (incl. `bypass`), and a FastAPI server. LightRAG is more service-oriented (long-running API + WebUI); GraphRAG is more pipeline-oriented (CLI + Parquet outputs). [`circlemind-ai/fast-graphrag`](surveys/circlemind-ai__fast-graphrag.md) is the **library-shaped** counterpart — single import, pickle-only persistence, personalized PageRank as the primary retrieval primitive; README claims **6× cost reduction** vs microsoft/graphrag on Wizard of Oz ($0.08 vs $0.48). [`getzep/graphiti`](surveys/getzep__graphiti.md) covers the *online memory* gap GraphRAG leaves with bi-temporal edges and incremental writes — but optimizes for conversation memory, not corpus-wide thematic Q&A.

## Code pointers (evidence)

- LLM graph extractor (custom delimiter prompt + gleanings loop): [`packages/graphrag/graphrag/index/operations/extract_graph/graph_extractor.py:38`](https://github.com/microsoft/graphrag/blob/main/packages/graphrag/graphrag/index/operations/extract_graph/graph_extractor.py)
- Hierarchical Leiden clustering: [`packages/graphrag/graphrag/index/operations/cluster_graph.py`](https://github.com/microsoft/graphrag/blob/main/packages/graphrag/graphrag/index/operations/cluster_graph.py) → calls `graspologic-native`'s `hierarchical_leiden`
- Community-report extraction: [`packages/graphrag/graphrag/index/operations/summarize_communities/community_reports_extractor.py`](https://github.com/microsoft/graphrag/blob/main/packages/graphrag/graphrag/index/operations/summarize_communities/community_reports_extractor.py)
- Vector-store factory (3 built-in backends): [`packages/graphrag-vectors/graphrag_vectors/vector_store_factory.py:54`](https://github.com/microsoft/graphrag/blob/main/packages/graphrag-vectors/graphrag_vectors/vector_store_factory.py)
- Storage factory (file / Azure Blob / Cosmos / memory): [`packages/graphrag-storage/graphrag_storage/storage_factory.py`](https://github.com/microsoft/graphrag/blob/main/packages/graphrag-storage/graphrag_storage/storage_factory.py)
- Local Search orchestration: [`packages/graphrag/graphrag/query/structured_search/local_search/search.py:31`](https://github.com/microsoft/graphrag/blob/main/packages/graphrag/graphrag/query/structured_search/local_search/search.py)
- Global Search (map-reduce) and DRIFT Search: [`packages/graphrag/graphrag/query/structured_search/global_search/search.py`](https://github.com/microsoft/graphrag/blob/main/packages/graphrag/graphrag/query/structured_search/global_search/search.py), [`drift_search/search.py`](https://github.com/microsoft/graphrag/blob/main/packages/graphrag/graphrag/query/structured_search/drift_search/search.py)
- Entity data model with embeddings + community membership: [`packages/graphrag/graphrag/data_model/entity.py:13`](https://github.com/microsoft/graphrag/blob/main/packages/graphrag/graphrag/data_model/entity.py)
- Workflow registry (entry points for `graphrag index` / `graphrag update`): [`packages/graphrag/graphrag/index/workflows/factory.py`](https://github.com/microsoft/graphrag/blob/main/packages/graphrag/graphrag/index/workflows/factory.py)
- Output schema reference: [`docs/index/outputs.md`](https://github.com/microsoft/graphrag/blob/main/docs/index/outputs.md)
- Most useful single file to read first: [`docs/index/default_dataflow.md`](https://github.com/microsoft/graphrag/blob/main/docs/index/default_dataflow.md) for the pipeline shape, then [`packages/graphrag/graphrag/api/index.py`](https://github.com/microsoft/graphrag/blob/main/packages/graphrag/graphrag/api/index.py) for the Python entrypoint.

## Open questions

- How does production-grade GraphRAG (Azure AI's hosted service) diverge from this open repo? The README disclaims "not an officially supported Microsoft offering" — likely the hosted version swaps NetworkX for a real graph DB and adds API surface, but neither code nor architecture diff is visible from this repo.
- DRIFT search docs are sparse — the algorithmic details (how follow-up questions are generated, when to terminate) are best understood by reading `drift_search/primer.py` + `state.py` directly. Worth a deeper future pass.
- The `unified-search-app/` Streamlit demo isn't part of the published `graphrag` PyPI package; coverage of its config is spotty.

---

*Surveyed via the `curating-agentic-kbs` skill. Re-survey scheduled after 30 days of last `pushed_at` change.*

*Audit 2026-05-02: clone-verified against [`packages/`](https://github.com/microsoft/graphrag/tree/main/packages) (all 8 sub-packages: graphrag, graphrag-cache, graphrag-chunking, graphrag-common, graphrag-input, graphrag-llm, graphrag-storage, graphrag-vectors), [`packages/graphrag/graphrag/query/structured_search/`](https://github.com/microsoft/graphrag/tree/main/packages/graphrag/graphrag/query/structured_search) (4 modes: basic / drift / global / local), [`packages/graphrag-vectors/`](https://github.com/microsoft/graphrag/tree/main/packages/graphrag-vectors/graphrag_vectors) (3 backends: lancedb / azure_ai_search / cosmosdb), [`packages/graphrag-storage/`](https://github.com/microsoft/graphrag/tree/main/packages/graphrag-storage/graphrag_storage) (4 backends: file / azure_blob / azure_cosmos / memory), [`extract_graph/graph_extractor.py:31-33`](https://github.com/microsoft/graphrag/blob/main/packages/graphrag/graphrag/index/operations/extract_graph/graph_extractor.py#L31-L33) (`TUPLE_DELIMITER = "<\|>"` / `RECORD_DELIMITER = "##"` / `COMPLETION_DELIMITER = "<\|COMPLETE\|>"` — exact verbatim). **All major claims verified verbatim:** 4 search modes, 3 vector backends, 4 storage backends, 8-package monorepo, custom delimiters, hierarchical Leiden via `graspologic-native~=1.2`, no MCP at all (grep `mcp\.|FastMCP|model_context_protocol` returns 0 hits across all packages). Added version `3.0.9`. **No corrections needed** — survey quality matches cognee tier.*

*Re-audit iter 72 (2026-05-03): re-verified version pin + 8-package monorepo. Architectural state unchanged: `packages/graphrag` v3.0.9 still current, monorepo `0.0.0` umbrella unchanged, 8 sub-packages still match (graphrag / -cache / -chunking / -common / -input / -llm / -storage / -vectors). MIT unchanged. ★32,670 → ★32,720 (+50 stars, ~0.15% growth in 2 days — moderate velocity, slightly faster than LightRAG's +0.08%). `pushed_at` 2026-04-30 unchanged. No corrections needed — survey is current. Cohort cross-link: still consumed by [`fast-graphrag`](circlemind-ai__fast-graphrag.md) survey as "service-shaped → pipeline-shaped → library-shaped" graphrag taxonomy (3-shape framing established iter 43).*
