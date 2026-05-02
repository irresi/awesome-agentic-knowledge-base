# ComposioHQ/composio

- **Stars:** 27,985 · **Last push:** 2026-05-02 · **Created:** 2024-02-23 · **License:** MIT (Sampark Inc.) · **Lang:** TypeScript primary + Python · **Versions:** `@composio/core 0.8.1` (TS), `composio 0.12.0` Python, Python SDK rolling toward `1.0.0-rc2`
- **Category:** kb-app (toolkit-routing-as-service; per-user isolated MCP sessions)
- **Tagline:** "Composio powers 1000+ toolkits, tool search, context management, authentication, and a sandboxed workbench to help you build AI agents that turn intent into action."

## TL;DR

A **toolkit-routing-as-service** platform that wraps **1000+ third-party-tool integrations** behind a single SDK and exposes per-user **isolated MCP sessions** with managed OAuth. Dual TS + Python SDKs share semantics (TS is the primary development surface per `AGENTS.md`); both compile down to typed `Tool` / `ToolCollection` generics over **23 provider integrations** (TS: 11 — anthropic / claude-agent-sdk / cloudflare / google / langchain / llamaindex / mastra / openai / openai-agents / vercel; Python: 12 — anthropic / autogen / claude_agent_sdk / crewai / gemini / google / google_adk / langchain / langgraph / llamaindex / openai / openai_agents). The architectural bet: **agents shouldn't reimplement OAuth, schema-conversion, and per-tool sandboxing for every external service**; Composio bundles them. Cohort-first **MCP-session-as-service** primitive (`composio.experimental.create(userId, {toolkits, manageConnections})` returns an MCP URL). MIT.

## KB Architecture (as a tool/connection layer)

### Storage
- Composio is API-backed — the canonical state lives in Composio's hosted backend (`@composio/client` SDK calls). The repo is the SDK, not the data plane.
- For self-hosted/on-prem: SDKs proxy to a backend instance configured via `APIEnvironment` + `base_url` + `api_key`.

### Toolkit catalog ("1000+ toolkits")
- **Toolkit** = bundle of related tools (e.g., `gmail` toolkit ≈ N gmail-related tools). README claims **1000+ toolkits**.
- `Toolkits.ts` (TS) / `Toolkits` (Python) is the listing/discovery API.
- **Tool search** at the protocol layer — the SDK provides `Tools.list({...})` with filters (`ToolListParams`).
- Fully-typed across providers via `TToolCollection` + `TTool` generics — e.g., OpenAI's collection returns `ChatCompletionToolParam[]`, Anthropic's returns its own type, with the same `composio.tools.get(toolkitName)` API.

### Per-user MCP-session-as-service (cohort first)
- [`ts/packages/core/src/models/ToolRouter.ts`](https://github.com/ComposioHQ/composio/blob/main/ts/packages/core/src/models/ToolRouter.ts):
  ```typescript
  const session = await composio.experimental.create(userId, {
    toolkits: ['gmail'],
    manageConnections: true
  });
  console.log(session.mcp.url);  // → isolated MCP server URL
  ```
- Each `userId` × `toolkits` combination spawns an isolated remote MCP server with its own URL. The agent connects to that URL and gets tools scoped to that user's connected accounts.
- `ToolRouterSession.ts` + `ToolRouterSessionFileMount.ts` — file-mount abstractions for sandbox-style sessions.
- **Cohort-first remote-MCP-session-as-service primitive** — most cohort entries either run an MCP server in the same process (claude-mem, basic-memory) or as an edge worker (honcho), or persist workflows as MCP servers (sim). Composio creates *per-user, per-toolkit-set* ephemeral MCP endpoints.
- Topics include `mcp`, `remote-mcp-server`, `sse` — the SDK's MCP transport supports both Streamable HTTP and SSE.

### Auth + connection layer (cohort-novel scale)
- [`AuthConfigs.ts`](https://github.com/ComposioHQ/composio/blob/main/ts/packages/core/src/models/AuthConfigs.ts) — declarative auth-config per toolkit (OAuth scopes, API key shapes, etc.).
- [`AuthScheme.ts`](https://github.com/ComposioHQ/composio/blob/main/ts/packages/core/src/models/AuthScheme.ts) — the abstract auth-scheme contract.
- [`ConnectedAccounts.ts`](https://github.com/ComposioHQ/composio/blob/main/ts/packages/core/src/models/ConnectedAccounts.ts) + [`ConnectionRequest.ts`](https://github.com/ComposioHQ/composio/blob/main/ts/packages/core/src/models/ConnectionRequest.ts) — per-user connected-account state + connection-request flow.
- **Auth-as-service for tools** — Composio runs the OAuth dance for 1000+ services so the agent doesn't have to. Cohort first to make per-user OAuth a first-class abstraction at this scale.

### Custom tools + custom toolkits (extension surface)
- [`CustomTool.ts`](https://github.com/ComposioHQ/composio/blob/main/ts/packages/core/src/models/CustomTool.ts) — `experimental_createTool('GREP', {name, description, inputParams: z.object({...}), execute})` factory, with Zod schema validation.
- `CustomTools.ts` — collection management for custom tools.
- `experimental_createToolkit('DEV_TOOLS', {name, description, tools: [grep]})` — bundle custom tools into custom toolkits.
- Schema conversion via `json-schema-to-zod` (TS) and `json-schema-to-pydantic` (Python) — Zod ⇄ JSON Schema ⇄ Pydantic round-trip support.

### Triggers (event-shaped agent invocations)
- [`Triggers.ts`](https://github.com/ComposioHQ/composio/blob/main/ts/packages/core/src/models/Triggers.ts) — event subscriptions across toolkits (e.g., "fire when a gmail arrives matching X"). Pusher dependency in Python deps suggests realtime event delivery.

### Provider integration model
- TS providers in [`ts/packages/providers/`](https://github.com/ComposioHQ/composio/tree/main/ts/packages/providers): 10 providers + base (`anthropic` / `claude-agent-sdk` / `cloudflare` / `google` / `langchain` / `llamaindex` / `mastra` / `openai` / `openai-agents` / `vercel`).
- Python providers in [`python/providers/`](https://github.com/ComposioHQ/composio/tree/main/python/providers): 12 providers (`anthropic` / `autogen` / `claude_agent_sdk` / `crewai` / `gemini` / `google` / `google_adk` / `langchain` / `langgraph` / `llamaindex` / `openai` / `openai_agents`).
- Each provider implements `BaseComposioProvider` / `BaseProvider` with type generics `<TTool, TToolCollection>` so the same Composio call returns provider-native types.
- `pnpm create:provider <name> [--agentic]` scaffolds new providers (TS).

### CLI
- [`ts/packages/cli/`](https://github.com/ComposioHQ/composio/tree/main/ts/packages/cli) — TS CLI built with **Effect.ts** + **@clack/prompts** (cohort-rare functional-effects toolchain; Effect-managed errors via `effect-errors/`).
- `cli-keyring/` — separate package for OS keyring credential storage.
- `analytics/`, `commands/`, `experimental-features.ts`, `generation/` — code-generation utilities for SDK builders.

### Platform abstraction
- [`ts/packages/core/src/platform/`](https://github.com/ComposioHQ/composio/tree/main/ts/packages/core/src/platform): `node.ts` + `workerd.ts` (Cloudflare Workers) + `edge-light` — per-runtime conditional imports via `package.json#imports`.
- [`Files.node.ts`](https://github.com/ComposioHQ/composio/blob/main/ts/packages/core/src/models/Files.node.ts) vs [`Files.workerd.ts`](https://github.com/ComposioHQ/composio/blob/main/ts/packages/core/src/models/Files.workerd.ts) — Node fs vs Workers Web-Streams variants.
- **Cohort-first explicit Cloudflare-Workers-runtime support** at the SDK level (honcho's MCP is a CF Worker but composio's *whole core SDK* runs on Workers).

### Build + tooling
- **pnpm workspaces** for the TS monorepo; **changesets** for versioning.
- Bun version pinned (`.bun-version`) — but pnpm is the canonical PM.
- `ts-builders/` — TypeScript code-generation utilities (probably for SDK type generation from API specs).
- `json-schema-to-zod/` — internal schema-conversion utility shipped as separate package.
- `vendor/` — read-only reference submodules (Effect, Clack — explicit "do not modify" per AGENTS.md).
- 4 self-modifying agent skills in `.agents/skills/`, plus skills in `.claude/skills/` and `.claude/commands/` and `.claude/rules/`.

## Notable design choices

- **Toolkit-routing-as-service** with **per-user isolated MCP sessions** — `composio.experimental.create(userId, {toolkits})` returns an MCP URL scoped to that user × that toolkit set. Cohort-first remote-MCP-session-as-service primitive — most cohort entries serve a single MCP endpoint per process; Composio multiplexes per (user, toolkit-set) tuples.
- **1000+ toolkits backed by managed OAuth** — `AuthConfigs` + `ConnectedAccounts` + `ConnectionRequest` make per-user OAuth a first-class abstraction. Cohort-first auth-as-service for tools at this scale (cohort entries that integrate apps — anything-llm 35 connectors, sim 35 connectors, mindsdb 34 handlers — bundle the OAuth code per-app inline; Composio externalizes it).
- **Dual TS + Python SDK with shared semantics + provider-typed generics** — `<TTool, TToolCollection>` generic parameters mean the same `composio.tools.get(...)` call returns `ChatCompletionToolParam[]` in OpenAI provider, Anthropic-typed tools in Anthropic provider, etc. Cohort-first generic-typed tool collections preserving provider-native types.
- **23 provider integrations** (10+1 TS + 12 Python) — combined provider catalog larger than most cohort entries' single-language equivalents.
- **Effect.ts + @clack/prompts CLI** — cohort-rare functional-effects toolchain (Effect provides typed-error + dependency injection); explicit `vendor/` of Effect + Clack as read-only submodules per AGENTS.md.
- **Cloudflare-Workers-runtime support at the SDK core level** — `package.json#imports` conditional `workerd` / `edge-light` / `node` exports + per-platform `Files.{node,workerd}.ts` + per-platform `platform/{node,workerd}.ts`. Cohort-first explicit Workers-edge runtime as a first-class deploy target for the SDK itself.
- **Custom tools + custom toolkits as extension surface** — `experimental_createTool` + `experimental_createToolkit` let users register tools with Zod-validated input params alongside the 1000+ built-ins.
- **Triggers as event-shaped agent invocations** — Pusher-backed realtime delivery (per Python `pysher>=1.0.8` dep).

## Dependencies

TS (`@composio/core 0.8.1`): Effect.ts, @clack/prompts, Zod, json-schema-to-zod, @composio/client (proprietary client SDK), Pusher (TS equivalent for triggers). Python (`composio 0.12.0`): `pysher>=1.0.8`, `pydantic>=2.6`, `composio-client==1.35.0`, `openai`, `json-schema-to-pydantic>=0.4.8`. Both depend on the proprietary `composio-client` package (the API client) — the OSS SDK is a wrapper over the hosted Composio backend.

## Tradeoffs

- **For**: cohort-first **per-user isolated MCP sessions** (`session.mcp.url`); cohort-first **auth-as-service** for 1000+ toolkits with managed OAuth; cohort-first **provider-typed generic tool collections** (`<TTool, TToolCollection>` preserves provider-native types); broad provider catalog (23 across TS + Python); Cloudflare-Workers-runtime native; custom tool + custom toolkit extension via Zod schemas; Triggers for event-shaped invocations; mature dual-SDK with shared semantics; clean monorepo structure (pnpm workspaces + changesets); MIT.
- **Against**: **API-backed = depends on Composio's hosted backend** — the OSS repo is the SDK, not the data plane; self-hosting requires an `APIEnvironment` Composio backend; **proprietary `@composio/client` / `composio-client==1.35.0` packages** are the API SDK (transitive proprietary dep); 1000+ toolkit claim is partly via the hosted catalog (not all 1000+ are self-hostable definitions); Effect.ts CLI adds learning curve for contributors; v3-SDK churn (`@composio/core` is at v0.8.1 = pre-1.0); Python SDK is `1.0.0-rc2` (release-candidate); the TS-first development model means Python features may lag (per AGENTS.md: "main development focus is on the TypeScript SDK").

## When to use vs. cohort

- vs. **anything-llm** ([survey](Mintplex-Labs__anything-llm.md)) — anything-llm bundles 35 in-tree OAuth connectors + 17 Aibitat plugins per workspace; Composio externalizes OAuth + tools to a hosted catalog of 1000+. anything-llm for "self-hosted everything in one repo"; Composio for "use 1000+ external services without writing OAuth code".
- vs. **sim** ([survey](simstudioai__sim.md)) — sim has 35 OAuth connectors + 220 in-tree tools + persisted-workflow-as-MCP. Composio has 1000+ toolkits via hosted backend + per-user MCP sessions. sim for "deploy your workflow as MCP"; Composio for "consume external services as MCP".
- vs. **mindsdb** ([survey](mindsdb__mindsdb.md)) — mindsdb federates *data sources* via SQL; Composio federates *action endpoints* (gmail-send / linear-create-issue / etc.) via MCP. Different complementary axes — could use both: mindsdb for "what data does the agent query?", Composio for "what actions does the agent take?".
- vs. **byterover-cli** ([survey](campfirein__byterover-cli.md)) — byterover-cli is memory-router-as-product (7 backends, QueryType-based routing). Composio is tool-router-as-product (1000+ toolkits, per-user MCP sessions). Same architectural shape (router-as-product) at different layers — memory vs tools. Together they signal the **router-as-product** category is hardening across 4 substrate types: memory (byterover-cli), tools (anything-llm-host + Composio), MCP role types (sim / honcho / anything-llm), data sources (mindsdb).
- vs. **llama_index** ([survey](run-llama__llama_index.md)) — llama_index ships 68 in-tree tool packages as part of its 571-package monorepo; Composio centralizes 1000+ via hosted backend. llama_index for "Python framework with everything"; Composio for "tool-routing layer your existing framework can call".

## Code pointers

- TS core SDK entry: [`ts/packages/core/src/composio.ts`](https://github.com/ComposioHQ/composio/blob/main/ts/packages/core/src/composio.ts) (`Composio` class).
- Per-user MCP session: [`ts/packages/core/src/models/ToolRouter.ts`](https://github.com/ComposioHQ/composio/blob/main/ts/packages/core/src/models/ToolRouter.ts) (`composio.experimental.create(userId, {toolkits, manageConnections})`).
- MCP server management: [`ts/packages/core/src/models/MCP.ts`](https://github.com/ComposioHQ/composio/blob/main/ts/packages/core/src/models/MCP.ts).
- Auth abstractions: [`ts/packages/core/src/models/{AuthConfigs,AuthScheme,ConnectedAccounts,ConnectionRequest}.ts`](https://github.com/ComposioHQ/composio/tree/main/ts/packages/core/src/models).
- Custom tools/toolkits: [`ts/packages/core/src/models/CustomTool.ts`](https://github.com/ComposioHQ/composio/blob/main/ts/packages/core/src/models/CustomTool.ts) + `CustomTools.ts`.
- Triggers (event-based): [`ts/packages/core/src/models/Triggers.ts`](https://github.com/ComposioHQ/composio/blob/main/ts/packages/core/src/models/Triggers.ts).
- Platform abstraction: [`ts/packages/core/src/platform/{node,workerd}.ts`](https://github.com/ComposioHQ/composio/tree/main/ts/packages/core/src/platform) + `package.json#imports`.
- 11 TS providers: [`ts/packages/providers/`](https://github.com/ComposioHQ/composio/tree/main/ts/packages/providers).
- 12 Python providers: [`python/providers/`](https://github.com/ComposioHQ/composio/tree/main/python/providers).
- Effect.ts CLI: [`ts/packages/cli/`](https://github.com/ComposioHQ/composio/tree/main/ts/packages/cli) (Effect.ts + @clack/prompts).
- Python SDK entry: [`python/composio/sdk.py`](https://github.com/ComposioHQ/composio/blob/main/python/composio/sdk.py) (`Composio` class).
- AGENTS.md (canonical): [`AGENTS.md`](https://github.com/ComposioHQ/composio/blob/main/AGENTS.md).

## Open questions

- **OSS vs hosted boundary** — the SDK depends on `composio-client` (proprietary). Can self-hosters run a fully OSS Composio backend, or is the hosted backend required for non-trivial use?
- **1000+ toolkit catalog source-of-truth** — are toolkit definitions in the OSS repo, or only on the hosted backend? The repo's `ts/packages/providers/` has only 10 entries (which are *AI providers*, not external toolkits like gmail/linear).
- **MCP session lifecycle** — when does a per-user `session.mcp.url` expire? What's the storage cost model?
- **Effect.ts adoption rationale** — Effect adds significant learning curve. What concrete benefits did the team get vs a more conventional `commander` / `yargs` CLI?
- **Python SDK 1.0.0-rc2 vs `composio==0.12.0`** — the Python `__version__.py` says `1.0.0-rc2` but `pyproject.toml` says `0.12.0`. Which is canonical?

---

*Audit 2026-05-02: clone-verified against [ComposioHQ/composio@main](https://github.com/ComposioHQ/composio) (last commit 2026-05-02 07:49). MIT confirmed in `LICENSE` (Sampark Inc. 2025). Versions: TS `@composio/core 0.8.1`, Python `composio 0.12.0` (pyproject.toml) / `1.0.0-rc2` (`__version__.py`). Provider counts enumerated by directory: TS providers=11 (`ls ts/packages/providers/` minus README.md), Python providers=12 (`ls python/providers/`). Core models (15) verified by `ls ts/packages/core/src/models/`: `AuthConfigs`, `AuthScheme`, `ConnectedAccounts`, `ConnectionRequest`, `CustomTool`, `CustomTools`, `Files.{node,workerd}`, `MCP`, `RemoteFile`, `SessionContext`, `ToolRouter`, `ToolRouterSession`, `ToolRouterSessionFileMount`, `Toolkits`, `Tools`, `Triggers`. ToolRouter usage example verified verbatim from `ToolRouter.ts:1-22` JSDoc. CustomTool factory verified at `CustomTool.ts:1-30`. Platform abstraction (node / workerd / edge-light) verified at `package.json#imports` + `platform/` directory. Effect.ts + @clack/prompts CLI verified per AGENTS.md "Project Architecture" section. AGENTS.md "TypeScript SDK is main development" claim verified verbatim. 1000+ toolkit claim verified via README description (not enumerable in-tree — toolkit definitions live in hosted backend). Pusher dependency verified at `python/pyproject.toml`. composio-client proprietary package dependency verified. Corrections: none (first-pass survey).*
