# MODSetter/SurfSense

- **Stars:** 14,051 · **Last push:** 2026-05-01 · **Created:** 2024-07-30 · **License:** Apache-2.0 · **Lang:** Python (FastAPI) + TypeScript (Next.js + Electron) · **Version:** `0.0.19`
- **Category:** kb-app (privacy-focused **NotebookLM alternative for teams**)
- **Author:** MODSetter

## TL;DR

A 4-process system that delivers a **NotebookLM-style team KB** with **no data limits**: FastAPI backend (`surfsense_backend/`) + Next.js web app (`surfsense_web/`) + Electron desktop app (`surfsense_desktop/`) + browser extension (`surfsense_browser_extension/`), all sharing the same Postgres + Drizzle schema and version `0.0.19`. Ships **22 connector indexers** (Airtable / BookStack / ClickUp / Confluence / Discord / Dropbox / Elasticsearch / GitHub / Google Calendar / Google Drive / Google Gmail / Jira / Linear / local-folder / Luma / Notion / Obsidian / OneDrive / Slack / Teams / web-crawler) — broadest first-party connector set in cohort *for read-only KB ingestion* (vs anything-llm / sim's 35 OAuth-action connectors). **9 ETL parsers** (audio / Azure Doc Intelligence / direct_convert / Docling / LlamaCloud / plaintext / unstructured / vision_llm) + dedicated `kokoro_tts_service` (TTS) + `stt_service` (STT). 4 internal LangGraph agents — `autocomplete` / `new_chat` / `podcaster` / `video_presentation` — with `chat_deepagent.py` as the chat-time DeepAgents wrapper. **Redis + Celery + slowapi rate-limiter** scaffolding. **5 README languages** (en / es / hi / pt-BR / zh-CN). Apache-2.0.

## KB Architecture

### Storage
- Postgres (Drizzle on the web side, SQLAlchemy + Alembic on the backend) — same schema both sides.
- Pgvector for embeddings (per the hybrid-search retriever's vector-search path on `Chunk` ORM rows).
- Redis for caching + rate-limiting (slowapi).
- No graph backend.
- Document hashing via `compute_content_hash` + `compute_identifier_hash` + `compute_unique_identifier_hash` (3 hash kinds for dedup at different identifier granularities — cohort first to ship 3-tier identifier hashing).

### Connectors (22 indexers)
- [`tasks/connector_indexers/`](https://github.com/MODSetter/SurfSense/tree/main/surfsense_backend/app/tasks/connector_indexers): 22 per-source `*_indexer.py` files plus `base.py`, dispatched via Celery tasks.
- [`app/connectors/`](https://github.com/MODSetter/SurfSense/tree/main/surfsense_backend/app/connectors): per-connector business logic (some have a `_history.py` sibling for incremental-sync state — Airtable, ClickUp, Confluence, Jira, Notion, Slack, Teams).
- Source-by-source incremental-sync model: each `*_history.py` tracks last-synced-cursor / etag / timestamp per connector account.
- **22 read-only KB connectors** is the broadest cohort connector count for "ingest into KB" use — anything-llm and sim's 35 connectors are OAuth-action-shaped (write to external services), SurfSense's are read-into-KB-shaped.

### ETL pipeline (9 parsers)
- [`etl_pipeline/`](https://github.com/MODSetter/SurfSense/tree/main/surfsense_backend/app/etl_pipeline): `etl_document.py`, `etl_pipeline_service.py`, `file_classifier.py`, `parsers/`.
- 9 parsers in [`etl_pipeline/parsers/`](https://github.com/MODSetter/SurfSense/tree/main/surfsense_backend/app/etl_pipeline/parsers): `audio` / `azure_doc_intelligence` / `direct_convert` / `docling` / `llamacloud` / `plaintext` / `unstructured` / `vision_llm`. Cohort first to bundle Azure Document Intelligence + Docling + LlamaCloud + Unstructured + Vision-LLM parsers in the same project (typical cohort entries pick 1-2 parser backends).
- File-classifier dispatch routes documents to the right parser based on MIME type + magic bytes.

### Indexing pipeline
- [`indexing_pipeline/indexing_pipeline_service.py`](https://github.com/MODSetter/SurfSense/blob/main/surfsense_backend/app/indexing_pipeline/indexing_pipeline_service.py) — orchestrates: connector_document → chunker → embedder → summarizer → persistence (with explicit `pipeline_logger.py` events: `log_batch_aborted`, `log_chunking_overflow`, `log_doc_skipped_unknown`, `log_document_queued`, `log_document_requeued`, …).
- Document-level summarization built into the pipeline (`document_summarizer.py`) — cohort first to make doc-summary a first-class indexing-pipeline stage (vs cohort entries that bolt summarization on at query time).
- Adapters for ingestion sources: `file_upload_adapter.py` for direct file uploads.
- Explicit `EMBEDDING_ERRORS`, `PERMANENT_LLM_ERRORS`, `RETRYABLE_LLM_ERRORS` taxonomies in `indexing_pipeline/exceptions.py` — typed retry buckets (cohort-first explicit exception-typing for retry classification).

### Hybrid retrieval
- [`retriever/`](https://github.com/MODSetter/SurfSense/tree/main/surfsense_backend/app/retriever): two retrievers — `chunks_hybrid_search.py` (`ChucksHybridSearchRetriever` — note the `Chuck` typo in the class name) + `documents_hybrid_search.py` (document-level retriever).
- **Document-grouped vs chunk-based reranking** — `reranker_service.rerank_documents` accepts both formats (per the docstring): "Document-grouped (new format): Has `document_id`, `chunks` list, and `content` (concatenated)" vs "Chunk-based (legacy format): Individual chunks with `chunk_id` and `content`". Cohort first to support **document-grouped reranking** — most cohort rerankers operate at the chunk level only.
- `_MAX_FETCH_CHUNKS_PER_DOC = 20` — caps chunks-per-document to bound rerank cost.

### LangGraph agents (4 internal agents)
- [`agents/`](https://github.com/MODSetter/SurfSense/tree/main/surfsense_backend/app/agents): 4 sub-graphs — `autocomplete/`, `new_chat/`, `podcaster/`, `video_presentation/`.
- Each agent has the standard LangGraph file shape: `configuration.py`, `graph.py`, `nodes.py`, `prompts.py`, `state.py`, `utils.py`.
- **`new_chat/chat_deepagent.py`** — wraps DeepAgents for chat-time tool-use. `checkpointer.py` for cross-session state. `memory_extraction.py` for fact extraction during chat. `sandbox.py` for code-execution tool surface.
- **Podcaster agent** generates audio podcasts from KB content using `kokoro_tts_service` (Kokoro TTS).
- **Video presentation agent** generates video presentations from KB content (cohort first specialized video-generation agent).

### LLM + multimodal services
- [`services/llm_router_service.py`](https://github.com/MODSetter/SurfSense/blob/main/surfsense_backend/app/services/llm_router_service.py) + [`llm_service.py`](https://github.com/MODSetter/SurfSense/blob/main/surfsense_backend/app/services/llm_service.py) — LiteLLM-based router, with a curated `OPENROUTER_SLUG_TO_PROVIDER` map (`openai` / `anthropic` / `google` / `mistralai` / `cohere` / `x-ai` / `perplexity`) gating which OpenRouter slugs translate cleanly to native provider APIs.
- [`services/model_list_service.py`](https://github.com/MODSetter/SurfSense/blob/main/surfsense_backend/app/services/model_list_service.py) — fetches OpenRouter's public model catalog with **24-hour cache** and a local fallback JSON file. Cohort first to fetch live model lists from OpenRouter's API with explicit cache TTL + fallback file.
- [`services/kokoro_tts_service`](https://github.com/MODSetter/SurfSense/blob/main/surfsense_backend/app/services/kokoro_tts_service.py) — Kokoro TTS for podcast generation.
- `services/stt_service.py` — speech-to-text for audio ingestion.
- `services/image_gen_router_service.py` — image generation routing.
- `services/openrouter_integration_service.py` — direct OpenRouter integration alongside LiteLLM router.
- `services/composio_service.py` — **Composio integration** (cohort cross-link to [ComposioHQ/composio](ComposioHQ__composio.md) — SurfSense uses Composio's toolkit catalog as one of its tool-source backends).
- `services/docling_service.py` — Docling integration for advanced document parsing.

### Multi-process distribution
- **4 separate apps** all version-pinned to `0.0.19` (single source-of-truth `VERSION` file at repo root):
  1. `surfsense_backend/` — FastAPI + Celery + Postgres + Redis
  2. `surfsense_web/` — Next.js 15 + Drizzle + biome (lint) + assistant-ui (`@assistant-ui/react`) + Vercel AI SDK (`@ai-sdk/react`) — cohort first to ship Vercel `assistant-ui` for the chat surface
  3. `surfsense_desktop/` — Electron app reusing the web frontend (concurrently runs `pnpm --dir ../surfsense_web dev` + `electron .`); ships installers for macOS / Windows / Linux via electron-builder
  4. `surfsense_browser_extension/` — Chrome extension with `background/` + `routes/` + `lib/` + `assets/`

### i18n + docs
- 5 README languages: `en` (default) / `es` / `hi` / `pt-BR` / `zh-CN` — cohort second after deepwiki-open's 10 README languages.
- Web app has `i18n/` directory + `messages/` for translations.
- Cursor-skills directory (`.cursor/skills/`) for Cursor-IDE integration.

## Notable design choices

- **Privacy-focused NotebookLM alternative shape** — README explicitly positions as "alternative to NotebookLM for teams with no data limits". Cohort first to fill the NotebookLM-shape KB slot (multi-source ingest → conversational + audio/video output for team knowledge management).
- **22 read-only KB connectors** as a separate camp from action-OAuth connectors — anything-llm's 35 + sim's 35 connectors do "agent takes action in external service via OAuth"; SurfSense's 22 do "ingest external content into searchable KB". Different design intent within the "many connectors" pattern.
- **9 ETL parser backends co-existing** (Azure DI + Docling + LlamaCloud + Unstructured + Vision-LLM + audio + plaintext + direct-convert) — cohort first to bundle 5 enterprise-tier parsers in one project. Most cohort entries pick 1-2 parser strategies; SurfSense picks "let the user route by file type to the best parser".
- **Document-grouped reranking** alongside chunk-based — `reranker_service.rerank_documents` handles both shapes (`{document_id, chunks, content}` for grouped; `{chunk_id, content}` for legacy). Cohort first to support document-level reranking explicitly.
- **3-tier identifier hashing** (`compute_content_hash` + `compute_identifier_hash` + `compute_unique_identifier_hash`) — cohort first to type identity at 3 granularities for connector dedup (per-content / per-source-id / per-(source × tenant)).
- **Document-summary as first-class indexing-pipeline stage** — `document_summarizer.py` runs at ingest, not at query time. Cohort first to bake doc-summary into the indexing path itself.
- **Typed retry-classification taxonomy** — `EMBEDDING_ERRORS`, `PERMANENT_LLM_ERRORS`, `RETRYABLE_LLM_ERRORS` enums in `indexing_pipeline/exceptions.py` drive batch-retry decisions explicitly. Cohort-first explicit retry-bucket typing.
- **Dedicated podcaster + video-presentation agents** — `podcaster/` generates audio via Kokoro TTS, `video_presentation/` generates videos. Cohort first specialized podcast + video generation as separate agent sub-graphs (vs cohort entries that treat audio/video as ETL output formats only).
- **Live OpenRouter model catalog with 24-hour cache + local fallback** — `model_list_service.py` is cohort first to dynamically fetch the OpenRouter model catalog rather than hardcoding it. The `OPENROUTER_SLUG_TO_PROVIDER` curated mapping handles the divergence between OpenRouter slugs and native provider API names (with explicit notes about why deepseek / qwen / ai21 / microsoft are excluded).
- **4-process distribution** (backend / web / desktop-Electron / browser-extension) — all sharing one Postgres schema and one `0.0.19` version. Cohort widest single-product distribution surface (vs sim's 3 apps + helm + browser-extension; vs anything-llm's server + UI + extension + 6 cloud-deploy templates).
- **Composio service integration** — SurfSense uses Composio as a tool-source backend (`services/composio_service.py`). Cohort cross-link: 2 cohort entries now consume Composio's toolkit catalog directly.
- **`assistant-ui` for chat UX** — `@assistant-ui/react ^0.12.19` + `@assistant-ui/react-markdown ^0.12.6` (cohort first; sim uses custom Drizzle-typed React components).

## Dependencies

**Backend** (Python): FastAPI + uvicorn + SQLAlchemy + Alembic + Celery + Redis + slowapi (rate-limit) + LiteLLM + LangGraph (per `agents/` shape) + DeepAgents (per `chat_deepagent.py`) + Kokoro TTS + Docling + Unstructured + LlamaCloud + Azure Doc Intelligence + Composio. **Web**: Next.js 15 + Turbopack + Drizzle + biome (lint) + Vercel AI SDK (`@ai-sdk/react ^1.2.12`) + assistant-ui (`@assistant-ui/react ^0.12.19`) + ariakit + react-hook-form + zod + Cloudflare Turnstile (`@marsidev/react-turnstile ^1.5.0`) + Babel-standalone (in-browser code execution) + drizzle-kit. **Desktop**: Electron + electron-builder + concurrently + wait-on. **Browser extension**: standard manifest-v3 stack.

## Tradeoffs

- **For**: cohort-first **NotebookLM-shape KB** with no data limits; **22 read-only KB connectors** (broadest in cohort for ingest-into-KB shape); **9 ETL parser backends** including 5 enterprise-tier (Azure DI + Docling + LlamaCloud + Unstructured + Vision-LLM); **document-grouped reranking** alongside chunk-based; **3-tier identifier hashing** for connector dedup; **document-summary as first-class indexing stage**; **typed retry-classification taxonomy**; **dedicated podcaster + video-presentation agents**; **live OpenRouter model catalog** with 24h cache + fallback; **4-process distribution** (backend + web + Electron desktop + browser extension) all sharing one Postgres schema and one VERSION file; cohort cross-link to Composio (consumes toolkit catalog); 5 README languages; Apache-2.0.
- **Against**: very early version (`0.0.19` — pre-1.0 churn risk); single-author project (sustainability); 4-process distribution = 4 deployment surfaces to maintain; class name typo in `ChucksHybridSearchRetriever` (`Chunks` mistyped) suggests rushed code review; LangGraph + DeepAgents + Celery + Redis = heavy dep stack; the privacy-focused positioning is largely "you self-host" — no cloud SLA documented; OpenRouter dependency for model catalog means SurfSense breaks if OpenRouter API is down (24h cache softens this); browser extension distribution path not yet documented in repo (no Chrome Web Store listing referenced).

## When to use vs. cohort

- vs. **anything-llm** ([survey](Mintplex-Labs__anything-llm.md)) — anything-llm: 37 LLM providers + 35 OAuth-action connectors + Aibitat agent + 17 plugins. SurfSense: 22 read-only KB connectors + 9 ETL parsers + 4 LangGraph agents + audio/video output. anything-llm for "agent takes actions in external services"; SurfSense for "team knowledge base from many sources, with podcast/video output".
- vs. **deepwiki-open** ([survey](AsyncFuncAI__deepwiki-open.md)) — deepwiki-open is server-shaped wiki-compiler for any GitHub/GitLab/BitBucket repo. SurfSense is general-purpose KB for 22 source types with 4-process distribution. Different scope (deepwiki = code wiki; SurfSense = team KB across all source types).
- vs. **khoj-ai/khoj** ([survey](khoj-ai__khoj.md)) — khoj is search-first cross-modal with Obsidian/Notion/GitHub sync + self-hosted Postgres. SurfSense is similar shape but adds explicit podcaster/video-presentation agents + browser extension + Electron desktop. khoj for "personal knowledge with cross-modal search"; SurfSense for "team knowledge with multi-output content generation".
- vs. **Tencent/WeKnora** ([survey](Tencent__WeKnora.md)) — WeKnora is Tencent enterprise-RAG with Auto-Wiki + 7 IM platforms + skill-mounted sandbox. SurfSense is privacy-focused team-KB. Pick WeKnora for CN enterprise + IM-channel coverage; SurfSense for self-hosted no-data-limits + multi-output.
- vs. **labring/FastGPT** ([survey](labring__FastGPT.md)) — FastGPT is workspace-scoped multi-LLM kb-app with visual workflow + CN-cloud-tilted (Bailian / Volcengine / Qwen). SurfSense is US/global-cloud-tilted (OpenRouter-based) without visual workflow but with podcast/video output.

## Code pointers

- 22 connector indexers: [`surfsense_backend/app/tasks/connector_indexers/`](https://github.com/MODSetter/SurfSense/tree/main/surfsense_backend/app/tasks/connector_indexers).
- 9 ETL parsers: [`surfsense_backend/app/etl_pipeline/parsers/`](https://github.com/MODSetter/SurfSense/tree/main/surfsense_backend/app/etl_pipeline/parsers).
- Indexing pipeline orchestration: [`surfsense_backend/app/indexing_pipeline/indexing_pipeline_service.py`](https://github.com/MODSetter/SurfSense/blob/main/surfsense_backend/app/indexing_pipeline/indexing_pipeline_service.py).
- Hybrid retrievers (chunk + document): [`surfsense_backend/app/retriever/{chunks,documents}_hybrid_search.py`](https://github.com/MODSetter/SurfSense/tree/main/surfsense_backend/app/retriever).
- Reranker (document-grouped + chunk-based): [`surfsense_backend/app/services/reranker_service.py`](https://github.com/MODSetter/SurfSense/blob/main/surfsense_backend/app/services/reranker_service.py).
- LangGraph agents: [`surfsense_backend/app/agents/{autocomplete,new_chat,podcaster,video_presentation}/`](https://github.com/MODSetter/SurfSense/tree/main/surfsense_backend/app/agents).
- DeepAgents chat wrapper: [`surfsense_backend/app/agents/new_chat/chat_deepagent.py`](https://github.com/MODSetter/SurfSense/blob/main/surfsense_backend/app/agents/new_chat/chat_deepagent.py).
- LLM router + OpenRouter slug map: [`surfsense_backend/app/services/llm_router_service.py`](https://github.com/MODSetter/SurfSense/blob/main/surfsense_backend/app/services/llm_router_service.py) + [`model_list_service.py`](https://github.com/MODSetter/SurfSense/blob/main/surfsense_backend/app/services/model_list_service.py).
- Composio integration: [`surfsense_backend/app/services/composio_service.py`](https://github.com/MODSetter/SurfSense/blob/main/surfsense_backend/app/services/composio_service.py).
- 3-tier identifier hashing: [`surfsense_backend/app/indexing_pipeline/document_hashing.py`](https://github.com/MODSetter/SurfSense/blob/main/surfsense_backend/app/indexing_pipeline/document_hashing.py).
- Typed retry-classification: [`surfsense_backend/app/indexing_pipeline/exceptions.py`](https://github.com/MODSetter/SurfSense/blob/main/surfsense_backend/app/indexing_pipeline/exceptions.py) (`EMBEDDING_ERRORS`, `PERMANENT_LLM_ERRORS`, `RETRYABLE_LLM_ERRORS`).
- 4-process distribution: [`surfsense_{backend,web,desktop,browser_extension}/`](https://github.com/MODSetter/SurfSense).

## Open questions

- **Pgvector vs separate vector backend** — the survey infers pgvector usage from `Chunk` ORM rows but the repo's `db.py` should clarify if pgvector or another backend is wired in.
- **Class name typo** — `ChucksHybridSearchRetriever` (should be `ChunksHybridSearchRetriever`). Is this intentional / cute, or a code-review miss?
- **OpenRouter dependency** — what happens if OpenRouter's API is unreachable for >24 hours? The local fallback file is shipped, but how often is it refreshed?
- **Browser extension distribution path** — code is in `surfsense_browser_extension/` but no Chrome Web Store / Firefox Add-ons listing referenced. Is the extension currently distributable end-to-end?
- **Desktop app + browser extension overlap** — both surfaces let users save/clip web content. What's the intended UX split?

---

*Audit 2026-05-02: clone-verified against [MODSetter/SurfSense@main](https://github.com/MODSetter/SurfSense) (last commit 2026-05-01 22:57). Apache-2.0 confirmed in `LICENSE`. Single-source `VERSION 0.0.19` confirmed at repo root and matches all 4 sub-projects. Connector indexers=22 verified by `ls surfsense_backend/app/tasks/connector_indexers/` minus `__init__.py` and `base.py`. ETL parsers=9 verified by `ls etl_pipeline/parsers/` minus `__init__.py`. LangGraph agents=4 verified by `ls agents/` minus `__init__.py`. Hybrid retrievers (chunk + document) verified by `ls retriever/`. Document-grouped reranker support verified at `services/reranker_service.py:24-30` docstring. 3-tier identifier hashing verified at `indexing_pipeline/indexing_pipeline_service.py:20-25` (imports `compute_content_hash`, `compute_identifier_hash`, `compute_unique_identifier_hash`). Typed retry-error enums verified at `indexing_pipeline/exceptions.py` (`EMBEDDING_ERRORS`, `PERMANENT_LLM_ERRORS`, `RETRYABLE_LLM_ERRORS`). OpenRouter live-catalog with 24h cache + fallback verified at `services/model_list_service.py:1-50`. Kokoro TTS verified at `services/kokoro_tts_service.py` (`from kokoro import KPipeline`). Composio integration verified by `services/composio_service.py` existence. 4-process distribution verified by repo top-level layout. Vercel `@assistant-ui/react ^0.12.19` + `@ai-sdk/react ^1.2.12` verified at `surfsense_web/package.json`. 5 README languages verified by `ls README.*.md` (en + es + hi + pt-BR + zh-CN). Class name typo `ChucksHybridSearchRetriever` confirmed verbatim at `retriever/chunks_hybrid_search.py:11`. Corrections: none (first-pass survey).*
