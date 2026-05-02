# Survey: basicmachines-co/basic-memory

**Date:** 2026-05-01
**Stars:** 2,957 · **Last push:** 2026-05-01 · **Created:** 2024-12-02
**Category:** memory-framework
**Slug:** [basicmachines-co/basic-memory](https://github.com/basicmachines-co/basic-memory)

---

## TL;DR (3 lines)

- **What it is:** Local-first **Zettelkasten + knowledge graph** built on the Model Context Protocol — markdown files in a folder are the source of truth, and the DB is a derived, watched index. The LLM (via MCP) reads and writes those files directly.
- **How its KB works:** `.md` files with **YAML frontmatter** + structured **observations** (`- [tag] statement`) and **relations** (`relates_to [[Other Note]]`) are parsed by **syntax rules (no LLM)** into entities/edges; index lives in **SQLite (default) or Postgres** with **sqlite-vec + fastembed** for local embeddings; `watchfiles` keeps DB ↔ files in sync.
- **Verdict:** Pick when **the user owns the data on disk** (Obsidian-style workflow, git-versioned notes, no vendor lock); skip if you need LLM-based atomic-fact extraction or production-scale indexing — basic-memory is single-user / single-machine in spirit.

## KB Architecture

### Storage
- **Vector store:** **sqlite-vec** — SQLite extension for vectors (in-process, no separate service); embeddings via **fastembed** (ONNX, local)
- **Graph store:** **derived from markdown** — `[[Wiki Links]]` between notes form the graph, tracked in the relational DB; no Neo4j-class store
- **Metadata / structured:** **SQLite** (default, via aiosqlite) OR **Postgres** (psycopg) — both indexed via SQLAlchemy 2.x + Alembic migrations
- **Source of truth:** the **markdown files themselves**, not the DB. Files are ground truth; the DB is a re-buildable cache.
- **Cache:** in-process; `watchfiles` reacts to filesystem changes
- **Object / blob:** N/A — files are the storage

### Ingestion / Extraction
- **Source types accepted:** **markdown files** in a watched folder; importers under `src/basic_memory/importers/` for migrating from other systems
- **Chunking strategy:** per-note; an "entity" = one markdown file
- **Entity / fact extraction:** **rule-based parser, no LLM** — `markdown-it-py` parses, `python-frontmatter` reads YAML, syntax patterns extract observations and relations:
  - Observation: `- [category] free-text statement #optional-tags (context)`
  - Relation: `verb_phrase [[Other Note]]`
- **Schema:** explicit observation+relation grammar; optional `schema` field in frontmatter for typed entities; custom frontmatter fields stored in `entity_metadata`
- **Bidirectional sync:** LLM edits a file via MCP → watchfiles triggers re-parse → DB update; or DB update → file rewrite via mdformat

### Retrieval
- **Modes:** SQLite FTS (text) + sqlite-vec (dense embeddings); filtering by frontmatter (type, tags, permalink), date ranges, and graph distance via `[[links]]`
- **Reranker:** **none** — light stack; relies on FTS rank + vector score; no Cohere/BGE/HF reranker class
- **Top-k defaults:** configurable per MCP query
- **Context assembly:** notes are returned with their observation lists and relation neighborhoods

### Memory model
- **Tiers:** notes (raw markdown) + observations (structured statements inside a note) + relations (typed edges via `[[links]]`) + frontmatter metadata
- **Bi-temporal:** **no** — git provides history if you commit your vault
- **Self-update mechanism:** **bidirectional** — files watched, DB rebuilt automatically; LLM writes through MCP, file change re-syncs
- **Decay / forgetting:** **none** — files persist forever (delete is explicit)
- **Files-as-truth:** unique to this cohort entry — DB is *cache*, not record

### MCP / connectors
- **MCP server exposed:** **yes** — primary interface; `fastmcp>=3.0.1` in core deps; default surface for Claude Desktop / Cursor / Codex
- **MCP client used:** **no** — basic-memory is the backend
- **Native connectors:** **4 conversation-export importers** under [`src/basic_memory/importers/`](https://github.com/basicmachines-co/basic-memory/tree/main/src/basic_memory/importers): `chatgpt_importer.py`, `claude_conversations_importer.py`, `claude_projects_importer.py`, `memory_json_importer.py`. (All conversation-shaped — no document importers like Notion/Joplin.)
- **Smithery / discovery:** ships `smithery.yaml`, `server.json`, `skills-lock.json` — listed in [Smithery's MCP catalog](https://smithery.ai/) for one-click install
- **Tool-call surface:** MCP tools for read / write / search / list / move / link

### Notable design choices
- **AGPL-3.0-or-later license** — most copyleft of this cohort; intentionally hostile to closed-source SaaS forks
- **Files are the contract** — `git add notes/` works because the data IS the markdown; vendor lock is structurally impossible
- **Rule-based extraction over LLM extraction** — predictable, free, and the structure is meaningful to humans (you can edit it manually)
- **sqlite-vec + fastembed in core, not as an extra** — embeddings are first-class, local, no API key
- **Smithery-first distribution** — ships the metadata for one-click install in MCP marketplaces
- **Postgres is opt-in for multi-user / shared deployments** (docker-compose-postgres.yml)
- **NOTE-FORMAT.md is a binding spec** — the syntax for observations and relations is documented and stable

## Dependencies (KB-relevant)

From `pyproject.toml` (core):

```
mcp>=1.23.1                   fastmcp>=3.0.1   # MCP runtime
sqlalchemy>=2.0               aiosqlite        # default index
psycopg==3.3.1   asyncpg      # postgres opt-in
alembic>=1.14                 # migrations
markdown-it-py>=3.0           python-frontmatter>=1.1   # parsing
mdformat + mdformat-gfm + mdformat-frontmatter   # bidirectional rewrite
fastembed>=0.7                # local embeddings (ONNX)
sqlite-vec>=0.1.6             # in-SQLite vector index
watchfiles>=1.0               # file→DB sync
fastapi[standard]             # HTTP API
typer + rich                  # CLI
logfire>=4.19                 # telemetry
openai>=1.100                 # optional LLM provider
```

`docker-compose.yml` ships SQLite-only mode; `docker-compose-postgres.yml` ships Postgres mode.

## Tradeoffs

**Pros:**
- **Data ownership is structural** — you own a folder of markdown; no DB blobs to extract
- **No LLM cost on ingest** — rule-based extraction means free, reproducible
- **Embeddings + FTS without a separate service** — sqlite-vec runs in-process
- **Git-friendly by construction** — version your vault, branch your knowledge
- **Smallest stack of any surveyed memory framework** — single binary path, no Docker required for default mode
- **Readable by humans** — observations + relations format is just markdown you'd happily write yourself

**Cons:**
- **No LLM atomic-fact extraction** — if your data is conversation messages or unstructured text, you'll need to pre-process; basic-memory expects structured markdown
- **Single-user / single-machine in design** — Postgres mode helps for shared use but the "files are the truth" model doesn't generalize to multi-tenant SaaS cleanly
- **No reranker** — retrieval quality plateaus at FTS + vector with no learned reordering
- **AGPL-3.0** — fine for personal use and open-source services; complicates internal-tool deployment in many enterprises
- **Markdown is the only input** — importers help, but a "drop in arbitrary documents" path requires you to write the importer

## When to use it

- **Good fit:** personal-knowledge-management for AI-assisted thinkers; Obsidian-style writers who want LLM read+write; researchers/PIs who want their lab notes git-versioned and AI-readable; teams with one shared markdown repo
- **Bad fit:** SaaS products with arbitrary user content; multi-tenant deployments at scale; workloads needing LLM-based fact extraction from raw chats
- **Closest alternative (in this cohort):** none — basic-memory is the only "files-as-truth" entry. The closest peers outside this cohort are Obsidian + LLM plugins, but those don't ship the MCP surface end-to-end. **graphiti** is the opposite end of the spectrum (graph-as-truth with bi-temporal audit).

## Code pointers (evidence)

- Markdown parser: `src/basic_memory/markdown/`
- Sync engine: `src/basic_memory/sync/` (uses `watchfiles`)
- DB models + repos: `src/basic_memory/{models,repository}/`
- MCP server: `src/basic_memory/mcp/`
- CLI: `src/basic_memory/cli/main.py` (entry: `bm`)
- Importers (4): [`src/basic_memory/importers/`](https://github.com/basicmachines-co/basic-memory/tree/main/src/basic_memory/importers) — `chatgpt_importer.py`, `claude_conversations_importer.py`, `claude_projects_importer.py`, `memory_json_importer.py`
- Note format spec: top-level `NOTE-FORMAT.md`
- Most useful single file to read first: `NOTE-FORMAT.md` — defines the observation/relation grammar that drives the entire pipeline

## Open questions

- Performance ceiling on the watchfiles loop — at how many notes does the re-sync latency become noticeable? The `test_sync_performance_benchmark.py` likely answers but wasn't read.
- Conflict-resolution policy when both the LLM (via MCP) and a human edit the same file simultaneously — markdown-merge or last-write-wins?
- The bidirectional rewrite uses `mdformat` — does it preserve trailing whitespace, comment placement, and idiosyncratic formatting? (Round-trip purity matters for git diff-readability.)

---

*Surveyed via the `curating-agentic-kbs` skill. Re-survey scheduled after 30 days of last `pushed_at` change.*

*Audit 2026-05-02: clone-verified against [`pyproject.toml`](https://github.com/basicmachines-co/basic-memory/blob/main/pyproject.toml), [`src/basic_memory/importers/`](https://github.com/basicmachines-co/basic-memory/tree/main/src/basic_memory/importers), `NOTE-FORMAT.md`, `smithery.yaml`, `server.json`, `skills-lock.json`. **Correction:** importer list — survey listed `chatgpt / claude_export / notion / joplin`; actual files are `chatgpt_importer / claude_conversations_importer / claude_projects_importer / memory_json_importer` (4 conversation-shape importers, no Notion or Joplin). **Verified:** AGPL-3.0-or-later license, core deps (mcp `>=1.23.1`, fastmcp `>=3.0.1`, sqlite-vec `>=0.1.6`, fastembed `>=0.7.4`, watchfiles `>=1.0.4`, markdown-it-py `>=3.0`, python-frontmatter `>=1.1`, psycopg `==3.3.1` exact pin, mdformat + mdformat-gfm + mdformat-frontmatter, logfire `>=4.19`, aiosqlite `>=0.20`), Smithery distribution files, `NOTE-FORMAT.md` spec exists. Version is dynamic via `uv-dynamic-versioning` (no static version in pyproject).*
