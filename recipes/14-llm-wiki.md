# Recipe 14 — Self-maintaining LLM Wiki (Karpathy pattern)

> Agent that ingests anything you drop in (URLs, PDFs, transcripts) and
> maintains a hand-readable interlinked markdown wiki that's always up to date.

## Data flow

| # | Input | Transform | Output | Status |
|---|---|---|---|---|
| 1 | URL `.txt` / PDF / transcript dropped in `~/wiki-inbox/` | `fswatch` or Python `watchdog` daemon detects new file → SurfSense web-crawler (for URLs) or DocsGPT-style PDF parse → normalize to markdown into `_pending/` subfolder | Pending markdown files queued for ingest | 🔴 |
| 2 | Pending markdown | basic-memory accepts as freeform markdown with `[[Wiki Links]]` relations + observation grammar (`- [tag] statement`); markdown IS the database (no separate index store) | basic-memory vault, hand-readable + queryable | 🟢 |
| 3 | Pending file + existing vault | launchd plist (or cron) spawns Claude Code session every N minutes pointing at the vault. claude-obsidian's `/wiki` skill reads `_pending/`, drills into related vault pages via `[[Wiki Links]]` traversal + Markdown grep (no vector store native), decides *merge* / *create* / *split*, and edits markdown with `[[Wiki Links]]`. `PostToolUse[Write\|Edit]` hook git-auto-commits each wiki write (`wiki: auto-commit YYYY-MM-DD HH:MM`); `Stop` hook rewrites `wiki/hot.md` (Last Updated / Key Recent Facts / Recent Changes / Active Threads, ≤500 words); `SessionStart` hook reads `wiki/hot.md` so next session inherits context. | Updated vault pages + agent-log entries; pending folder drained | 🟢 |
| 4 | User question | claude-obsidian's `/wiki-query` skill answers from the vault between maintenance runs (hot-cache + index scan + drill-down via wikilink traversal — no vector retrieval by default; optional DragonScale Memory extension adds semantic tiling) | Answer in Obsidian | 🟢 |

## Build path

1. **Drop zone + watcher** — `fswatch` or `watchdog` (~50 LoC) watches `~/wiki-inbox/`; routes URLs to SurfSense web-crawler, PDFs to DocsGPT-style parser. Output to `_pending/`.
2. **Vault** — basic-memory's vault is the canonical wiki. YAML frontmatter (`tags`, `sources`, `updated`) + `[[Wiki Links]]` for relations.
3. **Maintainer agent** — launchd plist on macOS (or cron on Linux) fires a Claude Code session pointing at the vault; claude-obsidian's `/wiki` skill does the merge/create/split decision and edits.
4. **Quick lookup** — `/wiki-query` skill for ad-hoc questions outside the maintenance window.

## Why this combo

Karpathy's pattern explicitly rejects chunked RAG over raw notes — the *synthesis* into pages is the point. basic-memory + claude-obsidian nail this: claude-obsidian is purpose-built around Karpathy's LLM-wiki pattern (`/wiki`, `/wiki-query`, `SessionStart`/`Stop` hooks for state), and basic-memory provides the markdown-first vault those skills edit. Note: claude-mem (which we considered) is a Claude Code lifecycle-hook plugin for *capturing* sessions, not for cron-driven file edits — wrong primitive for this loop. SamurAIGPT/llm-wiki-agent and NicholasSpisak/second-brain implement equivalent loops; both are valid alternatives if you'd rather fork than wire claude-obsidian.

## Glue you write

- Drop-zone watcher (`fswatch` or Python `watchdog`, ~50 LoC) — the only meaningfully custom piece
- Maintainer-agent prompt with merge/create/split decision rules (or extend claude-obsidian's `/wiki` skill prompt)
- launchd plist on macOS (or cron on Linux) firing the maintainer Claude Code session

## Signal

`needs.md` Scenario 14 — Strong (Karpathy original tweet, multiple GitHub forks: SamurAIGPT, NicholasSpisak, eugeniughelbur, plus aimaker.substack walkthrough).
