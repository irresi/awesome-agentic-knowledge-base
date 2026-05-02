# Recipe 09 — Team-convention code reviewer

> Agent that reviews PRs using your team's actual conventions extracted from
> past PRs, ADRs, and CLAUDE.md — not generic "best practices."

## Data flow

| # | Input | Transform | Output | Status |
|---|---|---|---|---|
| 1 | Last N=500 merged PRs + ADRs + CLAUDE.md | `gh api` walker pulls PR diffs + review comments. **Convention-pattern extraction is custom** (LLM-assisted clustering of review-comment themes, ~150 LoC). code-review-graph indexes the *current codebase* (Tree-sitter graph + Leiden communities + criticality flows) but does NOT mine PR review threads — keep it for "where in the code does this convention apply" lookups. | Convention list (with timestamps from comment dates) + current-codebase structural index | 🟡 |
| 2 | Convention list | graphiti ingests as `text` episodes; bi-temporal facts mean "we used to allow X but as of PR #1234 we don't" auto-supersedes via `invalid_at`. LightRAG indexes ADR markdown for "why" lookups. | Temporal-aware convention graph + ADR semantic index | 🟢 |
| 3 | New PR diff | open-code-review (forked) reviewer agent loads CLAUDE.md + recent ADRs (LightRAG) + active conventions for this diff (graphiti queried with `valid_at=now`); reviews with citations | Inline review comments citing original PR or ADR per convention | 🟢 |
| 4 | `pull_request: opened` event | GitHub Action runs reviewer; confidence-gated output (high → comment, medium → request-changes, low → silent) | Posted PR comments | 🟢 |

## Build path

1. **Mine team conventions** — `gh api` walker → LLM-assisted clustering script. This is the meaningful glue.
2. **Decisions as temporal graph** — feed convention timestamps into graphiti so superseded rules don't get cited.
3. **Reviewer agent** — fork open-code-review; replace built-in personas with a prompt that loads CLAUDE.md + ADRs (LightRAG) + active graphiti conventions for the diff.
4. **GitHub Action** — runs on PR open. Add confidence gating so low-confidence reviews stay silent.

## Why this combo

open-code-review already nails the persona pattern; the upgrade is grounding it in *your* team's history instead of generic Beck/Fowler personas. graphiti is essential — convention drift kills these agents (cite a rule that was overturned, lose trust). LightRAG over ADRs handles the "why" questions reviewers always ask.

## Glue you write

- One-time PR mining script (`gh api` walker + LLM-assisted convention clustering, ~150 LoC) — the meaningful custom piece
- ADR + CLAUDE.md loader for the reviewer prompt
- GitHub Action YAML (~50 LoC) wrapping open-code-review with confidence gating

## Signal

`needs.md` Scenario 9 — Medium-Strong (open-code-review repo, Copilot-review changelog, Broccoli HN Show, 29% YoY PR-volume jump).
