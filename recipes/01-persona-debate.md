# Recipe 01 — Persona-debate from X + GitHub

> Build N persona-agents cloned from real people's X timeline + GitHub history,
> put them in a moderated debate over a topic.

## Data flow

| # | Input | Transform | Output | Status |
|---|---|---|---|---|
| 1 | X archive ZIP (one per persona, from X settings) + `gh api /users/{u}/events` (PRs / issues / comments) + blog URLs | Twitter-archive parser + `gh api` walker + SurfSense web-crawler indexer (RSS not first-class — feed it URLs) | One JSON dump per persona, ~5–50k tokens of authentic writing | 🟢 |
| 2 | Per-persona JSON corpus | Spawn one letta agent per persona; corpus → letta `Block`s in core memory; system prompt `"You are {name}. The following is your authentic writing."` Wire mem0 with `user_id=persona_id` for runtime fact lookup. | N stateful letta agents — each "is" one persona, each with persona-scoped mem0 | 🟢 |
| 3 | Debate topic + N persona-agents | LangGraph state machine (StateGraph + subgraphs): chair-agent (no persona) drives rounds `opening → rebuttal_1 → rebuttal_2 → closing`. Multi-agent-debate prompt scaffold inspired by Du et al. 2023 (arXiv:2305.14325) — note: that paper aims to *converge to consensus* for factuality; you'll need to invert the prompts (instruct each persona to *defend* their priors) so personas stay distinct. | Streamed debate transcript (text per persona per round) + chair-agent scoring at close | 🟡 |
| 4 | Debate transcript | claude-mem captures the session through its 5 lifecycle hooks (`SessionStart`/`UserPromptSubmit`/`PostToolUse`/`Stop`/`SessionEnd` — async worker, primarily on `PostToolUse`); the worker uses Claude Agent SDK to extract typed observations (`facts` / `narrative` / `concepts` / `files_read` / `files_modified`) into SQLite + ChromaDB | Replayable + searchable session in claude-mem's store; export to markdown via the `timeline-report` skill | 🟢 |

## Build path

1. **Persona corpus** — write one fetcher per source (~50 LoC each: X archive parser, gh-api events walker, SurfSense URL feeder for blogs).
2. **Letta agents** — `client.agents.create(name=persona, memory_blocks=[Block(label="writings", value=corpus[:50000])])` per persona. Optionally hydrate mem0 with extracted factoids ("X strongly prefers Rust") for runtime retrieval.
3. **Debate orchestration** — LangGraph nodes: `propose_topic`, `persona_speak(persona_id, round_id)`, `chair_critique`. Loop 3 rounds; chair scores at close. Du et al. paper provides the multi-round message-exchange scaffold (each agent sees the others' last response and revises) — but you have to flip the prompt from "reach consensus" to "argue your persona's position".
4. **Capture** — claude-mem's lifecycle hooks fire on every tool use (`PostToolUse`) and at end-of-session (`SessionEnd`); the worker's Claude Agent SDK extractor produces typed observations including `narrative`, so the round-by-round prose is preserved.

## Why this combo

letta's memory-block model maps 1:1 to "this agent IS this person" without fine-tuning — fine-tuning a 5–50k token corpus is wasteful. graphiti would over-engineer for static historical text (no temporal updates needed). The chair pattern matters: without an explicit defend-your-priors instruction + a chair to keep personas separated, multi-agent debates tend to converge to bland agreement (verify currency of any specific citation before adopting).

## Glue you write

- Per-source persona fetcher (~50 LoC each: X archive parser, `gh api` walker, SurfSense URL list builder)
- LangGraph debate state machine (~80 LoC) with a 3-round chair pattern (chair role is your addition; Du et al. is chair-less and consensus-seeking — borrow the multi-round message-exchange shape, not the prompts)
- System-prompt generator from corpus (top-N highest-engagement tweets, recent blog excerpts)

## Signal

`needs.md` Scenario 1 — Strong (HN Show, "Agents of the Roundtable" blog, LangChain X-clone tutorial, debate-personality paper).
