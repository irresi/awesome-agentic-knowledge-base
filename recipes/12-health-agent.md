# Recipe 12 — Health agent (wearables + journal)

> Agent over Apple Health + sleep + voice journal that answers
> "why did I feel terrible last Tuesday" with multi-source citations.

## Data flow

| # | Input | Transform | Output | Status |
|---|---|---|---|---|
| 1 | HealthKit data + Garmin / Polar / Suunto / Google Health Connect (Whoop and Samsung Health are not yet supported by Open Wearables — see roadmap) | Apple Health MCP (e.g. `neiltron/apple-health-mcp` — DuckDB + SQL over Apple Health CSV exports) exposes HealthKit; Open Wearables (`the-momentum/open-wearables`, early-stage / pre-1.0) provides a consistent REST API across cloud-based providers (Garmin, Suunto, Polar) and SDK-based providers (Apple HealthKit, Google Health Connect) | Daily metric records (steps, sleep, HRV, etc.) per source, normalized | 🟡 |
| 2 | Voice journal markdown (Recipe 05 pipeline) + metric records | graphiti `add_episode(EpisodeType.json)` for metrics + `EpisodeType.text` for journal entries; bi-temporal storage means events are queryable at any timestamp | Time-stamped event graph: metrics + life events on shared timeline | 🟢 |
| 3 | Same events | cognee's ECL pipeline (`extract → cognify → load`) builds entities + relations; you define a custom ontology with relation types like `precedes` / `correlates_with`, OR use a memify pipeline (`apply_feedback_weights`) to promote recurring co-occurrences. **No causal-inference primitive** — surface as "frequently co-occurs," not "causes." | Ontology-aware entity/relation graph with co-occurrence weights | 🟢 |
| 4 | "Why did I feel terrible last Tuesday?" | letta agent with two custom tools (Letta's external-memory pattern — no built-in adapter): `events_around(date, ±N days)` queries graphiti, `related_entities(symptom)` queries cognee | Answer cites metric source AND journal quote: "HRV down 18%, you said 'underslept and stressed'" | 🟡 |

## Build path

1. **Unify wearables** — Apple Health MCP for HealthKit (e.g. `neiltron/apple-health-mcp`, `the-momentum/apple-health-mcp-server`, `salgado/apple-watch-health-mcp`); Open Wearables for Garmin/Polar/Suunto/Google Health Connect (Whoop + Samsung Health Connect not yet supported — pre-1.0 project). Daily pull → normalized JSON.
2. **Pair with journal** — feed metrics + journal markdown into graphiti as separate `EpisodeType`s on the same timeline.
3. **Ontology graph** — define cognee ontology with `precedes` / `correlates_with` relations; or use memify's co-occurrence weighting. Don't claim causation.
4. **Q&A** — Letta agent with two custom tools per Letta's external-memory tutorial.

## Why this combo

graphiti + cognee covers two complementary axes: graphiti's bi-temporal facts answer *what happened when* (and what was true at time t), cognee's ontology-aware extraction answers *which entities relate to which*. Causal inference itself is a usage pattern (custom relation types like `precedes`, `correlates_with`, or memify-promoted co-occurrence weights) — not a turn-key feature of either repo. letta's tool-calling lets you expose both as queryable services, but via custom tools per Letta's external-memory tutorial, not a built-in adapter.

## Glue you write

- Apple Health export normalizer (HealthKit JSON → graphiti `EpisodeType.json` events, ~80 LoC)
- Open Wearables → graphiti adapter (one function per vendor, mostly schema mapping; Open Wearables already standardizes Garmin/Polar/Suunto + Apple HealthKit + Google Health Connect through a consistent REST API; Whoop/Samsung Health are on the roadmap, not in current release)
- Custom cognee ontology with `precedes` / `correlates_with` relations OR memify pipeline config for co-occurrence weighting
- Two Letta custom tools (`events_around`, `related_entities`) — ~50 LoC each, follow Letta's external-memory tutorial
- Optional iMessage shortcut (macOS) for ad-hoc questions

## Signal

`needs.md` Scenario 12 — Medium (Perplexity-Health launch, Apple-Health-API HN ask, Open Wearables, Themomentum.ai write-up).

## Caveat

This is health data — keep it local. Do not pipe to any hosted LLM you don't run yourself unless you've thought about HIPAA/your-jurisdiction equivalent. letta + a local model (Ollama / vLLM) is the safer default.
