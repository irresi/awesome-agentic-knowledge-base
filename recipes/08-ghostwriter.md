# Recipe 08 — Ghostwriter in your voice

> Agent grounded in your past blog posts + tweets + Slack messages that drafts
> new posts in your specific voice. Style + topic retrieval, no fine-tuning.

## Data flow

| # | Input | Transform | Output | Status |
|---|---|---|---|---|
| 1 | X archive ZIP + blog-repo markdown + exported Slack DMs + Claude conversations | basic-memory's `claude_conversations_importer.py` for chat history; per-source custom scripts (X parser ~50 LoC, blog walker, Slack DM exporter) for the rest. byterover-cli is a *coding-agent memory router*, not a personal-corpus aggregator — wrong tool here. | basic-memory vault with user-defined `source: blog \| tweet \| slack` frontmatter (frontmatter is freeform via `python-frontmatter`) | 🟡 |
| 2 | Vault corpus | Two parallel indexes: LightRAG over content (topic retriever); separate style-embedding index informed by the "Catch Me If You Can? Not Yet" methodology (arXiv:2509.14543, EMNLP 2025 Findings, Wang et al.) — captures syntactic/lexical fingerprints independent of topic (paper evaluates in-context style imitation; the embedding-based retrieval pattern here is your own glue, not lifted from the paper) | Two retrievers: `topic_retrieve(prompt)` returns same-topic passages; `style_retrieve(prompt)` returns style-similar passages | 🟡 |
| 3 | Draft prompt (e.g. "essay on X") | letta agent calls two custom tools: `topic_retrieve(prompt)` and `style_retrieve(prompt)` (Letta's external-memory pattern — custom tools, not built-in adapters); assembles prompt: `style examples (match cadence, do not paraphrase) / topic context (use as facts/refs)` | Draft text matching user voice + grounded in user's facts | 🟢 |
| 4 | Draft text | Obsidian plugin inserts as new note, OR `gh` CLI commits to blog repo as draft branch | Editable draft, never auto-published | 🟢 |

## Build path

1. **Aggregate corpus** — basic-memory ships chat-history importers; write per-source scripts for X archive / blog / Slack DM (~50 LoC each). User-defined frontmatter for source filtering.
2. **Two indexes** — LightRAG for topic; build a separate style-embedding service with off-the-shelf HuggingFace style/authorship-attribution models (e.g., AnnaWegmann/Style-Embedding) over the same corpus (~100 LoC).
3. **Draft loop** — letta agent with two custom retrieval tools. Prompt structure: `style examples / topic context / draft prompt`.
4. **Output** — Obsidian plugin command `/draft-as-me` or `gh` CLI to push to a blog repo's draft branch.

## Why this combo

The Sep 2025 paper ("Catch Me If You Can? Not Yet: LLMs Still Struggle to Imitate the Implicit Writing Styles of Everyday Authors", arXiv:2509.14543, EMNLP 2025 Findings, Wang et al.) showed that even strong models struggle with implicit style imitation on informal text — the paper tests in-context learning, not fine-tuning, but it motivates curating style examples carefully (whether via retrieval or hand-picked few-shot) over naive "write like me" prompts. (Note: memvid is a single-file persistent memory store backed by WAL + Tantivy BM25 + HNSW, not a context compressor — drop it from this recipe.)

## Glue you write

- Per-source corpus importers (X archive parser, blog-repo walker, Slack DM exporter) — ~50 LoC each
- Style-embedding service (~100 LoC: HF style/authorship-attribution model + nearest-neighbor index over the corpus)
- Two letta custom tools (`style_retrieve`, `topic_retrieve`) — Letta's external-memory tool pattern
- Optional Obsidian plugin command `/draft-as-me`

## Signal

`needs.md` Scenario 8 — Medium (GHOSTYPE HN Show; "Catch Me If You Can" arXiv; Junia.ai default-voice piece).
