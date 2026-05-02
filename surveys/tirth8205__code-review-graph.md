# Survey: tirth8205/code-review-graph

**Date:** 2026-05-02
**Stars:** 14,539 · **Last push:** 2026-04-21 · **Created:** 2026-02-26
**Category:** wiki-compiler
**Slug:** [tirth8205/code-review-graph](https://github.com/tirth8205/code-review-graph)

---

## TL;DR (3 lines)

- **What it is:** Python tool (PyPI: `code-review-graph`) that builds a **persistent, incrementally-updated knowledge graph** of your codebase using Tree-sitter and exposes it via **22 MCP tools + 5 prompts** (FastMCP, stdio). Pitched as "stop burning tokens" — claims 8.2× average token reduction across 6 real repos. MIT, by Tirth Kanani.
- **How its KB works:** Tree-sitter parses **32 languages** (including Vue SFC, Solidity, Dart, R, Perl, Lua, Jupyter/Databricks notebooks) → SQLite-backed graph store with BFS impact analysis → optional embeddings (sentence-transformers / Google Gemini / MiniMax) → **FTS5 hybrid search (keyword + vector)** → MCP tools deliver minimal-context responses with `next_tool_suggestions` field hinting the optimal next call. **Auto-installs MCP config** into 11 AI coding tools.
- **Verdict:** Pick when you want a **token-efficient codebase KG** that drops into Claude Code / Cursor / Codex / Windsurf / Zed / Continue / OpenCode / Antigravity / Qwen / Qoder / Kiro with one `code-review-graph install` command. Skip if you want a server-shaped wiki (use deepwiki-open) or a Claude-Code-plugin-shaped wiki (use Understand-Anything).

## KB Architecture

### Storage
- **Vector store:** **SQLite + FTS5** (full-text search) + optional vector embeddings stored in SQLite (Python `sentence-transformers` local, Google Gemini API, or MiniMax API). Hybrid search merges FTS5 keyword + vector cosine.
- **Graph store:** **SQLite-backed graph** ([`code_review_graph/graph.py`](https://github.com/tirth8205/code-review-graph/blob/main/code_review_graph/graph.py)) — nodes + edges with BFS impact analysis. Plus **Leiden community detection** for architecture overview (cohort second after graphrag).
- **Metadata / structured:** SQLite (single file, single binary).
- **Object / blob:** Generated D3.js HTML graphs in `visualization.py`.

### Ingestion / Extraction
- **Source types accepted:** **32 languages via Tree-sitter** — per [`EXTENSION_TO_LANGUAGE` in `code_review_graph/parser.py`](https://github.com/tirth8205/code-review-graph/blob/main/code_review_graph/parser.py): bash, c, cpp, csharp, dart, elixir, gdscript, go, java, javascript, julia, kotlin, lua, luau, notebook (`.ipynb`), objc, perl, php, powershell, python, r, rescript, ruby, rust, scala, solidity, svelte, swift, tsx, typescript, vue, zig. Plus a `_parse_databricks_py_notebook` sub-parser for `.py` Databricks notebooks. Cohort second-largest tree-sitter language coverage (after aider's ~41 across two query dirs). (Upstream README advertises "23 languages + notebooks" — the dict in code includes additional grammars beyond the marketing list.)
- **Chunking strategy:** **AST-driven** — tree-sitter parses produce structural nodes (file / class / function / method) without arbitrary chunking; LLM only sees the structural graph, not raw bytes.
- **Entity / fact extraction:** **Mechanical (tree-sitter)** as primary; LLM is only used at *query time* for description/summarization, not extraction. Cohort first to be tree-sitter-only at extraction time and LLM-only at query time.
- **Schema:** Nodes (file / class / function / module) + edges (calls / inherits / imports / uses) + flows (execution paths with criticality scoring) + communities (Leiden-detected clusters).

### Retrieval
- **Modes:** **Hybrid FTS5 keyword + vector** ([`code_review_graph/search.py`](https://github.com/tirth8205/code-review-graph/blob/main/code_review_graph/search.py)). Plus graph-traversal queries (`query_graph` MCP tool with target). Plus BFS impact analysis (`get_impact`).
- **Reranker:** None — designed for *minimal context*, not high-recall.
- **Top-k defaults:** Per-tool minimal default (~5 results). MCP responses include `detail_level=minimal` flag (target: ≤800 tokens of graph context per task).
- **Context assembly:** **`get_minimal_context(task="…")` returns ~100 tokens** as the bootstrap call; subsequent calls use `detail_level="minimal"` by default. Each response includes a **`next_tool_suggestions`** field guiding the agent toward the optimal next tool.

### Memory model
- **Tiers:** Single graph state (per-repo `.code-review-graph/` directory or similar). No conversational memory.
- **Bi-temporal:** No — but git-based incremental change tracking ([`incremental.py`](https://github.com/tirth8205/code-review-graph/blob/main/code_review_graph/incremental.py)) gives "what changed since the last build" semantics.
- **Self-update mechanism:** **Git-based change detection** + **file watching** (`watch` CLI command runs as a daemon). `detect-changes` CLI subcommand performs risk-scored change impact analysis ([`changes.py`](https://github.com/tirth8205/code-review-graph/blob/main/code_review_graph/changes.py)).
- **Decay / forgetting:** None — graph is rebuilt incrementally from current git state.

### MCP / connectors
- **MCP server exposed:** **Yes — 22 MCP tools + 5 prompts** via FastMCP stdio transport ([`code_review_graph/main.py`](https://github.com/tirth8205/code-review-graph/blob/main/code_review_graph/main.py)). Tools include `get_minimal_context`, `query_graph`, `list_*` family, `detect_changes`, `get_impact`, refactor tools (`rename_preview`, `dead_code`, `refactoring_suggestions`).
- **MCP client used:** No — it's a server.
- **Native connectors:** **Auto-installs into 11 AI coding tools** — `code-review-graph install` auto-detects Codex, Claude Code, Cursor, Windsurf, Zed, Continue, OpenCode, Antigravity, Qwen, Qoder, and Kiro, writes MCP config + injects "graph-aware instructions" into platform rules. Cohort first to ship as a one-command-installable MCP server with auto-config-writer for 11 AI tools.
- **Tool-call surface:** 22 MCP tools + CLI subcommands (`install`, `build`, `update`, `watch`, `status`, `visualize`, `serve`, `wiki`, `detect-changes`, `register`, `unregister`, `repos`, `eval`). VS Code extension at `code-review-graph-vscode/`.

### Notable design choices
- **Token-efficiency as the entire product thesis** — `get_minimal_context()` ~100 tokens, target ≤5 tool calls per task, ≤800 total tokens of graph context. Every response carries `next_tool_suggestions` to guide the agent. Cohort first to ship token efficiency as the headline metric (8.2× claimed reduction).
- **MCP-config-writer for 11 AI tools** — closest cohort analogue is byterover-cli's MCP-config-writer (3 tools); this is the broadest auto-install in cohort.
- **19-language tree-sitter coverage** — second-largest in cohort after aider, *includes notebooks* (Jupyter, Databricks) which other tree-sitter users don't.
- **Mechanical extraction at build time + LLM at query time** — inverse of repos that LLM-extract at ingest. Saves cost and is deterministic.
- **Leiden community detection** for architecture overview — cohort second after graphrag.
- **Refactor module** ([`code_review_graph/refactor.py`](https://github.com/tirth8205/code-review-graph/blob/main/code_review_graph/refactor.py)) — `rename_preview`, `dead_code` detection, `refactoring_suggestions`. Cohort first to ship refactor primitives as MCP tools.
- **Daemon + file watcher** — `watch` CLI runs `incremental.py` continuously; graph stays fresh without manual rebuilds.
- **PyPI distribution** — `pip install code-review-graph` or `pipx` or `uvx`. Single Python package.
- **5 README languages** — EN / 中文 / 日本語 / 한국어 / हिन्दी (cohort first to ship Hindi).
- **AGENTS.md + CLAUDE.md + GEMINI.md** — three host-specific guidance files, signaling "first-class on multiple hosts".
- **VS Code extension** in `code-review-graph-vscode/` subdir.
- **MIT** — pure permissive.

## Dependencies (KB-relevant)

From the README and CLAUDE.md (no `pyproject.toml` at repo root; package metadata on PyPI):

```
Python >= 3.10
tree-sitter (19 language grammars)
sqlite + FTS5 (built-in)
fastmcp                                  # MCP server
sentence-transformers (optional)         # local embeddings
google-generativeai (optional)           # Gemini embeddings
minimax (optional)                       # MiniMax embeddings
networkx (likely)                        # graph algorithms
python-leidenalg (likely)                # Leiden community detection
gitpython                                # incremental change detection
watchdog                                 # file watcher
d3.js (frontend asset for visualize)
```

License: **MIT**.

## Tradeoffs

**Pros:**
- **Token-efficiency as the design point** — measured 8.2× reduction is rare in cohort to be a *primary* metric.
- **Auto-MCP-install for 11 AI tools** — drops "wire this into Cursor / Codex / Windsurf / …" friction to a single command.
- **32 languages incl. Vue SFC, Solidity, Jupyter, Databricks notebooks, gdscript, luau, rescript** — broader than aider's tree-sitter pack on certain niches.
- **Dual BFS engine** for impact analysis — SQLite recursive-CTE by default (`get_impact_radius_sql`, faster on large graphs); legacy NetworkX Python-side BFS available via `CRG_BFS_ENGINE=networkx` env override. Cohort first to ship a switchable graph-traversal backend.
- **Refactor primitives** (rename preview, dead code detection, suggestions) — uncommon cohort feature.
- **`next_tool_suggestions` field** — guides the agent toward optimal next call, reducing wasted tool invocations.
- **Daemon + file watcher** — graph stays fresh without manual rebuilds.
- **Single `pip install` distribution** — easiest install in the wiki-compiler category.
- **AGENTS.md + CLAUDE.md + GEMINI.md** — explicit host coverage.

**Cons:**
- **Created 2026-02-26** — only 2 months old at survey time. ★14k in 2 months is rapid; sustained development trajectory unproven.
- **Single-author project** — bus factor 1.
- **No conversational memory** — single graph per repo, no per-user/session.
- **Embedding tier is optional** — works without embeddings (FTS5 only), but vector quality depends on user provisioning Gemini/MiniMax/local model.
- **MIT + closed-host integrations** — auto-installer modifies host configs (Cursor / Codex / etc.); behavior depends on those hosts' MCP support.
- **Files like `AGENTS 2.md`, `analysis 2.py`, `enrich 2.py`, `enrich 3.py`** in the repo — looks like editor-duplicate-on-save artifacts that snuck into git. Code-hygiene concern.
- **Heavy claims with single-author validation** — 8.2× reduction across 6 repos; replication harness exists at `eval/` but third-party benchmarks not yet visible.

## When to use it

- **Good fit:** teams using AI coding tools (Cursor / Claude Code / Codex / Windsurf / Continue / Zed / etc.) who want one shared codebase KG with one-command MCP install; codebases in 19+ languages that benefit from Leiden community detection + flow analysis; products that care about LLM token cost as a primary metric.
- **Bad fit:** server-tier wikis (use deepwiki-open); plugin-shape wikis with privacy-preserving filePath sanitization (use Understand-Anything); teams that need multi-author maturity and an established trajectory.
- **Closest alternative:** [`Lum1104/Understand-Anything`](surveys/Lum1104__Understand-Anything.md) — also a codebase wiki-compiler, plugin-shape vs CLI-shape; UA has 35-edge Zod-validated KG vs CRG's SQLite graph + FTS5. [`AsyncFuncAI/deepwiki-open`](surveys/AsyncFuncAI__deepwiki-open.md) is the server-shape alternative; [`Aider-AI/aider`](surveys/Aider-AI__aider.md)'s tree-sitter PageRank repo-map shares the "structural map for token efficiency" idea but is internal to aider's chat loop, not exposed as MCP.

## Code pointers (evidence)

- Tree-sitter parser (32 languages incl. notebooks): [`code_review_graph/parser.py`](https://github.com/tirth8205/code-review-graph/blob/main/code_review_graph/parser.py) — see `EXTENSION_TO_LANGUAGE` dict + `_parse_databricks_py_notebook`
- SQLite-backed graph + dual-engine BFS impact analysis (SQL default `get_impact_radius_sql`; NetworkX legacy via `CRG_BFS_ENGINE=networkx`): [`code_review_graph/graph.py:597-744`](https://github.com/tirth8205/code-review-graph/blob/main/code_review_graph/graph.py#L597-L744) + [`code_review_graph/constants.py:22-23`](https://github.com/tirth8205/code-review-graph/blob/main/code_review_graph/constants.py#L22-L23)
- Leiden community detection (`g.community_leiden(...)` with `n_iterations=2` cap, resolution scaled inversely with graph size): [`code_review_graph/communities.py:222-313`](https://github.com/tirth8205/code-review-graph/blob/main/code_review_graph/communities.py#L222-L313)
- FTS5 virtual table DDL (`CREATE VIRTUAL TABLE nodes_fts USING fts5(...)`): [`code_review_graph/migrations.py:148-157`](https://github.com/tirth8205/code-review-graph/blob/main/code_review_graph/migrations.py#L148-L157)
- 22 MCP tools: [`code_review_graph/tools.py`](https://github.com/tirth8205/code-review-graph/blob/main/code_review_graph/tools.py)
- FastMCP server entry point + 5 prompts: [`code_review_graph/main.py`](https://github.com/tirth8205/code-review-graph/blob/main/code_review_graph/main.py)
- Incremental git-based change detection + file watching: [`code_review_graph/incremental.py`](https://github.com/tirth8205/code-review-graph/blob/main/code_review_graph/incremental.py)
- Optional embeddings (sentence-transformers / Gemini / MiniMax): [`code_review_graph/embeddings.py`](https://github.com/tirth8205/code-review-graph/blob/main/code_review_graph/embeddings.py)
- D3.js HTML graph viz: [`code_review_graph/visualization.py`](https://github.com/tirth8205/code-review-graph/blob/main/code_review_graph/visualization.py)
- Flow detection + criticality scoring: [`code_review_graph/flows.py`](https://github.com/tirth8205/code-review-graph/blob/main/code_review_graph/flows.py)
- Leiden community detection + file-based grouping: [`code_review_graph/communities.py`](https://github.com/tirth8205/code-review-graph/blob/main/code_review_graph/communities.py)
- FTS5 hybrid search: [`code_review_graph/search.py`](https://github.com/tirth8205/code-review-graph/blob/main/code_review_graph/search.py)
- Risk-scored change impact: [`code_review_graph/changes.py`](https://github.com/tirth8205/code-review-graph/blob/main/code_review_graph/changes.py)
- Refactor primitives (rename / dead-code / suggestions): [`code_review_graph/refactor.py`](https://github.com/tirth8205/code-review-graph/blob/main/code_review_graph/refactor.py)
- CLI subcommands (install / build / update / watch / status / visualize / serve / wiki / detect-changes / register / unregister / repos / eval): [`code_review_graph/cli.py`](https://github.com/tirth8205/code-review-graph/blob/main/code_review_graph/cli.py)
- VS Code extension: [`code-review-graph-vscode/`](https://github.com/tirth8205/code-review-graph/tree/main/code-review-graph-vscode)
- Most useful single file to read first: [`CLAUDE.md`](https://github.com/tirth8205/code-review-graph/blob/main/CLAUDE.md) — explicit token-efficiency guidance + tool-usage rules + architecture overview.

## Open questions

- "8.2× token reduction" — what's the test methodology? `eval/` directory exists; worth a deeper look.
- File duplicates (`AGENTS 2.md`, `analysis 2.py`, `enrich 2.py`, `enrich 3.py`) — are these accidentally checked-in or intentional version variants?
- ★14k in 2 months — is the trajectory organic? Other star-spike-pattern repos in our queue triggered red flags; CRG's growth pattern is plausible (clear value prop, broad host coverage, clean docs) but worth tracking.
- Daemon mode UX — does the watcher need explicit start/stop, or auto-runs on system startup?
- Refactor module — what's the precision/recall on dead-code detection compared to existing tools (vulture, ruff)?
- 5 host-config-writer paths (`install` for 11 AI tools) — what's the testing matrix? How does it handle conflicting MCP configs?

---

*Surveyed via the `curating-agentic-kbs` skill. Re-survey scheduled after 30 days of last `pushed_at` change.*

*Audit 2026-05-02: clone-verified against [`parser.py`](https://github.com/tirth8205/code-review-graph/blob/main/code_review_graph/parser.py), [`graph.py`](https://github.com/tirth8205/code-review-graph/blob/main/code_review_graph/graph.py), [`communities.py`](https://github.com/tirth8205/code-review-graph/blob/main/code_review_graph/communities.py), [`search.py`](https://github.com/tirth8205/code-review-graph/blob/main/code_review_graph/search.py), [`constants.py`](https://github.com/tirth8205/code-review-graph/blob/main/code_review_graph/constants.py), [`migrations.py`](https://github.com/tirth8205/code-review-graph/blob/main/code_review_graph/migrations.py). **Corrections:** language count **19 → 32** (initial draft used the outdated diagram alt-text from upstream README, which itself claims 23; the actual `EXTENSION_TO_LANGUAGE` dict in `parser.py` has 32 entries); added **dual-BFS-engine** detail (SQL default + NetworkX legacy via `CRG_BFS_ENGINE`) and Leiden `n_iterations=2` cap. **Verified:** BFS impact analysis (`get_impact_radius`), Leiden via `g.community_leiden`, FTS5 hybrid (`nodes_fts` virtual table), embedder providers (sentence-transformers / Gemini / MiniMax), MIT license.*
