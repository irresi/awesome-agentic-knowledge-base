# memgraph/memgraph

- **Stars:** 3,966 · **Last push:** 2026-05-02 · **Created:** 2020-09-21 · **License:** **APL + BSL + MEL** (triple) · **Lang:** C/C++ (CMake + Conan)
- **Category:** infra-layer (graph database; 2nd cohort entry alongside [`FalkorDB/FalkorDB`](FalkorDB__FalkorDB.md))

## TL;DR

A Cypher-compatible **in-memory graph database** that bundles **text indexes (Tantivy)** + **vector indexes (USearch)** + **graph traversal** in a single ATOMIC database operation — so retrieval pipelines can run as one query instead of being scattered across multiple systems. C/C++ engine, NuRaft for HA consensus, RocksDB for disk persistence, Conan-managed dependency stack. **Triple-licensed**: APL (Apache Public) for permissive parts, BSL 1.1 for the core engine (auto-converts to Apache after a few years), MEL (Memgraph Enterprise License) for paid features. Source-of-truth file says: *"variously licensed under the Business Source License 1.1 (BSL), the Memgraph Enterprise License (MEL)"* with APL also in `licenses/APL.txt`. Distinct from FalkorDB (Redis-module shape, sparse-matrix + GraphBLAS, SSPL) — memgraph is a standalone server with its own consensus + index layer.

## KB Architecture (as a graph engine)

### Storage
- **In-memory primary**: `src/storage/v2/inmemory/` — primary data lives in RAM with Delta + commit log for write durability. Snapshot system in `storage/v2/durability/`.
- **Disk persistence**: ADR 003 documents RocksDB integration (`rocksdb-memgraph` is a custom Conan-managed fork). Used for snapshots + WAL.
- **Indexes** (multiple types in `storage/v2/`): `label_index`, `label_property_index`, `edge_property_index`, `edge_type_index`, `edge_type_property_index`, `unique_constraints`, plus `async_indexer` for non-blocking concurrent index creation (ADR 004).
- **Text search via Tantivy** (ADR 001, 2024-01-05) — Rust full-text search engine, integrated via FFI. Provides regex, full-text, fuzzy, aggregations over text data. Cohort first to ship a Rust text-search engine (Tantivy) embedded in a C++ graph DB.
- **Vector search via USearch** (ADR 005, 2024-11-15) — Unum's high-performance ANN library, in-memory + on-disk + thread-safe + with quantization support. Cohort first to ship USearch-backed vector indexes co-located with graph data (other cohort vector backends use Faiss / hnswlib / Milvus / pgvector / Qdrant — none use USearch).

### Query layer
- **Cypher-compatible** via own parser (`src/query/`). Neo4j-wire-compatible Bolt protocol enables existing Neo4j drivers to connect.
- **Single-query atomic retrieval** — README's headline architectural claim: "*Memgraph provides both [text + vector + graph] in a single query layer: built-in text and vector indexes for similarity search combined with full graph traversal, so retrieval pipelines can run as a single atomic database operation instead of being scattered across multiple systems.*"
- Query memory tracking with per-DB granularity (ADR 005, 007) — concurrent multi-tenant workloads can be isolated by per-database memory budgets.
- Streaming sources in `src/integrations/`: `kafka` + `pulsar` (custom `pulsar-client-cpp-memgraph` fork) — live graph updates from event streams.
- `arrow_parquet` support in `src/query/` — Parquet I/O for bulk import/export.

### High availability
- **NuRaft** for consensus (ADR 002, 2024-01-10) — eBay's NuRaft is the chosen Raft impl after the team tried writing their own Raft 3 times unsuccessfully ("approximately 4 person-weeks of engineering work each time" per the ADR's "Problem" section, refreshingly honest).
- `src/coordination/` + `src/distributed/` + `src/replication/` + `src/replication_handler/` + `src/replication_coordination_glue/` — full HA stack.
- `lamport_clock.cpp` in `src/distributed/` for distributed event ordering.

### Multi-tenancy + RBAC
- ADR 005 (Multi-tenant RBAC) + `src/dbms/tenant_profiles.cpp` + `src/auth/` — per-database isolation with role-based access control.
- `src/license/` — triggers feature gates for MEL-licensed (Enterprise) capabilities.
- `src/audit/` — audit logging for compliance.

### Streaming / integrations
- 2 streaming source modules in `src/integrations/`: **kafka** + **pulsar**. CSV import via `src/csv/`. CDC (change data capture) is natively supported via the integrations layer.
- **MAGE** (Memgraph Advanced Graph Extensions) lives in a `mage/` subdirectory with `Dockerfile.cugraph` (cuGraph integration — GPU graph algorithms, cohort first).
- Pulsar-client-cpp fork (`pulsar-client-cpp-memgraph`) and rocksdb fork (`rocksdb-memgraph`) and librdtsc fork (`librdtsc-memgraph`) and nuraft fork (`nuraft-memgraph`) and nlohmann_json fork (`nlohmann_json-memgraph`) — **5 in-house Conan-managed dependency forks**.

### Architecture Decision Records (cohort-first formal ADR practice)
9 ADRs in [`ADRs/`](https://github.com/memgraph/memgraph/tree/master/ADRs):
- `001_tantivy.md` (text search)
- `002_nuraft.md` (HA consensus)
- `003_rocksdb.md` (disk persistence)
- `004_concurrent_index_creation.md`
- `005_multi_tenant_rbac.md`
- `005_query_memory_tracking_refactor.md`
- `005_usearch.md` (vector search)
- `006_ninja_conan_build.md`
- `007_db_specific_memory_tracking.md`

Each ADR documents Author / Status / Date / Problem / Criteria / Decision — cohort-first formal architecture-decision discipline.

### Build + dependencies
- **Conan 2.x** for C++ package management. `conan.lock` pins **40+ dependencies** including custom forks (rocksdb-memgraph, nuraft-memgraph, pulsar-client-cpp-memgraph, librdtsc-memgraph, nlohmann_json-memgraph, mgclient).
- **Ninja** + CMake build (ADR 006). Build via `build.sh`.
- Core deps include: `usearch/2.21`, `simdjson/4.2`, `xsimd/14`, `stringzilla/3.11`, `range-v3/0.12`, `protobuf/3.21`, `openssl/3.0`, `librdkafka/2.6`, `s2n/1.5`.

## Notable design choices

- **Triple license** (APL + BSL + MEL) — most layered cohort license stack. APL for `licenses/APL.txt` permissive third-party pieces, BSL 1.1 for the core engine (BSL converts to Apache-2.0 after a few years), MEL for paid Enterprise features. Implication: the BSL-covered code becomes Apache-2.0 in time, but `src/license/` gates MEL features via runtime checks.
- **Single atomic query for text + vector + graph** — Tantivy + USearch + label-property indexes co-located in the same database, queried through one Cypher statement. Cohort-first single-system retrieval primitive (vs FalkorDB's RediSearch-bundle-but-separate-modules pattern, vs ragflow's separate Elasticsearch + vector backend split).
- **Custom Conan forks for 5 deps** (rocksdb / nuraft / pulsar-client-cpp / librdtsc / nlohmann_json) — patches required to make stock libraries fit memgraph's threading + memory model. Cohort-first deep customization at the dep layer.
- **NuRaft adopted after 3 in-house Raft attempts failed** — the ADR honestly documents 3 prior attempts ("approximately 4 person-weeks of engineering work each time") before adopting eBay's NuRaft. Most cohort entries hide this kind of pivot history.
- **9 formal ADRs** with structured Author/Status/Date/Problem/Criteria/Decision template — cohort-first formal architecture-decision practice (most cohort repos document architecture in CLAUDE.md / README only).
- **GPU graph algorithms via MAGE/cugraph** — `mage/Dockerfile.cugraph` ships a NVIDIA-cuGraph-backed Docker image. Cohort first GPU-accelerated graph compute.
- **Streaming CDC via Kafka + Pulsar** — first-class graph mutation from event streams. Most cohort graph-store entries (Neo4j / Kuzu / nano-vectordb / NetworkX) require batch ingest.

## Tradeoffs

- **For**: cohort-first **single-query atomic retrieval** (text + vector + graph in one Cypher statement); cohort-first formal **ADR practice** (9 ADRs); cohort-first **NuRaft HA consensus**; cohort-first **USearch vector backend**; cohort-first **GPU graph algorithms** (cuGraph via MAGE); production-grade Cypher engine; Bolt-wire compatibility (Neo4j drivers connect); kafka + pulsar streaming sources; concurrent index creation (non-blocking, ADR 004); per-DB memory tracking (ADR 007); refreshingly honest ADR for NuRaft documenting 3 prior failed attempts.
- **Against**: **triple license complexity** (APL + BSL + MEL) — consumers need to verify per-file what license applies; in-memory primary means RAM is the working-set bound (vs FalkorDB's Redis-key namespaced, or Neo4j's disk-primary); 5 in-house Conan dep forks (rocksdb / nuraft / pulsar-cpp / librdtsc / nlohmann_json) = patch-maintenance burden; C++ codebase = higher contributor barrier than Python/JS cohort peers; MEL-gated features (HA replication tier, audit logging tier) push production setups toward the commercial offering.

## When to use vs. cohort

- vs. **FalkorDB** — both are graph engines for AI-context workloads. FalkorDB: SSPL, Redis-module shape, sparse-matrix + GraphBLAS algebra, RediSearch bundled (text + vector via Redis modules), no built-in HA. memgraph: APL+BSL+MEL, standalone server, in-memory storage with RocksDB persistence, Tantivy + USearch indexes baked into the storage layer, NuRaft HA. Pick FalkorDB when Redis ops + GraphBLAS algebra fit; pick memgraph when single-query atomic text+vector+graph retrieval + HA matter more than license simplicity.
- vs. **Neo4j** (not surveyed; cohort consumer via graphiti / cognee / mem0 / WeKnora / llama_index) — Neo4j is JVM-based with broader ecosystem, Apache-2.0 community / GPL-3.0 Enterprise. memgraph is C++ + Bolt-compatible (Neo4j drivers work) + in-memory primary. memgraph is faster on multi-hop traversals; Neo4j has the larger documentation ecosystem.
- vs. **Kuzu** (cohort consumer via mem0 / graphiti / cognee) — Kuzu is embeddable (single-process, like SQLite); memgraph is a server. Pick Kuzu when you want graph-as-a-library; pick memgraph when you want graph-as-a-service.

## Used by (cohort)

- **Already cross-referenced**: [`FalkorDB`](FalkorDB__FalkorDB.md) survey lists memgraph as an alternative ("Cypher + in-memory, BSL after 2 years"). [`mem0`](mem0ai__mem0.md), [`getzep/graphiti`](getzep__graphiti.md), [`topoteretes/cognee`](topoteretes__cognee.md) integrations exist via Neo4j Bolt-wire compatibility.
- [`run-llama/llama_index`](run-llama__llama_index.md) ships `llama-index-graph-stores-memgraph` (1 of its 7 graph_stores adapters).

## Code pointers

- Storage v2 entry: [`src/storage/v2/storage.cpp`](https://github.com/memgraph/memgraph/blob/master/src/storage/v2/storage.cpp).
- Index types: [`src/storage/v2/{label,label_property,edge_property,edge_type,edge_type_property}_index.{cpp,hpp}`](https://github.com/memgraph/memgraph/tree/master/src/storage/v2).
- Async (non-blocking) indexer: [`src/storage/v2/async_indexer.cpp`](https://github.com/memgraph/memgraph/blob/master/src/storage/v2/async_indexer.cpp).
- Cypher query interpreter: [`src/query/cypher_query_interpreter.cpp`](https://github.com/memgraph/memgraph/blob/master/src/query/cypher_query_interpreter.cpp).
- Streaming sources: [`src/integrations/{kafka,pulsar}/`](https://github.com/memgraph/memgraph/tree/master/src/integrations).
- HA coordinator: [`src/coordination/`](https://github.com/memgraph/memgraph/tree/master/src/coordination) + [`src/replication/`](https://github.com/memgraph/memgraph/tree/master/src/replication).
- Multi-tenant + RBAC: [`src/dbms/tenant_profiles.cpp`](https://github.com/memgraph/memgraph/blob/master/src/dbms/tenant_profiles.cpp) + [`src/auth/`](https://github.com/memgraph/memgraph/tree/master/src/auth).
- License gates: [`src/license/`](https://github.com/memgraph/memgraph/tree/master/src/license).
- Audit logging: [`src/audit/`](https://github.com/memgraph/memgraph/tree/master/src/audit).
- 9 ADRs: [`ADRs/`](https://github.com/memgraph/memgraph/tree/master/ADRs) — 001 Tantivy / 002 NuRaft / 003 RocksDB / 004 Concurrent Index / 005 Multi-tenant RBAC / 005 Query Memory Tracking / 005 USearch / 006 Ninja+Conan Build / 007 DB-specific Memory Tracking.
- Conan dep lock with custom forks: [`conan.lock`](https://github.com/memgraph/memgraph/blob/master/conan.lock) (5 `*-memgraph` forks).
- MAGE GPU module: [`mage/Dockerfile.cugraph`](https://github.com/memgraph/memgraph/blob/master/mage/Dockerfile.cugraph).

## Open questions

- **License-mix runtime semantics** — when a self-hoster builds memgraph from source, what triggers MEL gates? Is it just the `src/license/` runtime checks, or are some files compiled out without an MEL key?
- **USearch vs FalkorDB-RediSearch vector quality** — both ship vector indexes co-located with graph data. Is there a benchmark comparing recall/QPS for typical graphRAG workloads?
- **GPU MAGE adoption** — the `Dockerfile.cugraph` exists but cuGraph is heavyweight; what fraction of memgraph users actually deploy MAGE-cugraph in production vs the CPU-only image?
- **Streaming + HA consistency** — when Kafka/Pulsar streams update a NuRaft-replicated graph, what's the consistency model? Does the streaming layer block on Raft commit?
- **40-dep Conan stack** with 5 in-house forks: what's the upgrade cadence relative to upstream releases?

---

*Audit 2026-05-02: clone-verified against [memgraph/memgraph@master](https://github.com/memgraph/memgraph) (last commit 2026-05-02 01:47). License confirmed in `LICENSE` (BSL + MEL with reference to `licenses/APL.txt`, `licenses/BSL.txt`, `licenses/MEL.pdf`). C/C++ + CMake + Conan build verified by `CMakeLists.txt` + `conan.lock`. 9 ADRs enumerated by `ls ADRs/` (001 Tantivy / 002 NuRaft / 003 RocksDB / 004 Concurrent Index / 005 Multi-tenant RBAC / 005 Query Memory Tracking / 005 USearch / 006 Ninja+Conan Build / 007 DB-specific Memory Tracking). Tantivy decision verified at `ADRs/001_tantivy.md` (status APPROVED, 2024-01-05, Author Marko Budiselic). USearch decision verified at `ADRs/005_usearch.md` (status APPROVED, 2024-11-15, Authors Marko Budiselic + David Ivekovic). NuRaft decision (with 3 prior failed Raft attempts noted) verified at `ADRs/002_nuraft.md`. Streaming sources (kafka + pulsar) verified by `ls src/integrations/`. 5 in-house Conan dep forks (rocksdb-memgraph, nuraft-memgraph, pulsar-client-cpp-memgraph, librdtsc-memgraph, nlohmann_json-memgraph) verified by `grep "memgraph" conan.lock`. MAGE cuGraph verified by `find . -name 'Dockerfile.cugraph'`. Multi-tenant RBAC verified by `src/dbms/tenant_profiles.cpp` existence. README single-atomic-retrieval claim verified verbatim from `README.md:42-47`. Corrections: none (first-pass survey).*
