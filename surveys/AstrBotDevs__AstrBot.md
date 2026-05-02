# Survey: AstrBotDevs/AstrBot

**Date:** 2026-05-01
**Stars:** 31,088 · **Last push:** 2026-05-01 · **Created:** 2023 · **Version:** `4.23.6`
**Category:** kb-app
**Slug:** [AstrBotDevs/AstrBot](https://github.com/AstrBotDevs/AstrBot)

---

## TL;DR (3 lines)

- **What it is:** Multi-platform IM chatbot framework (QQ / WeChat / Feishu / DingTalk / Telegram / Slack / Discord / Telegram / Lark / WeChat Official Accounts) with an integrated knowledge-base module, an MCP-client agent loop, plugin ecosystem ("stars"), and a Docker-sandboxed computer-use mode.
- **How its KB works:** Per-KB SQLite tables (knowledge_bases / kb_documents / kb_media) → chunkers (recursive / fixed-size, default 512 / 50 overlap) → optional LLM "text repair" prompt to strip nav/ads → Faiss flat index for dense retrieval, rank-bm25 with jieba+HIT-stopwords for sparse retrieval → **RRF fusion (k=60)** → optional rerank via pluggable provider (bailian / nvidia / vllm / xinference). Conversations and personas are SQL-backed; "long-term memory" is a per-group chat-history accumulator, not vector recall.
- **Verdict:** Pick when you need to ship a knowledge-aware chatbot across many Chinese-and-global IM platforms in one codebase. Not the right tool when you need a graph KB, multi-tenant SaaS RAG, or MCP-server-as-product (AstrBot is *MCP client only*).

## KB Architecture

### Storage
- **Vector store:** **Faiss** (`faiss-cpu>=1.12.0`) — flat IndexFlatL2 via `astrbot.core.db.vec_db.faiss_impl`, paired with a separate SQLite `DocumentStorage` for chunk metadata + per-doc rows. Single backend; abstracted behind a `BaseVecDB` ABC so swap-in is feasible but no other backend ships.
- **Graph store:** *None.*
- **Metadata / structured:** **SQLite** via `aiosqlite` + SQLAlchemy 2 / SQLModel; one DB for KB tables (`knowledge_bases`, `kb_documents`, `kb_media`), one for conversations/personas/platform-history/cron/event-log.
- **Object / blob:** Local filesystem — `KBMedia.file_path` stores extracted images / videos from documents.

### Ingestion / Extraction
- **Source types accepted:** PDF (pypdf), EPUB, plain text, Markdown / DOCX / XLSX (via `markitdown-no-magika[docx,xls,xlsx]`), URL (`url_parser` for web pages). Plus IM events flowing through `ConversationManager` (kept separate from the KB).
- **Chunking strategy:** Two chunkers in [`knowledge_base/chunking/`](https://github.com/AstrBotDevs/AstrBot/tree/main/astrbot/core/knowledge_base/chunking) — `RecursiveCharacterChunker` (default) and `FixedSizeChunker`. Per-KB `chunk_size` (default 512) and `chunk_overlap` (default 50) stored on the KB row.
- **Entity / fact extraction:** *No structured entity/triple extraction.* Instead, an **LLM "text repair" pass** ([`prompts.py`](https://github.com/AstrBotDevs/AstrBot/blob/main/astrbot/core/knowledge_base/prompts.py)) — a small LLM is asked to separate signal from noise (UI / nav / ads), output `<repaired_text>` blocks, and discard pure-noise chunks (`<discard_chunk />`). Splits multi-topic chunks. Rate-limited via an in-process `RateLimiter`. Not a graph builder — strictly a chunk cleaner.
- **Schema:** **Flat** — `KBDocument` → many `Chunk` rows (in SQLite + Faiss vector) → optional `KBMedia` rows for image/video extracted alongside text.

### Retrieval
- **Modes:** **Dense + sparse + RRF fusion** (`astrbot.core.knowledge_base.retrieval.RetrievalManager`). Dense path: query → embedding provider → Faiss top-k (default `top_k_dense=50`). Sparse path: query → jieba tokens (HIT stopwords removed) → cached `BM25Okapi` index → top-k (default `top_k_sparse=50`). Fusion: Reciprocal Rank Fusion (`k=60`). Optional rerank via provider on top-`top_m_final` (default 5).
- **Reranker:** Pluggable via `RerankProvider` abstraction. Built-in providers: `bailian_rerank_source`, `nvidia_rerank_source`, `vllm_rerank_source`, `xinference_rerank_source`. No HuggingFace cross-encoder default.
- **Top-k defaults:** `top_k_dense=50`, `top_k_sparse=50`, `top_m_final=5`. All per-KB tunable on the `KnowledgeBase` SQLModel row.
- **Context assembly:** RetrievalManager returns `RetrievalResult` rows (chunk_id / doc_id / kb_id / content / score / metadata); the agent pipeline injects them into the prompt. Token-bounded merge into the conversation history.

### Memory model
- **Tiers:** Three *separate* layers, intentionally not unified:
  - **Conversation history** — `ConversationManager` (full SQL history per `unified_msg_origin`, with switch / delete / persona-id / human-readable rollup APIs).
  - **Persona** — `PersonaManager` (system-prompt presets + per-conversation persona-id binding).
  - **"Long-term memory"** — `astrbot/builtin_stars/astrbot/long_term_memory.py`. Misleading name: this is an in-memory `defaultdict[unified_msg_origin → list[chat]]` that records group-chat exchanges so the bot can do "active reply" (probabilistic interjection); it's NOT vector recall over past memory. Image-caption hook for vision-aware history.
  - **Knowledge base** — formal `astrbot/core/knowledge_base/` module described above. Doc-RAG, separate from conversation memory.
- **Bi-temporal:** No.
- **Self-update mechanism:** None — KBs are explicitly built via WebUI / API uploads; conversation history is append-only by design.
- **Decay / forgetting:** None automatic; conversation manager exposes `delete_conversation` / `delete_conversations_by_user_id`.

### MCP / connectors
- **MCP server exposed:** **No.** `grep` for `mcp.server` / `FastMCP` returns zero matches. AstrBot does not surface itself or its KB as an MCP server.
- **MCP client used:** **Yes — three transports in one class** ([`astrbot/core/agent/mcp_client.py`](https://github.com/AstrBotDevs/AstrBot/blob/main/astrbot/core/agent/mcp_client.py)). Imports `mcp.client.stdio`, `mcp.client.sse`, **AND** `mcp.client.streamable_http`. Notable hardening: explicit allowlist `{python, node, npx, uv, deno, bun, ...}` and explicit denylist `{bash, sh, curl, ssh, rm, sudo, chmod, kill, shutdown, ...}` for stdio commands — defensive layer most other repos in this cohort don't ship.
- **Native connectors:** The **IM platforms themselves** are AstrBot's connectors. First-party adapters for QQ (`aiocqhttp`, `qq-botpy`), WeChat (`wechatpy`), Feishu/Lark (`lark-oapi`), DingTalk (`dingtalk-stream`), Telegram (`python-telegram-bot`), Slack (`slack-sdk`), Discord (`py-cord`), WeChat Official Accounts. Plus 1000+ community plugins.
- **Tool-call surface:** Agent loop in `astrbot/core/agent/` with `func_tool_manager`, `tool_executor`, `mcp_client`. Plugins ("stars") register tools via decorators. Computer-use mode runs tools inside an `aiodocker`-managed Docker sandbox at `/workspace`.

### Notable design choices
- **Skills system over the sandbox** — `astrbot/core/skills/skill_manager.py` mounts `SKILL.md` files at `/workspace/skills/<name>/SKILL.md` inside the Docker sandbox, with bundle scan/sync logic, ZIP-import safety (rejects `__MACOSX` entries, name normalization, path traversal guards). Same conceptual pattern as claude-mem's bundled skills, OpenHands's `.openhands/microagents/*.md`, and Anthropic's plugin Skills — but **mounted into a sandbox FS rather than read by the host**.
- **AGPL-3.0-or-later** with a custom EULA — shifts the cohort's AGPL count.
- **Per-KB embedding/rerank provider** — `embedding_provider_id` and `rerank_provider_id` are columns on the `KnowledgeBase` row, so different KBs in one deployment can use entirely different vendors. Rare in this cohort (most repos pin one default).
- **No vector backend pluggability beyond Faiss** despite the `BaseVecDB` ABC — every code path imports `faiss_impl` directly. The abstraction is real but unused.
- **LLM "text repair" prompt as ingestion step** — explicitly cleans web-scraped / OCR'd noise instead of dumping raw chunks. One of two cohort members with an LLM in the *cleanup* stage rather than the *extraction* stage.
- **MCP client supports stdio + SSE + StreamableHTTP** — three transports is more than any other surveyed repo (cline supports stdio + SSE + StreamableHTTP too; khoj only stdio+SSE; ragflow/mem0/cognee mostly stdio).
- **`python-ripgrep==0.0.8`** as a hard dep — AstrBot uses ripgrep for repo/skill scanning inside the sandbox.
- **Quart (async Flask)** for HTTP, Vue 3 + Vite dashboard. 1000+ plugins distributed via a central plugin store.

## Dependencies (KB-relevant)

From `pyproject.toml`:

```
license = { text = "AGPL-3.0-or-later" }
requires-python = ">=3.12"

# KB / retrieval
faiss-cpu>=1.12.0
rank-bm25>=0.2.2
jieba>=0.42.1
markitdown-no-magika[docx,xls,xlsx]>=0.1.2
pypdf>=6.1.1
sqlalchemy[asyncio]>=2.0.41
sqlmodel>=0.0.24
aiosqlite>=0.21.0
xinference-client            # rerank / embedding backend

# Agent / MCP / sandbox
mcp>=1.8.0
aiodocker>=0.24.0            # Docker sandbox for computer-use
python-ripgrep==0.0.8
tenacity>=9.1.2

# IM platform adapters (each is an MCP-substitute connector)
aiocqhttp, qq-botpy, wechatpy, lark-oapi, dingtalk-stream
python-telegram-bot, slack-sdk, py-cord

# Multi-LLM SDKs
openai, anthropic, google-genai, dashscope (Alibaba Bailian)
```

License: **AGPL-3.0-or-later** + custom EULA (`EULA.md`).

## Tradeoffs

**Pros:**
- **Best-in-class IM-platform coverage** — 8+ first-party adapters, no other repo in this cohort treats IM as the primary surface.
- **Hardened MCP client** — explicit allowlist/denylist of stdio commands is a real defense-in-depth pattern; cohort peers ship raw `subprocess.Popen` with no guardrails.
- **Per-KB tunables on the row** — chunk_size / chunk_overlap / top_k_dense / top_k_sparse / top_m_final / embedding_provider_id / rerank_provider_id all per-KB, not a single global config. Easy to A/B retrieval settings without forking config files.
- **Clean separation of memory layers** — conversation, persona, KB, "long-term" (group-chat tape) are deliberately decoupled. Easy to reason about; easy to disable any one.
- **Three-transport MCP client + Docker sandbox + skills mount** — production-shaped agent runtime in one process.

**Cons:**
- **Single vector backend (Faiss)** — `BaseVecDB` ABC exists but no second implementation. Scale ceiling = whatever Faiss flat-index handles in RAM.
- **No graph layer, no entity extraction, no atomic-fact memory** — ingestion is "chunk → embed → BM25 + Faiss". No multi-hop, no temporal, no schema-typed facts.
- **MCP client only — no MCP server** — you cannot wire AstrBot's KB into Claude Code / Cursor as a tool source. Reverse direction works (AstrBot consumes external MCP servers), but interop is one-way.
- **"Long-term memory" name is misleading** — the `LongTermMemory` builtin is in-process group-chat history with active-reply triggers; not vector-backed recall.
- **AGPL-3.0 + custom EULA** — copyleft AND additional terms; embedding constraints are stricter than pure AGPL. Read [`EULA.md`](https://github.com/AstrBotDevs/AstrBot/blob/main/EULA.md) before commercial use.
- **Heavy dependency surface** — 70+ runtime deps including IM SDKs that pin specific versions; conflict-prone in a shared venv.

## When to use it

- **Good fit:** teams shipping a knowledge-aware chatbot across QQ/WeChat/Feishu/DingTalk/Telegram/Discord/Slack/Lark in one codebase; deployments where the KB is per-group/per-tenant SQLite + Faiss; CN-market-first products that need jieba + Bailian-rerank-friendly providers.
- **Bad fit:** SaaS RAG over millions of docs (Faiss flat-index ceiling); products that need graph reasoning or bi-temporal memory; teams that want to expose the KB as an MCP server for other agents to consume; LGPL/Apache-only legal envelopes.
- **Closest alternative:** [`infiniflow/ragflow`](surveys/infiniflow__ragflow.md) — same kb-app + multi-tenant shape but with deep document parsing (deepdoc OCR), pluggable doc engines, full graph layer, and both MCP server + client. RAGFlow is the heavy enterprise variant; AstrBot is the IM-platform-first lightweight one. [`labring/FastGPT`](surveys/labring__FastGPT.md) overlaps on the "TS-first KB+chat platform" thesis but FastGPT is workflow-driven and runs Mongo + multiple vector backends.

## Code pointers (evidence)

- KB SQL schema (Pydantic/SQLModel rows): [`astrbot/core/knowledge_base/models.py:11`](https://github.com/AstrBotDevs/AstrBot/blob/main/astrbot/core/knowledge_base/models.py)
- Faiss vector DB (with separate SQLite document store): [`astrbot/core/db/vec_db/faiss_impl/vec_db.py:15`](https://github.com/AstrBotDevs/AstrBot/blob/main/astrbot/core/db/vec_db/faiss_impl/vec_db.py)
- Hybrid retrieval orchestrator: [`astrbot/core/knowledge_base/retrieval/manager.py:37`](https://github.com/AstrBotDevs/AstrBot/blob/main/astrbot/core/knowledge_base/retrieval/manager.py)
- BM25 sparse retriever (jieba + HIT stopwords + per-KB cached BM25Okapi): [`astrbot/core/knowledge_base/retrieval/sparse_retriever.py:33`](https://github.com/AstrBotDevs/AstrBot/blob/main/astrbot/core/knowledge_base/retrieval/sparse_retriever.py)
- RRF fusion (k=60): [`astrbot/core/knowledge_base/retrieval/rank_fusion.py:27`](https://github.com/AstrBotDevs/AstrBot/blob/main/astrbot/core/knowledge_base/retrieval/rank_fusion.py)
- LLM "text repair" prompt — ingestion-time chunk cleaner: [`astrbot/core/knowledge_base/prompts.py:1`](https://github.com/AstrBotDevs/AstrBot/blob/main/astrbot/core/knowledge_base/prompts.py)
- MCP client (stdio + SSE + StreamableHTTP, allowlist/denylist): [`astrbot/core/agent/mcp_client.py`](https://github.com/AstrBotDevs/AstrBot/blob/main/astrbot/core/agent/mcp_client.py)
- Skills bundle → sandbox FS sync: [`astrbot/core/skills/skill_manager.py`](https://github.com/AstrBotDevs/AstrBot/blob/main/astrbot/core/skills/skill_manager.py); applied via [`astrbot/core/computer/computer_client.py`](https://github.com/AstrBotDevs/AstrBot/blob/main/astrbot/core/computer/computer_client.py)
- "Long-term memory" (per-group chat-history accumulator, *not* vector memory): [`astrbot/builtin_stars/astrbot/long_term_memory.py`](https://github.com/AstrBotDevs/AstrBot/blob/main/astrbot/builtin_stars/astrbot/long_term_memory.py)
- Most useful single file to read first: [`astrbot/core/knowledge_base/retrieval/manager.py`](https://github.com/AstrBotDevs/AstrBot/blob/main/astrbot/core/knowledge_base/retrieval/manager.py) — single class shows the dense/sparse/RRF/rerank pipeline end-to-end.

## Open questions

- The `BaseVecDB` abstraction looks designed for Qdrant/Milvus/etc. swap-in. Why does only Faiss ship? Roadmap or deliberate?
- The skill-mount design is sandbox-side — does it support hot-reload, or does sandbox restart on `SKILL.md` change?
- The `EULA.md` addendum on top of AGPL-3.0 — what restrictions does it add beyond the license? (Worth a legal review for any commercial deployment.)
- 1000+ community plugins — is there a quality / security review process, or is plugin install effectively `git clone + run`?

---

*Surveyed via the `curating-agentic-kbs` skill. Re-survey scheduled after 30 days of last `pushed_at` change.*

*Audit 2026-05-02: clone-verified against [`pyproject.toml`](https://github.com/AstrBotDevs/AstrBot/blob/main/pyproject.toml) (v4.23.6, AGPL-3.0-or-later), [`astrbot/core/knowledge_base/retrieval/rank_fusion.py`](https://github.com/AstrBotDevs/AstrBot/blob/main/astrbot/core/knowledge_base/retrieval/rank_fusion.py), [`astrbot/core/agent/mcp_client.py`](https://github.com/AstrBotDevs/AstrBot/blob/main/astrbot/core/agent/mcp_client.py). **All major claims verified verbatim:** RRF default `k: int = 60` exact in `__init__`, MCP allowlist `_DEFAULT_STDIO_COMMAND_ALLOWLIST` (`mcp_client.py:27`) with env-var override `ASTRBOT_MCP_STDIO_ALLOWED_COMMANDS`, all 8 IM SDKs as deps (`aiocqhttp`, `dingtalk-stream`, `lark-oapi`, `py-cord`, `python-telegram-bot`, `slack-sdk`, `wechatpy`, plus `telegramify-markdown`), core deps `faiss-cpu>=1.12.0`, `rank-bm25>=0.2.2`, `jieba>=0.42.1`, `mcp>=1.8.0`. Added version `4.23.6` to header. **No corrections needed** — survey quality matches cognee / microsoft-graphrag / deepwiki-open / MemOS / OpenHands / khoj tier.*
