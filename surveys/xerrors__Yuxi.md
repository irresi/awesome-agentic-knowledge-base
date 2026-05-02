# xerrors/Yuxi (语析)

- **Stars:** 5,069 · **Last push:** 2026-05-01 · **Created:** 2024-07-05 · **License:** MIT · **Lang:** Python (3.12 ≤ x < 3.14) + Vue.js · **Version:** `yuxi-workspace 0.6.2` (per pyproject.toml; v0.6.0 release notes 2026-04-01)
- **Category:** kb-app (multi-tenant Agent Harness with first-class **knowledge graph + RAG** built on **LightRAG** as substrate)
- **Author:** xerrors (Chinese-language project — 语析 = "language analysis")

## TL;DR

A Vue + FastAPI + LangGraph v1 platform that **explicitly consumes [`HKUDS/LightRAG`](HKUDS__LightRAG.md) as its knowledge-graph substrate** (cohort first deliberate downstream-consumption pattern documented in pyproject description: `"基于 LangGraph v1 + Vue.js + FastAPI + LightRAG 架构构建"`). Implements 3 KnowledgeBase backends behind one `KnowledgeBaseManager` factory: **`lightrag.py`** (KG-shaped, the headline integration) + **`milvus.py`** (vector-only) + **`dify.py`** (Dify-managed remote KB). 4 buildin LangGraph agents architecture with **8 middleware classes** (`attachment` + `context` + `dynamic_tool` + `knowledge_base` + `runtime_config` + `skills` + `summary` + …) for layered concerns. **9 document parsers** in `plugins/parser/` (DeepSeek-OCR / MinerU / MinerU-official / PaddleX-pp_structure_v3 / RapidOCR / unified / zip_utils + base + factory) — cohort-novel breadth for *Chinese-language document parsing* with PaddleX + DeepSeek-OCR specialty. **`ragflow_like` chunking strategy** (cohort-novel inspiration credit — explicitly named to acknowledge ragflow's per-format chunker pattern). **`LITE_MODE` startup** (cohort-first explicit "skip-knowledge-base-modules" startup option for development). **Sandbox provisioner** as separate Docker service. **API Key authentication** for external system integration. CN-language docs throughout. MIT.

## KB Architecture

### Storage
- Postgres (business + KB metadata + LangGraph checkpoint pool, separate `storage/postgres/` connection-pool managers per concern).
- Redis (event stream + ARQ task queue state).
- MinIO (object storage for files + parsed Markdown).
- **Milvus** (vector backend for the `milvus.py` KB implementation).
- **Neo4j** (graph backend, used as `graph` Docker service — primarily by LightRAG-shaped KBs).
- Sandbox: virtual filesystem at `/home/gem/user-data` (per release notes).

### Knowledge bases (3 implementations behind 1 factory)
- [`backend/package/yuxi/knowledge/`](https://github.com/xerrors/Yuxi/tree/main/backend/package/yuxi/knowledge): `base.py` (`KnowledgeBase` ABC, `FileStatus` enum) + `factory.py` + `manager.py` (`KnowledgeBaseManager` dispatch by KB type) + `chunking/` + `graphs/` + `implementations/` + `utils/`.
- **3 KB implementations** in `implementations/`:
  1. **`lightrag.py`** — *the headline integration*. Imports `from lightrag import LightRAG, QueryParam` and `from lightrag.kg.shared_storage import initialize_pipeline_status`. Wires LightRAG to the Yuxi `KnowledgeBase` interface, including: `openai_complete_if_cache` + `openai_embed` LLM/embed wiring, Neo4j graph driver, Milvus vector backend, **embedding-model dynamic switch fix** for [LightRAG #580](https://github.com/HKUDS/LightRAG/issues/580) (per v0.6.0 changelog).
  2. **`milvus.py`** — vector-only KB without graph layer.
  3. **`dify.py`** — proxies to Dify-managed remote KB (cohort cross-link, since Dify is also a candidate but unsurveyed).
- **`ragflow_like` chunking strategy** in `chunking/ragflow_like/`: `dispatcher.py` + `presets.py` + `nlp.py` + `parsers/` + `utils/`. Module name explicitly credits ragflow's per-format chunker pattern as inspiration. Cohort-novel naming-as-attribution pattern.
- KB **predicate-based read-only mount into sandbox** (per v0.6.0 changelog): `用户可访问知识库 ∩ 当前 Agent 已启用知识库` exposes original files + parsed Markdown via the sandbox FS. Cohort first to expose KB content to agent sandbox via predicate-driven mount.

### Document parsers (9 in `plugins/parser/`)
- [`backend/package/yuxi/plugins/parser/`](https://github.com/xerrors/Yuxi/tree/main/backend/package/yuxi/plugins/parser): `base.py` + `deepseek_ocr.py` + `factory.py` + `mineru.py` + `mineru_official.py` + `pp_structure_v3.py` (PaddleX) + `rapid_ocr.py` + `unified.py` (the dispatching adapter) + `zip_utils.py`.
- **Cohort-novel Chinese-language document parsing breadth** — DeepSeek-OCR + MinerU (official + custom variants) + PaddleX `pp_structure_v3` + RapidOCR span CN OCR/document-AI ecosystem. SurfSense's 9 parsers (Azure DI / Docling / LlamaCloud / Unstructured / Vision-LLM / etc.) target US/global ecosystem; Yuxi's target CN ecosystem.
- `unified.py` is the dispatching adapter consumed by `lightrag.py` (`from yuxi.plugins.parser.unified import Parser`).

### Agent runtime
- [`backend/package/yuxi/agents/`](https://github.com/xerrors/Yuxi/tree/main/backend/package/yuxi/agents): `base.py` (`BaseAgent` + `BaseContext`) + `backends/` (sandbox / KB / Skills external-execution backends) + `buildin/` (chatbot + deep_agent + …) + `middlewares/` + `models.py` + `skills/buildin/{deep-reporter,reporter}` + `state.py` + `toolkits/{buildin,debug,kbs,mysql,registry.py,utils.py}`.
- **8 middleware classes** in `middlewares/` for layered agent runtime concerns:
  1. `attachment_middleware` — file-attachment handling
  2. `context_middlewares` — runtime context wiring
  3. `dynamic_tool_middleware` — runtime tool registration
  4. `knowledge_base_middleware` — KB query injection
  5. `runtime_config_middleware` — per-run config overlay
  6. `skills_middleware` — Skills layer
  7. `summary_middleware` — summarization side-effects
  8. (`__init__.py` aggregator)
  Cohort-first explicit middleware-chain abstraction at the LangGraph agent layer (vs cohort entries that bury these as tool decorators or system-prompt injection).
- **2 buildin Skills**: `reporter` (database reports — deprecated per v0.6.0, "数据库报表将由 Skills 完成") + **`deep-reporter`** (deep analysis / industry research / scientific reports — cohort-novel specialized "deep research" skill that ships in-tree).
- **2 buildin SubAgents** per v0.6.0 release notes (specific names not enumerated in scanned files but documented).
- 4 toolkit categories: `buildin` + `debug` + `kbs` + `mysql` + `registry.py` aggregator. **Dedicated `kbs/` toolkit** routes per-KB queries through type-specific dispatchers.

### Services (~20 services in `services/`)
- agent_run, chat, conversation, evaluation, feedback, filesystem, knowledge_fs (KB-as-FS), langfuse, mcp, model_cache, model_provider, oidc, remote_skill_install, run_queue, run_worker, skill, subagent, task, thread_files, tool.
- **`langfuse_service.py`** — Langfuse tracing (cohort second after honcho's Langfuse + DeepTutor's Langfuse).
- **`oidc_service.py`** — OIDC enterprise SSO.
- **`mcp_service.py`** — MCP server/client integration.
- **`evaluation_service.py`** — KB evaluation primitives (cohort second after deepset-ai/haystack's evaluators).
- **`subagent_service.py`** — first-class subagent management (per v0.6.0 release notes added).

### Sandbox + filesystem
- `docker/sandbox_provisioner/` — separate Docker service that provisions sandboxes for agent tool execution.
- `present_artifacts` builtin tool (per v0.6.0): agent writes files into `/home/gem/user-data/outputs/` then explicitly registers them in LangGraph state's `artifacts` field; frontend displays as collapsible stacked-card UI. Cohort first explicit "artifacts as agent output channel".
- KB read-only mount into sandbox FS (predicate-based per `用户可访问知识库 ∩ 当前 Agent 已启用知识库`) — cohort first.

### LITE_MODE
- Per v0.6.0: `make up-lite` startup excludes knowledge-base + knowledge-graph modules. **Cohort first explicit "skip the heavy modules at startup"** option for dev iteration. Implementation gates router registration in `server/routers/__init__.py` to skip KB/graph/evaluation/mindmap routes.

### Frontend
- Vue 3 + Vite (`web/` — Vue path-aliased components / composables / stores / utils / views / layouts / router).
- WeChat-mini-program-style attachment system (per v0.6.0: "重构附件系统，直接集成在了沙盒文件系统中").
- Streaming UX with `useStreamSmoother` composable (cohort-novel explicit smoothing layer for SSE chunks).
- Frontend-side Chinese / English bilingual support inferred from CN-language docs.

### Distribution
- 2-process dev architecture: `web-dev` (Vite hot-reload) + `api-dev` (FastAPI hot-reload) + `worker-dev` (ARQ queue worker) + `sandbox-provisioner` + Postgres + Redis + MinIO + Milvus + Neo4j + (optional `all` profile for `mineru-*` + `paddlex` parsers).
- ARQ for async background tasks (cohort first to use ARQ — most cohort entries use Celery, RQ, or BullMQ).
- Docker Compose: `docker-compose.yml` + `docker-compose.prod.yml` (separate prod profile).
- DeepWiki badge + zread.ai badge in README — uses 2 cohort-relevant external KB-explorer services.
- 演示视频 (Bilibili) link — cohort first to ship a Bilibili demo video.

## Notable design choices

- **Explicit cohort-downstream-consumer pattern** — Yuxi's pyproject.toml description literally names "LightRAG" alongside FastAPI + LangGraph + Vue as architecture pillars: `"基于 LangGraph v1 + Vue.js + FastAPI + LightRAG 架构构建"`. Cohort first to *officially document* a downstream relationship to another cohort entry (vs cohort entries that consume cognee / mem0 / FalkorDB as adapters per llama_index, where the consumption is one-of-N rather than a headline architecture pillar).
- **`ragflow_like` chunking attribution** — `chunking/ragflow_like/` directory name explicitly credits ragflow's per-format chunker pattern as inspiration. Cohort first **naming-as-attribution** pattern (vs cohort entries that re-implement RAG patterns silently). Worth tracking if other cohort entries adopt similar attribution naming.
- **8-middleware chain at LangGraph layer** — `middlewares/` decomposes agent runtime concerns into orthogonal middleware classes. Cohort first explicit middleware-chain abstraction at the LangGraph agent layer (most cohort entries bury these concerns as tool decorators / system-prompt injection / direct state mutation).
- **`LITE_MODE` development optimization** — `make up-lite` skips KB+graph modules at startup for fast iteration. Cohort-first explicit dev-mode shortcut.
- **9 Chinese-ecosystem document parsers** — cohort-novel breadth for CN doc-AI: DeepSeek-OCR / MinerU (custom + official) / PaddleX `pp_structure_v3` / RapidOCR. Distinct from SurfSense's US-tilted 9 parsers (Azure DI / Docling / LlamaCloud / Unstructured / Vision-LLM).
- **3 KB backends behind 1 factory** — `KnowledgeBaseManager` dispatches LightRAG-shaped vs Milvus-only vs Dify-remote KBs. The lightrag.py implementation includes an upstream-bug fix for [LightRAG #580](https://github.com/HKUDS/LightRAG/issues/580) — cohort-first downstream-fix-loop where a cohort consumer fixes an upstream cohort issue.
- **Sandbox + KB-mount predicate** — agent tools see `用户可访问知识库 ∩ 当前 Agent 已启用知识库` mounted read-only into `/home/gem/user-data`. Cohort first to expose KB content to agent sandbox via explicit-predicate mount.
- **`present_artifacts` agent output channel** — agent writes to `/home/gem/user-data/outputs/`, registers files in LangGraph state's `artifacts` field, frontend renders as stacked cards. Cohort first explicit "artifacts as agent output channel" pattern.
- **2 buildin specialized Skills** — `reporter` (database reports) + `deep-reporter` (industry research / scientific reports). Cohort-second specialized "deep research" skill in-tree (after deer-flow's deep-research skill).
- **API Key authentication** for external system integration (per v0.6.0).
- **ARQ task queue** instead of Celery / RQ / BullMQ — cohort first ARQ usage.

## Dependencies

Python 3.12 ≤ x < 3.14, Vue.js (web), FastAPI ≥ 0.121, uvicorn ≥ 0.34.2, ARQ ≥ 0.26.3 (background tasks), uses **Tsinghua PyPI mirror** as default index (CN-cloud-tilted distribution). LightRAG (consumed via PyPI). Neo4j Python driver. Milvus pymilvus. Optional: MinerU + PaddleX (`all` Docker profile).

## Tradeoffs

- **For**: cohort-first **explicit-downstream-consumer** pattern (LightRAG as headline architecture pillar, not just a backend option); cohort-first **8-middleware-chain at LangGraph layer**; cohort-first **`LITE_MODE` dev-shortcut**; cohort-first **9 Chinese-ecosystem document parsers** (DeepSeek-OCR / MinerU / PaddleX / RapidOCR coverage); cohort-first **KB-mount-into-sandbox via predicate**; cohort-first **`present_artifacts` agent output channel** + frontend stacked-card rendering; cohort-first **`ragflow_like` naming-as-attribution** pattern; cohort-second specialized **`deep-reporter` Skill**; cohort-first **upstream-bug downstream-fix loop** (Yuxi's `lightrag.py` carries fix for LightRAG #580); active dev (8 v0.5.0 → v0.6.0 release stages with substantial refactors); MIT; trendshift badge confirms recent trending status.
- **Against**: CN-language-first docs and code comments raise contributor friction for non-CN audiences (cohort-rare full CN documentation); single-author project (xerrors); Python 3.12+ requirement narrows runtime compatibility; heavy multi-service deploy (Postgres + Redis + MinIO + Milvus + Neo4j + sandbox + Vite + worker) — significant ops surface for production; v0.6.x signals pre-1.0 churn risk despite the substantial feature set; KB-implementation parity is uneven (lightrag.py is most-developed; milvus.py is vector-only; dify.py is a remote-proxy); Tsinghua PyPI mirror as default may not work for international contributors.

## When to use vs. cohort

- vs. **HKUDS/LightRAG** ([survey](HKUDS__LightRAG.md)) — Yuxi *consumes* LightRAG. Use LightRAG directly when you want a Python KG library + 6 retrieval modes; use Yuxi when you want LightRAG packaged with Vue UI + middleware chain + sandbox + Skills + multi-agent + CN-document parsing.
- vs. **MaxKB / FastGPT** (CN-tilted kb-apps) — MaxKB is Django + GPL-3.0 with Bailian / Volcengine / Wenxin / Zhipu CN-cloud LLMs. FastGPT is TypeScript + workflow + visual builder. Yuxi is FastAPI + LightRAG-substrate + LangGraph + middleware-chain. CN ecosystem coverage all three; Yuxi distinct on LightRAG-as-architecture-pillar.
- vs. **anything-llm / sim** (US-tilted kb-apps) — anything-llm: 37 LLMs / 35 connectors / Aibitat / SQLite-default. sim: workflow-as-MCP / 35 connectors / 17 LLMs / Drizzle. Yuxi: LightRAG-substrate / 9 CN parsers / LangGraph middleware. Different architectural strengths.
- vs. **HKUDS/DeepTutor** ([survey](HKUDS__DeepTutor.md)) — DeepTutor is HKUDS lab's tutoring application. Both consume LightRAG-family substrate. DeepTutor for personalized learning use case; Yuxi for general multi-tenant agent harness with CN-doc + KG focus.
- vs. **SurfSense** ([survey](MODSetter__SurfSense.md)) — SurfSense is US-cloud NotebookLM alternative with 22 read-only KB connectors + Electron desktop + 4-process distribution. Yuxi is CN-cloud LangGraph platform with 9 CN parsers + LightRAG substrate + sandbox-provisioner. Same general "team-KB-with-agent" shape, opposite cloud-ecosystem tilts.

## Code pointers

- LightRAG integration: [`backend/package/yuxi/knowledge/implementations/lightrag.py`](https://github.com/xerrors/Yuxi/blob/main/backend/package/yuxi/knowledge/implementations/lightrag.py).
- KB factory + manager: [`backend/package/yuxi/knowledge/{factory,manager,base}.py`](https://github.com/xerrors/Yuxi/tree/main/backend/package/yuxi/knowledge).
- 3 KB implementations: [`backend/package/yuxi/knowledge/implementations/{lightrag,milvus,dify}.py`](https://github.com/xerrors/Yuxi/tree/main/backend/package/yuxi/knowledge/implementations).
- 9 document parsers: [`backend/package/yuxi/plugins/parser/`](https://github.com/xerrors/Yuxi/tree/main/backend/package/yuxi/plugins/parser).
- `ragflow_like` chunking: [`backend/package/yuxi/knowledge/chunking/ragflow_like/`](https://github.com/xerrors/Yuxi/tree/main/backend/package/yuxi/knowledge/chunking/ragflow_like).
- 8 middleware classes: [`backend/package/yuxi/agents/middlewares/`](https://github.com/xerrors/Yuxi/tree/main/backend/package/yuxi/agents/middlewares).
- 2 buildin Skills: [`backend/package/yuxi/agents/skills/buildin/{reporter,deep-reporter}/`](https://github.com/xerrors/Yuxi/tree/main/backend/package/yuxi/agents/skills/buildin).
- Toolkits: [`backend/package/yuxi/agents/toolkits/{buildin,debug,kbs,mysql}/`](https://github.com/xerrors/Yuxi/tree/main/backend/package/yuxi/agents/toolkits).
- Services (~20): [`backend/package/yuxi/services/`](https://github.com/xerrors/Yuxi/tree/main/backend/package/yuxi/services).
- Sandbox provisioner: [`docker/sandbox_provisioner/`](https://github.com/xerrors/Yuxi/tree/main/docker/sandbox_provisioner).
- LITE_MODE startup: per v0.6.0 release notes (`make up-lite`); router gating in [`backend/server/routers/__init__.py`](https://github.com/xerrors/Yuxi/blob/main/backend/server/routers/__init__.py).
- `present_artifacts` agent tool: per v0.6.0 release notes; in `agents/toolkits/buildin/tools.py`.
- Architecture overview: [`ARCHITECTURE.md`](https://github.com/xerrors/Yuxi/blob/main/ARCHITECTURE.md) + [`AGENTS.md`](https://github.com/xerrors/Yuxi/blob/main/AGENTS.md) + [`CLAUDE.md`](https://github.com/xerrors/Yuxi/blob/main/CLAUDE.md).

## Open questions

- **LightRAG #580 fix downstream-trip** — Yuxi carries a fix for an upstream LightRAG bug. Has it been upstreamed? Are other LightRAG consumers (e.g., DeepTutor — same lab) also affected?
- **`ragflow_like` chunking parity** — module name credits ragflow as inspiration. How close is the implementation to ragflow's actual chunkers?
- **Dify integration depth** — `dify.py` is one of 3 KB implementations. Is it a thin proxy or substantive integration? (Cohort cross-link: Dify is in candidates, ★139k.)
- **Subagent enumeration** — release notes mention "2 buildin subagents" but specific names not in scanned files. Worth grepping `agents/buildin/` for the actual implementations.
- **`deep-reporter` vs cohort `deep_solve` / `deep_research`** — Yuxi's `deep-reporter` Skill, DeepTutor's `deep_solve` capability, deer-flow's `deep-research` skill, basic-memory's `deep_research` mode all converge on "deep research" naming. Is there an emergent cohort pattern around long-horizon research workflows?
- **Tsinghua PyPI mirror** as default — does this work for international contributors, or is there a mirror-fallback path?

---

*Audit 2026-05-03: clone-verified against [xerrors/Yuxi@main](https://github.com/xerrors/Yuxi) (last commit 2026-05-01 14:18). MIT confirmed in `LICENSE`. Version `yuxi-workspace 0.6.2` per `backend/pyproject.toml`; v0.6.0 release notes dated 2026-04-01 in README. **Cohort-downstream-consumer pattern verified verbatim** in pyproject description: `"基于 LangGraph v1 + Vue.js + FastAPI + LightRAG 架构构建"`. LightRAG integration verified at `backend/package/yuxi/knowledge/implementations/lightrag.py:1-25` (imports `from lightrag import LightRAG, QueryParam`). 3 KB implementations enumerated by `ls knowledge/implementations/` (lightrag / milvus / dify). 9 parsers verified by `ls plugins/parser/` (deepseek_ocr / mineru / mineru_official / pp_structure_v3 / rapid_ocr / unified / zip_utils + base + factory). 8 middleware classes verified by `ls agents/middlewares/`. 2 buildin Skills verified by `ls agents/skills/buildin/` (reporter + deep-reporter). 4 toolkit categories verified by `ls agents/toolkits/`. ~20 services verified by `ls services/`. `ragflow_like` chunking dir verified at `knowledge/chunking/ragflow_like/`. Architecture overview verified verbatim from `ARCHITECTURE.md:1-30`. v0.6.0 release notes (LITE_MODE, sandbox, KB-mount predicate, present_artifacts, API Key auth) verified in README. Tsinghua PyPI mirror default verified at `backend/pyproject.toml:30-32`. Corrections: none (first-pass survey).*
