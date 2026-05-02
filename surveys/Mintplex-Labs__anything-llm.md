# Mintplex-Labs/anything-llm

- **Stars:** 59,380 · **Last push:** 2026-05-02 · **Created:** 2023-06-04 · **License:** MIT · **Lang:** JavaScript / Node.js ≥18 · **Version:** 1.12.1
- **Category:** kb-app (workspace-scoped multi-LLM chat platform with built-in agent + MCP runtime)
- **Author:** Timothy Carambat (Mintplex Labs)

## TL;DR

Three-process Node.js workspace monorepo (`server/` Express+Prisma + `frontend/` React + `collector/` doc ingestion) that ships **37 LLM providers / 14 embedding engines / 10 vector backends** in-tree, plus **17 built-in Aibitat agent plugins**, **3 default agent skills**, and a **MCPHypervisor** that boots MCP servers under a singleton and converts each MCP server's tools into native Agent plugins (`@@mcp_{name}` namespace). SQLite by default (Prisma; PostgreSQL alternative is commented in [`server/prisma/schema.prisma`](https://github.com/Mintplex-Labs/anything-llm/blob/master/server/prisma/schema.prisma)). The **workspace** is the multi-tenant primitive — every document lives under a `workspace_documents` row scoped to a `workspaces` parent.

## KB Architecture

### Storage
- **Vector DB**: 10 in-tree backends in [`server/utils/vectorDbProviders/`](https://github.com/Mintplex-Labs/anything-llm/tree/master/server/utils/vectorDbProviders): `astra` / `chroma` / `chromacloud` / `lance` (default — pure-JS embeddable, no service) / `milvus` / `pgvector` / `pinecone` / `qdrant` / `weaviate` / `zilliz`. Selected via `VECTOR_DB` env var.
- **Metadata**: SQLite via Prisma (`storage/anythingllm.db`); the schema commented PostgreSQL block at the top of [`server/prisma/schema.prisma`](https://github.com/Mintplex-Labs/anything-llm/blob/master/server/prisma/schema.prisma) signals "swap one block to migrate" — no separate connector.
- **Blob / files**: filesystem under `storage/` (documents in `documents/`, originals in `hotdir/`).
- **No graph store** — knowledge stays as embedded chunks; no entity-extraction pipeline.

### Ingestion
- The **`collector/` is its own service** (separate process from the API server). Pipeline: `processSingleFile/` (8 file-format converters: `asAudio` / `asDocx` / `asEPub` / `asImage` / `asMbox` / `asOfficeMime` / `asPDF` / `asTxt` / `asXlsx`) + `processLink/` (URL fetch & convert) + `processRawText/` + `extensions/` (resync + custom plugins).
- Image/audio handlers route through OCR / Whisper-equivalent flows (provider-configurable).
- **Document sync queues** (`document_sync_queues` Prisma model) — watched documents trigger background re-ingest.
- **Workspace-scoped**: every chunk is namespaced to a workspace; cross-workspace isolation is the default tenant boundary.

### LLM + embedding + reranker integration
- **37 LLM providers** in [`server/utils/AiProviders/`](https://github.com/Mintplex-Labs/anything-llm/tree/master/server/utils/AiProviders) (most in cohort that bundle providers in-tree, vs llama_index's 104 separate packages): `anthropic` / `apipie` / `azureOpenAi` / `bedrock` / `cohere` / `cometapi` / `deepseek` / `dellProAiStudio` / `dockerModelRunner` / `fireworksAi` / `foundry` / `gemini` / `genericOpenAi` / `giteeai` / `groq` / `huggingface` / `koboldCPP` / `lemonade` / `liteLLM` / `lmStudio` / `localAi` / `mistral` / `modelMap` / `moonshotAi` / `novita` / `nvidiaNim` / `ollama` / `openAi` / `openRouter` / `perplexity` / `ppio` / `privatemode` / `sambanova` / `textGenWebUI` / `togetherAi` / `xai` / `zai`.
- **14 embedding engines** in [`server/utils/EmbeddingEngines/`](https://github.com/Mintplex-Labs/anything-llm/tree/master/server/utils/EmbeddingEngines): `azureOpenAi` / `cohere` / `gemini` / `genericOpenAi` / `lemonade` / `liteLLM` / `lmstudio` / `localAi` / `mistral` / `native` / `ollama` / `openAi` / `openRouter` / `voyageAi`. `native` ships an in-process embedder so a zero-API-key default works.
- **1 reranker**: `EmbeddingRerankers/native/index.js` — single in-tree reranker (vs cohort peers like ragflow's ~20 or mem0's 5). Rerankers were a late add and the surface is intentionally minimal.

### Aibitat agent runtime
- Custom in-house agent framework in [`server/utils/agents/aibitat/`](https://github.com/Mintplex-Labs/anything-llm/tree/master/server/utils/agents/aibitat) (NOT LangChain or LlamaIndex). 4 sub-dirs: `plugins/`, `providers/`, `utils/`, `example/`.
- **17 built-in plugins** in [`aibitat/plugins/`](https://github.com/Mintplex-Labs/anything-llm/tree/master/server/utils/agents/aibitat/plugins): `chat-history` / `cli` / `create-files` / `file-history` / `filesystem` / `gmail` / `google-calendar` / `http-socket` / `memory` / `outlook` / `rechart` / `sql-agent` / `summarize` / `web-browsing` / `web-scraping` / `websocket` (+ `index.js`).
- **3 default-enabled skills**: `memory`, `docSummarizer`, `webScraping` (declared in `defaults.js:DEFAULT_SKILLS`).
- **Skill-availability gating** — `defaults.js:SKILL_FILTER_CONFIG` defines per-skill `getAvailability()` checkers (e.g., `filesystem-agent` checks if the underlying tool is installed; `gmail-agent` checks Gmail OAuth bridge; `outlook-agent` checks Outlook bridge; `create-files-agent` checks fs writability). **Cohort-novel availability-aware skill loading** — skills disappear from the agent's tool list when their backing system isn't present, rather than failing at call time.

### Agent flows (workflow editor)
- [`server/utils/agentFlows/`](https://github.com/Mintplex-Labs/anything-llm/tree/master/server/utils/agentFlows) — visual no-code workflow builder. **3 executor types**: `api-call` / `llm-instruction` / `web-scraping`. Workflows are stored as imported manifests (`imported-manifest.schema.json`) and exposed as agent skills via `imported.js`.

### MCP — Hypervisor + plugin synthesis
- [`server/utils/MCP/`](https://github.com/Mintplex-Labs/anything-llm/tree/master/server/utils/MCP): `hypervisor.js` (`MCPHypervisor` base class — boot/shutdown lifecycle for configured MCP servers) + `index.js` (`MCPCompatibilityLayer extends MCPHypervisor`, **singleton**).
- `activeMCPServers()` returns flow names in `@@mcp_{name}` format (server-name namespace prefix).
- `convertServerToolsToPlugins(name, _aibitat)` — for each MCP server, list its tools, filter through `getSuppressedTools(name)` (per-server tool-disable list), and synthesize Aibitat plugin objects so MCP tools are first-class agent capabilities.
- **Different from cohort MCP patterns**: most cohort entries either *expose* an MCP server (claude-mem's 8 tools, WeKnora's 27 tools) or *consume* one (mem0's MCP plugin). anything-llm runs **multiple MCP servers internally** under a hypervisor and presents their union as the agent's tool list — closest analogue is byterover-cli's memory-router-as-product, but for tool-routing rather than memory-routing.

### Distribution breadth
- **6 cloud-deploy targets** under [`cloud-deployments/`](https://github.com/Mintplex-Labs/anything-llm/tree/master/cloud-deployments): `aws`, `gcp`, `openshift`, `helm`, `k8`, `huggingface-spaces` — most cohort deployment targets shipped in-tree.
- **Browser extension** ([`browser-extension/`](https://github.com/Mintplex-Labs/anything-llm/tree/master/browser-extension)).
- **Embeddable widget** ([`embed/`](https://github.com/Mintplex-Labs/anything-llm/tree/master/embed)).
- **Docker** with bare-metal docs ([`BARE_METAL.md`](https://github.com/Mintplex-Labs/anything-llm/blob/master/BARE_METAL.md)).
- **Telegram bot** ([`server/utils/telegramBot/`](https://github.com/Mintplex-Labs/anything-llm/tree/master/server/utils/telegramBot)).

## Notable design choices

- **Provider-bundled monorepo at the *application* tier** — anything-llm bundles 37 LLMs + 14 embedders + 10 vector DBs in-tree (vs llama_index's separately versioned 571 packages). Result: one `git pull` + `yarn setup` gets you everything; tradeoff is a much larger node_modules and slower release cadence per provider.
- **Workspace as the multi-tenant primitive, not user/agent** — `workspace_documents` is the join table; permissions/embedding scope/chat history all key off `workspaceId`. Closest cohort analogue is FastGPT's project model. Different from mem0/letta's user/agent scoping.
- **Aibitat (in-house) instead of LangChain** — the custom agent runtime keeps `aibitat/plugins/` as the integration boundary, so each plugin is a self-contained file. Lets the team avoid LangChain/LlamaIndex churn at the cost of reimplementing well-trodden patterns.
- **Skill-availability gating** — cohort first to make agent skills *disappear* from the tool list when their backing system isn't present (vs the more common "always advertise, fail at call time"). Pattern fits the "workspace owner toggles skills in UI" use case.
- **MCPHypervisor singleton** — multi-MCP-server boot under one process, with per-server tool suppression and `@@mcp_{name}` namespacing. The pattern would scale poorly past ~20 servers (singleton bottleneck), but for typical workspace setups (1-5 MCP servers) it's clean.
- **3-process architecture (server + collector + frontend)** — collector being a separate service means doc-ingest crashes don't take down the API; cohort peers (FastGPT, MaxKB, ragflow) similarly split, but anything-llm's collector is the most isolated (separate `package.json` + `yarn` install).

## Dependencies

Node.js ≥18 monorepo. `server/`: Express + Prisma + Winston + bcrypt + node-cron + adm-zip + various provider SDKs. `frontend/`: React + Vite + i18next (locale-aware). `collector/`: separate Node service with mime-detection + format-conversion deps (mammoth, pdf-parse, etc.). Prisma datasource defaults to SQLite; PostgreSQL alternative requires uncommenting two blocks + `yarn prisma:setup`.

## Tradeoffs

- **For**: largest in-tree LLM/embedding/vector provider matrix in the cohort (37 / 14 / 10); SQLite default = zero-infra to start; 6 cloud-deploy targets shipped (helm/k8/aws/gcp/openshift/huggingface-spaces); MCP hypervisor turns external MCP servers into first-class agent skills automatically; skill-availability gating gracefully degrades; workspace primitive is well-modeled in the schema; mature project (★59k, since 2023-06).
- **Against**: only **1 reranker** (`native`) — far behind ragflow / mem0 / khoj / WeKnora; no graph backend at all (cohort peers have at least one); custom Aibitat runtime means LangChain/LlamaIndex ecosystem improvements don't flow through; SQLite default scales poorly past ~10 concurrent users (Postgres swap requires ops work despite the schema comment); 37-provider matrix means provider-specific bug surface is large; collector being a separate process adds dev-environment friction.

## When to use vs. cohort

- vs. **labring/FastGPT** — both are workspace-scoped multi-LLM kb-apps with visual workflow builders. FastGPT is TypeScript + pgvector/Milvus/etc. + jieba+tiktoken hybrid retrieval + CJK-first; anything-llm is JavaScript + 10-vector-DB matrix + JS-native ingestion + Latin-first. FastGPT for CN-cloud + heavy workflows; anything-llm for "deploy anywhere with one repo".
- vs. **1Panel-dev/MaxKB** — MaxKB is Django + Postgres-only + 35-step workflow + Chinese-language extraction prompt + CN-cloud LLMs. anything-llm is Node + SQLite-default + simpler agent model + Latin-cloud LLMs. MaxKB for CN enterprises with Postgres-as-everything; anything-llm for international teams that want LanceDB-out-of-the-box.
- vs. **infiniflow/ragflow** — ragflow is doc-engine-heavy (per-format chunkers, deep document understanding, agent memory layer). anything-llm is provider-matrix-heavy (37 LLMs, 14 embedders) but doc-ingest is comparatively lightweight (8 generic format converters). Pick ragflow when document quality is the bottleneck; anything-llm when LLM-provider diversity is.
- vs. **khoj-ai/khoj** — khoj is search-first (cross-modal, Obsidian/Notion/Github sync) with self-hosted Postgres. anything-llm is workspace-chat-first with broader-but-shallower integrations.

## Code pointers

- LLM provider directory: [`server/utils/AiProviders/`](https://github.com/Mintplex-Labs/anything-llm/tree/master/server/utils/AiProviders) (37 sub-dirs).
- Vector DB factory: [`server/utils/vectorDbProviders/base.js`](https://github.com/Mintplex-Labs/anything-llm/blob/master/server/utils/vectorDbProviders/base.js) + 10 backend dirs.
- Embedding engines: [`server/utils/EmbeddingEngines/`](https://github.com/Mintplex-Labs/anything-llm/tree/master/server/utils/EmbeddingEngines) (14 sub-dirs).
- MCP hypervisor: [`server/utils/MCP/hypervisor.js`](https://github.com/Mintplex-Labs/anything-llm/blob/master/server/utils/MCP/hypervisor.js) + [`MCP/index.js`](https://github.com/Mintplex-Labs/anything-llm/blob/master/server/utils/MCP/index.js) (`MCPCompatibilityLayer.convertServerToolsToPlugins`).
- Aibitat plugins (17 built-in): [`server/utils/agents/aibitat/plugins/`](https://github.com/Mintplex-Labs/anything-llm/tree/master/server/utils/agents/aibitat/plugins).
- Default skills + availability config: [`server/utils/agents/defaults.js:9-35`](https://github.com/Mintplex-Labs/anything-llm/blob/master/server/utils/agents/defaults.js).
- Agent flow executors: [`server/utils/agentFlows/executors/`](https://github.com/Mintplex-Labs/anything-llm/tree/master/server/utils/agentFlows/executors) (api-call, llm-instruction, web-scraping).
- Prisma schema (with PostgreSQL swap comments): [`server/prisma/schema.prisma`](https://github.com/Mintplex-Labs/anything-llm/blob/master/server/prisma/schema.prisma).
- Document collector format converters: [`collector/processSingleFile/convert/`](https://github.com/Mintplex-Labs/anything-llm/tree/master/collector/processSingleFile/convert) (asAudio/asDocx/asEPub/asImage/asMbox/asOfficeMime/asPDF/asTxt/asXlsx).
- Cloud deployment templates: [`cloud-deployments/`](https://github.com/Mintplex-Labs/anything-llm/tree/master/cloud-deployments) (aws / gcp / openshift / helm / k8 / huggingface-spaces).

## Open questions

- The reranker tier ships **only `native`** — is the team treating reranker as out-of-scope or is BGE/Cohere/Voyage-rerank planned? (Cohort peers all ship 3+ reranker options.)
- Aibitat is in-house; how does maintenance burden compare to LangChain/LlamaIndex over time? Does the team backport popular framework features?
- MCPHypervisor uses a singleton `_instance` — what's the upper bound on concurrent MCP servers before the boot/shutdown lifecycle becomes a bottleneck?
- The `imported-manifest.schema.json` agent-flow format is its own DSL — is there import compatibility with LangFlow/Flowise/n8n flows, or is it standalone?

---

*Audit 2026-05-02: clone-verified against [Mintplex-Labs/anything-llm@master](https://github.com/Mintplex-Labs/anything-llm) (last commit 2026-05-02 00:56). Version 1.12.1 / MIT confirmed in `package.json`. Provider counts enumerated by directory: AiProviders=37 (verified by `ls -1 server/utils/AiProviders | wc -l`), EmbeddingEngines=14 (same method), vectorDbProviders=10 (excluding `base.js`), EmbeddingRerankers=1 (only `native/`). Aibitat plugins=17 (verified by `ls -1 server/utils/agents/aibitat/plugins | wc -l`, includes `index.js` aggregator). Default skills (memory, docSummarizer, webScraping) verified at `server/utils/agents/defaults.js:13`. Skill availability config (`SKILL_FILTER_CONFIG`) verified at `defaults.js:18-35` for filesystem-agent, create-files-agent, gmail-agent, outlook-agent. MCP hypervisor singleton + `convertServerToolsToPlugins` verified at `server/utils/MCP/index.js:1-65`. SQLite default + commented PostgreSQL swap verified at `server/prisma/schema.prisma:1-17`. Collector converters enumerated from `collector/processSingleFile/convert/`. 6 cloud-deploy targets verified by `ls cloud-deployments/`. Corrections: none (first-pass survey).*
