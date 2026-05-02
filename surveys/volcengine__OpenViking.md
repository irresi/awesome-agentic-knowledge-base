# Survey: volcengine/OpenViking

**Date:** 2026-05-02
**Stars:** 23,317 · **Last push:** 2026-05-01 · **Created:** 2026-01 · **Version:** ragfs `0.1.0` (Cargo workspace: 3 crates `ov_cli` / `ragfs` / `ragfs-python`) · **License:** AGPL-3.0
**Category:** memory-framework
**Slug:** [volcengine/OpenViking](https://github.com/volcengine/OpenViking)

---

## TL;DR (3 lines)

- **What it is:** ByteDance Volcengine's open-source **"Context Database for AI Agents"** — Python + Rust hybrid (`pip install openviking` + a Rust `ragfs` crate + `ov_cli`). AGPL-3.0. Distinct architectural bet: **filesystem-paradigm context management** instead of fragmented vector storage. Ships preset directories for `user/agent/resources/session`.
- **How its KB works:** Memories, resources, and skills all live as *files* in a virtual filesystem (RAG-FS, "ragfs"). **L0 / L1 / L2 `ContextLevel`** tiers (ABSTRACT / OVERVIEW / DETAIL) drive on-demand loading to save tokens. **Hierarchical + recursive retrieval** combines directory positioning with semantic search. **7 ragfs backends** ship in the Rust crate: `kvfs`, `localfs`, `memfs`, `queuefs`, `s3fs`, `serverinfofs`, `sqlfs`.
- **Verdict:** Pick when "context-as-files" maps cleanly to your agent's mental model and you want **observable retrieval trajectories** + automatic session compression with long-term memory extraction. Skip if you prefer flat vector retrieval, want to avoid AGPL, or don't need the FS abstraction's overhead.

## KB Architecture

### Storage
- **Vector store:** Indirectly — files at L0 (ABSTRACT), L1 (OVERVIEW), L2 (DETAIL) tiers carry vector indexes; storage backend depends on the `ragfs` plugin chosen. The `Vectorize` dataclass + `ContextLevel` enum drive what gets embedded.
- **Graph store:** *None.*
- **Metadata / structured:** **`ragfs` virtual filesystem** with 7 backend plugins ([`crates/ragfs/src/plugins/`](https://github.com/volcengine/OpenViking/tree/main/crates/ragfs/src/plugins)): `kvfs` (key-value), `localfs` (host filesystem), `memfs` (in-memory), `queuefs` (queue-shaped), `s3fs` (S3-compatible), `serverinfofs` (server metadata), `sqlfs` (SQL-backed). The Python side queries via `pyagfs/` bindings.
- **Object / blob:** S3-compatible via `s3fs` ragfs plugin.

### Ingestion / Extraction
- **Source types accepted:** PDFs (`pdfplumber` + `pdfminer-six`), DOCX (`python-docx`), PPTX (`python-pptx`), XLSX (`openpyxl`), XLS (`xlrd`), EPUB (`ebooklib`), legacy DOC (`olefile`), web (`readabilipy`, `markdownify`).
- **Chunking strategy:** Tiered — content lives at L0 (abstract), L1 (overview), L2 (detail) levels; retrieval picks the right level on demand. Custom chunkers in [`openviking/parse/`](https://github.com/volcengine/OpenViking/tree/main/openviking/parse).
- **Entity / fact extraction:** [`openviking/core/building_tree.py`](https://github.com/volcengine/OpenViking/blob/main/openviking/core/building_tree.py) — an LLM builds the directory tree from raw inputs. `intent_analyzer.py` classifies queries to drive directory-recursive retrieval.
- **Schema:** **`Context` dataclass** with `ContextType` enum (memory / resource / skill / session) + `ResourceContentType` enum + `ContextLevel` enum. URIs follow a filesystem-style schema validated by [`uri_validation.py`](https://github.com/volcengine/OpenViking/blob/main/openviking/core/uri_validation.py).

### Retrieval
- **Modes:** **Hierarchical + directory-recursive** ([`retrieve/hierarchical_retriever.py`](https://github.com/volcengine/OpenViking/blob/main/openviking/retrieve/hierarchical_retriever.py)) — combines directory positioning with semantic search. **Intent-analyzer-driven** routing to subtrees ([`retrieve/intent_analyzer.py`](https://github.com/volcengine/OpenViking/blob/main/openviking/retrieve/intent_analyzer.py)). **Visualized retrieval trajectory** — the README claims you can observe and debug the directory traversal path.
- **Reranker:** Per-tier reranking; integrates with `litellm` for model-agnostic LLM-as-reranker.
- **Top-k defaults:** Configurable per-directory.
- **Context assembly:** L0 → L1 → L2 progressive disclosure. **Memory lifecycle** ([`retrieve/memory_lifecycle.py`](https://github.com/volcengine/OpenViking/blob/main/openviking/retrieve/memory_lifecycle.py)) governs when memories age out / get reloaded.

### Memory model
- **Tiers:** **L0 / L1 / L2 vertical tiers** + **directory-tree horizontal organization** + **session/user/agent preset roots**. Cohort first to combine tiered loading with FS-paradigm memory.
- **Bi-temporal:** No.
- **Self-update mechanism:** **Automatic session management** — README states content / resource references / tool calls in conversations are automatically compressed; long-term memory extracted from sessions. `apscheduler>=3.11.0` powers scheduled tasks.
- **Decay / forgetting:** `memory_lifecycle.py` — explicit lifecycle module (cohort first to name memory lifecycle as a first-class subsystem).

### MCP / connectors
- **MCP server exposed:** Yes — server module at [`openviking/server/`](https://github.com/volcengine/OpenViking/tree/main/openviking/server) (FastAPI-based per `fastapi>=0.128.0` dep).
- **MCP client used:** Yes — [`openviking/core/mcp_converter.py`](https://github.com/volcengine/OpenViking/blob/main/openviking/core/mcp_converter.py) converts between MCP and OpenViking's internal context format.
- **Native connectors:** Bot module at [`bot/`](https://github.com/volcengine/OpenViking/tree/main/bot); console at [`openviking/console/`](https://github.com/volcengine/OpenViking/tree/main/openviking/console). Volcengine SDK integration (`volcengine>=1.0.216`, `volcengine-python-sdk[ark]>=5.0.3`).
- **Tool-call surface:** **Skill loader** ([`openviking/core/skill_loader.py`](https://github.com/volcengine/OpenViking/blob/main/openviking/core/skill_loader.py)) — loads skills as files inside the FS paradigm. Plus model providers via `litellm` (vendor-agnostic LLM router).

### Notable design choices
- **"Filesystem paradigm" as the architectural primitive** — context (memory + resource + skill) is files in a tree, not rows in a vector DB. Cohort first. Closest analogue: byterover-cli's git-like context tree, but ByteRover's tree is per-repo development context; OpenViking's tree is *the entire memory model*.
- **L0 / L1 / L2 tiered loading** — explicit `ContextLevel` enum drives token-cost minimization. Cohort first to type the tier explicitly (cognee has summary tiers but not enumerated as Level 0/1/2).
- **Rust `ragfs` crate with 7 plugins** — `kvfs`, `localfs`, `memfs`, `queuefs`, `s3fs`, `serverinfofs`, `sqlfs`. Pluggable storage at the FS layer rather than the vector layer.
- **`pyagfs/`** — Python bindings to the Rust ragfs crate; the Python and Rust halves communicate through this FFI.
- **Visualized retrieval trajectory** — directory-traversal path is observable; cohort first to claim retrieval observability as a primary feature (ragflow has tracing, onyx has langfuse/langsmith, but neither emphasizes retrieval-trajectory visualization).
- **Memory lifecycle as a first-class module** — separate `memory_lifecycle.py` for retention/eviction logic.
- **Multi-language READMEs** — EN / 简体中文 / 日本語. ByteDance's typical international distribution.
- **AGPL-3.0** — strong copyleft; Volcengine ships an AGPL OSS version with a hosted commercial offering on volcengine.com.
- **Heavy LLM-router dep** — `litellm>=1.0.0,<1.83.13` for vendor-agnostic LLM access (similar shape to Onyx's litellm integration).
- **Bot subdirectory** — IM-bot integrations live at top-level `bot/` (not surveyed in detail).

## Dependencies (KB-relevant)

From `pyproject.toml`:

```
name = "openviking"
license = "AGPL-3.0"
requires-python = ">=3.10"

# Core
pydantic>=2.0.0, typing-extensions>=4.5.0
pyyaml>=6.0, jinja2>=3.1.6
fastapi>=0.128.0, uvicorn>=0.39.0
httpx>=0.25.0, requests>=2.31.0
apscheduler>=3.11.0                       # scheduled session compression
xxhash>=3.0.0
typer>=0.12.0                             # CLI

# Document parsers
pdfplumber>=0.10.0, pdfminer-six>=20251230
python-docx, python-pptx, openpyxl, xlrd, olefile
ebooklib, readabilipy, markdownify

# LLM
litellm>=1.0.0,<1.83.13                   # vendor-agnostic LLM router
openai>=1.0.0
volcengine>=1.0.216
volcengine-python-sdk[ark]>=5.0.3         # ByteDance Ark / Doubao models
json-repair>=0.25.0
```

License: **AGPL-3.0**.

## Tradeoffs

**Pros:**
- **Filesystem-paradigm memory model** — maps cleanly to how developers think about "where things live" without committing to a graph or vector schema.
- **L0/L1/L2 tiered loading** — explicit token-cost optimization at the type level.
- **7-backend ragfs plugin system** — KV / local / mem / queue / S3 / serverinfo / SQL coverage from one Rust crate.
- **Visualized retrieval trajectory** — debugging black-box retrieval is a real cohort gap that OpenViking specifically addresses.
- **Automatic session compression + long-term memory extraction** scheduled via APScheduler.
- **Separable Python + Rust split** — Python for the agent-facing API, Rust for performance-critical FS ops.
- **Multi-language docs** + Volcengine partnership signals strong CN-cloud distribution.

**Cons:**
- **AGPL-3.0** — same legal concerns as basic-memory / OpenHands / claude-mem / khoj / AstrBot.
- **CN-cloud-tilt** — Volcengine SDK as a hard dep + Doubao/Ark as the primary LLM target. Globally portable but China-cloud-first.
- **No graph layer** — the FS paradigm encodes hierarchy but not arbitrary relationships.
- **`litellm` upper-bound pin** (`<1.83.13`) signals upstream version sensitivity.
- **Relatively new (created 2026-01)** — 4 months of public history; production maturity unproven.
- **Python + Rust split** adds build complexity (Rust toolchain + C++ compiler required).
- **Filesystem metaphor's ceiling** — when memories don't decompose neatly into a tree, you'll fight the abstraction.

## When to use it

- **Good fit:** agent products where memory naturally maps to per-user/per-session/per-resource directories; teams wanting **observable retrieval trajectories** for debugging; CN-cloud / Doubao deployments; products that benefit from explicit L0/L1/L2 tiered loading to control LLM token cost.
- **Bad fit:** pure-flat-fact memory (use mem0); graph-traversal-heavy memory (use graphiti / cognee); single-binary deployments (Python + Rust + FS layer is heavier than memvid's single-`.mv2`-file); Apache-2.0/MIT-only legal envelopes.
- **Closest alternative:** [`campfirein/byterover-cli`](surveys/campfirein__byterover-cli.md) — also has a hierarchical/git-like context tree, but as a coding-agent context layer rather than a general memory database. [`MemTensor/MemOS`](surveys/MemTensor__MemOS.md) is the closest research-shaped peer (MemCube as a memory container vs OpenViking's filesystem). [`topoteretes/cognee`](surveys/topoteretes__cognee.md)'s "memify pipelines" share the consolidation angle.

## Code pointers (evidence)

- Core context abstractions (Context / ContextType / ContextLevel / Vectorize): [`openviking/core/context.py`](https://github.com/volcengine/OpenViking/blob/main/openviking/core/context.py)
- Preset directories (`user`, `agent`, `resources`, `session`) + `DirectoryInitializer`: [`openviking/core/directories.py`](https://github.com/volcengine/OpenViking/blob/main/openviking/core/directories.py)
- Skill loader: [`openviking/core/skill_loader.py`](https://github.com/volcengine/OpenViking/blob/main/openviking/core/skill_loader.py)
- MCP converter: [`openviking/core/mcp_converter.py`](https://github.com/volcengine/OpenViking/blob/main/openviking/core/mcp_converter.py)
- Hierarchical retriever + intent analyzer + memory lifecycle: [`openviking/retrieve/`](https://github.com/volcengine/OpenViking/tree/main/openviking/retrieve)
- Building tree (LLM-driven dir construction): [`openviking/core/building_tree.py`](https://github.com/volcengine/OpenViking/blob/main/openviking/core/building_tree.py)
- Rust `ragfs` crate (7 plugins): [`crates/ragfs/src/plugins/`](https://github.com/volcengine/OpenViking/tree/main/crates/ragfs/src/plugins) (`kvfs/`, `localfs/`, `memfs/`, `queuefs/`, `s3fs/`, `serverinfofs/`, `sqlfs/`)
- Python ↔ Rust bindings: [`openviking/pyagfs/`](https://github.com/volcengine/OpenViking/tree/main/openviking/pyagfs)
- Server (FastAPI): [`openviking/server/`](https://github.com/volcengine/OpenViking/tree/main/openviking/server)
- CLI (Typer + Rust `ov_cli`): [`openviking_cli/`](https://github.com/volcengine/OpenViking/tree/main/openviking_cli) + [`crates/ov_cli/`](https://github.com/volcengine/OpenViking/tree/main/crates/ov_cli)
- Most useful single file to read first: [`openviking/core/context.py`](https://github.com/volcengine/OpenViking/blob/main/openviking/core/context.py) — the `Context` + `ContextType` + `ContextLevel` types are the architectural center.

## Open questions

- ragfs is a custom Rust crate — what's the maturity vs production tooling like (e.g., backups, replication)?
- Visualized retrieval trajectory — what's the actual UI? Console output? Web dashboard? Worth a deeper dive.
- Building-tree LLM cost — how often does the LLM rebuild directory structure as new memories accumulate?
- Memory lifecycle policies — defaults / configurability surface?
- L0/L1/L2 tiered embedding strategy — are different embedding models used per tier, or same model with different chunking?
- The `bot/` directory — what IM platforms ship?

---

*Surveyed via the `curating-agentic-kbs` skill. Re-survey scheduled after 30 days of last `pushed_at` change.*

*Audit 2026-05-02: clone-verified against [`Cargo.toml`](https://github.com/volcengine/OpenViking/blob/main/Cargo.toml) (workspace with 3 crates: `ov_cli`, `ragfs`, `ragfs-python`), [`crates/ragfs/Cargo.toml`](https://github.com/volcengine/OpenViking/blob/main/crates/ragfs/Cargo.toml) (`ragfs` v0.1.0), [`crates/ragfs/src/plugins/`](https://github.com/volcengine/OpenViking/tree/main/crates/ragfs/src/plugins) (7 backend subdirs), [`crates/ov_cli/src/main.rs`](https://github.com/volcengine/OpenViking/blob/main/crates/ov_cli/src/main.rs) (CLI commands document L0/L1/L2 tiers), [`LICENSE`](https://github.com/volcengine/OpenViking/blob/main/LICENSE) (AGPL-3.0). **All major cohort-first claims verified verbatim:** 7 ragfs backend plugins exact (`kvfs`, `localfs`, `memfs`, `queuefs`, `s3fs`, `serverinfofs`, `sqlfs`), L0/L1/L2 tier semantic confirmed in CLI: L0 = "abstract content", L1 = "overview content", L2 = "file content" (the `Read` / `Abstract` / `Overview` subcommands at `main.rs:274-284`). **No corrections needed** — survey quality matches cognee / microsoft-graphrag / deepwiki-open / MemOS / OpenHands / khoj / AstrBot tier. Added version `ragfs 0.1.0` + Cargo workspace structure + AGPL-3.0 to header.*
