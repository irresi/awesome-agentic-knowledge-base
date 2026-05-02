# Recipe 13 — Customer-voice support agent over historical tickets

> Agent over your closed Zendesk/Intercom tickets that drafts replies in
> your team's documented resolution voice, citing the original ticket #.

## Data flow

| # | Input | Transform | Output | Status |
|---|---|---|---|---|
| 1 | Zendesk + Intercom tickets | composio's Zendesk tool runs Zendesk's Search API filter (`status:solved` — composio is a *tool-routing layer*, NOT a query DSL); script-side post-filter on `csat ≥ 4` (don't train the agent on bad replies) | Closed + high-satisfaction tickets only | 🟢 |
| 2 | Selected tickets | ragflow's `qa` chunker (one of 14 specialized chunkers) maps tickets to problem-reply pairs natively; intermediate diagnostic-step structure is custom in your ingest mapper (ragflow's `qa` doesn't model intermediate steps) | Hybrid index over problem-reply pairs (BM25 + vector) | 🟢 |
| 3 | All resolutions | Nightly job extracts recurring patterns into memU `MemoryCategory` folders by customer segment (`segments/enterprise/`, `segments/smb/`); `MemoryItem` files hold pattern descriptions. Per-segment partitioning is a usage convention atop memU's category-folder primitive. | Per-segment resolution-pattern memory | 🟢 |
| 4 | New incoming ticket | onyx agent: retrieves top-k similar resolutions (ragflow) + applicable patterns (memU); drafts reply citing `Ticket #432 (resolved 2026-03-12)`; surfaces in agent UI via citation processor — **never auto-sends** | Draft reply with ticket citation in agent's draft pane | 🟢 |

## Build path

1. **Selective export** — composio Zendesk tool with `status:solved` query, then your script post-filters on CSAT.
2. **Resolution-shaped index** — ragflow ingests with `qa` chunker; your ingest mapper handles diagnostic-step structure if you need it.
3. **Pattern memory** — nightly script writes patterns to memU folders per segment.
4. **Drafting agent** — onyx agent reads ragflow + memU; drafts with `chat/citation_processor.py`-style citations. Browser extension surfaces "draft with AI" button in Zendesk.

## Why this combo

ragflow's `qa` chunker is the cleanest fit for problem-reply data. onyx's citation processor is the trust mechanism — agents that cite *which* ticket they're modeling are auditable. memU's category folders make per-segment patterns easy to inspect and edit (just look at the markdown files). Composio replaces multiple OAuth setups with one config.

## Glue you write

- Zendesk/Intercom → ragflow ingestion mapper (~100 LoC; includes diagnostic-step parsing)
- Browser extension that injects "draft with AI" button into Zendesk agent workspace (~150 LoC, vanilla JS — Zendesk Apps Framework alternative also works)
- CSAT post-filter (Zendesk Search API + script-side filter on csat ≥ 4)

## Signal

`needs.md` Scenario 13 — Medium (Twig benchmarks, Zendesk AI-as-tickets release, Intercom Fin, Canary 2026 review).
