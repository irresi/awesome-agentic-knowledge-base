# circlemind-ai/fast-graphrag

- **Stars:** 3,777 · **Last push:** 2025-11-01 · **Created:** 2024-10-30 · **License:** MIT · **Lang:** Python (3.10–3.12, Poetry, `fast-graphrag` v0.0.5)
- **Category:** graphrag (third in cohort, alongside microsoft/graphrag and HKUDS/LightRAG)
- **Authors:** Luca Pinchetti, Antonio Vespoli, Yuhang Song @ [circlemind.co](https://circlemind.co)

## TL;DR

A **library-only** GraphRAG framework whose entire pipeline lives in a single import — `from fast_graphrag import GraphRAG` — with no daemon, no service, no MCP, no UI. The architectural bet: **personalized PageRank as the primary retrieval primitive** (computed by [`igraph`](https://python.igraph.org/)'s C-backed `personalized_pagerank`) using LLM-extracted query entities as the reset distribution, then cascaded sparse-matrix dot products score relationships and chunks. Persistence is **pickle-only** (`igraph_data.pklz` + hnswlib HNSW + pickled K/V + pickled blobs) inside one `working_dir/`. Distinct positioning: **6× cost claim** vs microsoft/graphrag on Wizard of Oz ($0.08 vs $0.48). **Stagnant**: last push 2025-11-01, version still 0.0.5.

## KB Architecture

### Storage
- All four storage interfaces are pickled to `working_dir/`: `_gdb_igraph.py` (igraph as `igraph_data.pklz`), `_vdb_hnswlib.py` (hnswlib HNSW), `_ikv_pickle.py` (indexed K/V), `_blob_pickle.py` (raw blobs).
- No external DB. No Postgres, no Neo4j, no Milvus/Qdrant, no Redis. The pickle files are the database. **First cohort entry to ship a graphrag library with zero external storage dependencies** (LightRAG has 4×13 backend matrix; microsoft/graphrag emits Parquet artifacts).
- `_namespace.py` exposes a `Workspace` abstraction with checkpoints (`with_checkpoints` wraps async storage transitions).
- Content hashing via `xxhash` (`THash` type) — used to filter duplicate chunks at ingest.

### Ingestion
- `DefaultChunkingService` splits with hierarchical separators including **CJK punctuation** (`。`, `．`, `！`, `？`) before falling back to ASCII (`.`, `!`, `?`); `chunk_token_size` × `TOKEN_TO_CHAR_RATIO=4` converts token budgets to char budgets.
- `DefaultInformationExtractionService` does single-pass LLM entity+relationship extraction, then runs an **iterative "gleaning" loop**: after each extraction, the LLM is asked `entity_relationship_gleaning_done_extraction` (`done` | `continue`); if `continue`, a fresh `entity_relationship_continue_extraction` call adds missed entities. Bounded by `max_gleaning_steps` to cap cost.
- The `domain` + `example_queries` + `entity_types` triple is required at `GraphRAG.__init__` and injected into every extraction prompt as priming — i.e., **declarative typing constraint**, not extracted. This contrasts with LightRAG's open-ended LLM extraction.
- `instructor` (v1.6+) for structured Pydantic-typed LLM outputs; `json-repair` for malformed-JSON recovery; `tenacity` for retries; `aiolimiter` for concurrency.
- `CONCURRENT_TASK_LIMIT` env var caps parallel LLM tasks (relevant for local-model deployments).

### Graph + retrieval
- The `IGraphStorage.score_nodes(initial_weights)` function is the heart of the system:
  ```python
  ppr_scores = self._graph.personalized_pagerank(
      damping=self.config.ppr_damping, directed=False, reset=reset_prob
  )
  ```
  `reset_prob` is the (1 × #entities) sparse vector of LLM-extracted query-entity scores, normalized to a probability distribution. The PPR random-walk then propagates relevance from those query-entities through the graph topology.
- Cascade in `_state_manager.py:_score_*`:
  1. Query → LLM extracts entities → `_score_entities_by_query` builds `(1 × #all_entities)` sparse weights, optionally divided by `_get_entities_to_num_docs()` (`node_specificity` — IDF-style boost for rare entities).
  2. `_score_entities_by_graph` calls `score_nodes(entity_scores)` (the PPR step above).
  3. `_score_relationships_by_entities`: `node_scores · entities_to_relationships_map` (sparse dot product → `(1 × #relationships)`).
  4. `_score_chunks_by_relations`: `relationship_scores · relationships_to_chunks_map` (sparse dot → `(1 × #chunks)`).
- Result: ranked chunks served back to the LLM with `QueryParam(entities_max_tokens=4000, relations_max_tokens=3000, chunks_max_tokens=9000, with_references=False, only_context=False)`.

### Ranking policies
4 pluggable policies in `_policies/_ranking.py`, applied to the PPR scores before token-budget truncation:
- **`RankingPolicy_WithThreshold`** *(default for entities, threshold=0.005; for relationships, default 0.005)* — drops scores below `threshold`, then keeps top `max_entities=128`.
- **`RankingPolicy_TopK`** — keep top-K only (batch size 1 only).
- **`RankingPolicy_Elbow`** — sorts scores, finds the largest first-difference jump, keeps everything above it (knee detection).
- **`RankingPolicy_WithConfidence`** — `raise NotImplementedError("Confidence policy is not supported yet.")` (stub since at least v0.0.5).

### LLM / embedding integrations
3 providers in `_llm/`:
- `_llm_openai.py` — OpenAI (default; also covers OpenAI-compatible endpoints).
- `_llm_genai.py` — Google GenAI / Vertex AI (`google-genai`, `vertexai` deps).
- `_llm_voyage.py` — Voyage AI (`voyageai`).

(Compare to LightRAG's many-provider matrix or microsoft/graphrag's pluggable LLM-config — fast-graphrag picks 3 to support and ships them in-tree.)

### Memory model
**None.** This is a chunk-RAG pipeline with a knowledge-graph index; no conversation memory, no persona, no memory triggers. The "GraphRAG" here is *retrieval-side only*. Pair with a separate memory framework (mem0, letta, llama_index Memory, …) for agent-loop personalization.

### MCP
**None.** No MCP server, no MCP client, no tool-use surface. The library is meant to be embedded inside a larger agent harness that owns the agent/MCP layer.

## Notable design choices

- **PageRank as the core retrieval algorithm** — most cohort graphrag entries score chunks via vector similarity + LLM rerank. fast-graphrag instead lets graph topology do the work: extract query entities → seed PPR → walk the graph → cascade scores down the entity → relationship → chunk lattice via sparse-matrix products. The `igraph` C backend makes this O(milliseconds) per query.
- **Domain-priming as a typed init contract** — `domain` (free-text) + `example_queries` (list) + `entity_types` (closed-set list) are required `__init__` args and shape every extraction prompt. The user pre-declares the ontology rather than letting the LLM open-endedly type entities. This is closer to a schema-driven KG than to LightRAG's "anything goes" extraction; trades flexibility for precision.
- **Pickle-only persistence** — entire system serializes to `working_dir/*.pklz`. No DB ops to learn, but no concurrent-writer support and no fan-out across nodes either. Workspace + checkpoints give in-process transactional safety.
- **Iterative gleaning loop** — after the first extraction pass, the LLM itself decides via a `done`|`continue` self-check whether more entities need to be added, capped at `max_gleaning_steps`. Cohort-novel: an explicit *quality-vs-cost knob* turned by the LLM rather than by code thresholds.
- **Cost-anchored positioning** — README's headline number is `$0.08 vs $0.48 (6×)` on Wizard of Oz. The `benchmarks/` directory ships `2wikimultihopqa_{51,101}.json` plus result dumps under `benchmarks/results/{lightrag,nano,graph,vdb}/` — the comparison set is published in-tree.
- **Multilingual chunking** — separator list interleaves Chinese full-width and ASCII punctuation (`。`/`．`/`！`/`？`/`.`/`!`/`?`), so CJK ingestion works without configuration.

## Dependencies

`igraph^0.11`, `xxhash^3.5`, `pydantic^2.9`, `scipy^1.14`, `scikit-learn^1.5`, `tenacity^9`, `openai^1.52`, `hnswlib^0.8`, `instructor^1.6`, `tiktoken^0.8`, `aiolimiter^1.1`, `google-genai^1.3`, `vertexai^1.71`, `sentencepiece^0.2`, `json-repair^0.39`, `voyageai^0.3`. **No FastAPI, no databases, no agent SDK, no MCP.**

## Tradeoffs

- **For**: minimal install (pure Python + igraph C bindings), no infra to provision, fast PPR via igraph C-core, declarative entity-type typing for higher-precision extraction, gleaning loop catches missed entities, multilingual chunking out-of-the-box, in-tree benchmarks for reproducible cost claims, library shape composes cleanly under any agent harness.
- **Against**: **stagnant since 2025-11-01** (~6-month gap before this 2026-05-02 audit); still v0.0.5 (no SemVer-guaranteed API stability); pickle-only persistence prevents concurrent writers; no service / MCP / UI = the integrator owns all the wiring; only 3 LLM provider integrations (OpenAI / Google / Voyage); `RankingPolicy_WithConfidence` is a stub (`NotImplementedError`); no streaming responses; no built-in evaluation harness despite the cost-comparison benchmarks shipping in-tree (the comparison was a one-shot artifact, not a continuously-runnable suite).

## When to use vs. cohort

- vs. **microsoft/graphrag** — both are graphrag pipelines. microsoft/graphrag emits Parquet artifacts and runs DRIFT global/local search via community summaries; fast-graphrag stays in-process via PPR. Pick fast-graphrag for embedded use under tight cost constraints; pick microsoft/graphrag when community-level abstraction is required or Parquet handoff suits the team.
- vs. **HKUDS/LightRAG** — both are graphrag libraries. LightRAG is a long-running service with 4×13 backend matrix and 6 named retrieval modes (`local`/`global`/`hybrid`/`mix`/`naive`/`bypass`); fast-graphrag is a single-pickle library with one PPR-based retrieval. Pick LightRAG when you need backend-portability and an HTTP API; pick fast-graphrag when you want zero-infra and lower cost.
- vs. **getzep/graphiti** — graphiti is bitemporal-KG-as-a-service with 16 search recipes × 4 reranker modes. fast-graphrag has no temporal model and one ranking pipeline. Pick graphiti when as-of-date queries matter; pick fast-graphrag when you only need topical retrieval.

## Code pointers

- Entry: [fast_graphrag/__init__.py](https://github.com/circlemind-ai/fast-graphrag/blob/main/fast_graphrag/__init__.py) (`GraphRAG` dataclass + `Config` defaults).
- PageRank scoring: [fast_graphrag/_storage/_gdb_igraph.py:165](https://github.com/circlemind-ai/fast-graphrag/blob/main/fast_graphrag/_storage/_gdb_igraph.py#L165) (`score_nodes` → `personalized_pagerank`).
- Score cascade: [fast_graphrag/_services/_state_manager.py:285-310](https://github.com/circlemind-ai/fast-graphrag/blob/main/fast_graphrag/_services/_state_manager.py#L285-L310) (`_score_entities_by_query` / `_score_entities_by_graph` / `_score_relationships_by_entities` / `_score_chunks_by_relations`).
- Gleaning loop: [fast_graphrag/_services/_information_extraction.py:76-100](https://github.com/circlemind-ai/fast-graphrag/blob/main/fast_graphrag/_services/_information_extraction.py#L76-L100) (`_gleaning`).
- Ranking policies: [fast_graphrag/_policies/_ranking.py](https://github.com/circlemind-ai/fast-graphrag/blob/main/fast_graphrag/_policies/_ranking.py) (4 classes; `WithConfidence` is `NotImplementedError`).
- Multilingual chunk separators: [fast_graphrag/_services/_chunk_extraction.py:13-26](https://github.com/circlemind-ai/fast-graphrag/blob/main/fast_graphrag/_services/_chunk_extraction.py).
- Benchmarks: [benchmarks/questions/2wikimultihopqa_{51,101}.json](https://github.com/circlemind-ai/fast-graphrag/tree/main/benchmarks/questions) + [benchmarks/results/{lightrag,nano,graph,vdb}/](https://github.com/circlemind-ai/fast-graphrag/tree/main/benchmarks/results).

## Open questions

- The repo has been stagnant for ~6 months at v0.0.5. circlemind.co's commercial offering (referenced in README badges) may be where active development moved — needs a status check before recommending in production.
- `RankingPolicy_WithConfidence` is a `NotImplementedError` stub. Was confidence-based ranking abandoned, or is it pending the next release?
- The 6× cost claim uses Wizard of Oz as a fixed-corpus benchmark. How does the ratio scale on real production corpora (where igraph's working-set may exceed RAM)?
- No memory layer at all — does circlemind.co intend fast-graphrag to pair with a memory-framework cohort entry (e.g., mem0, letta) for production agent loops, or with their own commercial offering?

---

*Audit 2026-05-02: clone-verified against [circlemind-ai/fast-graphrag@main](https://github.com/circlemind-ai/fast-graphrag) (last commit 2025-11-01). Version 0.0.5 / MIT confirmed in `pyproject.toml`. Personalized PageRank via igraph confirmed at `_storage/_gdb_igraph.py:172` (`self._graph.personalized_pagerank(damping=…, directed=False, reset=reset_prob)`). Score cascade verified line-by-line at `_services/_state_manager.py:285-310`. Gleaning loop verified at `_services/_information_extraction.py:76-100`. 4 ranking policies enumerated from `_policies/_ranking.py` (WithThreshold default threshold=0.005 + max_entities=128; TopK; Elbow; WithConfidence raises NotImplementedError). LLM providers (OpenAI / Google GenAI / Voyage) enumerated from `_llm/` directory. Storage adapters (igraph .pklz / hnswlib / pickled k/v / pickled blob) enumerated from `_storage/`. Multilingual separators verified verbatim from `_services/_chunk_extraction.py:13-26`. No MCP, no FastAPI, no DB confirmed by exhaustive `pyproject.toml` dep grep. Stagnation flag: pushed_at 2025-11-01 vs audit date 2026-05-02 = ~6 months. Corrections: none (first-pass survey).*
