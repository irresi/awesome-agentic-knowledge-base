<h1 align="center">🧠 Awesome Agentic Knowledge Base</h1>

<p align="center">
  Empirical map of how trending AI agents build their knowledge base systems.
  Every entry is backed by a survey report of an actual repo. Components are ranked
  by adoption frequency across the surveyed cohort, not by fame.
</p>

> ⚠️ **Status: Under Review & Beta.** This map is being verified manually.

## Cohort

46 trending agentic repos, sorted by GitHub star count. **kb-app is the largest category (16 repos)**, followed by memory-framework (12), wiki-compiler (6), coding-agent (5), graphrag (3), infra-layer (3), and llama_index as the sole kb-framework — making it a downstream aggregator of much of the rest of the cohort.

| Repo | Category | What it is |
|---|---|---|
| [infiniflow/ragflow](https://github.com/infiniflow/ragflow) | kb-app | Production RAG with deep document understanding; swappable doc engine + per-format chunkers + in-memory NetworkX GraphRAG ([survey](surveys/infiniflow__ragflow.md)) |
| [OpenHands/OpenHands](https://github.com/OpenHands/OpenHands) | coding-agent | Multi-tenant coding-agent orchestrator; sandboxed runtime + microagent skill loader ([survey](surveys/OpenHands__OpenHands.md)) |
| [thedotmack/claude-mem](https://github.com/thedotmack/claude-mem) | coding-agent | Claude Code memory plugin; lifecycle hooks → SQLite + ChromaDB-via-stdio-MCP ([survey](surveys/thedotmack__claude-mem.md)) |
| [bytedance/deer-flow](https://github.com/bytedance/deer-flow) | coding-agent | ByteDance super agent harness; LangGraph-native v2 rewrite + 21 public skills ([survey](surveys/bytedance__deer-flow.md)) |
| [cline/cline](https://github.com/cline/cline) | coding-agent | VSCode/JetBrains/CLI coding agent; no DB — knowledge in `.clinerules/*.md` + `@file` mentions ([survey](surveys/cline__cline.md)) |
| [Mintplex-Labs/anything-llm](https://github.com/Mintplex-Labs/anything-llm) | kb-app | Workspace-scoped multi-LLM kb-app; 37 LLMs + 14 embedders + 10 vector backends in-tree ([survey](surveys/Mintplex-Labs__anything-llm.md)) |
| [mem0ai/mem0](https://github.com/mem0ai/mem0) | memory-framework | Universal memory layer; LLM auto-extracts atomic facts from chat with 24-vector-backend matrix ([survey](surveys/mem0ai__mem0.md)) |
| [run-llama/llama_index](https://github.com/run-llama/llama_index) | kb-framework | Foundational Python RAG/agent framework; 571 separately versioned integration packages ([survey](surveys/run-llama__llama_index.md)) |
| [Aider-AI/aider](https://github.com/Aider-AI/aider) | coding-agent | Terminal pair-programmer; PageRank-weighted tree-sitter "repo-map" KB, no LLM extraction ([survey](surveys/Aider-AI__aider.md)) |
| [safishamsi/graphify](https://github.com/safishamsi/graphify) | wiki-compiler | Code/docs/papers/images → graph; Python lib distributed as Claude Code skill + 10 sibling-IDE bundles ([survey](surveys/safishamsi__graphify.md)) |
| [mindsdb/mindsdb](https://github.com/mindsdb/mindsdb) | infra-layer | Federated SQL query engine; agents query unified data via single SQL surface, 34 in-tree handlers ([survey](surveys/mindsdb__mindsdb.md)) |
| [HKUDS/LightRAG](https://github.com/HKUDS/LightRAG) | graphrag | EMNLP 2025 GraphRAG library; 4-storage abstraction × 13 backends + 6 retrieval modes ([survey](surveys/HKUDS__LightRAG.md)) |
| [khoj-ai/khoj](https://github.com/khoj-ai/khoj) | kb-app | Self-hostable personal "second-brain"; single-Postgres KB stack via pgvector + Muninn memory agent ([survey](surveys/khoj-ai__khoj.md)) |
| [abhigyanpatwari/GitNexus](https://github.com/abhigyanpatwari/GitNexus) | wiki-compiler | "Zero-Server Code Intelligence Engine"; CLI+MCP + browser zero-server from one repo ([survey](surveys/abhigyanpatwari__GitNexus.md)) |
| [microsoft/graphrag](https://github.com/microsoft/graphrag) | graphrag | Microsoft Research's reference GraphRAG; pure batch pipeline + Hierarchical Leiden + Parquet outputs ([survey](surveys/microsoft__graphrag.md)) |
| [AstrBotDevs/AstrBot](https://github.com/AstrBotDevs/AstrBot) | kb-app | Multi-platform IM chatbot framework; SQLite + Faiss hybrid retrieval + 8 IM platform adapters ([survey](surveys/AstrBotDevs__AstrBot.md)) |
| [onyx-dot-app/onyx](https://github.com/onyx-dot-app/onyx) | kb-app | Most enterprise-shaped repo; 49 SaaS connectors + federated retrieval on Vespa/OpenSearch + ACP "Build" sandbox ([survey](surveys/onyx-dot-app__onyx.md)) |
| [simstudioai/sim](https://github.com/simstudioai/sim) | kb-app | Bun + Next.js workflow platform; 35 connectors + 220 tools + persisted-workflow-as-MCP server ([survey](surveys/simstudioai__sim.md)) |
| [ComposioHQ/composio](https://github.com/ComposioHQ/composio) | kb-app | Toolkit-routing-as-service; 1000+ third-party-tool integrations + per-user isolated MCP sessions ([survey](surveys/ComposioHQ__composio.md)) |
| [labring/FastGPT](https://github.com/labring/FastGPT) | kb-app | TypeScript-first kb + visual workflow platform; pgvector/Milvus/OceanBase + MongoDB metadata ([survey](surveys/labring__FastGPT.md)) |
| [getzep/graphiti](https://github.com/getzep/graphiti) | memory-framework | Bi-temporal KG library; every edge carries 4 temporal fields, Neo4j/FalkorDB/Kuzu/Neptune backends ([survey](surveys/getzep__graphiti.md)) |
| [deepset-ai/haystack](https://github.com/deepset-ai/haystack) | kb-app | Component-pipeline RAG framework; 24 component categories + 50+ vector-backend sibling packages ([survey](surveys/deepset-ai__haystack.md)) |
| [volcengine/OpenViking](https://github.com/volcengine/OpenViking) | memory-framework | ByteDance Volcengine "Context Database for AI Agents"; filesystem-paradigm context with 7 backend plugins ([survey](surveys/volcengine__OpenViking.md)) |
| [HKUDS/DeepTutor](https://github.com/HKUDS/DeepTutor) | kb-app | Agent-Native Personalized Tutoring; versioned KB indexes + scheduled TutorBot subsystem ([survey](surveys/HKUDS__DeepTutor.md)) |
| [letta-ai/letta](https://github.com/letta-ai/letta) | memory-framework | The original MemGPT; agent-self-managed memory blocks + 50 explicitly normalized ORM tables ([survey](surveys/letta-ai__letta.md)) |
| [1Panel-dev/MaxKB](https://github.com/1Panel-dev/MaxKB) | kb-app | "Max Knowledge Brain" enterprise agent platform from FIT2CLOUD; single-Postgres + pgvector ([survey](surveys/1Panel-dev__MaxKB.md)) |
| [arc53/DocsGPT](https://github.com/arc53/DocsGPT) | kb-app | Private AI platform for agents + assistants + enterprise search; 4-agent-type taxonomy + RAG-as-LLM-tool ([survey](surveys/arc53__DocsGPT.md)) |
| [topoteretes/cognee](https://github.com/topoteretes/cognee) | memory-framework | ECL (Extract / Cognify / Load) memory platform; rdflib/OWL ontologies + named "memify" pipelines ([survey](surveys/topoteretes__cognee.md)) |
| [AsyncFuncAI/deepwiki-open](https://github.com/AsyncFuncAI/deepwiki-open) | wiki-compiler | DeepWiki clone; turns GitHub/GitLab/BitBucket repo into wiki + Mermaid diagrams + Ask + DeepResearch ([survey](surveys/AsyncFuncAI__deepwiki-open.md)) |
| [memvid/memvid](https://github.com/memvid/memvid) | memory-framework | First Rust-native repo; single `.mv2` file packs WAL + Tantivy + HNSW + Logic-Mesh graph + signed/encrypted capsules ([survey](surveys/memvid__memvid.md)) |
| [tirth8205/code-review-graph](https://github.com/tirth8205/code-review-graph) | wiki-compiler | Token-efficient codebase KG; tree-sitter (32 languages) + MCP, auto-installs into 11 AI coding tools ([survey](surveys/tirth8205__code-review-graph.md)) |
| [Tencent/WeKnora](https://github.com/Tencent/WeKnora) | kb-app | Tencent's RAG + Agent + Auto-Wiki platform; 7 vector backends + 7 IM platforms + step-graph chat pipeline ([survey](surveys/Tencent__WeKnora.md)) |
| [MODSetter/SurfSense](https://github.com/MODSetter/SurfSense) | kb-app | Privacy-focused NotebookLM alternative; 22 connector indexers + 9 ETL parsers + 4-process distribution ([survey](surveys/MODSetter__SurfSense.md)) |
| [NevaMind-AI/memU](https://github.com/NevaMind-AI/memU) | memory-framework | "24/7 Always-On Proactive Memory" framework; Python with Rust core via PyO3 ([survey](surveys/NevaMind-AI__memU.md)) |
| [mksglu/context-mode](https://github.com/mksglu/context-mode) | kb-app | Context-engineering MCP server; tool-output sandboxing + "Think in Code" + 98% context reduction ([survey](surveys/mksglu__context-mode.md)) |
| [vectorize-io/hindsight](https://github.com/vectorize-io/hindsight) | memory-framework | Vectorize's open-source agent memory; biomimetic 3-tier (World facts / Experience facts / Mental models) ([survey](surveys/vectorize-io__hindsight.md)) |
| [Lum1104/Understand-Anything](https://github.com/Lum1104/Understand-Anything) | wiki-compiler | First wiki-compiler in cohort; Claude Code plugin → KG + React/React-Flow dashboard, no DB ([survey](surveys/Lum1104__Understand-Anything.md)) |
| [MemTensor/MemOS](https://github.com/MemTensor/MemOS) | memory-framework | Research-grade memory framework; three-tier cross-modality (KV-cache / LoRA / textual) + MemCube abstraction ([survey](surveys/MemTensor__MemOS.md)) |
| [xerrors/Yuxi](https://github.com/xerrors/Yuxi) | kb-app | CN-language Agent Harness explicitly built on LightRAG + Vue + FastAPI + LangGraph v1 ([survey](surveys/xerrors__Yuxi.md)) |
| [campfirein/byterover-cli](https://github.com/campfirein/byterover-cli) | memory-framework | Memory-router-as-product; `brv` CLI + Ink REPL + Vite Web UI over 7 memory backends ([survey](surveys/campfirein__byterover-cli.md)) |
| [FalkorDB/FalkorDB](https://github.com/FalkorDB/FalkorDB) | infra-layer | Graph-database engine loaded as Redis module; sparse-matrix adjacency via GraphBLAS + OpenCypher + Bolt ([survey](surveys/FalkorDB__FalkorDB.md)) |
| [memgraph/memgraph](https://github.com/memgraph/memgraph) | infra-layer | Cypher-compatible in-memory graph DB; single-query atomic retrieval (text + vector + graph) ([survey](surveys/memgraph__memgraph.md)) |
| [AgriciDaniel/claude-obsidian](https://github.com/AgriciDaniel/claude-obsidian) | wiki-compiler | Claude Code plugin + Obsidian vault implementing Andrej Karpathy's "LLM Wiki" pattern ([survey](surveys/AgriciDaniel__claude-obsidian.md)) |
| [circlemind-ai/fast-graphrag](https://github.com/circlemind-ai/fast-graphrag) | graphrag | Library-only GraphRAG; Personalized PageRank as primary retrieval primitive + pickle-only persistence ([survey](surveys/circlemind-ai__fast-graphrag.md)) |
| [plastic-labs/honcho](https://github.com/plastic-labs/honcho) | memory-framework | Plastic Labs's memory library; peer paradigm + scheduled "memory consolidation agent" (Dreamer) ([survey](surveys/plastic-labs__honcho.md)) |
| [basicmachines-co/basic-memory](https://github.com/basicmachines-co/basic-memory) | memory-framework | Local-first Zettelkasten + KG over markdown files; rule-based grammar (no LLM extraction) ([survey](surveys/basicmachines-co__basic-memory.md)) |

## Adoption — Storage

Storage breaks down into seven roles. **Vector stores** dominate the cohort (only 7 repos run none); **Postgres and SQLite** dominate metadata; **Redis** is the standard cache; **S3-compatible blob storage** is universal among production-shaped kb-apps. **Graph storage** stays niche — most cohort repos either skip graphs entirely or run an in-process NetworkX. **Embedders** are split between local sentence-transformers and cloud APIs. A small but distinctive **Markdown-filesystem camp** treats `.md` files as the primary KB substrate (sometimes with a derived DB index, sometimes with no DB at all).

### Vector store

| Component | Used by | % | Trade-offs |
|---|---|---|---|
| pgvector | mem0, FastGPT, cognee, khoj, MaxKB, WeKnora, letta | 23% | Postgres-stack ops; cohort's most-adopted vector backend |
| Milvus | mem0, FastGPT, LightRAG, WeKnora, MemOS | 17% | mature pure-vector engine, separate service |
| OpenSearch | ragflow, mem0, graphiti, LightRAG, onyx | 17% | strong full-text + vector, JVM ops |
| Faiss | mem0, LightRAG, AstrBot, deepwiki-open | 13% | embeddable C++ library, search-only |
| Qdrant | mem0, LightRAG, WeKnora, MemOS | 13% | Rust + good filtering, separate service |
| ChromaDB | mem0, cognee, claude-mem (via stdio MCP) | 10% | embeddable; claude-mem skips the npm package by going stdio-MCP |
| Elasticsearch | ragflow, mem0, WeKnora | 10% | mature hybrid search, JVM ops |
| Pinecone | mem0, letta | 7% | managed serverless vector DB |
| Turbopuffer | mem0, letta | 7% | serverless vector with per-namespace isolation |
| SQLite-FTS5 + optional vectors | basic-memory, code-review-graph | 7% | minimum-viable hybrid search inside one SQLite file |
| LanceDB | cognee, graphrag (default) | 7% | embedded columnar; ships as the GraphRAG default |
| Azure AI Search | mem0, graphrag | 7% | hosted hybrid retrieval, vendor-tied |
| Weaviate | mem0, WeKnora | 7% | graph-aware vector with native multi-tenancy |
| sqlite-vec | basic-memory, WeKnora | 7% | embedded vector for SQLite |

**No vector store in core** — 7 repos: cline, aider, OpenHands (orchestrator), Understand-Anything, byterover-cli (delegates to swarm router), deer-flow (per-skill external services), haystack (core ships `InMemoryDocumentStore` only; production backends in 50+ sibling packages).

**Singletons** (1 repo only):

- ragflow — Infinity
- mem0 — MongoDB / Cassandra / Vertex AI / Upstash / Supabase / Redis-as-vector / S3-Vectors
- FastGPT — OceanBase / OpenGauss / SeekDB
- LightRAG — nano-vectordb (default)
- graphrag — Cosmos DB
- onyx — Vespa (default)
- memvid — HNSW-inside-`.mv2`
- WeKnora — Neo4j-as-vector
- OpenViking — filesystem-paradigm context with L0/L1/L2 tiered embedding

### Graph store

| Component | Used by | % | Trade-offs |
|---|---|---|---|
| Neo4j | graphiti, cognee, LightRAG, WeKnora, MemOS | 17% | mature Cypher + vector index, heavy ops |
| NetworkX (in-process) | ragflow, LightRAG, graphrag, haystack | 13% | zero-ops |
| Kuzu | graphiti, cognee | 7% | embeddable, smaller community |
| AWS Neptune | graphiti, cognee | 7% | managed + AWS-native; vendor-lock |

**No graph at all** — 12 repos: mem0 (graph removed in v3 — built-in entity linking instead), FastGPT, basic-memory, OpenHands, claude-mem, cline, aider, khoj, AstrBot, MaxKB, deepwiki-open, deer-flow.

**Singletons** (1 repo only):

- LightRAG — Memgraph (mem0 removed it in v3)
- graphiti — FalkorDB
- onyx — Postgres-as-graph
- memvid — Logic-Mesh in-`.mv2`-file
- Understand-Anything — `knowledge-graph.json` with 35 typed edges
- MemOS — PolarDB
- code-review-graph — SQLite-backed graph with BFS impact analysis + Leiden community detection (cohort second after graphrag)

### Metadata / structured store

| Component | Used by | % | Trade-offs |
|---|---|---|---|
| Postgres | mem0, FastGPT, cognee, basic-memory, OpenHands, LightRAG, khoj, onyx, MaxKB, WeKnora, MemOS, deer-flow (opt-in), letta, memU | 47% | de-facto cohort default for ops-grade metadata |
| SQLite | cognee, basic-memory, claude-mem, aider (diskcache), AstrBot, WeKnora, deer-flow, code-review-graph, memU | 30% | embedded, zero-ops; single-machine ceiling |
| MongoDB | FastGPT, LightRAG | 7% | document-store; rich querying |
| MySQL | ragflow, MemOS | 7% | CN-cloud-friendly metadata store |

**File-only no-DB camp** — 5 repos:

- cline — `~/.cline/data/*.json`
- memvid — single `.mv2`
- Understand-Anything — `.understand-anything/*.json`
- byterover-cli — `.brv/` git-like tree
- claude-obsidian — Obsidian Markdown vault (`wiki/` + `.raw/` + `.vault-meta/`) with git auto-commits on every wiki write

**Singletons** (1 repo only):

- LightRAG — JSON-file KV (default)
- graphiti — graph-as-metadata
- khoj — embedded `pgserver` for laptop self-host
- graphrag — Parquet-on-pluggable-blob
- onyx — schema-per-tenant Alembic
- MaxKB — `django-mptt` hierarchical folders
- memvid — single `.mv2` file
- WeKnora — DuckDB for `data_analysis` tool
- OpenViking — virtual filesystem (`ragfs` Rust crate) with 7 backend plugins
- letta — ClickHouse for OTEL / provider tracing (cohort first)
- FalkorDB — Redis as primary state (new infra-layer pattern: graph-DB-on-Redis)

### Markdown filesystem (KB substrate)

| Pattern | Used by | Notes |
|---|---|---|
| Markdown vault as source-of-truth + derived DB index | basic-memory | `.md` files in a folder are the SoT; SQLite (default) or Postgres + sqlite-vec + fastembed indexes them; bidirectional file ↔ DB sync via `watchfiles` |
| Pure Markdown vault, no DB | claude-obsidian | Obsidian vault (`wiki/` + `.raw/` + `.vault-meta/`) with git auto-commits on every wiki write |
| Markdown KB (`.md` + YAML frontmatter) alongside Postgres app data | OpenHands | `.openhands/microagents/*.md` with `triggers:` frontmatter loaded by `KeywordTrigger` / `TaskTrigger`; Postgres holds app state separately |
| Markdown rules files (no DB, no extraction) | cline | `.clinerules/*.md` (project rules) + `@file:lines` mentions per-message; ContextManager keeps full edit history for replay |

**Why this is its own substrate, not just "no-DB":** Markdown files are *human-editable + git-friendly* — readers and agents update the same artifacts. The 4 entries above all let humans drop into the same files the agent reads/writes; that bidirectional ergonomic is what distinguishes Markdown from JSON-blob storage (Understand-Anything, byterover-cli, memvid).

### Cache / queue

| Component | Used by | % | Trade-offs |
|---|---|---|---|
| Redis / Valkey | ragflow, FastGPT, cognee, OpenHands, LightRAG, onyx, MaxKB, WeKnora | 27% | ubiquitous, adds another service |

**Singletons** (1 repo only):

- graphrag — file-backed pipeline cache
- AstrBot — in-process BM25 cache
- onyx — dedicated Celery worker fleet
- MaxKB — APScheduler memory triggers
- memvid — embedded WAL inside `.mv2`
- WeKnora — `hibiken/asynq` Go-native job queue + `panjf2000/ants` goroutine pool
- Understand-Anything — `PostToolUse` hook on git commits + `SessionStart` staleness check via `.understand-anything/meta.json:gitCommitHash` vs `git rev-parse HEAD`

### Blob + Embedder

**Blob storage**

| Backend | Used by | % |
|---|---|---|
| S3-compatible | ragflow, FastGPT, OpenHands, onyx, WeKnora | 17% |
| MinIO (explicit) | ragflow, FastGPT, onyx, WeKnora | 13% |

**Singletons / notable:**

- Azure Blob Storage — graphrag
- 6-backend blob factory (COS / OSS / TOS / MinIO / S3 / local) — WeKnora

**Embedders**

| Pattern | Used by | % |
|---|---|---|
| sentence-transformers local (bi-encoder + cross-encoder) | ragflow, mem0, graphiti, khoj, onyx, MaxKB, WeKnora | 23% |
| fastembed local ONNX | cognee, basic-memory | 7% |

**Singletons / notable:**

- ONNX + CLIP + Whisper with shipped mel-filterbank bytes — memvid
- Embeddings stored as `number[]` arrays directly on graph-node JSON records + 15-line vanilla-JS cosine similarity — Understand-Anything

## Adoption — Ingestion / Extraction

**LLM-based entity / fact extraction is the cohort default at 67%**, but mechanical (non-LLM) extraction is a real counter-current — basic-memory, aider, memvid, and code-review-graph all ship serviceable KBs without any LLM cost. The cohort splits roughly evenly between "agent ingests documents" (50%) and "agent ingests conversations / sessions" (50%), with tree-sitter-based code awareness as the most common specialized track.

| Pattern | Used by | % | Trade-offs |
|---|---|---|---|
| LLM-based entity / fact extraction | ragflow, mem0, graphiti, cognee, claude-mem, LightRAG, khoj, graphrag, onyx, MaxKB, WeKnora, Understand-Anything, MemOS, byterover-cli, deer-flow, haystack, OpenViking, deepwiki-open, memU, claude-obsidian (Claude reads source → extracts entities/concepts → wikilinked Obsidian Markdown pages) | 67% | quality high, cost scales with corpus / turns |
| Document inputs (PDF / DOCX / MD …) | ragflow, FastGPT, cognee, basic-memory, LightRAG, khoj, graphrag, AstrBot, onyx, MaxKB, memvid, WeKnora, haystack, OpenViking, letta | 50% | broad source coverage, may need OCR/layout |
| Per-format / specialized chunking | ragflow, FastGPT, cognee, graphrag, AstrBot, onyx, MaxKB, memvid, WeKnora, Understand-Anything, haystack | 37% | strong on document variety, more code surface |
| Conversation / episode / session inputs | ragflow, mem0, graphiti, cognee, OpenHands, claude-mem, khoj, MaxKB, WeKnora, MemOS, byterover-cli, deer-flow, OpenViking, letta, memU | 50% | hands-off DX for agent memory |
| Tree-sitter for code awareness | claude-mem, cline, aider, Understand-Anything, code-review-graph (32 languages incl. Vue SFC, Solidity, Dart, R, Perl, Lua, Jupyter / Databricks notebooks) | 17% | language-aware extraction |
| Hand-curated markdown KB (rules / notes / microagents) | basic-memory, OpenHands, cline | 11% | git-friendly, debuggable |
| Mechanical (non-LLM) extraction at build time + LLM at query time | basic-memory, aider, memvid, code-review-graph (tree-sitter parses produce all structural nodes; LLM is only invoked at query time, not extraction) | 14% | predictable, free, deterministic; misses semantic nuance |

**Singletons** (1 repo only):

- ragflow — deepdoc OCR
- FastGPT — doc2x/textin OCR
- graphiti — Pydantic-typed entity schemas + gliner2
- cognee — rdflib/OWL ontologies + memify
- basic-memory — rule-based grammar
- OpenHands — trigger-based skill activation
- claude-mem — lifecycle-hook compression
- cline — `@file` mention + ContextManager
- aider — PageRank-weighted tree-sitter tags
- khoj — "Muninn" memory-manager prompt + 8 native source adapters
- graphrag — custom `<\|>`-tuple delimiter + Hierarchical Leiden
- AstrBot — LLM "text repair" prompt + 8 IM platforms
- onyx — 49 SaaS connectors + federated retrieval
- MaxKB — 4-category long-term memory
- memvid — 7-kind `MemoryCard` + Logic-Mesh + PII masking + ed25519
- WeKnora — PaddleOCR + step-graph chat pipeline + Auto-Wiki + 7 IM platforms
- Understand-Anything — 9 specialist agents writing to disk + Zod-validated 35-edge schema
- MemOS — `mem_reader/` with multi-modal/skill/preference reads + tree-text-memory + scheduler with analyzer/monitors/ORM
- byterover-cli:
  - **24 prompt-as-tool files** spanning shell/code execution (`bash_exec` / `code_exec`), curation (`curate` / `expand_knowledge` / `detect_domains`), swarm memory (`swarm_query` / `swarm_store` / `search_history`), memory CRUD (read / write / edit / delete / list), todos (read / write), knowledge topics (create / expand / search), and file ops (glob / grep / file)
  - **Curate workflow** with explicit approve/reject pending-changes review

## Adoption — Retrieval

**Hybrid BM25 + dense is the floor (43%)** — the cohort's baseline retrieval shape; graph-traversal retrieval reaches 40% as graphRAG patterns mature. Reranker adoption splits along open-source vs cloud-API lines: HuggingFace cross-encoders (30%) lead self-host stacks, while pluggable rerank-provider abstractions (27%) trade depth for vendor flexibility.

| Component | Used by | % | Trade-offs |
|---|---|---|---|
| Hybrid BM25 + dense | ragflow, mem0, FastGPT, graphiti, basic-memory, claude-mem, AstrBot, onyx, MaxKB, memvid, WeKnora, haystack, code-review-graph (FTS5 keyword + optional sentence-transformers/Gemini/MiniMax embeddings) | 43% | text-search floor; khoj/cognee/graphrag use vector / vector+graph instead |
| Graph-traversal retrieval (incl. BFS / directory-recursive / multi-hop) | ragflow, mem0, graphiti, cognee, basic-memory, graphrag, memvid, WeKnora, Understand-Anything, MemOS, OpenViking, code-review-graph (BFS impact analysis + Leiden communities) | 40% | richer multi-hop |
| HuggingFace / sentence-transformer reranker | ragflow, mem0, graphiti, khoj, onyx, MaxKB, WeKnora, MemOS, haystack | 30% | self-host friendly, slower than API |
| Pluggable rerank-provider abstraction (vendor-agnostic) | ragflow, mem0, FastGPT, AstrBot, onyx, MaxKB, WeKnora, haystack | 27% | one config knob covers many backends; trades depth for breadth |
| Cohere reranker (explicit) | ragflow, mem0, onyx, MaxKB | 14% | strong default, paid API |
| BGE reranker (explicit) | mem0, graphiti | 7% | open-weight strong reranker |
| LLM-as-reranker | mem0, graphiti | 7% | great quality, latency-heavy |

**Singletons** (1 repo only):

- ragflow — 20 reranker backend classes (largest in cohort) + RAPTOR
- graphiti — pre-baked recipes
- cognee — schema-aware retrieval
- basic-memory — FTS + sqlite-vec
- OpenHands — trigger-based skill activation
- claude-mem — HTTP `/search`
- cline — `@`-mention
- aider — PageRank repo-map
- khoj — two-tier retrieval on single Postgres
- graphrag — four named search modes
- AstrBot — RRF k=60
- onyx — time-decay + Deep-Research orchestrator
- MaxKB — LangGraph + `deepagents`
- memvid — time-travel queries + replay engine
- WeKnora — step-graph chat pipeline + Auto-Wiki
- Understand-Anything — cosine-only + node-and-neighborhood scoping
- MemOS:
  - `mem_agent/deepsearch_agent.py` — agent-driven multi-step retrieval (third cohort entry naming this; cf. onyx Deep Research, graphrag DRIFT)
  - **Tree-text-memory hierarchical retrieval** — splits `organize/` (write-time) vs `retrieve/` (read-time)
  - Preference-text-memory dedicated retrievers

## Adoption — Memory model

**Self-update on every input dominates (63%)**, with auto-structured memory close behind (53%) — the cohort default is "always-fresh, write-amplification". Cross-session memory is universal in memory-frameworks but absent in 6 cohort repos (cline, aider, graphrag, haystack, deepwiki-open, code-review-graph) that treat each session as cold.

| Pattern | Used by | % | Trade-offs |
|---|---|---|---|
| Self-update on each input | ragflow, mem0, graphiti, cognee, basic-memory, claude-mem, khoj, onyx, MaxKB, WeKnora, Understand-Anything, MemOS, byterover-cli, deer-flow, OpenViking, letta, code-review-graph, memU, claude-obsidian (4-event hooks: SessionStart / PostCompact / PostToolUse[Write\|Edit] / Stop, with hot-cache rewrite + git auto-commit) | 63% | always-fresh, write-amplification |
| Auto-structured memory from inputs | ragflow, mem0, graphiti, cognee, basic-memory, claude-mem, khoj, onyx, MaxKB, memvid, Understand-Anything, MemOS, deer-flow, OpenViking, letta, memU | 53% | hands-off DX |
| Hand-authored rules / skill / microagent files | basic-memory, OpenHands, cline, AstrBot, WeKnora, Understand-Anything, byterover-cli, deer-flow, claude-obsidian (11 SKILL.md files following Claude Code's plugin spec) | 30% | git-friendly, predictable; doesn't scale without curation |
| AGPL-3.0-or-later license | basic-memory, OpenHands, claude-mem, khoj, AstrBot, OpenViking | 20% | aggressive copyleft; ship-to-end-user pattern |
| Two-tier KB + agent-memory split | ragflow, khoj | 7% | per-corpus retrieval separated from per-user memory |
| Human-in-the-loop policy/strategy/interface as a typed framework subsystem | byterover-cli (curate workflow), haystack | 7% | rare in cohort; haystack ships the most explicit HITL primitives |
| No cross-session memory at all | cline, aider, graphrag, haystack, deepwiki-open, code-review-graph | 20% | session-cold each time; users supply context explicitly |
| Temporal awareness in memory | graphiti, cognee, memvid | 10% | enables "as-of-date" queries; complex to implement |

**Singletons** (1 repo only):

- FastGPT — KB-as-the-only-memory layer
- mem0 — single flat fact tier
- graphiti — bi-temporal `valid_at`/`invalid_at`/`expired_at`/`created_at` (4 fields per `EntityEdge`)
- cognee — RDF/OWL ontology + memify
- ragflow — `forgetting_policy` per namespace
- basic-memory — files-as-source-of-truth
- OpenHands — append-only event log
- claude-mem — lifecycle-hook ingestion + privacy tags
- cline — `@`-mention + git-checkpoint
- aider — PageRank-weighted repo-map
- khoj — delete-then-create atomic-fact model
- graphrag — hierarchical-Leiden community summaries
- AstrBot — four parallel memory tiers
- onyx — `Persona` + Deep-Research state machine
- MaxKB — 4-category long-term memory + APScheduler
- memvid — immutable append-only frames + signed/encrypted capsules
- WeKnora — token-threshold consolidator + Auto-Wiki
- Understand-Anything — `FingerprintStore` + `.understand-anything/intermediate/`
- MemOS — three explicit memory tiers (KV-cache + LoRA + textual) + MemCube + Multi-MemCube
- byterover-cli:
  - **7-backend memory router** in `PROVIDER_TYPES` enum (`byterover` / `honcho` / `hindsight` / `obsidian` / `local-markdown` / `gbrain` / `memory-wiki`) — 4 local + 3 cloud
  - `QueryType` classifier (`factual` / `personal` / `relational` / `temporal`) routes via `ProviderCapabilities` + `isLocalProvider` / `isCloudProvider` gating
  - **Git-like context tree separate from memory** (`children-hash` / `derived-artifact` / `propagate-summaries` / `snapshot-diff`)
  - **ELv2 (Elastic License 2.0)** — cohort-first non-AGPL/MIT/Apache copyleft
  - `hindsight` and `gbrain` as backend slots suggest pre-release ecosystem partnerships

## Adoption — MCP / connectors

**MCP is near-universal among production-shaped repos** — 60% expose servers, 57% are clients, with 30% staying protocol-neutral. **SDK choice splits cleanly along language lines:** FastMCP dominates Python stacks, `@modelcontextprotocol/sdk` dominates TypeScript/Bun stacks. The "no MCP" camp is structurally distinct — every entry is a library, pipeline, plugin, or infra-class repo, not a deployable product.

### Role type

| Role | Used by | % | Trade-offs |
|---|---|---|---|
| MCP server exposed | ragflow, mem0, FastGPT, graphiti, cognee, basic-memory, OpenHands, claude-mem, onyx, MaxKB, WeKnora, MemOS, byterover-cli, deer-flow, haystack, OpenViking, letta, code-review-graph | 60% | drop-in for Claude Code / Cursor / Codex / Desktop |
| MCP client used | ragflow, mem0, FastGPT, cognee, OpenHands, claude-mem, cline, khoj, AstrBot, onyx, MaxKB, WeKnora, byterover-cli, deer-flow, haystack, OpenViking, letta | 57% | outbound tool use; near-universal among production-shaped repos |
| No MCP at all | aider, LightRAG, graphrag, memvid, Understand-Anything, FalkorDB, deepwiki-open, memU, claude-obsidian | 30% | library/pipeline/plugin/infra-class — intentionally protocol-neutral; claude-obsidian uses Claude Code's native skill/agent/hook surface instead |

### SDK / framework

| SDK | Used by | % | Trade-offs |
|---|---|---|---|
| **FastMCP** (Python, Pydantic-backed) | OpenHands, basic-memory, MaxKB, MemOS, onyx, DocsGPT, code-review-graph, hindsight | 17% | dominant Python MCP SDK in cohort |
| **`@modelcontextprotocol/sdk`** (TS/JS) | claude-mem, cline, FastGPT, sim, byterover-cli, context-mode, honcho | 15% | dominant TS/Bun MCP SDK in cohort |
| **PydanticAI** agent runtime | mindsdb, hindsight | 4% | typed sub-agents + output validation; cohort-novel "Pydantic-shaped Python agentic stack" |

**SDK singletons:**

- WeKnora — vanilla `mcp.server.stdio` Python SDK (separate `mcp-server/` project) + `mark3labs/mcp-go` (Go client) — cohort's only Go MCP user
- MaxKB — uniquely **runtime-synthesizes FastMCP per user-authored Python tool** via `ast` rewriting (every tool gets its own ad-hoc `FastMCP(uuid)` module)

### Distribution / install targets

| Mechanism | Used by | % | Notes |
|---|---|---|---|
| Auto-install MCP config into N AI coding tools (one command) | code-review-graph (11 tools), context-mode (12 adapters + 14 configs), byterover-cli (22+ agents), GitNexus | 9% | growing cohort meta-pattern — "stop telling users to edit JSON manually" |
| ClawHub Skill marketplace | WeKnora, DeepTutor | 4% | CN-ecosystem distribution channel |
| Per-IDE skill markdown bundles | graphify (11 per-IDE `skill-*.md` files) | 2% | (singleton) — Claude Code base + 10 sibling-IDE variants in one package |
| Smithery MCP catalog | basic-memory | 2% | (singleton) — MCP-server registry distribution |

### Per-repo connector / harness highlights

- ragflow — broad native-connector catalogue
- mem0 — plugin lifecycle hooks; MCP server in 3 flavors
- FastGPT — MCP-servers-as-DB-resources schema
- graphiti — MCP server only (no client)
- cognee — `cognee/skill.md` Claude-Skills bundle
- OpenHands — GitHub/GitLab/Bitbucket + browsergym + sandboxed runtime
- claude-mem — stdio-MCP + 8 bundled skills
- cline — McpHub + OAuth + StreamableHttp
- khoj — per-user `McpServer` + 8 native source adapters + e2b sandbox
- AstrBot — 8 IM-platform adapters + Docker sandbox + `SKILL.md` skills (MCP client only)
- onyx — 49 SaaS connectors + federated retrieval + ACP "Build" sandbox
- WeKnora — ~27 agent tools + 7 IM platforms + 3 KB connectors (Feishu / Notion / Yuque)
- Understand-Anything — `.claude-plugin/plugin.json` + 8 slash-commands + 9 agents + 2 hooks (no MCP)
- MemOS — 4 first-party apps shipped (cloud-and-self-hosted-plugin-pair pattern); hookable plugin system with typed hook-spec registry

## Adoption — Observability / Eval

**Production agentic stacks default to LLM-tracing-and-metrics tools (Langfuse + OpenTelemetry + Prometheus + Sentry) rather than RAG-specific eval frameworks.** The legacy "RAG evaluation" reference set (RAGAS, Phoenix/Arize, Inspect AI, Promptfoo, TruLens) is conspicuously absent — surveyed cohort entries either ship in-tree benchmark harnesses or skip formal eval entirely.

| Tool | Used by | % | Trade-offs |
|---|---|---|---|
| Langfuse | deer-flow, mindsdb, cognee, honcho, OpenViking, Yuxi | 13% | open self-hostable LLM tracing + eval; OpenTelemetry-compatible; cohort's most-adopted observability tool |
| OpenTelemetry / OTEL | OpenHands, graphiti, hindsight, letta | 9% | vendor-neutral tracing standard; pairs with any backend (Langfuse / Jaeger / Honeycomb / Datadog) |
| Prometheus | MemOS, mindsdb, honcho, hindsight | 9% | standard metrics export; cohort default for system-level metrics |
| Sentry | honcho, onyx, cognee | 7% | error tracking; cohort default for app-level exceptions |
| LangSmith | deer-flow, OpenViking | 4% | LangChain's hosted tracing/eval; SaaS-only |
| PostHog | haystack, cognee | 4% | product analytics + opt-in usage telemetry |

**Singletons** (1 repo only):

- DeepEval — cognee (only cohort entry shipping a third-party eval framework)
- CloudEvents — honcho (event-interop standard)

**In-tree eval harnesses** — instead of pulling in external frameworks, several cohort entries ship their own benchmark/eval code:

- MemOS — [`evaluation/`](https://github.com/MemTensor/MemOS/tree/main/evaluation) directory with LoCoMo / LongMemEval / PrefEval; paper claims +43.70% vs OpenAI Memory
- fast-graphrag — `benchmarks/questions/2wikimultihopqa_*.json` + `benchmarks/results/{lightrag,nano,graph,vdb}/` for cost comparison ($0.08 vs $0.48 vs microsoft/graphrag)
- haystack — built-in RAG quality metrics in the `evaluation/` package (faithfulness, groundedness, answer correctness)

**Notably absent from cohort** — RAGAS, Phoenix/Arize, Inspect AI, Promptfoo, TruLens, Helicone, AgentOps appear in **zero** surveyed repos. They're well-known reference tools, but production agentic stacks haven't adopted them yet — implying either (a) the eval-framework category is still pre-consolidation, or (b) production teams build eval into CI rather than running a separate framework.

## Patterns observed

These are cohort-wide patterns the surveys surfaced. Each top-level bullet leads with the one-line takeaway; sub-bullets give the supporting evidence and edge cases.

### Storage and licensing

- **MCP server adoption (60%) edges out client (57%).** Server in 18/30 repos, client in 17.
  - Nine repos run no MCP at all: aider, LightRAG, graphrag, memvid, Understand-Anything, FalkorDB, deepwiki-open, memU, claude-obsidian.
  - Common shape: all are libraries, pipelines, plugins, or infra-class.
  - **Pattern hardening:** products run MCP; libraries / plugins / pipelines don't.
  - anything-llm surfaces a 3rd MCP role — *host* — distinct from server and client (see "MCP role types" below).

- **Postgres dominates metadata; pgvector leads vector backends; "no DB at all" is now its own camp.**
  - Numbers: Postgres 14/30 (47%), SQLite 10/30 (33%), pgvector 7/30 (23%), OpenSearch 6/30 (20%).
  - **No-DB camp (5 repos)** — five different shapes, all opt out of databases entirely:
    - cline — `~/.cline/data/*.json` per-user atomic file stores
    - memvid — single `.mv2` binary file
    - Understand-Anything — `.understand-anything/{knowledge-graph,meta,fingerprints,config}.json`
    - byterover-cli — `.brv/` git-like tree
    - claude-obsidian — Obsidian Markdown vault with git auto-commits
  - **Single-DB camp:** khoj, MaxKB, onyx (non-vector), graphrag (Parquet-only).
  - **Polyglot camp:** WeKnora (7 vector × 6 blob), mem0 (24 vector backends).

- **Workload shape predicts vector-backend choice; deployment shape predicts the storage envelope.**
  - ChromaDB → memory frameworks
  - Faiss → chatbot frameworks
  - LanceDB → graph-pipeline tools
  - OpenSearch + pgvector → enterprise kb-apps
  - HNSW-in-a-file → portable-memory libraries

- **License-shape predicts deployment-shape almost perfectly.** As repos shift from "library you import" → "deployable product" → "infrastructure other products consume", licenses harden from permissive to anti-cloud-hosting copyleft.
  - **9 license tiers visible** in the cohort (most → least restrictive):
    - PolyForm Noncommercial 1.0.0 (GitNexus) — most restrictive; commercial requires explicit license
    - SSPL (FalkorDB) — Server Side Public License; restricts hosting providers
    - ELv2 (byterover-cli, mindsdb, context-mode) — Elastic License 2.0; first 3-entry cluster
    - AGPL-3.0 (basic-memory, OpenHands, claude-mem, khoj, AstrBot, honcho, OpenViking)
    - GPL-3.0 (MaxKB)
    - APL + BSL 1.1 + MEL triple-license (memgraph) — most layered cohort license stack
    - MIT-with-enterprise-bolt-on (onyx `ee/`, sim `apps/sim/ee/`)
    - Apache-with-SaaS-restriction ("FastGPT Open Source License")
    - Permissive Apache-2.0 / MIT — everyone else
  - **AGPL is the dominant "deployable memory framework" license** (≥7 entries).
  - **ELv2 cluster** spans 3 substrate types: memory-router (byterover-cli), federated-data-engine (mindsdb), context-engineering-MCP (context-mode). Pattern: **"MCP-shaped infra-layer agent tools wanting to block hosted-SaaS competitors"**.

### Memory model

- **Memory update triggers now have 7 modes** — each picks a different "when to consolidate" point on the spectrum.
  - *Write-through on every input* — mem0, graphiti, cognee, basic-memory, claude-mem, khoj
  - *Batch via background worker* — onyx, ragflow
  - *User-configurable schedule* — MaxKB (cron / interval / every-N-hours / daily / weekly / monthly via APScheduler)
  - *Threshold-triggered* — WeKnora (0.5 × context-window with 3-retry + raw-archive fallback)
  - *Explicit-commit boundary* — memvid (append-only frames)
  - *Token-pressure waterfall + composable blocks* — llama_index (FIFO queue ejecting into ordered `BaseMemoryBlock`s)
  - *Scheduled consolidation agent* — honcho's Dreamer (deduction + induction specialists explore the observation space on a cron, optionally seeded by surprisal-sampled anomalies)

- **Structured-memory taxonomies are converging on small fixed enums (3–7 categories), but split across 3 orthogonal axes.**
  - *Facts/topics taxonomies* (largest camp at the schema layer) — MaxKB's 4-category (`偏好/背景/约定/目标`), graphiti's 4-tier (saga/episodic/community/entity), memvid's 7-kind MemoryCard.
  - *Cross-modality* (MemOS) — `ActivationMemory` (KV-cache) / `ParametricMemory` (LoRA) / `TextualMemory` (traditional). Types across KV-cache vs weights vs text.
  - *Cognitive-process* (hindsight + honcho) — separates what was observed from what was inferred:
    - hindsight types at the *memory-tier* layer: World facts / Experience facts / Mental models
    - honcho types at the *observation* layer: `explicit` / `deductive` / `inductive` (`DocumentLevel` enum)
  - Most repos converge on 4–6 categories of textual facts; MemOS + hindsight + honcho point to research directions the others haven't followed.

### Skills, wikis, and routers

- **`SKILL.md` is the de-facto skill-file standard — now ≥11 cohort entries.** Convergent design across Bun / Python / TypeScript / Go / multi-stack repos. Loaders differ on when to load full bodies (eager vs progressive-disclosure vs on-demand).
  - **Three sub-patterns** ship across the cohort:
    - *User-facing skills* — claude-mem (8), Understand-Anything (8), claude-obsidian (11), deer-flow (21), DeepTutor (14)
    - *Project-meta skills* — sim (14 self-modifying skills targeting *the project itself*), honcho (4 incl. version-migration helpers)
    - *Per-IDE skill bundles* — graphify (11 markdown files: `skill.md` + 10 sibling per-IDE variants)
  - **Four delivery modes** for the same primitive:
    - Bundled + exposed as MCP — claude-mem
    - Trigger-fired markdown — OpenHands `triggers:` frontmatter
    - Progressive-disclosure plugin bundle — cognee, claude-obsidian, Understand-Anything, deer-flow
    - Docker-sandbox-mount — AstrBot (skills mounted into the sandbox FS), WeKnora (preloaded SKILL.md registry)

- **Wiki-compiler hardened into a 6-repo cohort category.**
  - Members: Understand-Anything, deepwiki-open, code-review-graph, claude-obsidian, graphify, GitNexus.
  - WeKnora's Auto-Wiki overlaps on *output* (kb-app inner feature); microsoft/graphrag overlaps on *technique* (entity-extraction-as-graph) — both distinct from the dedicated wiki-compiler shape.
  - Camp ≥3 entries enables intra-camp comparison; see surveyed entries for graphify and GitNexus's distinct contributions.

- **Three distinct shapes for "graphrag" as a category** — all share LLM-extracted entities + relationships, but disagree on whether the KB is a service, an artifact, or a process-local object:
  - *Service-shaped* (LightRAG) — long-running FastAPI server + WebUI; 4 storage abstractions × 13 swappable backend impls; 6 named retrieval modes (`local` / `global` / `hybrid` / `mix` / `naive` / `bypass`) as HTTP endpoints.
  - *Pipeline-shaped* (microsoft/graphrag) — CLI + Parquet outputs; in-memory NetworkX graph; the "system" is your filesystem after `graphrag index`.
  - *Library-shaped* (fast-graphrag) — single import (`from fast_graphrag import GraphRAG`), pickle-only persistence in one `working_dir/`. Personalized PageRank from query-entity reset distribution drives retrieval directly.

- **Router-as-product is now a recognized cohort-wide pattern at the harness/infra layer.** Originally surfaced with byterover-cli (memory-router-as-product, 7 backends behind `swarm_query` / `swarm_store`); now hardens to **4 substrate types**:
  - Memory routing — byterover-cli (7 backends)
  - Tool / MCP routing — anything-llm host + Composio per-user sessions
  - Workflow routing — sim's persisted-workflow-as-MCP
  - Data-source routing — mindsdb federated SQL

- **Infra-layer is a 3-entry cohort category, each with a distinct shape.** Surveying these as peers (rather than transitive deps) clarifies the trade space.
  - *Graph-DB as Redis module* — FalkorDB (Cypher-on-Redis via GraphBLAS sparse matrices)
  - *Graph-DB as standalone server* — memgraph (in-memory C++ + NuRaft HA + Tantivy text + USearch vector)
  - *Federated query engine* — mindsdb (federated SQL + 34 in-tree handlers + A2A protocol + most-complete-MCP)

### Coding-agent KBs

- **Coding-agent KBs split into FOUR distinct camps** — complementary, not competing. They answer "where does the agent get its context?" with extract-and-recall vs hand-author vs user-mention vs compute-on-the-fly.
  - *Extracting* — claude-mem; lifecycle hooks → LLM extracts → SQLite + ChromaDB → semantic search.
  - *Trigger-based* — OpenHands; `.openhands/microagents/*.md` with `triggers: [keywords]`; hand-authored, no extraction.
  - *Mention-based* — cline; `.clinerules/*.md` (rules) + `@file:lines` mentions per-message; no recall, no extraction.
  - *Computed / repo-map* — aider; PageRank-weighted symbol selection from tree-sitter parses; no LLM extraction, no MCP, no cross-session memory.

- **Mechanical (non-LLM) extraction works** — useful counter-example to the "more LLM = more quality" assumption. **4/30 cohort entries** ship serviceable KBs without LLM cost:
  - basic-memory — grammar-based observation parser
  - aider — tree-sitter PageRank
  - memvid — `Rules` extraction mode (default)
  - code-review-graph — tree-sitter → graph

- **The actual KB code may not live in the named repo.** OpenHands pins `openhands-sdk==1.19.1` as a separate package — when a "trending coding-agent repo" depends on a versioned SDK, the SDK is where the retrieval/memory primitives are. Reader/curator note: **follow the SDK pin**.

### MCP maturity

- **MCP role types have grown from 2 → 6: server / client / *host* / *edge-worker* / *persisted-workflow-as-server* / *per-user-isolated-session*.** Initial framing was binary; five cohort-novel roles emerged:
  - *MCP host* (anything-llm) — `MCPCompatibilityLayer extends MCPHypervisor` boots N external MCP servers under one process and converts each server's tools into native agent-runtime plugins. Neither exposes nor consumes MCP — it **mounts** N servers as in-process tool sources.
  - *MCP edge-worker* (honcho) — MCP shipped as a separate Cloudflare Worker package, deployed independently from the FastAPI core, decoupling MCP scaling from the API server.
  - *Persisted-workflow-as-MCP-server* (sim) — `workflow-mcp-sync.ts` keeps `workflowMcpServer` + `workflowMcpTool` Drizzle tables in sync with deployed workflows; workflows become long-lived MCP servers addressable by any client. Distinct from llama_index's per-call `workflow_as_mcp` helper.
  - *Per-user-isolated-MCP-session-as-service* (Composio) — `composio.experimental.create(userId, {toolkits, manageConnections})` returns an MCP URL scoped to that `(userId × toolkit-set)` tuple. Combined with `AuthConfigs` + `AuthScheme` + `ConnectedAccounts` to deliver **auth-as-service for tools at scale** across 1000+ services.

- **Production-quality MCP integration now requires four things, not just "point an SDK at it".**
  - *Protocol-version negotiation* — sim's `client.ts` negotiates 3 versions (`2025-06-18` / `2025-03-26` / `2024-11-05`).
  - *Security / consent UX hooks* — sim ships custom `McpSecurityPolicy` + `McpConsentRequest`/`McpConsentResponse` + pre-call `validateMcpDomain` + `validateMcpServerSsrf` SSRF guards.
  - *Capability completeness* — mindsdb is the only cohort entry shipping the full MCP stack: tools + prompts + resources + completions + OAuth + dual SSE/Streamable-HTTP transport.
  - *Per-tenant isolation* — Composio's per-user × per-toolkit-set MCP URLs.
  - hindsight adds a FastMCP 2.x AND 3.x compat layer — cohort-first dual-API-version handling.

- **"Deep research" is becoming a recognized cohort capability tier**, separate from "tool-calling agent" and "RAG over docs". Pattern signature: multi-turn iterative search + intermediate planning step + final synthesis (often via a separate writing/reporting sub-agent).
  - **5 explicit + 2 implicit = 7 cohort entries** with a long-horizon-research workflow primitive:
    - deer-flow — `deep-research` skill in `skills/public/`
    - basic-memory — `deep_research` mode
    - DeepTutor — `deep_research` capability + Plan→ReAct→Write `deep_solve` capability
    - Yuxi — `deep-reporter` skill for industry research / scientific reports
    - DocsGPT — `ResearchAgent` as one of 4 agent types
    - onyx — Deep Research orchestrator state machine (implicit)
    - microsoft/graphrag — DRIFT search shape (implicit)

### Cohort meta-patterns

- **Cohort-internal dependencies are starting to resemble inter-project ecosystems.** Yuxi (CN-language kb-app) makes it explicit:
  - *Documented downstream-consumer* — Yuxi's `pyproject.toml` literally names LightRAG as an architecture pillar: `"基于 LangGraph v1 + Vue.js + FastAPI + LightRAG 架构构建"`. Cohort first to officially document a downstream-consumer relationship to another cohort entry as a *headline* pillar (vs. one-of-N adapters per llama_index).
  - *Downstream-fix-loop* — Yuxi's `knowledge/implementations/lightrag.py` adapter carries a fix for [LightRAG #580](https://github.com/HKUDS/LightRAG/issues/580). Cohort first to ship a downstream consumer that *carries an upstream-bug fix* for another cohort entry.
  - *Naming-as-attribution* — Yuxi's `chunking/ragflow_like/` directory name explicitly credits ragflow's per-format chunker pattern as inspiration.
  - The cohort is starting to look like a **self-aware ecosystem with documented internal dependencies, downstream-fix loops, and explicit cross-attribution naming** — closer to a Linux-distro-package-graph model than a list of isolated projects.

- **Connector taxonomy splits in two — read-into-KB vs OAuth-action.** Initial framing treated "many connectors" as one pattern; SurfSense reveals the split.
  - *Ingest connectors* (flow content INTO the KB): SurfSense (22 indexers — Airtable / BookStack / ClickUp / Confluence / Discord / Dropbox / Elasticsearch / GitHub / GoogleCalendar / GoogleDrive / Gmail / Jira / Linear / Luma / Notion / Obsidian / OneDrive / Slack / Teams / web-crawler), parts of WeKnora's 3 KB connectors.
  - *Action connectors* (flow agent ACTIONS OUT to external services): anything-llm (35), sim (35), mindsdb (34), Composio (1000+).
  - Implication: cohort entries with N>20 connectors should be classified by direction, not just count.

- **mindsdb opens THREE new agent-protocol axes** the rest of the cohort hasn't followed yet:
  - *Google A2A protocol* — `MindsDBAgent` is the cohort's first Agent-to-Agent HTTP client (Google's 2025 inter-agent interop spec). MCP routes tool calls; A2A routes agent-to-agent messages.
  - *SQL as the agent query language* — `mindsdb-sql-parser` extends SQL with `CREATE KNOWLEDGE_BASE` / `CREATE JOB` / `CREATE TRIGGER` / `CREATE AGENT` / `CREATE CHATBOT` / `CREATE MODEL` DDL. Cohort first to make SQL the user-facing primary interface; further reinforced by a **MySQL wire protocol endpoint** so any MySQL client/driver becomes an agent client.
  - *Most complete MCP capability stack* — see "Production-quality MCP" above.

- **Scheduled-agent-as-subsystem is now a 2-entry cohort pattern** (honcho's Dreamer + DeepTutor's TutorBot). Each is a separate scheduler-driven subsystem within a parent KB system, distinct from request-driven agent loops:
  - *honcho-Dreamer* — runs *consolidation* on the agent's memory; adds surprisal-sampling at the entry.
  - *DeepTutor-TutorBot* — runs *user-facing tutoring tasks*; adds heartbeat for liveness.
  - Both ship their own `cron`-shaped scheduler.

- **Typed contracts at the schema layer** — three cohort entries make schema-level types do load-bearing work:
  - graphify's `EXTRACTED` / `INFERRED` / `AMBIGUOUS` edge confidence (`AMBIGUOUS` flagged for human review in `GRAPH_REPORT.md` — cohort first explicit human-review surface for graph quality)
  - honcho's `explicit` / `deductive` / `inductive` `DocumentLevel`
  - DeepTutor's typed `stages: list[str]` in `CapabilityManifest`

- **Single-query atomic retrieval is a cohort-novel architectural axis** — whether retrieval pipelines run as N-system-orchestrated or 1-system-atomic. memgraph picks the latter, bundling Tantivy (full-text) + USearch (vector) + property-graph indexes co-located in the same database, queryable via a single Cypher statement. FalkorDB picks "1-Redis-instance, multi-module" (text + vector inside Redis but routed through separate modules); everyone else picks N-system orchestration. memgraph also ships **9 formal ADRs** in `ADRs/` — cohort-first formal architecture-decision practice.

- **Framework-as-aggregator is a 4th category** beyond library / service / plugin — value proposition is integration breadth, not a novel memory model.
  - *Hub-and-spoke at extreme scale* — llama_index ships **571 separately versioned integration packages** under `llama-index-integrations/` (78 vector / 104 LLM / 159 reader / 68 tool / 26 reranker / 7 graph / 9 index / 14 retriever / 66 embedder).
  - *First-party adapters TO cohort members* — `llama-index-graph-rag-cognee` (cognee), `llama-index-memory-mem0` (mem0), `llama-index-graph-stores-falkordb` (FalkorDB) — the framework consumes the rest of the cohort rather than reimplementing it.
  - haystack is the elder-statesman analogue at smaller scale (50+ vector-backend sibling packages + 24 component categories in core).

## Surveyed repos

Per-repo summaries in cohort-table order (highest stars first). Each entry has the headline pitch and 3–5 distinctive bullets; click through to the full survey for the complete report.

### [infiniflow/ragflow](https://github.com/infiniflow/ragflow)
*kb-app · Apache-2.0 · [survey](surveys/infiniflow__ragflow.md)*

Production RAG with deep document understanding.

- Swappable doc engine — Elasticsearch / Infinity / OpenSearch
- Per-format specialized chunkers + `deepdoc` OCR
- In-memory NetworkX GraphRAG; per-tenant agent memory layer kept separate from the KB
- Both MCP server and client; **20 reranker backend classes** (largest in cohort)

### [OpenHands/OpenHands](https://github.com/OpenHands/OpenHands)
*coding-agent · MIT · [survey](surveys/OpenHands__OpenHands.md)*

Production multi-tenant coding-agent orchestrator with sandboxed runtime.

- Postgres + Redis + S3/GCS/local file-store; no vector store in the orchestrator repo
- KB is **`.openhands/microagents/*.md`** with `triggers:` frontmatter + `KeywordTrigger` / `TaskTrigger` loader
- Sandboxed runtime (Docker / k8s)
- The actual agent loop lives in pinned `openhands-sdk==1.19.1` — follow the SDK pin to find the real KB code

### [thedotmack/claude-mem](https://github.com/thedotmack/claude-mem)
*coding-agent · AGPL-3.0 · [survey](surveys/thedotmack__claude-mem.md)*

Claude Code memory plugin that extracts and re-injects context across sessions.

- Hooks **5 lifecycle events** → ships transcripts to a Bun worker on `:37777`
- Uses `@anthropic-ai/claude-agent-sdk` to extract typed observations into SQLite + ChromaDB-via-stdio-MCP
- Bundles 8 skills (mem-search / make-plan / do / pathfinder / smart-explore / timeline-report / knowledge-agent / version-bump)
- Privacy tags + multi-account profiles

### [bytedance/deer-flow](https://github.com/bytedance/deer-flow)
*coding-agent · MIT · [survey](surveys/bytedance__deer-flow.md)*

ByteDance's open-source super agent harness; v2.0 ground-up rewrite topped GitHub Trending #1 on 2026-02-28.

- LangGraph-native (most LangGraph-heavy repo in cohort: 7 langgraph-* packages + 6 langchain-*)
- FastAPI Gateway + Next.js frontend + Nginx + optional Kubernetes provisioner
- `deerflow-harness` Python package as importable substrate (agents / subagents / sandbox / mcp / memory / skills / runtime / community / reflection)
- **21 public skills** in SKILL.md format (deep-research, ppt-generation, podcast-generation, video-generation, skill-creator, …)
- 7 IM channels (DingTalk / Discord / Feishu / Slack / Telegram / WeChat / WeCom)

### [cline/cline](https://github.com/cline/cline)
*coding-agent · Apache-2.0 · [survey](surveys/cline__cline.md)*

VSCode/JetBrains/CLI coding agent — radical "no DB" design.

- **No vector store, no DB, no extraction** — knowledge lives in `.clinerules/*.md` + `@file` mentions + `~/.cline/data/*.json` atomic file stores + git checkpoints
- ContextManager keeps full edit history for replay
- MCP client only — first cohort exception to the universal MCP-server pattern

### [Mintplex-Labs/anything-llm](https://github.com/Mintplex-Labs/anything-llm)
*kb-app · MIT · [survey](surveys/Mintplex-Labs__anything-llm.md)*

Workspace-scoped multi-LLM kb-app + agent + MCP runtime.

- **Largest in-tree provider matrix in cohort:** 37 LLM providers + 14 embedders + 10 vector backends bundled in-tree (vs llama_index's 571 separately versioned packages)
- Custom Aibitat agent runtime (NOT LangChain/LlamaIndex) with 17 built-in plugins; 3 default-enabled
- **MCPHypervisor pattern** — boots multiple MCP servers and converts each server's tools into native Aibitat plugins (`@@mcp_{name}` namespace); cohort's first "MCP host" role
- **Skill-availability gating** — skills disappear from the agent's tool list when their backing system isn't installed (cohort first)
- 6 cloud-deploy targets (AWS / GCP / OpenShift / Helm / k8s / HuggingFace Spaces) — broadest in cohort

### [mem0ai/mem0](https://github.com/mem0ai/mem0)
*memory-framework · Apache-2.0 · [survey](surveys/mem0ai__mem0.md)*

Universal memory layer that ingests conversation messages and auto-extracts atomic facts.

- v3 multi-signal hybrid retrieval (semantic + BM25 + entity matching) scoped by user/agent/run
- **24 vector + 18 LLM + 11 embedder + 5 reranker provider plugins**
- **v3 removed `graph_store`** — entity linking is now built-in (auto-extracted entities used as a retrieval boost)
- Default OSS Docker compose ships only `pgvector` (Neo4j removed in v3)
- Python + TS SDKs; MCP server in three flavors

### [run-llama/llama_index](https://github.com/run-llama/llama_index)
*kb-framework · MIT · [survey](surveys/run-llama__llama_index.md)*

Foundational Python RAG/agent framework — the cohort's "framework-as-aggregator" exemplar.

- **571 separately versioned integration packages** under `llama-index-integrations/` (78 vector / 104 LLM / 66 embedders / 159 readers / 68 tools / 26 rerankers / 7 graph / 9 indices / 14 retrievers) — broadest backend coverage by ~3×
- **Memory = waterfall queue + composable blocks**: FIFO queue (default `token_limit=30000`) waterfalls ejected pressure-windows into ordered `BaseMemoryBlock`s with per-block `priority` knobs
- Two KG primitives ship side-by-side: legacy `KnowledgeGraphIndex` + current `PropertyGraphIndex` with 4 sub-retrievers + 4 transformations
- **Bidirectional MCP via the same primitive** in `llama-index-tools-mcp`: `McpToolSpec` consumes external servers; `workflow_as_mcp` exposes any `Workflow` as one
- First-party adapters for cohort members — `llama-index-graph-rag-cognee` / `llama-index-memory-mem0` / `llama-index-graph-stores-falkordb` / `llama-index-graph-stores-memgraph`

### [Aider-AI/aider](https://github.com/Aider-AI/aider)
*coding-agent · Apache-2.0 · [survey](surveys/Aider-AI__aider.md)*

Terminal pair-programmer — the cohort's purest minimalist coding-agent design.

- KB is a **PageRank-weighted "repo-map" from tree-sitter symbol tags** (30+ languages), cached in `.aider.tags.cache.v4/` (diskcache + SQLite)
- **No LLM extraction, no MCP at all, no cross-session memory** beyond git
- ChatSummary truncates older turns under a token budget
- Voice / clipboard / web-scrape inputs

### [safishamsi/graphify](https://github.com/safishamsi/graphify)
*wiki-compiler · MIT · [survey](surveys/safishamsi__graphify.md)*

Single-author Python library distributed as a Claude Code skill (+10 sibling-IDE bundles); turns code/docs/papers/images/videos into a queryable knowledge graph.

- Linear stateless pipeline — `detect → extract → build_graph → cluster → analyze → report → export`
- **21 tree-sitter language deps** baked in
- **Cohort-first typed edge confidence** — every edge labeled `EXTRACTED` / `INFERRED` / `AMBIGUOUS` (last flagged for human review in `GRAPH_REPORT.md`)
- **Cohort-first polyglot integration-point detection** via 11-language-family `_LANG_FAMILY` table — surfaces FFI bridges and microservice boundaries as "surprising connections"
- 6 export formats from one NetworkX graph (Obsidian / JSON / HTML / SVG / GraphML / Neo4j Cypher)

### [mindsdb/mindsdb](https://github.com/mindsdb/mindsdb)
*infra-layer · ELv2 · [survey](surveys/mindsdb__mindsdb.md)*

Federated SQL query engine — agents query unified data via a single SQL surface, no ETL.

- Custom `mindsdb-sql-parser` extends SQL with `CREATE KNOWLEDGE_BASE` / `CREATE JOB` / `CREATE TRIGGER` / `CREATE AGENT` / `CREATE CHATBOT` / `CREATE MODEL` DDL
- **34 in-tree handlers** (data sources + LLM providers + vector stores + ML); README claims 200+ via external packages
- Cohort-first **MySQL wire protocol endpoint** — any MySQL client/driver becomes an agent client
- Cohort-first **Google A2A protocol** implementation (`MindsDBAgent` HTTP client)
- **Most complete MCP capability stack in cohort** — tools + prompts + resources + completions + OAuth + dual SSE/Streamable-HTTP transport

### [HKUDS/LightRAG](https://github.com/HKUDS/LightRAG)
*graphrag · MIT · [survey](surveys/HKUDS__LightRAG.md)*

EMNLP 2025 GraphRAG library — service-shaped variant of the graphrag pattern.

- **4-storage abstraction** (KV / vector / graph / doc-status) × **13 pluggable backend impls** + 14 LLM bindings
- Default stack: nano-vectordb + NetworkX + JSON files (in-process)
- **6 named retrieval modes** — `local` / `global` / `hybrid` / `mix` / `naive` / `bypass` (cohort-first "skip retrieval" primitive)
- FastAPI server + React 19 WebUI + Ollama-compatible API; no MCP

### [khoj-ai/khoj](https://github.com/khoj-ai/khoj)
*kb-app · AGPL-3.0 · [survey](surveys/khoj-ai__khoj.md)*

Self-hostable personal "second-brain" with a single-Postgres KB stack.

- pgvector backend: `Entry` (chunked docs) + `UserMemory` (atomic facts extracted by an LLM-driven "Muninn" agent)
- `pgserver` extra runs embedded Postgres for laptop self-host
- 8 native source adapters: org-mode (only mainstream agent with org-mode), markdown, PDF, DOCX, plaintext, image, GitHub, Notion
- MCP client (stdio + SSE in one class), no MCP server
- Computer-use operator agent integrated; cross-encoder reranker (`mxbai-rerank-xsmall-v1`)

### [abhigyanpatwari/GitNexus](https://github.com/abhigyanpatwari/GitNexus)
*wiki-compiler · PolyForm Noncommercial 1.0.0 · [survey](surveys/abhigyanpatwari__GitNexus.md)*

"Zero-Server Code Intelligence Engine" — TypeScript monorepo with two deployment shapes from one repo.

- **Dual deployment** — `gitnexus` npm CLI + 22 MCP tools AND `gitnexus-web` Vite browser app that runs entirely client-side via WASM tree-sitter (cohort first browser-side code-KG)
- **11 language extractor configs** — cohort-novel "extractor as config file" pattern (vs per-language code)
- Cohort-first dedicated COBOL processor (legacy-system code-modernization use case)
- Cohort-first **adaptive tree-sitter buffer sizing** (512 KB → 32 MB based on `byteLength × 2`)
- Cohort-first **MCP staleness tracking** + **structured tool descriptions** with `WHEN TO USE / AFTER THIS / situational context` 3-part contract
- Most restrictive cohort license — commercial requires explicit license from akonlabs.com

### [microsoft/graphrag](https://github.com/microsoft/graphrag)
*graphrag · MIT · [survey](surveys/microsoft__graphrag.md)*

Microsoft Research's reference GraphRAG — pipeline-shaped variant; positioned as a "demonstration".

- LLM `GraphExtractor` (custom `<\|>`-tuple delimiters + iterative gleanings) → in-memory NetworkX → Hierarchical Leiden communities → per-community LLM `CommunityReport` summaries → Parquet outputs
- Vector factory: LanceDB (default) / Azure AI Search / Cosmos DB
- Storage factory: file / Azure Blob / Cosmos / memory
- **4 query modes** — Basic / Local / Global (map-reduce) / DRIFT (community-aware iterative)
- **No MCP, no memory, no reranker**; production users typically vendor

### [AstrBotDevs/AstrBot](https://github.com/AstrBotDevs/AstrBot)
*kb-app · AGPL-3.0 + custom EULA · [survey](surveys/AstrBotDevs__AstrBot.md)*

Multi-platform IM chatbot framework with first-party adapters for 8 IM platforms (QQ / WeChat / Feishu / DingTalk / Telegram / Slack / Discord / Lark).

- KB module: SQLite + Faiss (only backend) with hybrid retrieval — dense + jieba-BM25 → RRF (k=60) → optional pluggable reranker
- Per-KB knobs (chunk_size / top_k_dense / top_k_sparse / top_m_final / providers) stored on the row
- **MCP client only** with three transports (stdio + SSE + StreamableHTTP) in one class + allowlist/denylist hardening
- **Skills system mounts SKILL.md files into an `aiodocker` Docker sandbox** at `/workspace/skills/<name>/SKILL.md`
- Distinct memory layers (ConversationManager / PersonaManager / `LongTermMemory` per-group / KB) deliberately decoupled

### [onyx-dot-app/onyx](https://github.com/onyx-dot-app/onyx)
*kb-app · MIT + Onyx EE for `ee/` · [survey](surveys/onyx-dot-app__onyx.md)*

Most enterprise-shaped repo in the cohort (formerly Danswer).

- **49 first-party SaaS connectors** + federated retrieval; hybrid index on Vespa (default) or OpenSearch behind a `DocumentIndex` ABC
- **Postgres-backed knowledge graph** — entities + relationships + typed `KGAttributeImplicationProperty` as SQL tables (no graph DB), populated by a Celery worker
- MCP server (FastMCP + token auth) + MCP client (`claude-agent-sdk` + `agent-client-protocol`) for an ACP-based "Build" sandbox (Local Docker or Kubernetes)
- Multi-tenant via schema-per-tenant Alembic + `get_current_tenant_id()` contextvars
- Deep Research orchestrator state machine; voice + image-gen + 5 web-search providers
- Heavy ops surface (Vespa + Postgres + Redis + Celery + S3 + model_server) — "Onyx Lite" mode for laptop deployments

### [simstudioai/sim](https://github.com/simstudioai/sim)
*kb-app · Apache-2.0 + EE for `apps/sim/ee/` · [survey](surveys/simstudioai__sim.md)*

Bun-managed Next.js 15 + Drizzle workflow platform positioning as "central intelligence layer for AI workforce".

- **Cohort's most sophisticated MCP stack** — negotiates 3 MCP versions with OAuth 2.1 + elicitation; ships custom `McpSecurityPolicy` + consent layer + pre-call `validateMcpDomain` + `validateMcpServerSsrf` SSRF guards
- **`workflow-mcp-sync.ts` deploys workflows AS MCP servers** with DB persistence — cohort first "persisted workflow as MCP server"
- Most decomposed integration set in cohort: 35 connectors / **220 tools** (one `.ts` per tool) / 227 workflow blocks / 17 LLM providers / 7 chunkers / 11 file parsers
- **Cross-language guardrails** (cohort first) — `validate_pii.py` + `validate_pii.ts` coexist + JSON / regex / hallucination validators
- **Self-modifying agent skills** in `.agents/skills/` (14 skills targeting *the project itself*)

### [ComposioHQ/composio](https://github.com/ComposioHQ/composio)
*kb-app · MIT · [survey](surveys/ComposioHQ__composio.md)*

Toolkit-routing-as-service that wraps 1000+ third-party-tool integrations behind one SDK.

- Cohort-first **remote-MCP-session-as-service primitive** — `composio.experimental.create(userId, {toolkits, manageConnections})` returns an MCP URL scoped to that `(userId × toolkit-set)` tuple
- Cohort-first **auth-as-service for tools at scale** — `AuthConfigs` + `AuthScheme` + `ConnectedAccounts` + `ConnectionRequest` make per-user OAuth a first-class abstraction
- 23 provider integrations across TS + Python SDKs; **provider-typed generic tool collections** preserve provider-native types across providers
- Cohort-first explicit Cloudflare-Workers-runtime support at the SDK core level
- Effect.ts + @clack/prompts CLI; pnpm workspaces + changesets

### [labring/FastGPT](https://github.com/labring/FastGPT)
*kb-app · FastGPT Open Source License (Apache + SaaS restriction) · [survey](surveys/labring__FastGPT.md)*

TypeScript-first knowledge-base + visual workflow platform; CJK-first.

- pi-mono agent runtime
- Vector backends: pgvector / Milvus / OceanBase / OpenGauss / SeekDB
- MongoDB metadata + MinIO blobs
- jieba + tiktoken hybrid retrieval
- MCP servers as workflow nodes

### [getzep/graphiti](https://github.com/getzep/graphiti)
*memory-framework · Apache-2.0 · [survey](surveys/getzep__graphiti.md)*

Bi-temporal KG library — only cohort entry that supports "as-of-date" queries.

- Every `EntityEdge` carries 4 temporal fields: `valid_at` / `invalid_at` / `expired_at` / `created_at`
- 4 backends: Neo4j / FalkorDB / Kuzu / Neptune
- Pydantic-typed entities + `gliner2` extraction
- 4-tier schema: `EpisodicNode` / `EntityNode` / `CommunityNode` / `SagaNode`
- **16 pre-baked search recipes** (Combined×3 + Edge×5 + Node×5 + Community×3) over 4 reranker modes (RRF / node-distance / MMR / cross-encoder)

### [deepset-ai/haystack](https://github.com/deepset-ai/haystack)
*kb-app · Apache-2.0 · [survey](surveys/deepset-ai__haystack.md)*

The cohort's elder-statesman framework (created 2019-11).

- **Component-pipeline architecture** — pipelines are NetworkX DAGs of `Component`s connected via typed sockets
- 24 component categories ship in core (agents / audio / builders / classifiers / converters / embedders / evaluators / extractors / generators / joiners / preprocessors / rankers / retrievers / routers / tools / validators / websearch / writers / …)
- Vector backends are **50+ sibling packages**; core ships only `InMemoryDocumentStore` to keep install lean
- Tool model: `Tool` / `ComponentTool` / `PipelineTool` / `from_function` / `Toolset` / `SearchableToolset` (semantic search over tool descriptions)
- **Cohort-first `human_in_the_loop/` package** with policies / strategies / user_interfaces / dataclasses; built-in RAG-quality metrics in `evaluation/`

### [volcengine/OpenViking](https://github.com/volcengine/OpenViking)
*memory-framework · AGPL-3.0 · [survey](surveys/volcengine__OpenViking.md)*

ByteDance Volcengine's "Context Database for AI Agents"; Python + Rust hybrid.

- **Filesystem-paradigm context management** — memories, resources, and skills all live as files in a virtual filesystem (Rust `ragfs` crate with **7 backend plugins**)
- `ContextLevel` enum (L0=ABSTRACT / L1=OVERVIEW / L2=DETAIL) drives on-demand tiered loading — cohort first to type the tier explicitly
- Hierarchical + directory-recursive retrieval combined with semantic search; visualized retrieval trajectory for debugging
- `memory_lifecycle.py` is a first-class memory subsystem (cohort first to name it)
- Heavy CN-cloud tilt — Doubao/Ark models as primary LLM target

### [HKUDS/DeepTutor](https://github.com/HKUDS/DeepTutor)
*kb-app · Apache-2.0 · [survey](surveys/HKUDS__DeepTutor.md)*

Agent-Native Personalized Tutoring from HK Data Science (same lab as LightRAG).

- **6 named capabilities as typed pipelines** — `chat` / `deep_question` / `deep_research` / `deep_solve` (Plan → ReAct → Write) / `math_animator` / `visualize`
- Cohort-first **typed `CapabilityManifest`** with declarative `stages: list[str]`
- Cohort-first **versioned KB indexes with re-index workflow** — embedding-config drift surfaced as a first-class workflow primitive (not silent re-index)
- **TutorBot subsystem** = persistent autonomous AI tutors with `cron/service.py` scheduled execution + `heartbeat/` for liveness; 14 TutorBot skills incl. `skill-creator`, `tmux`
- Cohort-first dedicated `tex_chunker.py` for LaTeX/math chunking; cohort-first dedicated `co_writer/edit_agent.py` for collaborative writing

### [letta-ai/letta](https://github.com/letta-ai/letta)
*memory-framework · Apache-2.0 · [survey](surveys/letta-ai__letta.md)*

The original MemGPT — the research project that gave the cohort its memory-taxonomy lineage.

- **Memory blocks abstraction** — `Block(label, value, limit)` rows where `label ∈ {human, persona, system}` define typed slices of the LLM context with per-block char budgets
- **Archives** are shareable collections of **Passages** (embedded chunks)
- 3 vector backends: `native` (Postgres + pgvector), `tpuf` (Turbopuffer), `pinecone`
- **50 ORM tables** with explicit join tables for everything — most explicitly normalized memory schema in cohort
- **Agent-self-managed memory** — the agent calls `core_memory_*` and `archival_memory_*` tools to update its own state (inverse of mem0's auto-extract)
- 8 agent-loop variants (v1 / v2 / v3 / voice / voice_sleeptime / ephemeral / ephemeral_summary / batch); ClickHouse opt-in for OTEL + provider tracing

### [1Panel-dev/MaxKB](https://github.com/1Panel-dev/MaxKB)
*kb-app · GPL-3.0 · [survey](surveys/1Panel-dev__MaxKB.md)*

"Max Knowledge Brain" enterprise agent platform from FIT2CLOUD; Django 5.2 + Vue + heavy LangChain footprint.

- Single-Postgres-only via pgvector (no other vector backend ships)
- **35+ workflow step nodes** incl. loop_break / loop_continue / intent / parameter_extraction / mcp / image_to_video / video_understand / text_to_speech
- **23 model providers** (CN-cloud-heavy: Aliyun Bailian / Volcengine / Tencent / Wenxin / Zhipu / Qianfan / DeepSeek / Kimi)
- **Long-term memory = 4-category structured schema** (`偏好` / `背景` / `约定` / `目标`) extracted by a 230-line Chinese-language prompt; refreshed via APScheduler
- MCP servers synthesized at runtime from user-authored Python via `ast` rewriting → `@mcp.tool` decorators on a generated `FastMCP(uuid)` module
- First cohort entry on classic GPL (not AGPL)

### [arc53/DocsGPT](https://github.com/arc53/DocsGPT)
*kb-app · MIT · [survey](surveys/arc53__DocsGPT.md)*

Private AI platform for agents + assistants + enterprise search; Flask + Celery + Alembic + React stack.

- **Cohort-first 4-agent-type taxonomy** — `ClassicAgent` (pre-fetch RAG) / `AgenticAgent` (LLM-decides-when-to-search) / `WorkflowAgent` (visual workflows) / `ResearchAgent` (multi-turn deep research)
- **Cohort-first `internal_search` RAG-as-LLM-tool** — RAG becomes one tool among many that the agent calls when needed (vs RAG-as-front-of-pipeline)
- **Cohort-first MCP-bearer-token-reuse** — existing DocsGPT API keys are reused as MCP bearer tokens (no new credential surface)
- 8 vector backends + 15 file parsers incl. **cohort-first `openapi3_parser`** + 19 agent tools
- **CEL workflow evaluator** (cohort first to use Google's Common Expression Language for workflow conditional logic)
- 3 enterprise SaaS connectors (Confluence / GoogleDrive / SharePoint); cohort-first Chatwoot AI-assistant integration

### [topoteretes/cognee](https://github.com/topoteretes/cognee)
*memory-framework · Apache-2.0 · [survey](surveys/topoteretes__cognee.md)*

ECL (Extract / Cognify / Load) memory platform with rdflib/OWL ontologies.

- LanceDB + Kuzu defaults; also Chroma / pgvector / Neo4j / Neptune / Postgres + 2 hybrid stores
- Named **"memify" pipelines** — `consolidate_entity_descriptions` / `apply_feedback_weights` / `persist_sessions_in_knowledge_graph`
- 30+ optional extras including a `graphiti` backend extra
- Ships a `cognee/skill.md` Claude-Skills bundle

### [AsyncFuncAI/deepwiki-open](https://github.com/AsyncFuncAI/deepwiki-open)
*wiki-compiler · MIT · [survey](surveys/AsyncFuncAI__deepwiki-open.md)*

Open-source clone of DeepWiki; turns any GitHub/GitLab/BitBucket repo into an interactive wiki.

- Server-shaped wiki-compiler — RAG-powered "Ask" + multi-turn "DeepResearch" + auto-generated **Mermaid diagrams**
- Stack: Next.js 15 + React 19 + Mermaid frontend; FastAPI + adalflow + FAISS backend (cohort first to use SylphAI's `adalflow`)
- 5+ LLM providers + 3 embedder types with `DEEPWIKI_EMBEDDER_TYPE` runtime switch
- Per-host file fetchers with PAT auth for private repos
- **10 README languages** (most in cohort); MAX_INPUT_TOKENS = 7500 hard cap; no MCP

### [memvid/memvid](https://github.com/memvid/memvid)
*memory-framework · Apache-2.0 · [survey](surveys/memvid__memvid.md)*

First Rust-native repo in the cohort; everything in a single `.mv2` file.

- 4 KB header + WAL (1–64 MB) + zstd/lz4 segments + Tantivy lex index + HNSW vec index + Time Index + TOC footer with SHA-256 segment checksums — all in one file
- **Logic-Mesh on-disk graph blob** in the same file (1M-node / 5M-edge caps); entities extracted via `RulesEngine` (default) or LLM
- **7-kind `MemoryCard` taxonomy** — Fact / Preference / Event / Profile / Relationship / Goal / Other
- Hybrid retrieval: Tantivy BM25 + HNSW + RRF k=60; graph-aware `QueryPlanner` parses NL queries into `TriplePattern`/`GraphPattern` matches
- **Cryptographic provenance** — ed25519-dalek signing + blake3 hashing + AES-256-GCM `.mv2e` encryption capsules with TTL/rules
- No async, no MCP, no daemon; thin Python / Node / npm CLI wrappers

### [tirth8205/code-review-graph](https://github.com/tirth8205/code-review-graph)
*wiki-compiler · MIT · [survey](surveys/tirth8205__code-review-graph.md)*

Token-efficient codebase KG via tree-sitter + MCP; PyPI: `code-review-graph`. Created 2026-02-26 — fastest-growing in cohort.

- **Tree-sitter parses 32 languages** (incl. Vue SFC, Solidity, Dart, R, Perl, Lua, Jupyter / Databricks notebooks)
- SQLite-backed graph with BFS impact analysis + Leiden community detection (cohort second after graphrag)
- FTS5 hybrid search (keyword + optional sentence-transformers / Gemini / MiniMax embeddings)
- 22 MCP tools + 5 prompts via FastMCP stdio; pitch: **8.2× token reduction** measured across 6 repos
- **Auto-installs MCP config into 11 AI coding tools** with one `code-review-graph install` command (broadest cohort auto-config)
- Mechanical extraction at build time + LLM at query time (inverse of LLM-extract-at-ingest pattern)

### [Tencent/WeKnora](https://github.com/Tencent/WeKnora)
*kb-app · MIT · [survey](surveys/Tencent__WeKnora.md)*

Tencent's open-source RAG + Agent + Auto-Wiki platform; polyglot architecture.

- Stack: Go backend (gin / pgx / `hibiken/asynq` queue / `panjf2000/ants` goroutine pool) + Python `docreader/` gRPC service (PaddleOCR + VLM + 12 parsers) + Vue/React frontend + WeChat mini-program + Helm chart
- **7 vector backends** behind one retriever interface (Postgres+pgvector / Milvus / Qdrant / Elasticsearch v7+v8 / Weaviate / sqlite-vec / Neo4j) + **6 blob backends** (COS / OSS / TOS / MinIO / S3 / local)
- **Auto-Wiki** turns the KB into a navigable wiki with citation-aware linkify + dedup + lint + agent-tool CRUD
- Step-graph chat pipeline: `query_understand → query_expansion → search → merge → wiki_boost → rerank → filter_top_k`
- Memory consolidator triggers when `token_count > 0.5 × MaxContextTokens`; 3-retry + raw-archive fallback
- 5 preloaded SKILL.md skills following Claude's Progressive Disclosure pattern; Docker / local sandbox with explicit budgets (60s / 256MB / 1 CPU)

### [MODSetter/SurfSense](https://github.com/MODSetter/SurfSense)
*kb-app · Apache-2.0 · [survey](surveys/MODSetter__SurfSense.md)*

Privacy-focused NotebookLM alternative for teams (cohort first to fill the NotebookLM-shape KB slot).

- **4-process distribution** sharing one Postgres schema: backend (FastAPI + Celery + Redis + LangGraph + DeepAgents) + web (Next.js 15) + Electron desktop + Chrome MV3 extension — broadest single-product distribution surface in cohort
- **22 read-only KB connector indexers** (Airtable / BookStack / ClickUp / Confluence / Discord / Dropbox / Elasticsearch / GitHub / Google Calendar / Drive / Gmail / Jira / Linear / Luma / Notion / Obsidian / OneDrive / Slack / Teams / web-crawler) — distinct from anything-llm/sim's OAuth-action connectors; SurfSense ingests INTO the KB
- **9 ETL parser backends** co-existing — bundles 5 enterprise-tier parsers (Azure DI + Docling + LlamaCloud + Unstructured + Vision-LLM) in one project
- **3-tier identifier hashing** for connector dedup (per-content / per-source-id / per-(source × tenant)) — cohort first
- **Document-grouped reranking** alongside chunk-based; **document-summary as first-class indexing-pipeline stage**
- Cohort-first dedicated podcaster + video-presentation LangGraph agents with Kokoro TTS + STT services

### [NevaMind-AI/memU](https://github.com/NevaMind-AI/memU)
*memory-framework · Apache-2.0 · [survey](surveys/NevaMind-AI__memU.md)*

"24/7 Always-On Proactive Memory" framework; Python with Rust core via PyO3 / maturin.

- **"Memory as File System, File System as Memory"** — same metaphor as OpenViking but framed via Pydantic-typed records: `Resource` / `MemoryItem` / `MemoryCategory` / `CategoryItem`
- 3 storage backends (in-memory / SQLite / Postgres) behind `factory.py` + `interfaces.py` + `state.py`
- Workflow pipeline with `interceptor.py` + `step.py` + `pipeline.py` + `runner.py`
- **Hash-dedup baked into `BaseRecord`** — cohort first to make hash-based dedup a base-class concern
- LangGraph integration; 6 README languages

### [mksglu/context-mode](https://github.com/mksglu/context-mode)
*kb-app · ELv2 · [survey](surveys/mksglu__context-mode.md)*

Context-engineering MCP server addressing "the other half of the context problem" — what to *avoid putting into context in the first place*. Hacker News #1 with 570+ points.

- **Tool-output sandboxing** with cohort-first benchmarked 98% reduction (315 KB → 5.4 KB per `BENCHMARK.md`)
- **"Think in Code" paradigm** — `ctx_execute("javascript", code)` MCP tool lets the agent write a script and `console.log()` only the result
- **Session continuity via SQLite + FTS5 + BM25** with **fresh-session-as-clean-slate** semantics — without `--continue`, all previous data is *deleted immediately* (cohort first)
- **Cohort-widest agent-platform coverage** — 12 platform adapters + 14 platform configs spanning Antigravity / Claude Code / Codex / Cursor / Gemini CLI / JetBrains Copilot / Kiro / OpenClaw / OpenCode / Qwen Code / VS Code Copilot / Zed
- Cohort-novel **PRD-as-source-of-truth** doc pattern (forward-looking, distinct from memgraph's backward-looking ADRs)

### [vectorize-io/hindsight](https://github.com/vectorize-io/hindsight)
*memory-framework · MIT · [survey](surveys/vectorize-io__hindsight.md)*

Vectorize's open-source agent memory system; paper [arXiv:2512.12818](https://arxiv.org/abs/2512.12818).

- **Biomimetic 3-tier memory taxonomy** — `World facts` (general knowledge) + `Experience facts` (personal/episodic) + `Mental models` (LLM-consolidated patterns) — cohort first to type at *cognitive-process level*
- Postgres + pgvector backend; FastAPI server + Next.js control-plane UI
- Engine modules: `consolidation/`, `cross_encoder.py`, `directives/`, `entity_resolver.py`, **`jina_mlx_reranker.py`** (cohort-first Apple-MLX reranker), `query_analyzer.py`, `reflect/`, `retain/`
- **23 agent-framework integrations** (largest in cohort) — ag2, agentcore, agno, ai-sdk, autogen, claude-code, codex, crewai, langgraph, litellm, llamaindex, n8n, openai-agents, opencode, paperclip, pipecat, pydantic-ai, smolagents, strands, …
- MCP server via FastMCP with **2.x AND 3.x compat layer** (cohort first dual-API-version handling)
- Multi-tenant via memory **"Banks"** with per-bank tool filtering

### [Lum1104/Understand-Anything](https://github.com/Lum1104/Understand-Anything)
*wiki-compiler · MIT · [survey](surveys/Lum1104__Understand-Anything.md)*

First wiki-compiler in the cohort — Claude Code plugin that turns any codebase into an interactive knowledge graph + React/React-Flow dashboard.

- **TypeScript pnpm monorepo, no database, no vector backend, no MCP, no server** — everything lives in the analyzed project's `.understand-anything/` directory
- Two-phase extraction: deterministic `web-tree-sitter` WASM (9 per-language extractors + 12 per-format parsers + 10 framework registries + 38-language config) + LLM enrichment by **9 specialist agents** writing intermediates to disk to keep host-context small
- 8 slash-command skills following Claude Code's SKILL.md format
- **Two hooks**: `PostToolUse` Bash matcher detects `git commit/merge/cherry-pick/rebase` and fires auto-update; `SessionStart` checks `meta.json:gitCommitHash` against `git rev-parse HEAD`
- Privacy guard sanitizes every node's `filePath` on write (paths inside `projectRoot` → relative; absolute outside-paths reduced to filename)
- React + React Flow + Zustand + TailwindCSS v4 dashboard with prism-react-renderer source viewer

### [MemTensor/MemOS](https://github.com/MemTensor/MemOS)
*memory-framework · Apache-2.0 · [survey](surveys/MemTensor__MemOS.md)*

Research-grade memory framework; paper [arXiv:2507.03724](https://arxiv.org/abs/2507.03724).

- **Three explicitly-typed memory tiers** wrapped in a **MemCube** abstraction:
  - `ActivationMemory` (transformer KV-cache via `transformers.DynamicCache` + vLLM variant)
  - `ParametricMemory` (LoRA-as-memory — placeholder, typing in place)
  - `TextualMemory` (5+ implementations: simple / naive / tree / tree_text_memory / prefer_text_memory)
- **Multi-MemCube** for multi-tenant memory; `MemCube.download_repo` makes memory cubes a distributable artifact
- 3 graph backends — Neo4j (separate Community + Enterprise impls), **PolarDB** (Alibaba's Postgres fork — cohort first), Postgres
- Sophisticated `mem_scheduler/` with analyzer / monitors / task-schedule / webservice / ORM modules
- **Hookable plugin system** with 4-function API (`register_hook` / `register_hooks` / `trigger_hook` / `@hookable`); FastMCP server
- 4 shipped apps (cloud-and-self-hosted-plugin-pair pattern); benchmark claims +43.70% vs OpenAI Memory backed by paper + open eval

### [xerrors/Yuxi (语析)](https://github.com/xerrors/Yuxi)
*kb-app · MIT · [survey](surveys/xerrors__Yuxi.md)*

CN-language multi-tenant Agent Harness explicitly built on LightRAG + Vue + FastAPI + LangGraph v1.

- **Cohort first to officially document a downstream relationship to another cohort entry** as a headline architecture pillar (vs cohort entries that consume cognee/mem0/FalkorDB as one-of-N adapters)
- 3 KB implementations behind `KnowledgeBaseManager` factory — `lightrag.py` carries an upstream-bug fix for [LightRAG #580](https://github.com/HKUDS/LightRAG/issues/580) (**cohort first downstream-fix-loop**)
- Cohort-first **9 Chinese-ecosystem document parsers** (DeepSeek-OCR / MinerU / PaddleX `pp_structure_v3` / RapidOCR / unified)
- Cohort-first **`ragflow_like` chunking** — naming-as-attribution pattern (module credits ragflow's per-format chunker pattern by name)
- **Cohort-first 8-middleware chain** at LangGraph layer: attachment / context / dynamic_tool / knowledge_base / runtime_config / skills / summary
- Cohort-first **`present_artifacts` agent output channel** + cohort-first **KB-mount-into-sandbox via predicate**

### [campfirein/byterover-cli](https://github.com/campfirein/byterover-cli)
*memory-framework · ELv2 · [survey](surveys/campfirein__byterover-cli.md)*

`brv` CLI / Ink REPL / Vite Web UI for AI coding agents — first cohort entry on Elastic License 2.0.

- **Memory-router-as-product** — delegates to **7 memory backends** (`byterover` / `honcho` / `hindsight` / `obsidian` / `local-markdown` / `gbrain` / `memory-wiki` — 4 local + 3 cloud) with `isLocalProvider`/`isCloudProvider` gating
- **`QueryType` classifier** (`factual` / `personal` / `relational` / `temporal`) routes to backends with matching `ProviderCapabilities`
- 26 built-in agent tools as `.txt` prompt files incl. `swarm_query` / `swarm_store`, full memory CRUD, `curate` with explicit approve/reject review
- 18 LLM providers via Vercel `@ai-sdk/*` ecosystem
- **Git-like context tree** separate from memory (`.brv/` directory with `children-hash`, `derived-artifact`, `propagate-summaries`, `snapshot-diff`)
- MCP server via config-writers — generates configs so 22+ AI coding agents connect as MCP clients to `brv`

### [FalkorDB/FalkorDB](https://github.com/FalkorDB/FalkorDB)
*infra-layer · SSPL · [survey](surveys/FalkorDB__FalkorDB.md)*

First infra-layer entry — graph-database engine loaded as a Redis module (forked from RedisGraph after Redis Labs archived it).

- **Sparse-matrix adjacency representation + linear algebra over graphs** via [GraphBLAS](https://graphblas.org/) (bundled in `deps/`)
- **OpenCypher + Bolt protocol** so existing Neo4j drivers connect
- Multi-tenant via per-graph Redis-key namespacing; bundled RediSearch for graph-property text + vector indexing
- C engine + Rust core; 12 bundled deps (libcypher-parser / LAGraph / quickjs / utf8proc / xxHash)
- Used in production by [getzep/graphiti](surveys/getzep__graphiti.md) (1 of 4 graph backends) and [run-llama/llama_index](surveys/run-llama__llama_index.md) (`llama-index-graph-stores-falkordb`)
- First cohort entry on SSPL — restricts hosting providers from offering SaaS without open-sourcing surrounding infra

### [memgraph/memgraph](https://github.com/memgraph/memgraph)
*infra-layer · APL + BSL 1.1 + MEL · [survey](surveys/memgraph__memgraph.md)*

2nd infra-layer entry — Cypher-compatible in-memory graph database.

- **Single-query atomic retrieval** combining Tantivy (Rust full-text via FFI) + USearch (ANN library) + graph traversal in one Cypher statement (cohort first)
- Triple-licensed APL + BSL 1.1 + MEL — most layered cohort license stack; BSL 1.1 converts to Apache-2.0 after a few years
- C/C++ engine + NuRaft for HA consensus (ADR 002 documents adopting NuRaft after **3 in-house Raft attempts failed** — ~12 person-weeks of honest prior effort)
- RocksDB for disk persistence; Conan 2.x package management with 5 in-house dep forks
- Streaming sources via Kafka + Pulsar; **GPU graph algorithms via MAGE/cuGraph** (cohort first)
- **Cohort-first formal ADR practice** — 9 ADRs in `ADRs/` with structured Author/Status/Date/Problem/Criteria/Decision template
- Used by llama_index as `llama-index-graph-stores-memgraph` (1 of 7 graph_stores adapters)

### [AgriciDaniel/claude-obsidian](https://github.com/AgriciDaniel/claude-obsidian)
*wiki-compiler · MIT · [survey](surveys/AgriciDaniel__claude-obsidian.md)*

Claude Code plugin + Obsidian vault implementing [Andrej Karpathy's "LLM Wiki" pattern](https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f). The repo *is* the Obsidian vault — open in Obsidian directly.

- **No DB, no vector store** — pure Markdown filesystem with `wiki/` + `.raw/` + `.vault-meta/` folders
- **11 SKILL.md skills**: `autoresearch`, `canvas`, `defuddle`, `obsidian-bases`, `obsidian-markdown`, `save`, `wiki`, `wiki-fold`, `wiki-ingest`, `wiki-lint`, `wiki-query`
- **4-event hooks**: `SessionStart[startup\|resume]` / `PostCompact` / `PostToolUse[Write\|Edit]` / `Stop`
- **Hot cache primitive** — `wiki/hot.md` with `Last Updated` / `Key Recent Facts` / `Recent Changes` / `Active Threads` (≤500 words) read at session start, rewritten at session end
- Git auto-commits on every wiki write; cohort-first **`PostCompact` hook** explicitly handles Claude Code's context-compaction-loses-hook-state issue
- `[!contradiction]` callouts for sourced contradiction flagging; 8-category lint for wiki health; 3-round autoresearch with gap-filling

### [circlemind-ai/fast-graphrag](https://github.com/circlemind-ai/fast-graphrag)
*graphrag · MIT · [survey](surveys/circlemind-ai__fast-graphrag.md)*

circlemind.co's library-only GraphRAG (v0.0.5; stagnant since 2025-11 — commercial offering at circlemind.co may be where active dev moved).

- **Personalized PageRank as the primary retrieval primitive** — `igraph.personalized_pagerank(reset=query_entity_weights)` on a C-backed graph; sparse-matrix dot products cascade scores `entities → relationships → chunks`
- **Pickle-only persistence** in one `working_dir/` (`igraph_data.pklz` + `hnswlib` HNSW + pickled k/v + pickled blobs) — first cohort graphrag with zero external storage deps
- **Domain-priming as init contract** — `domain` + `example_queries` + `entity_types` (closed-set) are required `__init__` args injected into every extraction prompt
- Iterative "gleaning" loop — LLM self-checks `done`|`continue` after each extraction
- 4 ranking policies (`WithThreshold` default 0.005 / `TopK` / `Elbow` knee-detection / `WithConfidence` stub)
- Cost-anchored positioning: README headline `$0.08 vs $0.48 (6×)` vs microsoft/graphrag on Wizard of Oz; benchmarks in-tree
- No MCP, no memory layer, no service — pure embeddable library

### [plastic-labs/honcho](https://github.com/plastic-labs/honcho)
*memory-framework · AGPL-3.0 · [survey](surveys/plastic-labs__honcho.md)*

Plastic Labs's memory library for stateful agents.

- **Peer paradigm** — users AND agents are both `Peer`s; sessions can mix N peers with per-peer-per-session `observe_me` / `observe_others` knobs (cohort first to unify the identity primitive)
- Two background subsystems:
  - **Deriver** — real-time per-message representation update; observer/observed split lets one LLM call update N peers' models of one
  - **Dreamer** — cohort-first scheduled "memory consolidation agent" modeled on biological sleep cycles (`SurprisalTree` with **5 ANN tree variants** → `DeductionSpecialist` → `InductionSpecialist`)
- **3-level observation taxonomy** (`DocumentLevel`): `explicit` → `deductive` → `inductive` — cognitive-process axis at the *observation* layer
- **Dialectic API** (`POST /v1/peers/{peer_id}/chat`) with `format_new_turn_with_timestamp` injection so the LLM reasons about elapsed time
- **Peer Cards** capped at `MAX_PEER_CARD_FACTS = 40` (explicit cap to prevent unbounded growth)
- **MCP server is a separate Cloudflare Worker** — cohort first to ship MCP at the edge as a separately-deployable artifact
- 4 Claude Code skills incl. `migrate-honcho-py` / `migrate-honcho-ts`

### [basicmachines-co/basic-memory](https://github.com/basicmachines-co/basic-memory)
*memory-framework · AGPL-3.0 · [survey](surveys/basicmachines-co__basic-memory.md)*

Local-first Zettelkasten + KG over markdown files — the cohort's only files-as-source-of-truth design.

- SQLite (default) or Postgres index with sqlite-vec + fastembed
- **Rule-based grammar** (no LLM extraction): `[category] observation` and `verb [[link]]`
- Bidirectional file ↔ DB sync via watchfiles
- Ships in Smithery's MCP catalog

<!-- AUTO:END -->

---

## Enterprise & closed-source landscape

Out of scope for the surveyed cohort — no source to clone, no survey to write — but listed here as a directory so the open-source map has a counterpart you can orient against. Capabilities below are **vendor-described, not verified by code reading**, and are intentionally excluded from the adoption tables above. Where a closed product is the hosted tier of a surveyed repo, that bridge is called out.

### Hyperscaler managed RAG / KB

- **[Amazon Bedrock Knowledge Bases](https://aws.amazon.com/bedrock/knowledge-bases/)** — managed RAG over S3 + Aurora/OpenSearch/Pinecone/Neptune; **GraphRAG** GA on Neptune Analytics (entities + relationships auto-extracted at ingest); structured-data NL→SQL retrieval against data lakes/warehouses; multimodal parsing for tables/figures/charts. Closest closed analogue to the `graphrag` + `kb-app` cohort entries combined.
- **[Azure AI Search](https://azure.microsoft.com/products/ai-services/ai-search) + [Azure OpenAI On Your Data](https://learn.microsoft.com/azure/ai-services/openai/concepts/use-your-data)** — vector + hybrid + semantic ranker; **skillsets** ingestion pipeline (built-in + custom skills incl. entity extraction); one-click RAG wiring on top of an existing index.
- **[Google Vertex AI Search & Agent Builder](https://cloud.google.com/products/agent-builder)** — managed search-grounded agents, Gemini grounding with citations, layered on the Vertex AI RAG Engine.

### Document AI / entity extraction

- **[AWS Comprehend](https://aws.amazon.com/comprehend/)** — managed NER (built-in + custom entity recognizers), key-phrase extraction, PII detection, syntax. Frequently sits upstream of a Bedrock KB or a custom ingestion pipeline.
- **[Azure AI Document Intelligence](https://azure.microsoft.com/products/ai-services/ai-document-intelligence)** — layout + table + form extraction; prebuilt models (invoices / receipts / IDs) plus custom-model training.
- **[Google Document AI](https://cloud.google.com/document-ai)** — OCR + Layout Parser + specialized processors (Custom Document Extractor, Form Parser, Lending DocAI).

### Foundation-model-vendor RAG & memory

- **[OpenAI Assistants — File Search & Vector Stores](https://platform.openai.com/docs/assistants/tools/file-search)** — managed chunking + embeddings + ranking attached to an Assistant; closest closed analogue to the cohort's `kb-app` pattern.
- **[Anthropic Files API + memory tool](https://docs.anthropic.com/en/docs/build-with-claude/files)** — file uploads plus the agent-managed `memory` tool for long-term context; closest analogue to `memory-framework` entries like letta / honcho.
- **[Cohere Compass](https://cohere.com/compass)** + Command R+ retrieval — multi-aspect indexing (JSON-aware chunks) pitched at agentic RAG.

### Agent memory products

- **[Mem0 Cloud](https://mem0.ai/)** — hosted tier of the cohort's [`mem0ai/mem0`](surveys/mem0ai__mem0.md). Same atomic-fact extraction, SaaS-managed.
- **[Zep Cloud](https://www.getzep.com/)** — hosted tier built on the cohort's [`getzep/graphiti`](surveys/getzep__graphiti.md). Bi-temporal KG memory as a service.
- **[Membase](https://membase.so/)** — personal memory layer SaaS; KG auto-built from connected apps (Gmail / Slack / Notion / GitHub / Drive) and delivered to agents over MCP. Connector-driven, prosumer-flavored counterpart to mem0 / Zep.

### Enterprise search & Copilot-style assistants

- **[Glean](https://www.glean.com/)** — SaaS-connector enterprise search + agent platform; the closed-source shape that the cohort's [`onyx-dot-app/onyx`](surveys/onyx-dot-app__onyx.md) most directly competes with.
- **[Microsoft 365 Copilot + Microsoft Graph](https://www.microsoft.com/microsoft-365/copilot)** — grounded on Microsoft Graph (mail / files / Teams); connectors framework for non-Microsoft sources.
- **[Notion AI](https://www.notion.com/product/ai)** — workspace-grounded assistant; closest closed analogue to the `wiki-compiler` entries.

---

## Glossary

- **Atomic fact:** standalone verifiable claim with provenance.
- **Bi-temporal:** memory model tracking both validity time and recorded time.
- **Episodic memory:** raw, time-stamped event records.
- **Semantic memory:** distilled, entity-anchored claims derived from episodes.
- **MCP:** Model Context Protocol — the agent-to-tools wire format adopted across vendors.
- **Harness:** the OS layer around the LLM (skills, hooks, sandboxing, observability).

## Contributing

PRs that add a new survey are welcome. To propose a new repo for the cohort, open an issue with a link, a one-paragraph rationale, and the closest existing cohort entry it would extend or contrast.

## License

MIT. Linked projects retain their own licenses.
