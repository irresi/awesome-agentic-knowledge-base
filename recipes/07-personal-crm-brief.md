# Recipe 07 — Personal CRM "before this call" brief

> Agent over your Gmail + Calendar + LinkedIn + meeting notes that drafts
> a 1-paragraph briefing 30 minutes before every meeting.

## Data flow

| # | Input | Transform | Output | Status |
|---|---|---|---|---|
| 1 | Gmail messages + Calendar events + LinkedIn profiles + Granola meeting transcripts (markdown export) | composio fetches via prebuilt OAuth toolkits — Gmail (verified), Google Calendar (46 tools / 7 triggers), LinkedIn (22 tools; default shared OAuth app has strict rate limits — register your own OAuth app for production), plus a user-side config file listing which sources to sync | Per-source structured records keyed by contact email | 🟢 |
| 2 | Per-contact records | Ingest mapper writes to memU `MemoryCategory` folders — one folder per contact (`contacts/jane.smith/`) with `MemoryItem` files for emails / LinkedIn bio / meeting transcripts. Per-contact partitioning is a usage convention atop memU's category-folder primitive. | memU vault with per-contact partition (folder = contact) | 🟢 |
| 3 | Calendar event 30 minutes from now (via cron poll) | letta agent invokes user-defined custom tool `brief_for_meeting(event_id)`: reads attendee emails from event, looks up matching memU folders, synthesizes paragraph (relationship history / last touchpoint / open threads / their likely agenda) | Briefing text | 🟢 |
| 4 | Briefing text | composio Slack toolkit sends DM (`SLACK_OPEN_DM` then `SLACK_SEND_MESSAGE`, or `SLACK_SCHEDULE_MESSAGE`), OR `mailto:` opens email draft | Slack DM or email draft 30 min before meeting | 🔴 |

## Build path

1. **Connect sources** — composio config lists Gmail / Calendar / LinkedIn / Granola export folder. One-time OAuth.
2. **Ingest into memU** — write per-source mappers that route into the right contact folder. Email goes by `from`/`to` address; transcripts by attendee list.
3. **Briefing agent** — letta agent with one custom tool `brief_for_meeting(event_id)` (Letta's tool-calling pattern: tools are first-class ORM rows). Prompt template asks for the structured paragraph.
4. **Trigger** — cron polls calendar every 5 min; fires the agent at T-30min. Output goes to Slack DM via composio's Slack tool, or `mailto:`.

## Why this combo

memU's category-folder + item-file model fits the per-contact layout cleanly; you're picking it for the file-system metaphor (easy to inspect, edit, and back up), not for a built-in person partition (memU has no such primitive — its survey explicitly notes "no MaxKB-style 4-category enum or memvid-style 6-kind taxonomy"). Alternatives: Letta's `Identity` ORM table or per-user `Block`s give native per-person scoping inside Letta itself, dropping memU. composio replaces ~5 OAuth flows with one config. letta's tool-calling is enough; you don't need OpenHands' heavyweight executor.

## Glue you write

- Cron + calendar polling script (~80 LoC) — the only real custom piece
- Briefing prompt template (1 file)
- Gmail/transcript → memU ingestion mapper (one function per source)

## Signal

`needs.md` Scenario 7 — Medium (Echo, LinxMemo, Nametag HN Shows; Granola/Claude briefing Substack).
