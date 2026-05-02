# Survey: getzep/graphiti

**Date:** 2026-05-01
**Stars:** 25,575 · **Last push:** 2026-04-30 · **Created:** 2024-08-08
**Category:** memory-framework
**Slug:** [getzep/graphiti](https://github.com/getzep/graphiti)

---

## TL;DR (3 lines)

- **What it is:** Python library for building **temporally-aware knowledge graphs** for AI agents — the only surveyed repo whose primary data model is **bi-temporal**: every `EntityEdge` carries `valid_at` / `invalid_at` (validity time) plus `created_at` (recorded time) plus `expired_at` (when an updated fact superseded it).
- **How its KB works:** Each `add_episode` call routes a message/JSON event through LLM extraction → typed entities + edges (Pydantic schemas) → stored in **Neo4j (default), FalkorDB, Kuzu, or Neptune** with vector indexes ON the graph; retrieval is hybrid (semantic + BM25 + graph traversal) combined via RRF or cross-encoder reranking; episodes themselves are linked nodes (`EpisodicNode` + `HasEpisodeEdge`).
- **Verdict:** Pick when the *audit trail* matters — "what did we know on date X?" is a first-class query. Skip if you don't need temporality (mem0 will be cheaper to operate).

## KB Architecture

### Storage
- **Vector store:** **none separate** — vector indexes live ON the graph (Neo4j vector index, FalkorDB vector index)
- **Graph store:** **4 backends** — **Neo4j 5.26+** (primary), **FalkorDB** (Redis-based graph), **Kuzu** (embedded), **AWS Neptune** (`graphiti_core/driver/{neo4j,falkordb,kuzu,neptune}_driver.py`)
- **Metadata / structured:** none separate — node/edge properties carry it; `EntityNode`, `EpisodicNode`, `CommunityNode`, `SagaNode` are the schema
- **Object / blob:** N/A — episodic events stored as graph properties
- **Optional full-text:** **OpenSearch** via `neo4j-opensearch` extra (boto3 + opensearch-py) — augments Neo4j BM25 when scaled

### Ingestion / Extraction
- **Source types accepted:** **episodic events** — text messages, JSON, tool outputs; `EpisodeType` enum + `RawEpisode` model
- **Chunking strategy:** **none** — each episode is one unit
- **Entity / fact extraction:** **LLM-based** with custom **Pydantic entity types**; prompts in `graphiti_core/prompts/` for extraction, deduplication, summarization, saga summary; **gliner2** optional extra for non-LLM entity extraction
- **Schema:** `EntityNode`, `EpisodicNode` (the raw event), `CommunityNode` (Leiden-style cluster), `SagaNode` (sequence of related episodes); edges: `EntityEdge`, `EpisodicEdge`, `HasEpisodeEdge`, `NextEpisodeEdge`, `CommunityEdge`
- **Custom entity definitions:** users register Pydantic models — typed memory, validated at extract time
- **Deduplication:** explicit `dedupe_nodes_bulk`, `dedupe_edges_bulk` operations on bulk ingest

### Retrieval
- **Modes:** **hybrid** — semantic (vector) + BM25 + **graph traversal**, combined via **16 pre-baked recipes** in [`search_config_recipes.py`](https://github.com/getzep/graphiti/blob/main/graphiti_core/search/search_config_recipes.py) (Combined×3, Edge×5, Node×5, Community×3). Sample:
  - `COMBINED_HYBRID_SEARCH_CROSS_ENCODER` — vector+BM25 then cross-encoder rerank
  - `EDGE_HYBRID_SEARCH_RRF` — vector+BM25 fused with Reciprocal Rank Fusion
  - `EDGE_HYBRID_SEARCH_NODE_DISTANCE` — vector+BM25 weighted by graph distance from a focal node
  - `EDGE_HYBRID_SEARCH_MMR` — Maximal Marginal Relevance for diverse results
  - `EDGE_HYBRID_SEARCH_EPISODE_MENTIONS` — boost edges by episode-mention frequency
- **Reranker modes (4):** `rrf`, `node_distance`, `mmr`, `cross_encoder` — exposed as `EdgeReranker` / `NodeReranker` / `EpisodeReranker` / `CommunityReranker` enums in [`search_config.py`](https://github.com/getzep/graphiti/blob/main/graphiti_core/search/search_config.py)
- **Cross-encoder backends (4):** **BGE**, **OpenAI** (LLM-as-reranker), **Gemini**, base abstract ([`graphiti_core/cross_encoder/`](https://github.com/getzep/graphiti/tree/main/graphiti_core/cross_encoder))
- **Top-k defaults:** `DEFAULT_SEARCH_LIMIT` configurable; `RELEVANT_SCHEMA_LIMIT` for typed-edge results
- **Filters:** `SearchFilters` — by entity type, edge type, time range, group_id (multi-tenancy)

### Memory model
- **Tiers (4 Node classes):** [`EpisodicNode`](https://github.com/getzep/graphiti/blob/main/graphiti_core/nodes.py#L318) (raw events, time-stamped) + [`EntityNode`](https://github.com/getzep/graphiti/blob/main/graphiti_core/nodes.py#L499) (semantic facts, derived) + [`CommunityNode`](https://github.com/getzep/graphiti/blob/main/graphiti_core/nodes.py#L687) (Leiden-style cluster summaries) + [`SagaNode`](https://github.com/getzep/graphiti/blob/main/graphiti_core/nodes.py#L867) (summarized sequences of related episodes). `EpisodicNode.source: EpisodeType` enum is one of `message` / `json` / `text` / `fact_triple`.
- **Bi-temporal (4 fields):** every `EntityEdge` has `valid_at` (when fact became true), `invalid_at` (when invalidated), `expired_at` (when superseded by an update), `created_at` (when graphiti learned it). Querying "what we knew on date X" works directly. ([`edges.py:271-277`](https://github.com/getzep/graphiti/blob/main/graphiti_core/edges.py#L271-L277))
- **Self-update mechanism:** `add_episode` triggers extract → dedupe → relate → embed → optionally invalidate stale edges
- **Decay / forgetting:** **temporal invalidation** rather than score-based — facts get `invalid_at` set when superseded, kept for audit

### MCP / connectors
- **MCP server exposed:** **yes** — dedicated `mcp_server/` directory with full implementation (Docker Compose with Neo4j)
- **MCP client used:** **no** — graphiti is the *backend* memory; client side is the consumer
- **Native connectors:** N/A — accepts events programmatically via `add_episode`
- **REST API:** `server/` directory wraps graphiti as FastAPI service

### Notable design choices
- **Bi-temporal as a primitive, not a workaround** — every edge has the full triple of times; this is the differentiator vs. mem0 / openclaw / others that only track recorded time
- **Graph IS the storage** — no separate vector DB or metadata DB; vector index lives ON Neo4j/FalkorDB
- **Custom Pydantic entity types** — typed memory at extract time; graphiti rejects ill-formed entities up front
- **Search recipes, not search params** — pre-baked combinations (RRF, node-distance-weighted, cross-encoder) you compose by name
- **First-class OpenTelemetry tracing** — `OTEL_TRACING.md` documents the integration; graphiti operations show up as spans
- **Bulk dedup utilities** — `dedupe_nodes_bulk`, `dedupe_edges_bulk` for backfills (the "load 1M episodes" path)
- **MCP server exposes the temporal queries** — agents can ask "what changed in entity X yesterday" through MCP

## Dependencies (KB-relevant)

From `pyproject.toml`:

```
neo4j>=5.26.0                           # default graph backend, in core deps
openai>=1.91.0                          # default LLM + embedder, in core deps
pydantic>=2.11.5

extras:
  kuzu>=0.11.3                          # alt graph backend
  falkordb>=1.1.2,<2.0.0                # alt graph backend
  voyageai>=0.2.3                       # embedder option
  sentence-transformers>=3.2.1          # embedder option
  gliner2>=1.2.0                        # non-LLM entity extraction
  neo4j-opensearch                      # boto3 + opensearch-py for full-text augmentation
  neptune                               # boto3 + langchain-aws + opensearch-py
  tracing                               # opentelemetry-api + opentelemetry-sdk
```

## Tradeoffs

**Pros:**
- Only library in this cohort with native bi-temporal model — audit / "what did we know when" queries are trivial
- 4 graph backends (Neo4j / FalkorDB / Kuzu / Neptune) cover SaaS, embedded, AWS-native, and Redis-based deployments
- Search recipes (RRF / node-distance / cross-encoder) eliminate the "tune your hybrid weights" trap
- Pydantic-typed entities mean memory schema is enforced — corrupted facts can't slip in
- OpenTelemetry first-class — production observability built in

**Cons:**
- No vector DB choice — you're committing to a graph backend even if your data is mostly tabular
- LLM cost per `add_episode` (extract → dedup → relate) — same write-amplification as mem0
- 4 cross-encoder rerankers (BGE / OpenAI / Gemini / base) is fewer than ragflow's 14
- Graph backends are heavier ops than a Postgres+pgvector single-stack
- Python-only — no TypeScript SDK (gap vs. mem0)

## When to use it

- **Good fit:** time-sensitive domains (compliance, legal, fund/portfolio knowledge, scientific KGs); teams that need "as-of-date" queries; multi-agent systems where audit trail matters
- **Bad fit:** simple chatbot memory (use mem0); document-shaped corpora (use ragflow); teams without graph DB ops experience
- **Closest alternative (in this cohort):** mem0 — also has Neo4j/Memgraph/Kuzu/AGE graph backends and auto-extract; trade graphiti's bi-temporal + saga for mem0's broader vector/graph plug-in surface and TypeScript SDK

## Code pointers (evidence)

- Bi-temporal schema: [`graphiti_core/edges.py:271-354`](https://github.com/getzep/graphiti/blob/main/graphiti_core/edges.py#L271-L354) — `valid_at`, `invalid_at`, `expired_at`, `created_at` on `EntityEdge`
- Node taxonomy: [`graphiti_core/nodes.py`](https://github.com/getzep/graphiti/blob/main/graphiti_core/nodes.py) — `EpisodicNode:318`, `EntityNode:499`, `CommunityNode:687`, `SagaNode:867`
- Main entry: `graphiti_core/graphiti.py` — `Graphiti` class orchestrates `add_episode` / `search` / `build_communities`
- Graph drivers: `graphiti_core/driver/{neo4j,falkordb,kuzu,neptune}_driver.py`
- Cross-encoders: `graphiti_core/cross_encoder/{bge,openai,gemini}_reranker_client.py`
- Search recipes: `graphiti_core/search/search_config_recipes.py` — pre-baked hybrid strategies
- Prompts: `graphiti_core/prompts/{summarize_sagas, ...}` — extraction, dedupe, saga
- MCP server: `mcp_server/graphiti_mcp_server.py`
- REST API: `server/graph_service/main.py`
- Most useful single file to read first: `graphiti_core/graphiti.py` — orchestrator

## Open questions

- How does the saga summarization scale with episode volume? Saga seems like a higher-order grouping but the cost model is unclear from a 30-min skim.
- What's the migration story between graph backends? `migrations/` exists but cross-backend isn't obvious.
- The OpenSearch extra suggests Neo4j BM25 hits a ceiling at scale — at what corpus size?

---

*Surveyed via the `curating-agentic-kbs` skill. Re-survey scheduled after 30 days of last `pushed_at` change.*

*Audit 2026-05-02: clone-verified against [`edges.py`](https://github.com/getzep/graphiti/blob/main/graphiti_core/edges.py), [`nodes.py`](https://github.com/getzep/graphiti/blob/main/graphiti_core/nodes.py), [`search/search_config.py`](https://github.com/getzep/graphiti/blob/main/graphiti_core/search/search_config.py), [`search/search_config_recipes.py`](https://github.com/getzep/graphiti/blob/main/graphiti_core/search/search_config_recipes.py), [`driver/`](https://github.com/getzep/graphiti/tree/main/graphiti_core/driver). **Corrections:** bi-temporal field set 3 → **4** (added `expired_at`); reranker mode set 3 → **4** (added `mmr`); recipe count quantified to **16** (Combined×3 + Edge×5 + Node×5 + Community×3); 4-tier schema name "semantic" → actual class name `EntityNode`. **Verified:** 4 graph drivers (Neo4j / FalkorDB / Kuzu / Neptune), 4 cross-encoder backends (BGE / OpenAI / Gemini / base), Pydantic-typed entities, MCP server (`mcp_server/`), REST API (`server/`), OpenTelemetry tracing.*

*Re-audit iter 64 (2026-05-02): re-verified version pin. `graphiti-core` package now at **v0.29.0** (was unpinned in initial survey — adding for future drift detection). Apache-2.0 unchanged. ★25,575 → ★25,610 (+35 stars, ~0.14% growth in 2 days — fastest of the re-audited memory-framework trio: graphiti +0.14% > cognee +0.12% > letta +0.04%). `pushed_at` 2026-04-30 unchanged. No architectural corrections needed — survey is current. Cohort cross-refs still hold: cognee's `graphiti-core>=0.28.0` extra dep remains forward-compatible with v0.29.0; FalkorDB and llama_index still consume graphiti via the same backend interfaces.*
