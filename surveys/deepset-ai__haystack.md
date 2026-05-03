# Survey: deepset-ai/haystack

**Date:** 2026-05-02
**Stars:** 25,045 · **Last push:** 2026-04-30 · **Created:** 2019-11 · **Version:** `haystack-ai 2.29.0-rc0` (Apache-2.0)
**Category:** kb-framework
**Slug:** [deepset-ai/haystack](https://github.com/deepset-ai/haystack)

---

## TL;DR (3 lines)

- **What it is:** The cohort's elder statesman — Haystack 2.x (current `2.29.0-rc0`, Apache-2.0) is **deepset's open-source LLM-pipeline framework** for building RAG / agent / multimodal / semantic-search applications. PyPI: `haystack-ai`. Mature ecosystem with `haystack-experimental` and a separate-package world for vector-store integrations (Qdrant, Weaviate, Chroma, OpenSearch, Elasticsearch, Pinecone, …).
- **How its KB works:** **Component-pipeline architecture.** Pipelines are NetworkX DAGs of `Component`s that connect via typed sockets. **24 component categories** ship in core: agents, audio, builders, caching, classifiers, connectors, converters, embedders, evaluators, extractors, fetchers, generators, joiners, preprocessors, query, rankers, readers, retrievers (9 variants incl. in-memory bm25/embedding), routers, samplers, tools, validators, websearch, writers. Vector backends live in **`haystack_integrations.*`** sibling packages — core only ships `InMemoryDocumentStore`.
- **Verdict:** Pick when you want a **mature, modular, framework-shaped** RAG/agent platform with pluggable everything; cohort first to ship a `human_in_the_loop/` package with policies/strategies/interfaces; `Tool`/`Toolset`/`ComponentTool`/`PipelineTool`/`SearchableToolset` give the agent runtime real surface area. Skip if you want a single binary or a memory-framework — Haystack is a *framework* you compose into a product.

## KB Architecture

### Storage
- **Vector store:** **None native.** Core ships only [`haystack/document_stores/in_memory/`](https://github.com/deepset-ai/haystack/tree/main/haystack/document_stores/in_memory). Production backends are sibling packages — `haystack-integrations` packages on PyPI cover Qdrant, Weaviate, ChromaDB, Pinecone, OpenSearch, Elasticsearch, MongoDB Atlas, Astra DB, FAISS, Milvus, pgvector, Marqo, Snowflake, etc. The split is deliberate: core is small and stable, integrations move independently.
- **Graph store:** None native; `haystack-integrations` includes a Neo4j adapter.
- **Metadata / structured:** Determined by the chosen `DocumentStore` integration. Document schema is `haystack/dataclasses/document.py` — content + metadata dict + embedding + score + id.
- **Object / blob:** Per-integration; core has `data_classes/byte_stream.py` for binary content passing through pipelines.

### Ingestion / Extraction
- **Source types accepted:** Extensive `converters/` ecosystem — text, PDF, DOCX, HTML, JSON, Markdown, CSV, audio (whisper components), images (vision LLMs). Plus `connectors/` for external sources, `fetchers/` for HTTP, `websearch/` for SERP integrations.
- **Chunking strategy:** [`preprocessors/`](https://github.com/deepset-ai/haystack/tree/main/haystack/components/preprocessors) — `DocumentSplitter` with token / sentence / passage modes, `TextCleaner`, `RecursiveDocumentSplitter`, `HierarchicalDocumentSplitter`, etc.
- **Entity / fact extraction:** [`extractors/`](https://github.com/deepset-ai/haystack/tree/main/haystack/components/extractors) — Named-entity, key-phrase, custom-schema extractors via Pydantic. `LLMMetadataExtractor` for arbitrary LLM-driven attribute extraction.
- **Schema:** Per-component. The flagship `Document` dataclass is content-centric with structured `meta` for downstream filtering.

### Retrieval
- **Modes:** **Nine retrievers in core** — `auto_merging_retriever` (hierarchical chunks → parents on hit), `filter_retriever` (metadata-only), `multi_query_embedding_retriever` (LLM-generated query variants), `multi_query_text_retriever` (multi-keyword variants), `multi_retriever` (fan-out across stores), `sentence_window_retriever` (hit ± window of neighbors), `text_embedding_retriever`, plus 2 in-memory variants in `retrievers/in_memory/` (`bm25_retriever`, `embedding_retriever`), plus per-integration backend retrievers in `haystack_integrations.*`. `joiners/` (`DocumentJoiner` with concatenate / merge / RRF) compose multi-source results.
- **Reranker:** `rankers/` ships `LostInTheMiddleRanker`, `MetaFieldRanker`, `RecentnessRanker`, `SentenceTransformersDiversityRanker`, `SentenceTransformersSimilarityRanker`, `LLMRanker`, plus per-integration backends (Cohere, Jina, Nvidia, Voyage, etc.).
- **Top-k defaults:** Per-retriever; `top_k=10` is typical default but per-component overridable.
- **Context assembly:** `builders/` — `PromptBuilder`, `ChatPromptBuilder`, `AnswerBuilder`. `samplers/` for stochastic context sub-selection. `routers/` for conditional pipeline branches (`ConditionalRouter`, `FileTypeRouter`, `MetadataRouter`, etc.).

### Memory model
- **Tiers:** Pipeline-state-driven, not memory-framework-shaped. The `Agent` ([`components/agents/agent.py`](https://github.com/deepset-ai/haystack/blob/main/haystack/components/agents/agent.py)) maintains internal state (`components/agents/state/`); chat history is passed as `ChatMessage[]` between components. **No native long-term memory layer** — users compose memory via DocumentStore writes from chat-context, or wrap Mem0/Letta/etc. as a `Component`.
- **Bi-temporal:** No.
- **Self-update mechanism:** Pipeline-driven — components writing to a DocumentStore update the index; no built-in summarization/consolidation hook.
- **Decay / forgetting:** Per-component (`RecentnessRanker` decays at retrieval time); no automatic GC.

### MCP / connectors
- **MCP server exposed:** Yes — `haystack-experimental` has an MCP-server component (separate package, not core). Core's `tools/` module exposes the *concept* via `Toolset`/`SearchableToolset` but doesn't ship an MCP transport.
- **MCP client used:** Yes — via `haystack-experimental` MCP integrations.
- **Native connectors:** [`connectors/`](https://github.com/deepset-ai/haystack/tree/main/haystack/components/connectors) for external services; `websearch/` for SerperDev / SearchApi / etc.
- **Tool-call surface:** **Cohort-most-flexible tool model** — `tool.py` (base `Tool`), `from_function.py` (Python-function-as-tool), `component_tool.py` (any Haystack Component → Tool), `pipeline_tool.py` (entire Pipeline → Tool), `searchable_toolset.py` (semantic search over tool descriptions when toolsets get large), `Toolset` (grouping). The pipeline-as-tool primitive is unique in this cohort: any Pipeline becomes a callable tool the agent can invoke.

### Notable design choices
- **NetworkX DAG as the pipeline runtime** — `core/pipeline/` builds a graph of components with typed sockets; serialized via `marshal/`. Cohort has 3 NetworkX users now: ragflow, LightRAG, graphrag, **plus haystack at the pipeline level**.
- **Core-vs-integrations split** — `haystack-ai` core stays small (~20 deps); 50+ vector / LLM / connector / reranker integrations ship as separate `haystack-integrations.*` packages. Lets users avoid pulling in dependency mass they don't need.
- **`super_component/`** — composing components into reusable supercomponents; lets framework users build their own primitives.
- **Human-in-the-loop as a first-class package** ([`haystack/human_in_the_loop/`](https://github.com/deepset-ai/haystack/tree/main/haystack/human_in_the_loop)) — `policies.py`, `strategies.py`, `user_interfaces.py`, `dataclasses.py`. Cohort first to formalize HITL with policy/strategy/interface separation. (byterover-cli has a curate workflow but not as a typed framework subsystem.)
- **`evaluation/`** — first-class evaluators for RAG quality (faithfulness, answer correctness, context relevance, groundedness, etc.). Built-in eval is rare in cohort — only ragflow / cognee / WeKnora / MemOS ship evaluators.
- **Searchable toolset** — semantic search over tool descriptions when toolsets get large. Closest cohort analogue: claude-mem's `mem-search` skill, but at framework level rather than skill level.
- **AGENTS.md as the canonical AI-agent guidance** — CLAUDE.md just says "read AGENTS.md first". Cohort first to make AGENTS.md the source-of-truth (most others duplicate or have CLAUDE.md as primary).
- **`telemetry/`** — opt-in PostHog telemetry (with explicit pinned-version-exclusion for known-buggy releases). Cohort first to ship telemetry-as-a-package with version exclusions.
- **Reno for changelog management** — release notes generated from per-PR YAML files (`releasenotes/notes/`); enterprise-grade release engineering.

## Dependencies (KB-relevant)

From `pyproject.toml`:

```
name = "haystack-ai"
version = "2.29.0-rc0"
license = "Apache-2.0"
requires-python = ">=3.10"

# Core (small surface area)
openai>=1.99.2
pydantic, jinja2, pyyaml
networkx                            # Pipeline graphs
tenacity                            # retry
httpx
numpy
jsonschema, docstring-parser
filetype                            # MIME guessing
posthog                             # telemetry
haystack-experimental                # bleeding-edge components

# Plus 50+ haystack_integrations.* sibling packages on PyPI:
# qdrant, weaviate, chroma, pinecone, opensearch, elasticsearch,
# mongodb-atlas, astra-db, faiss, milvus, pgvector, marqo, snowflake,
# anthropic, ollama, cohere, jina, nvidia, voyage, ...
```

License: **Apache-2.0**.

## Tradeoffs

**Pros:**
- **Most mature framework in the cohort** — 6+ years of production usage, large ecosystem.
- **Explicit core-vs-integrations split** — keeps `haystack-ai` install lean; integrations move independently.
- **9 first-class retrievers** + diverse rankers — RAG primitives are well-covered without bolting them on.
- **Pipeline-as-tool primitive** — turn any Pipeline into a tool the agent can invoke; rare in cohort.
- **Human-in-the-loop package** with policy/strategy/interface separation.
- **Evaluation package** built in — RAG quality metrics (faithfulness, groundedness, answer correctness).
- **`super_component/`** for composing framework primitives — extensibility without forking.
- **Reno-based release notes** + telemetry-with-version-exclusions — enterprise release engineering.
- **Apache-2.0** with no enterprise-bolt-on or copyleft.

**Cons:**
- **Framework, not product** — you compose Haystack into a product; it doesn't ship as one.
- **No native memory layer** — agents need long-term memory wired via DocumentStore + custom write components, or via integration with mem0/letta/etc.
- **Vector backends are extras** — `pip install haystack-ai` gets you InMemoryDocumentStore; production backends require `pip install haystack-integrations.{qdrant,weaviate,chroma,…}`.
- **No bi-temporal model** — graphiti-shaped time-aware queries aren't first-class.
- **Pipeline DAGs have a learning curve** — typed sockets and component contracts are powerful but verbose.
- **`haystack-experimental` package gates bleeding-edge features** — you can be on stable 2.29 and still need experimental for the latest MCP/agent flows.

## When to use it

- **Good fit:** teams building production RAG/agent platforms wanting a mature, modular framework; products needing pluggable vector backends + rerankers + LLMs without lock-in; HITL workflows; enterprises wanting Apache-2.0 + version-pinned reno-based release engineering.
- **Bad fit:** single-binary CLIs / laptop-only deployments; products that want a memory-framework primitive (use mem0/graphiti/MemOS); products needing built-in long-term memory or bi-temporal queries.
- **Closest alternative:** [LangChain](https://github.com/langchain-ai/langchain) (used as the runtime in [`bytedance/deer-flow`](surveys/bytedance__deer-flow.md), [`1Panel-dev/MaxKB`](surveys/1Panel-dev__MaxKB.md)) — broader ecosystem but messier API; Haystack is more typed and more pipeline-graph-shaped. [`infiniflow/ragflow`](surveys/infiniflow__ragflow.md) is the kb-app product built *on top of* this kind of framework. For agent-memory, use [`mem0ai/mem0`](surveys/mem0ai__mem0.md) or [`getzep/graphiti`](surveys/getzep__graphiti.md).

## Code pointers (evidence)

- Core component / pipeline runtime: [`haystack/core/`](https://github.com/deepset-ai/haystack/tree/main/haystack/core) (`component/`, `pipeline/`, `super_component/`, `serialization.py`, `type_utils.py`)
- 24 component categories: [`haystack/components/`](https://github.com/deepset-ai/haystack/tree/main/haystack/components) (agents, audio, builders, caching, classifiers, connectors, converters, embedders, evaluators, extractors, fetchers, generators, joiners, preprocessors, query, rankers, readers, retrievers, routers, samplers, tools, validators, websearch, writers)
- 9 retriever types: [`haystack/components/retrievers/`](https://github.com/deepset-ai/haystack/tree/main/haystack/components/retrievers) — 7 single-file (`auto_merging_retriever.py`, `filter_retriever.py`, `multi_query_embedding_retriever.py`, `multi_query_text_retriever.py`, `multi_retriever.py`, `sentence_window_retriever.py`, `text_embedding_retriever.py`) + 2 in-memory variants (`in_memory/bm25_retriever.py`, `in_memory/embedding_retriever.py`)
- Tool model (Tool / from_function / component_tool / pipeline_tool / searchable_toolset / Toolset): [`haystack/tools/`](https://github.com/deepset-ai/haystack/tree/main/haystack/tools)
- Agent: [`haystack/components/agents/agent.py`](https://github.com/deepset-ai/haystack/blob/main/haystack/components/agents/agent.py) + [`agents/state/`](https://github.com/deepset-ai/haystack/tree/main/haystack/components/agents/state)
- Human-in-the-loop: [`haystack/human_in_the_loop/`](https://github.com/deepset-ai/haystack/tree/main/haystack/human_in_the_loop) (`policies.py`, `strategies.py`, `user_interfaces.py`, `dataclasses.py`, `types/`)
- Evaluation: [`haystack/evaluation/`](https://github.com/deepset-ai/haystack/tree/main/haystack/evaluation)
- In-memory DocumentStore (only native backend): [`haystack/document_stores/in_memory/`](https://github.com/deepset-ai/haystack/tree/main/haystack/document_stores/in_memory)
- AGENTS.md (canonical AI-agent guidance) — source of truth that CLAUDE.md defers to.
- Most useful single file to read first: [`haystack/components/__init__.py`](https://github.com/deepset-ai/haystack/blob/main/haystack/components/__init__.py) — exports the 25-category surface area.

## Open questions

- The `haystack-experimental` boundary — what currently lives there, and what's the stabilization criteria for promotion to core?
- Pipeline-as-tool primitive — is it cyclic-graph-safe, or only DAGs?
- Searchable toolset semantics — what's the indexing layer for tool descriptions? Same Document/embedding flow as RAG?
- Human-in-the-loop is rare in cohort — how heavily used is it in production deepset deployments?
- AGENTS.md vs CLAUDE.md — Haystack defers CLAUDE.md to AGENTS.md; is this the codex/AGENTS-format winner, or a cohort split?

---

*Surveyed via the `curating-agentic-kbs` skill. Re-survey scheduled after 30 days of last `pushed_at` change.*

*Audit 2026-05-02: clone-verified against [`VERSION.txt`](https://github.com/deepset-ai/haystack/blob/main/VERSION.txt) (`2.29.0-rc0`), [`haystack/components/`](https://github.com/deepset-ai/haystack/tree/main/haystack/components) (24 category subdirs), [`haystack/components/retrievers/`](https://github.com/deepset-ai/haystack/tree/main/haystack/components/retrievers) (7 single-file + 2 `in_memory/` = 9 retrievers), [`haystack/human_in_the_loop/`](https://github.com/deepset-ai/haystack/tree/main/haystack/human_in_the_loop) (4 files: `policies.py` / `strategies.py` / `user_interfaces.py` / `dataclasses.py` + `types/`). **Corrections:** component categories **25 → 24** (off-by-one); retriever count **8 → 9** (survey listed 7 single-file but said 8; actual includes in-memory bm25 + embedding = 9). **Verified verbatim:** version `2.29.0-rc0`, HITL package files exact (`policies` / `strategies` / `user_interfaces` / `dataclasses`), Apache-2.0 license, NetworkX DAG pipeline runtime.*
