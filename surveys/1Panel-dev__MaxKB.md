# Survey: 1Panel-dev/MaxKB

**Date:** 2026-05-01
**Stars:** 20,865 · **Last push:** 2026-04-30 · **Created:** 2023 · **Version:** `2.0.0`
**Category:** kb-app
**Slug:** [1Panel-dev/MaxKB](https://github.com/1Panel-dev/MaxKB)

---

## TL;DR (3 lines)

- **What it is:** "Max Knowledge Brain" — an enterprise agent platform from FIT2CLOUD, the team behind 1Panel; Django-based, Vue UI, **LangChain + LangGraph + `deepagents`** under the hood, multi-modal end-to-end (text + image + audio + video step nodes), single-Postgres-with-pgvector backend, 23 first-party LLM providers, and 35+ visual-workflow step nodes.
- **How its KB works:** **PostgreSQL + pgvector as the only KB backend**, with embedding rows in a custom `Embedding` model that uses a Django-defined `VectorField` (raw `vector` type). Three explicit retrieval modes (`SearchMode.embedding / keywords / blend`) on top of Django's `SearchVector` (Postgres FTS) for keyword search. Long-term memory is a separate **LLM-extracted 4-category schema** (`Preferences / Background / Agreements / Goals`) refreshed on a `ROUND`-or-`SCHEDULED` (cron / interval / daily / weekly / monthly) trigger via APScheduler + Celery.
- **Verdict:** Pick when you want a **Chinese-market-friendly, batteries-included, single-Postgres** agent platform with a heavy LangChain ecosystem (LangGraph workflows, `langchain-mcp-adapters`, 23 model providers) and serious multi-modal step nodes. Skip if you need polyglot vector backends, graph DBs, or AGPL-only / Apache-only legal envelopes — MaxKB is **GPL-3.0** (first in this cohort).

## KB Architecture

### Storage
- **Vector store:** **PostgreSQL + pgvector** ([`apps/knowledge/vector/pg_vector.py`](https://github.com/1Panel-dev/MaxKB/blob/main/apps/knowledge/vector/pg_vector.py)). Uses a Django-defined `VectorField(models.Field)` with `db_type → 'vector'` so embeddings live in the same table as document metadata. `BaseVectorStore` ABC exists ([`base_vector.py`](https://github.com/1Panel-dev/MaxKB/blob/main/apps/knowledge/vector/base_vector.py)) but only `PGVector` ships.
- **Graph store:** *None.*
- **Metadata / structured:** **PostgreSQL** via Django ORM + `django-mptt` (hierarchical `KnowledgeFolder`) + `django-db-connection-pool`. Schemas: `Knowledge`, `Document`, `Paragraph`, `Problem`, `Tag`, `Embedding` (vector), `KnowledgeWorkflow*`, `Application`, `ApplicationLongTermMemory`, etc.
- **Object / blob:** Local filesystem mounted at `~/.maxkb` per the install script; abstracted via the `oss/` Django app (separate `OSS` providers in pluggable form).

### Ingestion / Extraction
- **Source types accepted:** PDF (`pypdf`), DOCX (`python-docx`), XLS/XLSX (`xlrd` / `xlwt` / `openpyxl`), Markdown (via `markdownify`), HTML / plain text, audio (`pydub`, `pysilk`); plus URL crawling. Document parsing flows through `flow/step_node/document_extract_node` → `document_split_node`.
- **Chunking strategy:** Custom chunker in `common/chunk.py` (`text_to_chunk`) with `normalize_for_embedding` (emoji stripping via precompiled regex, Chinese-text-aware normalization). The split is configurable via the workflow node.
- **Entity / fact extraction:** *No native entity/triple extraction over documents.* But: **long-term memory uses LLM extraction** ([`apps/application/long_term_memory/__init__.py`](https://github.com/1Panel-dev/MaxKB/blob/main/apps/application/long_term_memory/__init__.py)) with a 230-line Chinese-language prompt that classifies extracted facts into 4 categories — **`偏好` (Preferences) / `背景` (Background) / `约定` (Agreements) / `目标` (Goals)** — with explicit merge / overwrite / `※已更新` / `※待确认` / cancellation rules. Each output bullet is `[label] content`, capped at 60 characters per line.
- **Schema:** **Flat doc → paragraph → embedding** for the KB; **structured 4-category** for long-term memory.

### Retrieval
- **Modes:** `SearchMode` enum has three values — `embedding` (pure dense), `keywords` (Postgres `to_tsvector` FTS via `common/utils/ts_vecto_util.py`), and **`blend`** (hybrid). The `search_knowledge_node` (and the legacy `search_document_node`) is the workflow-node entrypoint. Reranker is a separate workflow node (`reranker_node`).
- **Reranker:** Pluggable through `models_provider` — Cohere SDK is a hard dep (`cohere==5.17.0`); also Xinference, Qianfan, AWS Bedrock, etc. The `local_model` Django app runs **`sentence-transformers==5.0.0`** + Torch CPU/MPS for self-hosted cross-encoders.
- **Top-k defaults:** Configured per-application or per-workflow node; not hardcoded in the model layer.
- **Context assembly:** `chat_pipeline/` — multi-step pipeline manager (`pipeline_manage.py`) that composes chat steps; orchestrates retrieval → rerank → LLM call → long-term-memory write-back.

### Memory model
- **Tiers:**
  - **KB embeddings** (Postgres + pgvector) — doc-RAG.
  - **Chat history** — `Chat` + `ChatRecord` Django models.
  - **Application long-term memory** — `ApplicationLongTermMemory` row per `(application_id, chat_user_id)`, `memory: TEXT`. The 4-category schema is the *only* structured memory in the cohort with this shape.
  - **Workflow state** — LangGraph state machine, persisted per chat.
- **Bi-temporal:** No — long-term memory is "current-state-only" with `※已更新` annotations on overwritten fields, but no `valid_at` / `invalid_at`.
- **Self-update mechanism:** Two trigger types coded into `Application`:
  - **`ROUND`** — every N chat rounds, a Celery task (`celery:extract_long_term_memory`) re-runs extraction over the last N records.
  - **`SCHEDULED`** — APScheduler cron / interval / daily / weekly / monthly job (registered via `_deploy_long_term_*` helpers) that scans every chat user and calls `_run_extract`.
  - Either way, the LLM is fed `existing_memory` + `new_conversation` and asked to **merge / overwrite / delete** entries per the prompt's hard rules. `<think>...</think>` reasoning is stripped from output via regex.
- **Decay / forgetting:** Implicit — the prompt explicitly says cancelled `约定` rules and completed `目标` items should be **deleted**, putting forgetting in the LLM's hands rather than via TTL/score logic.

### MCP / connectors
- **MCP server exposed:** **Yes — but synthesized at runtime per user-authored tool.** `apps/common/utils/tool_code.py` parses user-supplied Python via `ast`, replaces unsafe annotations with `Any` (so FastMCP/Pydantic schema generation doesn't crash on `requests.Response` etc.), wraps each function with `@mcp.tool(description=...)`, and emits a generated module starting with `from mcp.server.fastmcp import FastMCP` + `mcp = FastMCP(uuid.uuid7())`. Each tool/application gets its own ad-hoc FastMCP server. Unique design in this cohort.
- **MCP client used:** **Yes — `langchain-mcp-adapters==0.2.2` + `MultiServerMCPClient`**. The `flow/step_node/mcp_node/` step lets a workflow node call any MCP server (referenced from a stored `Tool` row or inline JSON `mcp_servers` config). Variable-substitution into `tool_params` before invocation.
- **Native connectors:** None analogous to ragflow's catalogue or onyx's 63 first-party adapters. MaxKB leans on MCP + user-authored Python tools instead.
- **Tool-call surface:** **35+ workflow step nodes** in [`apps/application/flow/step_node/`](https://github.com/1Panel-dev/MaxKB/tree/main/apps/application/flow/step_node) — `ai_chat_step_node`, `application_node`, `condition_node`, `data_source_local_node`, `data_source_web_node`, `direct_reply_node`, `document_extract_node`, `document_split_node`, `form_node`, `image_generate_step_node`, `image_to_video_step_node`, `image_understand_step_node`, `intent_node`, `knowledge_write_node`, `loop_node` / `loop_break_node` / `loop_continue_node` / `loop_start_node`, `mcp_node`, `parameter_extraction_node`, `question_node`, `reranker_node`, `search_document_node`, `search_knowledge_node`, `speech_to_text_step_node`, `text_to_speech_step_node`, `text_to_video_step_node`, `tool_lib_node` / `tool_node` / `tool_start_node` / `tool_workflow_lib_node`, `variable_aggregation_node` / `variable_assign_node` / `variable_splitting_node`, `video_understand_step_node`. Multi-modal end-to-end is the design point.

### Notable design choices
- **Single-Postgres design taken further than khoj** — pgvector for embeddings, Postgres FTS for keywords, Postgres rows for the KG-substitute (Knowledge / Document / Paragraph / Tag), Postgres rows for chat history, Postgres rows for long-term memory, Postgres rows for workflow versions. The only auxiliary services are Redis (django-redis) and Celery's broker.
- **LangChain ecosystem first-class** — `langchain==1.2.15`, `langchain-core==1.3.0`, `langchain-openai`, `langchain-anthropic`, `langchain-community`, `langchain-deepseek`, `langchain-google-genai`, `langchain-huggingface`, `langchain-ollama`, `langchain-aws`, `langchain-mcp-adapters`, `langgraph==1.1.9`, `deepagents==0.5.3`. Heaviest LangChain footprint in the cohort.
- **23 model providers** in `models_provider/impl/` — Aliyun Bailian, AWS Bedrock, Azure, Anthropic, DeepSeek, Docker AI, Google Genai, Kimi, MiniMax, Ollama, OpenAI, Qwen, Regolo, Silicon Cloud, Tencent / Tencent Cloud, vLLM, Volcanic Engine, Wenxin, Xinference, Zhipu, etc. Heavily CN-cloud-friendly (Bailian / Qianfan / Volcengine / Tencent / Wenxin / Zhipu / DeepSeek / Kimi).
- **Workflow-as-DAG with versioned KB workflows** — `KnowledgeWorkflow` + `KnowledgeWorkflowVersion` lets users edit retrieval / chunking / extraction logic visually; a separate `tool_workflow_manage.py` handles tool DAGs. The `default_workflow*.json` templates ship in EN / zh-Hans / zh-Hant.
- **AST-rewriting tool sandbox** — user-supplied Python is parsed, annotations sanitized, return statements wrapped in `Result(result=..., tool_id=...)` Pydantic, and `@mcp.tool` decorators added — *then* a FastMCP server is generated that boots the tool. Different from cline's allowlist-only stdio MCP and onyx's ACP-build sandbox.
- **APScheduler + Celery for memory** — `apscheduler.cron`/`interval` triggers register Celery tasks under per-application IDs (`long_term:application:{id}:cron:{expr}`) with `replace_existing=True` and `misfire_grace_time=60`. Daily / weekly / monthly are decomposed to APScheduler `cron` triggers; `interval` keeps unit semantics.
- **Multi-modal step nodes** — image-to-video, video-understanding, speech-to-text, text-to-speech, text-to-video, image-generate as first-class workflow nodes, not plugins.
- **GPL-3.0** — first cohort entry on classic GPL (not AGPL). Distributable but weaker copyleft on SaaS than AGPL.
- **`django-mptt` hierarchical KB folders** — supports nested `KnowledgeFolder` trees with parent / lft / rght / tree_id ordering, rare in this cohort (most use flat tags or paths).

## Dependencies (KB-relevant)

From `pyproject.toml`:

```
# Core
django==5.2.13
djangorestframework==3.17.1
psycopg[binary]==3.2.9              # Postgres
django-redis==6.0.0
django-mptt==0.17.0                 # hierarchical KnowledgeFolder
django-db-connection-pool==1.2.6
celery[sqlalchemy]==5.5.3
django-celery-beat==2.8.1
celery-once==3.0.1
django-apscheduler==0.7.0           # long-term memory schedules

# LangChain ecosystem
langchain==1.2.15
langchain-core==1.3.0
langchain-openai==1.2.0
langchain-anthropic==1.4.1
langchain-community==0.4.1
langchain-deepseek==1.0.1
langchain-google-genai==4.2.2
langchain-huggingface==1.2.1
langchain-ollama==1.1.0
langchain-aws==1.4.5
langchain-mcp-adapters==0.2.2       # MCP client adapters
langgraph==1.1.9
deepagents==0.5.3

# ML / embedding / reranker
torch==2.8.0
sentence-transformers==5.0.0        # local cross-encoder via local_model app
cohere==5.17.0                      # Cohere reranker SDK
xinference-client==1.7.1.post1

# Provider SDKs (CN-heavy)
qianfan==0.4.12.3
zhipuai==2.1.5.20250708
volcengine-python-sdk[ark]==5.0.24
tencentcloud-sdk-python==3.0.1420
dashscope==1.25.16
anthropic==0.96.0

# File parsing
pypdf==6.10.2
python-docx==1.2.0
openpyxl==3.1.5, xlrd, xlwt
pydub, pysilk                       # audio
markdownify==1.2.2
beautifulsoup4==4.13.4
jieba==0.42.1                       # CJK tokenizer
```

License: **GPL-3.0**.

## Tradeoffs

**Pros:**
- **Single-Postgres simplicity at enterprise feature scope** — pgvector + FTS + Knowledge/Document/Paragraph/Embedding rows + chat history + long-term memory + workflow versions, all in one DB. Lighter ops than ragflow / onyx for the same feature breadth.
- **The cohort's most structured long-term memory model** — the 4-category prompt with explicit merge / overwrite / cancellation rules is meaningfully different from mem0's flat atomic facts and graphiti's bi-temporal triples.
- **35+ workflow step nodes including loop / break / continue / intent / parameter-extraction / image-to-video / video-understand** — full visual agent IDE, not just a chatbot.
- **Dynamic FastMCP server synthesis** — every user tool becomes an MCP server, no manual server authoring.
- **23 model providers, CN-cloud-heavy** — Bailian / Volcengine / Wenxin / Zhipu / Qianfan / Tencent are first-class, not afterthoughts.
- **APScheduler-based memory triggers** — cron / interval / daily / weekly / monthly are deployable per-app, with proper `replace_existing` + `misfire_grace_time` semantics.

**Cons:**
- **Single vector backend (pgvector)** — `BaseVectorStore` ABC unused; no Faiss/Qdrant/Milvus path. Postgres ceiling for very large embeddings.
- **No graph DB, no graph extraction** — KB is doc-RAG, not knowledge graph. KG-style multi-hop is out of scope.
- **GPL-3.0 only** — most permissive copyleft in the cohort isn't AGPL but isn't permissive either; reading distributing a fork triggers source-disclosure.
- **LangChain version churn risk** — `langchain==1.2`, `langchain-core==1.3`, `langgraph==1.1` pinned across 11 langchain-* packages; upstream breaking changes have a wide blast radius.
- **AST-rewriting tool sandbox** — execute-arbitrary-Python-as-MCP-server is powerful but security-sensitive; the annotation sanitization is `_safe_annotation_names` allowlist, but the function body is still arbitrary Python running in the host process.
- **Heavy CN dependency surface** — qianfan / zhipuai / volcengine / tencentcloud / dashscope / wenxin / kimi together pull dozens of MB of vendor SDKs even if you don't use them.
- **No native enterprise SaaS connectors** — ragflow / onyx / FastGPT all have richer first-party connector catalogues. MaxKB expects you to author tools.

## When to use it

- **Good fit:** CN-market enterprise agent platforms; teams that want LangGraph + deepagents under a visual editor; products that need multi-modal output (image/audio/video step nodes); deployments where one Postgres + Redis is the entire ops stack.
- **Bad fit:** SaaS products needing Apache-2.0 / MIT redistribution; large-scale RAG over millions of documents; products that need graph reasoning or polyglot vector backends; pipelines without LangChain / LangGraph appetite.
- **Closest alternative:** [`labring/FastGPT`](surveys/labring__FastGPT.md) — also a TS/CN-friendly KB+chat platform with workflow editor, but FastGPT runs Mongo + multiple vector backends and is TS-first; MaxKB is Python/Django + Postgres-only and integrates LangGraph instead of an in-house pi-mono runtime. [`infiniflow/ragflow`](surveys/infiniflow__ragflow.md) is the heavier doc-parsing alternative; MaxKB is the lighter agent-workflow alternative.

## Code pointers (evidence)

- pgvector store with Django `VectorField`: [`apps/knowledge/vector/pg_vector.py`](https://github.com/1Panel-dev/MaxKB/blob/main/apps/knowledge/vector/pg_vector.py)
- `BaseVectorStore` ABC + chunk normalization: [`apps/knowledge/vector/base_vector.py`](https://github.com/1Panel-dev/MaxKB/blob/main/apps/knowledge/vector/base_vector.py)
- `SearchMode.embedding/keywords/blend` enum: [`apps/knowledge/models/knowledge.py:281`](https://github.com/1Panel-dev/MaxKB/blob/main/apps/knowledge/models/knowledge.py)
- 4-category long-term memory extraction prompt + APScheduler triggers + Celery tasks: [`apps/application/long_term_memory/__init__.py`](https://github.com/1Panel-dev/MaxKB/blob/main/apps/application/long_term_memory/__init__.py)
- Dynamic FastMCP server synthesis from user Python: [`apps/common/utils/tool_code.py:170-260`](https://github.com/1Panel-dev/MaxKB/blob/main/apps/common/utils/tool_code.py)
- MCP-client workflow node (uses `MultiServerMCPClient`): [`apps/application/flow/step_node/mcp_node/impl/base_mcp_node.py`](https://github.com/1Panel-dev/MaxKB/blob/main/apps/application/flow/step_node/mcp_node/impl/base_mcp_node.py)
- 35+ workflow step nodes: [`apps/application/flow/step_node/`](https://github.com/1Panel-dev/MaxKB/tree/main/apps/application/flow/step_node)
- 23 model providers: [`apps/models_provider/impl/`](https://github.com/1Panel-dev/MaxKB/tree/main/apps/models_provider/impl)
- Workflow manager + LangGraph integration: [`apps/application/flow/workflow_manage.py`](https://github.com/1Panel-dev/MaxKB/blob/main/apps/application/flow/workflow_manage.py), [`knowledge_workflow_manage.py`](https://github.com/1Panel-dev/MaxKB/blob/main/apps/application/flow/knowledge_workflow_manage.py)
- Most useful single file to read first: [`apps/application/long_term_memory/__init__.py`](https://github.com/1Panel-dev/MaxKB/blob/main/apps/application/long_term_memory/__init__.py) — the 4-category prompt + scheduler + Celery integration is the design center.

## Open questions

- The AST-based tool sandbox runs user Python *in the host process* after generating the MCP server module. Is there any process-level isolation (subprocess / container), or just import-time sanitization? Looks like in-process, which is a real security surface.
- `BaseVectorStore` ABC exists — is the Postgres-only backend deliberate, or is a Qdrant/Milvus impl planned?
- `deepagents==0.5.3` is a recent LangGraph-adjacent agent framework; how is it actually wired into the workflow nodes? Worth a deeper future read.
- The 4-category memory prompt is in Chinese only — does it work for non-CJK conversations, or does the platform implicitly require CN-language LLMs?
- `tool_workflow_manage.py` vs `workflow_manage.py` distinction: separate execution semantics? Or just node-set scoping?

---

*Surveyed via the `curating-agentic-kbs` skill. Re-survey scheduled after 30 days of last `pushed_at` change.*

*Audit 2026-05-02: clone-verified against [`pyproject.toml`](https://github.com/1Panel-dev/MaxKB/blob/main/pyproject.toml) (v2.0.0, requires-python `~=3.11.0`), [`apps/application/long_term_memory/__init__.py`](https://github.com/1Panel-dev/MaxKB/blob/main/apps/application/long_term_memory/__init__.py) (4-category Chinese taxonomy `偏好 / 背景 / 约定 / 目标` with explicit update/overwrite/retain/append/delete policy semantics + `※已更新` annotation rules), [`apps/common/utils/tool_code.py`](https://github.com/1Panel-dev/MaxKB/blob/main/apps/common/utils/tool_code.py) (FastMCP runtime synthesis: `from mcp.server.fastmcp import FastMCP` + `mcp = FastMCP("{uuid}")` + `@mcp.tool` decorators generated via Python AST rewriting), [`apps/models_provider/impl/`](https://github.com/1Panel-dev/MaxKB/tree/main/apps/models_provider/impl) (23 provider directories). **Correction:** model provider count **28 → 23** (off-by-5; original count likely included 4 base helper files + `__init__.py`). **Verified verbatim:** core deps `django==5.2.13`, `langgraph==1.1.9`, `deepagents==0.5.3`, `django-mptt==0.17.0`, `django-celery-beat==2.8.1`, `django-apscheduler==0.7.0`. Added version `2.0.0` to header.*
