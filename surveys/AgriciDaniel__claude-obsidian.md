# Survey: AgriciDaniel/claude-obsidian

**Date:** 2026-05-02
**Stars:** 3,864 · **Last push:** 2026-04-24 · **Created:** 2026-04-07
**Category:** wiki-compiler
**Slug:** [AgriciDaniel/claude-obsidian](https://github.com/AgriciDaniel/claude-obsidian)

---

## TL;DR (3 lines)

- **What it is:** Claude Code plugin + Obsidian vault that implements **[Andrej Karpathy's "LLM Wiki" pattern](https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f)**. MIT, by AgriciDaniel (AI Marketing Hub). The repo *is* the Obsidian vault — open it directly in Obsidian. Pitched as "running notetaker" — Claude reads sources, extracts entities/concepts, files into structured Obsidian Markdown with wikilinks, maintains the wiki autonomously.
- **How its KB works:** **11 skills (SKILL.md)** + **4 commands** + **2 agents** (`wiki-ingest`, `wiki-lint`) + **4-event hooks** (`SessionStart` / `PostCompact` / `PostToolUse[Write|Edit]` / `Stop`). **Hot cache pattern**: `wiki/hot.md` is read at session start and rewritten at session end with a structured summary (Last Updated / Key Recent Facts / Recent Changes / Active Threads, ≤500 words). **Git auto-commits** on every wiki write via `PostToolUse` hook. **No DB, no vector store** — pure Obsidian Markdown files.
- **Verdict:** Pick when you want a **Claude-Code-plugin-shaped Obsidian-vault knowledge base** following Karpathy's LLM-wiki methodology — `/wiki`, `/wiki-ingest`, `/wiki-query`, `/wiki-lint`, `/save`, `/autoresearch`, `/canvas` skills give you autonomous wiki maintenance. Skip if you want a server-shaped wiki (use deepwiki-open) or a code-graph-shaped wiki (use Understand-Anything / code-review-graph).

## KB Architecture

### Storage
- **Vector store:** *None native.* Optional [DragonScale Memory](https://github.com/AgriciDaniel/claude-obsidian/blob/main/docs/dragonscale-guide.md) extension adds "log folds, deterministic page addresses, semantic tiling lint, boundary-first autoresearch" — but the base setup is filesystem-only.
- **Graph store:** **Obsidian's native graph view** of wikilinks. Cohort first to lean on Obsidian's graph as the visualization layer.
- **Metadata / structured:** Markdown files in `wiki/` with YAML frontmatter; raw sources cached in `.raw/`; vault metadata in `.vault-meta/` (git-added by the auto-commit hook); Obsidian Templater files in `_templates/`.
- **Object / blob:** Filesystem; assets in `wiki/meta/` (gif covers, images, canvas) plus `_attachments/` for images and PDFs referenced by wiki pages (per [`CLAUDE.md`](https://github.com/AgriciDaniel/claude-obsidian/blob/main/CLAUDE.md) and [`WIKI.md`](https://github.com/AgriciDaniel/claude-obsidian/blob/main/WIKI.md) vault-structure docs).

### Ingestion / Extraction
- **Source types accepted:** Files, URLs, and batch inputs via the **`wiki-ingest`** skill. Triggers on natural-language phrases: "ingest", "process this source", "add this to the wiki", "read and file this", "batch ingest", "ingest all of these", "ingest this url". Plus `defuddle` skill for cleaning content from arbitrary URLs.
- **Chunking strategy:** None — sources become wiki pages with cross-references; "a single source typically touches 8-15 wiki pages."
- **Entity / fact extraction:** **LLM-driven during ingest** — Claude reads the source, extracts entities + concepts, creates or updates wiki pages, builds cross-references via `[[Wikilinks]]`. Notes the agent uses "Obsidian Flavored Markdown": `[[Note Name]]`, `> [!type] Title` callouts, `![[file]]` embeds, YAML frontmatter for properties.
- **Schema:** **Obsidian Markdown is the schema.** Pages categorized by entity / concept / topic; links carry semantic relationships; callouts include **`[!contradiction]`** for sourced contradiction flagging.

### Retrieval
- **Modes:** **Hot cache + index scan + drill-down + synthesize.** Specifically: Claude reads `wiki/hot.md` (recent context), scans the index, drills into relevant pages, synthesizes an answer with **citations to specific wiki pages, not training data**. The `wiki-query` skill is the recall path.
- **Reranker:** None (Markdown grep / wikilink traversal).
- **Top-k defaults:** N/A — retrieval is graph-walk-shaped over wikilinks.
- **Context assembly:** **Hot cache is the context primitive.** Format: `Last Updated`, `Key Recent Facts`, `Recent Changes`, `Active Threads`. Capped at 500 words. **Overwritten** every session (cache, not journal).

### Memory model
- **Tiers:** **Hot cache** (`wiki/hot.md`) + **wiki pages** (everything else) + **raw sources** (`.raw/`). Cohort first to formalize a hot-cache-as-session-summary primitive.
- **Bi-temporal:** No formal bi-temporal model, but **git auto-commits** ("`wiki: auto-commit YYYY-MM-DD HH:MM`") give complete temporal history of every wiki write.
- **Self-update mechanism:** **Four hook events** drive autonomous maintenance:
  - `SessionStart[startup|resume]` — `cat wiki/hot.md` to restore recent context (silent, no announcement).
  - `PostCompact` — re-reads `wiki/hot.md` after Claude Code's context compaction, since hook-injected context doesn't survive compact.
  - `PostToolUse[Write|Edit]` — auto-commits wiki changes to git.
  - `Stop` (end of session) — checks if `wiki/` was modified; if yes, fires a prompt asking Claude to **rewrite `wiki/hot.md`** with the structured summary.
  - Cohort first to ship `PostCompact` hook handling — the only repo I've seen acknowledge that compaction destroys hook-injected context.
- **Decay / forgetting:** Hot cache is overwritten (not appended) at session end; older context lives only in wiki pages + git history.

### MCP / connectors
- **MCP server exposed:** **No.** Plugin uses Claude Code's native skill/agent/hook surface, not MCP.
- **MCP client used:** No.
- **Native connectors:** None network-side. Sources are local files or URLs (via the `defuddle` skill for cleaning).
- **Tool-call surface:** **11 skills** at [`skills/`](https://github.com/AgriciDaniel/claude-obsidian/tree/main/skills) — `autoresearch`, `canvas`, `defuddle`, `obsidian-bases`, `obsidian-markdown`, `save`, `wiki`, `wiki-fold`, `wiki-ingest`, `wiki-lint`, `wiki-query`. **4 slash commands** at [`commands/`](https://github.com/AgriciDaniel/claude-obsidian/tree/main/commands) (`autoresearch.md`, `canvas.md`, `save.md`, `wiki.md`). **2 sub-agents** at [`agents/`](https://github.com/AgriciDaniel/claude-obsidian/tree/main/agents) (`wiki-ingest.md`, `wiki-lint.md`).

### Notable design choices
- **The repo IS the vault** — open the GitHub clone directly in Obsidian; CLAUDE.md notes "This folder is both a Claude Code plugin and an Obsidian vault."
- **Karpathy's LLM Wiki pattern as the methodology** — explicit citation in README + ATTRIBUTION.md. First repo in cohort to be a *direct, named implementation* of Karpathy's pattern (other implementations exist in queue but this is the highest-star one).
- **Hot cache is the session continuity primitive** — `wiki/hot.md` is the only file Claude reads at SessionStart; it's the agent-side equivalent of git checkpointing for context.
- **`PostCompact` hook is unique in cohort** — explicitly handles the case where Claude Code's context compaction destroys hook-injected state. Only repo I've seen address this.
- **Git auto-commit on every Write|Edit** — `[ -d .git ] && git add wiki/ .raw/ .vault-meta/ 2>/dev/null && (git diff --cached --quiet || git commit -m "wiki: auto-commit $(date '+%Y-%m-%d %H:%M')" 2>/dev/null) || true`. Continuous-integration-shape commit cadence.
- **8-category lint** for wiki health — orphans, dead links, stale claims, missing cross-references, etc. (per README's comparison table); cohort first.
- **`[!contradiction]` callouts** — sourced contradiction flagging; wikis become contradiction-aware. Cohort first.
- **3-round autonomous research** — `autoresearch` skill runs multi-round web research with gap-filling. Sibling pattern to deepwiki-open's DeepResearch.
- **DragonScale Memory extension** ([docs/dragonscale-guide.md](https://github.com/AgriciDaniel/claude-obsidian/blob/main/docs/dragonscale-guide.md)) — opt-in extension with "log folds, deterministic page addresses, semantic tiling lint, boundary-first autoresearch". Naming nods to Karpathy's separately-maintained ideas.
- **AGENTS.md + CLAUDE.md + GEMINI.md** — three-host coverage signaling.
- **YouTube demo** — README links a video demo, rare in cohort.
- **MIT** — pure permissive.

## Dependencies (KB-relevant)

No `pyproject.toml` / `package.json` — this is a Claude Code plugin distributed as files. Dependencies are:
- **Claude Code** (or any host with Claude-Code-compatible skill/agent/hook loading).
- **Obsidian** for visualization (graph view, canvas, etc.).
- **git** for auto-commits.
- Optional: **kepano/obsidian-skills** plugin (deferred to as canonical Obsidian-markdown skill source).

License: **MIT**.

## Tradeoffs

**Pros:**
- **Pure-Markdown filesystem** — no DB, no vector store, no server. The wiki is just files. Diff-friendly, git-native, portable.
- **Hot cache as the session-continuity primitive** — solves "agent forgets between sessions" with a 500-word structured summary.
- **`PostCompact` hook handling** — only cohort entry that addresses Claude Code's context-compaction-loses-hook-state issue.
- **Git auto-commit** — every wiki write is versioned with timestamped messages.
- **Karpathy's LLM Wiki pattern** is a real methodology with public discussion — implementing it precisely is valuable for users buying into that paradigm.
- **`[!contradiction]` flagging + 8-category lint + 3-round autoresearch** — uncommon cohort features.
- **Obsidian visualizations come for free** — graph view, canvas, wiki map.
- **YouTube demo + clear blog post** — onboarding is unusually polished for a Claude Code plugin.

**Cons:**
- **Single-host (Claude Code)** — no MCP server means consumers outside Claude Code's plugin loader can't use it directly.
- **No vector retrieval** by default — drilldown via wikilinks works for small/medium vaults; large vaults may want hybrid search (DragonScale extension may address this).
- **Single-author project** (AgriciDaniel) — bus factor 1.
- **Obsidian-coupled** — losing Obsidian as a viewer takes away the graph/canvas/Map. The Markdown is portable but the experience isn't.
- **Hot cache as the continuity primitive has a 500-word ceiling** — long-running threads may need longer summaries.
- **Created 2026-04-07** — only 25 days old at survey time. ★3.9k in 25 days is rapid; trajectory worth tracking.
- **No formal entity/relation schema** — relies on LLM consistency at ingest time.

## When to use it

- **Good fit:** users wanting an Obsidian-vault-shaped LLM-wiki following Karpathy's pattern; Claude Code users who want a personal knowledge base that compounds via git commits; teams that prefer Markdown over DB-backed memory.
- **Bad fit:** non-Claude-Code hosts (use deepwiki-open or Understand-Anything for cross-host); vector-search-required deployments; large-scale multi-tenant SaaS.
- **Closest alternative:** [`Lum1104/Understand-Anything`](surveys/Lum1104__Understand-Anything.md) — same Claude-Code-plugin shape but for codebase analysis with Zod-validated 35-edge KG; claude-obsidian targets unstructured content into Obsidian Markdown. [`AsyncFuncAI/deepwiki-open`](surveys/AsyncFuncAI__deepwiki-open.md) is the server-shaped wiki-compiler with similar autoresearch concepts; deepwiki targets repos, claude-obsidian targets arbitrary sources. [`basicmachines-co/basic-memory`](surveys/basicmachines-co__basic-memory.md) is the cohort-closest "Markdown-is-the-truth" peer — basic-memory uses SQLite + sqlite-vec for retrieval, claude-obsidian leans on Obsidian + git.

## Code pointers (evidence)

- 11 skills (SKILL.md format): [`skills/`](https://github.com/AgriciDaniel/claude-obsidian/tree/main/skills) — `autoresearch`, `canvas`, `defuddle`, `obsidian-bases`, `obsidian-markdown`, `save`, `wiki`, `wiki-fold`, `wiki-ingest`, `wiki-lint`, `wiki-query`
- 4 slash commands: [`commands/`](https://github.com/AgriciDaniel/claude-obsidian/tree/main/commands) (`autoresearch.md`, `canvas.md`, `save.md`, `wiki.md`)
- 2 sub-agents: [`agents/`](https://github.com/AgriciDaniel/claude-obsidian/tree/main/agents) (`wiki-ingest.md`, `wiki-lint.md`)
- 4-event hooks: [`hooks/hooks.json`](https://github.com/AgriciDaniel/claude-obsidian/blob/main/hooks/hooks.json) (SessionStart / PostCompact / PostToolUse[Write|Edit] / Stop)
- Hot cache pattern: see hooks.json `Stop` handler — generates `wiki/hot.md` with `Last Updated` / `Key Recent Facts` / `Recent Changes` / `Active Threads` sections
- AGENTS.md / CLAUDE.md / GEMINI.md / WIKI.md at top-level — host-specific guidance + wiki taxonomy doc
- DragonScale Memory extension docs: [`docs/dragonscale-guide.md`](https://github.com/AgriciDaniel/claude-obsidian/blob/main/docs/dragonscale-guide.md)
- Bin / scripts / tests at top-level for Makefile-driven setup
- Most useful single file to read first: [`hooks/hooks.json`](https://github.com/AgriciDaniel/claude-obsidian/blob/main/hooks/hooks.json) — the lifecycle wiring is the architectural center.

## Open questions

- DragonScale Memory extension — what's the actual implementation? "Log folds, deterministic page addresses, semantic tiling lint, boundary-first autoresearch" are evocative but the implementation details aren't in the main README.
- Hot cache 500-word ceiling — is this enforced, or aspirational?
- `PostCompact` hook is genuinely useful — is this technique catching on in other Claude Code plugins? Worth flagging.
- 8-category wiki lint — what are the categories? Worth a closer read of `wiki-lint` skill.
- Obsidian-bases skill — what does it do? `obsidian-bases` is a relatively new Obsidian feature.

---

*Surveyed via the `curating-agentic-kbs` skill. Re-survey scheduled after 30 days of last `pushed_at` change.*

*Audit 2026-05-02: clone-verified against [`hooks/hooks.json`](https://github.com/AgriciDaniel/claude-obsidian/blob/main/hooks/hooks.json), [`CLAUDE.md`](https://github.com/AgriciDaniel/claude-obsidian/blob/main/CLAUDE.md), [`WIKI.md`](https://github.com/AgriciDaniel/claude-obsidian/blob/main/WIKI.md), and `skills/`/`agents/`/`commands/` directory listings. Hook event matchers, auto-commit command, hot-cache structured-summary format, and 11 skills + 4 commands + 2 agents counts all verbatim-correct. Storage section corrected to add `_templates/` and `_attachments/` (omitted in initial draft).*
