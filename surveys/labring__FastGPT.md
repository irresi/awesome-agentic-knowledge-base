# Survey: labring/FastGPT

**Date:** 2026-05-01
**Stars:** 27,890 · **Last push:** 2026-04-30 · **Created:** 2023-02-23 · **Version:** `4.0` · **License:** "FastGPT Open Source License" — Apache-2.0 + multi-tenant-SaaS commercial-license requirement + LOGO/copyright preservation
**Category:** kb-app
**Slug:** [labring/FastGPT](https://github.com/labring/FastGPT)

---

## TL;DR (3 lines)

- **What it is:** TypeScript-first knowledge-base + visual workflow platform — Next.js monorepo where end-users build chatbots and agents with drag-and-drop workflows on top of a managed dataset/RAG layer.
- **How its KB works:** Documents → 3rd-party OCR (textin / doc2x) or built-in parsers (pdfjs / mammoth / xlsx / turndown) → chunks tokenized with **jieba (Chinese) + tiktoken (English)** → MongoDB metadata + MinIO blobs + a **pluggable vector backend** (pg/Postgres+pgvector · Milvus · OceanBase · OpenGauss · SeekDB) — hybrid retrieval combines BM25-style jieba scoring with dense vectors, then an external Cohere-compatible reranker API. MCP servers are first-class workflow nodes.
- **Verdict:** Pick when you want **a TypeScript stack**, **strong Chinese-language support**, and **end-user-facing visual workflows** as the agent surface. Skip if your team is Python-native or if you need agentic memory (FastGPT's "memory" is the dataset itself, not a per-agent fact store).

## KB Architecture

### Storage
- **Vector store:** **5 backends** under `packages/service/common/vectorDB/`: **pg** (Postgres+pgvector), **milvus**, **oceanbase**, **opengauss**, **seekdb** — chosen via env-driven controller
- **Graph store:** **none** — no graph-based retrieval layer detected
- **Metadata / structured:** **MongoDB** via Mongoose (`packages/service/common/mongo/`); schemas in `core/dataset/schema.ts`, `core/app/schema.ts`, `core/agentSkills/schema.ts`, etc.
- **Object / blob:** **MinIO** (`@fastgpt-sdk/storage`, `packages/service/common/s3/`)
- **Cache / queue:** **Redis (ioredis)** + **BullMQ** for job queues (training, sync)

### Ingestion / Extraction
- **Source types accepted:** PDF (pdfjs-dist + 3rd-party doc2x/textin OCR), DOCX (mammoth), XLSX (node-xlsx), CSV (papaparse), HTML (turndown / cheerio), code, Markdown
- **Chunking strategy:** **per-format** parsers in `packages/service/worker/` + `core/dataset/training/`; tokenization with **`@node-rs/jieba`** (CJK) and **tiktoken** (English) — explicit Chinese-first design
- **Entity / fact extraction:** **chunk-level only** — there is no LLM-extracted-facts layer; chunks themselves are the unit (different from mem0's atomic-fact extraction)
- **Schema:** datasets → collections → data items (chunks); flat hierarchy with rich tagging via `MongoDatasetCollectionTags`
- **OCR:** delegated to paid 3rd-party services (textin, doc2x) under `packages/service/thirdProvider/` — not built-in

### Retrieval
- **Modes:** **hybrid** — `DatasetSearchModeEnum` defines multiple modes; `recallFromVectorStore` (dense) + `jiebaSplit` (BM25-style sparse) combined via `datasetSearchResultConcat` (`packages/service/core/dataset/search/controller.ts`)
- **Reranker:** **REST-API model-agnostic** — `core/ai/rerank/index.ts` calls any Cohere-compatible reranker endpoint; supports BGE, Cohere, Jina, etc. via the same wire format
- **Top-k defaults:** configurable per dataset-search node in workflow
- **Context assembly:** token-budget-aware (tiktoken counting); query extension via `datasetSearchQueryExtension`
- **Filters:** rich — tags `$and`/`$or`/null, time ranges via `createTime: { $gte, $lte }`

### Memory model
- **Tiers:** **none for agents** — the dataset/KB *is* the memory; chat history (`core/chat/`) is per-conversation, not extracted
- **Bi-temporal:** no
- **Self-update mechanism:** datasets have explicit sync (`core/dataset/datasetSync/`) — pulls from APIs/sources on schedule; not LLM-extracted
- **Decay / forgetting:** no

### MCP / connectors
- **MCP server exposed:** **yes** — `projects/mcp_server/` is a dedicated MCP server project; `@modelcontextprotocol/sdk` in deps; `support/mcp/schema.ts` manages MCP servers as DB-tracked resources
- **MCP client used:** **yes** — workflow can call external MCP servers as tool nodes
- **Native connectors:** dataset sync (apiDataset), Feishu, DingTalk, WeChat work, online webhooks; visual workflow plugs in 3rd-party APIs as nodes
- **Tool-call surface:** workflow nodes are the surface; agentSkills schema manages re-usable agent capabilities

### Notable design choices
- **TypeScript-first** — no Python in the core stack (sandbox/code-runner is separate)
- **`@mariozechner/pi-agent-core` + `@mariozechner/pi-ai` integration** — uses **pi-mono** as the underlying agent runtime (the only surveyed repo so far that doesn't write its own agent loop)
- **Visual workflow as primary UX** — drag-and-drop canvas; agents are workflows, not code
- **agentSkills are DB rows, not files** — `core/agentSkills/schema.ts` makes skills first-class Mongo objects
- **CJK-first** — jieba tokenization + Chinese vendor vector DBs (OceanBase / OpenGauss / SeekDB) signal the primary user base
- **MongoDB for metadata, not Postgres** — diverges from the broader "Postgres+pgvector all-in-one" trend
- **Multi-project monorepo:** app (main UI), agent-sandbox, code-sandbox, mcp_server, marketplace, volume-manager

## Dependencies (KB-relevant)

From `packages/service/package.json`:

```
"@modelcontextprotocol/sdk": "catalog:"
"@mariozechner/pi-agent-core": "^0.67.3"     # underlying agent runtime
"@mariozechner/pi-ai": "^0.67.3"
"@zilliz/milvus2-sdk-node": "2.4.10"
"pg": "^8.10.0"                              # pgvector
"mongoose": "catalog:"                       # MongoDB metadata
"minio": "catalog:"                          # blob store
"ioredis": "^5.6.0"  "bullmq": "^5.52.2"    # queue
"@node-rs/jieba": "catalog:"                 # CJK tokenization
"tiktoken": "1.0.17"
"pdfjs-dist": "4.10.38"  "mammoth": "^1.11.0"
"papaparse" "node-xlsx" "turndown" "cheerio"
```

Sub-projects under `projects/`: app · agent-sandbox · code-sandbox · marketplace · mcp_server · volume-manager.

## Tradeoffs

**Pros:**
- Full-stack TypeScript — fits TS shops cleanly; Node 20+ + pnpm 10
- Strongest CJK support of the surveyed kb-apps — jieba + Chinese-vendor vector DBs
- Visual workflow surface lowers the bar for non-engineers
- pi-mono integration means the agent runtime is shared with pi-mono's evolution
- MCP is first-class — exposes own KBs as MCP server, consumes external MCP servers as workflow nodes

**Cons:**
- No graph-RAG layer — multi-hop reasoning over the KB is weaker than ragflow's NetworkX flow
- No agentic memory layer — must combine with mem0/Letta if you want per-agent fact memory
- OCR is paid-3rd-party (doc2x / textin) — no in-tree deepdoc-style local OCR
- Stack is sprawling (5+ services + sub-projects) — like ragflow, non-trivial to self-host
- agentSkills as DB rows means skills don't version-control like file-based Claude skills

## When to use it

- **Good fit:** TypeScript-first team building a **product** (not a library); CJK-heavy content; users prefer visual workflow over code
- **Bad fit:** Python-native stacks; teams that want graph-RAG; teams whose agents need durable per-user fact memory (no built-in memory layer)
- **Closest alternative (in this cohort):** ragflow (kb-app, Python). FastGPT trades ragflow's GraphRAG + native OCR + agent memory for TypeScript-native + visual workflows + pi-mono.

## Code pointers (evidence)

- Vector backends: `packages/service/common/vectorDB/{pg,milvus,oceanbase,opengauss,seekdb}/index.ts`
- Search controller: `packages/service/core/dataset/search/controller.ts`
- Reranker: `packages/service/core/ai/rerank/index.ts`
- Tokenizers: `packages/service/common/string/jieba/`, `packages/service/common/string/tiktoken/`
- Mongo schemas: `packages/service/{core/dataset,core/app,core/agentSkills,support/mcp}/schema.ts`
- MCP server project: `projects/mcp_server/`
- Agent runtime: `@mariozechner/pi-agent-core` (pi-mono via npm)
- Most useful single file to read first: `packages/service/core/dataset/search/controller.ts`

## Open questions

- Is the SeekDB vector backend a public product, or an internal labring fork? Couldn't find a public docs page in 30-min skim.
- The pi-agent-core dependency tightly couples FastGPT to pi-mono's release cadence — what's the version-pin policy?
- agentSkills schema mentions records — how does the workflow runtime resolve a skill at execution time vs Claude Code's file-based skill registry?

---

*Surveyed via the `curating-agentic-kbs` skill. Re-survey scheduled after 30 days of last `pushed_at` change.*

*Audit 2026-05-02: clone-verified against [`package.json`](https://github.com/labring/FastGPT/blob/main/package.json) (v4.0), [`LICENSE`](https://github.com/labring/FastGPT/blob/main/LICENSE) ("FastGPT Open Source License" = Apache-2.0 + multi-tenant-SaaS commercial license + LOGO/copyright preservation), [`packages/service/common/vectorDB/`](https://github.com/labring/FastGPT/tree/main/packages/service/common/vectorDB) (5 backend subdirs: pg / milvus / oceanbase / opengauss / seekdb), [`projects/`](https://github.com/labring/FastGPT/tree/main/projects) (6 sub-projects: agent-sandbox / app / code-sandbox / marketplace / mcp_server / volume-manager), [`packages/service/package.json`](https://github.com/labring/FastGPT/blob/main/packages/service/package.json) (`@mariozechner/pi-agent-core ^0.67.3` + `@mariozechner/pi-ai ^0.67.3` + `@modelcontextprotocol/sdk catalog:`). **All major claims verified verbatim:** 5 vector backends exact, 6 sub-projects, pi-mono integration via `@mariozechner/*` packages, MCP both server (`projects/mcp_server/`) and client (`@modelcontextprotocol/sdk`). **Cohort license diversity discovery:** FastGPT joins SSPL (FalkorDB), ELv2 (byterover), AGPL+EULA (AstrBot), Onyx-Enterprise (onyx) as **5th hybrid-license cohort entry** — Apache-2.0 base + SaaS-commercial-restriction + branding-preservation conditions. Added version `4.0` and license clarification to header.*
