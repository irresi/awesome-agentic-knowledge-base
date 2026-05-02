# Survey: FalkorDB/FalkorDB

**Date:** 2026-05-02
**Stars:** 4,290 · **Last push:** 2026-04-30 · **Created:** 2023 (forked from RedisGraph)
**Category:** infra-layer
**Slug:** [FalkorDB/FalkorDB](https://github.com/FalkorDB/FalkorDB)

---

## TL;DR (3 lines)

- **What it is:** First **infra-layer** entry in this cohort — a graph-database engine (not a memory framework or KB app) loaded as a **Redis module** and consumed by other agentic memory frameworks. Tagline: "Ultra-fast, multi-tenant Graph Database powering Generative AI, Agent Memory, Cloud Security, and Fraud Detection." Forked from Redis Labs' RedisGraph after upstream archival; license: **SSPL** (Server Side Public License — cohort first).
- **How its KB works:** **Sparse-matrix representation of adjacency matrices + linear-algebra-over-graphs** via [GraphBLAS](https://graphblas.org/). Property Graph Model + OpenCypher (libcypher-parser bundled), with **Bolt protocol support** (Neo4j-wire-compatible) so existing Neo4j drivers can connect. Multi-tenant via per-graph namespacing inside a single Redis instance. C engine + Rust core (`deps/FalkorDB-core-rs`), bundling RediSearch for text indexing.
- **Verdict:** Pick when you need a high-throughput Cypher-compatible graph DB that's lighter ops than Neo4j (single Redis instance, no JVM) and OK with SSPL. As surveyed evidence: [`getzep/graphiti`](surveys/getzep__graphiti.md) ships FalkorDB as one of its four graph backends; [`run-llama/llama_index`](surveys/run-llama__llama_index.md) ships it as `llama-index-graph-stores-falkordb` (1 of 7 graph_stores adapters). Skip if you need a managed graph service or have legal/business issues with SSPL.

## KB Architecture (as a graph engine, not a memory framework)

### Storage
- **Vector store:** Bundled **RediSearch** module ships in [`deps/RediSearch/`](https://github.com/FalkorDB/FalkorDB/tree/master/deps/RediSearch) — provides text + vector indexing inside the same Redis instance. Vector indexes can be created on graph-node properties via OpenCypher extensions.
- **Graph store:** **The product itself.** Sparse-matrix-based adjacency representation (matrices store source / target / relationship-type tuples) operated on with GraphBLAS algebra. Per-graph keyed by Redis key name, supporting multi-tenancy in a single binary.
- **Metadata / structured:** All resident in Redis memory + RDB / AOF persistence. Bolt protocol stack ([`src/bolt/`](https://github.com/FalkorDB/FalkorDB/tree/master/src/bolt)) provides Neo4j-wire-compatible connectivity.
- **Object / blob:** N/A — pure graph engine.

### Ingestion / Extraction
- **Source types accepted:** OpenCypher `CREATE` / `MERGE` / `LOAD CSV` (via bundled libcsv); `bulk_insert/` for batch graph load; `effects/` module for replication/replay. CSV ingestion through [`src/csv_reader/`](https://github.com/FalkorDB/FalkorDB/tree/master/src/csv_reader) + libcsv.
- **Chunking strategy:** N/A — chunking is the consumer's responsibility.
- **Entity / fact extraction:** N/A — FalkorDB stores graphs the consumer constructs.
- **Schema:** Property Graph Model (nodes + relationships + labels + properties), with [`src/schema/`](https://github.com/FalkorDB/FalkorDB/tree/master/src/schema) for label/property indexes.

### Retrieval
- **Modes:** **OpenCypher** (full standard + proprietary extensions). Algorithmic retrieval via LAGraph algorithms (PageRank, BFS, label propagation, …). Constraint enforcement (`src/constraint/`), filter trees (`src/filter_tree/`), execution-plan optimizer (`src/execution_plan/`), arithmetic ops (`src/arithmetic/`).
- **Reranker:** N/A.
- **Top-k defaults:** Per OpenCypher `LIMIT` / `ORDER BY`.
- **Context assembly:** Result-set serialization (`src/resultset/`), with native types (`src/datatypes/`) for graph-aware return values.

### Memory model
- **Tiers:** N/A as a memory framework. This is the storage substrate; tier semantics live in the consuming repo (graphiti, mem0, custom apps).
- **Bi-temporal:** Not native — users encode temporal properties on edges/nodes (e.g., `:Edge {valid_at, invalid_at}`) and filter via Cypher.
- **Self-update mechanism:** N/A.
- **Decay / forgetting:** N/A — `MATCH … DELETE` / TTL via Redis `EXPIRE` on the graph key.

### MCP / connectors
- **MCP server exposed:** **No.** FalkorDB exposes Redis commands (`GRAPH.QUERY`, `GRAPH.RO_QUERY`, `GRAPH.PROFILE`, `GRAPH.LIST`, `GRAPH.DELETE`, …) and the Bolt protocol; downstream tools wrap MCP around it.
- **MCP client used:** **No.**
- **Native connectors:** N/A — accessed by Redis clients (any language) or Bolt-compatible Neo4j drivers.
- **Tool-call surface:** Cypher procedures registered via `src/procedures/` — cohort-scoped graph algorithms callable from `CALL`.

### Notable design choices
- **GraphBLAS + sparse matrices + LAGraph** — the architectural bet that distinguishes FalkorDB from Neo4j / Memgraph. Adjacency matrices are stored sparsely; queries become matrix multiplications + element-wise operations. Combines well with workloads that batch many traversals.
- **Built as a Redis module** — single-binary deployment; ops surface = "run Redis with `loadmodule`". Multi-tenancy = many keys in one instance. Works with Redis Cluster for horizontal scale.
- **Bolt-protocol compatibility** — existing Neo4j Python / Go / Java / TS drivers work via the bundled bolt stack ([`src/bolt/`](https://github.com/FalkorDB/FalkorDB/tree/master/src/bolt)) — drop-in for Neo4j → FalkorDB swaps.
- **C engine + Rust core (`FalkorDB-core-rs`)** — C surface for Redis-module integration; Rust bundle handles core data-structure work. Cargo workspace includes one member.
- **RediSearch bundled** — graph-property text indexes + vector indexes co-located with the graph data. Closest cohort analogue: WeKnora's Neo4j-as-vector pattern, but FalkorDB does it via the bundled RediSearch module.
- **SSPL-only license** — same license as MongoDB / Elasticsearch (post-2018). Hosting providers must open-source their hosting infra. Restrictive for SaaS but unrestrictive for self-hosted deployments.
- **12 bundled deps in `deps/`** (1 Rust core + 11 C deps) — `FalkorDB-core-rs` (Rust core), `GraphBLAS`, `LAGraph`, `RediSearch`, `libcsv`, `libcurl`, `libcypher-parser` (OpenCypher), `oniguruma` (regex), `quickjs` (JavaScript-in-procedures), `rax` (radix tree), `utf8proc` (Unicode normalization), `xxHash` (fast hashing). Self-contained — no external graph engine.
- **Performance benchmarks at [benchmark.falkordb.com](https://benchmark.falkordb.com/)** — public benchmark dashboard.

## Dependencies (KB-relevant)

From `Cargo.toml` + bundled `deps/`:

```
# Cargo workspace member
deps/FalkorDB-core-rs            # Rust core

# Bundled C deps (deps/)
GraphBLAS                        # SuiteSparse:GraphBLAS — sparse-matrix ops
LAGraph                          # Graph algorithms over GraphBLAS
RediSearch                       # Text + vector indexing
libcypher-parser                 # OpenCypher AST
libcsv, libcurl                  # I/O
oniguruma                        # Regex
quickjs                          # JS engine for stored procedures
rax                              # Adaptive radix tree
utf8proc                         # Unicode normalization
xxHash                           # Fast non-cryptographic hashing
```

License: **SSPL** ([`LICENSE.txt`](https://github.com/FalkorDB/FalkorDB/blob/master/LICENSE.txt)).

## Tradeoffs

**Pros:**
- **Lower ops surface than Neo4j** — single-binary Redis module; no JVM; no separate cluster service.
- **GraphBLAS + linear-algebra-over-graphs** — distinct algorithmic angle; good for batch traversals (e.g., subgraph extraction, multi-hop pattern matching).
- **OpenCypher + Bolt-protocol compatibility** — drops in for existing Neo4j-driver code; switching cost is small for Cypher-only consumers.
- **Bundled RediSearch** for text + vector inside the same instance — co-located graph + vector + text in one process.
- **Multi-tenant via Redis-key namespacing** — many small graphs scale better than many small Neo4j databases.
- **Active development with public benchmarks**.
- **Used in production by [`getzep/graphiti`](surveys/getzep__graphiti.md)** — surveyed cohort evidence that the engine works for agent-memory workloads.

**Cons:**
- **SSPL license** — requires hosting providers to open-source surrounding infra. Blocks fork-and-host-as-SaaS business models. Some legal envelopes also reject SSPL outright.
- **Less mature ecosystem** than Neo4j — fewer GUI tools, fewer educational materials, narrower driver ecosystem outside the Bolt-compatible drivers.
- **Memory-resident** — graphs must fit in RAM for hot working set; cold data persists via RDB / AOF but isn't lazily paged in.
- **Some Cypher dialect divergences** — proprietary extensions exist; portability between FalkorDB ↔ Neo4j ↔ Memgraph is not 100%.
- **Lower-level than memory frameworks** — consumers (graphiti / mem0 / custom apps) still need to design schemas + write extraction prompts + handle bi-temporal logic themselves.
- **Forked from RedisGraph after Redis Labs archived it** — the lineage means some upstream RedisGraph users moved here; signals "infra has its own backstory."

## When to use it

- **Good fit:** memory frameworks / KB apps choosing a graph backend with low ops cost and OpenCypher syntax; teams already running Redis who want graph-native queries on the same instance; deployments wanting Neo4j-driver compatibility without Neo4j's JVM footprint; workloads with many small graphs (multi-tenant memory).
- **Bad fit:** SaaS products where SSPL blocks redistribution; very large graphs (TB+) that won't fit in RAM; teams that need Neo4j Bloom / Aura / Browser ecosystem features; deployments that need only Cypher-99% compatibility (subtle dialect issues exist).
- **Closest alternative:** [Neo4j](https://neo4j.com) — broader ecosystem, JVM ops surface, Apache-2.0 community / GPL Enterprise. [**`memgraph/memgraph`**](memgraph__memgraph.md) — **now a surveyed cohort peer** (post-N=30, iter 53): Cypher + in-memory + Tantivy text + USearch vector + NuRaft HA in a single ATOMIC query, triple-licensed (APL + BSL 1.1 + MEL); FalkorDB's distinct slot vs memgraph is "Redis-module shape with sparse-matrix algebra (GraphBLAS) + RediSearch-bundle" vs memgraph's "standalone server with own consensus + index layer". [Kuzu](https://kuzudb.com) — embeddable graph DB, MIT-licensed; cohort evidence in [`mem0ai/mem0`](surveys/mem0ai__mem0.md), [`getzep/graphiti`](surveys/getzep__graphiti.md), [`topoteretes/cognee`](surveys/topoteretes__cognee.md). FalkorDB's distinct slot vs the cohort overall is "Redis-module shape with sparse-matrix algebra".

## Code pointers (evidence)

- Top-level Redis-module entrypoint: [`src/commands/`](https://github.com/FalkorDB/FalkorDB/tree/master/src/commands) (registers `GRAPH.*` Redis commands)
- Graph storage + schema: [`src/graph/`](https://github.com/FalkorDB/FalkorDB/tree/master/src/graph), [`src/schema/`](https://github.com/FalkorDB/FalkorDB/tree/master/src/schema)
- Cypher parser: [`deps/libcypher-parser`](https://github.com/FalkorDB/FalkorDB/tree/master/deps/libcypher-parser), AST in [`src/ast/`](https://github.com/FalkorDB/FalkorDB/tree/master/src/ast)
- Execution plan / optimizer: [`src/execution_plan/`](https://github.com/FalkorDB/FalkorDB/tree/master/src/execution_plan), filter trees [`src/filter_tree/`](https://github.com/FalkorDB/FalkorDB/tree/master/src/filter_tree)
- Bolt protocol stack: [`src/bolt/`](https://github.com/FalkorDB/FalkorDB/tree/master/src/bolt)
- LAGraph procedures: [`src/procedures/`](https://github.com/FalkorDB/FalkorDB/tree/master/src/procedures)
- GraphBLAS bundle: [`deps/GraphBLAS`](https://github.com/FalkorDB/FalkorDB/tree/master/deps/GraphBLAS)
- Rust core: [`deps/FalkorDB-core-rs`](https://github.com/FalkorDB/FalkorDB/tree/master/deps/FalkorDB-core-rs)
- Most useful single file to read first: the [Official Docs](https://docs.falkordb.com/) → then [`src/commands/`](https://github.com/FalkorDB/FalkorDB/tree/master/src/commands) for the Redis command surface.

## Open questions

- The Rust core (`FalkorDB-core-rs`) — what's its scope? Looks like data-structure work, but the boundary with the C engine merits a deeper read.
- Bolt-protocol compatibility — version coverage? Bolt 5.x?
- SSPL section 13 (hosting clause) — how does it interact with Redis-module redistribution specifically?
- Vector-index integration — is RediSearch used for graph-property vector search, and what's the cohort-relative quality?
- Roadmap on Cypher dialect parity vs Neo4j 5.x.

---

*Surveyed via the `curating-agentic-kbs` skill. Re-survey scheduled after 30 days of last `pushed_at` change.*

*Audit 2026-05-02: clone-verified against [`LICENSE.txt`](https://github.com/FalkorDB/FalkorDB/blob/master/LICENSE.txt) ("Server Side Public License VERSION 1, OCTOBER 16, 2018" verbatim — first line), [`deps/`](https://github.com/FalkorDB/FalkorDB/tree/master/deps) (12 bundled subdirs), [`src/`](https://github.com/FalkorDB/FalkorDB/tree/master/src) (all claimed subdirs present: ast, bolt, commands, csv_reader, graph, procedures, schema). **Correction:** bundled deps **9 → 12** (added `utf8proc` for Unicode normalization and `xxHash` for fast hashing, plus counting `FalkorDB-core-rs` as a 12th workspace dep — survey listed only 9 C deps and treated Rust core separately). **Verified verbatim:** SSPL license (cohort first), Rust core at `deps/FalkorDB-core-rs/` with Cargo.toml + build.rs + src/, GraphBLAS + LAGraph + RediSearch + libcypher-parser + libcsv + libcurl + oniguruma + quickjs + rax all present, Bolt protocol stack at `src/bolt/`, Cypher procedures at `src/procedures/`. **Cohort implication:** the missing utf8proc + xxHash deps strengthen the "self-contained, no external graph engine" claim — FalkorDB ships Unicode normalization + fast hashing as part of its bundle.*
