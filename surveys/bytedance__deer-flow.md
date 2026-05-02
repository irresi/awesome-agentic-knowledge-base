# Survey: bytedance/deer-flow

**Date:** 2026-05-02
**Stars:** 64,426 · **Last push:** 2026-05-01 · **Created:** 2025-05 · **Version:** `deer-flow 0.1.0` (orchestrator) + `deerflow-harness` (workspace package) · **License:** MIT (Bytedance 2025)
**Category:** coding-agent
**Slug:** [bytedance/deer-flow](https://github.com/bytedance/deer-flow)

---

## TL;DR (3 lines)

- **What it is:** ByteDance's open-source **super agent harness** — *"DeerFlow 2.0 = ground-up rewrite, no shared code with v1"*. LangGraph-based runtime, FastAPI Gateway, Next.js frontend, Nginx proxy, optional Kubernetes/provisioner sandbox tier. MIT licensed. Topped GitHub Trending #1 on 2026-02-28 after the v2 launch.
- **How its KB works:** **`deerflow-harness` Python package** ships agents/middlewares/sandbox/subagents/skills/MCP/memory subsystems. Memory is a per-thread `version: "1.0"` JSON document with `user.workContext.summary` extracted via a queue + summarization-hook middleware; LangGraph checkpointers (`langgraph-checkpoint-sqlite` default, `langgraph-checkpoint-postgres` opt-in) persist agent state. **21 public skills** ship in `skills/public/` (deep-research, ppt-generation, podcast-generation, video-generation, github-deep-research, …) following Anthropic's SKILL.md format. **7 IM channels** (DingTalk/Discord/Feishu/Slack/Telegram/WeChat/WeCom) and an embedded Python client.
- **Verdict:** Pick when you want a **production-shaped LangGraph harness** with sandbox + sub-agents + 20 ready-made skills + multi-channel IM bots — and you're OK with ByteDance's stack. Skip if you want a single-binary library or a memory-framework (DeerFlow is the harness, not the memory engine).

## KB Architecture

### Storage
- **Vector store:** *None native* — DeerFlow uses external retrieval (Tavily, Jina, Firecrawl, Exa, DuckDuckGo) and indexes are managed per-skill (deep-research / github-deep-research) rather than a shared vector DB. `duckdb>=1.4.4` for analytical workloads in skills.
- **Graph store:** *None.*
- **Metadata / structured:** **SQLite** (default) or **Postgres** (opt-in). `langgraph-checkpoint-sqlite` for thread-state checkpointing; `aiosqlite` + SQLAlchemy 2 + Alembic for migrations. Postgres extra: `langgraph-checkpoint-postgres` + `asyncpg` + `psycopg[binary]` + `psycopg-pool`.
- **Object / blob:** Local filesystem (`uploads/`) for user-uploaded files; sandbox provides isolated FS per-thread. `agent-sandbox>=0.0.19` external dep.

### Ingestion / Extraction
- **Source types accepted:** Conversational messages → memory queue → summarization hook. Web content via tavily/firecrawl/exa/jina/ddgs. PDFs via optional `pymupdf4llm`. Markdown via `markitdown[all,xlsx]` and `markdownify`. Image / chart / podcast / video generation are first-class through skills.
- **Chunking strategy:** Per-skill — deep-research skill builds multi-angle research notes; ppt/podcast/video skills compose structured outputs.
- **Entity / fact extraction:** Memory `extraction.py` + `updater.py` + `summarization_hook.py` distill conversation messages into a typed JSON structure; the `user.workContext.summary` field is the primary extracted artefact (free-form summary, not atomic facts).
- **Schema:** `version: "1.0"`, `lastUpdated`, `user.workContext.summary`/`updatedAt` — minimal taxonomy compared to MaxKB's 4-category or memvid's 6-kind taxonomies.

### Retrieval
- **Modes:** Per-skill — deep-research uses systematic multi-angle web search; github-deep-research is GitHub-shaped; chart-visualization / data-analysis pull from DuckDB. The harness does not enforce a global retrieval mode.
- **Reranker:** Per-skill / per-tool — none global.
- **Top-k defaults:** Skill-driven.
- **Context assembly:** **Middlewares pipeline** (10 components, per CLAUDE.md) — including `summarization_hook` for memory consolidation. Sub-agents (`bash_agent`, `general_purpose`) handle delegated tasks; sub-agent results are streamed back via `StreamBridge`.

### Memory model
- **Tiers:**
  - **Per-thread `ThreadState`** — LangGraph checkpointer state (SQLite/Postgres).
  - **Long-term memory** — JSON document at `agents/memory/storage.py`; queue + updater + summarization-hook middleware writes summaries on a schedule.
  - **Sandbox FS** — per-thread isolated filesystem.
- **Bi-temporal:** No.
- **Self-update mechanism:** **Summarization-hook middleware** (`agents/memory/summarization_hook.py`) — runs as part of the LangGraph middleware pipeline; consolidates older messages into the `workContext.summary` field.
- **Decay / forgetting:** Implicit through summarization (older raw messages get squeezed into the summary).

### MCP / connectors
- **MCP server exposed:** **Yes** — README mentions a dedicated "MCP Server" advanced feature; harness has [`deerflow/mcp/`](https://github.com/bytedance/deer-flow/tree/main/backend/packages/harness/deerflow/mcp) with `tools`, `cache`, `client` modules.
- **MCP client used:** Yes — via `langchain-mcp-adapters>=0.2.2` + the harness `mcp/client.py` consumes external MCP servers.
- **Native connectors:** **7 IM channels** at [`backend/app/channels/`](https://github.com/bytedance/deer-flow/tree/main/backend/app/channels) — `dingtalk.py`, `discord.py`, `feishu.py`, `slack.py`, `telegram.py`, `wechat.py`, `wecom.py`. Plus `agent-client-protocol>=0.4.0` for ACP integration with downstream tools.
- **Tool-call surface:** **21 shipped public skills** — academic-paper-review, bootstrap, chart-visualization, claude-to-deerflow, code-documentation, consulting-analysis, data-analysis, deep-research, find-skills, frontend-design, github-deep-research, image-generation, newsletter-generation, podcast-generation, ppt-generation, skill-creator, surprise-me, systematic-literature-review, vercel-deploy-claimable, video-generation, **web-design-guidelines**. Plus built-in tools (`tools/builtins/`: `present_files`, `ask_clarification`, `view_image`) and community tools (`community/`: tavily, jina_ai, firecrawl, image_search, aio_sandbox).

### Notable design choices
- **LangGraph as the runtime** — `langgraph>=1.1.9`, `langgraph-api>=0.8.1`, `langgraph-cli>=0.4.24`, `langgraph-runtime-inmem>=0.28.0`, `langgraph-sdk>=0.1.51`, `langgraph-checkpoint-sqlite>=3.0.3`. Most LangGraph-native repo in the cohort.
- **`deerflow-harness` as a separable package** — backend is split into `app/` (FastAPI Gateway + IM channels) and `packages/harness/` (the agent runtime). Harness is importable as `from deerflow import …`. Embedded `DeerFlowClient` exposes the runtime to other Python apps without the Gateway.
- **21 public skills following Anthropic's SKILL.md format** — convergent with claude-mem / OpenHands / WeKnora / UA / AstrBot / byterover-cli. The `claude-to-deerflow` skill is notable: explicit conversion path from Claude Code skills to DeerFlow skills. The `find-skills` skill helps the agent discover available capabilities. The newly-added `web-design-guidelines` skill suggests guidance/style-rule shaped skills are an emerging pattern.
- **Multi-language READMEs** — EN / 简体中文 / 日本語 / Français / Русский — broad geographic distribution.
- **"Coding Plan from ByteDance Volcengine"** — recommended models are Doubao-Seed-2.0-Code, DeepSeek v3.2, Kimi 2.5 — all CN providers; partnership-driven distribution.
- **Sandbox via `agent-sandbox` dep + Kubernetes provisioner mode** — Docker dev provisions sandboxes; production can offload to K8s via the provisioner service on port 8002.
- **Nginx as the unified entry point on port 2026** — Gateway 8001 + Frontend 3000 + (optional) Provisioner 8002 routed through one host.
- **`langfuse>=3.4.1` for tracing** — opt-in observability via Langfuse OR LangSmith. README documents how to use both providers.
- **InfoQuest integration** — BytePlus-developed search/crawl toolkit; promoted in the README. Cohort first to integrate a vendor-developed retrieval toolkit as a featured option.

## Dependencies (KB-relevant)

From `backend/packages/harness/pyproject.toml`:

```
name = "deerflow-harness"
requires-python = ">=3.12"

# Agent runtime (LangGraph-heavy)
langgraph>=1.1.9
langgraph-api>=0.8.1
langgraph-cli>=0.4.24
langgraph-runtime-inmem>=0.28.0
langgraph-sdk>=0.1.51
langgraph-checkpoint-sqlite>=3.0.3
langchain>=1.2.15
langchain-anthropic>=1.4.1
langchain-deepseek>=1.0.1
langchain-google-genai>=4.2.1
langchain-mcp-adapters>=0.2.2
langchain-openai>=1.2.1

# Sandbox + ACP
agent-sandbox>=0.0.19
agent-client-protocol>=0.4.0
kubernetes>=30.0.0

# Storage
sqlalchemy[asyncio]>=2.0,<3.0
aiosqlite>=0.19
alembic>=1.13
duckdb>=1.4.4                       # data-analysis skill

# Search / crawl
tavily-python>=0.7.17
firecrawl-py>=1.15.0
exa-py>=1.0.0
ddgs>=9.10.0
markdownify>=1.2.2
markitdown[all,xlsx]>=0.0.1a2
readabilipy>=0.3.0

# Tracing
langfuse>=3.4.1

# Optional extras
ollama: langchain-ollama>=0.3.0
postgres: asyncpg + psycopg + langgraph-checkpoint-postgres
pymupdf: pymupdf4llm>=0.0.17
```

License: **MIT**.

## Tradeoffs

**Pros:**
- **Largest LangGraph deployment in the cohort** — uses the official `langgraph-api` server + `langgraph-cli` + Studio integration via `langgraph.json`.
- **20 production-shaped skills shipped** — deep-research / ppt / podcast / video / github-deep-research / academic-paper-review are non-trivial workflows.
- **7 IM channels** — DingTalk, Feishu, WeCom, WeChat first-class alongside Slack/Telegram/Discord. Cohort second-largest IM surface (AstrBot has 8).
- **Sandbox tier with K8s provisioner mode** — production-grade isolation; not just docker-on-laptop.
- **Embedded Python client** — `DeerFlowClient` lets you embed the runtime in another app without the Gateway.
- **Tracing backed in** — Langfuse OR LangSmith via env vars; documented dual-provider setup.
- **Multi-language README + ByteDance + GitHub Trending #1** — strong distribution.
- **Skill `claude-to-deerflow`** — bidirectional conversion between Claude Code's skill system and DeerFlow's, signals interoperability is a design priority.

**Cons:**
- **Heavy operational footprint** — Gateway + Frontend + Nginx + (Provisioner) + Sandbox + LangGraph state. Not a single-binary tool.
- **No native vector store / graph store** — the harness leans on external retrieval; if you need cohort-style hybrid retrieval out of the box, you'll bolt it on.
- **Memory schema is minimal** — `user.workContext.summary` is one free-form field; no MaxKB-style 4-category, no memvid-style 6-kind, no graphiti bi-temporal.
- **Heavy LangGraph version churn risk** — pinned across 7 langgraph-* packages, plus 6 langchain-* packages.
- **DeerFlow 2.0 is a ground-up rewrite** — README explicitly says "shares no code with v1"; v1 users on `1.x` branch lose continuity.
- **CN-vendor-tilt** — recommended models / Volcengine partnership / InfoQuest integration are CN-cloud-favorable. Globally portable but China-cloud-first.
- **Skill catalogue is opinionated** — 20 shipped skills are useful but tilted toward research/content generation; less coverage for pure coding workflows.

## When to use it

- **Good fit:** teams wanting a LangGraph-based super-agent harness with sandboxed execution, sub-agent delegation, 20 ready-made skills, multi-channel IM, and observability via Langfuse/LangSmith. CN-cloud-friendly deployments. Research-heavy / content-generation workflows.
- **Bad fit:** single-binary CLIs / laptop-only deployments; teams allergic to LangChain/LangGraph; products needing typed memory taxonomies (use mem0/graphiti/memvid/MemOS); Apache-2.0-only or GPL-only legal envelopes.
- **Closest alternative:** [`OpenHands/OpenHands`](surveys/OpenHands__OpenHands.md) — also a multi-tenant coding-agent orchestrator with sandboxed runtime, microagents, and IM/Slack integration; OpenHands is more coding-agent-shaped, DeerFlow is more SuperAgent-shaped (research + content + IM bots). [`thedotmack/claude-mem`](surveys/thedotmack__claude-mem.md) is the Claude-Code-plugin-shaped alternative for capture+recall workflows. [`AstrBotDevs/AstrBot`](surveys/AstrBotDevs__AstrBot.md) is the comparable IM-platform-first chatbot framework, but Python/Quart-based and KB-module-shaped rather than super-agent-harness-shaped.

## Code pointers (evidence)

- Harness package layout: [`backend/packages/harness/deerflow/`](https://github.com/bytedance/deer-flow/tree/main/backend/packages/harness/deerflow) — `agents/`, `subagents/`, `sandbox/`, `tools/`, `mcp/`, `models/`, `skills/`, `runtime/`, `community/`, `reflection/`, `persistence/`, `config/`, `tracing/`, `guardrails/`, `uploads/`, `utils/`
- Memory subsystem: [`agents/memory/`](https://github.com/bytedance/deer-flow/tree/main/backend/packages/harness/deerflow/agents/memory) — `storage.py`, `queue.py`, `extraction.py`, `updater.py`, `summarization_hook.py`, `prompt.py`, `message_processing.py`
- LangGraph runtime: [`runtime/`](https://github.com/bytedance/deer-flow/tree/main/backend/packages/harness/deerflow/runtime) — `runs/`, `events/`, `store/`, `checkpointer/`, `stream_bridge/`, plus `RunManager` + `run_agent()`
- Sub-agents (bash + general-purpose): [`subagents/builtins/`](https://github.com/bytedance/deer-flow/tree/main/backend/packages/harness/deerflow/subagents/builtins) (`bash_agent.py`, `general_purpose.py`)
- 20 shipped skills: [`skills/public/`](https://github.com/bytedance/deer-flow/tree/main/skills/public) (each is a directory with SKILL.md + supporting files)
- 7 IM channels: [`backend/app/channels/`](https://github.com/bytedance/deer-flow/tree/main/backend/app/channels)
- Embedded Python client: [`packages/harness/deerflow/client.py`](https://github.com/bytedance/deer-flow/blob/main/backend/packages/harness/deerflow/client.py)
- LangGraph Studio config: [`backend/langgraph.json`](https://github.com/bytedance/deer-flow/blob/main/backend/langgraph.json)
- Most useful single file to read first: [`backend/CLAUDE.md`](https://github.com/bytedance/deer-flow/blob/main/backend/CLAUDE.md) — concise architecture overview written for AI agents, includes the full `harness/` directory map.

## Open questions

- The 10 middlewares — what's the full list? CLAUDE.md mentions "10 middleware components" but doesn't enumerate. Worth a deeper read of `agents/middlewares/`.
- `agent-client-protocol>=0.4.0` integration — is DeerFlow exposing ACP-compatible interfaces or consuming external ACP agents (like onyx's "Build" sandbox)?
- The `community/` tools (tavily, jina_ai, firecrawl, image_search, aio_sandbox) — are they cohort-defining ones or thin wrappers?
- Memory schema (`user.workContext.summary`) is minimal — is there a richer schema in the works, or is summarization the design point?
- Skill-creator workflow vs UA's 9 specialist agents vs WeKnora's 5 preloaded skills — do these converge on a shared skill-authoring pattern, or are they each going in different directions?
- v1 → v2 rewrite — what specifically did the team learn that motivated dropping all v1 code?

---

*Surveyed via the `curating-agentic-kbs` skill. Re-survey scheduled after 30 days of last `pushed_at` change.*

*Audit 2026-05-02: clone-verified against [`backend/pyproject.toml`](https://github.com/bytedance/deer-flow/blob/main/backend/pyproject.toml) (`deer-flow` v0.1.0; `deerflow-harness` workspace dep + `[postgres]` extra; `langgraph-sdk>=0.1.51`), [`backend/app/channels/`](https://github.com/bytedance/deer-flow/tree/main/backend/app/channels) (7 IM channel adapters: dingtalk, discord, feishu, slack, telegram, wechat, wecom — separate from 6 infra files: base, commands, manager, message_bus, service, store), [`skills/public/`](https://github.com/bytedance/deer-flow/tree/main/skills/public) (21 subdirs), [`LICENSE`](https://github.com/bytedance/deer-flow/blob/main/LICENSE) (MIT, "Bytedance Ltd. and/or its affiliates" 2025). **Correction:** public skills count **20 → 21** — added `web-design-guidelines` (newly shipped post-survey). **Verified verbatim:** 7 IM channels exact, MIT license, `deerflow-harness` workspace package + `[postgres]` extra for opt-in postgres checkpointer.*
