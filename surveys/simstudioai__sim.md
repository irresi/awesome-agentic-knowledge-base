# simstudioai/sim

- **Stars:** 28,199 · **Last push:** 2026-05-02 · **Created:** 2025-01-05 · **License:** Apache-2.0 · **Lang:** TypeScript (Bun) · **Workspaces:** 16 packages + 3 apps
- **Category:** kb-app (visual workflow builder + KB + agent + MCP runtime)
- **Tagline:** "Build, deploy, and orchestrate AI agents. Sim is the central intelligence layer for your AI workforce."

## TL;DR

A Bun-managed Next.js 15 + Drizzle + Postgres workflow platform whose architectural ambition is to be the **central runtime layer** for both agents and the KB they query. Ships **35 connectors / 220 tools / 17 LLM providers / 227 workflow blocks / 7 chunkers / 11 file parsers** in-tree, plus the cohort's most sophisticated **MCP stack** — `client.ts` negotiates 3 MCP versions (`2024-11-05` / `2025-03-26` / `2025-06-18`) with OAuth 2.1 + elicitation support, ships a custom `McpSecurityPolicy` + `McpConsentRequest` consent layer, and **`workflow-mcp-sync.ts` deploys workflows AS MCP servers** (auto-generates JSON Schema from workflow input blocks). Apache-2.0 with explicit `apps/sim/ee/` (Enterprise) tier under separate `LICENSE` covering access-control / audit-logs / data-retention / SSO / whitelabeling.

## KB Architecture

### Storage
- **Vector / KB**: Workspace-scoped `knowledgeBase` table (Drizzle schema in `@sim/db`); per-KB stored `embeddingModel`, `embeddingDimension`, `chunkingConfig`. Documents linked via `document.knowledgeBaseId`. **Per-KB embedding model** — useful for multi-model orgs.
- **Default embedding**: OpenAI `text-embedding-3-*` (default dimension `1536`); supports custom dimensions per `supportsCustomDimensions(modelName)` heuristic. BYOK keys via `getBYOKKey`.
- **Metadata**: Postgres via Drizzle ORM with explicit `@sim/db` package; Helm chart in `helm/sim/` for Kubernetes deployment.
- **Cache**: MCP cache adapter (`memory-cache.ts` or `redis-cache.ts` per `getMcpCacheType()`); Redis for rate limiting.

### Ingestion (most decomposed chunker surface in cohort)
- **7 chunker types** in [`apps/sim/lib/chunkers/`](https://github.com/simstudioai/sim/tree/main/apps/sim/lib/chunkers): `docs-chunker`, `json-yaml-chunker`, `recursive-chunker`, `regex-chunker`, `sentence-chunker`, `structured-data-chunker`, `text-chunker`, `token-chunker` — each with paired `*.test.ts`. Most explicit chunker decomposition in the cohort (vs cohort peers that ship 1-2 chunker functions).
- **11 file parsers** in [`apps/sim/lib/file-parsers/`](https://github.com/simstudioai/sim/tree/main/apps/sim/lib/file-parsers): `csv`, `doc`, `docx`, `html`, `json`, `md`, `pdf`, `pptx`, `txt`, `xlsx`, `yaml`. Indexed via `index.ts` registry.
- **Embedding batching**: `MAX_TOKENS_PER_REQUEST = 8000`, `MAX_CONCURRENT_BATCHES = env.KB_CONFIG_CONCURRENCY_LIMIT || 50`. Retryable-error detection + exponential backoff in `documents/utils.ts`.

### Workflow-as-runtime (the central architectural bet)
- [`apps/sim/blocks/blocks/`](https://github.com/simstudioai/sim/tree/main/apps/sim/blocks/blocks): **227 workflow blocks**, each a single `.ts` file (one per integration tool/provider). Examples: `agent.ts`, `api.ts`, `api_trigger.ts`, plus per-app blocks (airtable, asana, attio, …).
- [`apps/sim/lib/executor/`](https://github.com/simstudioai/sim/tree/main/apps/sim/lib/executor): `dag/` + `execution/` + `handlers/` + `human-in-the-loop/` + `orchestrators/` + `variables/` — full DAG executor with HITL support.
- [`apps/sim/triggers/`](https://github.com/simstudioai/sim/tree/main/apps/sim/triggers): 20+ trigger types (`gmail`, `gong`, `google-calendar`, `google-drive`, `googleforms`, `circleback`, `confluence`, `airtable`, `attio`, `calendly`, `fireflies`, …).
- [`apps/sim/connectors/`](https://github.com/simstudioai/sim/tree/main/apps/sim/connectors): 35 OAuth-shaped 3rd-party app connectors (Notion / Linear / Jira / GitHub / Airtable / GoogleDocs / GoogleSheets / GoogleDrive / GoogleCalendar / Microsoft Teams / OneDrive / Discord / HubSpot / Intercom / Zendesk / Webflow / WordPress / Evernote / Fireflies / etc.).
- [`apps/sim/tools/`](https://github.com/simstudioai/sim/tree/main/apps/sim/tools): **220 tool files** (`a2a`, `airweave`, `algolia`, `apify`, `arxiv`, `asana`, …) — per-tool implementations.

### LLM + agent
- **17 LLM providers** in [`apps/sim/providers/`](https://github.com/simstudioai/sim/tree/main/apps/sim/providers): `anthropic`, `azure-anthropic`, `azure-openai`, `bedrock`, `cerebras`, `deepseek`, `fireworks`, `gemini`, `google`, `groq`, `mistral`, `ollama`, `openai`, `openrouter`, `vertex`, `vllm`, `xai`. **Specialized `azure-anthropic`** (cohort-novel — most cohort entries treat Anthropic as one provider, not Azure-deployed Anthropic separately).
- [`apps/sim/lib/copilot/`](https://github.com/simstudioai/sim/tree/main/apps/sim/lib/copilot): separate **copilot subsystem** with `async-runs/`, `chat/`, `tool-executor/` (executor.ts, register-handlers.ts, router.ts), `vfs/` (virtual filesystem), `tools/` (client / handlers / mcp / registry / server / shared / workflow-tools.ts).
- `.agents/skills/` ships **14 internal agent skills** for self-modifying tasks: `add-block`, `add-connector`, `add-integration`, `add-tools`, `add-trigger`, `validate-integration`, `validate-trigger`, `validate-connector`, `cleanup`, `you-might-not-need-state`, `you-might-not-need-an-effect`, `react-query-best-practices`, `emcn-design-review`. **Cohort-first explicit "agent skills as project meta-tooling"** — the agent's skills target *the project itself*, not user workflows.

### MCP — most sophisticated stack in cohort
- [`apps/sim/lib/mcp/`](https://github.com/simstudioai/sim/tree/main/apps/sim/lib/mcp) — full MCP client + service + connection-manager + storage-cache.
- **3-version MCP protocol negotiation** (`SUPPORTED_VERSIONS = ['2025-06-18', '2025-03-26', '2024-11-05']`) — most cohort entries pin one MCP SDK version; sim explicitly negotiates across the 3 official protocol versions.
- **OAuth 2.1 + elicitation** support (per the `2025-06-18` version comment "Latest stable with elicitation and OAuth 2.1").
- **Custom MCP security/consent layer**: `McpSecurityPolicy`, `McpConsentRequest`, `McpConsentResponse` types. Pre-call domain validation via `validateMcpDomain` + `isMcpDomainAllowed` + `validateMcpServerSsrf` (SSRF guards). Cohort first to ship explicit MCP consent + SSRF protection.
- **Workflows-as-MCP-servers** — [`workflow-mcp-sync.ts`](https://github.com/simstudioai/sim/blob/main/apps/sim/lib/mcp/workflow-mcp-sync.ts): `generateSchemaFromBlocks` + `generateToolInputSchema` derive a JSON Schema from a workflow's start-block input format, then `loadDeployedWorkflowState` syncs deployed workflows into `workflowMcpServer` + `workflowMcpTool` Drizzle tables. Cohort first to **persist workflow-as-MCP deployments** (llama_index has the per-call helper `workflow_as_mcp`, but sim does background sync + DB persistence).
- Pluggable MCP transports: `StreamableHTTPClientTransport` (others available via `@modelcontextprotocol/sdk`).
- `pubsub.ts` for MCP cache invalidation across the realtime worker.

### Guardrails
- [`apps/sim/lib/guardrails/`](https://github.com/simstudioai/sim/tree/main/apps/sim/lib/guardrails): `validate_hallucination.ts`, `validate_json.ts`, `validate_pii.ts`, `validate_pii.py` (Python!), `validate_regex.ts`. **Cohort-first cross-language guardrail surface** — Python implementation of PII validation lives alongside the TS one (different deployment options).

### Realtime / multi-app
- 3 apps: `apps/sim` (Next.js main), `apps/realtime` (separate WebSocket server, run via `bun run dev:sockets`), `apps/docs` (docs site).
- 16 internal packages in `packages/`: `db` (Drizzle), `auth`, `cli`, `python-sdk`, `ts-sdk`, `security`, `audit`, `realtime-protocol`, `workflow-types`, `workflow-persistence`, `workflow-authz`, `logger`, `utils`, `tsconfig`, `testing`.
- Bun as package manager (cohort-rare — most cohort TS/JS entries use npm or pnpm). `biome.json` for linting (not Eslint).

### Enterprise tier
- [`apps/sim/ee/`](https://github.com/simstudioai/sim/tree/main/apps/sim/ee) under separate `LICENSE` (similar pattern to onyx-dot-app/onyx's `ee/` split): `access-control`, `audit-logs`, `data-retention`, `sso`, `whitelabeling`.

## Notable design choices

- **Workflow-as-MCP-server with DB persistence** — the workflow IS the MCP tool. `workflow-mcp-sync.ts` keeps `workflowMcpServer` + `workflowMcpTool` Drizzle tables in sync with deployed workflows; once you deploy a workflow with input blocks, it's instantly callable from any MCP client. Cohort first to persist the workflow-as-MCP mapping in DB (vs llama_index's per-call helper).
- **3-version MCP protocol negotiation** — most cohort entries support one MCP SDK version. sim negotiates across `2024-11-05` / `2025-03-26` / `2025-06-18` — the cohort's most resilient MCP client to upstream protocol churn.
- **Custom MCP consent + SSRF guards** — `McpSecurityPolicy` + `McpConsentRequest` types. Pre-call `validateMcpDomain` + `validateMcpServerSsrf`. Cohort first to ship explicit MCP-consent UX hooks + SSRF protection.
- **Workspace + per-KB embedding model + chunking config** — each `knowledgeBase` row stores its own `embeddingModel`, `embeddingDimension`, `chunkingConfig`. Multi-tenant with per-KB ingestion-pipeline customization.
- **7 chunker types with paired tests** — most decomposed chunker surface in cohort. Each chunker is a single named strategy with its own test file.
- **17 LLM providers including specialized `azure-anthropic`** — cohort-novel split (most cohort entries lump Anthropic-via-Azure into the generic Anthropic provider).
- **Cross-language guardrails (TS + Python)** — `validate_pii.py` lives alongside `validate_pii.ts` in the same directory. Cohort first to ship multi-language validation.
- **Self-modifying agent skills** — `.agents/skills/{add-block,add-connector,add-integration,add-tools,add-trigger,validate-*,cleanup,...}` — the agent skills target *the project itself*, used by humans + Claude/Cursor/Copilot to extend sim. Cohort-first "agent skills as project meta-tooling".
- **Bun + Biome instead of npm + ESLint** — cohort-rare TS toolchain (only honcho's `mcp/` sub-package also uses Bun).
- **Enterprise tier in `ee/` with separate LICENSE** — same split pattern as onyx; recurring cohort pattern for "MIT/Apache core + commercial-license enterprise features".

## Dependencies

`apps/sim`: Next.js 15 + React + Drizzle + Postgres + Redis. `@modelcontextprotocol/sdk` (MCP). Provider SDKs (Anthropic, OpenAI, Vertex, Bedrock, Mistral, etc.). `apps/realtime`: separate WebSocket service. `apps/docs`: docs site. Internal packages: `@sim/db`, `@sim/auth`, `@sim/cli`, `@sim/{python,ts}-sdk`, `@sim/security`, `@sim/audit`, `@sim/realtime-protocol`, `@sim/workflow-{types,persistence,authz}`. `bun@1.3.13` package manager. `biome` linter. `turbo` monorepo runner.

## Tradeoffs

- **For**: cohort-first **workflow-as-MCP-server with DB persistence** + **3-version MCP negotiation** + **MCP consent/SSRF guards** + **cross-language guardrails** (TS + Python); broadest workflow integration set in cohort (35 connectors / 220 tools / 227 blocks / 17 LLM providers); per-KB embedding model + chunking config; 7-chunker decomposition with paired tests; self-modifying agent skills (`.agents/skills/`); separate realtime app for WebSocket workloads; Helm chart for Kubernetes; Enterprise tier already split (`ee/` + separate LICENSE).
- **Against**: large surface area = large maintenance burden (16 internal packages × 3 apps × 220 tools × 227 blocks × 35 connectors); Bun as required runtime (no npm fallback documented); no graph store / no GraphRAG; only **1 reranker capability** (no dedicated reranker registry like ragflow); `apps/sim/ee/` Enterprise tier under separate license = mixed-license repo (consumers need to verify they don't pull `ee/` code); 17 LLM providers means provider-specific bugs are likely; visual workflow builder UI is in `apps/sim/app/` — the value depends on how good the React frontend is, not just the backend.

## When to use vs. cohort

- vs. **Mintplex-Labs/anything-llm** — both are workspace-scoped multi-LLM kb-apps with built-in agent + MCP. anything-llm: 37 LLM providers / 14 embedders / 10 vector backends in JS, Aibitat in-house agent runtime, MCP hypervisor pattern. sim: 17 LLM providers / 1 embedding shape (OpenAI-compatible) / Postgres-only KB store, Drizzle-typed workspace primitive, MCP with consent + workflows-as-MCP. anything-llm for "deploy anywhere with one repo + 10 vector backends"; sim for "deploy workflows as MCP servers with explicit consent + Enterprise tier".
- vs. **labring/FastGPT** — both are visual-workflow + RAG apps. FastGPT is CN-cloud-tilted (Bailian / Volcengine / Wenxin / Zhipu). sim is US-cloud-tilted with Bedrock / Vertex / Cerebras / Fireworks + specialized Azure-Anthropic.
- vs. **bytedance/deer-flow** — both ship visual workflow + tool integrations. deer-flow is LangGraph-native + 21 public skills + 7 IM channels + Python core. sim is Drizzle-native + workflow-as-MCP + 35 OAuth connectors + TypeScript core.
- vs. **run-llama/llama_index** — llama_index is a *framework* (571 separately versioned packages). sim is a *deployable product* (1 monorepo, 16 internal packages). Both ship MCP bidirectional support; sim adds DB persistence + consent + SSRF; llama_index adds 3 cohort-member adapters (cognee/mem0/FalkorDB).

## Code pointers

- KB service: [`apps/sim/lib/knowledge/service.ts`](https://github.com/simstudioai/sim/blob/main/apps/sim/lib/knowledge/service.ts) (`KnowledgeBaseService`, `KnowledgeBaseConflictError`, `getKnowledgeBases`).
- Embedding utils: [`apps/sim/lib/embeddings.ts`](https://github.com/simstudioai/sim/blob/main/apps/sim/lib/embeddings.ts) (BYOK, custom dimensions, batch by 8000-token limit).
- 7 chunkers: [`apps/sim/lib/chunkers/`](https://github.com/simstudioai/sim/tree/main/apps/sim/lib/chunkers).
- 11 file parsers: [`apps/sim/lib/file-parsers/`](https://github.com/simstudioai/sim/tree/main/apps/sim/lib/file-parsers).
- MCP client + version negotiation: [`apps/sim/lib/mcp/client.ts:46-50`](https://github.com/simstudioai/sim/blob/main/apps/sim/lib/mcp/client.ts) (`SUPPORTED_VERSIONS`).
- MCP service + cache adapter: [`apps/sim/lib/mcp/service.ts`](https://github.com/simstudioai/sim/blob/main/apps/sim/lib/mcp/service.ts).
- Workflow-as-MCP sync: [`apps/sim/lib/mcp/workflow-mcp-sync.ts`](https://github.com/simstudioai/sim/blob/main/apps/sim/lib/mcp/workflow-mcp-sync.ts) (`generateSchemaFromBlocks`, `generateParameterSchemaForWorkflow`).
- MCP storage: [`apps/sim/lib/mcp/storage/`](https://github.com/simstudioai/sim/tree/main/apps/sim/lib/mcp/storage) (memory-cache + redis-cache).
- Domain SSRF guards: [`apps/sim/lib/mcp/domain-check.ts`](https://github.com/simstudioai/sim/blob/main/apps/sim/lib/mcp/domain-check.ts).
- DAG executor: [`apps/sim/lib/executor/`](https://github.com/simstudioai/sim/tree/main/apps/sim/lib/executor).
- Copilot subsystem: [`apps/sim/lib/copilot/`](https://github.com/simstudioai/sim/tree/main/apps/sim/lib/copilot).
- Cross-language guardrails: [`apps/sim/lib/guardrails/`](https://github.com/simstudioai/sim/tree/main/apps/sim/lib/guardrails) (validate_pii.{ts,py} + json/regex/hallucination).
- Self-modifying agent skills: [`.agents/skills/`](https://github.com/simstudioai/sim/tree/main/.agents/skills) (14 skills: add-block, add-connector, add-integration, add-tools, add-trigger, validate-*, cleanup, you-might-not-need-*, react-query-best-practices, emcn-design-review).
- Enterprise tier (separate LICENSE): [`apps/sim/ee/`](https://github.com/simstudioai/sim/tree/main/apps/sim/ee) (access-control, audit-logs, data-retention, sso, whitelabeling).
- AGENTS.md (canonical) + CLAUDE.md (mirror): [`AGENTS.md`](https://github.com/simstudioai/sim/blob/main/AGENTS.md).

## Open questions

- **Vector backend abstraction** — KB metadata is in Postgres but where do embeddings live? `embeddingDimension` on the KB row suggests pgvector or similar; not surfaced in the file tree I scanned. (Likely `@sim/db` schema; needs deeper read of `packages/db/`.)
- **Workflow-as-MCP-server scaling** — `workflowMcpServer` + `workflowMcpTool` tables sync deployed workflows; what's the upper bound on concurrent MCP-exposed workflows?
- **MCP consent UX** — `McpConsentRequest` / `McpConsentResponse` types exist, but how does the React frontend surface consent prompts? (`apps/sim/components/`?)
- **Bun runtime requirement** — preinstall hook in package.json blocks npm. Can self-hosters use Node + npm, or is Bun mandatory? (Helm chart + Docker images would tell.)
- **`apps/sim/ee/` license boundary** — Apache-2.0 + separate `ee/` LICENSE. Does building Docker images include or exclude `ee/`? (`docker-compose.local.yml` vs `docker-compose.prod.yml` may differ.)

---

*Audit 2026-05-02: clone-verified against [simstudioai/sim@main](https://github.com/simstudioai/sim) (last commit 2026-05-02 04:01). Apache-2.0 confirmed in `LICENSE`. Counts enumerated by directory: connectors=35 (`ls apps/sim/connectors/`), tools=220 (`ls apps/sim/tools/`), workflow blocks=227 (`ls apps/sim/blocks/blocks/`), LLM providers=17 (anthropic / azure-anthropic / azure-openai / bedrock / cerebras / deepseek / fireworks / gemini / google / groq / mistral / ollama / openai / openrouter / vertex / vllm / xai), chunkers=7 (`apps/sim/lib/chunkers/` excluding tests/utils/index/types), file parsers=11. Self-modifying agent skills=14 verified by `ls .agents/skills/`. MCP 3-version negotiation verified at `apps/sim/lib/mcp/client.ts` (`SUPPORTED_VERSIONS = ['2025-06-18', '2025-03-26', '2024-11-05']`). MCP consent/security types (`McpSecurityPolicy`, `McpConsentRequest`, `McpConsentResponse`) verified at `apps/sim/lib/mcp/client.ts:24-32`. Workflow-as-MCP DB persistence verified at `apps/sim/lib/mcp/workflow-mcp-sync.ts` (`workflowMcpServer`, `workflowMcpTool` from `@sim/db`). SSRF guards verified at `apps/sim/lib/mcp/domain-check.ts` (`validateMcpDomain`, `isMcpDomainAllowed`, `validateMcpServerSsrf`). Cross-language guardrails verified by `ls apps/sim/lib/guardrails/` (validate_pii.py + validate_pii.ts coexist). Enterprise tier with separate LICENSE verified at `apps/sim/ee/LICENSE`. 16 internal packages verified by `ls packages/`. Bun + Biome verified in `package.json` (`packageManager: bun@1.3.13`) and `biome.json`. Corrections: none (first-pass survey).*
