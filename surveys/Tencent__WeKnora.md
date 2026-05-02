# Survey: Tencent/WeKnora

**Date:** 2026-05-01
**Stars:** 14,124 · **Last push:** 2026-04-30 · **Created:** 2025 · **Version:** `0.5.1`
**Category:** kb-app
**Slug:** [Tencent/WeKnora](https://github.com/Tencent/WeKnora)

---

## TL;DR (3 lines)

- **What it is:** Tencent's open-source RAG + Agent + **Auto-Wiki** platform — Go backend (gin/pgx/asynq) + a separate Python `docreader/` gRPC service + Python MCP server + Vue/React frontend + WeChat mini-program. Distributed via GitHub, **WeChat Dialog Open Platform**, a Chrome extension, and a ClawHub skill marketplace listing.
- **How its KB works:** **7-backend retriever zoo** behind one `retriever/` interface — Postgres + pgvector, Milvus, Qdrant, Elasticsearch (v7+v8), Weaviate, sqlite-vec, **Neo4j as the graph backend**. Chat pipeline is a fully-explicit step graph (`query_understand → query_expansion → search / search_parallel / search_entity → merge_overlap / merge_expand → wiki_boost → rerank → ...`). Memory layer is an LLM-driven **conversation consolidator** that summarizes old turns when token count exceeds 0.5 × context-window. Skills follow "Claude's Progressive Disclosure" pattern (frontmatter discovery first, then body).
- **Verdict:** Pick when you need a **production-grade Chinese-and-global RAG platform with Auto-Wiki, 7 vector backends, 7 IM platform adapters, Docker / k8s sandboxes, and skill bundles**, and you're OK running Go + Python + Postgres + Redis + (vector backend) + (object store) + an asynq job queue. Skip if you want a memory framework or a single-binary library — WeKnora is the most operationally heavy repo in this cohort after Onyx.

## KB Architecture

### Storage
- **Vector store:** Pluggable factory at [`internal/application/repository/retriever/`](https://github.com/Tencent/WeKnora/tree/main/internal/application/repository/retriever) — **`postgres`** (pgvector via `pgvector-go`), **`milvus`** (`milvus-io/milvus/client/v2`), **`qdrant`** (`qdrant/go-client`), **`elasticsearch`** (both v7 and v8 SDKs), **`weaviate`**, **`sqlite`** (`asg017/sqlite-vec-go-bindings`), **`neo4j`** (Neo4j-as-vector via the Go driver). Most pluggable vector layer in this cohort.
- **Graph store:** **Neo4j** (`neo4j/neo4j-go-driver/v6`) wired into the same retriever registry as a graph backend. Surfaced through `query_knowledge_graph` agent tool + `search_entity` chat-pipeline step.
- **Metadata / structured:** **Postgres** via `pgx/v5` + `golang-migrate/migrate/v4`; SQLite for tests and embedded deployments. The `tenant.go` repo + `tenant_disabled_shared_agent.go` enforce per-tenant scoping.
- **Object / blob:** **6-backend factory** at [`internal/application/service/file/`](https://github.com/Tencent/WeKnora/tree/main/internal/application/service/file) — **COS** (Tencent Cloud), **OSS** (Alibaba Cloud), **TOS** (Volcengine), **MinIO**, **S3** (AWS), **local**. Largest blob-backend surface in cohort.

### Ingestion / Extraction
- **Source types accepted:** Documents via the separate **Python `docreader/` gRPC service**: PDF (`pdfplumber` + `pypdf` + `pypdf2`), DOCX (`python-docx` + `docx2_parser` + `docx_parser` chain), Excel (`excel_parser`), Markdown (`mistletoe` + `markdown` + `markdownify`), HTML (`goose3`, `trafilatura`, `playwright`-rendered), images (`paddleocr` + VLM), antiword for legacy DOC, Markitdown for catch-all. **Three native KB connectors** at [`internal/datasource/connector/`](https://github.com/Tencent/WeKnora/tree/main/internal/datasource/connector) — **Feishu (Lark)**, **Notion**, **Yuque**.
- **Chunking strategy:** Multi-stage pipeline in `chat_pipeline/` — `merge_overlap.go` + `merge_expand.go` + `merge_history.go` + `merge_faq.go` for context expansion; `query_understand.go` + `query_expansion.go` for query rewriting; per-format chunkers in `docreader/splitter/`.
- **Entity / fact extraction:** **LLM-based** via `extract_entity.go` chat-pipeline step + standalone `extract.go` service. Knowledge graph populated through Neo4j; surfaced via `query_knowledge_graph` agent tool.
- **Schema:** **Document → chunk + KG triples + FAQ + wiki pages**. The Auto-Wiki feature ([wiki_ingest*.go](https://github.com/Tencent/WeKnora/blob/main/internal/application/service/wiki_ingest.go), `wiki_page.go`, `wiki_linkify.go`, `wiki_lint.go`, `wiki_ingest_dedup.go`, `wiki_ingest_cite.go`) materializes a *navigable wiki* from KB content, with citation-aware linking and dedup.

### Retrieval
- **Modes:** Step-graph chat pipeline ([`internal/application/service/chat_pipeline/`](https://github.com/Tencent/WeKnora/tree/main/internal/application/service/chat_pipeline)) — `load_history → query_understand → query_expansion → search` (or `search_parallel` / `search_entity`) → `merge_overlap → merge_expand → wiki_boost → rerank → filter_top_k → into_chat_message → chat_completion(_stream)`. FAQ-aware via `knowledgebase_search_faq.go` + `merge_faq.go`. **Hybrid keyword + dense + graph retrieval** all behind one fusion layer (`knowledgebase_search_fusion.go`).
- **Reranker:** Pluggable via [`internal/models/rerank/`](https://github.com/Tencent/WeKnora/tree/main/internal/models/rerank); a separate **Python rerank server demo** ([`rerank_server_demo.py`](https://github.com/Tencent/WeKnora/blob/main/rerank_server_demo.py)) is shipped as a reference HTTP wrapper for HuggingFace cross-encoders / OpenAI / Cohere-API-shaped backends.
- **Top-k defaults:** Configurable via `filter_top_k.go`; per-pipeline + per-knowledge-base overrides.
- **Context assembly:** [`internal/application/service/llmcontext/`](https://github.com/Tencent/WeKnora/tree/main/internal/application/service/llmcontext) with two pluggable storage backends (`memory_storage.go`, `redis_storage.go`) behind `storage.go` interface. Citation processor + dedup + "wiki_boost" prioritizes wiki-confirmed pages when retrieving.

### Memory model
- **Tiers:**
  - **KB chunks** (one of 7 vector backends).
  - **Knowledge graph** (Neo4j entities/relationships).
  - **Wiki pages** (auto-generated navigable wiki — citations + linkify + dedup + lint).
  - **Conversation history + LLM context store** (Postgres + Redis).
  - **Agent memory** — [`internal/agent/memory/consolidator.go`](https://github.com/Tencent/WeKnora/blob/main/internal/agent/memory/consolidator.go) compresses old conversation turns via LLM summarization. **Triggered when `token_count > 0.5 × MaxContextTokens`**; `maxConsolidationAttempts = 3`; `consolidationTimeout = 60s`; **falls back to raw archiving** on failure. Cohort first for an explicit threshold + retry-with-fallback consolidator.
- **Bi-temporal:** No `valid_at`/`invalid_at`. Documents have `updated_at`; KG nodes are upserted.
- **Self-update mechanism:** Memory consolidator is **token-threshold-triggered**; KG extraction runs as part of the chunk-ingest path; FAQ + wiki ingestion are pipelined.
- **Decay / forgetting:** Consolidation trims older raw turns into a memory block; raw archives kept on consolidator failure. No automatic GC.

### MCP / connectors
- **MCP server exposed:** **Yes — separate Python project at [`mcp-server/`](https://github.com/Tencent/WeKnora/tree/main/mcp-server).** [`weknora_mcp_server.py`](https://github.com/Tencent/WeKnora/blob/main/mcp-server/weknora_mcp_server.py) uses the official `mcp.server.stdio` SDK; calls back into the Go API at `WEKNORA_BASE_URL` with `WEKNORA_API_KEY`. Distributed as a separate `pyproject.toml` so it can be installed standalone.
- **MCP client used:** **Yes** — `mark3labs/mcp-go` (Go MCP SDK) at [`internal/mcp/`](https://github.com/Tencent/WeKnora/tree/main/internal/mcp), exposed to agents through the `mcp_tool.go` agent tool.
- **Native connectors:** Feishu / Notion / Yuque for KB ingestion + 7 IM-platform integrations at [`internal/im/`](https://github.com/Tencent/WeKnora/tree/main/internal/im) — DingTalk, Feishu, Mattermost, Slack, Telegram, WeChat, WeCom (WeChat Work).
- **Tool-call surface:** **~27 agent tools** at [`internal/agent/tools/`](https://github.com/Tencent/WeKnora/tree/main/internal/agent/tools) — 15 single-file `var ...Tool = BaseTool{` declarations (`data_analysis` (DuckDB-backed), `data_schema`, `database_query`, `sequentialthinking`, `todo_write`, `knowledge_search`, `list_knowledge_chunks`, `query_knowledge_graph`, `web_fetch`, `web_search`, `get_document_info`, `grep_chunks`, `skill_execute`, `skill_read`, `final_answer`) + the `mcp_tool` wrapper + **9 wiki CRUD tools** registered via `NewBaseTool(...)` (`wiki_read_page` / `wiki_write_page` / `wiki_replace_text` / `wiki_rename_page` / `wiki_delete_page` / `wiki_flag_issue` / `wiki_read_issue` / `wiki_update_issue` / `wiki_read_source_doc`). Internal helpers (`json_repair`, `param_cast`, `param_validate`, `strip_think`, `sanitize_messages`, `truncate`, `normalize_id`) are utility code, not registered tools.

### Notable design choices
- **Polyglot service split** — Go for the API/agent runtime, Python for document parsing (gRPC), Python for the MCP server, Python for the rerank demo. Cohort first with this many languages on the *server* side.
- **"Claude Progressive Disclosure" skill loader** — [`internal/agent/skills/loader.go`](https://github.com/Tencent/WeKnora/blob/main/internal/agent/skills/loader.go) explicitly cites the pattern. Level 1 = scan SKILL.md frontmatter (lightweight discovery); Level 2/3 = read full body on demand. `MaxNameLength=64` / `MaxDescriptionLength=1024` mirror Anthropic's spec.
- **5 preloaded skills shipped in repo** — `citation-generator`, `data-processor`, `doc-coauthoring`, `document-analyzer`, `openmaic-classroom`. Each is a Markdown file with frontmatter + Chinese-language playbook.
- **Auto-Wiki as a first-class output** — `wiki_ingest*.go` materialize a navigable wiki from documents with deduplication, citation-aware links, and lint passes. Wiki pages are CRUD'able by the agent through dedicated tools.
- **Token-threshold memory consolidator** — `DefaultConsolidationThreshold = 0.5` × `MaxContextTokens`; up to 3 LLM retries; `consolidationTimeout = 60s`; **graceful fallback to raw archiving** if all attempts fail.
- **Sandbox is Docker-or-local with budgets** — [`internal/sandbox/`](https://github.com/Tencent/WeKnora/tree/main/internal/sandbox) — `SandboxTypeDocker` / `SandboxTypeLocal` / `SandboxTypeDisabled`; default 60 s timeout, 256 MB RAM, 1 CPU. Default image `wechatopenai/weknora-sandbox:latest`. Includes `validator.go` to reject dangerous commands and argument injection.
- **Background jobs via `asynq`** (Redis-backed) + **`panjf2000/ants` goroutine pool** for retrieval parallelism — Go-native worker model rather than Celery.
- **`opencc` CN↔TW conversion** baked in (`longbridgeapp/opencc v0.3.13`).
- **Distribution channels beyond GitHub** — listed on Tencent's own *WeChat Dialog Open Platform*, *ClawHub Skill marketplace*, and a Chrome extension. Cohort first.
- **MIT** with explicit third-party-component license inheritance — Tencent does not impose additional limitations.

## Dependencies (KB-relevant)

From `go.mod` (Go 1.24.11):

```
# HTTP / framework
github.com/gin-gonic/gin v1.11.0
github.com/gin-contrib/cors v1.7.5
github.com/golang-jwt/jwt/v5 v5.3.0

# Vector / search backends
github.com/pgvector/pgvector-go v0.3.0
github.com/asg017/sqlite-vec-go-bindings v0.1.6
github.com/milvus-io/milvus/client/v2 v2.6.2
github.com/qdrant/go-client v1.16.1
github.com/elastic/go-elasticsearch/v7 v7.17.10
github.com/elastic/go-elasticsearch/v8 v8.18.0
github.com/neo4j/neo4j-go-driver/v6 v6.0.0
# (Weaviate via REST)

# Storage
github.com/jackc/pgx/v5 v5.7.2
github.com/golang-migrate/migrate/v4 v4.19.1
github.com/redis/go-redis/v9 v9.14.0
github.com/duckdb/duckdb-go/v2 v2.5.4         # data_analysis tool
github.com/parquet-go/parquet-go v0.25.0
github.com/minio/minio-go/v7 v7.0.91
github.com/aws/aws-sdk-go-v2/service/s3 v1.83.0
github.com/aliyun/alibabacloud-oss-go-sdk-v2 v1.4.1

# Agent / orchestration
github.com/hibiken/asynq v0.25.1               # background jobs
github.com/panjf2000/ants/v2 v2.11.3           # goroutine pool
github.com/robfig/cron/v3 v3.0.1
github.com/mark3labs/mcp-go v0.43.0            # MCP client SDK
github.com/google/jsonschema-go v0.4.2

# Connectors / IM platforms
github.com/larksuite/oapi-sdk-go/v3 v3.5.3      # Lark / Feishu
github.com/slack-go/slack v0.18.0-rc2
github.com/open-dingtalk/dingtalk-stream-sdk-go v0.9.1
github.com/gorilla/websocket v1.5.3

# LLM
github.com/sashabaranov/go-openai v1.40.5
github.com/ollama/ollama v0.11.4
github.com/JohannesKaufmann/html-to-markdown/v2 v2.5.0
github.com/longbridgeapp/opencc v0.3.13         # CN↔TW
github.com/chromedp/chromedp v0.14.2            # headless browser
```

`docreader/pyproject.toml` (Python ≥3.10):

```
paddleocr>=2.10.0,<3.0.0  paddlepaddle>=3.0.0,<4.0.0
markitdown[docx,pdf,xls,xlsx]>=0.1.3
pdfplumber, pypdf, pypdf2, python-docx
goose3[all], trafilatura, playwright (HTML)
mistletoe, markdownify
ollama, openai (VLM-OCR fallback)
grpcio (gRPC server)
```

License: **MIT** (with third-party components retaining their own licenses).

## Tradeoffs

**Pros:**
- **7 vector backends behind one retriever interface** — only repo with Postgres + Milvus + Qdrant + ES + Weaviate + sqlite-vec + Neo4j-as-vector all wired up.
- **Auto-Wiki + wiki CRUD agent tools** — turning a KB into a navigable, dedup'd, citation-linked wiki is a unique deliverable.
- **Skills system follows Claude's Progressive Disclosure** pattern — explicit citation in code, 5 preloaded skills shipped, MaxNameLength=64 / MaxDescription=1024.
- **Production-grade memory consolidator** — explicit threshold (0.5× context), 3-attempt retry, graceful fallback, 60s timeout. Most engineered consolidator in cohort.
- **40+ agent tools including DuckDB-backed data analysis** — the `data_analysis` tool runs analytical queries inside the agent loop.
- **Multi-tenant from day one** — `tenant_disabled_shared_agent.go` makes per-tenant gating explicit.
- **6 blob backends** — COS / OSS / TOS / MinIO / S3 / local. The largest blob-backend surface in this cohort.
- **7 IM-platform adapters + 3 KB connectors** — DingTalk / Feishu / Mattermost / Slack / Telegram / WeChat / WeCom + Feishu / Notion / Yuque ingestion.
- **Native Go scheduling** via `asynq` + `ants` — simpler ops than Celery + Redis + Beat.

**Cons:**
- **Operationally heavy** — Go API + Python docreader gRPC + Python MCP server + Python rerank demo + Postgres + Redis + (vector backend) + (object store) + asynq workers. Largest service surface in cohort after Onyx.
- **No bi-temporal memory** — KG entities upsert; no `valid_at`/`invalid_at`. Use graphiti if you need this.
- **MCP server is Python-side** — separate `pyproject.toml`; the Go binary doesn't expose MCP itself.
- **Heavy CN-cloud bias** — first-class COS / OSS / TOS / Tencent integrations; AWS-S3 / Azure-Blob support is solid but not the design center.
- **Skills are Chinese-language by default** — preloaded SKILL.md bodies are CN; non-CN deployments would need translation.
- **Auto-Wiki is opinionated** — once you're in, you're committed to the wiki shape (pages + citations + linkify + dedup + lint). Can't be turned off cleanly.
- **Per-format chunking is split across two languages** — Go does merging/expansion; Python `docreader/` does parsing. Cross-language debugging surface.

## When to use it

- **Good fit:** CN-and-global enterprise KBs that need 7 swappable vector backends, multi-tenant Postgres, Auto-Wiki materialization, IM-platform reach (WeChat / WeCom / Lark / DingTalk + Slack / Telegram / Mattermost), and a Docker/local sandbox for code execution. WeChat-ecosystem deployments with mini-program + WeChat Open Platform integration.
- **Bad fit:** single-binary or laptop-grade deployments; libraries that want to embed a memory layer without running 4+ services; products that need bi-temporal memory or memory frameworks (use graphiti / mem0); MIT-only legal envelopes that won't permit third-party component licenses (WeKnora *is* MIT but inherits everything else).
- **Closest alternative:** [`infiniflow/ragflow`](surveys/infiniflow__ragflow.md) — same kb-app + multi-tenant + deep-doc + MCP server + client shape; ragflow is parsing-heavy (deepdoc OCR, RAPTOR), WeKnora is connector-and-pipeline-heavy (7 vector backends, 7 IM platforms, Auto-Wiki). [`onyx-dot-app/onyx`](surveys/onyx-dot-app__onyx.md) is the closest enterprise alternative for non-CN markets — Vespa/OpenSearch + 63 connectors + Deep Research; WeKnora trades Deep Research for Auto-Wiki and adds CN-cloud blob backends.

## Code pointers (evidence)

- 7-backend retriever registry: [`internal/application/repository/retriever/`](https://github.com/Tencent/WeKnora/tree/main/internal/application/repository/retriever) (`postgres/`, `milvus/`, `qdrant/`, `elasticsearch/`, `weaviate/`, `sqlite/`, `neo4j/`)
- Step-graph chat pipeline: [`internal/application/service/chat_pipeline/`](https://github.com/Tencent/WeKnora/tree/main/internal/application/service/chat_pipeline) (`chat_pipeline.go`, `query_understand.go`, `query_expansion.go`, `search.go` / `search_parallel.go` / `search_entity.go`, `merge_overlap.go` / `merge_expand.go` / `merge_history.go` / `merge_faq.go`, `wiki_boost.go`, `rerank.go`, `filter_top_k.go`)
- Memory consolidator (token-threshold + 3-retry + fallback): [`internal/agent/memory/consolidator.go`](https://github.com/Tencent/WeKnora/blob/main/internal/agent/memory/consolidator.go)
- Skills loader (Progressive Disclosure): [`internal/agent/skills/loader.go`](https://github.com/Tencent/WeKnora/blob/main/internal/agent/skills/loader.go), [`internal/agent/skills/skill.go`](https://github.com/Tencent/WeKnora/blob/main/internal/agent/skills/skill.go), preloaded skills at [`skills/preloaded/`](https://github.com/Tencent/WeKnora/tree/main/skills/preloaded)
- Agent tool registry (40+ tools): [`internal/agent/tools/`](https://github.com/Tencent/WeKnora/tree/main/internal/agent/tools) (esp. `mcp_tool.go`, `data_analysis.go`, `query_knowledge_graph.go`, `wiki_*.go`, `sequentialthinking.go`, `todo_write.go`)
- Auto-Wiki ingestion + CRUD: [`internal/application/service/wiki_ingest.go`](https://github.com/Tencent/WeKnora/blob/main/internal/application/service/wiki_ingest.go), `wiki_linkify.go`, `wiki_lint.go`, `wiki_ingest_dedup.go`, `wiki_ingest_cite.go`, `wiki_page.go`
- Sandbox (Docker/local with budgets + validators): [`internal/sandbox/`](https://github.com/Tencent/WeKnora/tree/main/internal/sandbox)
- IM platform adapters: [`internal/im/`](https://github.com/Tencent/WeKnora/tree/main/internal/im) (`dingtalk/`, `feishu/`, `mattermost/`, `slack/`, `telegram/`, `wechat/`, `wecom/`)
- KB-source connectors: [`internal/datasource/connector/`](https://github.com/Tencent/WeKnora/tree/main/internal/datasource/connector) (`feishu/`, `notion/`, `yuque/`)
- Python `docreader/` gRPC service (12 parsers + PaddleOCR + VLM): [`docreader/`](https://github.com/Tencent/WeKnora/tree/main/docreader)
- Python MCP server: [`mcp-server/weknora_mcp_server.py`](https://github.com/Tencent/WeKnora/blob/main/mcp-server/weknora_mcp_server.py)
- Most useful single file to read first: [`internal/application/service/chat_pipeline/chat_pipeline.go`](https://github.com/Tencent/WeKnora/blob/main/internal/application/service/chat_pipeline/chat_pipeline.go) — the step graph is the architecture; everything else is plumbing.

## Open questions

- The 7 retriever backends — does any production deployment actually run more than one at a time, or is the abstraction primarily for migration?
- Auto-Wiki dedup + linkify uses LLM passes; how do they handle high-volume ingestion economically? Worth a deeper future read.
- The skills loader cites "Claude's Progressive Disclosure" by name — is the runtime API surface compatible with Anthropic's Skills, or just the file format?
- The 5 preloaded skills are CN-language; is there an EN-translation initiative or are skills expected to be replaced per-deployment?
- DuckDB-backed `data_analysis` tool — what's the schema-discovery flow? Auto-detected from chunks or user-supplied?
- The Python MCP server is a thin HTTP wrapper around the Go API — why not embed FastMCP directly in Go via `mark3labs/mcp-go` to remove the language hop?

---

*Surveyed via the `curating-agentic-kbs` skill. Re-survey scheduled after 30 days of last `pushed_at` change.*

*Audit 2026-05-02: clone-verified against [`internal/application/repository/retriever/`](https://github.com/Tencent/WeKnora/tree/main/internal/application/repository/retriever) (7 vector backends), [`internal/application/service/file/`](https://github.com/Tencent/WeKnora/tree/main/internal/application/service/file) (6-backend blob factory: cos / oss / tos / minio / s3 / **local**), [`internal/im/`](https://github.com/Tencent/WeKnora/tree/main/internal/im) (7 IM platforms), [`internal/datasource/connector/`](https://github.com/Tencent/WeKnora/tree/main/internal/datasource/connector) (3 KB connectors: feishu / notion / yuque), [`internal/agent/tools/`](https://github.com/Tencent/WeKnora/tree/main/internal/agent/tools), `VERSION`, `mcp-server/`, `internal/sandbox/`, `internal/agent/skills/loader.go`. **Correction:** agent-tool count "40+" → **~27** (15 single-file `var ...Tool = BaseTool{` + 1 mcp_tool wrapper + 9 wiki CRUD via `NewBaseTool(...)` + 2 helper-shape registrations). The 7 helper files (`json_repair`, `param_cast`, `param_validate`, `strip_think`, `sanitize_messages`, `truncate`, `normalize_id`) are internal utilities, not registered agent tools. **Verified verbatim:** 7 vector backends (postgres/milvus/qdrant/elasticsearch/weaviate/sqlite/neo4j), 6 blob backends (incl. local), 7 IM platforms (dingtalk/feishu/mattermost/slack/telegram/wechat/wecom), 3 KB datasource connectors, MCP server (Python `mcp-server/` standalone) + MCP client (Go `mark3labs/mcp-go` in `internal/mcp/`), Auto-Wiki (`wiki_ingest*.go` family), skill loader cites Anthropic Progressive Disclosure (`MaxNameLength=64` / `MaxDescriptionLength=1024`), token-threshold consolidator (`consolidator.go`), Docker/local sandbox (`internal/sandbox/`). Added version `0.5.1`.*
