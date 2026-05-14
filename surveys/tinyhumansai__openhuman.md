# Survey: tinyhumansai/openhuman

**Date:** 2026-05-15
**Stars:** 7,406 · **Last push:** 2026-05-14 · **Created:** 2026-02-18 (~3 months old)
**Category:** kb-app
**Slug:** [tinyhumansai/openhuman](https://github.com/tinyhumansai/openhuman)
**License:** **GPL-3.0** (cohort second after [1Panel-dev/MaxKB](1Panel-dev__MaxKB.md))
**Lang:** Rust core (`openhuman 0.53.46`) + TypeScript/React app (Tauri 2.10.1) + Remotion (mascot renderer) · pnpm 10.10.0 workspace
**Versions:** Rust crate `openhuman 0.53.46`, app `openhuman-app` via Tauri, builds 3 binaries (`openhuman-core` / `slack-backfill` / `gmail-backfill-3d`)

---

## TL;DR (3 lines)

- **What it is:** Open-source desktop **agentic assistant** ("Personal AI super intelligence") — Tauri desktop shell + 80MB Rust core + React UI; the agent has a visible **desktop mascot** that joins Google Meets as a participant, auto-fetches your accounts every 20 min, and compresses everything into a local Obsidian-readable vault. Built as a single-vendor alternative to Claude Cowork / OpenClaw / Hermes; positioned as "context in minutes, not weeks" via Karpathy's LLM-knowledge-base pattern.
- **How its KB works:** A **dual memory stack** mid-migration — legacy `UnifiedMemory` (SQLite + FTS5 + vector_chunks blobs + graph triples + episodic + 5-signal hybrid scoring) coexists with the new **Memory-Tree** 4-phase pipeline: Phase 1 deterministic ≤3k-token Markdown chunks (sha256-based IDs, immutable bodies in an Obsidian-compatible vault with auto-seeded `.obsidian/graph.json` + `types.json`), Phase 2 scored/extracted entities into a `mem_tree_entity_index`, Phase 3 **bucket-seal** cascade across **3 tree kinds** (source / topic / global) with L0=`INPUT_TOKEN_BUDGET=50_000` and L1+=`SUMMARY_FANOUT=10`, Phase 4 **6 retrieval primitives** exposed to the LLM with no orchestrator (`query_source / query_global / query_topic / search_entities / drill_down / fetch_leaves`).
- **Verdict:** Pick when you want a **desktop-first** all-batteries Personal AI (mascot, voice, Meet-joiner, Composio-backed 1000+ OAuth toolkits, TokenJuice tool-output compactor) and you accept GPL-3.0 + a hard dependency on the OpenHuman SaaS backend (cloud Voyage embeddings + LLM via OpenAI-compatible proxy + Composio billing). Skip if you need a self-hosted server (this is a Tauri desktop app), permissive licensing, or vendor independence — the core *can* run on local Ollama but the default and most-paths-default is the OpenHuman backend.

## KB Architecture

### Storage

- **Vector store:** SQLite `vector_chunks` table with `embedding BLOB` (legacy `UnifiedMemory` at [`src/openhuman/memory/store/unified/init.rs:101-115`](https://github.com/tinyhumansai/openhuman/blob/main/src/openhuman/memory/store/unified/init.rs#L101-L115)). Memory-Tree path stores summary embeddings separately ([`tree_source/store.rs::get_summary_embedding`](https://github.com/tinyhumansai/openhuman/blob/main/src/openhuman/memory/tree/tree_source/store.rs)). No external vector DB; embeddings live next to rows.
- **Graph store:** SQLite `graph_global` + `graph_namespace` triple tables ((subject, predicate, object, attrs_json)). No Neo4j / Kuzu / FalkorDB — graph is just **SQL triples** ([`init.rs:80-99`](https://github.com/tinyhumansai/openhuman/blob/main/src/openhuman/memory/store/unified/init.rs#L80-L99)). Cohort-novel: graph-as-SQL-triples shipping in the same SQLite file as docs + vectors + FTS5 + segments + events + profile.
- **Metadata / structured:** SQLite (`rusqlite 0.37` with `bundled` feature — no system libsqlite3 required). WAL mode + `PRAGMA synchronous = NORMAL`. **15-second `SQLITE_BUSY_TIMEOUT`** ([`tree/store.rs:36`](https://github.com/tinyhumansai/openhuman/blob/main/src/openhuman/memory/tree/store.rs#L36)) — explicit comment about Windows-host contention from 4 job workers + scheduler + ingest writing the same `chunks.db`.
- **Object / blob:** On-disk Markdown sidecar files. Memory-Tree content store writes one `.md` per chunk under `<content_root>/{chat|email|document}/<source_slug>/<id>.md`, **except email chunks** which skip the disk write (they live once in `<content_root>/raw/<source>/<ts>_<id>.md`). SHA-256 stored in SQLite over body bytes only; front-matter `tags:` is rewritable without invalidating the hash.

### Ingestion / Extraction

- **Source types accepted:** Three canonical [`SourceKind`](https://github.com/tinyhumansai/openhuman/blob/main/src/openhuman/memory/tree/types.rs)s — Chat / Email / Document. Concrete `DataSource` enum maps 8 providers: Discord / Telegram / Whatsapp → Chat; Gmail / OtherEmail → Email; Notion / MeetingNotes / DriveDocs → Document. Marked `#[non_exhaustive]` for additive expansion.
- **Chunking strategy:** **Source-kind-dispatched** ([`tree/chunker.rs:1-25`](https://github.com/tinyhumansai/openhuman/blob/main/src/openhuman/memory/tree/chunker.rs)). Chat splits at `## ` message boundaries; Email at `---\nFrom:` separators; Document is paragraph-greedy. Oversize units fall back to paragraph/line/char splitter with `partial_message = true` tag. `DEFAULT_CHUNK_MAX_TOKENS = 3_000` (well under the 50k seal budget so each L0 fold sees ~15+ chunks). Cohort-novel: **per-source-kind splitter dispatch** rather than a single generic chunker.
- **Entity / fact extraction:** LLM-based via the `EntityExtractor` trait in [`tree/score/extract/`](https://github.com/tinyhumansai/openhuman/blob/main/src/openhuman/memory/tree/score/) with canonicalisation in [`score/resolver.rs`](https://github.com/tinyhumansai/openhuman/blob/main/src/openhuman/memory/tree/score/resolver.rs). Runs on chunks via the background `IngestionQueue` ([`memory/ingestion/queue.rs`](https://github.com/tinyhumansai/openhuman/blob/main/src/openhuman/memory/ingestion/queue.rs)) so `doc_put` callers never block. Default extraction model: `DEFAULT_MEMORY_EXTRACTION_MODEL`. Provider-routed via `hint:` virtual model names.
- **Schema:** **Atomic-fact + chunk hybrid**. Chunks have deterministic IDs `sha256(source_kind | "\0" | source_id | "\0" | seq)` truncated to 32 hex chars ([`tree/types.rs:10-12`](https://github.com/tinyhumansai/openhuman/blob/main/src/openhuman/memory/tree/types.rs)) — idempotent re-ingest. Each summary node tracks `entities` (canonical IDs) + `topics` (labels) populated by **3-strategy [`LabelStrategy`](https://github.com/tinyhumansai/openhuman/blob/main/src/openhuman/memory/tree/tree_source/bucket_seal.rs)**: `ExtractFromContent(extractor)` for Source trees (catches emergent themes), `UnionFromChildren` for Global trees (no LLM call), `Empty` for Topic trees (their scope already pins the theme).

### Retrieval

- **Modes:** **Six LLM-callable primitives** exposed without an orchestrator ([`tree/retrieval/mod.rs:1-18`](https://github.com/tinyhumansai/openhuman/blob/main/src/openhuman/memory/tree/retrieval/mod.rs)): `query_source` / `query_global` / `query_topic` / `search_entities` (LIKE over `mem_tree_entity_index`) / `drill_down` (BFS walk of `child_ids` with optional semantic rerank) / `fetch_leaves` (batch raw-chunk hydration, cap 20). Explicit design note: *"orchestration (which tool to call, how to combine) is left to the calling LLM"*. Cohort-novel: most cohort entries ship a single `retrieve(query)` or `recall(query)` entry — OpenHuman expects the LLM to compose the 6 primitives itself. The legacy `UnifiedMemory.query()` path uses a **5-signal hybrid score** (graph + vector + keyword + episodic + freshness — see [`unified/query.rs`](https://github.com/tinyhumansai/openhuman/blob/main/src/openhuman/memory/store/unified/query.rs)).
- **Reranker:** Optional inside `drill_down` (semantic rerank when LLM-callable); not a global reranker. Embeddings drive the rerank.
- **Top-k defaults:** `search_entities` `DEFAULT_LIMIT = 5` (`MAX_LIMIT = 100`); `fetch_leaves` cap 20; `DefaultMemoryLoader` for prior-conversation injection: `limit=5`, `min_relevance_score=0.4`, `max_context_chars=2000`, `PRIOR_CONVERSATION_LIMIT=3` ([`agent/memory_loader.rs:11`](https://github.com/tinyhumansai/openhuman/blob/main/src/openhuman/agent/memory_loader.rs#L11)).
- **Context assembly:** **Prior-conversation prefix** at chat start — only entries keyed `high.*` survive into the system prompt; medium/low remain query-only ([`agent/memory_loader.rs:14`](https://github.com/tinyhumansai/openhuman/blob/main/src/openhuman/agent/memory_loader.rs#L14)). Cohort-novel: **importance-prefixed dynamic memory** (`high.`/`medium.`/`low.` keys, only `high.` auto-injected). Memory citations attached to responses for UI provenance display.

### Memory model

- **Tiers:** **5+ coexisting tiers in two stacks.** Legacy `UnifiedMemory` has `MemoryCategory { Core, Daily, Conversation, Custom(_) }` ([`memory/traits.rs:30-44`](https://github.com/tinyhumansai/openhuman/blob/main/src/openhuman/memory/traits.rs#L30-L44)). Memory-Tree adds a **bucket-seal cascade**: L0 buffer → L1 summary on `token_sum >= INPUT_TOKEN_BUDGET=50_000` → L2+ on `item_ids.len() >= SUMMARY_FANOUT=10` ([`tree_source/types.rs`](https://github.com/tinyhumansai/openhuman/blob/main/src/openhuman/memory/tree/tree_source/types.rs)). Plus a **separate** `tree_summarizer` module that builds a time-based root→year→month→day→hour tree as a parallel KB layer ([`tree_summarizer/mod.rs`](https://github.com/tinyhumansai/openhuman/blob/main/src/openhuman/tree_summarizer/mod.rs)). Plus `conversations/` (JSONL append-only thread+message), plus `tool_memory/` (RAG-style tool-output capture rules with `TOOL_MEMORY_PROMPT_CAP`), plus `subconscious/` (SQLite-backed task evaluator + reflection store).
- **Bi-temporal:** **No.** Chunks carry `timestamp_ms` + `time_range_start_ms` + `time_range_end_ms` ([`store.rs:54-56`](https://github.com/tinyhumansai/openhuman/blob/main/src/openhuman/memory/tree/store.rs)) — `time_range` is a single observation interval, not the dual valid-time / transaction-time of Graphiti/Letta.
- **Self-update mechanism:** **Auto-extract via 1200s (20-min) periodic sync** ([`composio/periodic.rs:46-50`](https://github.com/tinyhumansai/openhuman/blob/main/src/openhuman/composio/periodic.rs)) — the global tick walks every active Composio connection, dispatches to the registered native provider's `sync(ctx, SyncReason::Periodic)`, and feeds canonicalised chunks into the Memory-Tree ingest pipeline. Per-connection state in a process-global `Arc<Mutex<HashMap<(toolkit, connection_id), Instant>>>`, rebuilt on restart.
- **Decay / forgetting:** Lifecycle states (`pending_extraction / admitted / buffered / sealed / dropped` — [`tree/store.rs:38-48`](https://github.com/tinyhumansai/openhuman/blob/main/src/openhuman/memory/tree/store.rs#L38-L48)). Admission gate rejects low-signal chunks before they enter L0. No TTL; sealed summaries are kept indefinitely.

### MCP / connectors

- **MCP server exposed:** No native MCP server in the core. JSON-RPC surface only (`openhuman.memory_tree_*` / `openhuman.composio_*` / `openhuman.meet_agent_*` / `openhuman.memory_*` etc. — schema-registered controllers via the `schemars 1.2` registry).
- **MCP client used:** App layer has [`app/src/lib/mcp/`](https://github.com/tinyhumansai/openhuman/tree/main/app/src) (TS frontend); the Rust core does not maintain an MCP client. Skills are *legacy* metadata-only after the QuickJS runtime was removed ([`skills/mod.rs:1`](https://github.com/tinyhumansai/openhuman/blob/main/src/openhuman/skills/mod.rs#L1) — *"Legacy skill metadata helpers retained after QuickJS runtime removal."*).
- **Native connectors:** Architecturally split in two — **18 native chat-channel providers** in [`channels/providers/`](https://github.com/tinyhumansai/openhuman/tree/main/src/openhuman/channels/providers) (Slack, Discord, Telegram, WhatsApp, Matrix, Signal, iMessage, QQ, DingTalk, Lark, Mattermost, IRC, email_channel, Linq, Presentation, Web, WhatsApp-Web, …) — **cohort-leading channel breadth**, more than AstrBot's 8 IM SDKs — plus **4 in-tree native Composio providers** (`gmail/`, `github/`, `notion/`, `slack/`) at [`composio/providers/`](https://github.com/tinyhumansai/openhuman/tree/main/src/openhuman/composio/providers) and **23 catalogued Composio toolkits** across 5 category files (`messaging` + `google` + `productivity` + `social_media` + `business`). The "1000+ Composio toolkits" comes via the backend proxy, **not** in-tree — see [`composio/mod.rs:1-12`](https://github.com/tinyhumansai/openhuman/blob/main/src/openhuman/composio/mod.rs#L1-L12): *"the core does not hit the Composio API directly — everything goes through the backend"*.
- **Tool-call surface:** 14 specialised in-tree agents at [`agent/agents/`](https://github.com/tinyhumansai/openhuman/tree/main/src/openhuman/agent/agents) (archivist / code_executor / critic / help / integrations_agent / morning_briefing / orchestrator / planner / researcher / summarizer / tool_maker / tools_agent / trigger_reactor / trigger_triage / welcome). Tools at [`tools/impl/`](https://github.com/tinyhumansai/openhuman/tree/main/src/openhuman/tools/impl): agent / browser / computer / cron / filesystem / memory / network / system / whatsapp_data — 9 tool families. Dispatcher supports XML / JSON / **P-Format** strategies ([`agent/dispatcher.rs`](https://github.com/tinyhumansai/openhuman/blob/main/src/openhuman/agent/dispatcher.rs)) — cohort-novel **P-Format** tool-call serialisation.

### Notable design choices

- **TokenJuice** ([`src/openhuman/tokenjuice/`](https://github.com/tinyhumansai/openhuman/tree/main/src/openhuman/tokenjuice)) — Rust port of [vincentkoc/tokenjuice](https://github.com/vincentkoc/tokenjuice) (a TypeScript lib) for terminal-output compaction *before* it reaches the LLM context. **3-layer rule overlay**: builtin (`include_str!` of vendored JSONs) → user (`~/.config/tokenjuice/rules/`) → project (`.tokenjuice/rules/` relative to cwd), higher layer wins on duplicate `id`. 60+ vendored rules across `archive/build/cloud/database/...` categories. `TINY_OUTPUT_MAX_CHARS = 240` — small outputs pass through unmodified. Caveat: this is **tool-output**-shaped, not the "every email body and search payload" the README implies — HTML→Markdown / URL-shortening lives elsewhere (e.g. the [`fast_html_to_text`](https://github.com/tinyhumansai/openhuman/blob/main/src/openhuman/providers/) post-processor in `providers/gmail/post_process.rs`, swapped in after `html2md` was found allocating ~894 MB heap on 10 KB inputs).
- **Cohort-first MeetAgent** — `src/openhuman/meet_agent/` ([README](https://github.com/tinyhumansai/openhuman/blob/main/src/openhuman/meet_agent/mod.rs)) is a long-lived per-session VAD/STT/LLM/TTS pipeline. Tauri shell pumps PCM frames into the core via `meet_agent_push_listen_pcm`; the core decides whether to reply (turn orchestration) and emits synthesized PCM back through `meet_agent_poll_speech` for the shell's virtual-mic. Splits cleanly from the validation-only `meet/` domain. No cohort entry has this.
- **Subconscious engine** — `src/openhuman/subconscious/` evaluates due tasks on a tick, executes "act" tasks via the local model, creates escalations for ambiguous ones, and persists reflections (`Reflection { Deduction, Induction, ... }`, capped `MAX_REFLECTIONS_PER_TICK`). SQLite-backed task store with generation-counter overlap guard so a slow tick can't overwrite a fast tick. Cohort cross-link: closest analogue is [`plastic-labs/honcho`](plastic-labs__honcho.md)'s **Dreamer** (deduction+induction specialists), but Honcho consolidates conversation; OpenHuman's Subconscious is **task-driven** (due tasks → act/escalate) — different shape.
- **Cohort-novel desktop mascot** — `app/src/mascot/` + `remotion/` (Remotion render pipeline → runtime PNG/Lottie assets). The "agent has a face" — speaks (TTS lip-sync via Whisper-rs decode of TTS-produced audio), reacts to mouse, joins Meets visibly. No cohort entry ships a visual avatar.
- **3-tree topology with strategy split** — Source/Topic/Global summary trees all reuse the same SQLite tables (`mem_tree_trees / mem_tree_summaries / mem_tree_buffers`) and same `bucket_seal::append_leaf` cascade, but differ only in `LabelStrategy` and registry/routing logic. Topic trees are entity-scoped (one per top-N entity, `hotness.rs` decides which entities are promoted to a tree); Global trees union-merge labels from already-labeled source summaries (no LLM call). Cohort-novel: **three independent summary trees in one store** with strategy polymorphism.
- **Routing-by-hint** — virtual model names `reasoning-v1 / agentic-v1 / coding-v1 / summarization-v1` route to provider+model pairs via [`providers/router.rs`](https://github.com/tinyhumansai/openhuman/blob/main/src/openhuman/providers/router.rs) (`RouterProvider`). Cohort-overlap: simstudioai ships 17 LLM providers, anything-llm 37; OpenHuman ships routing-as-virtual-model-name primitive distinct from a provider menu.
- **Cargo `[patch.crates-io]` of `whisper-rs-sys`** — single dependency override forking `whisper-rs-sys` to fix `LNK2038` on Windows MSVC (CRT mismatch — upstream `cmake` builds /MD, Rust uses /MT). Patched to `static_crt(true)`. Engineering rigour: one-line patch, fork at [`tinyhumansai/whisper-rs-sys`](https://github.com/tinyhumansai/whisper-rs-sys.git).
- **Cohort-second on scheduled-agent** — DeepTutor (iter 68) was cohort-first; OpenHuman's Composio `periodic.rs` + Subconscious `engine.rs` + `cron 0.12` dep adds a second instance. Distinct from DeepTutor: scheduled work is split across three subsystems (account sync / task evaluation / generic cron) rather than one TutorBot supervisor.
- **Cohort-first 18-channel chat-provider breadth** — beats AstrBot's 8 IM SDKs. Includes regional-Chinese providers (Linq, QQ, DingTalk, Lark, WhatsApp-Web) — second cohort entry with Chinese-ecosystem connectors (after AstrBot/Yuxi).

## Dependencies (KB-relevant)

From [`Cargo.toml`](https://github.com/tinyhumansai/openhuman/blob/main/Cargo.toml) (Rust core, `openhuman 0.53.46`):

```toml
# Storage / serialization
rusqlite = { version = "0.37", features = ["bundled"] }   # bundled libsqlite3 — no system dep
postgres = { version = "0.19", features = ["with-chrono-0_4"] }  # ?? — only used by bins, not core path
schemars = "1.2"                          # JSON-Schema for the RPC controller registry
serde = { version = "1", features = ["derive"] }
serde_json = "1" ; serde_yaml = "0.9"

# Memory crypto + integrity
aes-gcm = "0.10" ; argon2 = "0.5" ; chacha20poly1305 = "0.10" ; sha2 = "0.10" ; hmac = "0.12"

# Networking (cloud LLM + embeddings + integrations)
reqwest = { version = "0.12", default-features = false, features = ["json","blocking","rustls-tls","native-tls","stream","http2","multipart","socks"] }
axum = { version = "0.8", default-features = false, features = ["http1","json","tokio","query","ws","macros"] }
socketioxide = { version = "0.15", features = ["extensions"] }   # Composio trigger fan-out
tokio = { version = "1", features = ["full","sync"] }
async-imap = { version = "0.11", features = ["runtime-tokio"], default-features = false }
lettre = { version = "0.11.19", default-features = false, features = ["builder","smtp-transport","rustls-tls"] }

# Voice + audio
whisper-rs = "0.16"                       # STT (forked whisper-rs-sys via [patch.crates-io])
cpal = "0.15" ; hound = "3.5"             # audio I/O
enigo = "0.3" ; rdev = "0.5" ; arboard = "3"  # input + clipboard for the autocomplete features

# Optional feature flags
matrix-sdk = { version = "0.16", optional = true, features = ["e2e-encryption","rustls-tls","markdown"] }  # channel-matrix
whatsapp-rust = { version = "0.5", optional = true, features = ["sqlite-storage","tokio-runtime"] }       # whatsapp-web
pdf-extract = { version = "0.10", optional = true }                                                      # rag-pdf
```

Frontend (`app/package.json`, omitted for brevity): React + Tauri 2.10.1 + assistant-ui surface; `pnpm-workspace.yaml` lists 4 packages.

## Tradeoffs

**Pros:**
- **Local-first KB output as Obsidian vault** — chunks land as `.md` files in a vault you can open and edit; `.obsidian/graph.json` + `types.json` auto-seeded so colour-by-summary-level + `date`/`datetime` typed front-matter work without manual config. SHA-256-over-body integrity check on every read.
- **Idempotent re-ingest** — deterministic sha256 chunk IDs + UNIQUE upsert semantics make re-ingestion a no-op rather than a duplicate-creating mess. Solves a class of bugs that bit other cohort entries (visible in cline / aider / SurfSense incident notes).
- **Bucket-seal cascade with level-aware gates** — token-budget gate at L0 (50k input → summariser) prevents the summariser's input ceiling from being exceeded; fanout-count gate at L1+ keeps tree fan-in stable independent of summariser-output token variance.
- **Strategy-polymorphic label resolution** — Source/Global/Topic trees share a single seal pipeline but differ via `LabelStrategy` enum (`ExtractFromContent` / `UnionFromChildren` / `Empty`). Cleanly avoids cross-pollination of entity labels into topic trees.
- **20-min auto-fetch tick** — chosen to balance "tomorrow's context this morning" against the foreground-load + battery cost of more frequent ticks (explicit comment cites that the laptop "was visibly busy" at the old 60s cadence).
- **6-primitive retrieval surface with no orchestrator** — pushes orchestration to the LLM, removes a class of "the retrieval composer disagrees with the LLM" bugs. Each primitive returns the same `RetrievalHit / NodeKind` shape so prompts can do dispatch directly.
- **TokenJuice rule library** — verifiable mechanism for the README's "80% reduction" claim, with 3-layer overlay so users / projects can extend without forking. The "60+ vendored rule files for terminal-output shapes" is meaningfully different from generic chunking.
- **Production-grade engineering signals** — `[patch.crates-io]` for one specific Windows linker issue; explicit comment on the `html2md` 894 MB heap-allocation incident with the linear-time replacement; `SQLITE_BUSY_TIMEOUT = 15s` with rationale ("Windows-host contention from 4 job workers + scheduler + ingest"); generation-counter overlap guard in the Subconscious engine.
- **Cohort-first MeetAgent + desktop mascot** — fills slots no other cohort entry occupies.

**Cons:**
- **Hard-coupled to OpenHuman SaaS backend** — `cloud` embedding provider (Voyage 1024d via backend) is the default and the only one not requiring opt-in; `OpenHumanBackendProvider` resolves a session JWT lazily on each call; Composio path is "backend owns API key, billing/margin, toolkit allowlist, HMAC webhook verification". Local Ollama works but is **second-class** — the offline story is "set `memory.embedding_provider = "ollama"` and `local_ai.usage.embeddings = true`" rather than a turn-key flag.
- **Dual memory stacks mid-migration** — legacy `UnifiedMemory` (5-signal hybrid scoring) and new Memory-Tree (bucket-seal cascade) coexist. Module doc explicitly says *"they coexist until the legacy remote-client layer is replaced in a future phase"* ([`memory/tree/mod.rs:5-8`](https://github.com/tinyhumansai/openhuman/blob/main/src/openhuman/memory/tree/mod.rs)). A new operator has two systems to debug, two schemas to learn, two ingestion paths.
- **GPL-3.0 license** — second cohort entry on classic GPL (after [MaxKB](1Panel-dev__MaxKB.md)). Distributable but stronger source-disclosure trigger than MIT/Apache. App vendors that need to redistribute as a bundled feature in proprietary software cannot use OpenHuman without legal review.
- **Tauri 2.x desktop-only** — there is no server mode. You cannot host this as a team-shared agent; every user runs a local Tauri shell + Rust core process pair. Dockerfile exists but builds a single-user runtime, not a multi-tenant server.
- **Skills system removed** — `skills/mod.rs:1` reads *"Legacy skill metadata helpers retained after QuickJS runtime removal."*. No active skill runtime in the open repo at this snapshot — capability extension goes through Composio toolkits + in-tree native providers, not user-authored skills.
- **No MCP server, limited MCP client** — for a 2026 agent harness this is a gap; cohort peers (DocsGPT, SurfSense, mksglu/context-mode) ship MCP servers. OpenHuman exposes everything via in-house JSON-RPC instead.
- **Graph layer is just SQL triples** — no Cypher, no graph algorithms, no SPARQL. Joins for path queries are hand-written. For agentic memory shapes where relationship traversal matters (cohort peers like cognee / graphiti / FalkorDB / memgraph), this is a deliberate downgrade.
- **"118+ integrations" is Composio-mediated** — the README's headline number comes from a backend-proxied SaaS dependency, not in-tree code. In-tree native Composio providers: 4 (`gmail / github / notion / slack`). In-tree native chat channels: 18. Catalogued (curated tool-list) Composio toolkits: 23. Direct API integrations: a handful in [`integrations/`](https://github.com/tinyhumansai/openhuman/tree/main/src/openhuman/integrations) (Apify, Google Places, Stock Prices, Twilio).

## When to use it

- **Good fit:** Solo developers / power-users who want a **single-binary desktop AI** with batteries (mascot, voice, Meet-joiner, 20-min auto-fetch, Composio OAuth toolkits, TokenJuice) and accept the OpenHuman SaaS backend + GPL-3.0. Rust-first teams who like the engineering taste (deterministic IDs, content-store SHA verification, level-aware seal gates, generation-counter overlap guards). Anyone who likes the "Obsidian vault as KB output" pattern from [AgriciDaniel/claude-obsidian](AgriciDaniel__claude-obsidian.md) but wants the agent + auto-fetch + voice stack bundled.
- **Bad fit:** Team-shared KB or multi-tenant SaaS (this is a single-user Tauri desktop app); regulated environments needing audited self-hosted-only deployment (the cloud backend is the default path); MIT/Apache-only legal envelopes; products needing rich graph reasoning (graph here is plain SQL triples — pick FalkorDB / memgraph / Neo4j-backed stacks like Graphiti instead); products needing MCP-server-as-surface (DocsGPT / SurfSense / context-mode); offline-only deployments (technically possible but second-class).
- **Closest alternative:**
  - [`AgriciDaniel/claude-obsidian`](AgriciDaniel__claude-obsidian.md) — Karpathy-LLM-wiki Obsidian-vault pattern, MIT, but plugin-only (no auto-fetch, no agent, no voice, no Composio).
  - [`NousResearch/hermes-agent`](_index.json) (candidate) — "agent that grows with you" memory shape, but BYO models / terminal-first per the OpenHuman comparison table.
  - [`Mintplex-Labs/anything-llm`](Mintplex-Labs__anything-llm.md) — broader provider matrix (37 LLMs / 14 embedders / 10 vectors), MIT, multi-user Docker, but no mascot/Meet/voice and no Obsidian-vault output.
  - [`plastic-labs/honcho`](plastic-labs__honcho.md) — Dreamer (deduction+induction) consolidation agent + peer paradigm, but AGPL-3.0 and server-based.
  - [`bytedance/deer-flow`](bytedance__deer-flow.md) — also "proactive context-aware AI partner" positioning, but Python LangGraph stack vs OpenHuman's Rust-native.

## Code pointers (evidence)

- **Memory-Tree entrypoint:** [`src/openhuman/memory/tree/mod.rs`](https://github.com/tinyhumansai/openhuman/blob/main/src/openhuman/memory/tree/mod.rs) — phase-comment layout
- **Chunk schema + deterministic IDs:** [`src/openhuman/memory/tree/types.rs:10-12`](https://github.com/tinyhumansai/openhuman/blob/main/src/openhuman/memory/tree/types.rs)
- **Chunker source-kind dispatch:** [`src/openhuman/memory/tree/chunker.rs:1-25`](https://github.com/tinyhumansai/openhuman/blob/main/src/openhuman/memory/tree/chunker.rs)
- **SQLite schema (Memory-Tree):** [`src/openhuman/memory/tree/store.rs:51-78`](https://github.com/tinyhumansai/openhuman/blob/main/src/openhuman/memory/tree/store.rs)
- **Legacy UnifiedMemory schema:** [`src/openhuman/memory/store/unified/init.rs:46-115`](https://github.com/tinyhumansai/openhuman/blob/main/src/openhuman/memory/store/unified/init.rs)
- **Bucket-seal cascade:** [`src/openhuman/memory/tree/tree_source/bucket_seal.rs:1-30`](https://github.com/tinyhumansai/openhuman/blob/main/src/openhuman/memory/tree/tree_source/bucket_seal.rs) (level-aware gates), [`tree_source/types.rs`](https://github.com/tinyhumansai/openhuman/blob/main/src/openhuman/memory/tree/tree_source/types.rs) (`INPUT_TOKEN_BUDGET=50_000`, `SUMMARY_FANOUT=10`, `OUTPUT_TOKEN_BUDGET=5_000`)
- **3 LabelStrategy variants:** [`bucket_seal.rs::LabelStrategy`](https://github.com/tinyhumansai/openhuman/blob/main/src/openhuman/memory/tree/tree_source/bucket_seal.rs)
- **6 retrieval primitives:** [`src/openhuman/memory/tree/retrieval/mod.rs:13-23`](https://github.com/tinyhumansai/openhuman/blob/main/src/openhuman/memory/tree/retrieval/mod.rs)
- **5-signal hybrid scoring (legacy):** [`src/openhuman/memory/store/unified/query.rs`](https://github.com/tinyhumansai/openhuman/blob/main/src/openhuman/memory/store/unified/query.rs) (`compose_query_score(keyword, vector, graph)` + freshness + episodic)
- **Auto-fetch periodic loop:** [`src/openhuman/composio/periodic.rs:1-50`](https://github.com/tinyhumansai/openhuman/blob/main/src/openhuman/composio/periodic.rs) (`TICK_SECONDS = 1200`)
- **TokenJuice rule engine:** [`src/openhuman/tokenjuice/mod.rs`](https://github.com/tinyhumansai/openhuman/blob/main/src/openhuman/tokenjuice/mod.rs) (3-layer rule overlay; `TINY_OUTPUT_MAX_CHARS = 240`)
- **TokenJuice builtin rule index:** [`src/openhuman/tokenjuice/rules/builtin.rs`](https://github.com/tinyhumansai/openhuman/blob/main/src/openhuman/tokenjuice/rules/builtin.rs)
- **Content-store integrity contract:** [`src/openhuman/memory/tree/content_store/README.md`](https://github.com/tinyhumansai/openhuman/blob/main/src/openhuman/memory/tree/content_store/README.md) (body bytes immutable, SHA-256 verified, `tags:` rewrites preserve hash)
- **Obsidian-vault defaults staging:** [`src/openhuman/memory/tree/content_store/obsidian.rs`](https://github.com/tinyhumansai/openhuman/blob/main/src/openhuman/memory/tree/content_store/obsidian.rs)
- **Memory-loader (importance-prefix prior-conversation injection):** [`src/openhuman/agent/memory_loader.rs:6-15`](https://github.com/tinyhumansai/openhuman/blob/main/src/openhuman/agent/memory_loader.rs)
- **Provider routing (`hint:` virtual model names):** [`src/openhuman/providers/router.rs:1-15`](https://github.com/tinyhumansai/openhuman/blob/main/src/openhuman/providers/router.rs)
- **Subconscious engine + reflection store:** [`src/openhuman/subconscious/engine.rs:1-40`](https://github.com/tinyhumansai/openhuman/blob/main/src/openhuman/subconscious/engine.rs)
- **MeetAgent session loop:** [`src/openhuman/meet_agent/mod.rs:1-40`](https://github.com/tinyhumansai/openhuman/blob/main/src/openhuman/meet_agent/mod.rs)
- **Channel providers (18 chats):** [`src/openhuman/channels/providers/`](https://github.com/tinyhumansai/openhuman/tree/main/src/openhuman/channels/providers)
- **Most useful single file to read first:** [`src/openhuman/memory/tree/mod.rs`](https://github.com/tinyhumansai/openhuman/blob/main/src/openhuman/memory/tree/mod.rs) — gives the 4-phase architecture in 35 lines, then [`tree_source/README.md`](https://github.com/tinyhumansai/openhuman/blob/main/src/openhuman/memory/tree/tree_source/README.md) for bucket-seal mechanics.

## Open questions

- **`postgres = "0.19"` dependency** — appears in `Cargo.toml` but core path uses SQLite. Backfill bins (`slack-backfill`, `gmail-backfill-3d`) probably consume it; would need to grep to be certain. If unused in app path, this is a dead dep.
- **Tool-memory** (`memory/tool_memory/`) — RAG-style "memory rules" loaded into the prompt up to `TOOL_MEMORY_PROMPT_CAP`. Is this the layer where "remember to use tool X with flags Y" hints persist across turns? Worth a follow-up read for the cohort's prompt-augmentation pattern.
- **`encryption/` module** — `aes-gcm` + `argon2` + `chacha20poly1305` deps suggest local-data-at-rest encryption. Is the chunks.db encrypted on disk? The README claims "encrypted locally" but the SQLite open call uses plain `Connection::open`. Possible the encryption wraps only specific blobs (credentials, OAuth tokens) and not the full Memory-Tree.
- **Composio backend dependency** — how much of the "118+ integrations" actually requires the OpenHuman SaaS backend (billing-key holder) versus an end-user-supplied Composio API key? Would a true offline / self-hosted operator be blocked at the Composio surface even if Ollama covers the LLM/embedder?
- **Skills runtime removal** — `skills/mod.rs:1` says QuickJS was removed. What replaced user-authored extensibility? Is it pure Composio + native providers + cron tasks now, with no per-user code injection point?
- **`tree_summarizer` (hour/day/month/year tree) vs `memory/tree/tree_source` (bucket-seal cascade)** — these are two parallel summary-tree implementations. Are they redundant, or does one feed the other? Worth a follow-up.
- **`subconscious::reflection::Reflection { Deduction, ... }`** — what exactly are the variants? `Reflection.rs:apply_cap` suggests N kinds; the cohort comparison to honcho's Dreamer hinges on the answer.

---

*Surveyed via the `curating-agentic-kbs` skill. Re-survey scheduled after 30 days of last `pushed_at` change.*
