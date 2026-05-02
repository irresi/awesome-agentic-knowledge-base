# Survey: onyx-dot-app/onyx

**Date:** 2026-05-01
**Stars:** 28,824 · **Last push:** 2026-04-30 · **Created:** 2023 (formerly **Danswer**)
**Category:** kb-app
**Slug:** [onyx-dot-app/onyx](https://github.com/onyx-dot-app/onyx)

---

## TL;DR (3 lines)

- **What it is:** The most enterprise-shaped repo in the cohort: a multi-tenant "open-source AI platform" (formerly Danswer) for connecting LLMs to ~49 first-party SaaS sources (Confluence, Jira, Slack, Salesforce, Notion, Google Drive, GitHub, Zendesk, Zulip, …) with deep-research agents, code-execution sandboxes, voice mode, image gen, and an MCP server wrapped in FastAPI auth.
- **How its KB works:** Hybrid index on **Vespa** (default) or **OpenSearch**, with metadata + a **Postgres-backed knowledge graph** (entities / relationships as SQL tables, not a graph DB) populated by a Celery batch worker (`kg_extraction`). Multi-tenant Postgres + Redis + S3-compatible blob (MinIO/S3) + `model_server` for embeddings & local cross-encoder reranking. Federated connectors query source-of-truth services without bulk indexing.
- **Verdict:** The serious enterprise pick. Choose when you need 60+ connectors, multi-tenant deployment, deep-research orchestration, voice / image / sandbox / MCP server / ACP-based build agent — *and* you're OK running Vespa/OpenSearch + Postgres + Redis + Celery + S3 + a model server. Skip if you want a single-binary KB or a memory framework — Onyx is doc-RAG, not user/agent memory.

## KB Architecture

### Storage
- **Vector store:** **Vespa** (default, `backend/onyx/document_index/vespa/`) **or OpenSearch** (`backend/onyx/document_index/opensearch/`) — pluggable via `document_index/factory.py`. Vespa stores embeddings + text chunks + per-chunk metadata in a single index document. The OpenSearch backend ships with a [detailed README](https://github.com/onyx-dot-app/onyx/blob/main/backend/onyx/document_index/opensearch/README.md) explaining hybrid-pipeline normalization and time-decay tradeoffs.
- **Graph store:** **Postgres-as-graph.** No Neo4j/Kuzu/etc. The `onyx/kg/` module persists entities, relationships, and entity-types in normal SQL tables (`KGEntities`, `KGRelationships`, `EntityType`); enrichment is handled by Celery worker `kg_extraction.py`. Ungrounded vs grounded entities (`KGGroundingType`) and per-attribute typed tracking (`KGAttributeTrackInfo`).
- **Metadata / structured:** **Postgres** (asyncpg + SQLAlchemy + Alembic). One DB for users, connectors, documents, KG, file records, deep-research state. Multi-tenant via `alembic_tenants/` schema-per-tenant migrations.
- **Object / blob:** **S3-compatible** (`backend/onyx/file_store/file_store.py`) — uses `boto3` with `S3_ENDPOINT_URL` so MinIO / R2 / GCS-via-interop / native S3 all work. Falls back to a Postgres `FileRecord` BYTEA store for tiny envs.

### Ingestion / Extraction
- **Source types accepted:** **49 first-party connectors** in [`backend/onyx/connectors/`](https://github.com/onyx-dot-app/onyx/tree/main/backend/onyx/connectors) — Airtable, Asana, Axero, Bitbucket, Blob, Bookstack, Canvas, Clickup, Coda, Confluence, Discord, Discourse, Document360, Dropbox, Drupal Wiki, Egnyte, File, Fireflies, Freshdesk, Gitbook, GitHub, GitLab, Gmail, Gong, Google Drive, Google Site, Guru, Highspot, Hubspot, IMAP, Jira, Linear, Loopio, MediaWiki, Notion, Outline, Productboard, RequestTracker, Salesforce, SharePoint, Slab, Slack, Teams, TestRail, Web, Wikipedia, XenForo, Zendesk, Zulip. (Counted as the 52 subdirs minus 3 utility dirs: `cross_connector_utils`, `google_utils`, `mock_connector`.) Plus federated retrieval for sources that resist bulk indexing (`federated_connectors/slack`).
- **Chunking strategy:** [`backend/onyx/indexing/chunker.py`](https://github.com/onyx-dot-app/onyx/blob/main/backend/onyx/indexing/chunker.py) with title/content ratio (`TITLE_CONTENT_RATIO`), `chunk_content_enrichment.py` for surrounding-context injection, and per-format adapters in `indexing/adapters/`.
- **Entity / fact extraction:** **LLM-based KG extraction** in `kg/extractions/extraction_processing.py` runs as a Celery task. Entities, relationships, and `KGAttributeImplicationProperty` (e.g., infer `from_email` → ACCOUNT/EMPLOYEE) are upserted into Postgres. Entity types come from a default catalog (`kg/setup/kg_default_entity_definitions.py`) plus per-tenant config.
- **Schema:** **Doc-chunk + Postgres-KG hybrid.** Each ingested document → enriched chunks (Vespa) + extracted KG triples (Postgres). KG schema includes entity attributes, parent-child recursion (`KG_MAX_PARENT_RECURSION_DEPTH`), and grounded/ungrounded distinction.

### Retrieval
- **Modes:** **Hybrid keyword + dense** with normalization processor (Vespa or OpenSearch native pipeline). `HYBRID_ALPHA` config controls the keyword-vs-vector mix; `DOC_TIME_DECAY` adds recency bias; `RECENCY_BIAS_MULTIPLIER` and `RERANK_COUNT` control reranking surface. Federated retrieval mode queries source-of-truth services (e.g., live Slack search) without indexing.
- **Reranker:** Three external providers (`RerankerProvider` enum: **Cohere, Litellm, Bedrock**) plus an in-process **HF cross-encoder** running in the separate `model_server` container (`sentence-transformers==5.4.1`, `transformers==5.5.4`).
- **Top-k defaults:** `RERANK_COUNT` is the candidate pool size before rerank; final k flows from chat config. `chunk_retrieval.py` returns `InferenceChunk` records.
- **Context assembly:** `chat/citation_processor.py` does dynamic citation mapping; `chat/llm_loop.py` constructs message history with reasoning-model awareness (`model_is_reasoning_model`).

### Memory model
- **Tiers:** Onyx is fundamentally *doc-RAG*, not memory framework — but layers exist:
  - **Doc index** (Vespa/OpenSearch).
  - **KG** (Postgres entities/relationships, batch-extracted).
  - **Chat history** (Postgres-backed conversations + chat-state container `ChatStateContainer`).
  - **Deep Research state** — multi-step plan + clarification + final-report state machine (`deep_research/dr_loop.py`) with orchestrator / research-plan / clarification prompts in `prompts/deep_research/orchestration_layer.py`.
  - **Personas** (custom agents with instructions / knowledge / actions) — DB-stored.
- **Bi-temporal:** No native `valid_at`/`invalid_at`; KG entities have `KG_COVERAGE_START_DATE` and `KG_MAX_COVERAGE_DAYS` global windows + per-document `updated_at`.
- **Self-update mechanism:** **Celery batch worker** (`kg_extraction`) processes documents in `KGStage` states; per-tenant cron-triggered. Not online write-through.
- **Decay / forgetting:** `DOC_TIME_DECAY` boosts recent docs at query time; no automatic deletion. `delete_from_kg_entities__no_commit` / `delete_from_kg_relationships__no_commit` for explicit purges.

### MCP / connectors
- **MCP server exposed:** **Yes — full FastMCP + FastAPI wrapper** ([`backend/onyx/mcp_server/api.py`](https://github.com/onyx-dot-app/onyx/blob/main/backend/onyx/mcp_server/api.py)). Custom token verifier (`OnyxTokenVerifier`); HTTP transport on a dedicated port (`MCP_SERVER_PORT`); tools registered: `search`. Resources: `indexed_sources`. CORS-aware, `streamable-http` Accept-header handling.
- **MCP client used:** **Yes — "Actions & MCP"** (per README — agents can call external MCP servers). Plus `claude-agent-sdk>=0.1.19` and `agent-client-protocol>=0.7.1` as core deps.
- **Native connectors:** 49 first-party (above), plus federated, plus web-search providers (Google PSE / Serper / Exa / SearXNG / Brave) and content providers (in-house Onyx web crawler / Firecrawl / Exa).
- **Tool-call surface:** Built-in tools (search, web search, code execution, image gen, voice, deep research) + user-built **Custom Agents** with instructions/knowledge/actions, plus per-persona MCP server lists. **ACP-based "Build" feature** runs user-authored code agents in a sandbox manager (local Docker *or* Kubernetes) — `backend/onyx/server/features/build/sandbox/`.

### Notable design choices
- **Document index is interface-pluggable, not just configurable.** `document_index/interfaces.py` + `interfaces_new.py` formalize a `DocumentIndex` ABC; Vespa and OpenSearch both implement it. Adding a third backend is a registration call.
- **OpenSearch hybrid pipeline is documented in repo** ([opensearch/README.md](https://github.com/onyx-dot-app/onyx/blob/main/backend/onyx/document_index/opensearch/README.md)) — discussion of normalization-stage limitations, why `0` minimum-clip is a real artifact, and why time-decay can't be additive on un-normalized embedding scores. One of the most analytically honest retrieval design docs in this cohort.
- **Postgres-as-graph instead of a graph DB** — KG is *queried via JOINs*, not Cypher. Trade is: SQL skills + tooling > graph DB ops, but you give up multi-hop graph algorithms.
- **MIT + Onyx Enterprise License (EE)** — `backend/ee/`, `web/src/app/ee/`, `web/src/ee/` are EE-licensed. The OSS portion is genuine MIT (the Expat clause).
- **Multi-tenancy is first-class.** `alembic_tenants/` runs schema-per-tenant migrations; `shared_configs/contextvars.py` exposes `get_current_tenant_id()`; the file store and DB engine both pick tenant from contextvars.
- **`model_server` is a separate container** for embeddings + cross-encoder reranking. Decouples GPU-bound work from the API tier.
- **Deep Research is stateful.** `dr_loop.py` runs ORCHESTRATOR_PROMPT → CLARIFICATION_PROMPT → RESEARCH_PLAN → repeated tool-call cycles → FINAL_REPORT_PROMPT, streaming `DeepResearchPlanDelta` packets to the UI. Configurable to skip clarification (`SKIP_DEEP_RESEARCH_CLARIFICATION`).
- **`claude-agent-sdk` + `agent-client-protocol`** as hard deps — Onyx adopts ACP for the build/sandbox feature and embeds Anthropic's Claude Agent SDK directly.
- **`CLAUDE.md` and `AGENTS.md` are *identical*** at the repo root — single source of truth for agent guidance, double-published for tool compatibility.
- **Onyx Lite** mode — `<1 GB RAM` deployment, lightweight chat UI variant. Co-installed via `install_onyx.sh`.

## Dependencies (KB-relevant)

From `pyproject.toml` (root + backend group):

```
# Vector / search
opensearch-py==3.0.0
voyageai==0.2.3                  # alternative embedder
cohere==5.6.1                    # embedder + reranker
sentence-transformers==5.4.1     # local cross-encoder (model_server)
transformers==5.5.4

# DB / cache / queue / blob
asyncpg==0.30.0
alembic==1.18.4
sqlalchemy[asyncio]              # via -[backend]
redis==5.0.8
celery==5.5.1
boto3==1.39.11                   # S3 / MinIO file store
aioboto3==15.1.0

# LLM SDKs
litellm[google]==1.83.0
openai==2.14.0
google-genai==1.52.0
claude-agent-sdk>=0.1.19
agent-client-protocol>=0.7.1

# MCP / API
fastmcp                          # imported in mcp_server/api.py
fastapi==0.133.1
uvicorn==0.35.0

# Misc / observability
sentry-sdk[fastapi,celery,starlette]==2.14.0
prometheus_client>=0.21.1
prometheus_fastapi_instrumentator==7.1.0
kubernetes>=31.0.0               # k8s sandbox manager
discord-py==2.4.0                # connector + slackbot images
```

License: **MIT** for OSS / **Onyx Enterprise License** for `ee/` directories.

## Tradeoffs

**Pros:**
- **Connector breadth is unmatched** — 49 first-party adapters + federated retrieval, plus credentials providers / OAuth. Nothing else in this cohort touches this surface area.
- **Two production-grade hybrid backends** (Vespa, OpenSearch) behind the same interface — pick by ops preference, not by code rewrite.
- **Multi-tenancy is in the migrations, not bolted on** — schema-per-tenant Alembic + contextvars-based tenant resolution.
- **Deep Research state machine ships with the orchestration prompts** — orchestrator / clarification / research-plan / final-report are all real prompts, not aspirational docs.
- **MCP server has real auth** (token verifier) and FastMCP wrapping — production-shaped, not a toy.
- **Honest design documentation** (OpenSearch README) and excellent CLAUDE.md / AGENTS.md.

**Cons:**
- **Operational footprint is the largest in this cohort** — Vespa/OpenSearch + Postgres + Redis + Celery (multi-worker) + MinIO/S3 + model_server + (optionally) Kubernetes for the build sandbox. "Onyx Lite" exists but the full feature set isn't lightweight.
- **No graph backend** — entities/relationships live in Postgres. Multi-hop queries become SQL JOINs, which is fine until they aren't.
- **No vector backend simpler than Vespa/OpenSearch** — no SQLite/Faiss/pgvector path for "I just want a single binary".
- **EE/OSS split** — the Onyx Enterprise License covers `ee/` directories with substantive functionality (some auth, some SSO, some governance). Read the licenses before forking.
- **Memory framework adjacency is weak** — chat history is DB-stored but no atomic-fact / per-user memory layer exists. Treat as doc-RAG, not Mem0/Letta substitute.
- **Heavy LLM-SDK dependency surface** — claude-agent-sdk + ACP + litellm + openai + cohere + voyage all coexist; pinned versions; conflict-prone in shared venvs.

## When to use it

- **Good fit:** enterprise-search / knowledge-retrieval products with 5+ SaaS sources to connect; multi-tenant SaaS RAG; teams that want deep-research / agentic workflows + code-exec sandbox + voice + image-gen in one platform; deployments where Vespa or OpenSearch is acceptable.
- **Bad fit:** single-binary / laptop demos; agent-memory frameworks (use Mem0 / Graphiti / Khoj); products that require Cypher-native multi-hop graph traversal; teams without ops bandwidth for Celery + Redis + Vespa.
- **Closest alternative:** [`infiniflow/ragflow`](surveys/infiniflow__ragflow.md) — the closest cohort peer in shape (kb-app, OpenSearch/Infinity, deep-doc OCR, MCP server + client, multi-tenant). RAGFlow is more parsing-heavy (deepdoc OCR, RAPTOR), Onyx is more connector-heavy (60+ sources, federated retrieval). For pure agent-memory needs, see [`mem0ai/mem0`](surveys/mem0ai__mem0.md).

## Code pointers (evidence)

- Vespa hybrid index: [`backend/onyx/document_index/vespa/vespa_document_index.py`](https://github.com/onyx-dot-app/onyx/blob/main/backend/onyx/document_index/vespa/vespa_document_index.py)
- OpenSearch backend with normalization-pipeline tradeoffs explained: [`backend/onyx/document_index/opensearch/README.md`](https://github.com/onyx-dot-app/onyx/blob/main/backend/onyx/document_index/opensearch/README.md), [`opensearch_document_index.py`](https://github.com/onyx-dot-app/onyx/blob/main/backend/onyx/document_index/opensearch/opensearch_document_index.py)
- Pluggable doc-index factory: [`backend/onyx/document_index/factory.py`](https://github.com/onyx-dot-app/onyx/blob/main/backend/onyx/document_index/factory.py), [`interfaces_new.py`](https://github.com/onyx-dot-app/onyx/blob/main/backend/onyx/document_index/interfaces_new.py)
- KG batch extraction (Celery worker): [`backend/onyx/kg/extractions/extraction_processing.py:199`](https://github.com/onyx-dot-app/onyx/blob/main/backend/onyx/kg/extractions/extraction_processing.py)
- KG schema models: [`backend/onyx/kg/models.py`](https://github.com/onyx-dot-app/onyx/blob/main/backend/onyx/kg/models.py)
- 49 first-party connectors (52 subdirs - 3 utility dirs): [`backend/onyx/connectors/`](https://github.com/onyx-dot-app/onyx/tree/main/backend/onyx/connectors)
- Federated retrieval (live source-of-truth queries): [`backend/onyx/federated_connectors/`](https://github.com/onyx-dot-app/onyx/tree/main/backend/onyx/federated_connectors)
- Reranker providers (Cohere / Litellm / Bedrock + local HF cross-encoder): [`backend/onyx/natural_language_processing/search_nlp_models.py`](https://github.com/onyx-dot-app/onyx/blob/main/backend/onyx/natural_language_processing/search_nlp_models.py), [`shared_configs/enums.py:RerankerProvider`](https://github.com/onyx-dot-app/onyx/blob/main/backend/shared_configs/enums.py)
- MCP server (FastMCP + FastAPI + token auth): [`backend/onyx/mcp_server/api.py`](https://github.com/onyx-dot-app/onyx/blob/main/backend/onyx/mcp_server/api.py)
- Deep Research orchestration: [`backend/onyx/deep_research/dr_loop.py:195`](https://github.com/onyx-dot-app/onyx/blob/main/backend/onyx/deep_research/dr_loop.py), [`prompts/deep_research/orchestration_layer.py`](https://github.com/onyx-dot-app/onyx/blob/main/backend/onyx/prompts/deep_research/orchestration_layer.py)
- ACP build sandbox (Local docker / Kubernetes): [`backend/onyx/server/features/build/sandbox/`](https://github.com/onyx-dot-app/onyx/tree/main/backend/onyx/server/features/build/sandbox)
- File store (S3 / MinIO + Postgres fallback): [`backend/onyx/file_store/file_store.py`](https://github.com/onyx-dot-app/onyx/blob/main/backend/onyx/file_store/file_store.py)
- Multi-tenant Alembic: [`backend/alembic_tenants/`](https://github.com/onyx-dot-app/onyx/tree/main/backend/alembic_tenants)
- Most useful single file to read first: [`CLAUDE.md`](https://github.com/onyx-dot-app/onyx/blob/main/CLAUDE.md) (architecture overview written for AI agents) → then [`backend/onyx/document_index/opensearch/README.md`](https://github.com/onyx-dot-app/onyx/blob/main/backend/onyx/document_index/opensearch/README.md) for the retrieval reasoning.

## Open questions

- The KG attribute system (`KGAttributeTrackInfo`, `KGAttributeImplicationProperty`) is non-trivial — what's the user-facing UX for defining new entity types? Schema-tuning workflow?
- "Deep Research is top of leaderboard as of Feb 2026" (per README) — what's the eval methodology in [`onyx_deep_research_bench`](https://github.com/onyx-dot-app/onyx_deep_research_bench)? Worth a deeper future pass.
- The ACP-based build sandbox is recent (`agent-client-protocol>=0.7.1`); how does it compose with Custom Agents / personas / MCP tools that already exist? Likely the sandbox runs ACP agents that call MCP tools, but the integration shape merits a closer look.
- Federated connectors currently only ship Slack; expectation is Linear, Salesforce will follow — interface is in `federated_connectors/interfaces.py`.

---

*Surveyed via the `curating-agentic-kbs` skill. Re-survey scheduled after 30 days of last `pushed_at` change.*

*Audit 2026-05-02: clone-verified against [`backend/onyx/connectors/`](https://github.com/onyx-dot-app/onyx/tree/main/backend/onyx/connectors), [`backend/onyx/document_index/`](https://github.com/onyx-dot-app/onyx/tree/main/backend/onyx/document_index), [`backend/onyx/federated_connectors/`](https://github.com/onyx-dot-app/onyx/tree/main/backend/onyx/federated_connectors), [`backend/onyx/kg/extractions/`](https://github.com/onyx-dot-app/onyx/tree/main/backend/onyx/kg/extractions), [`backend/onyx/mcp_server/`](https://github.com/onyx-dot-app/onyx/tree/main/backend/onyx/mcp_server), [`backend/shared_configs/enums.py`](https://github.com/onyx-dot-app/onyx/blob/main/backend/shared_configs/enums.py), [`backend/requirements/default.txt`](https://github.com/onyx-dot-app/onyx/blob/main/backend/requirements/default.txt). **Correction:** connector count "63" / "~60" → **49 real first-party connectors** (52 subdirs minus 3 utilities: `cross_connector_utils`, `google_utils`, `mock_connector`). Added Zendesk + Zulip to enumerated list (missing from initial draft). **Verified verbatim:** dual Vespa + OpenSearch document_index (pluggable factory), `federated_connectors/slack` (only Slack ships; `Linear` / `Salesforce` planned per `interfaces.py`), KG extraction `extraction_processing.py`, MCP server with full FastMCP+FastAPI structure (`api.py` + `auth.py` + `tools/` + `resources/` + `mcp.json.template`), `RerankerProvider` enum (`COHERE` / `LITELLM` / `BEDROCK`) at [`shared_configs/enums.py:13-16`](https://github.com/onyx-dot-app/onyx/blob/main/backend/shared_configs/enums.py#L13-L16), all dep pins exact (`claude-agent-sdk==0.1.19`, `agent-client-protocol==0.7.1`, `cohere==5.6.1`, `celery==5.5.1`, `opensearch-py==3.0.0`).*
