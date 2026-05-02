# Recipe 06 — Then-vs-now personal-history agent

> Agent over your full ChatGPT/Claude history + blog drafts that answers
> "what did I think about X two years ago vs now," with both quotes.

## Data flow

| # | Input | Transform | Output | Status |
|---|---|---|---|---|
| 1 | ChatGPT export ZIP + Claude.ai data export ZIP (claude.ai → Settings → Privacy → Export Data emails a JSON bundle; basic-memory's `claude_conversations_importer.py` parses it as a starting point) + Obsidian vault | Per-source parsers normalize to `(timestamp, source, text)` records; chronological sort | Time-ordered record stream | 🟡 |
| 2 | Record stream | graphiti's `add_episode` ingests each record (`EpisodeType.message` / `text`); LLM extracts `EntityEdge`s with `valid_at` / `invalid_at` / `expired_at` / `created_at` timestamps; later "I changed my mind" auto-supersedes earlier facts | Bi-temporal knowledge graph: every fact queryable at any historical timestamp | 🟢 |
| 3 | Query "what did the user believe about X at time t" | letta agent calls custom tool `search_graphiti_memory(query, at_time)` (Letta's external-memory pattern — no built-in graph backend); graphiti returns facts active at `t` + the source text that established/invalidated them | Two-quote answer: belief at t1, current belief, with source links | 🟡 |
| 4 | User invokes via Obsidian or CLI | claude-obsidian (Claude Code plugin implementing Karpathy's wiki pattern) gets a custom slash-command `/history-of "<topic>"` that opens a timeline page; CLI alternative: `personal-history then-vs-now <topic>` | Markdown timeline page with quotes + dates | 🟢 |

## Build path

1. **Export and parse** — ChatGPT export ZIP has a stable JSON-bundled format; ~100 LoC parser. Claude history: trigger a data export from claude.ai (Settings → Privacy → Export Data emails a JSON ZIP — the Anthropic Messages API itself is stateless and has no list-past-conversations endpoint), then reuse basic-memory's existing `claude_conversations_importer.py` (`ClaudeConversationsImporter` class) as a starting point. Obsidian vault is a directory walk.
2. **Ingest into graphiti** — chronological order matters: feed records oldest-first so `invalid_at` supersedes correctly.
3. **Letta external-memory tools** — write `insert_memory(text)` and `search_graphiti_memory(query, at_time)` per Letta's external-memory tutorial. Same pattern Letta documents for mem0/Zep/MongoDB/Weaviate.
4. **Front-end** — extend claude-obsidian with a `/history-of` skill, or wrap as a CLI tool.

## Why this combo

graphiti is the only repo in the cohort doing bi-temporal facts. Without it you're back to "vector search returns both vegetarian and pescatarian as equally valid." letta + graphiti is a documented external-memory *pattern* (not a built-in adapter) — write two custom tools per Letta's tutorial; the bigger work is in normalizing exports.

## Glue you write

- ChatGPT export parser (~100 LoC, well-documented format)
- Claude history parser (~150 LoC; consumes the claude.ai Settings→Privacy→Export Data JSON bundle — there is no Anthropic API endpoint for listing prior conversations — building on basic-memory's `claude_conversations_importer.py` as a starting point)
- Obsidian vault walker that respects frontmatter dates (~50 LoC)
- Two Letta custom tools (`insert_memory`, `search_graphiti_memory`) — ~50 LoC each, follow Letta's external-memory tutorial
- One Obsidian command/CLI subcommand for the "then vs now" view

## Signal

`needs.md` Scenario 6 — Medium-Strong (ChatGPT memory upgrade, Karpathy second-brain Substack, PersonaAgent paper).
