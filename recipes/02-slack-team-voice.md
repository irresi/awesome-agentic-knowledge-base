# Recipe 02 — Slack/Notion → team-voice agent

> Self-hosted agent that reads company Slack + Notion + Confluence + GitHub
> history and answers internal questions in the team's voice, with citations.

## Data flow

| # | Input | Transform | Output | Status |
|---|---|---|---|---|
| 1 | Slack channels + Notion pages + Confluence docs + GitHub issues/PRs + GDrive files | onyx connectors crawl incrementally; document-level permission sync via per-connector `retrieve_all_slim_docs_perm_sync` (Slack permission-sync edge case re: connector start-date was tracked at [#9664](https://github.com/onyx-dot-app/onyx/issues/9664), closed COMPLETED 2026-03-27) | Postgres `documents` rows with raw text + per-doc ACL metadata | 🟢 |
| 2 | Indexed documents | onyx's title-aware chunker (`backend/onyx/indexing/chunker.py` — reserves tokens for title prefix + metadata suffix via `MAX_METADATA_PERCENTAGE` budget, plus retrieval-side `TITLE_CONTENT_RATIO` blending title vs content embeddings); Celery `kg_extraction` task in `backend/onyx/kg/extractions/extraction_processing.py` populates `kg_entity` / `kg_relationship` Postgres tables (ORM: `KGEntity` / `KGRelationship`) so shared people/projects link across sources | Hybrid index (BM25 + dense vector) + Postgres KG | 🟢 |
| 3 | User question + 5–10 hand-picked team-voice exemplar replies (in agent system prompt) | onyx agent: hybrid retrieval auto-filtered by user permissions, then LLM emits answer; `backend/onyx/chat/citation_processor.py` maps citations to source docs | Answer text with `[1][2]` citation markers | 🟢 |
| 4 | `@OnyxBot` mention or DM | onyx native Slack bot (`backend/onyx/onyxbot/slack/`; DM and `@OnyxBot` mention both supported per `slack/models.py`); DMs are the safer path for multi-turn — historic stale issue [#1496](https://github.com/onyx-dot-app/onyx/issues/1496) (closed NOT_PLANNED 2025-01) noted personas-in-channel-threads not responding; verify current behavior before relying on channel-thread persona follow-ups | Slack reply with citation links rendered | 🟢 |

## Build path

1. **Deploy onyx** — `docker compose up`. Plug in Slack, Notion, Confluence, GitHub connectors via the admin UI; turn permission sync on per-connector.
2. **Wait for indexing** — incremental crawl + chunker + Celery KG extraction run automatically.
3. **Add team-voice few-shot** — append 5–10 short exemplar replies from senior engineers to onyx's agent system prompt. The retriever still grounds answers; the few-shot only shapes voice.
4. **Connect Slack** — install `@OnyxBot`; default to DM-driven flow if channel-thread persona follow-ups behave inconsistently. Channel allowlist if you don't want the bot crawling everywhere.

## Why this combo

onyx is the closest single repo to the asked-for shape — connectors, hybrid retrieval, document-level permission sync, citations, and a Slack bot are all bundled. Picking ragflow or anything-llm here means re-implementing the connectors. The only piece onyx doesn't ship is style — solved by 10 lines of system prompt, not a separate framework.

## Glue you write

- 5–10 hand-curated team-voice exemplar replies (the smaller and more recent, the better)
- Slack channel allowlist (which channels the bot is allowed to crawl + reply in)

## Signal

`needs.md` Scenario 2 — Strong (Onyx HN Show, Dust case studies, Notion 3.3 release, Question Base guide).
