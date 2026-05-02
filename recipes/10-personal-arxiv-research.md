# Recipe 10 — Personal-arxiv research agent

> Agent over your saved papers (Zotero / arXiv pile) that answers
> "what's the consensus across my reading list on X" with citations to the
> specific PDFs you've actually read — including your margin notes.

## Data flow

| # | Input | Transform | Output | Status |
|---|---|---|---|---|
| 1 | Zotero library | **Better BibTeX plugin** exports BibTeX/citation keys (its actual scope — it does NOT export PDF annotations). For annotations, use Zotero 6+'s native "Add Note from Annotations" or a dedicated tool like `pdfannots` (Python CLI extracts highlights+comments to Markdown/JSON). DeepTutor's RAG pipeline (LaTeX chunker, embedding signatures, versioned indexes) extracts PDF body — annotations come from the pdfannots/Zotero-native path, NOT from DeepTutor. | Body passages + annotation passages, BibTeX-keyed | 🟢 |
| 2 | All paper passages | fast-graphrag is designed for LLM-extracted NL knowledge graphs where `entity_types` are user-declared **nouns** (the docs example uses `["Character", "Animal", "Place", "Object", "Activity", "Event"]`). Repurposing it for a claim-graph (claims-as-entities, supports/refutes/extends-as-relations) requires custom prompt-engineering — NOT a documented use case. **Note: fast-graphrag is stagnant since 2025-11-01 and still at v0.0.5.** Alternative is microsoft/graphrag (LLM `GraphExtractor` + iterative gleaning + optional `extract_covariates` for claims-as-covariates), also requiring custom typing. | Cross-paper claim graph: claims linked across papers as supports / refutes / extends | 🟡 |
| 3 | "What's the consensus on X" | llama_index **Workflows** (event-driven `@step` async DAG with `Context`; the older "Query Pipeline" abstraction is deprecated) orchestrate: structural query first (claim graph), semantic fallback (passages), annotation merge so highlights surface in citations | Ranked claim cluster + supporting/refuting paper IDs + page-level passages + your highlights | 🟡 |
| 4 | Lit-review prompt | sim's DAG executor (`apps/sim/lib/executor/dag/`) runs a workflow **you author yourself in sim's visual UI** (sim ships 227 workflow blocks but no prebuilt planner-executor primitive — the multi-step lit-review is user-composed): identify cluster → retrieve supports/refutes → look up your annotations → synthesize. Output via Obsidian plugin (claude-obsidian pattern). | `/lit-review <topic>` outputs a markdown page with linked citations into the Obsidian reading-notes vault | 🟡 |

## Build path

1. **Zotero export + annotations** — install Better BibTeX for BibTeX/citation-key export; for annotations use Zotero 6+'s native "Add Note from Annotations" or `pdfannots` against the PDF folder. Run DeepTutor on PDFs separately for body extraction. Merge annotations + body in step 3.
2. **Claim graph** — write a custom `entity_types`+prompt setup for fast-graphrag to coerce claim-vs-evidence semantics (note: this is NOT a documented use case — fast-graphrag's typing assumes nouns). OR pivot to microsoft/graphrag (also a custom-prompt job, but actively maintained).
3. **Workflow** — llama_index Workflows for retrieval orchestration. Annotation-aware retriever returns highlights when they cover the passage.
4. **User-authored sim workflow** — visually compose the multi-step lit-review in sim's UI (sim has no prebuilt planner-executor primitive). Trigger via `/lit-review` Obsidian command.

## Why this combo

A claim graph is what separates "list of papers about X" from "the consensus is Y because of papers A, B vs C, D." llama_index Workflows orchestrate the structural+semantic mix. Annotation extraction is the work of Zotero 6+ native annotations / `pdfannots` (NOT Better BibTeX, which is BibTeX-export only, and NOT DeepTutor, which has no annotation primitive) — splitting these concerns is honest about what each tool ships.

## Glue you write

- Better BibTeX install (BibTeX/citation-key export) + Zotero 6+ native annotation export (or `pdfannots` script over PDF folder) → DeepTutor batch script (~80 LoC; merges annotations with DeepTutor body extraction)
- Custom `entity_types` + prompt-engineering for fast-graphrag to coerce claim-vs-evidence semantics — undocumented use, expect tuning effort (or pivot to microsoft/graphrag)
- Annotation-aware retriever wrapper (returns highlight if it covers the passage)
- sim workflow JSON describing the user-authored multi-step lit-review (composed from sim's 227 blocks)
- Obsidian command `/lit-review <topic>` outputting a markdown page with linked citations

## Signal

`needs.md` Scenario 10 — Medium (PaperOrchestra paper Apr 2026; awesome-ai-agent-papers; FlowPIE arXiv; Consensus AI).
