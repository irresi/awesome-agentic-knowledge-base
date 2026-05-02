# Recipes

Concrete buildable agents, composed mostly from surveyed repos. When picking a
tool for any stage, the priority order is:

1. **🟢 Use existing repo / tool as-is** — the cohort survey lists the capability
2. **🟡 Borrow methodology from a paper** — write light glue around a documented technique
3. **🔴 Custom implementation** — last resort, only when neither 1 nor 2 fits

A recipe with all-🟢 stages is a weekend assembly job. Anything 🟡 or 🔴 means
real engineering — but the card spells out exactly which lines you'll have to
write.

## The 14 recipes

| # | Recipe | Stack | Status |
|---|---|---|---|
| [01](01-persona-debate.md) | Persona-debate from X + GitHub | letta · graphiti · LangGraph · claude-mem | 🟢🟢🟡🟢 |
| [02](02-slack-team-voice.md) | Slack/Notion → team-voice agent | onyx (full stack) | 🟢🟢🟢🟢 |
| [03](03-ask-my-codebase.md) | "Ask my codebase," persistent | GitNexus · GitNexus+LightRAG · cline+claude-mem · MCP | 🟢🟢🟢🟡 |
| [04](04-self-hosted-deepwiki.md) | Self-hosted DeepWiki for private repo | deepwiki-open · LightRAG · aider /ask · Action | 🟢🟢🟢🟢 |
| [05](05-voice-memo-second-brain.md) | Voice memo → second-brain | whisper.cpp · basic-memory · ClaudeCode+claude-mem · Telegram | 🟢🟢🟢🔴 |
| [06](06-personal-history.md) | Then-vs-now personal-history agent | exporters · graphiti · letta+custom-tools · Obsidian | 🟡🟢🟡🟢 |
| [07](07-personal-crm-brief.md) | Personal CRM "before this call" brief | composio · memU-categories · letta+custom-tool · cron | 🟢🟢🟢🔴 |
| [08](08-ghostwriter.md) | Ghostwriter in your voice | basic-memory+custom · LightRAG+style-emb · letta+custom-tools · Obsidian | 🟡🟡🟢🟢 |
| [09](09-team-convention-reviewer.md) | Team-convention code reviewer | gh+custom-mining · graphiti · open-code-review · Action | 🟡🟢🟢🟢 |
| [10](10-personal-arxiv-research.md) | Personal-arxiv research agent | DeepTutor+BetterBibTeX · fast-graphrag · llama_index-Workflows · sim+Obsidian | 🟢🟡🟡🟡 |
| [11](11-discord-community-agent.md) | Discord community-voice agent | Discord-MCP · anything-llm · memU-categories · AstrBot+star | 🟢🟢🟢🟡 |
| [12](12-health-agent.md) | Health agent (wearables + journal) | AppleHealth-MCP+OpenWearables · graphiti · cognee · letta+custom-tools | 🟢🟢🟢🟡 |
| [13](13-support-over-tickets.md) | Customer-voice support over tickets | composio · ragflow · memU · onyx | 🟢🟢🟢🟢 |
| [14](14-llm-wiki.md) | Self-maintaining LLM Wiki | watcher · basic-memory · LightRAG · claude-obsidian | 🔴🟢🟢🟢 |

Status string reads left-to-right matching the four pipeline steps in each
card's **Data flow** table (steps 1, 2, 3, 4). The Stack column above shows
the same four steps as a one-line summary (`step1 · step2 · step3 · step4`).

## Card format

Every card has the same five sections so they're scannable side-by-side:

- **Data flow** — 4-row pipeline table: `# · Input · Transform · Output · Status`. This is the heart of each card — read this and you understand "what data goes in, what comes out, who does the work" without reading the prose.
- **Build path** — operational details for each pipeline step in order (configs, commands, alternatives)
- **Why this combo** — the trade-off vs alternatives in the same cohort
- **Glue you write** — what's not in any repo, your code
- **Signal** — pointer back to the underlying need

The **Data flow** table is intentionally narrative-of-data, not a list of
repos by role. A row says "this data shape transforms into that data shape via
this tool/method," so the card answers "if I combine these, this is what
happens" rather than "these are the boxes."

## Verification status

All 14 cards have been verified against `surveys/` + live sources (May 2026):
cohort surveys, GitHub repo READMEs, recent issues, papers, and MCP-server lists.

What was found and corrected (most consequential errors caught in the pass):

- **claude-mem is a Claude Code lifecycle-hook plugin**, not a runtime / cron file-editor / Read-Glob-Grep tool provider. Affected #03, #05, #14.
- **Letta has no built-in graph/memory adapter** — every "letta + X memory" is a custom-tool pattern (`insert_memory`, `search_X_memory`) per Letta's external-memory tutorial. Affected #06, #07, #08, #12.
- **memU's primitive is `MemoryCategory` folders + `MemoryItem` files**, not `person_id` / per-segment partitioning. Affected #07, #11, #13.
- **cognee has no causal-inference primitive** — it does ontology-aware entity/relation extraction; causal modeling is custom ontology + memify pipelines. Affected #12.
- **fast-graphrag is stagnant since 2025-11-01** and is designed for LLM-extracted natural-language KGs, not pre-built code/claim graphs. Affected #03, #10.
- **byterover-cli is a coding-agent memory router**, not a personal-corpus aggregator. Affected #08.
- **Apple Voice Memos on-device transcription is macOS 15 (Sequoia) + Apple Silicon**, not macOS 14. Affected #05.
- **Outdated terminology**: aider "chat-mode" → `/ask` mode; llama_index "Query Pipelines" → Workflows.
- **Capability inflation**: "ACL hydration" (onyx says permission sync), "code-review-graph extracts approved patterns" (it indexes current codebase), "DeepTutor preserves PDF annotations" (it doesn't — use Better BibTeX), "memvid compresses long context" (it's a persistent store, not a compressor).

Status strings reflect post-verification reality: stages downgraded from 🟢 to 🟡 indicate that a custom-tool pattern, custom prompt-engineering, or third-party glue is needed beyond "drop in the repo as-is."

## Sources

Underlying needs and community evidence: `needs.md` (gitignored — local research file).
Per-repo deep dives: [`surveys/`](../surveys/).
