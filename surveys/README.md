# Per-repo surveys (n=46)

One section per cohort entry — headline pitch + 3–5 distinctive bullets. Click through for the full code-reading report. Body order is by star count (highest first); use the index below to jump by category.

For the cohort-wide map, adoption tables, and patterns, see [`../README.md`](../README.md).

---

## Index

**kb-app (15)** — [ragflow](#infiniflowragflow) · [anything-llm](#mintplex-labsanything-llm) · [khoj](#khoj-aikhoj) · [AstrBot](#astrbotdevsastrbot) · [onyx](#onyx-dot-apponyx) · [sim](#simstudioaisim) · [composio](#composiohqcomposio) · [FastGPT](#labringfastgpt) · [DeepTutor](#hkudsdeeptutor) · [MaxKB](#1panel-devmaxkb) · [DocsGPT](#arc53docsgpt) · [WeKnora](#tencentweknora) · [SurfSense](#modsettersurfsense) · [context-mode](#mksglucontext-mode) · [Yuxi](#xerrorsyuxi)

**memory-framework (12)** — [mem0](#mem0aimem0) · [graphiti](#getzepgraphiti) · [OpenViking](#volcengineopenviking) · [letta](#letta-ailetta) · [cognee](#topoteretescognee) · [memvid](#memvidmemvid) · [memU](#nevamind-aimemu) · [hindsight](#vectorize-iohindsight) · [MemOS](#memtensormemos) · [byterover-cli](#campfireinbyterover-cli) · [honcho](#plastic-labshoncho) · [basic-memory](#basicmachines-cobasic-memory)

**wiki-compiler (6)** — [graphify](#safishamsigraphify) · [GitNexus](#abhigyanpatwarigitnexus) · [deepwiki-open](#asyncfuncaideepwiki-open) · [code-review-graph](#tirth8205code-review-graph) · [Understand-Anything](#lum1104understand-anything) · [claude-obsidian](#agricidanielclaude-obsidian)

**coding-agent (5)** — [OpenHands](#openhandsopenhands) · [claude-mem](#thedotmackclaude-mem) · [deer-flow](#bytedancedeer-flow) · [cline](#clinecline) · [aider](#aider-aiaider)

**graphrag (3)** — [LightRAG](#hkudslightrag) · [microsoft/graphrag](#microsoftgraphrag) · [fast-graphrag](#circlemind-aifast-graphrag)

**infra-layer (3)** — [mindsdb](#mindsdbmindsdb) · [FalkorDB](#falkordbfalkordb) · [memgraph](#memgraphmemgraph)

**kb-framework (2)** — [llama_index](#run-llamallama_index) · [haystack](#deepset-aihaystack)

---

## [infiniflow/ragflow](https://github.com/infiniflow/ragflow)
*kb-app · Apache-2.0 · [survey](infiniflow__ragflow.md)*

Production RAG with deep document understanding.

- Swappable doc engine — Elasticsearch / Infinity / OpenSearch
- Per-format specialized chunkers + `deepdoc` OCR
- In-memory NetworkX GraphRAG; per-tenant agent memory layer kept separate from the KB
- Both MCP server and client; **20 reranker backend classes** (largest in cohort)

## [OpenHands/OpenHands](https://github.com/OpenHands/OpenHands)
*coding-agent · MIT · [survey](OpenHands__OpenHands.md)*

Production multi-tenant coding-agent orchestrator with sandboxed runtime.

- Postgres + Redis + S3/GCS/local file-store; no vector store in the orchestrator repo
- KB is **`.openhands/microagents/*.md`** with `triggers:` frontmatter + `KeywordTrigger` / `TaskTrigger` loader
- Sandboxed runtime (Docker / k8s)
- The actual agent loop lives in pinned `openhands-sdk==1.19.1` — follow the SDK pin to find the real KB code

## [thedotmack/claude-mem](https://github.com/thedotmack/claude-mem)
*coding-agent · AGPL-3.0 · [survey](thedotmack__claude-mem.md)*

Claude Code memory plugin that extracts and re-injects context across sessions.

- Hooks **5 lifecycle events** → ships transcripts to a Bun worker on `:37777`
- Uses `@anthropic-ai/claude-agent-sdk` to extract typed observations into SQLite + ChromaDB-via-stdio-MCP
- Bundles 8 skills (mem-search / make-plan / do / pathfinder / smart-explore / timeline-report / knowledge-agent / version-bump)
- Privacy tags + multi-account profiles

## [bytedance/deer-flow](https://github.com/bytedance/deer-flow)
*coding-agent · MIT · [survey](bytedance__deer-flow.md)*

ByteDance's open-source super agent harness; v2.0 ground-up rewrite topped GitHub Trending #1 on 2026-02-28.

- LangGraph-native (most LangGraph-heavy repo in cohort: 7 langgraph-* packages + 6 langchain-*)
- FastAPI Gateway + Next.js frontend + Nginx + optional Kubernetes provisioner
- `deerflow-harness` Python package as importable substrate (agents / subagents / sandbox / mcp / memory / skills / runtime / community / reflection)
- **21 public skills** in SKILL.md format (deep-research, ppt-generation, podcast-generation, video-generation, skill-creator, …)
- 7 IM channels (DingTalk / Discord / Feishu / Slack / Telegram / WeChat / WeCom)

## [cline/cline](https://github.com/cline/cline)
*coding-agent · Apache-2.0 · [survey](cline__cline.md)*

VSCode/JetBrains/CLI coding agent — radical "no DB" design.

- **No vector store, no DB, no extraction** — knowledge lives in `.clinerules/*.md` + `@file` mentions + `~/.cline/data/*.json` atomic file stores + git checkpoints
- ContextManager keeps full edit history for replay
- MCP client only — first cohort exception to the universal MCP-server pattern

## [Mintplex-Labs/anything-llm](https://github.com/Mintplex-Labs/anything-llm)
*kb-app · MIT · [survey](Mintplex-Labs__anything-llm.md)*

Workspace-scoped multi-LLM kb-app + agent + MCP runtime.

- **Largest in-tree provider matrix in cohort:** 37 LLM providers + 14 embedders + 10 vector backends bundled in-tree (vs llama_index's 571 separately versioned packages)
- Custom Aibitat agent runtime (NOT LangChain/LlamaIndex) with 17 built-in plugins; 3 default-enabled
- **MCPHypervisor pattern** — boots multiple MCP servers and converts each server's tools into native Aibitat plugins (`@@mcp_{name}` namespace); cohort's first "MCP host" role
- **Skill-availability gating** — skills disappear from the agent's tool list when their backing system isn't installed (cohort first)
- 6 cloud-deploy targets (AWS / GCP / OpenShift / Helm / k8s / HuggingFace Spaces) — broadest in cohort

## [mem0ai/mem0](https://github.com/mem0ai/mem0)
*memory-framework · Apache-2.0 · [survey](mem0ai__mem0.md)*

Universal memory layer that ingests conversation messages and auto-extracts atomic facts.

- v3 multi-signal hybrid retrieval (semantic + BM25 + entity matching) scoped by user/agent/run
- **24 vector + 18 LLM + 11 embedder + 5 reranker provider plugins**
- **v3 removed `graph_store`** — entity linking is now built-in (auto-extracted entities used as a retrieval boost)
- Default OSS Docker compose ships only `pgvector` (Neo4j removed in v3)
- Python + TS SDKs; MCP server in three flavors

## [run-llama/llama_index](https://github.com/run-llama/llama_index)
*kb-framework · MIT · [survey](run-llama__llama_index.md)*

Foundational Python RAG/agent framework — the cohort's "framework-as-aggregator" exemplar.

- **571 separately versioned integration packages** under `llama-index-integrations/` (78 vector / 104 LLM / 66 embedders / 159 readers / 68 tools / 26 rerankers / 7 graph / 9 indices / 14 retrievers) — broadest backend coverage by ~3×
- **Memory = waterfall queue + composable blocks**: FIFO queue (default `token_limit=30000`) waterfalls ejected pressure-windows into ordered `BaseMemoryBlock`s with per-block `priority` knobs
- Two KG primitives ship side-by-side: legacy `KnowledgeGraphIndex` + current `PropertyGraphIndex` with 4 sub-retrievers + 4 transformations
- **Bidirectional MCP via the same primitive** in `llama-index-tools-mcp`: `McpToolSpec` consumes external servers; `workflow_as_mcp` exposes any `Workflow` as one
- First-party adapters for cohort members — `llama-index-graph-rag-cognee` / `llama-index-memory-mem0` / `llama-index-graph-stores-falkordb` / `llama-index-graph-stores-memgraph`

## [Aider-AI/aider](https://github.com/Aider-AI/aider)
*coding-agent · Apache-2.0 · [survey](Aider-AI__aider.md)*

Terminal pair-programmer — the cohort's purest minimalist coding-agent design.

- KB is a **PageRank-weighted "repo-map" from tree-sitter symbol tags** (30+ languages), cached in `.aider.tags.cache.v4/` (diskcache + SQLite)
- **No LLM extraction, no MCP at all, no cross-session memory** beyond git
- ChatSummary truncates older turns under a token budget
- Voice / clipboard / web-scrape inputs

## [safishamsi/graphify](https://github.com/safishamsi/graphify)
*wiki-compiler · MIT · [survey](safishamsi__graphify.md)*

Single-author Python library distributed as a Claude Code skill (+10 sibling-IDE bundles); turns code/docs/papers/images/videos into a queryable knowledge graph.

- Linear stateless pipeline — `detect → extract → build_graph → cluster → analyze → report → export`
- **21 tree-sitter language deps** baked in
- **Cohort-first typed edge confidence** — every edge labeled `EXTRACTED` / `INFERRED` / `AMBIGUOUS` (last flagged for human review in `GRAPH_REPORT.md`)
- **Cohort-first polyglot integration-point detection** via 11-language-family `_LANG_FAMILY` table — surfaces FFI bridges and microservice boundaries as "surprising connections"
- 6 export formats from one NetworkX graph (Obsidian / JSON / HTML / SVG / GraphML / Neo4j Cypher)

## [mindsdb/mindsdb](https://github.com/mindsdb/mindsdb)
*infra-layer · ELv2 · [survey](mindsdb__mindsdb.md)*

Federated SQL query engine — agents query unified data via a single SQL surface, no ETL.

- Custom `mindsdb-sql-parser` extends SQL with `CREATE KNOWLEDGE_BASE` / `CREATE JOB` / `CREATE TRIGGER` / `CREATE AGENT` / `CREATE CHATBOT` / `CREATE MODEL` DDL
- **34 in-tree handlers** (data sources + LLM providers + vector stores + ML); README claims 200+ via external packages
- Cohort-first **MySQL wire protocol endpoint** — any MySQL client/driver becomes an agent client
- Cohort-first **Google A2A protocol** implementation (`MindsDBAgent` HTTP client)
- **Most complete MCP capability stack in cohort** — tools + prompts + resources + completions + OAuth + dual SSE/Streamable-HTTP transport

## [HKUDS/LightRAG](https://github.com/HKUDS/LightRAG)
*graphrag · MIT · [survey](HKUDS__LightRAG.md)*

EMNLP 2025 GraphRAG library — service-shaped variant of the graphrag pattern.

- **4-storage abstraction** (KV / vector / graph / doc-status) × **13 pluggable backend impls** + 14 LLM bindings
- Default stack: nano-vectordb + NetworkX + JSON files (in-process)
- **6 named retrieval modes** — `local` / `global` / `hybrid` / `mix` / `naive` / `bypass` (cohort-first "skip retrieval" primitive)
- FastAPI server + React 19 WebUI + Ollama-compatible API; no MCP

## [khoj-ai/khoj](https://github.com/khoj-ai/khoj)
*kb-app · AGPL-3.0 · [survey](khoj-ai__khoj.md)*

Self-hostable personal "second-brain" with a single-Postgres KB stack.

- pgvector backend: `Entry` (chunked docs) + `UserMemory` (atomic facts extracted by an LLM-driven "Muninn" agent)
- `pgserver` extra runs embedded Postgres for laptop self-host
- 8 native source adapters: org-mode (only mainstream agent with org-mode), markdown, PDF, DOCX, plaintext, image, GitHub, Notion
- MCP client (stdio + SSE in one class), no MCP server
- Computer-use operator agent integrated; cross-encoder reranker (`mxbai-rerank-xsmall-v1`)

## [abhigyanpatwari/GitNexus](https://github.com/abhigyanpatwari/GitNexus)
*wiki-compiler · PolyForm Noncommercial 1.0.0 · [survey](abhigyanpatwari__GitNexus.md)*

"Zero-Server Code Intelligence Engine" — TypeScript monorepo with two deployment shapes from one repo.

- **Dual deployment** — `gitnexus` npm CLI + 22 MCP tools AND `gitnexus-web` Vite browser app that runs entirely client-side via WASM tree-sitter (cohort first browser-side code-KG)
- **11 language extractor configs** — cohort-novel "extractor as config file" pattern (vs per-language code)
- Cohort-first dedicated COBOL processor (legacy-system code-modernization use case)
- Cohort-first **adaptive tree-sitter buffer sizing** (512 KB → 32 MB based on `byteLength × 2`)
- Cohort-first **MCP staleness tracking** + **structured tool descriptions** with `WHEN TO USE / AFTER THIS / situational context` 3-part contract
- Most restrictive cohort license — commercial requires explicit license from akonlabs.com

## [microsoft/graphrag](https://github.com/microsoft/graphrag)
*graphrag · MIT · [survey](microsoft__graphrag.md)*

Microsoft Research's reference GraphRAG — pipeline-shaped variant; positioned as a "demonstration".

- LLM `GraphExtractor` (custom `<|>`-tuple delimiters + iterative gleanings) → in-memory NetworkX → Hierarchical Leiden communities → per-community LLM `CommunityReport` summaries → Parquet outputs
- Vector factory: LanceDB (default) / Azure AI Search / Cosmos DB
- Storage factory: file / Azure Blob / Cosmos / memory
- **4 query modes** — Basic / Local / Global (map-reduce) / DRIFT (community-aware iterative)
- **No MCP, no memory, no reranker**; production users typically vendor

## [AstrBotDevs/AstrBot](https://github.com/AstrBotDevs/AstrBot)
*kb-app · AGPL-3.0 + custom EULA · [survey](AstrBotDevs__AstrBot.md)*

Multi-platform IM chatbot framework with first-party adapters for 8 IM platforms (QQ / WeChat / Feishu / DingTalk / Telegram / Slack / Discord / Lark).

- KB module: SQLite + Faiss (only backend) with hybrid retrieval — dense + jieba-BM25 → RRF (k=60) → optional pluggable reranker
- Per-KB knobs (chunk_size / top_k_dense / top_k_sparse / top_m_final / providers) stored on the row
- **MCP client only** with three transports (stdio + SSE + StreamableHTTP) in one class + allowlist/denylist hardening
- **Skills system mounts SKILL.md files into an `aiodocker` Docker sandbox** at `/workspace/skills/<name>/SKILL.md`
- Distinct memory layers (ConversationManager / PersonaManager / `LongTermMemory` per-group / KB) deliberately decoupled

## [onyx-dot-app/onyx](https://github.com/onyx-dot-app/onyx)
*kb-app · MIT + Onyx EE for `ee/` · [survey](onyx-dot-app__onyx.md)*

Most enterprise-shaped repo in the cohort (formerly Danswer).

- **49 first-party SaaS connectors** + federated retrieval; hybrid index on Vespa (default) or OpenSearch behind a `DocumentIndex` ABC
- **Postgres-backed knowledge graph** — entities + relationships + typed `KGAttributeImplicationProperty` as SQL tables (no graph DB), populated by a Celery worker
- MCP server (FastMCP + token auth) + MCP client (`claude-agent-sdk` + `agent-client-protocol`) for an ACP-based "Build" sandbox (Local Docker or Kubernetes)
- Multi-tenant via schema-per-tenant Alembic + `get_current_tenant_id()` contextvars
- Deep Research orchestrator state machine; voice + image-gen + 5 web-search providers
- Heavy ops surface (Vespa + Postgres + Redis + Celery + S3 + model_server) — "Onyx Lite" mode for laptop deployments

## [simstudioai/sim](https://github.com/simstudioai/sim)
*kb-app · Apache-2.0 + EE for `apps/sim/ee/` · [survey](simstudioai__sim.md)*

Bun-managed Next.js 15 + Drizzle workflow platform positioning as "central intelligence layer for AI workforce".

- **Cohort's most sophisticated MCP stack** — negotiates 3 MCP versions with OAuth 2.1 + elicitation; ships custom `McpSecurityPolicy` + consent layer + pre-call `validateMcpDomain` + `validateMcpServerSsrf` SSRF guards
- **`workflow-mcp-sync.ts` deploys workflows AS MCP servers** with DB persistence — cohort first "persisted workflow as MCP server"
- Most decomposed integration set in cohort: 35 connectors / **220 tools** (one `.ts` per tool) / 227 workflow blocks / 17 LLM providers / 7 chunkers / 11 file parsers
- **Cross-language guardrails** (cohort first) — `validate_pii.py` + `validate_pii.ts` coexist + JSON / regex / hallucination validators
- **Self-modifying agent skills** in `.agents/skills/` (14 skills targeting *the project itself*)

## [ComposioHQ/composio](https://github.com/ComposioHQ/composio)
*kb-app · MIT · [survey](ComposioHQ__composio.md)*

Toolkit-routing-as-service that wraps 1000+ third-party-tool integrations behind one SDK.

- Cohort-first **remote-MCP-session-as-service primitive** — `composio.experimental.create(userId, {toolkits, manageConnections})` returns an MCP URL scoped to that `(userId × toolkit-set)` tuple
- Cohort-first **auth-as-service for tools at scale** — `AuthConfigs` + `AuthScheme` + `ConnectedAccounts` + `ConnectionRequest` make per-user OAuth a first-class abstraction
- 23 provider integrations across TS + Python SDKs; **provider-typed generic tool collections** preserve provider-native types across providers
- Cohort-first explicit Cloudflare-Workers-runtime support at the SDK core level
- Effect.ts + @clack/prompts CLI; pnpm workspaces + changesets

## [labring/FastGPT](https://github.com/labring/FastGPT)
*kb-app · FastGPT Open Source License (Apache + SaaS restriction) · [survey](labring__FastGPT.md)*

TypeScript-first knowledge-base + visual workflow platform; CJK-first.

- pi-mono agent runtime
- Vector backends: pgvector / Milvus / OceanBase / OpenGauss / SeekDB
- MongoDB metadata + MinIO blobs
- jieba + tiktoken hybrid retrieval
- MCP servers as workflow nodes

## [getzep/graphiti](https://github.com/getzep/graphiti)
*memory-framework · Apache-2.0 · [survey](getzep__graphiti.md)*

Bi-temporal KG library — only cohort entry that supports "as-of-date" queries.

- Every `EntityEdge` carries 4 temporal fields: `valid_at` / `invalid_at` / `expired_at` / `created_at`
- 4 backends: Neo4j / FalkorDB / Kuzu / Neptune
- Pydantic-typed entities + `gliner2` extraction
- 4-tier schema: `EpisodicNode` / `EntityNode` / `CommunityNode` / `SagaNode`
- **16 pre-baked search recipes** (Combined×3 + Edge×5 + Node×5 + Community×3) over 4 reranker modes (RRF / node-distance / MMR / cross-encoder)

## [deepset-ai/haystack](https://github.com/deepset-ai/haystack)
*kb-framework · Apache-2.0 · [survey](deepset-ai__haystack.md)*

The cohort's elder-statesman framework (created 2019-11).

- **Component-pipeline architecture** — pipelines are NetworkX DAGs of `Component`s connected via typed sockets
- 24 component categories ship in core (agents / audio / builders / classifiers / converters / embedders / evaluators / extractors / generators / joiners / preprocessors / rankers / retrievers / routers / tools / validators / websearch / writers / …)
- Vector backends are **50+ sibling packages**; core ships only `InMemoryDocumentStore` to keep install lean
- Tool model: `Tool` / `ComponentTool` / `PipelineTool` / `from_function` / `Toolset` / `SearchableToolset` (semantic search over tool descriptions)
- **Cohort-first `human_in_the_loop/` package** with policies / strategies / user_interfaces / dataclasses; built-in RAG-quality metrics in `evaluation/`

## [volcengine/OpenViking](https://github.com/volcengine/OpenViking)
*memory-framework · AGPL-3.0 · [survey](volcengine__OpenViking.md)*

ByteDance Volcengine's "Context Database for AI Agents"; Python + Rust hybrid.

- **Filesystem-paradigm context management** — memories, resources, and skills all live as files in a virtual filesystem (Rust `ragfs` crate with **7 backend plugins**)
- `ContextLevel` enum (L0=ABSTRACT / L1=OVERVIEW / L2=DETAIL) drives on-demand tiered loading — cohort first to type the tier explicitly
- Hierarchical + directory-recursive retrieval combined with semantic search; visualized retrieval trajectory for debugging
- `memory_lifecycle.py` is a first-class memory subsystem (cohort first to name it)
- Heavy CN-cloud tilt — Doubao/Ark models as primary LLM target

## [HKUDS/DeepTutor](https://github.com/HKUDS/DeepTutor)
*kb-app · Apache-2.0 · [survey](HKUDS__DeepTutor.md)*

Agent-Native Personalized Tutoring from HK Data Science (same lab as LightRAG).

- **6 named capabilities as typed pipelines** — `chat` / `deep_question` / `deep_research` / `deep_solve` (Plan → ReAct → Write) / `math_animator` / `visualize`
- Cohort-first **typed `CapabilityManifest`** with declarative `stages: list[str]`
- Cohort-first **versioned KB indexes with re-index workflow** — embedding-config drift surfaced as a first-class workflow primitive (not silent re-index)
- **TutorBot subsystem** = persistent autonomous AI tutors with `cron/service.py` scheduled execution + `heartbeat/` for liveness; 14 TutorBot skills incl. `skill-creator`, `tmux`
- Cohort-first dedicated `tex_chunker.py` for LaTeX/math chunking; cohort-first dedicated `co_writer/edit_agent.py` for collaborative writing

## [letta-ai/letta](https://github.com/letta-ai/letta)
*memory-framework · Apache-2.0 · [survey](letta-ai__letta.md)*

The original MemGPT — the research project that gave the cohort its memory-taxonomy lineage.

- **Memory blocks abstraction** — `Block(label, value, limit)` rows where `label ∈ {human, persona, system}` define typed slices of the LLM context with per-block char budgets
- **Archives** are shareable collections of **Passages** (embedded chunks)
- 3 vector backends: `native` (Postgres + pgvector), `tpuf` (Turbopuffer), `pinecone`
- **50 ORM tables** with explicit join tables for everything — most explicitly normalized memory schema in cohort
- **Agent-self-managed memory** — the agent calls `core_memory_*` and `archival_memory_*` tools to update its own state (inverse of mem0's auto-extract)
- 8 agent-loop variants (v1 / v2 / v3 / voice / voice_sleeptime / ephemeral / ephemeral_summary / batch); ClickHouse opt-in for OTEL + provider tracing

## [1Panel-dev/MaxKB](https://github.com/1Panel-dev/MaxKB)
*kb-app · GPL-3.0 · [survey](1Panel-dev__MaxKB.md)*

"Max Knowledge Brain" enterprise agent platform from FIT2CLOUD; Django 5.2 + Vue + heavy LangChain footprint.

- Single-Postgres-only via pgvector (no other vector backend ships)
- **35+ workflow step nodes** incl. loop_break / loop_continue / intent / parameter_extraction / mcp / image_to_video / video_understand / text_to_speech
- **23 model providers** (CN-cloud-heavy: Aliyun Bailian / Volcengine / Tencent / Wenxin / Zhipu / Qianfan / DeepSeek / Kimi)
- **Long-term memory = 4-category structured schema** (`偏好` / `背景` / `约定` / `目标`) extracted by a 230-line Chinese-language prompt; refreshed via APScheduler
- MCP servers synthesized at runtime from user-authored Python via `ast` rewriting → `@mcp.tool` decorators on a generated `FastMCP(uuid)` module
- First cohort entry on classic GPL (not AGPL)

## [arc53/DocsGPT](https://github.com/arc53/DocsGPT)
*kb-app · MIT · [survey](arc53__DocsGPT.md)*

Private AI platform for agents + assistants + enterprise search; Flask + Celery + Alembic + React stack.

- **Cohort-first 4-agent-type taxonomy** — `ClassicAgent` (pre-fetch RAG) / `AgenticAgent` (LLM-decides-when-to-search) / `WorkflowAgent` (visual workflows) / `ResearchAgent` (multi-turn deep research)
- **Cohort-first `internal_search` RAG-as-LLM-tool** — RAG becomes one tool among many that the agent calls when needed (vs RAG-as-front-of-pipeline)
- **Cohort-first MCP-bearer-token-reuse** — existing DocsGPT API keys are reused as MCP bearer tokens (no new credential surface)
- 8 vector backends + 15 file parsers incl. **cohort-first `openapi3_parser`** + 19 agent tools
- **CEL workflow evaluator** (cohort first to use Google's Common Expression Language for workflow conditional logic)
- 3 enterprise SaaS connectors (Confluence / GoogleDrive / SharePoint); cohort-first Chatwoot AI-assistant integration

## [topoteretes/cognee](https://github.com/topoteretes/cognee)
*memory-framework · Apache-2.0 · [survey](topoteretes__cognee.md)*

ECL (Extract / Cognify / Load) memory platform with rdflib/OWL ontologies.

- LanceDB + Kuzu defaults; also Chroma / pgvector / Neo4j / Neptune / Postgres + 2 hybrid stores
- Named **"memify" pipelines** — `consolidate_entity_descriptions` / `apply_feedback_weights` / `persist_sessions_in_knowledge_graph`
- 30+ optional extras including a `graphiti` backend extra
- Ships a `cognee/skill.md` Claude-Skills bundle

## [AsyncFuncAI/deepwiki-open](https://github.com/AsyncFuncAI/deepwiki-open)
*wiki-compiler · MIT · [survey](AsyncFuncAI__deepwiki-open.md)*

Open-source clone of DeepWiki; turns any GitHub/GitLab/BitBucket repo into an interactive wiki.

- Server-shaped wiki-compiler — RAG-powered "Ask" + multi-turn "DeepResearch" + auto-generated **Mermaid diagrams**
- Stack: Next.js 15 + React 19 + Mermaid frontend; FastAPI + adalflow + FAISS backend (cohort first to use SylphAI's `adalflow`)
- 5+ LLM providers + 3 embedder types with `DEEPWIKI_EMBEDDER_TYPE` runtime switch
- Per-host file fetchers with PAT auth for private repos
- **10 README languages** (most in cohort); MAX_INPUT_TOKENS = 7500 hard cap; no MCP

## [memvid/memvid](https://github.com/memvid/memvid)
*memory-framework · Apache-2.0 · [survey](memvid__memvid.md)*

First Rust-native repo in the cohort; everything in a single `.mv2` file.

- 4 KB header + WAL (1–64 MB) + zstd/lz4 segments + Tantivy lex index + HNSW vec index + Time Index + TOC footer with SHA-256 segment checksums — all in one file
- **Logic-Mesh on-disk graph blob** in the same file (1M-node / 5M-edge caps); entities extracted via `RulesEngine` (default) or LLM
- **7-kind `MemoryCard` taxonomy** — Fact / Preference / Event / Profile / Relationship / Goal / Other
- Hybrid retrieval: Tantivy BM25 + HNSW + RRF k=60; graph-aware `QueryPlanner` parses NL queries into `TriplePattern`/`GraphPattern` matches
- **Cryptographic provenance** — ed25519-dalek signing + blake3 hashing + AES-256-GCM `.mv2e` encryption capsules with TTL/rules
- No async, no MCP, no daemon; thin Python / Node / npm CLI wrappers

## [tirth8205/code-review-graph](https://github.com/tirth8205/code-review-graph)
*wiki-compiler · MIT · [survey](tirth8205__code-review-graph.md)*

Token-efficient codebase KG via tree-sitter + MCP; PyPI: `code-review-graph`. Created 2026-02-26 — fastest-growing in cohort.

- **Tree-sitter parses 32 languages** (incl. Vue SFC, Solidity, Dart, R, Perl, Lua, Jupyter / Databricks notebooks)
- SQLite-backed graph with BFS impact analysis + Leiden community detection (cohort second after graphrag)
- FTS5 hybrid search (keyword + optional sentence-transformers / Gemini / MiniMax embeddings)
- 22 MCP tools + 5 prompts via FastMCP stdio; pitch: **8.2× token reduction** measured across 6 repos
- **Auto-installs MCP config into 11 AI coding tools** with one `code-review-graph install` command (broadest cohort auto-config)
- Mechanical extraction at build time + LLM at query time (inverse of LLM-extract-at-ingest pattern)

## [Tencent/WeKnora](https://github.com/Tencent/WeKnora)
*kb-app · MIT · [survey](Tencent__WeKnora.md)*

Tencent's open-source RAG + Agent + Auto-Wiki platform; polyglot architecture.

- Stack: Go backend (gin / pgx / `hibiken/asynq` queue / `panjf2000/ants` goroutine pool) + Python `docreader/` gRPC service (PaddleOCR + VLM + 12 parsers) + Vue/React frontend + WeChat mini-program + Helm chart
- **7 vector backends** behind one retriever interface (Postgres+pgvector / Milvus / Qdrant / Elasticsearch v7+v8 / Weaviate / sqlite-vec / Neo4j) + **6 blob backends** (COS / OSS / TOS / MinIO / S3 / local)
- **Auto-Wiki** turns the KB into a navigable wiki with citation-aware linkify + dedup + lint + agent-tool CRUD
- Step-graph chat pipeline: `query_understand → query_expansion → search → merge → wiki_boost → rerank → filter_top_k`
- Memory consolidator triggers when `token_count > 0.5 × MaxContextTokens`; 3-retry + raw-archive fallback
- 5 preloaded SKILL.md skills following Claude's Progressive Disclosure pattern; Docker / local sandbox with explicit budgets (60s / 256MB / 1 CPU)

## [MODSetter/SurfSense](https://github.com/MODSetter/SurfSense)
*kb-app · Apache-2.0 · [survey](MODSetter__SurfSense.md)*

Privacy-focused NotebookLM alternative for teams (cohort first to fill the NotebookLM-shape KB slot).

- **4-process distribution** sharing one Postgres schema: backend (FastAPI + Celery + Redis + LangGraph + DeepAgents) + web (Next.js 15) + Electron desktop + Chrome MV3 extension — broadest single-product distribution surface in cohort
- **22 read-only KB connector indexers** (Airtable / BookStack / ClickUp / Confluence / Discord / Dropbox / Elasticsearch / GitHub / Google Calendar / Drive / Gmail / Jira / Linear / Luma / Notion / Obsidian / OneDrive / Slack / Teams / web-crawler) — distinct from anything-llm/sim's OAuth-action connectors; SurfSense ingests INTO the KB
- **9 ETL parser backends** co-existing — bundles 5 enterprise-tier parsers (Azure DI + Docling + LlamaCloud + Unstructured + Vision-LLM) in one project
- **3-tier identifier hashing** for connector dedup (per-content / per-source-id / per-(source × tenant)) — cohort first
- **Document-grouped reranking** alongside chunk-based; **document-summary as first-class indexing-pipeline stage**
- Cohort-first dedicated podcaster + video-presentation LangGraph agents with Kokoro TTS + STT services

## [NevaMind-AI/memU](https://github.com/NevaMind-AI/memU)
*memory-framework · Apache-2.0 · [survey](NevaMind-AI__memU.md)*

"24/7 Always-On Proactive Memory" framework; Python with Rust core via PyO3 / maturin.

- **"Memory as File System, File System as Memory"** — same metaphor as OpenViking but framed via Pydantic-typed records: `Resource` / `MemoryItem` / `MemoryCategory` / `CategoryItem`
- 3 storage backends (in-memory / SQLite / Postgres) behind `factory.py` + `interfaces.py` + `state.py`
- Workflow pipeline with `interceptor.py` + `step.py` + `pipeline.py` + `runner.py`
- **Hash-dedup baked into `BaseRecord`** — cohort first to make hash-based dedup a base-class concern
- LangGraph integration; 6 README languages

## [mksglu/context-mode](https://github.com/mksglu/context-mode)
*kb-app · ELv2 · [survey](mksglu__context-mode.md)*

Context-engineering MCP server addressing "the other half of the context problem" — what to *avoid putting into context in the first place*. Hacker News #1 with 570+ points.

- **Tool-output sandboxing** with cohort-first benchmarked 98% reduction (315 KB → 5.4 KB per `BENCHMARK.md`)
- **"Think in Code" paradigm** — `ctx_execute("javascript", code)` MCP tool lets the agent write a script and `console.log()` only the result
- **Session continuity via SQLite + FTS5 + BM25** with **fresh-session-as-clean-slate** semantics — without `--continue`, all previous data is *deleted immediately* (cohort first)
- **Cohort-widest agent-platform coverage** — 12 platform adapters + 14 platform configs spanning Antigravity / Claude Code / Codex / Cursor / Gemini CLI / JetBrains Copilot / Kiro / OpenClaw / OpenCode / Qwen Code / VS Code Copilot / Zed
- Cohort-novel **PRD-as-source-of-truth** doc pattern (forward-looking, distinct from memgraph's backward-looking ADRs)

## [vectorize-io/hindsight](https://github.com/vectorize-io/hindsight)
*memory-framework · MIT · [survey](vectorize-io__hindsight.md)*

Vectorize's open-source agent memory system; paper [arXiv:2512.12818](https://arxiv.org/abs/2512.12818).

- **Biomimetic 3-tier memory taxonomy** — `World facts` (general knowledge) + `Experience facts` (personal/episodic) + `Mental models` (LLM-consolidated patterns) — cohort first to type at *cognitive-process level*
- Postgres + pgvector backend; FastAPI server + Next.js control-plane UI
- Engine modules: `consolidation/`, `cross_encoder.py`, `directives/`, `entity_resolver.py`, **`jina_mlx_reranker.py`** (cohort-first Apple-MLX reranker), `query_analyzer.py`, `reflect/`, `retain/`
- **23 agent-framework integrations** (largest in cohort) — ag2, agentcore, agno, ai-sdk, autogen, claude-code, codex, crewai, langgraph, litellm, llamaindex, n8n, openai-agents, opencode, paperclip, pipecat, pydantic-ai, smolagents, strands, …
- MCP server via FastMCP with **2.x AND 3.x compat layer** (cohort first dual-API-version handling)
- Multi-tenant via memory **"Banks"** with per-bank tool filtering

## [Lum1104/Understand-Anything](https://github.com/Lum1104/Understand-Anything)
*wiki-compiler · MIT · [survey](Lum1104__Understand-Anything.md)*

First wiki-compiler in the cohort — Claude Code plugin that turns any codebase into an interactive knowledge graph + React/React-Flow dashboard.

- **TypeScript pnpm monorepo, no database, no vector backend, no MCP, no server** — everything lives in the analyzed project's `.understand-anything/` directory
- Two-phase extraction: deterministic `web-tree-sitter` WASM (9 per-language extractors + 12 per-format parsers + 10 framework registries + 38-language config) + LLM enrichment by **9 specialist agents** writing intermediates to disk to keep host-context small
- 8 slash-command skills following Claude Code's SKILL.md format
- **Two hooks**: `PostToolUse` Bash matcher detects `git commit/merge/cherry-pick/rebase` and fires auto-update; `SessionStart` checks `meta.json:gitCommitHash` against `git rev-parse HEAD`
- Privacy guard sanitizes every node's `filePath` on write (paths inside `projectRoot` → relative; absolute outside-paths reduced to filename)
- React + React Flow + Zustand + TailwindCSS v4 dashboard with prism-react-renderer source viewer

## [MemTensor/MemOS](https://github.com/MemTensor/MemOS)
*memory-framework · Apache-2.0 · [survey](MemTensor__MemOS.md)*

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

## [xerrors/Yuxi](https://github.com/xerrors/Yuxi)
*kb-app · MIT · [survey](xerrors__Yuxi.md)*

CN-language multi-tenant Agent Harness explicitly built on LightRAG + Vue + FastAPI + LangGraph v1.

- **Cohort first to officially document a downstream relationship to another cohort entry** as a headline architecture pillar (vs cohort entries that consume cognee/mem0/FalkorDB as one-of-N adapters)
- 3 KB implementations behind `KnowledgeBaseManager` factory — `lightrag.py` carries an upstream-bug fix for [LightRAG #580](https://github.com/HKUDS/LightRAG/issues/580) (**cohort first downstream-fix-loop**)
- Cohort-first **9 Chinese-ecosystem document parsers** (DeepSeek-OCR / MinerU / PaddleX `pp_structure_v3` / RapidOCR / unified)
- Cohort-first **`ragflow_like` chunking** — naming-as-attribution pattern (module credits ragflow's per-format chunker pattern by name)
- **Cohort-first 8-middleware chain** at LangGraph layer: attachment / context / dynamic_tool / knowledge_base / runtime_config / skills / summary
- Cohort-first **`present_artifacts` agent output channel** + cohort-first **KB-mount-into-sandbox via predicate**

## [campfirein/byterover-cli](https://github.com/campfirein/byterover-cli)
*memory-framework · ELv2 · [survey](campfirein__byterover-cli.md)*

`brv` CLI / Ink REPL / Vite Web UI for AI coding agents — first cohort entry on Elastic License 2.0.

- **Memory-router-as-product** — delegates to **7 memory backends** (`byterover` / `honcho` / `hindsight` / `obsidian` / `local-markdown` / `gbrain` / `memory-wiki` — 4 local + 3 cloud) with `isLocalProvider`/`isCloudProvider` gating
- **`QueryType` classifier** (`factual` / `personal` / `relational` / `temporal`) routes to backends with matching `ProviderCapabilities`
- 26 built-in agent tools as `.txt` prompt files incl. `swarm_query` / `swarm_store`, full memory CRUD, `curate` with explicit approve/reject review
- 18 LLM providers via Vercel `@ai-sdk/*` ecosystem
- **Git-like context tree** separate from memory (`.brv/` directory with `children-hash`, `derived-artifact`, `propagate-summaries`, `snapshot-diff`)
- MCP server via config-writers — generates configs so 22+ AI coding agents connect as MCP clients to `brv`

## [FalkorDB/FalkorDB](https://github.com/FalkorDB/FalkorDB)
*infra-layer · SSPL · [survey](FalkorDB__FalkorDB.md)*

First infra-layer entry — graph-database engine loaded as a Redis module (forked from RedisGraph after Redis Labs archived it).

- **Sparse-matrix adjacency representation + linear algebra over graphs** via [GraphBLAS](https://graphblas.org/) (bundled in `deps/`)
- **OpenCypher + Bolt protocol** so existing Neo4j drivers connect
- Multi-tenant via per-graph Redis-key namespacing; bundled RediSearch for graph-property text + vector indexing
- C engine + Rust core; 12 bundled deps (libcypher-parser / LAGraph / quickjs / utf8proc / xxHash)
- Used in production by [getzep/graphiti](getzep__graphiti.md) (1 of 4 graph backends) and [run-llama/llama_index](run-llama__llama_index.md) (`llama-index-graph-stores-falkordb`)
- First cohort entry on SSPL — restricts hosting providers from offering SaaS without open-sourcing surrounding infra

## [memgraph/memgraph](https://github.com/memgraph/memgraph)
*infra-layer · APL + BSL 1.1 + MEL · [survey](memgraph__memgraph.md)*

2nd infra-layer entry — Cypher-compatible in-memory graph database.

- **Single-query atomic retrieval** combining Tantivy (Rust full-text via FFI) + USearch (ANN library) + graph traversal in one Cypher statement (cohort first)
- Triple-licensed APL + BSL 1.1 + MEL — most layered cohort license stack; BSL 1.1 converts to Apache-2.0 after a few years
- C/C++ engine + NuRaft for HA consensus (ADR 002 documents adopting NuRaft after **3 in-house Raft attempts failed** — ~12 person-weeks of honest prior effort)
- RocksDB for disk persistence; Conan 2.x package management with 5 in-house dep forks
- Streaming sources via Kafka + Pulsar; **GPU graph algorithms via MAGE/cuGraph** (cohort first)
- **Cohort-first formal ADR practice** — 9 ADRs in `ADRs/` with structured Author/Status/Date/Problem/Criteria/Decision template
- Used by llama_index as `llama-index-graph-stores-memgraph` (1 of 7 graph_stores adapters)

## [AgriciDaniel/claude-obsidian](https://github.com/AgriciDaniel/claude-obsidian)
*wiki-compiler · MIT · [survey](AgriciDaniel__claude-obsidian.md)*

Claude Code plugin + Obsidian vault implementing [Andrej Karpathy's "LLM Wiki" pattern](https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f). The repo *is* the Obsidian vault — open in Obsidian directly.

- **No DB, no vector store** — pure Markdown filesystem with `wiki/` + `.raw/` + `.vault-meta/` folders
- **11 SKILL.md skills**: `autoresearch`, `canvas`, `defuddle`, `obsidian-bases`, `obsidian-markdown`, `save`, `wiki`, `wiki-fold`, `wiki-ingest`, `wiki-lint`, `wiki-query`
- **4-event hooks**: `SessionStart[startup|resume]` / `PostCompact` / `PostToolUse[Write|Edit]` / `Stop`
- **Hot cache primitive** — `wiki/hot.md` with `Last Updated` / `Key Recent Facts` / `Recent Changes` / `Active Threads` (≤500 words) read at session start, rewritten at session end
- Git auto-commits on every wiki write; cohort-first **`PostCompact` hook** explicitly handles Claude Code's context-compaction-loses-hook-state issue
- `[!contradiction]` callouts for sourced contradiction flagging; 8-category lint for wiki health; 3-round autoresearch with gap-filling

## [circlemind-ai/fast-graphrag](https://github.com/circlemind-ai/fast-graphrag)
*graphrag · MIT · [survey](circlemind-ai__fast-graphrag.md)*

circlemind.co's library-only GraphRAG (v0.0.5; stagnant since 2025-11 — commercial offering at circlemind.co may be where active dev moved).

- **Personalized PageRank as the primary retrieval primitive** — `igraph.personalized_pagerank(reset=query_entity_weights)` on a C-backed graph; sparse-matrix dot products cascade scores `entities → relationships → chunks`
- **Pickle-only persistence** in one `working_dir/` (`igraph_data.pklz` + `hnswlib` HNSW + pickled k/v + pickled blobs) — first cohort graphrag with zero external storage deps
- **Domain-priming as init contract** — `domain` + `example_queries` + `entity_types` (closed-set) are required `__init__` args injected into every extraction prompt
- Iterative "gleaning" loop — LLM self-checks `done`|`continue` after each extraction
- 4 ranking policies (`WithThreshold` default 0.005 / `TopK` / `Elbow` knee-detection / `WithConfidence` stub)
- Cost-anchored positioning: README headline `$0.08 vs $0.48 (6×)` vs microsoft/graphrag on Wizard of Oz; benchmarks in-tree
- No MCP, no memory layer, no service — pure embeddable library

## [plastic-labs/honcho](https://github.com/plastic-labs/honcho)
*memory-framework · AGPL-3.0 · [survey](plastic-labs__honcho.md)*

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

## [basicmachines-co/basic-memory](https://github.com/basicmachines-co/basic-memory)
*memory-framework · AGPL-3.0 · [survey](basicmachines-co__basic-memory.md)*

Local-first Zettelkasten + KG over markdown files — the cohort's only files-as-source-of-truth design.

- SQLite (default) or Postgres index with sqlite-vec + fastembed
- **Rule-based grammar** (no LLM extraction): `[category] observation` and `verb [[link]]`
- Bidirectional file ↔ DB sync via watchfiles
- Ships in Smithery's MCP catalog

---

← Back to [cohort map, adoption tables, and patterns](../README.md).
