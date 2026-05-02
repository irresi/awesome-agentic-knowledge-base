# plastic-labs/honcho

- **Stars:** 3,149 · **Last push:** 2026-05-01 · **Created:** 2023-09-10 · **License:** AGPL-3.0 · **Lang:** Python (≥3.10) · **Version:** 3.0.6
- **Category:** memory-framework (agent psychology + identity)
- **Author:** [Plastic Labs](https://plasticlabs.ai) (commercial: honcho.dev)
- **Tagline:** "Memory library for building stateful agents" — primary focus is **agent identity + social cognition + just-in-time personalization**.

## TL;DR

A FastAPI + Postgres + pgvector server that models **users and agents as a single "peer" primitive**, then runs two background subsystems on top: a **Deriver** (real-time per-message context update via a minimal LLM prompt) and a **Dreamer** (scheduled "dream cycle" of autonomous specialist agents that perform **deductive then inductive reasoning** over accumulated observations, sampled by **geometric surprisal** from one of 5 tree implementations — covertree / LSH / prototype / RPTree / sklearn). The Dialectic API at `/peers/{peer_id}/chat` injects the resulting peer representation into LLM responses just-in-time. **MCP server is a separate Cloudflare Worker**, not in-tree FastAPI. AGPL-3.0.

## KB Architecture

### Peer paradigm
- **Users and agents are both `Peer`s** — a unified primitive. Sessions can mix N peers (human or AI). Per-peer-per-session `observe_me: bool` + `observe_others: bool` knobs control which peers consume each other's stream into their own representations.
- **Primitive hierarchy**: `Workspace` (root org unit) → `Peer` (any participant) → `Session` (conversation context) → `Message` (data unit). `Collections` and `Documents` are the internal vector storage of peer representations (NOT exposed via API).
- Cohort-first signal: most surveyed memory frameworks scope by `user_id` OR `agent_id` (mem0, letta) but not as the same type. honcho's `observe_me` / `observe_others` matrix means an agent can passively model another agent in the same session.

### Storage
- **Metadata**: Postgres via SQLAlchemy 2.0 + Alembic migrations. Many ORM tables — explicit `session_peers_table` association, JSONB `configuration` + `internal_metadata` per peer-session join, soft `joined_at` / `left_at` timestamps.
- **Vector**: 3 backends in `src/vector_store/`: `lancedb`, `turbopuffer`, **pgvector** (default — same Postgres instance via `pgvector.sqlalchemy.Vector`).
- **Caching**: Redis via `cashews[redis]==7.4.4`.
- **No graph store** — entity relationships emerge inside peer representations, not as a separate graph DB.

### Ingestion
- Single API endpoint shape: `/v1/{resource}/{id}/{action}`. Messages enter via `POST /sessions/{id}/messages` (batch up to 100).
- Each new message enqueues background tasks: `representation` (update observers' peer models) + `summary` (session-level summarization).
- **Session-based queue ordering** — per-session FIFO so consolidation of a single conversation can't reorder.
- **PDF ingestion** via `pdfplumber` (cohort-first to ship PDF in a memory-framework — most memory entries assume pre-cleaned text).

### Deriver — real-time representation update
- [`src/deriver/`](https://github.com/plastic-labs/honcho/tree/main/src/deriver) — `consumer.py`, `deriver.py`, `enqueue.py`, `prompts.py`, `queue_manager.py`.
- `process_representation_tasks_batch(messages, ..., observers, observed)` — the **observer/observed split** lets one batch update N observers' representations of one observed peer in a single LLM call.
- `minimal_deriver_prompt` keeps the per-message overhead small; `estimate_minimal_deriver_prompt_tokens` lets the queue manager budget LLM cost per task.

### Dreamer — scheduled agentic consolidation (cohort-first)
- [`src/dreamer/`](https://github.com/plastic-labs/honcho/tree/main/src/dreamer) is the cohort's first **scheduled "memory consolidation agent"** — runs as a background loop independent of message ingestion, modeled on biological sleep-cycle memory consolidation.
- `dream_scheduler.py` — singleton scheduler; configurable `DreamType` enum.
- `orchestrator.py` runs each dream cycle:
  - **Step 0 (optional)**: surprisal sampling pre-filters observations by **geometric surprisal score** (`SurprisalTree` from `dreamer/trees/`).
  - **Step 1**: **deduction specialist** — autonomous agent searches observation space, creates deductive observations (logical implications, can delete duplicates).
  - **Step 2**: **induction specialist** — autonomous agent looks at BOTH explicit AND deductive observations, creates inductive observations (patterns synthesized).
- Three observation levels (`DocumentLevel` enum): explicit → deductive → inductive — cohort-first cognitive-process taxonomy at *the observation layer* (vs hindsight's at the *memory-tier* layer).
- 5 tree implementations in [`src/dreamer/trees/`](https://github.com/plastic-labs/honcho/tree/main/src/dreamer/trees): `covertree`, `lsh`, `prototype`, `rptree`, `sklearn_wrapper` (+ `base.py`, `graph.py`). Cohort first to ship multiple ANN tree variants for representation indexing.
- [`dreamer/specialists.py`](https://github.com/plastic-labs/honcho/blob/main/src/dreamer/specialists.py): `class DeductionSpecialist` / `class InductionSpecialist` — both `extends ABC` with `Callable` tool sets.

### Dialectic API — just-in-time personalization
- `POST /v1/peers/{peer_id}/chat` — bespoke responses pulling from the peer's representation.
- [`src/dialectic/core.py`](https://github.com/plastic-labs/honcho/blob/main/src/dialectic/core.py) — uses `DIALECTIC_TOOLS` and `DIALECTIC_TOOLS_MINIMAL` from `utils/agent_tools.py`. Tools include `search_memory`, `create_observations`, `create_observations_deductive`, `create_observations_inductive`, `update_peer_card`, `get_peer_card`.
- **Streaming responses** with `StreamingResponseWithMetadata`.
- `format_new_turn_with_timestamp` injects an explicit "turn started at <iso>" formatter so the LLM can reason about elapsed time within a session.

### Peer Cards
- Compact per-peer fact summary, capped at `MAX_PEER_CARD_FACTS = 40` (in [`utils/agent_tools.py:33`](https://github.com/plastic-labs/honcho/blob/main/src/utils/agent_tools.py#L33)) to prevent unbounded growth from repeated agent updates.
- `get_peer_card` is *not* in the dialectic tool list — peer card is **injected directly into the prompt** rather than fetched on-demand. `update_peer_card` is the only peer-card mutation tool.

### LLM + observability
- 3 LLM backends in [`src/llm/backends/`](https://github.com/plastic-labs/honcho/tree/main/src/llm/backends): `anthropic.py`, `gemini.py`, `openai.py`.
- Full LLM wrapper: `tool_loop.py`, `structured_output.py`, `caching.py`, `executor.py`, `request_builder.py`, `history_adapters.py`, `runtime.py`, `registry.py`, `credentials.py` — most decomposed LLM stack in cohort.
- **Observability**: Sentry (`sentry-sdk[anthropic,fastapi,sqlalchemy]`), Langfuse, Prometheus (`prometheus_client`), CloudEvents (`cloudevents>=1.12.0`) — multi-backend telemetry.

### MCP — Cloudflare Worker (cohort-novel)
- The MCP server is **a separate sub-project** at [`mcp/`](https://github.com/plastic-labs/honcho/tree/main/mcp), packaged as a **Cloudflare Worker** (TypeScript / Bun / `wrangler`), NOT bundled into the Python FastAPI server.
- Deps: `@honcho-ai/sdk ^2.1.0`, `@modelcontextprotocol/sdk ^1.26.0`, `agents ^0.4.0`, `nanoid`, `zod`. `@cloudflare/workers-types` + `wrangler ^4.24.3`.
- Distribution model: hosted MCP at the edge — connect to honcho's hosted MCP via Cloudflare DNS, separate from your honcho-server install.
- Cohort first: every other MCP-shipping cohort entry (claude-mem, mem0, basic-memory, byterover-cli, OpenViking, hindsight) bundles MCP in the same process as the API. honcho splits the deployment surface.

### SDKs + CLI + Skills
- **2 SDKs** in `sdks/`: `python` + `typescript`.
- **CLI**: separate `honcho-cli/` package with own `pyproject.toml`.
- **4 Claude Code skills** in `.claude/skills/`: `honcho-cli`, `honcho-integration`, `migrate-honcho-py`, `migrate-honcho-ts` — incl. version-migration helpers (cohort-first to ship migration *skills*).

## Notable design choices

- **Peer paradigm with `observe_me`/`observe_others` matrix** — single primitive for users + agents lets multi-agent sessions naturally model "Agent A models Agent B's behavior". Cohort first.
- **Dreamer = scheduled deduction + induction agents** — the cohort's first explicit *memory-consolidation agent*. Dreams are background processes that grow the agent's understanding without new input. Loosely modeled on biological REM consolidation; replaces "summarize when buffer is full" patterns with "specialists explore the observation space when scheduled".
- **Surprisal-based sampling** — picks anomalous observations to consolidate via geometric distance in tree-indexed embedding space. Cohort first to use Bayesian-surprise primitives for memory-update prioritization.
- **3-level observation taxonomy at the *cognitive-process* axis** (explicit → deductive → inductive) — distinct from hindsight's 3-tier (`World facts` / `Experience facts` / `Mental models` at the *memory-type* axis) and MemOS's 3-tier (KV-cache / LoRA / textual at the *modality* axis). Honcho's split is *what kind of reasoning produced this fact*.
- **MCP as Cloudflare Worker** — first cohort entry to ship MCP at the edge as a separately-deployable artifact, not in the same process as the API. Implication: an org can use Honcho Cloud's MCP without self-hosting the server.
- **5 ANN tree implementations in `dreamer/trees/`** — covertree / LSH / prototype / RPTree / sklearn-wrapper. Most decomposed nearest-neighbor surface in the cohort; the surprisal sampler can switch tree types per dream cycle.
- **Peer card cap (40 facts)** — explicit guard against unbounded representation growth. Cohort-first concrete cap.

## Dependencies

Python 3.10+. Server: `fastapi[standard]`, `sqlalchemy`, `pgvector`, `psycopg[binary]`, `alembic`, `pydantic-settings`, `tenacity`, `tiktoken`, `pyjwt`. Vector: `lancedb`, `turbopuffer`. ML: `scikit-learn`, `pyarrow`. LLM: `openai`, `google-genai` (Anthropic via `sentry-sdk[anthropic]` instrumentation; backend at `src/llm/backends/anthropic.py`). Observability: `langfuse`, `sentry-sdk[anthropic,fastapi,sqlalchemy]`, `prometheus_client`, `cloudevents`. Cache: `cashews[redis]`. PDF: `pdfplumber`. ID: `nanoid`.

## Tradeoffs

- **For**: cohort-first **peer paradigm** (users + agents as one primitive), cohort-first **scheduled memory consolidation agent** (dreamer), cohort-first **surprisal-based sampling** with 5 tree variants, **AGPL-licensed** (honcho.dev cloud is the commercial offering), MCP at the edge as separate deployable, full observability stack (Sentry + Langfuse + Prometheus + CloudEvents), per-peer-per-session observability matrix.
- **Against**: **AGPL-3.0** is restrictive for commercial integrators that don't want copyleft propagation; only **3 LLM backends** (Anthropic / Gemini / OpenAI) — narrower than mem0's 18 or anything-llm's 37; **no graph store**; Dreamer's specialist + surprisal complexity adds operational surface (singleton scheduler, separate consumer queue, sentry instrumentation) — overkill for "give me a thin memory layer" use cases (mem0 is simpler); MCP as Cloudflare Worker means self-hosters need both a Python FastAPI server AND a TS/Bun edge function to get MCP, doubling the deploy surface.

## When to use vs. cohort

- vs. **mem0** — mem0 is "auto-extract facts from messages → vector store with 5 reranker options". honcho is "model peer psychology with deductive + inductive specialists running on a schedule". mem0 for thin SDK; honcho when *agent identity over time* matters more than fact recall.
- vs. **letta** — letta exposes memory blocks (`human` / `persona` / `system`) that the agent itself manages via `core_memory_*` tools. honcho keeps representation-building *external* to the agent (Deriver + Dreamer run on the server). letta when the agent should self-manage; honcho when an external service should model the agent.
- vs. **graphiti** — graphiti is bitemporal-KG-as-a-service (every edge has 4 time fields). honcho has no temporal model at the edge level — time lives in messages and observation timestamps. Pick graphiti for "what did we know on date X"; pick honcho for "who is this peer becoming".
- vs. **hindsight** — both are biomimetic. hindsight types memory at the *cognitive-process* axis with 3 tiers (`World facts` / `Experience facts` / `Mental models`). honcho types *observations* at the cognitive-process axis with 3 levels (`explicit` / `deductive` / `inductive`). hindsight is mental-models-the-agent-builds; honcho is observations-the-server-derives.
- vs. **basic-memory** — basic-memory is markdown-FS observation parser for personal use. honcho is multi-tenant per-peer representation with background consolidation. basic-memory for "my notes"; honcho for "my product's users".

## Code pointers

- Peer paradigm + observe_me/others: [`src/models.py`](https://github.com/plastic-labs/honcho/blob/main/src/models.py) (`session_peers_table`).
- Dialectic core: [`src/dialectic/core.py`](https://github.com/plastic-labs/honcho/blob/main/src/dialectic/core.py).
- Deriver entry: [`src/deriver/deriver.py`](https://github.com/plastic-labs/honcho/blob/main/src/deriver/deriver.py) (`process_representation_tasks_batch`).
- Dream orchestration: [`src/dreamer/orchestrator.py`](https://github.com/plastic-labs/honcho/blob/main/src/dreamer/orchestrator.py).
- Specialists (deduction + induction agents): [`src/dreamer/specialists.py`](https://github.com/plastic-labs/honcho/blob/main/src/dreamer/specialists.py).
- Surprisal sampler: [`src/dreamer/surprisal.py`](https://github.com/plastic-labs/honcho/blob/main/src/dreamer/surprisal.py).
- 5 ANN tree implementations: [`src/dreamer/trees/`](https://github.com/plastic-labs/honcho/tree/main/src/dreamer/trees) (covertree, lsh, prototype, rptree, sklearn_wrapper).
- Agent tools (Dialectic + dreamer specialist tool sets): [`src/utils/agent_tools.py`](https://github.com/plastic-labs/honcho/blob/main/src/utils/agent_tools.py) (`MAX_PEER_CARD_FACTS = 40` at L33).
- LLM backends: [`src/llm/backends/`](https://github.com/plastic-labs/honcho/tree/main/src/llm/backends) (anthropic, gemini, openai).
- Vector store backends: [`src/vector_store/`](https://github.com/plastic-labs/honcho/tree/main/src/vector_store) (pgvector, turbopuffer, lancedb).
- MCP Cloudflare Worker (separate package): [`mcp/`](https://github.com/plastic-labs/honcho/tree/main/mcp) — `@modelcontextprotocol/sdk ^1.26.0` + `wrangler`.
- Claude Code skills: [`.claude/skills/`](https://github.com/plastic-labs/honcho/tree/main/.claude/skills) (4 skills incl. migration helpers).
- Architecture canon: [`CLAUDE.md`](https://github.com/plastic-labs/honcho/blob/main/CLAUDE.md).

## Open questions

- **Dreamer cost** — running deduction + induction specialists on a schedule is LLM-heavy. What's the recommended cadence vs token budget for a typical agent workload?
- **Surprisal threshold tuning** — geometric-surprisal scores depend on tree shape and observation density; is there a documented heuristic for picking when an observation is "anomalous enough" to consolidate?
- **AGPL boundary for SDK consumers** — the Python/TS SDKs in `sdks/` connect to a server. Does AGPL propagate to a closed-source app that uses the SDK to call a self-hosted Honcho server? (The answer matters for commercial integrators who want to ship a binary.)
- **MCP Worker auth** — the Cloudflare Worker takes session/peer IDs; how does it authenticate to the FastAPI server in self-hosted setups vs Honcho Cloud?

---

*Audit 2026-05-02: clone-verified against [plastic-labs/honcho@main](https://github.com/plastic-labs/honcho) (last commit 2026-05-01 19:36). Version 3.0.6 / AGPL-3.0 confirmed in `pyproject.toml` and `LICENSE`. Vector backends (3): pgvector / lancedb / turbopuffer enumerated from `src/vector_store/`. LLM backends (3): anthropic / gemini / openai enumerated from `src/llm/backends/`. 5 ANN tree implementations (covertree / lsh / prototype / rptree / sklearn_wrapper) verified by `ls src/dreamer/trees/`. `MAX_PEER_CARD_FACTS = 40` verified at `src/utils/agent_tools.py:33`. Specialists (`DeductionSpecialist`, `InductionSpecialist`) verified in `dreamer/specialists.py`. 3-level observation taxonomy (explicit / deductive / inductive) verified in specialist prompts and `DocumentLevel` enum (`utils/types.py`). Dreamer scheduler singleton verified at `dream_scheduler.py:21-30`. Surprisal scoring verified in `dreamer/surprisal.py` (`SurprisalTree` import + `np`-backed geometric distance). Peer paradigm with `session_peers_table` + `configuration` JSONB column verified at `src/models.py:42-90`. Observe_me/observe_others knobs verified in `mcp/instructions.md`. MCP as Cloudflare Worker verified in `mcp/package.json` (`@modelcontextprotocol/sdk ^1.26.0` + `wrangler ^4.24.3`). 4 Claude Code skills in `.claude/skills/` verified by `ls`. Dialectic tool sets (`DIALECTIC_TOOLS`, `DIALECTIC_TOOLS_MINIMAL`) verified in `utils/agent_tools.py`. Corrections: none (first-pass survey).*

*Re-audit iter 78 (2026-05-03): re-verified version pin. Architectural state unchanged: v3.0.6 still current, AGPL-3.0 unchanged. ★3,149 → ★3,151 (+2 stars, ~0.06% growth — modest velocity expected for this 3.1k tier). `pushed_at` 2026-05-01 unchanged. No corrections needed. **Cohort cross-link still holds**: scheduled-agent-as-subsystem 2-entry pattern (honcho's Dreamer + DeepTutor's TutorBot — both surfaced in iter 69 + iter 74 Patterns observed bullets) remains the only cohort instances of the pattern.*
