<h1 align="center">🧠 Awesome Agentic Knowledge Base</h1>

<p align="center">
  An empirical map of knowledge base systems in top AI agents. Components are code-verified from high-star GitHub repositories and ranked strictly by actual adoption frequency, not vendor claims.
</p>

> *Living document — manually verified, contributions welcome.*

## TL;DR — what 46 trending open-source ai-agent repos actually use

- 20 of 46 (43%) use LLM-based entity extraction — but **4 ship serviceable KBs without any LLM cost** (basic-memory, aider, memvid, code-review-graph)
- 18 of 46 expose MCP servers, 17 are clients — **9 intentionally avoid MCP** (all libraries / pipelines / plugins / infra)
- Postgres leads metadata, pgvector leads vector backends, Redis is the default cache — full breakdown in [Adoption — Storage](#adoption--storage)
- 12 repos use no graph at all — **in-process NetworkX is more common than Neo4j**
- "No DB at all" is now its own camp — **5 repos, 5 different shapes** (from `.json` files to a single `.mv2` binary to Obsidian vaults)
- License hardens with deployment shape: **library → product → infra mirrors MIT → AGPL → ELv2/SSPL**

> Numbers are cohort-wide (n=46) unless noted. Adoption tables below switch to role-conditional denominators (e.g. `n=39` for vector adopters). Every claim links to an individual repo survey under [`surveys/`](./surveys/).

## Open-source repos

46 trending open-source ai-agent repos (the **cohort**), sorted by GitHub star count. **kb-app is the largest category (15 repos)**, followed by memory-framework (12), wiki-compiler (6), coding-agent (5), graphrag (3), infra-layer (3), and kb-framework (2: llama_index + haystack) — both downstream aggregators of much of the rest of the cohort.

**Categories**

- `kb-app` — deployable KB product end-users / admins run as a service
- `memory-framework` — library specialized for agent memory (`pip` / `npm install`)
- `wiki-compiler` — code or docs → human-readable wiki
- `coding-agent` — IDE-side agent harness with its own KB
- `graphrag` — LLM-extracted KG + retrieval, library-shaped
- `infra-layer` — DB / federation engine other agents consume
- `kb-framework` — general-purpose RAG/agent aggregator (llama_index, haystack)

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
| [deepset-ai/haystack](https://github.com/deepset-ai/haystack) | kb-framework | Component-pipeline RAG framework; 24 component categories + 50+ vector-backend sibling packages ([survey](surveys/deepset-ai__haystack.md)) |
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

## Patterns observed

These are cohort-wide patterns the surveys surfaced. Each top-level bullet leads with the one-line takeaway; sub-bullets give the supporting evidence and edge cases.

### Storage and licensing

- **MCP server adoption (39%) edges out client (37%).** Server in 18/46 repos, client in 17.
  - Nine repos run no MCP at all: aider, LightRAG, graphrag, memvid, Understand-Anything, FalkorDB, deepwiki-open, memU, claude-obsidian.
  - Common shape: all are libraries, pipelines, plugins, or infra-class.
  - **Pattern hardening:** products run MCP; libraries / plugins / pipelines don't.
  - anything-llm surfaces a 3rd MCP role — *host* — distinct from server and client (see "MCP role types" below).

- **Postgres dominates metadata; pgvector leads vector backends; "no DB at all" is now its own camp.**
  - Numbers: Postgres 14/41 (34%, of repos with a metadata DB), SQLite 9/41 (22%), pgvector 7/39 (18%, of repos with a vector store), OpenSearch 5/39 (13%).
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

- **Mechanical (non-LLM) extraction works** — useful counter-example to the "more LLM = more quality" assumption. **4/46 cohort entries** ship serviceable KBs without LLM cost:
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

## Adoption — Storage

Storage breaks down into seven roles. **Vector stores** dominate the cohort (only 7 repos run none); **Postgres and SQLite** dominate metadata; **Redis** is the standard cache; **S3-compatible blob storage** is universal among production-shaped kb-apps. **Graph storage** stays niche — most cohort repos either skip graphs entirely or run an in-process NetworkX. **Embedders** are split between local sentence-transformers and cloud APIs. A small but distinctive **Markdown-filesystem camp** treats `.md` files as the primary KB substrate (sometimes with a derived DB index, sometimes with no DB at all).

### Vector store (n=39)

| Component | Used by | Adoption | Trade-offs |
|---|---|---|---|
| pgvector | mem0, FastGPT, cognee, khoj, MaxKB, WeKnora, letta | 18% | Postgres-stack ops; cohort's most-adopted vector backend |
| Milvus | mem0, FastGPT, LightRAG, WeKnora, MemOS | 13% | mature pure-vector engine, separate service |
| OpenSearch | ragflow, mem0, graphiti, LightRAG, onyx | 13% | strong full-text + vector, JVM ops |
| Faiss | mem0, LightRAG, AstrBot, deepwiki-open | 10% | embeddable C++ library, search-only |
| Qdrant | mem0, LightRAG, WeKnora, MemOS | 10% | Rust + good filtering, separate service |
| ChromaDB | mem0, cognee, claude-mem (via stdio MCP) | 8% | embeddable; claude-mem skips the npm package by going stdio-MCP |
| Elasticsearch | ragflow, mem0, WeKnora | 8% | mature hybrid search, JVM ops |
| Pinecone | mem0, letta | 5% | managed serverless vector DB |
| Turbopuffer | mem0, letta | 5% | serverless vector with per-namespace isolation |
| SQLite-FTS5 + optional vectors | basic-memory, code-review-graph | 5% | minimum-viable hybrid search inside one SQLite file |
| LanceDB | cognee, graphrag (default) | 5% | embedded columnar; ships as the GraphRAG default |
| Azure AI Search | mem0, graphrag | 5% | hosted hybrid retrieval, vendor-tied |
| Weaviate | mem0, WeKnora | 5% | graph-aware vector with native multi-tenancy |
| sqlite-vec | basic-memory, WeKnora | 5% | embedded vector for SQLite |

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

### Graph store (n=34)

| Component | Used by | Adoption | Trade-offs |
|---|---|---|---|
| Neo4j | graphiti, cognee, LightRAG, WeKnora, MemOS | 15% | mature Cypher + vector index, heavy ops |
| NetworkX (in-process) | ragflow, LightRAG, graphrag, haystack | 12% | zero-ops |
| Kuzu | graphiti, cognee | 6% | embeddable, smaller community |
| AWS Neptune | graphiti, cognee | 6% | managed + AWS-native; vendor-lock |

**No graph at all** — 12 repos: mem0 (graph removed in v3 — built-in entity linking instead), FastGPT, basic-memory, OpenHands, claude-mem, cline, aider, khoj, AstrBot, MaxKB, deepwiki-open, deer-flow.

**Singletons** (1 repo only):

- LightRAG — Memgraph (mem0 removed it in v3)
- graphiti — FalkorDB
- onyx — Postgres-as-graph
- memvid — Logic-Mesh in-`.mv2`-file
- Understand-Anything — `knowledge-graph.json` with 35 typed edges
- MemOS — PolarDB
- code-review-graph — SQLite-backed graph with BFS impact analysis + Leiden community detection (cohort second after graphrag)

### Metadata / structured store (n=41)

| Component | Used by | Adoption | Trade-offs |
|---|---|---|---|
| Postgres | mem0, FastGPT, cognee, basic-memory, OpenHands, LightRAG, khoj, onyx, MaxKB, WeKnora, MemOS, deer-flow (opt-in), letta, memU | 34% | de-facto cohort default for ops-grade metadata |
| SQLite | cognee, basic-memory, claude-mem, aider (diskcache), AstrBot, WeKnora, deer-flow, code-review-graph, memU | 22% | embedded, zero-ops; single-machine ceiling |
| MongoDB | FastGPT, LightRAG | 5% | document-store; rich querying |
| MySQL | ragflow, MemOS | 5% | CN-cloud-friendly metadata store |

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

### Cache / queue (n=46)

| Component | Used by | Adoption | Trade-offs |
|---|---|---|---|
| Redis / Valkey | ragflow, FastGPT, cognee, OpenHands, LightRAG, onyx, MaxKB, WeKnora | 17% | ubiquitous, adds another service |

**Singletons** (1 repo only):

- graphrag — file-backed pipeline cache
- AstrBot — in-process BM25 cache
- onyx — dedicated Celery worker fleet
- MaxKB — APScheduler memory triggers
- memvid — embedded WAL inside `.mv2`
- WeKnora — `hibiken/asynq` Go-native job queue + `panjf2000/ants` goroutine pool
- Understand-Anything — `PostToolUse` hook on git commits + `SessionStart` staleness check via `.understand-anything/meta.json:gitCommitHash` vs `git rev-parse HEAD`

### Blob + Embedder

**Blob storage (n=46)**

| Backend | Used by | Adoption |
|---|---|---|
| S3-compatible | ragflow, FastGPT, OpenHands, onyx, WeKnora | 11% |
| MinIO (explicit) | ragflow, FastGPT, onyx, WeKnora | 9% |

**Singletons / notable:**

- Azure Blob Storage — graphrag
- 6-backend blob factory (COS / OSS / TOS / MinIO / S3 / local) — WeKnora

**Embedders (n=39)**

| Pattern | Used by | Adoption |
|---|---|---|
| sentence-transformers local (bi-encoder + cross-encoder) | ragflow, mem0, graphiti, khoj, onyx, MaxKB, WeKnora | 18% |
| fastembed local ONNX | cognee, basic-memory | 5% |

**Singletons / notable:**

- ONNX + CLIP + Whisper with shipped mel-filterbank bytes — memvid
- Embeddings stored as `number[]` arrays directly on graph-node JSON records + 15-line vanilla-JS cosine similarity — Understand-Anything

## Adoption — Ingestion / Extraction (n=46)

**LLM-based entity / fact extraction is the cohort default at 43%**, but mechanical (non-LLM) extraction is a real counter-current — basic-memory, aider, memvid, and code-review-graph all ship serviceable KBs without any LLM cost. The cohort splits roughly evenly between "agent ingests documents" (33%) and "agent ingests conversations / sessions" (33%), with tree-sitter-based code awareness as the most common specialized track.

| Pattern | Used by | Adoption | Trade-offs |
|---|---|---|---|
| LLM-based entity / fact extraction | ragflow, mem0, graphiti, cognee, claude-mem, LightRAG, khoj, graphrag, onyx, MaxKB, WeKnora, Understand-Anything, MemOS, byterover-cli, deer-flow, haystack, OpenViking, deepwiki-open, memU, claude-obsidian (Claude reads source → extracts entities/concepts → wikilinked Obsidian Markdown pages) | 43% | quality high, cost scales with corpus / turns |
| Document inputs (PDF / DOCX / MD …) | ragflow, FastGPT, cognee, basic-memory, LightRAG, khoj, graphrag, AstrBot, onyx, MaxKB, memvid, WeKnora, haystack, OpenViking, letta | 33% | broad source coverage, may need OCR/layout |
| Per-format / specialized chunking | ragflow, FastGPT, cognee, graphrag, AstrBot, onyx, MaxKB, memvid, WeKnora, Understand-Anything, haystack | 24% | strong on document variety, more code surface |
| Conversation / episode / session inputs | ragflow, mem0, graphiti, cognee, OpenHands, claude-mem, khoj, MaxKB, WeKnora, MemOS, byterover-cli, deer-flow, OpenViking, letta, memU | 33% | hands-off DX for agent memory |
| Tree-sitter for code awareness | claude-mem, cline, aider, Understand-Anything, code-review-graph (32 languages incl. Vue SFC, Solidity, Dart, R, Perl, Lua, Jupyter / Databricks notebooks) | 11% | language-aware extraction |
| Hand-curated markdown KB (rules / notes / microagents) | basic-memory, OpenHands, cline | 7% | git-friendly, debuggable |
| Mechanical (non-LLM) extraction at build time + LLM at query time | basic-memory, aider, memvid, code-review-graph (tree-sitter parses produce all structural nodes; LLM is only invoked at query time, not extraction) | 9% | predictable, free, deterministic; misses semantic nuance |

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

**Hybrid BM25 + dense is the cohort's baseline retrieval shape (28% of cohort)**; graph-traversal retrieval reaches 26% as graphRAG patterns mature. Reranker adoption is dense *within* the 11 repos that ship any reranker (≈73% adopt a pluggable provider abstraction; ≈82% offer HuggingFace / sentence-transformer rerankers) but only 11/46 of the cohort ships rerankers at all.

### Retrieval pattern (n=46)

| Pattern | Used by | Adoption | Trade-offs |
|---|---|---|---|
| Hybrid BM25 + dense | ragflow, mem0, FastGPT, graphiti, basic-memory, claude-mem, AstrBot, onyx, MaxKB, memvid, WeKnora, haystack, code-review-graph (FTS5 keyword + optional sentence-transformers/Gemini/MiniMax embeddings) | 28% | text-search floor; khoj/cognee/graphrag use vector / vector+graph instead |
| Graph-traversal retrieval (incl. BFS / directory-recursive / multi-hop) | ragflow, mem0, graphiti, cognee, basic-memory, graphrag, memvid, WeKnora, Understand-Anything, MemOS, OpenViking, code-review-graph (BFS impact analysis + Leiden communities) | 26% | richer multi-hop |

### Reranker (n=11)

Universe = repos that ship any reranker: ragflow, mem0, graphiti, FastGPT, AstrBot, onyx, MaxKB, WeKnora, MemOS, haystack, khoj.

| Component | Used by | Adoption | Trade-offs |
|---|---|---|---|
| HuggingFace / sentence-transformer reranker | ragflow, mem0, graphiti, khoj, onyx, MaxKB, WeKnora, MemOS, haystack | 82% | self-host friendly, slower than API |
| Pluggable rerank-provider abstraction (vendor-agnostic) | ragflow, mem0, FastGPT, AstrBot, onyx, MaxKB, WeKnora, haystack | 73% | one config knob covers many backends; trades depth for breadth |
| Cohere reranker (explicit) | ragflow, mem0, onyx, MaxKB | 36% | strong default, paid API |
| BGE reranker (explicit) | mem0, graphiti | 18% | open-weight strong reranker |
| LLM-as-reranker | mem0, graphiti | 18% | great quality, latency-heavy |

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

## Adoption — Memory model (n=46)

**Self-update on every input dominates (41%)**, with auto-structured memory close behind (35%) — the cohort default is "always-fresh, write-amplification". Cross-session memory is universal in memory-frameworks but absent in 6 cohort repos (cline, aider, graphrag, haystack, deepwiki-open, code-review-graph) that treat each session as cold.

| Pattern | Used by | Adoption | Trade-offs |
|---|---|---|---|
| Self-update on each input | ragflow, mem0, graphiti, cognee, basic-memory, claude-mem, khoj, onyx, MaxKB, WeKnora, Understand-Anything, MemOS, byterover-cli, deer-flow, OpenViking, letta, code-review-graph, memU, claude-obsidian (4-event hooks: SessionStart / PostCompact / PostToolUse[Write\|Edit] / Stop, with hot-cache rewrite + git auto-commit) | 41% | always-fresh, write-amplification |
| Auto-structured memory from inputs | ragflow, mem0, graphiti, cognee, basic-memory, claude-mem, khoj, onyx, MaxKB, memvid, Understand-Anything, MemOS, deer-flow, OpenViking, letta, memU | 35% | hands-off DX |
| Hand-authored rules / skill / microagent files | basic-memory, OpenHands, cline, AstrBot, WeKnora, Understand-Anything, byterover-cli, deer-flow, claude-obsidian (11 SKILL.md files following Claude Code's plugin spec) | 20% | git-friendly, predictable; doesn't scale without curation |
| AGPL-3.0-or-later license | basic-memory, OpenHands, claude-mem, khoj, AstrBot, OpenViking | 13% | aggressive copyleft; ship-to-end-user pattern |
| Two-tier KB + agent-memory split | ragflow, khoj | 4% | per-corpus retrieval separated from per-user memory |
| Human-in-the-loop policy/strategy/interface as a typed framework subsystem | byterover-cli (curate workflow), haystack | 4% | rare in cohort; haystack ships the most explicit HITL primitives |
| No cross-session memory at all | cline, aider, graphrag, haystack, deepwiki-open, code-review-graph | 13% | session-cold each time; users supply context explicitly |
| Temporal awareness in memory | graphiti, cognee, memvid | 7% | enables "as-of-date" queries; complex to implement |

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

**MCP is mainstream among production-shaped repos** — 39% expose servers, 37% are clients, with 20% staying protocol-neutral. **SDK choice splits cleanly along language lines:** FastMCP dominates Python stacks, `@modelcontextprotocol/sdk` dominates TypeScript/Bun stacks. The "no MCP" camp is structurally distinct — every entry is a library, pipeline, plugin, or infra-class repo, not a deployable product.

### Role type (n=46)

| Role | Used by | Adoption | Trade-offs |
|---|---|---|---|
| MCP server exposed | ragflow, mem0, FastGPT, graphiti, cognee, basic-memory, OpenHands, claude-mem, onyx, MaxKB, WeKnora, MemOS, byterover-cli, deer-flow, haystack, OpenViking, letta, code-review-graph | 39% | drop-in for Claude Code / Cursor / Codex / Desktop |
| MCP client used | ragflow, mem0, FastGPT, cognee, OpenHands, claude-mem, cline, khoj, AstrBot, onyx, MaxKB, WeKnora, byterover-cli, deer-flow, haystack, OpenViking, letta | 37% | outbound tool use; near-universal among production-shaped repos |
| No MCP at all | aider, LightRAG, graphrag, memvid, Understand-Anything, FalkorDB, deepwiki-open, memU, claude-obsidian | 20% | library/pipeline/plugin/infra-class — intentionally protocol-neutral; claude-obsidian uses Claude Code's native skill/agent/hook surface instead |

### SDK / framework (n=37)

Universe = repos that ship any MCP integration (= 46 − 9 no-MCP).

| SDK | Used by | Adoption | Trade-offs |
|---|---|---|---|
| **FastMCP** (Python, Pydantic-backed) | OpenHands, basic-memory, MaxKB, MemOS, onyx, DocsGPT, code-review-graph, hindsight | 22% | dominant Python MCP SDK in cohort |
| **`@modelcontextprotocol/sdk`** (TS/JS) | claude-mem, cline, FastGPT, sim, byterover-cli, context-mode, honcho | 19% | dominant TS/Bun MCP SDK in cohort |
| **PydanticAI** agent runtime | mindsdb, hindsight | 5% | typed sub-agents + output validation; cohort-novel "Pydantic-shaped Python agentic stack" |

**SDK singletons:**

- WeKnora — vanilla `mcp.server.stdio` Python SDK (separate `mcp-server/` project) + `mark3labs/mcp-go` (Go client) — cohort's only Go MCP user
- MaxKB — uniquely **runtime-synthesizes FastMCP per user-authored Python tool** via `ast` rewriting (every tool gets its own ad-hoc `FastMCP(uuid)` module)

### Distribution / install targets (n=46)

| Mechanism | Used by | Adoption | Notes |
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

## Adoption — Observability / Eval (n=46)

**Production agentic stacks default to LLM-tracing-and-metrics tools (Langfuse + OpenTelemetry + Prometheus + Sentry) rather than RAG-specific eval frameworks.** The legacy "RAG evaluation" reference set (RAGAS, Phoenix/Arize, Inspect AI, Promptfoo, TruLens) is conspicuously absent — surveyed cohort entries either ship in-tree benchmark harnesses or skip formal eval entirely.

| Tool | Used by | Adoption | Trade-offs |
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

## Surveyed repos

Per-repo summaries split out into [`surveys/README.md`](surveys/README.md) — one section per repo, keeps this map focused on cohort-wide patterns and lets the per-repo writeups grow without page-bloat.

Each survey file under [`surveys/`](surveys/) is the source of truth for that repo (TL;DR, architecture, KB internals, dependencies, audit trail).

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
