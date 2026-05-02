# Recipe 11 — Discord community-voice agent

> Agent over a Discord/Slack community's full message history that answers
> FAQs in the community's tone — sounds like a long-time member, not a corporate FAQ bot.

## Data flow

| # | Input | Transform | Output | Status |
|---|---|---|---|---|
| 1 | Discord guild full message history | Discord MCP (e.g. `tolgasumer/discord-mcp` for paginated `get_channel_messages`) does one-time bulk pull + `MESSAGE_CREATE` listener for incremental updates; respects role permissions | Per-channel message archive | 🟢 |
| 2 | Per-channel messages | anything-llm: one workspace per channel (`#help`, `#general`, etc.); workspace primitive scopes RAG retrieval so `#help` doesn't surface offtopic banter | Channel-scoped workspaces with auto-filtered retrieval | 🟢 |
| 3 | 20–30 hand-picked exemplar messages from longtime members | Curate into memU `MemoryCategory` folders by tone (`tone/welcoming`, `tone/technical`, `tone/playful`) — each folder contains 5–10 `MemoryItem` files. Per-tone partitioning is a usage convention atop memU's category-folder primitive. | memU vault with per-tone exemplar files | 🟢 |
| 4 | Discord message in #help | AstrBot (8+ first-class chat-platform adapters incl. Discord) + custom AstrBot star/plugin: queries anything-llm REST API for channel-scoped passages + memU for tone exemplars; AstrBot reply pipeline composes answer | Reply in Discord channel matching community tone | 🟡 |

## Build path

1. **Pull guild history** — Discord MCP bulk pull + incremental listener. Wire to anything-llm's ingestion.
2. **Channel-scoped indexes** — anything-llm workspaces, one per channel.
3. **Curate tone exemplars** — by hand, ~30 messages organized into 3–5 memU category folders. One-time work.
4. **AstrBot bridge** — custom AstrBot star (~100 LoC) that calls anything-llm's REST API + memU lookup, then passes to AstrBot's reply pipeline. Alternative: drop anything-llm and use AstrBot's native KB (Faiss + BM25 + RRF) with one KB per channel, eliminating the bridge.

## Why this combo

AstrBot is the closest one-repo match — picking a generic agent framework here means re-implementing Discord event loops, rate limiting, and role checks. anything-llm's workspace primitive maps 1:1 to channels. memU vs. mem0 here: memU's category-folder model fits the per-tone layout cleanly (one folder per tone tag); per-entity partitioning is a usage pattern, not a primitive. If you don't need anything-llm's UI/connectors, AstrBot's built-in KB (Faiss + BM25 + RRF, per-KB embedding/rerank provider) handles channel-scoped RAG natively — that path drops the bridge plugin entirely.

## Glue you write

- Discord MCP → anything-llm ingestion mapper (~80 LoC)
- Custom AstrBot star (~100 LoC) bridging to anything-llm REST API + memU lookup; OR skip and use AstrBot's native KB
- Tone-exemplar curation: 20–30 hand-picked messages organized into 3–5 memU category folders (one-time, ~1 hour of work)
- Optional: feedback collector — community thumbs-up/down on bot replies feeds back into memU as positive/negative tone examples

## Signal

`needs.md` Scenario 11 — Medium (OpenClaw Discord guide, Eesel ranking, Google ADK Discord tutorial, Discord MCP).
