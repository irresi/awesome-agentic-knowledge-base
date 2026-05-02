# Survey: OpenHands/OpenHands

**Date:** 2026-05-01
**Stars:** 72,442 · **Last push:** 2026-05-01 · **Created:** 2024-03-13 (renamed from All-Hands-AI/OpenHands) · **Version:** orchestrator `openhands-ai 1.7.0` (SDK pinned at `1.19.1`) · **License:** MIT (OSS) + separate license for `enterprise/`
**Category:** coding-agent
**Slug:** [OpenHands/OpenHands](https://github.com/OpenHands/OpenHands)

---

## TL;DR (3 lines)

- **What it is:** Open-source autonomous **software-engineer agent** — orchestrator app server + React UI + sandbox runtime. The actual agent loop is delegated to versioned PyPI packages (`openhands-sdk`, `openhands-aci`, `openhands-agent-server`, `openhands-tools`) pinned at v1.19.1.
- **How its KB works:** No vector store in this repo. The KB pattern is **markdown "microagents"** in `.openhands/microagents/*.md` with **YAML frontmatter triggers** (`triggers: [keywords]` or `TaskTrigger`); a **`skill_loader.py`** proxies to the agent-server's `/api/skills` endpoint to compose context per-conversation. Conversation episodes themselves are **SQL event-logs** (Postgres via SQLAlchemy + asyncpg) plus **blob file-store** (local · memory · S3 · GCS).
- **Verdict:** Pick when you want a **production multi-tenant SaaS-style coding agent** with sandboxed runtime (Docker/k8s) and trigger-based context shaping. Skip if you expected a memory framework — the actual SDK + KB primitives live in separate `openhands-sdk` package, not here.

## KB Architecture

### Storage
- **Vector store:** **none** in the main `openhands/` orchestrator. Vector ops, if any, live in `openhands-sdk` (separate PyPI package).
- **Graph store:** none
- **Metadata / structured:** **Postgres** via SQLAlchemy[asyncio] + asyncpg + pg8000; conversation events, settings, secrets, conversation-info tables under `openhands/app_server/{app_conversation,settings,secrets}/`
- **Object / blob (file_store):** **4 backends** in `openhands/app_server/file_store/`: `local.py`, `memory.py`, `s3.py`, `google_cloud.py` — for conversation artifacts and uploaded files
- **Cache / queue:** **Redis** 5.2–7

### Ingestion / Extraction
- **Source types accepted:** **microagent markdown files** (`.openhands/microagents/*.md`) checked into the repo; user-uploaded files via the conversation API; sandboxed shell/browser/jupyter activity captured as events
- **Chunking strategy:** **none** — microagents are loaded whole; conversation events are append-only
- **Entity / fact extraction:** **none** — no LLM extraction in main repo. Microagents are **hand-authored** by the user/team.
- **Schema:** **microagent frontmatter contract:**
  ```yaml
  ---
  name: documentation
  type: knowledge
  version: 1.0.0
  agent: CodeActAgent
  triggers:
    - documentation
    - docs
    - document
  ---
  ```
- **Trigger types:** `KeywordTrigger`, `TaskTrigger` (`openhands.sdk.context.skills`)

### Retrieval
- **Modes:** **trigger-based skill activation** — when a user message contains a keyword in any microagent's `triggers` list, the agent loads that microagent's content into context. No vector retrieval in main repo.
- **Reranker:** none
- **Top-k defaults:** N/A — match-all-triggered semantics
- **Context assembly:** at conversation start, `skill_loader.py` calls agent-server's `/api/skills` to build the org+repo+sandbox-aware skill set

### Memory model
- **Tiers:** episodic (conversation event log in SQL) + skills/microagents (hand-curated markdown) + sandbox file system (ephemeral per conversation)
- **Bi-temporal:** no
- **Self-update mechanism:** **none automatic** — microagents are git-tracked; conversation events accumulate but aren't extracted into long-term memory
- **Decay / forgetting:** events persist; microagents change only when committed
- **Notable:** OpenHands draws an explicit line — *the conversation is replayable*, but cross-conversation memory is the user's job (write a microagent, or use an external mem0-style backend)

### MCP / connectors
- **MCP server exposed:** **yes** — `openhands/app_server/mcp/mcp_router.py`; `mcp>=1.25` + `fastmcp>=3.2`
- **MCP client used:** **yes** — agents call MCP servers as tools
- **Native connectors:** GitHub (`pygithub`), GitLab, Bitbucket via `openhands/app_server/git/`, Google Drive, Slack via integrations dir
- **Sandbox integration:** Docker (per-conversation containers) or Kubernetes (`kubernetes>=33.1`)
- **Tool-call surface:** browsergym (`browsergym-core==0.13.3`) for browser, libtmux for terminal, jupyter-kernel-gateway for code

### Notable design choices
- **Orchestrator + SDK split** — this repo is the *server / UI / glue*; the heavy lifting (agent loop, tools, ACI = Agent-Computer-Interface) lives in pinned PyPI packages (`openhands-sdk==1.19.1`, etc.). This makes upgrades atomic.
- **Microagents as the KB** — the KB pattern is human-curated markdown with `triggers:` + `agent:` frontmatter. The maintainers reject auto-extraction; users write what the agent should know.
- **Trigger-based context shaping** — skills/microagents activate by keyword or task type, not by similarity. Predictable, debuggable, but biased toward hand-curation.
- **SaaS-grade primitives** — multi-tenant `user_auth/`, `secrets/`, `org` config, JWT (`pyjwt` + `jwcrypto`), enterprise/ directory; designed to be hosted as a service.
- **Sandbox is first-class** — every conversation gets a sandbox (Docker or k8s); the agent doesn't run on the host.
- **Telemetry: OpenTelemetry + lmnr (Laminar)** — production observability built in.

## Dependencies (KB-relevant)

From `pyproject.toml` (selected core):

```
fastapi  starlette  python-socketio  fastmcp>=3.2  mcp>=1.25
sqlalchemy[asyncio]>=2.0.40  asyncpg>=0.30  pg8000>=1.31  redis>=5.2,<7
boto3  google-api-python-client  kubernetes>=33.1,<36.0  docker
browsergym-core==0.13.3   libtmux>=0.46   jupyter-kernel-gateway
playwright>=1.55          pypdf  python-docx  python-pptx  python-frontmatter

# The actual agent runtime, pinned to a release:
openhands-sdk==1.19.1
openhands-aci==0.3.3
openhands-agent-server==1.19.1
openhands-tools==1.19.1

# LLM stack
litellm  anthropic[vertex]  openai==2.8  google-genai
```

## Tradeoffs

**Pros:**
- Production architecture — sandbox per conversation, multi-tenant auth, OpenTelemetry, k8s support
- Skills/microagents as markdown is git-friendly and reviewable (vs. opaque vector embeddings)
- Trigger-based loading is debuggable — you know exactly which microagent fired
- Pinned SDK versions decouple upstream changes; main repo can ship fast without SDK churn
- 4 file-store backends (local / memory / s3 / GCS) is real cloud portability

**Cons:**
- No vector retrieval in main repo — if you want semantic KB you need to write a microagent that calls an external memory MCP server (e.g. mem0 / openclaw / basic-memory)
- Microagents are hand-curated — no auto-extraction means humans must keep up with the corpus
- The actual agent loop / KB primitives live in `openhands-sdk` (closed-ish — open repo but not in this clone), so this survey is shallower than ragflow/mem0/etc.
- Heavy stack — Docker + k8s + Postgres + Redis + S3-class blob + React UI + Python backend
- Trigger keyword matching can mis-fire (the `documentation` trigger fires on any message containing "docs")

## When to use it

- **Good fit:** teams self-hosting a coding-agent product; need sandboxed multi-tenant deployment; want hand-controlled context loading via trigger-based skills; can supply their own memory backend if richer recall is needed
- **Bad fit:** "give me a memory layer" use cases — pair with mem0 / openclaw / graphiti instead; small single-user setups (lighter agents like Aider or Claude Code direct work better); offline / air-gapped environments
- **Closest alternative (in this cohort):** none yet directly — Aider, Cline, claude-mem are upcoming surveys. For the *KB pattern alone*, basic-memory's hand-authored markdown is the closest analog; but OpenHands wraps it in trigger-based skill activation.

## Code pointers (evidence)

- Microagents (2 shipped): `.openhands/microagents/documentation.md` + `glossary.md` — both demonstrate the frontmatter trigger contract
- Skill loader: `openhands/app_server/app_conversation/skill_loader.py` — proxies to agent-server `/api/skills`
- File store backends: `openhands/app_server/file_store/{local,memory,s3,google_cloud}.py`
- Conversation service: `openhands/app_server/app_conversation/{app_conversation_service,sql_app_conversation_info_service}.py`
- MCP integration: `openhands/app_server/mcp/mcp_router.py`
- Sandbox: `openhands/app_server/sandbox/`
- Pinned SDK packages: see `pyproject.toml` (`openhands-sdk==1.19.1` etc.) — the actual agent loop lives there
- Most useful single file to read first: `.openhands/microagents/documentation.md` + `skill_loader.py` together — show the KB pattern end-to-end

## Open questions

- The actual vector-search code (if any) lives in `openhands-sdk`. Without surveying that package, can't confirm whether OpenHands does any embedding-based retrieval at all.
- `TaskTrigger` is referenced but the trigger semantics aren't documented in this clone — does it match by task name, by tool used, or both?
- Microagents are loaded on conversation start. Do they reload mid-session if .md files change, or is it session-locked?

---

*Surveyed via the `curating-agentic-kbs` skill. Re-survey scheduled after 30 days of last `pushed_at` change.*

*Audit 2026-05-02: clone-verified against [`pyproject.toml`](https://github.com/OpenHands/OpenHands/blob/main/pyproject.toml) (orchestrator `openhands-ai 1.7.0`), [`LICENSE`](https://github.com/OpenHands/OpenHands/blob/main/LICENSE) (MIT for OSS + separate license for `enterprise/`), [`openhands/app_server/file_store/`](https://github.com/OpenHands/OpenHands/tree/main/openhands/app_server/file_store) (4 backends: local / memory / s3 / google_cloud), [`openhands/app_server/mcp/`](https://github.com/OpenHands/OpenHands/tree/main/openhands/app_server/mcp) (`mcp_router.py`), [`.openhands/microagents/`](https://github.com/OpenHands/OpenHands/tree/main/.openhands/microagents) (2 shipped: `documentation.md` + `glossary.md`). **All major claims verified verbatim:** SDK pins exact (`openhands-sdk==1.19.1`, `openhands-aci==0.3.3`, `openhands-agent-server==1.19.1`, `openhands-tools==1.19.1` — confirms LESSONS L3 "follow the SDK pin" pattern), `browsergym-core==0.13.3`, `mcp>=1.25` + `fastmcp>=3.2,<4`, `kubernetes>=33.1,<36.0` (upper bound was missing from survey), `openai==2.8.0` with documented litellm incompatibility comment. **Minor enhancements:** added orchestrator version `1.7.0` (distinct from SDK pin), MIT/enterprise license split, second shipped microagent (`glossary.md`), kubernetes upper bound. **No corrections needed** — survey quality matches cognee / microsoft-graphrag / deepwiki-open / MemOS tier.*

*Re-audit iter 60 (2026-05-02): re-verified version-pin paths against `main@2026-05-02`. Architectural state unchanged: orchestrator `openhands-ai 1.7.0` still current, SDK pins still `1.19.1` family, MIT/enterprise license split unchanged, MCP router still at `openhands/app_server/mcp/mcp_router.py`. ★72,442 → ★72,497 (+55 stars, ~0.08% growth in 2 days — slowest of the high-traffic re-audited trio: ragflow +0.06%, OpenHands +0.08%, claude-mem +0.47%). No corrections needed — survey is current.*
