# mindsdb/mindsdb

- **Stars:** 39,089 · **Last push:** 2026-04-30 · **Created:** 2018-08-02 (8 years old) · **License:** Elastic License 2.0 (ELv2) for Core, with per-file overrides · **Lang:** Python 3.10–3.13
- **Category:** infra-layer (3rd cohort entry alongside [`FalkorDB`](FalkorDB__FalkorDB.md) and [`memgraph`](memgraph__memgraph.md); different shape — query engine for federated data, not a graph DB)
- **Tagline:** "Query engine for AI analytics, powering agents to answer questions across all your live data"

## TL;DR

A **federated query engine** that exposes structured + unstructured data sources, LLM providers, vector stores, and SaaS apps **as virtual tables addressable via SQL**, then layers an agent runtime on top. Custom `mindsdb-sql-parser` (~v0.13.8) extends SQL with constructs for `KNOWLEDGE_BASE`, `JOB`, `TRIGGER`, `AGENT`, `CHATBOT`, `MODEL`. The core architectural bet: agents query *unified* data via a single SQL surface — no ETL, no per-source SDK juggling. Ships **34 in-tree handlers** (data sources / LLM providers / vector stores / SaaS apps) with claims of 200+ via external handler packages. **Cohort-first Google A2A protocol implementation** (`api/a2a/MindsDBAgent`) and **most complete MCP API surface in cohort** (server with prompts + resources + tools + completions + OAuth, `mcp.streamable_http_app` + `mcp.sse_app` dual transport). Agent runtime built on **PydanticAI** with explicit *Planning Step* documented via mermaid in `AGENT_FLOW_DIAGRAM.md`. Companion AI co-worker product **ANTON** lives in a separate repo. **2nd ELv2-licensed cohort entry** (after byterover-cli).

## KB Architecture

### Storage — federated via handlers (200+ data sources claim, 34 in-tree)
- 34 in-tree handler packages in [`mindsdb/integrations/handlers/`](https://github.com/mindsdb/mindsdb/tree/main/mindsdb/integrations/handlers): mix of:
  - **Data sources**: `mysql`, `postgres`, `mariadb`, `mssql`, `oracle`, `snowflake`, `bigquery`, `redshift`, `databricks`, `timescaledb`, `salesforce`, `hubspot`, `shopify`, `netsuite`, `email`, `web`, `file`, `rest_api`
  - **LLM providers**: `anthropic`, `openai`, `cohere`, `bedrock`, `huggingface`, `huggingface_api`, `ollama`, `groq`, `llama_index`
  - **Vector stores**: `chromadb`, `pgvector`, `duckdb_faiss`
  - **ML platforms**: `mlflow`
- README claims **200+ live data sources**; the gap (~166) is filled via external handler packages (handler-storage-factory pattern; not all are vendored in-tree).
- **Knowledge Base interface** in [`mindsdb/interfaces/knowledge_base/`](https://github.com/mindsdb/mindsdb/tree/main/mindsdb/interfaces/knowledge_base): `KnowledgeBaseController` + `KnowledgeBaseTable` + 4 KB providers (`bedrock` / `gemini` / `snowflake` + base) for embeddings/storage. KB preprocessing has `document_loader.py`, `document_preprocessor.py`, `text_splitter.py`, `json_chunker.py`, `models.py`, `constants.py`.

### Query layer — SQL as the agent language
- [`mindsdb-sql-parser ~= 0.13.8`](https://pypi.org/project/mindsdb-sql-parser/) extends SQL with custom DDL/DML constructs:
  - `CREATE KNOWLEDGE_BASE` — declarative KB definition
  - `CREATE JOB` / `CREATE TRIGGER` — workflow scheduling
  - `CREATE AGENT` / `CREATE CHATBOT` — agent declaration
  - `CREATE MODEL` — LLM/ML model registration
- **Cohort first to use SQL as the agent query language**. Most cohort entries provide REST/GraphQL/MCP APIs; mindsdb makes SQL the canonical agent surface.
- `interfaces/data_catalog/` builds metadata catalogs over connected sources (used by the agent's planning step).
- `interfaces/jobs/`, `interfaces/triggers/`, `interfaces/tasks/` — workflow primitives, all SQL-addressable.

### Agent runtime — PydanticAI + explicit planning step
- [`mindsdb/interfaces/agents/`](https://github.com/mindsdb/mindsdb/tree/main/mindsdb/interfaces/agents): `agents_controller.py` (`AgentsController`, `AgentParams`, `AgentMode` enum), `pydantic_ai_agent.py`, `chart_agent.py`, `modes/`, `utils/`.
- **PydanticAI** is the in-tree agent framework (cohort second after `vectorize-io/hindsight`'s pydantic-ai integration).
- Documented agent flow in [`AGENT_FLOW_DIAGRAM.md`](https://github.com/mindsdb/mindsdb/blob/main/mindsdb/interfaces/agents/AGENT_FLOW_DIAGRAM.md):
  ```
  AgentsController.get_completion → init PydanticAIAgent → init SQL Toolkit
    → build Data Catalog (sample data + metadata for each table/KB)
    → PLANNING STEP (separate Planning Agent w/ PlanResponse output type)
    → Execution → Response
  ```
- **Cohort-first explicit "Planning Agent" as a typed sub-agent** with `PlanResponse` output type (vs cohort patterns of inline planning prompts).
- `chart_agent.py` — auto-generates charts as agent capability (cohort first specialized chart-generation agent).
- **Langfuse tracing** built into the agent flow ("Setup Langfuse Trace for observability" step in flow diagram).

### API surface — multi-protocol (cohort widest)
6 separate API modules in [`mindsdb/api/`](https://github.com/mindsdb/mindsdb/tree/main/mindsdb/api):
1. **`http/`** — REST + Swagger
2. **`mysql/`** — **MySQL wire protocol** (cohort first to expose MySQL-protocol endpoint — agents can connect via any MySQL client/driver)
3. **`mcp/`** — Model Context Protocol server (most complete in cohort, see below)
4. **`a2a/`** — **Google's Agent-to-Agent (A2A) protocol** (cohort first), with `MindsDBAgent` HTTP client class supporting `text` / `text/plain` / `application/json` content types
5. **`litellm/`** — LiteLLM-compatible endpoint (proxies to in-tree LLM handlers)
6. **`executor/`** — query execution engine
7. **`common/`** — shared middleware (auth, rate-limiting)

### MCP — most complete cohort surface
[`mindsdb/api/mcp/`](https://github.com/mindsdb/mindsdb/tree/main/mindsdb/api/mcp) ships:
- **5 MCP capability domains**: `tools/` (with `query.py`), `prompts/` (with `sample_table.py`), `resources/` (with `schema.py`), `completions.py`, plus base `mcp_instance.py` and `app.py` Starlette wrapper.
- **OAuth 2.1** authentication via `oauth.py` + `BearerAuthBackend` middleware.
- **Dual transport**: `mcp.streamable_http_app()` + `mcp.sse_app()` — supports both Streamable HTTP (newer) and SSE (legacy) MCP transports in same server.
- Rate limiting + CORS + auth-context middleware.
- **Cohort first to ship full MCP capability stack** (tools + prompts + resources + completions + OAuth + dual transport). Most cohort MCP servers expose only `tools`; mindsdb exposes the full MCP capability matrix.

### Workflow + scheduling
- `interfaces/jobs/` (cron-like SQL `CREATE JOB`)
- `interfaces/triggers/` (event-based)
- `interfaces/tasks/`
- `interfaces/chatbot/` — chatbot agent abstraction

### Storage / persistence
- SQLAlchemy + Alembic migrations (`mindsdb/migrations/versions/`)
- Default DB: SQLite or Postgres (configurable). Postgres requires `psycopg[binary]` + `psycopg2-binary`.
- Redis + `walrus==0.9.3` (Redis abstraction layer) for caching.
- DuckDB (`duckdb ~= 1.3.2`) for in-process analytics.

### Observability
- **Langfuse** for agent tracing.
- **Prometheus** (`prometheus-client==0.20.0`) for metrics.
- `mindsdb/metrics/` module.

## Notable design choices

- **SQL as the agent query language** with custom `mindsdb-sql-parser` extending it with `KNOWLEDGE_BASE` / `JOB` / `TRIGGER` / `AGENT` / `CHATBOT` / `MODEL` DDL — cohort first. Other cohort entries treat SQL as a backend (graphiti uses Neo4j Cypher, mem0 uses pgvector queries) but mindsdb makes SQL the *user-facing primary* interface for agent definitions and queries.
- **Federated data + KB unification** — agents query unified structured tables + unstructured KB content via single SQL surface. The "Connect → Unify → Respond" workflow eliminates per-source SDK ceremony.
- **MySQL wire protocol** as agent endpoint — cohort first. Means any MySQL client/driver becomes an agent client. Different from anything-llm/sim/honcho's HTTP-only model.
- **Cohort-first Google A2A protocol** — `MindsDBAgent` HTTP client implements Google's Agent-to-Agent spec. Enables mindsdb agents to interop with other A2A-speaking agents from Google + adopters.
- **Most complete MCP surface in cohort** — tools + prompts + resources + completions + OAuth + dual SSE/Streamable-HTTP transport. Most cohort MCP servers expose only the tools capability.
- **Explicit Planning Agent as typed sub-agent** with `PlanResponse` output type — cohort-novel agent-flow primitive (most cohort entries embed planning in inline system prompts).
- **PydanticAI** as the in-tree agent framework (cohort second after hindsight's integration).
- **AI co-worker product split** — ANTON (separate repo) is the "personal AI agent" UI product; mindsdb-the-repo focuses on the query engine substrate. Cohort second to split product into engine + UI repos (after onyx's similar pattern).
- **ELv2 license** — second cohort entry on Elastic License 2.0 (after [`byterover-cli`](campfirein__byterover-cli.md)). README explicitly addresses license diversity ("If there is a LICENSE file located in the same directory as the work, that license will apply to the work") — implementation files may have per-file overrides.

## Dependencies

Python 3.10–3.13. Core: `flask 3.1.3`, `flask-restx`, `werkzeug`, `pandas 2.3.1`, `sqlalchemy>=2.0`, `pydantic 2.12.5`, `redis 6.4.0`, `walrus 0.9.3` (Redis abstraction), `mindsdb-sql-parser ~= 0.13.8`, `duckdb ~= 1.3.2`, `boto3>=1.34.131`, `prometheus-client 0.20.0`, `lark` (parser generator). Agent: PydanticAI. Per-handler deps loaded lazily (handler-specific `requirements.txt`). MCP: `mcp` SDK with OAuth + bearer-auth middleware.

## Tradeoffs

- **For**: cohort-first **SQL-as-agent-query-language** + **federated data via 34+ handlers** (200+ via external packages); cohort-first **Google A2A protocol** implementation; cohort-most-complete **MCP surface** (tools + prompts + resources + completions + OAuth + dual transport); cohort-first **MySQL wire protocol** endpoint for agents; explicit **Planning Agent** as typed sub-agent; PydanticAI + Langfuse + Prometheus observability stack; established 8-year-old project (since 2018-08); diverse license model with per-file overrides allows partial-OSS adoption; AI co-worker product (ANTON) in separate repo for UI tier.
- **Against**: **ELv2 restricts SaaS hosting** without commercial agreement (same constraint as byterover-cli); custom `mindsdb-sql-parser` adds a learning curve (SQL extensions are non-standard); 200+ handler claim is partly aspirational (only 34 in-tree); large dependency surface (lark + flask + walrus + duckdb + many SDKs); core infra-layer abstractions (DBMS-style metadata + custom SQL dialect) are heavyweight for thin agent use-cases (mem0 / honcho are leaner); ANTON is the "user product" — mindsdb-only is more substrate than UX.

## When to use vs. cohort

- vs. **FalkorDB** ([survey](FalkorDB__FalkorDB.md)) and **memgraph** ([survey](memgraph__memgraph.md)) — both are graph databases; mindsdb is a federated SQL query engine. Pick FalkorDB/memgraph when graph topology matters; pick mindsdb when you need agents to query 200+ heterogeneous data sources via one interface (no shared shape across the 3 infra-layer entries — different infra slots).
- vs. **run-llama/llama_index** ([survey](run-llama__llama_index.md)) — llama_index is a Python framework with 571 separately versioned packages; mindsdb is a deployable infrastructure with in-tree handlers. llama_index for "framework you import"; mindsdb for "service you point your agent at".
- vs. **simstudioai/sim** ([survey](simstudioai__sim.md)) — sim is workflow-builder + KB + 35 connectors via Drizzle/Postgres; mindsdb is SQL-engine + 34 handlers. sim for visual workflow design; mindsdb for SQL-native data federation.
- vs. **infiniflow/ragflow** ([survey](infiniflow__ragflow.md)) — ragflow is doc-engine-heavy with deep document understanding + per-format chunkers; mindsdb is data-source-heavy with federated SQL. Pick ragflow when document quality is the bottleneck; mindsdb when data-source diversity is.
- vs. **deepset-ai/haystack** ([survey](deepset-ai__haystack.md)) — both are mature frameworks. Haystack is component-pipeline (NetworkX DAG of typed Components); mindsdb is SQL-engine + agent runtime. Different abstractions; haystack for compose-your-own RAG, mindsdb for SQL-native agent queries over heterogeneous data.

## Code pointers

- 34 in-tree handlers: [`mindsdb/integrations/handlers/`](https://github.com/mindsdb/mindsdb/tree/main/mindsdb/integrations/handlers).
- KB controller: [`mindsdb/interfaces/knowledge_base/controller.py`](https://github.com/mindsdb/mindsdb/blob/main/mindsdb/interfaces/knowledge_base/controller.py) (`KnowledgeBaseController`, `KnowledgeBaseTable`).
- KB providers: [`mindsdb/interfaces/knowledge_base/providers/`](https://github.com/mindsdb/mindsdb/tree/main/mindsdb/interfaces/knowledge_base/providers) (bedrock / gemini / snowflake).
- KB preprocessing: [`mindsdb/interfaces/knowledge_base/preprocessing/`](https://github.com/mindsdb/mindsdb/tree/main/mindsdb/interfaces/knowledge_base/preprocessing) (document_loader / document_preprocessor / text_splitter / json_chunker).
- Agent flow diagram: [`mindsdb/interfaces/agents/AGENT_FLOW_DIAGRAM.md`](https://github.com/mindsdb/mindsdb/blob/main/mindsdb/interfaces/agents/AGENT_FLOW_DIAGRAM.md).
- PydanticAI agent: [`mindsdb/interfaces/agents/pydantic_ai_agent.py`](https://github.com/mindsdb/mindsdb/blob/main/mindsdb/interfaces/agents/pydantic_ai_agent.py).
- Chart agent: [`mindsdb/interfaces/agents/chart_agent.py`](https://github.com/mindsdb/mindsdb/blob/main/mindsdb/interfaces/agents/chart_agent.py).
- A2A protocol: [`mindsdb/api/a2a/agent.py`](https://github.com/mindsdb/mindsdb/blob/main/mindsdb/api/a2a/agent.py) (`MindsDBAgent`).
- MCP server: [`mindsdb/api/mcp/app.py`](https://github.com/mindsdb/mindsdb/blob/main/mindsdb/api/mcp/app.py) — Starlette wrapper + dual transport + OAuth + tools/prompts/resources/completions modules.
- MySQL wire protocol: [`mindsdb/api/mysql/`](https://github.com/mindsdb/mindsdb/tree/main/mindsdb/api/mysql).
- LiteLLM endpoint: [`mindsdb/api/litellm/`](https://github.com/mindsdb/mindsdb/tree/main/mindsdb/api/litellm).
- Custom SQL parser: [`mindsdb-sql-parser`](https://pypi.org/project/mindsdb-sql-parser/) (separate package, pinned `~= 0.13.8` in `requirements/requirements.txt`).
- Companion AI co-worker product: [`mindsdb/anton`](https://github.com/mindsdb/anton) (separate repo).

## Open questions

- **Handler count gap** — README claims "200+ data sources" but only 34 are in-tree. Where do the other ~166 live? Per-PyPI? GitHub orgs? Is there a published handler registry?
- **A2A protocol maturity** — Google's A2A spec is recent (2025). Which other mindsdb consumers (or external A2A-speaking agents) are interoperating in production?
- **MCP capability adoption** — mindsdb ships prompts + resources + completions in its MCP server, but most cohort MCP clients only consume tools. Are there client-side cohort entries that exercise the full mindsdb MCP capability matrix?
- **ELv2 enforcement** — same constraint as byterover-cli ("you can't host as a SaaS"). What's mindsdb's commercial model — managed cloud + on-prem free, or does ELv2 + per-file overrides allow more permissive use of specific subsystems?
- **ANTON ↔ mindsdb relationship** — ANTON is in a separate repo. Is the AI co-worker built on top of mindsdb-the-engine, or is it a parallel product line?

---

*Audit 2026-05-02: clone-verified against [mindsdb/mindsdb@main](https://github.com/mindsdb/mindsdb) (last commit 2026-04-30 11:59). License diverse (ELv2 for Core per `LICENSE` + per-file overrides). Handler count 34 verified by `ls -1 mindsdb/integrations/handlers/ | wc -l`. KB providers (bedrock / gemini / snowflake) verified by `ls mindsdb/interfaces/knowledge_base/providers/`. KB preprocessing modules (document_loader / document_preprocessor / text_splitter / json_chunker / models / constants) verified by `ls mindsdb/interfaces/knowledge_base/preprocessing/`. Agent classes (`AgentParamsData`, `AgentMode`, `AgentParams`, `AgentsController`) verified at `mindsdb/interfaces/agents/agents_controller.py`. AGENT_FLOW_DIAGRAM.md mermaid flow verified verbatim. A2A `MindsDBAgent` HTTP client verified at `mindsdb/api/a2a/agent.py:1-30` (`SUPPORTED_CONTENT_TYPES = ["text", "text/plain", "application/json"]`). MCP server with prompts + resources + tools + completions + OAuth verified by `ls mindsdb/api/mcp/` and `head -40 mindsdb/api/mcp/app.py` (BearerAuthBackend, AuthContextMiddleware, dual `mcp.streamable_http_app` + `mcp.sse_app`). 6 API modules (a2a / common / executor / http / litellm / mcp / mysql) verified by `ls mindsdb/api/`. `mindsdb-sql-parser ~= 0.13.8` verified at `requirements/requirements.txt`. PydanticAI agent class verified at `mindsdb/interfaces/agents/pydantic_ai_agent.py`. Companion ANTON repo at `https://github.com/mindsdb/anton` referenced from README. Corrections: none (first-pass survey).*
