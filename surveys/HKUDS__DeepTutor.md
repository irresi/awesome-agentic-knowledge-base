# HKUDS/DeepTutor

- **Stars:** 22,889 · **Last push:** 2026-05-01 · **Created:** 2025-12-28 (5 months old) · **License:** Apache-2.0 · **Lang:** Python (≥3.11) + Next.js 16 · **Version:** `1.0.0` (deeptutor package); release tags v1.3.4 ([2026-05-01](https://github.com/HKUDS/DeepTutor/releases/tag/v1.3.4))
- **Category:** kb-app (Agent-Native Personalized Tutoring; HKUDS lab — same lab as [`HKUDS/LightRAG`](HKUDS__LightRAG.md))
- **Paper:** [arXiv:2604.26962](https://arxiv.org/abs/2604.26962)

## TL;DR

A 2-process system for **agent-native personalized tutoring** from HK Data Science: Python core (`deeptutor/`) + `deeptutor_cli` Typer-based CLI + Next.js 16 web frontend (`web/`). The architectural bet: **a tutoring agent owns its own knowledge base + persistent autonomous instances ("TutorBot") + per-user memory + chat history + skills + sessions** under a unified "Space" abstraction. Capabilities ship as **6 named pipelines** — `chat` / `deep_question` / `deep_research` / `deep_solve` (Plan → ReAct → Write multi-agent) / `math_animator` / `visualize` — each with a typed `CapabilityManifest` + `stages: list[str]` declaration. **Versioned KB indexes with re-index workflow** (per v1.3.0 changelog) is cohort-novel for "embedding-config drift handled as a first-class workflow primitive". **TutorBot subsystem** is a persistent autonomous AI tutor with its own `agent/loop.py` + `memory.py` + `subagent.py` + `team/` + scheduled execution via `cron/service.py` (cohort-second after honcho's Dreamer to ship a scheduled-agent primitive, but DeepTutor's runs are user-facing tutoring tasks rather than memory-consolidation). **14 TutorBot skills** in `tutorbot/skills/` (cron / deep-question / deep-research / deep-solve / github / knowledge-base / memory / notebook / skill-creator / summarize / tmux / weather / clawhub + README). **10 README languages** (en + zh + ja + es + fr + ar + ru + hi + pt + th + pl) — ties [`AsyncFuncAI/deepwiki-open`](AsyncFuncAI__deepwiki-open.md) for cohort top.

## KB Architecture

### Storage
- Persistent storage via **`deeptutor/services/storage/`** module (per-user "Space" hub with chat history / skills / memory unified per v1.3.3 changelog).
- Versioned KB indexes per the `services/rag/index_versioning.py` module — index versions are first-class artifacts that can be re-indexed via documented workflow (cohort first to ship index-version-drift recovery as a workflow).
- `embedding_signature.py` — embedding-config signature stored alongside index data so the system can detect when re-indexing is required (config drift = different signature).
- `file_routing.py` for routing per-file-type to the right ingest pipeline.
- `smart_retriever.py` for retrieval routing logic.
- Configuration via `python-dotenv` + `pydantic-settings` (`.env.example` 4870 lines + `.env.example_CN` separate Chinese-cloud config).

### Ingestion / RAG
- [`deeptutor/services/rag/`](https://github.com/HKUDS/DeepTutor/tree/main/deeptutor/services/rag): `service.py` + `embedding_signature.py` + `factory.py` + `file_routing.py` + `index_versioning.py` + `pipelines/` + `smart_retriever.py`.
- [`deeptutor/knowledge/`](https://github.com/HKUDS/DeepTutor/tree/main/deeptutor/knowledge): `add_documents.py` + `initializer.py` + `manager.py` + `naming.py` + `progress_tracker.py` (cohort-first first-class progress tracker for KB ingest).
- `tools/tex_chunker.py` — dedicated LaTeX chunker (cohort first specialized LaTeX chunking, fits the personalized-learning use case where math/science content is common).
- v1.3.3 (2026-04-30) added NVIDIA NIM + Gemini embedding support; v1.3.0 (2026-04-27) introduced versioned KB indexes with re-index workflow.

### Capabilities (6 named pipelines)
[`deeptutor/capabilities/`](https://github.com/HKUDS/DeepTutor/tree/main/deeptutor/capabilities) — each capability is a class extending `BaseCapability` with a typed `CapabilityManifest`:
1. **`chat`** — interactive chat
2. **`deep_question`** — depth-first question exploration
3. **`deep_research`** — long-horizon research
4. **`deep_solve`** — `MultiAgent`-based problem solving with `stages=["planning", "reasoning", "writing"]` (Plan → ReAct → Write)
5. **`math_animator`** — math content animation (cohort first specialized math-animation capability)
6. **`visualize`** — visualization generation
- `_answer_now.py` is a private helper (underscore prefix).
- `request_contracts.py` defines per-capability request schemas via `get_capability_request_schema()`.
- Typed `CapabilityManifest(name, description, stages: list[str])` exposes the staged execution model — cohort first to type pipeline stages declaratively.

### TutorBot subsystem (persistent autonomous AI tutors)
- [`deeptutor/tutorbot/`](https://github.com/HKUDS/DeepTutor/tree/main/deeptutor/tutorbot): `agent/{context,loop,memory,skills,subagent,team,tools}` + `bus/` + `channels/` + `config/` + `cron/{service,types}.py` + `heartbeat/` + `providers/` + `session/` + `skills/` + `templates/` + `utils/`.
- **`cron/service.py`** runs scheduled tutoring tasks — cohort-second scheduled-agent primitive (after honcho's Dreamer), but for user-facing tutoring rather than memory consolidation.
- **`heartbeat/`** for liveness/health-check signals — cohort first explicit liveness instrumentation for an agent subsystem.
- **`bus/`** + **`channels/`** for inter-component messaging — pub/sub backbone between TutorBot subagents.
- **`team/`** for multi-agent coordination (cohort cross-link to camel-ai/camel pattern, but in-tree).
- 14 TutorBot skills (`tutorbot/skills/{clawhub,cron,deep-question,deep-research,deep-solve,github,knowledge-base,memory,notebook,skill-creator,summarize,tmux,weather}/` + README) — middle of cohort SKILL.md count (vs deer-flow 21, claude-obsidian 11, claude-mem 8).
- **`skill-creator/`** is a meta-skill for *generating new skills at runtime* (cohort second after sim's `.agents/skills/add-block` family of self-modifying skills).
- **`tmux` skill** — cohort-novel terminal-multiplexer skill (suggests TutorBot can spawn long-running tasks in tmux sessions).
- **`weather` skill** — cohort first weather-tool-as-tutoring-context (small-but-novel).

### Agent runtime
- [`deeptutor/runtime/`](https://github.com/HKUDS/DeepTutor/tree/main/deeptutor/runtime): `bootstrap/` + `mode.py` + `orchestrator.py` + `registry/` — pluggable runtime mode + orchestration.
- [`deeptutor/agents/`](https://github.com/HKUDS/DeepTutor/tree/main/deeptutor/agents) — agent definitions consumed by capabilities.
- [`deeptutor/core/`](https://github.com/HKUDS/DeepTutor/tree/main/deeptutor/core): `capability_protocol.py` + `context.py` + `errors.py` + `stream.py` + `stream_bus.py` + `tool_protocol.py` + `trace.py` — clean protocol abstractions (cohort-first explicit `capability_protocol.py` typed contract for capability authors).
- [`deeptutor/core/stream_bus.py`](https://github.com/HKUDS/DeepTutor/blob/main/deeptutor/core/stream_bus.py) — pub/sub backbone for capability streaming (used by `deep_solve` for stage-by-stage event emission).

### LLM provider integration
- [`deeptutor/services/llm/`](https://github.com/HKUDS/DeepTutor/tree/main/deeptutor/services/llm): `client.py` + `cloud_provider.py` + `local_provider.py` + `provider_core/` + `provider_factory.py` + `provider_registry.py` + `providers/` + `routing.py` + `traffic_control.py` + `error_mapping.py` + `executors.py` + `multimodal.py` + `context_window.py`.
- 3 in-tree provider modules in `services/llm/providers/`: `anthropic.py` + `open_ai.py` + `base_provider.py` + `routing.py`.
- **`traffic_control.py`** for rate-limiting / quota management (cohort-novel explicit traffic-control module name).
- **`context_window.py`** for context-budget management at the LLM-call layer.
- **`multimodal.py`** for image/document attachment handling.
- v1.2.3 (2026-04-24) added document attachments (PDF/DOCX/XLSX/PPTX); v1.3.3 added NVIDIA NIM + Gemini embedding adapters.

### Co-Writer subsystem
- [`deeptutor/co_writer/`](https://github.com/HKUDS/DeepTutor/tree/main/deeptutor/co_writer): `edit_agent.py` + `prompts/` + `storage.py` — collaborative writing agent with persistent storage (cohort first specialized co-writing agent, distinct from DeepTutor's chat/research/solve capabilities).

### CLI (`deeptutor_cli/`)
- 14 Typer command modules: `book` / `bot` / `chat` / `common` / `config_cmd` / `kb` / `memory` / `notebook` / `plugin` / `provider_cmd` / `session_cmd` + `main.py` + `__main__.py`.
- Standalone CLI subagent matches the SKILL.md format (separate `SKILL.md` at repo root specifies per-capability CLI invocation).

### SKILL.md as user-facing skill spec
- Top-level `SKILL.md` (5303 chars) describes "Teach your AI agent to configure, manage, and use DeepTutor entirely through the command line" — cohort first to ship a SKILL.md that documents using the *project itself* via CLI (vs cohort SKILL.md patterns of (a) bundled skills as MCP, (b) trigger-fired markdown, (c) progressive-disclosure plugin bundles).
- "When to Use" + "Prerequisites" + "Commands" structure follows Anthropic SKILL.md spec.

### Internationalization
- **10 README languages** in `assets/README/`: en (root) + zh + ja + es + fr + ar + ru + hi + pt + th + pl. **Ties cohort top** with [`AsyncFuncAI/deepwiki-open`](AsyncFuncAI__deepwiki-open.md) (also 10 languages).
- Web frontend has dedicated `web/i18n/` + `web/locales/` directories.

## Notable design choices

- **Versioned KB indexes with re-index workflow** — `services/rag/index_versioning.py` + `services/rag/embedding_signature.py` make embedding-config drift a first-class workflow primitive. Cohort first to ship index-version-drift recovery as a documented workflow (vs cohort entries that silently re-index on config change or require manual re-build).
- **Capability as typed protocol** — `core/capability_protocol.py` + `CapabilityManifest(name, description, stages: list[str])` types the staged execution model declaratively. Cohort first to type pipeline stages at the protocol layer (vs cohort entries that bury stage names in implementation code).
- **TutorBot = persistent autonomous AI tutor** — separate subsystem with `agent/{loop,memory,subagent,team}` + `cron/service.py` + `heartbeat/` + `bus/` + `channels/`. Cohort second to ship a scheduled-agent primitive (after honcho's Dreamer); DeepTutor's runs user-facing tutoring tasks vs honcho's runs memory-consolidation specialists. Together they signal **scheduled-agent-as-subsystem** is a hardening cohort pattern (now 2 entries: honcho-consolidation, DeepTutor-tutoring).
- **`skill-creator` meta-skill** — TutorBot can generate new skills at runtime via `tutorbot/skills/skill-creator/`. Cohort-second meta-skill pattern (after sim's `.agents/skills/add-block` family).
- **`tex_chunker.py`** dedicated LaTeX chunker — cohort first specialized LaTeX chunking, fits the math-heavy personalized-learning use case.
- **`math_animator` capability** — cohort first specialized math-animation pipeline.
- **`co_writer/edit_agent.py`** — cohort first dedicated co-writing edit agent (distinct from chat or RAG agents).
- **`heartbeat/` for agent liveness** — cohort first explicit liveness instrumentation for an agent subsystem.
- **HKUDS lab cross-link** — same lab as [`LightRAG`](HKUDS__LightRAG.md). DeepTutor uses RAG primitives that overlap with LightRAG architecturally; potential future shared-substrate research direction.
- **10 README languages tied with deepwiki-open** for cohort top.

## Dependencies

Python ≥3.11, Next.js 16, Apache-2.0. Core: `openai>=1.30`, `tiktoken`, `aiohttp`, `httpx`, `requests`, `ddgs>=9.9.1` (DuckDuckGo search), `pydantic>=2`, `pydantic-settings>=2`, `aiosqlite>=0.19` (async SQLite for storage), `typer[all]>=0.9` (CLI), `python-dotenv`, `PyYAML`, `jinja2`, `nest_asyncio`, `tenacity`. Embedding adapters per v1.3.3: NVIDIA NIM + Gemini + OpenAI / Anthropic. Web: Next.js 16. Optional cli/server extras (`pip install -e ".[cli]"` / `".[server]"`). Docker support via `Dockerfile` + `docker-compose.dev.yml` + `docker-compose.ghcr.yml`.

## Tradeoffs

- **For**: cohort-first **versioned KB indexes with re-index workflow** + **embedding-signature drift detection**; cohort-first **typed capability protocol** with declarative stage lists; cohort-first **dedicated `tex_chunker`** for LaTeX/math content; cohort-first **`math_animator` capability**; cohort-first **co-writing agent** with persistent storage; cohort-first **heartbeat instrumentation** for agent liveness; cohort-second **scheduled-agent subsystem** (TutorBot's `cron/service.py`); cohort-second **meta-skill** (`skill-creator`); 10 README languages (cohort tie); active dev (8 releases v1.2.1 → v1.3.4 in 11 days = high velocity); HKUDS lab cross-link to LightRAG; Apache-2.0; Docker-shipped; multilingual.
- **Against**: very young project (5 months old, ★22k in 5 months suggests rapid traction but unproven longevity); pre-1.0 churn risk despite the `version = "1.0.0"` declaration in pyproject.toml — release-tag versioning is at v1.3.4 (mismatched); Tutoring-domain focus narrows applicability vs general kb-app entries (anything-llm, sim, FastGPT, MaxKB); only **3 in-tree LLM providers** (anthropic / openai / base_provider) — narrower than llama_index's 104 / anything-llm's 37 / sim's 17; no MCP server (per directory inspection — TutorBot has skills but no `mcp/` server module); **`v1.3.0`'s "rebuilt Knowledge workspace"** + frequent v1.2.x → v1.3.x churn signals architecture is still settling; web frontend ships separately from CLI/Python-core (3-process distribution: Python core + CLI + Next.js web).

## When to use vs. cohort

- vs. **HKUDS/LightRAG** ([survey](HKUDS__LightRAG.md)) — same lab. LightRAG is the *RAG-substrate* (4 storage abstractions × 13 backend impls + 6 retrieval modes). DeepTutor is the *tutoring application* using RAG-like primitives. Likely future architectural alignment as the lab consolidates substrate. Use LightRAG when you want the RAG framework; DeepTutor when you want a deployable tutoring agent.
- vs. **anything-llm / sim / FastGPT / MaxKB** (kb-app camp) — these are general workspace kb-apps. DeepTutor is **domain-specialized for personalized learning** (math animation + LaTeX chunking + co-writer + tutoring-skill catalog). Pick DeepTutor when the workload is education/tutoring; pick the general kb-apps for broader use.
- vs. **honcho** ([survey](plastic-labs/honcho.md)) — both ship scheduled-agent subsystems. honcho's Dreamer runs memory-consolidation specialists; DeepTutor's TutorBot runs user-facing tutoring tasks. honcho is "agent identity service"; DeepTutor is "tutoring agent runtime". Together they signal scheduled-agent-as-subsystem as a hardening cohort pattern.

## Code pointers

- Capability protocol: [`deeptutor/core/capability_protocol.py`](https://github.com/HKUDS/DeepTutor/blob/main/deeptutor/core/capability_protocol.py) (`BaseCapability`, `CapabilityManifest`).
- 6 named capabilities: [`deeptutor/capabilities/`](https://github.com/HKUDS/DeepTutor/tree/main/deeptutor/capabilities) (chat / deep_question / deep_research / deep_solve / math_animator / visualize).
- Versioned KB indexes: [`deeptutor/services/rag/index_versioning.py`](https://github.com/HKUDS/DeepTutor/blob/main/deeptutor/services/rag/index_versioning.py) + [`embedding_signature.py`](https://github.com/HKUDS/DeepTutor/blob/main/deeptutor/services/rag/embedding_signature.py).
- LaTeX chunker: [`deeptutor/tools/tex_chunker.py`](https://github.com/HKUDS/DeepTutor/blob/main/deeptutor/tools/tex_chunker.py).
- TutorBot agent: [`deeptutor/tutorbot/agent/`](https://github.com/HKUDS/DeepTutor/tree/main/deeptutor/tutorbot/agent) (`loop` + `memory` + `subagent` + `team`).
- TutorBot scheduled execution: [`deeptutor/tutorbot/cron/service.py`](https://github.com/HKUDS/DeepTutor/blob/main/deeptutor/tutorbot/cron/service.py).
- TutorBot heartbeat: [`deeptutor/tutorbot/heartbeat/`](https://github.com/HKUDS/DeepTutor/tree/main/deeptutor/tutorbot/heartbeat).
- 14 TutorBot skills: [`deeptutor/tutorbot/skills/`](https://github.com/HKUDS/DeepTutor/tree/main/deeptutor/tutorbot/skills).
- Co-Writer: [`deeptutor/co_writer/edit_agent.py`](https://github.com/HKUDS/DeepTutor/blob/main/deeptutor/co_writer/edit_agent.py).
- LLM router + traffic control: [`deeptutor/services/llm/{routing,traffic_control,context_window,multimodal}.py`](https://github.com/HKUDS/DeepTutor/tree/main/deeptutor/services/llm).
- CLI: [`deeptutor_cli/`](https://github.com/HKUDS/DeepTutor/tree/main/deeptutor_cli) (14 Typer command modules).
- Top-level SKILL.md: [`SKILL.md`](https://github.com/HKUDS/DeepTutor/blob/main/SKILL.md) (5303 chars; "Teach your AI agent to configure, manage, and use DeepTutor entirely through the command line").
- Web frontend: [`web/`](https://github.com/HKUDS/DeepTutor/tree/main/web) (Next.js 16 + i18n + locales).

## Open questions

- **Version mismatch** — `pyproject.toml` says `version = "1.0.0"` but release tags are at v1.3.4 (with rapid 1.2.x → 1.3.x churn in last 14 days). Which is canonical for downstream consumers?
- **No MCP server** — DeepTutor exposes SKILL.md (CLI-driven) but no MCP server. Is this intentional given the TutorBot's pub/sub bus architecture, or planned for future versions?
- **HKUDS lab consolidation** — DeepTutor and LightRAG (same lab) currently have parallel RAG substrates. Is there a stated plan to consolidate on LightRAG's substrate?
- **Math animator capability** — what's the underlying renderer? Manim? Custom?
- **TutorBot heartbeat semantics** — what triggers a TutorBot to be considered unhealthy, and what's the recovery action?
- **`tutorbot/skills/clawhub`** — what is "clawhub"? Likely OpenClaw / ClawCode (cohort cross-reference to MemOS's OpenClaw integration), but worth confirming.

---

*Audit 2026-05-02: clone-verified against [HKUDS/DeepTutor@main](https://github.com/HKUDS/DeepTutor) (last commit 2026-05-01 12:17). Apache-2.0 confirmed in `LICENSE`. `pyproject.toml` version `1.0.0` vs release tag v1.3.4 — flagged in Open questions. Counts verified by directory enumeration: 6 capabilities (`ls deeptutor/capabilities/` minus `__init__.py`, `_answer_now.py`, `request_contracts.py`), 14 TutorBot skills (`ls deeptutor/tutorbot/skills/` minus README.md), 14 Typer command modules in `deeptutor_cli/` minus `README.md`/`__init__.py`/`__main__.py`, 3 LLM providers in `deeptutor/services/llm/providers/` (anthropic + openai + base_provider). `BaseCapability` + `CapabilityManifest` + `stages` verified verbatim from `capabilities/deep_solve.py:30-32`. Versioned KB index module + embedding signature verified by `ls deeptutor/services/rag/`. `tex_chunker.py` verified at `deeptutor/tools/tex_chunker.py`. TutorBot subsystem (`agent/{loop,memory,subagent,team}`, `cron/service.py`, `heartbeat/`, `bus/`, `channels/`) verified by `ls deeptutor/tutorbot/`. Co-Writer (`edit_agent.py` + `prompts/` + `storage.py`) verified by `ls deeptutor/co_writer/`. 10 README languages verified by `ls assets/README/` (en root + 10 sibling). Top-level SKILL.md verified at repo root (5303 chars). Web frontend Next.js 16 verified at `web/`. v1.3.4 release date 2026-05-01 verified per README "Releases" section. Corrections: none (first-pass survey).*
