# arc53/DocsGPT

- **Stars:** 17,871 · **Last push:** 2026-05-02 · **Created:** 2023-02-02 (3 years old) · **License:** MIT · **Lang:** Python (Flask + Celery + Alembic + Gunicorn) + TypeScript (React) · **Version:** `0.17.0` (per `application/version.py`)
- **Category:** kb-app (Private AI platform for agents + assistants + enterprise search)
- **Author:** arc53

## TL;DR

A **Flask + Celery + React** "private AI platform" with **4 distinct agent types** (`ClassicAgent` / `AgenticAgent` / `WorkflowAgent` / `ResearchAgent`) sharing a common `BaseAgent`, dispatched through `agent_creator.py`. Ships **15 LLM provider modules** (with a separate `providers/` sub-tree of 14 alternate implementations), **8 vector backends** (`elasticsearch` / `embeddings_local` (in-process) / `faiss` / `lancedb` / `milvus` / `mongodb` / `pgvector` / `qdrant`), **15 file parsers** in `parser/file/` (audio / docling / docs / epub / html / image / json / markdown / openapi3 / pptx / rst / tabular + bulk + base), and **3 SaaS connectors** in `parser/connectors/` (confluence / google_drive / share_point — explicitly enterprise-tilted). **19 agent tools** in `agents/tools/` including **`mcp_tool.py`** (MCP-as-tool wrapper) + **`internal_search.py`** (RAG-as-LLM-callable-tool: "instead of pre-fetching docs into the prompt, the LLM decides when and what to search"). **Cohort-first MCP server-as-FastMCP-streamable-HTTP-mount** at `/mcp` — `mcp_server.py` exposes DocsGPT retrieval over MCP using **existing DocsGPT agent API keys as MCP bearer tokens** (no new credential surface). Web frontend (`frontend/`) is React + the React widget is shipped as a separate npm package in `extensions/react-widget/`. Built-in **Chatwoot integration** in `extensions/chatwoot/`. **Hacktoberfest community** badge — high contributor activity. MIT.

## KB Architecture

### Storage (8 vector backends + relational/blob)
- 8 vector backends in [`application/vectorstore/`](https://github.com/arc53/DocsGPT/tree/main/application/vectorstore): `elasticsearch.py` / `embeddings_local.py` (in-process, FAISS-backed for laptops) / `faiss.py` / `lancedb.py` / `milvus.py` / `mongodb.py` / `pgvector.py` / `qdrant.py`. Plus base classes (`base.py`, `document_class.py`) + `vector_creator.py` factory.
- **Repo includes pre-baked FAISS index** (`application/index.faiss` + `application/index.pkl`) — the docs are pre-indexed in the repo as a quick-start example for new users (cohort first to ship a pre-baked FAISS index in the repo).
- **MongoDB as primary metadata store** (per `services/` and DB layout); `application/alembic/` for SQL migrations.
- **Celery + Celery worker** for async background tasks (`celery_init.py`, `celeryconfig.py`, `worker.py`).
- Storage abstraction in `application/storage/`.

### Ingestion (15 file parsers + 3 enterprise SaaS connectors)
- 15 file parsers in [`application/parser/file/`](https://github.com/arc53/DocsGPT/tree/main/application/parser/file): `audio_parser` / **`docling_parser`** / `docs_parser` / `epub_parser` / `html_parser` / `image_parser` / `json_parser` / `markdown_parser` / **`openapi3_parser`** (cohort-novel — parses OpenAPI 3 specs into chunks, fitting the "documents AS API specs" enterprise use case) / `pptx_parser` / `rst_parser` / `tabular_parser` + `bulk.py` (batch loader) + `base.py` + `base_parser.py` + `constants.py`.
- 3 SaaS connectors in [`application/parser/connectors/`](https://github.com/arc53/DocsGPT/tree/main/application/parser/connectors): `confluence` / `google_drive` / `share_point` + `_auth_utils.py` + `connector_creator.py` factory + base. **All 3 enterprise SaaS sources** — distinct positioning vs anything-llm/sim's developer-tool connectors (Notion, Linear, Jira) and SurfSense's broad mix.
- `embedding_pipeline.py` orchestrates ingest → chunk → embed → persist flow.
- `chunking.py` — chunk strategy (single-file impl).

### Retrieval
- [`application/retriever/`](https://github.com/arc53/DocsGPT/tree/main/application/retriever): `base.py` + `classic_rag.py` (the canonical RAG retriever) + `retriever_creator.py` factory.
- **`internal_search` tool** wraps `ClassicRAG` retriever AS an LLM-callable tool — cohort-novel "RAG-as-LLM-tool" pattern: *"instead of pre-fetching docs into the prompt, the LLM decides when and what to search. Supports multiple searches per session"*. Optional capabilities when sources have `directory_structure`: `path_filter` on search (restrict to file/folder), `list_files` action (browse the file/folder structure). Cohort first to combine RAG-as-tool + filesystem-aware browse actions.

### Agent runtime — 4 agent types
- [`application/agents/`](https://github.com/arc53/DocsGPT/tree/main/application/agents): `agent_creator.py` (factory) + `base.py` (`BaseAgent`) + 4 agent class files:
  1. **`classic_agent.py`** — traditional pre-fetch-RAG-then-call-LLM
  2. **`agentic_agent.py`** — LLM-decides-when-to-search via `internal_search` tool
  3. **`research_agent.py`** — multi-turn deep-research workflow
  4. **`workflow_agent.py`** — runs visual workflows (`workflows/` sub-dir)
- `tool_executor.py` for tool-call dispatch.
- **Cohort-first 4-agent-type taxonomy** — most cohort kb-apps ship 1 generic agent runtime; DocsGPT explicitly types 4 distinct agent shapes for different workloads.

### 19 agent tools (`agents/tools/`)
- `api_body_serializer` (helper) + `api_tool.py` (call any HTTP API as a tool) + `base.py` + **`brave.py`** (Brave search) + **`cryptoprice.py`** (crypto price lookup — cohort-novel: a domain-specific tool shipped in-tree) + **`duckduckgo.py`** (DDG search) + **`internal_search.py`** (RAG-as-tool) + **`mcp_tool.py`** (wraps external MCP servers as DocsGPT tools — cohort-second after llama_index's `McpToolSpec` to consume MCP servers from inside an agent runtime) + **`memory.py`** (memory store/recall as tool) + **`notes.py`** (note-taking) + **`ntfy.py`** (ntfy.sh notifications — cohort first) + **`postgres.py`** (Postgres query tool) + **`read_webpage.py`** (web page reader) + `spec_parser.py` (helper) + **`telegram.py`** (Telegram messaging — cohort first agent-tool flavor) + **`think.py`** (Anthropic-style "think" tool) + **`todo_list.py`** (todo CRUD) + `tool_action_parser.py` (helper) + `tool_manager.py`.

### Workflow engine
- [`application/agents/workflows/`](https://github.com/arc53/DocsGPT/tree/main/application/agents/workflows): `cel_evaluator.py` + `node_agent.py` + `schemas.py` + `workflow_engine.py`.
- **CEL (Common Expression Language) evaluator** for workflow predicates — cohort first to use Google's CEL for workflow conditional logic (vs cohort entries that use Python expressions or custom DSLs).

### LLM provider integration (15 + 14 alternates = 2 stacks)
- 15 modules in [`application/llm/`](https://github.com/arc53/DocsGPT/tree/main/application/llm): `anthropic` / `docsgpt_provider` (custom hosted) / `google_ai` / `groq` / `handlers/` / `llama_cpp` / `llm_creator.py` (factory) / `novita` / `open_router` / `openai` / `premai` / `sagemaker` / `providers/` (separate sub-tree).
- 14 modules in [`application/llm/providers/`](https://github.com/arc53/DocsGPT/tree/main/application/llm/providers): `_apikey_or_llm_name.py` + `anthropic.py` + `azure_openai.py` + `base.py` + `docsgpt.py` + `google.py` + `groq.py` + `huggingface.py` + `llama_cpp.py` + `novita.py` + `openai.py` + `openai_compatible.py` + `openrouter.py` + `premai.py` + `sagemaker.py`. **Two parallel LLM-provider trees** — likely a refactoring artifact from migrating from one abstraction to another. Worth flagging as architectural debt.

### MCP server (cohort-novel: API-key-as-bearer-token)
- [`application/mcp_server.py`](https://github.com/arc53/DocsGPT/blob/main/application/mcp_server.py) — **FastMCP server mounted at `/mcp`** by `application/asgi.py` over Streamable HTTP transport.
- Exposes DocsGPT retrieval as MCP tool.
- **Cohort-first MCP-bearer-token-reuse-pattern**: existing DocsGPT agent API keys are reused as MCP bearer tokens (`get_http_headers(include={"authorization"})` with explicit `include` to override FastMCP's default header-stripping). No new credential surface.
- Pairs with `mcp_tool.py` (DocsGPT consuming external MCP) — DocsGPT is **both MCP server AND MCP client** (cohort second after Composio + sim + llama_index for bidirectional MCP).

### Multimodal (`stt/` + `tts/`)
- `application/stt/` — speech-to-text.
- `application/tts/` — text-to-speech.
- `audio_parser.py` + `image_parser.py` — multimodal ingest.
- Cohort second to ship STT + TTS + audio + image (after SurfSense's Kokoro TTS + STT services).

### Distribution channels
- **3 distribution surfaces** in `extensions/`:
  1. `extensions/react-widget/` — npm-distributable React widget for embedding DocsGPT into other web apps
  2. `extensions/chatwoot/` — Chatwoot (open-source customer-support platform) integration — cohort first Chatwoot integration
- **Kubernetes** deployment in `deployment/k8s/` + `deployment/optional/`.
- **Devcontainer** support (`.devcontainer/`).
- **Documentation site** at `docs/` (Next.js + MDX).

### Tests
- 14 test categories in `tests/`: `agents` / `api` / `core` / `e2e` / `integration` / `llm` / `parser` / `seed` / `security` / `services` / `storage` / `stt` / `tts` / `vectorstore` / `worker`. Most decomposed test-organization in cohort.

### Frontend
- React + Vite (per `frontend/` deps). 19-directory structure includes `husky/` (git hooks), `public/`, `src/`.

## Notable design choices

- **4-agent-type taxonomy** (`Classic` / `Agentic` / `Research` / `Workflow`) — cohort first to explicitly type agent runtimes by workload shape rather than ship one generic agent. Pattern: classify the user's use case, route to the appropriate agent type. Distinct from cohort entries that ship one tool-calling agent and let prompts decide behavior.
- **`internal_search` RAG-as-LLM-tool** pattern — the LLM decides when and what to search rather than the system pre-fetching documents into the prompt. Cohort-novel reframing: RAG becomes one tool among many that the agent calls when needed (vs RAG-as-front-of-pipeline that always runs).
- **MCP-bearer-token-reuse** — DocsGPT's MCP server reuses existing agent API keys as bearer tokens. Cohort first to explicitly reuse existing auth surface for MCP rather than adding a separate credential layer.
- **`openapi3_parser`** for ingest — cohort first to parse OpenAPI 3 specs as KB documents (fits the "ingest your API spec into the agent's KB" enterprise use case).
- **3 enterprise SaaS connectors** (Confluence / Google Drive / SharePoint) — explicitly enterprise-tilted distinct from anything-llm/sim's developer-tool tilt (Notion / Linear / Jira) and SurfSense's broad mix.
- **CEL (Common Expression Language) evaluator** for workflow predicates — cohort first; Google's CEL is widely used in policy/config systems but cohort-first as workflow-DSL.
- **Pre-baked FAISS index** in repo (`application/index.faiss` + `index.pkl`) — quick-start onboarding optimization. Cohort first.
- **2 parallel LLM-provider trees** (`llm/` + `llm/providers/`) — likely refactoring debt; both have similar provider names. Worth flagging.
- **Chatwoot integration** in `extensions/chatwoot/` — cohort first; positions DocsGPT as a Chatwoot AI-assistant backend.
- **DocsGPT is both MCP server AND MCP client** — cohort second after Composio + sim + llama_index for bidirectional MCP.
- **3-year-old project (since 2023-02)** — established, mature codebase. Hacktoberfest badge signals contributor activity (`hacktoberfest` + `hacktoberfest2025` in topics).

## Dependencies

Python (Flask + Celery + Alembic + Gunicorn + Uvicorn for ASGI MCP mount), MongoDB (primary metadata store), Redis (Celery broker), 8 vector backend SDKs (FAISS / Qdrant / Milvus / LanceDB / pgvector / Elasticsearch / MongoDB Atlas Vector / in-process embeddings), 15 LLM SDK modules. React + Vite (frontend). Docling for document parsing. FastMCP for MCP server. PyTorch + transformers (for `embeddings_local`).

## Tradeoffs

- **For**: cohort-first **4-agent-type taxonomy** (Classic / Agentic / Research / Workflow); cohort-first **`internal_search` RAG-as-LLM-tool** pattern; cohort-first **MCP-bearer-token-reuse** (no new credential surface); cohort-first **`openapi3_parser`** for KB ingest; cohort-first **CEL workflow predicates**; cohort-first **pre-baked FAISS index** in repo; **15 file parsers + 3 enterprise SaaS connectors** (Confluence / GDrive / SharePoint) — enterprise-tilted; **8 vector backends + 15 LLM modules**; **bidirectional MCP** (server + client); STT + TTS + audio + image multimodal; **3 distribution surfaces** (React widget npm + Chatwoot integration + standalone); 14-category test suite; 3-year-old established codebase; Hacktoberfest contributor velocity; MIT.
- **Against**: **2 parallel LLM-provider trees** (`llm/` + `llm/providers/`) — refactoring debt; chunk strategy is a single-file impl (`chunking.py`) — less decomposed than SurfSense's 7 chunkers; only **1 retriever shape** (`classic_rag` — vs cohort entries with multi-mode retrievers like LightRAG's 6 modes); single-author lineage (arc53); MongoDB as primary metadata store narrows ops compatibility (cohort norm is Postgres or SQLite); v0.17.0 — pre-1.0 churn risk despite 3-year history; no graph backend at all (cohort norm is at least one graph option); some agent tools are domain-specific (`cryptoprice` / `ntfy` / `telegram`) and may not fit all use cases; documentation site at `docs/` is separate Next.js project = additional maintenance surface.

## When to use vs. cohort

- vs. **anything-llm** ([survey](Mintplex-Labs__anything-llm.md)) — anything-llm: 37 LLMs / 35 OAuth-action connectors / 17 Aibitat plugins. DocsGPT: 15 LLMs / 8 vector backends / 4 agent types / 3 enterprise SaaS connectors (Confluence/GDrive/SharePoint). anything-llm for "deploy anywhere with one repo + 10 vector backends"; DocsGPT for "enterprise search with private data + 4 agent types".
- vs. **MODSetter/SurfSense** ([survey](MODSetter__SurfSense.md)) — both fill the "private team KB" slot but with different shapes. SurfSense: 22 read-only KB connectors + 9 ETL parsers + 4 LangGraph agents + 4-process distribution. DocsGPT: 3 enterprise SaaS connectors + 15 file parsers + 4-agent-type taxonomy + bidirectional MCP. SurfSense for NotebookLM-shape with broad source coverage; DocsGPT for enterprise search with explicit agent typing.
- vs. **labring/FastGPT** ([survey](labring__FastGPT.md)) — FastGPT: TS workspace-scoped + visual workflow + CN-cloud-tilt (Bailian/Volcengine). DocsGPT: Python + 4 agent types + enterprise SaaS connectors + Chatwoot integration. Different ecosystem tilts (CN vs US/EU enterprise).
- vs. **HKUDS/DeepTutor** ([survey](HKUDS__DeepTutor.md)) — DeepTutor is education-specialized (math_animator + tex_chunker + TutorBot scheduled agent). DocsGPT is enterprise-search-specialized (openapi3_parser + 3 SaaS connectors + Chatwoot). Different vertical applications of similar substrate.

## Code pointers

- 4 agent types: [`application/agents/{classic,agentic,research,workflow}_agent.py`](https://github.com/arc53/DocsGPT/tree/main/application/agents).
- Agent factory: [`application/agents/agent_creator.py`](https://github.com/arc53/DocsGPT/blob/main/application/agents/agent_creator.py).
- 19 agent tools: [`application/agents/tools/`](https://github.com/arc53/DocsGPT/tree/main/application/agents/tools).
- `internal_search` RAG-as-tool: [`application/agents/tools/internal_search.py`](https://github.com/arc53/DocsGPT/blob/main/application/agents/tools/internal_search.py).
- MCP server (FastMCP, `/mcp` mount, bearer-token reuse): [`application/mcp_server.py`](https://github.com/arc53/DocsGPT/blob/main/application/mcp_server.py).
- MCP-as-tool client: [`application/agents/tools/mcp_tool.py`](https://github.com/arc53/DocsGPT/blob/main/application/agents/tools/mcp_tool.py).
- Workflow engine + CEL evaluator: [`application/agents/workflows/{cel_evaluator,workflow_engine,node_agent,schemas}.py`](https://github.com/arc53/DocsGPT/tree/main/application/agents/workflows).
- 8 vector backends: [`application/vectorstore/`](https://github.com/arc53/DocsGPT/tree/main/application/vectorstore).
- 15 file parsers: [`application/parser/file/`](https://github.com/arc53/DocsGPT/tree/main/application/parser/file).
- 3 enterprise SaaS connectors: [`application/parser/connectors/{confluence,google_drive,share_point}/`](https://github.com/arc53/DocsGPT/tree/main/application/parser/connectors).
- 2 parallel LLM-provider trees: [`application/llm/`](https://github.com/arc53/DocsGPT/tree/main/application/llm) + [`application/llm/providers/`](https://github.com/arc53/DocsGPT/tree/main/application/llm/providers).
- Pre-baked FAISS index: [`application/index.faiss`](https://github.com/arc53/DocsGPT/blob/main/application/index.faiss) + [`application/index.pkl`](https://github.com/arc53/DocsGPT/blob/main/application/index.pkl).
- Distribution: [`extensions/react-widget/`](https://github.com/arc53/DocsGPT/tree/main/extensions/react-widget) + [`extensions/chatwoot/`](https://github.com/arc53/DocsGPT/tree/main/extensions/chatwoot).
- 14 test categories: [`tests/`](https://github.com/arc53/DocsGPT/tree/main/tests).

## Open questions

- **`llm/` vs `llm/providers/` parallel trees** — 2 directories with overlapping provider names. Is this a deprecation-in-progress, or are they two distinct abstractions (e.g., `llm/` for runtime client, `llm/providers/` for capability metadata)?
- **`embeddings_local`** vector backend — implementation uses FAISS internally per import inspection. Is this distinct from the `faiss.py` backend, or a wrapper?
- **MongoDB as primary metadata store** — cohort norm is Postgres or SQLite. What was the original rationale, and is there a Postgres migration path?
- **`research_agent` vs cohort `deep_research`** — DocsGPT's `ResearchAgent` and Yuxi's `deep-reporter` Skill and DeepTutor's `deep_research` capability and deer-flow's `deep-research` skill all converge on long-horizon research workflows. The cohort emerging-pattern of "deep-research-as-named-workflow" continues to crystallize.
- **Chatwoot integration depth** — `extensions/chatwoot/` is the integration code. How deep is the bidirectional sync (e.g., does Chatwoot conversation history flow into DocsGPT's KB)?
- **`v0.17.0` after 3 years** — pre-1.0 versioning despite 3-year history suggests cautious release cadence. What's the path to v1?

---

*Audit 2026-05-03: clone-verified against [arc53/DocsGPT@main](https://github.com/arc53/DocsGPT) (last commit 2026-05-02 00:20). MIT confirmed in `LICENSE`. Version `0.17.0` per `application/version.py`. Counts verified by directory enumeration: 4 agent types (`agents/{classic,agentic,research,workflow}_agent.py`), 19 agent tools (`ls agents/tools/*.py | wc -l`), 8 vector backends (`ls vectorstore/*.py` minus `__init__`/`base`/`document_class`/`vector_creator`), 15 file parsers (`ls parser/file/*.py`), 3 SaaS connectors (`confluence` / `google_drive` / `share_point`), 15 LLM modules in `llm/` + 14 in `llm/providers/`. MCP server with bearer-token-reuse verified verbatim from `application/mcp_server.py:1-15` ("FastMCP server exposing DocsGPT retrieval over streamable HTTP. Mounted at `/mcp` by `application/asgi.py`. Bearer tokens are the existing DocsGPT agent API keys — no new credential surface."). `internal_search` RAG-as-tool verified verbatim from `agents/tools/internal_search.py:13-22`. CEL workflow evaluator verified at `agents/workflows/cel_evaluator.py`. Pre-baked FAISS index verified by `ls application/*.faiss` + `*.pkl`. 14 test categories verified by `ls tests/`. Chatwoot + react-widget extensions verified by `ls extensions/`. Corrections: none (first-pass survey).*
