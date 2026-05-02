# Survey: memvid/memvid

**Date:** 2026-05-01
**Stars:** 15,316 · **Last push:** 2026-03-16 · **Created:** 2024 · **Version:** `memvid-core 2.0.139` (Rust 2024, ≥1.85, Apache-2.0)
**Category:** memory-framework
**Slug:** [memvid/memvid](https://github.com/memvid/memvid)

---

## TL;DR (3 lines)

- **What it is:** First Rust-native repo in this cohort. `memvid-core` v2.0.139 is a pure-Rust library (Rust 2024, ≥1.85) that packages documents, embeddings, search indices, time index, optional in-file knowledge graph, signing keys, and crash-safety log into a **single `.mv2` file** — no databases, no sidecar files, no daemon. Distributed as a Crate plus thin Python / Node / CLI SDK wrappers.
- **How its KB works:** Append-only "Smart Frames" inside `.mv2` ([Header 4 KB → embedded WAL 1-64 MB → Data Segments → Tantivy lex index → HNSW vec index → Time Index → TOC footer with checksums]). Hybrid retrieval = Tantivy BM25 + HNSW dense → **RRF (k=60)**. Memory layer = `MemoryCard` rows with one of **seven explicit kinds** (`Fact = 0` / `Preference = 1` / `Event = 2` / `Profile = 3` / `Relationship = 4` / `Goal = 5` / `Other = 6`) plus an in-file **Logic-Mesh** graph (`MVLM` magic) for entity/relationship tracking. PII masking happens at query time via regex; encryption capsules (`.mv2e`) ship behind a feature flag.
- **Verdict:** Pick when you need **portable, single-file, persistent agent memory** that can be shipped on disk, signed, encrypted, time-traveled, and queried offline — and you're OK living in Rust (or a thin SDK over it). Skip if you need a server-class hybrid index, MCP integration (none), or write-amplification beyond the WAL window.

## KB Architecture

### Storage
- **Vector store:** **HNSW in-file** ([`src/vec.rs`](https://github.com/memvid/memvid/blob/main/src/vec.rs), feature `vec`). Built with local ONNX text embeddings or cloud APIs via `feature = "api_embed"`. Product-quantized variant in [`src/vec_pq.rs`](https://github.com/memvid/memvid/blob/main/src/vec_pq.rs). Single backend, no swap-out — HNSW lives as a `Vec Index Segment` inside the `.mv2` file.
- **Graph store:** **Logic-Mesh** ([`src/types/logic_mesh.rs`](https://github.com/memvid/memvid/blob/main/src/types/logic_mesh.rs)) — a custom on-disk graph blob with `LOGIC_MESH_MAGIC = b"MVLM"`, schema version 1, hard caps (1M nodes, 5M edges) for DoS prevention. Stores entities and relationships extracted during ingestion. **Cohort first**: a graph format designed to live inside the same single file as the vector index.
- **Metadata / structured:** **No external DB.** Everything is in `.mv2`: TOC footer with segment catalog + SHA-256 checksums, time index (chronological ordering), header (magic `MV2\0`, version, WAL offsets, footer offset, `toc_checksum`).
- **Object / blob:** Same — content lives as compressed payloads (`zstd` or `lz4_flex`) in the Data Segments region of the same file.

### Ingestion / Extraction
- **Source types accepted:** PDF (three pluggable extractors — `pdf-extract`, `pdf_oxide`, `lopdf`, plus optional `extractous` GraalVM-backed), DOCX/XLSX (via `calamine` + `quick-xml` + `zip`), plain text, audio (`whisper.rs` with `melfilters.bytes` + `melfilters128.bytes` precomputed mel filterbanks shipped in-repo), images via CLIP (feature `clip`).
- **Chunking strategy:** [`src/structure/chunker.rs`](https://github.com/memvid/memvid/blob/main/src/structure/chunker.rs) + [`structure/detector.rs`](https://github.com/memvid/memvid/blob/main/src/structure/detector.rs) detect document structure before chunking; SymSpell-based OCR repair (`feature = "symspell_cleanup"`) fixes word-broken PDFs (`"emp lo yee" → "employee"`).
- **Entity / fact extraction:** **Four modes** via `ExtractionMode` enum ([`src/triplet/types.rs`](https://github.com/memvid/memvid/blob/main/src/triplet/types.rs)):
  - **`Rules`** (default) — fast, offline, pattern-based via [`src/enrich/rules.rs`](https://github.com/memvid/memvid/blob/main/src/enrich/rules.rs).
  - **`Llm(String)`** — LLM-only extraction (the variant carries the model-name config string).
  - **`Hybrid`** — rules-first, LLM-on-fallback (auto-enabled when LLM configured).
  - **`Disabled`** — extraction off entirely.
  Triples land in the Logic-Mesh graph; structured atomic facts land as `MemoryCard` rows.
- **Schema:** **Seven-kind atomic-fact memory** — `MemoryKind { Fact = 0, Preference = 1, Event = 2, Profile = 3, Relationship = 4, Goal = 5, Other = 6 }` ([`src/types/memory_card.rs`](https://github.com/memvid/memvid/blob/main/src/types/memory_card.rs)) with frame-id linkage, identity (deduplication), provenance, and versioning fields. The most explicitly typed memory schema in the cohort — superset of MaxKB's 4-category and graphiti's 4-tier saga model. The `Other = 6` variant is for custom/extension kinds.

### Retrieval
- **Modes:** **Hybrid Tantivy BM25 + HNSW dense + RRF** ([`src/memvid/ask.rs`](https://github.com/memvid/memvid/blob/main/src/memvid/ask.rs), `RRF_K = 60.0`). Plus **graph-aware search** via `QueryPlanner` ([`src/graph_search.rs`](https://github.com/memvid/memvid/blob/main/src/graph_search.rs)) that parses NL queries for relational patterns, runs `TriplePattern` / `GraphPattern` matches against MemoryCards / Logic-Mesh, then fuses with vector ranking. **Time-travel queries** via `TimelineQueryBuilder`.
- **Reranker:** No external reranker; in-process token-overlap reorder helper (`reorder_hits_by_token_matches`) only. This is conscious — memvid optimizes for offline / no-network / single-binary deployment.
- **Top-k defaults:** Configurable per `SearchRequest`; `snippet_chars=200` is a typical default. RRF k=60 hardcoded.
- **Context assembly:** `build_context` helper composes `AskContextFragment`s with `AskContextFragmentKind` distinctions; `AskMode` selects retrieval strategy; `AskRetriever` selects engine (`SearchEngineKind`).

### Memory model
- **Tiers:** Two structured tiers + one raw:
  - **Frames** — raw byte content (`put_bytes` / `put_bytes_with_options`) compressed and committed via WAL.
  - **MemoryCards** — six-kind atomic facts extracted by the rules engine or LLM.
  - **Logic-Mesh** — graph of entities + relationships derived during ingestion.
- **Bi-temporal:** Approximate — frames have transaction time (sequence + commit timestamp), `Event` memory kind has content time, `temporal_track` feature parses natural-language dates ("last Tuesday") via `interim`. No formal `valid_at` / `invalid_at` like graphiti, but Time Index + Event kind + replay engine give "as-of-frame" queries.
- **Self-update mechanism:** Explicit — `put_bytes()` then `commit()`. Frames are immutable once committed; "deletes" mark tombstones, never rewrite. The `replay/engine.rs` lets you walk the history forward / branch.
- **Decay / forgetting:** None automatic — frames are append-only by design. Capsule expiry exists for `.mv2` capsules with rules + TTL (per README "Capsule Context"), but the core file format is "rewindable timeline", not GC'd.

### MCP / connectors
- **MCP server exposed:** **No.**
- **MCP client used:** **No.**
- **Native connectors:** None network-side. The "connectors" are file format extractors (PDF/DOCX/audio/image/text).
- **Tool-call surface:** N/A — memvid is a library, not an agent runtime. The Python / Node SDKs expose put/search/ask/timeline; consumers are expected to wire those into whatever agent loop they run.

### Notable design choices
- **Single-file format with crash safety** — Header + embedded WAL + segments + footer with checksums. Cargo dep `fs2` for advisory file locks ([`src/lock.rs`](https://github.com/memvid/memvid/blob/main/src/lock.rs), [`lockfile.rs`](https://github.com/memvid/memvid/blob/main/src/lockfile.rs)). All writes go through WAL; commits are atomic. Failed writes don't corrupt prior frames.
- **Cargo feature gating is the configuration UX** — `lex` (Tantivy BM25), `vec` (HNSW + ONNX), `clip` (CLIP image embeddings), `whisper` (audio transcription), `api_embed` (OpenAI embeddings), `temporal_track` (NL dates), `parallel_segments` (multi-threaded ingest), `encryption` (AES-256-GCM `.mv2e` capsules), `symspell_cleanup` (PDF text repair). Compose only what you need; binary stays minimal.
- **Seven-kind MemoryCard taxonomy** — Fact / Preference / Event / Profile / Relationship / Goal / Other — explicitly tagged at extraction time. Cohort superset of MaxKB's `偏好/背景/约定/目标` and an alternative to mem0's flat atomic-fact / graphiti's saga-episodic-community-semantic.
- **Logic-Mesh as in-file graph** — instead of running Neo4j, a graph blob lives next to the vec index in the same file with magic bytes `MVLM`, hard caps for DoS, and `Result<()>` validation. Closest cohort analogue: graphrag's Parquet outputs (also in-file), but graphrag uses NetworkX in-memory; memvid persists the graph as a typed blob.
- **PII masking at query time** ([`src/pii.rs`](https://github.com/memvid/memvid/blob/main/src/pii.rs)) — regex-based detection for emails, US SSN, phone, credit cards, IPv4, common API key patterns → replaced with `[EMAIL]` / `[SSN]` / `[PHONE]` / `[CREDIT_CARD]` / `[IP_ADDRESS]` / `[API_KEY]` placeholders before the masked text reaches an LLM. Original text stays searchable in the file. **Cohort first** — most repos defer PII to upstream connectors; memvid bakes it in.
- **Cryptographic provenance** — `ed25519-dalek` signatures ([`src/signature.rs`](https://github.com/memvid/memvid/blob/main/src/signature.rs)) + `blake3` content hashing + `sha2` for TOC checksums. Files are tamper-evident and signable.
- **Encryption capsules** (`.mv2e`) — AES-256-GCM password-based encryption behind `feature = "encryption"`. Capsules with rules and expiry semantics ("Capsule Context") are first-class in the API.
- **No async** — explicitly synchronous library design; CLAUDE.md notes "No async: Library is synchronous for simplicity." Cohort first — every other repo runs an async tokio/asyncio loop.
- **Multi-language SDK strategy** — Rust crate is the source of truth (`memvid-core`); thin wrappers (`memvid-sdk` PyPI, `@memvid/sdk` npm, `memvid-cli` npm) expose the same API. Compare to mem0 (separate Python and TS implementations) or graphiti (Python only).
- **Benchmark-driven marketing** — README leads with LoCoMo benchmark numbers (+35% SOTA, 0.025ms P50 / 0.075ms P99). Open-source eval is published and reproducible per the README; LLM-as-Judge methodology.

## Dependencies (KB-relevant)

From `Cargo.toml`:

```
[package]
name = "memvid-core"
version = "2.0.139"
edition = "2024"
rust-version = "1.85.0"
license = "Apache-2.0"

[dependencies]
# Storage / IO / safety
zstd = "0.13.1", lz4_flex = "0.12.0"      # compression
fs2 = "0.4.3"                              # file locks
bincode = "2.0.1", serde = "1.0.228"       # serialization
blake3 = "1.5.1", sha2 = "0.10.9"          # hashing
ed25519-dalek = "2.2.0"                    # signing

# Search
# (Tantivy BM25 enabled via `lex` feature; HNSW via `vec` feature — both gated)
once_cell = "1.19.0"
unicode-normalization = "0.1", unicode-segmentation = "1.11"

# Document extraction
extractous = { version = "0.3", optional = true }      # GraalVM-backed
lopdf = "0.39"
pdf-extract = { version = "0.10", optional = true }    # pure-Rust default
pdf_oxide = { version = "0.3", optional = true }       # 2025 high-accuracy
pdfium-render = { version = "0.8.28", optional = true }
calamine = "0.22"                                       # XLSX
quick-xml = "0.31", zip = "7.1"                         # DOCX

# Time / NL
time = "0.3.36", chrono = "0.4.42"
interim = { version = "0.2.1", optional = true }        # NL date parser

# Audio (feature `whisper`)
# melfilters.bytes / melfilters128.bytes shipped in-repo
```

License: **Apache-2.0**.

## Tradeoffs

**Pros:**
- **Truly portable memory** — copy/email/version one `.mv2` file and the whole memory state moves with you. No "dump pgvector + dump Postgres + sync object store" choreography.
- **Crash-safe by construction** — WAL + immutable frames + atomic commits + advisory file locks. Other in-process designs (AstrBot's Faiss, LightRAG's nano-vectordb) don't have this.
- **Most explicitly typed memory schema in the cohort** — six MemoryKind variants give the agent runtime a typed surface ("give me all `Preference` cards for user X").
- **Cryptographic provenance** — signing + checksums + optional encryption out of the box. Useful for medical/legal/financial deployments.
- **PII masking baked in** — query-time only, original stays searchable.
- **Cargo feature gating** — start with `lex+vec`, opt into CLIP/Whisper/encryption only when needed. Binary footprint stays small.
- **Pure Rust, sync, no daemon** — drops cleanly into embedded/desktop/CLI contexts. Cohort first for "no async, no server".

**Cons:**
- **No MCP at all** — neither server nor client. Library expects you to wire it into whatever agent runtime you ship.
- **Single vector backend (HNSW), single graph format (Logic-Mesh)** — no Qdrant/Milvus/Neo4j swap-out. Trade-off for the single-file design.
- **Python/Node SDKs are wrappers** — Rust core is the source of truth; non-Rust users pay an FFI tax and depend on SDK release cadence.
- **No reranker** — relies on token-overlap reorder + RRF. For high-precision retrieval you'd need to bolt one on outside.
- **Sync API** — fine for CLIs / batch ingest, awkward for high-concurrency servers; you'd run multiple processes / pool.
- **6+ week gap since last push** (2026-03-16) is the longest in this cohort. Active per CHANGELOG, but check before adopting.
- **Eval methodology disclaimers** — the +35% / +76% / +56% headlines are LLM-as-Judge with open eval, but cohort comparisons against "industry average" are coarse; reproduce locally before quoting.
- **No conversation/episode adapters** — memvid is doc-RAG-shaped. Conversation memory is up to the integrator.

## When to use it

- **Good fit:** desktop / mobile / offline AI agents that need portable persistent memory; medical / legal / financial agents needing signed + encrypted + auditable memory; embedded products where "ship one file" beats "stand up a service"; Rust-first stacks; benchmark-conscious agent harnesses.
- **Bad fit:** SaaS multi-tenant RAG over millions of docs (single-file ceiling); MCP-server-as-product designs; high-concurrency servers wanting async; teams without Rust appetite *and* unwilling to depend on the SDK wrappers.
- **Closest alternative:** [`basicmachines-co/basic-memory`](surveys/basicmachines-co__basic-memory.md) — also "files-as-source-of-truth" memory, but Python + SQLite + sqlite-vec + markdown files (one note per memory). Memvid is one file *of* memories; basic-memory is many files *as* memories. For agent-side memory frameworks with online write-through, [`mem0ai/mem0`](surveys/mem0ai__mem0.md) is the closest functional alternative — opposite stack (Python + 30+ swappable vector backends + always-online).

## Code pointers (evidence)

- File-format spec: [`MV2_SPEC.md`](https://github.com/memvid/memvid/blob/main/MV2_SPEC.md)
- Public API surface: [`src/lib.rs`](https://github.com/memvid/memvid/blob/main/src/lib.rs)
- Memvid struct + lifecycle (create / open / put / commit): [`src/memvid/`](https://github.com/memvid/memvid/tree/main/src/memvid)
- WAL + crash safety: [`src/io/`](https://github.com/memvid/memvid/tree/main/src/io) (header.rs, wal.rs, time_index.rs)
- Hybrid retrieval (Tantivy BM25 + HNSW + RRF k=60): [`src/memvid/ask.rs:21`](https://github.com/memvid/memvid/blob/main/src/memvid/ask.rs)
- Graph-aware search planner: [`src/graph_search.rs`](https://github.com/memvid/memvid/blob/main/src/graph_search.rs)
- Vector index (HNSW + product quantization): [`src/vec.rs`](https://github.com/memvid/memvid/blob/main/src/vec.rs), [`src/vec_pq.rs`](https://github.com/memvid/memvid/blob/main/src/vec_pq.rs)
- 6-kind MemoryCard schema: [`src/types/memory_card.rs`](https://github.com/memvid/memvid/blob/main/src/types/memory_card.rs)
- Logic-Mesh on-disk graph (`MVLM` magic): [`src/types/logic_mesh.rs`](https://github.com/memvid/memvid/blob/main/src/types/logic_mesh.rs)
- Triplet extractor (`Rules` / `Hybrid` / `LLM`): [`src/triplet/extractor.rs`](https://github.com/memvid/memvid/blob/main/src/triplet/extractor.rs), [`src/enrich/rules.rs`](https://github.com/memvid/memvid/blob/main/src/enrich/rules.rs)
- PII masking (regex): [`src/pii.rs`](https://github.com/memvid/memvid/blob/main/src/pii.rs)
- ed25519 signatures + checksums: [`src/signature.rs`](https://github.com/memvid/memvid/blob/main/src/signature.rs), [`src/footer.rs`](https://github.com/memvid/memvid/blob/main/src/footer.rs)
- Replay / time-travel engine: [`src/replay/engine.rs`](https://github.com/memvid/memvid/blob/main/src/replay/engine.rs)
- Audio + image embedders: [`src/whisper.rs`](https://github.com/memvid/memvid/blob/main/src/whisper.rs), [`src/clip.rs`](https://github.com/memvid/memvid/blob/main/src/clip.rs)
- AI guidance: [`CLAUDE.md`](https://github.com/memvid/memvid/blob/main/CLAUDE.md)
- Most useful single file to read first: [`MV2_SPEC.md`](https://github.com/memvid/memvid/blob/main/MV2_SPEC.md) — the file format is the architecture; once you understand the segment layout the rest is mechanical.

## Open questions

- "Memvid v1 was actually MP4-encoded" (per the v1 README on older tags) — what motivated the v2 pivot to a non-video single-file format? Worth a deeper history pass.
- Logic-Mesh has hard caps (1M nodes, 5M edges); how does this scale across multiple `.mv2` files? Federated / linked capsules?
- Cohort-unique sync API — do the SDK wrappers (Python / Node) expose async via a runtime, or is everything blocking on the Rust core?
- LoCoMo benchmark methodology — the numbers are loud; reproducibility instructions are linked but the eval harness's pinned versions of competing systems matter.
- The 6-kind MemoryCard schema overlaps with MaxKB's 4-category in obvious ways — was either inspired by the other, or convergent design? Compare prompts.

---

*Surveyed via the `curating-agentic-kbs` skill. Re-survey scheduled after 30 days of last `pushed_at` change.*

*Audit 2026-05-02: clone-verified against [`Cargo.toml`](https://github.com/memvid/memvid/blob/main/Cargo.toml) (v2.0.139, edition 2024, rust ≥1.85, Apache-2.0), [`src/types/memory_card.rs`](https://github.com/memvid/memvid/blob/main/src/types/memory_card.rs), [`src/types/logic_mesh.rs`](https://github.com/memvid/memvid/blob/main/src/types/logic_mesh.rs), [`src/triplet/types.rs`](https://github.com/memvid/memvid/blob/main/src/triplet/types.rs), [`src/triplet/extractor.rs`](https://github.com/memvid/memvid/blob/main/src/triplet/extractor.rs), [`src/memvid/ask.rs`](https://github.com/memvid/memvid/blob/main/src/memvid/ask.rs). **Corrections:** MemoryKind variants **6 → 7** (added `Other = 6` for custom/extension kinds — not in initial draft); ExtractionMode **3 → 4** modes (added `Disabled`); LLM variant signature is `Llm(String)` carrying model-name config, not bare `LLM`. **Verified verbatim:** `RRF_K = 60.0` exact at [`ask.rs:19`](https://github.com/memvid/memvid/blob/main/src/memvid/ask.rs#L19), `LOGIC_MESH_MAGIC = b"MVLM"` at [`logic_mesh.rs:14`](https://github.com/memvid/memvid/blob/main/src/types/logic_mesh.rs#L14), shipped mel-filterbank bytes at `src/melfilters.bytes` + `src/melfilters128.bytes`, crypto deps `ed25519-dalek 2.2.0` + `blake3 1.5.1` + `sha2 0.10.9`, version `memvid-core 2.0.139`.*
