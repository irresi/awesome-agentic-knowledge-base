# Recipe 03 — "Ask my codebase," persistent across sessions

> Coding agent that builds and persists a map of your repo so a fresh session
> never re-explains the codebase. Survives refactors.

## Data flow

| # | Input | Transform | Output | Status |
|---|---|---|---|---|
| 1 | Local repo + git pushes | GitNexus parses with Tree-sitter (11 languages via config-driven extractor files, plus a separate COBOL processor); staleness tracked via git-commit-hash diff (full re-analyze on drift; per-file incremental indexing is on the README roadmap, not yet shipped) | Code graph in **LadybugDB** (CLI: native persistent; web: WASM in-memory) — note: GitNexus is **PolyForm Noncommercial 1.0.0**, not OSS-permissive: nodes (files / classes / functions / methods), edges (calls / imports / contains) | 🟡 |
| 2 | Markdown / docstring-bearing source / READMEs (LightRAG ingests text + markdown out of the box; pulling docstrings/comments out of source files requires your own pre-extraction step — LightRAG has no built-in docstring parser) | LightRAG indexes the prose layer alongside the structural graph; pick a query mode (`local` / `global` / `hybrid` / `mix` / `naive` / `bypass`) | Hybrid retrieval: structural query first (GitNexus MCP), semantic fallback (LightRAG REST / Ollama-compatible API) | 🟡 |
| 3 | Coding session in Claude Code (also Cursor / OpenCode / OpenClaw — claude-mem is Claude-Code-lifecycle-coupled, not generic) | claude-mem's `Stop` hook runs the `summarize` handler that calls Claude Agent SDK to extract typed observations (`facts` / `narrative` / `concepts` / `files_read` / `files_modified` — note: NO `decisions` type); rows land in SQLite, embeddings in ChromaDB (over stdio MCP). Worker exposes a `POST /api/search` HTTP endpoint on `:37777`. Decision-shaped content has to surface implicitly inside `narrative` / `concepts` since there's no decisions primitive. | Persistent session memory the next session can query via the bundled `search` MCP tool or the `mem-search` skill | 🟢 |
| 4 | MCP query from Claude Code / Cursor / Cline | GitNexus already ships its own MCP server with 22 tools (stdio + HTTP transports) — no ~100-LoC wrapper needed; claude-mem ships an MCP server with `search` / `timeline` / `get_observations` tools (the verbatim tool name is `search`, not `session_search`) | Two MCP servers available across coding agents — code structure (GitNexus) + cross-session memory (claude-mem) | 🟢 |

## Build path

1. **Generate code graph** — `gitnexus analyze` writes the LadybugDB store. Add a Git post-commit hook to call `gitnexus analyze` on each commit (full re-analyze; per-file incremental is roadmap). **Verify the PolyForm Noncommercial 1.0.0 license fits your use case** before depending on it.
2. **Index prose** — point LightRAG at `*.md` / READMEs / any pre-extracted docstrings file you build yourself; LightRAG ships PDF/DOCX/MD ingestion but not a Python/JS docstring extractor — that's your script. Pick a default query mode (e.g. `mix`) for the semantic layer.
3. **Capture sessions** — install claude-mem from the Claude Code marketplace; the plugin's `hooks.json` registers itself on `SessionStart` / `UserPromptSubmit` / `PostToolUse` / `PreToolUse` / `Stop` (no `SessionEnd` hook in claude-mem). Phrase decision-shaped content explicitly ("we decided to use X over Y because Z") so it ends up inside `narrative` / `concepts` (claude-mem has no first-class `decisions` type).
4. **Wire MCP** — GitNexus's MCP server (22 tools) and claude-mem's MCP server are both already shippable; register both in `~/.claude/settings.json` (or your IDE's MCP config). No custom wrapper required.

## Why this combo

Graph-based retrieval beats vector chunks across refactors — moving a file doesn't break a graph node, just an edge. claude-mem turns prior sessions into a queryable artifact instead of context-window pollution; "decision log" is a usage pattern (prompt the conversation toward "we decided X" phrasing), not a typed claude-mem primitive. MCP makes this portable to Claude Code, Cursor, and Cline simultaneously without three integrations. (fast-graphrag is a tempting alternative, but it's designed for LLM-extracted natural-language KGs over documents — domain + entity_types priming + PPR over chunks — not for pre-built code graphs, and the repo has been stagnant since 2025-11-01 at v0.0.5.)

## Glue you write

- Git post-commit hook that calls `gitnexus analyze` (per-file incremental indexing isn't shipped yet; full re-analyze on each commit is the supported path)
- A small docstring/comment extractor (Python `ast` / TypeScript compiler API) that emits markdown LightRAG can ingest — LightRAG itself only ingests text/markdown/PDF/DOCX, not raw source code
- Two MCP server registrations in `~/.claude/settings.json` (GitNexus + claude-mem) — both are already shippable
- Conversation phrasing convention to surface decisions inside claude-mem's `narrative` / `concepts` observations (no `decisions` type exists)

## Signal

`needs.md` Scenario 3 — Strong (Brifly, Hmem, RemembrallMCP, Loom — all HN Shows in Feb–Apr 2026 doing this exact shape).
