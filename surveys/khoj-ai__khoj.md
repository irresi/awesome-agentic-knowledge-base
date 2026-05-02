# Survey: khoj-ai/khoj

**Date:** 2026-05-01
**Stars:** 34,329 · **Last push:** 2026-05-01 · **Created:** 2021-08-04 · **Version:** dynamic (no static pin in `pyproject.toml`) · **License:** AGPL-3.0
**Category:** kb-app (personal AI second-brain)
**Slug:** [khoj-ai/khoj](https://github.com/khoj-ai/khoj)

---

## TL;DR (3 lines)

- **What it is:** Self-hostable "personal AI second brain" — chat with local/online LLMs against your own docs (org-mode, markdown, PDF, DOCX, plaintext, image, GitHub, Notion). Django + FastAPI server, Next.js web UI, native apps for Obsidian/Emacs/desktop/phone/WhatsApp.
- **How its KB works:** **Two-tier vector KB on Postgres+pgvector.** Tier 1 = `Entry` table (chunked document embeddings) populated by per-source `*_to_entries.py` adapters using `langchain-text-splitters` (256-token recursive chunking). Tier 2 = `UserMemory` table (atomic first-person facts extracted from chat by an LLM-driven "Muninn" agent that returns `MemoryUpdates(create, delete)`). Retrieval = cosine distance via pgvector → optional cross-encoder rerank (`mxbai-rerank-xsmall-v1`). Bi-encoder default: `thenlper/gte-small` (sentence-transformers).
- **Verdict:** Pick when you want **a turnkey self-hostable second-brain** with multi-source ingestion (org-mode is rare!) + chat + an MCP-client tool layer + a real product UI. Skip if you need agent-memory primitives in a library form (use mem0/graphiti) or a graph-based KB (use LightRAG/cognee).

## KB Architecture

### Storage
Khoj is **PostgreSQL-only for persistence**, with pgvector providing vector capability inside the same database. No separate vector store.

| Storage type | Backend | Notes |
|---|---|---|
| **Vector** | Postgres + **pgvector** (`pgvector.django.VectorField`) | One backend; `dimensions=None` means embedding dim is set at runtime per search model |
| **Relational** | Postgres (Django ORM) | Users, agents, conversations, MCP servers, automations |
| **Document chunks** | `Entry` table | One row per chunk; columns: `embeddings`, `raw`, `compiled`, `heading`, `file_source`, `file_type`, `file_path`, `hashed_value`, `corpus_id` |
| **Long-term memory** | `UserMemory` table | One row per atomic fact; columns: `embeddings`, `raw`, `agent`, `search_model` |
| **MCP registry** | `McpServer` table | `name`, `path` (URL or script), `api_key` |
| **Generic KV** | `DataStore` table | `key`/`value` JSONField; for misc per-user state |
| **Local-mode option** | `pgserver` extra | Embedded Postgres for laptop deployments — no external DB needed |

- **Workspace isolation:** per-user via `KhojUser` foreign key on every row; per-agent via optional `Agent` FK
- **Cache:** none for embeddings (always recompute on query); torch tensors saved to disk for one-time index files
- **No Redis/MongoDB/Elasticsearch** — single-database stack is a deliberate simplification

### Ingestion / Extraction
- **Source types accepted:** org-mode, markdown, PDF (`pymupdf` + `rapidocr-onnxruntime` for OCR), plaintext, DOCX (`docx2txt`), image, **GitHub (repo scrape)**, **Notion (API)**
- Each source has a dedicated adapter at `src/khoj/processor/content/<type>/<type>_to_entries.py` extending `TextToEntries`
- **Chunking strategy:** `langchain-text-splitters.RecursiveCharacterTextSplitter` — token-aware (default `max_tokens=256`), separators in priority order: `["\n\n", "\n", "!", "?", ".", " ", "\t", ""]`, `chunk_overlap=0`. Words > 500 chars are dropped (not truncated) to preserve quality. Heading prefix (last 100 chars) re-prepended to non-first chunks
- **Entity / fact extraction:** **LLM-based, but only for the memory tier.** `extract_facts_from_query` (`routers/helpers.py:986`) takes the last 2 turns of chat + existing facts and emits `MemoryUpdates(create=[str], delete=[id])`. No update primitive — to update a fact you delete + create
- **Memory persona:** the prompt names the memory manager "**Muninn**" (Norse mythology raven of memory) and demands atomic, self-contained, first-person facts
- **No entity / relation extraction for documents** — the doc tier is pure vector RAG, not GraphRAG

### Retrieval
- **Vector search:** `EntryAdapters.search_with_embeddings` issues `CosineDistance` queries via pgvector ORM annotation, ordered ascending, capped by `bi_encoder_confidence_threshold` and `top_k=10` (`search_type/text_search.py:99`)
- **Reranker:** `CrossEncoderModel` (`processor/embeddings.py:117`) — default model `mixedbread-ai/mxbai-rerank-xsmall-v1`; can call HF inference endpoint instead of running locally; only triggered when results > 1 and explicitly enabled
- **Memory retrieval:** two paths — `pull_memories(user, limit=10, window=7)` for time-window slicing (last 7 days, no semantic filter) and `search_memories(query, user)` for cosine-distance top-K
- **Filters:** `search_filter/{date,file,word}_filter.py` — pre-filter on metadata before vector search
- **Top-k defaults:** entries 10, memories 10
- **Source navigation:** results include `file_path`, `heading`, `uri` so the UI can jump back to source

### Memory model
- **Tiers:**
  1. Recent chat history (full text in `Conversation` table)
  2. **Recent memories** — last 7 days from `UserMemory`, fetched by `pull_memories`
  3. **Long-term memories** — full table, queried by `search_memories` with cosine distance
  4. Document chunks — `Entry` table
- **Bi-temporal:** no — `created_at` and `updated_at` only, no separate validity window
- **Self-update mechanism:** **`ai_update_memories`** runs after each chat turn (when memory is enabled): pulls recent memories → calls `extract_facts_from_query` → applies `create`/`delete` ops. **Memory can be globally disabled per user** (`ConversationAdapters.ais_memory_enabled`)
- **Decay / forgetting:** explicit — the LLM is instructed to add deletes for facts that are "no longer relevant or true"; users can also manually delete via `DELETE /memories/{id}`

### MCP / connectors
- **MCP server exposed:** **NO** — Khoj is the orchestrator, not a tool source for other agents
- **MCP client used:** **YES** — `processor/tools/mcp.py:13` `MCPClient` class supports **both stdio AND SSE transports**. Discovers npm packages (paths starting with `@` or no `/`), Python `.py` scripts, JS `.js` scripts, or HTTP(S) URLs. Per-user MCP server registration via `McpServer` DB table
- **Native API providers:** Anthropic (0.75), OpenAI (2.x), Google GenAI (1.52), and any OpenAI-compatible endpoint (Ollama, LM Studio, OpenRouter via the openai client)
- **Native connectors:** Notion (OAuth), GitHub (token), web search (online_search.py), web scraping, e2b code interpreter (sandboxed Python execution)
- **API:** FastAPI under Django ASGI; routers split by concern (`api_chat`, `api_content`, `api_memories`, `api_agents`, `api_automation`, etc.)
- **Computer-use agent:** dedicated `processor/operator/` with Anthropic + OpenAI + UI-TARS binary backends — Khoj can drive a browser/computer via vision agent

### Notable design choices
- **Two-tier KB (docs + facts) in one Postgres** — every other surveyed memory framework runs vector + graph + KV across multiple stores. Khoj proves you can do "personal AI" with **one database**
- **`pgserver` local extra** — `pgserver==0.1.4` ships an embedded Postgres for laptop installs; same code runs against managed Postgres in cloud mode. Closest equivalent in cohort to LightRAG's "default-runs-in-process" property but using Postgres rather than NetworkX
- **MCP client supports both stdio AND SSE in one class** — cleanest dual-transport implementation seen so far in the cohort
- **Persona-named memory extractor** — "Muninn" is the most explicit memory-agent personification in the cohort. Atomic + first-person + delete-then-create is mem0-pattern but in a self-hosted application
- **No update on memories — only create+delete** — by-design constraint in the prompt that simplifies reasoning about consistency
- **Connector-rich** — Notion + GitHub + WhatsApp + Obsidian + Emacs is the broadest user-side surface in the cohort
- **AGPL-3.0 license** — joins claude-mem, OpenHands, basic-memory in the AGPL group; FastGPT is also AGPL
- **Default embed model is small** — `thenlper/gte-small` (33M params); memory + speed prioritized over peak quality

## Dependencies (KB-relevant)

From `pyproject.toml`:

```
# Core KB stack
pgvector == 0.2.4                      # Postgres vector ext (Django binding)
psycopg2-binary == 2.9.9               # Postgres driver
django == 5.1.15                       # ORM, auth, admin
sentence-transformers == 3.4.1         # bi-encoder + cross-encoder
transformers >= 4.53.0  torch == 2.6.0 # local model runtime
langchain-text-splitters == 0.3.11     # RecursiveCharacterTextSplitter
langchain-community == 0.3.31          # ingestion utilities

# LLM bindings
anthropic == 0.75.0
openai >= 2.0.0
google-genai == 1.52.0
mcp >= 1.23.0                          # MCP client (stdio + SSE)

# Source-specific parsers
pymupdf == 1.24.11                     # PDF
rapidocr-onnxruntime == 1.4.4          # OCR for PDFs / images
docx2txt == 0.8                        # DOCX
markdownify  markdown-it-py            # Markdown
beautifulsoup4 ~= 4.12.3               # HTML scraping
openai-whisper                         # voice transcription
magika                                 # MIME / file-type sniffing

# Tooling
e2b-code-interpreter ~= 1.0.0          # sandboxed code-exec tool
fastapi  uvicorn  apscheduler          # API + scheduling
authlib  itsdangerous                  # OAuth + signed cookies

# local-mode extra
pgserver == 0.1.4                      # embedded Postgres
```

No Redis, no MongoDB, no Neo4j, no Qdrant, no Faiss, no separate graph store — the **single-database property** is striking compared to ragflow / FastGPT / LightRAG.

## Tradeoffs

**Pros:**
- One-database stack (Postgres+pgvector) drastically reduces ops surface area for self-hosters
- `pgserver` makes laptop self-hosting genuinely zero-config
- Two-tier KB (chunks + atomic facts) gives both RAG-over-docs and chat-memory in the same product
- 8 native source adapters (org-mode, markdown, PDF, DOCX, plaintext, image, GitHub, Notion) is unmatched in the cohort
- MCP client with stdio + SSE transports unlocks the broader MCP ecosystem
- Computer-use agent integrated end-to-end (operator/) — rare in cohort
- AGPL is friendly for self-hosting, restrictive for SaaS competitors

**Cons:**
- **No graph KB** — pure vector retrieval; no entity/relation extraction over docs (LightRAG/cognee/graphiti users won't find that here)
- **No reranker by default** — must explicitly enable; default ranking is bi-encoder cosine only
- **No bi-temporal memory** — facts have `created_at`/`updated_at` but no validity window à la graphiti
- **Chunk-overlap = 0** — by-design but can cause boundary artifacts on long passages
- **Memory tier requires LLM call per turn** — `ai_update_memories` cost is unavoidable when memory is on
- **AGPL** restricts forking into proprietary SaaS

## When to use it

- **Good fit:** individuals/teams self-hosting a "personal Notion + chat" replacement; org-mode users (only mainstream agent that handles org-mode natively); users wanting MCP-tool support without writing custom plumbing; teams that already operate Postgres
- **Bad fit:** library use cases (Khoj is an application, not a library — embed mem0/graphiti/cognee instead); GraphRAG workflows; production that needs a separate vector DB tier for scaling beyond a single Postgres
- **Closest alternatives (in this cohort):**
  - **basic-memory** — same "personal second-brain" niche but markdown-only and bring-your-own-LLM via MCP; no UI
  - **FastGPT** — KB-app with multi-store backends; broader product but TypeScript stack
  - **ragflow** — heavier KB-app focused on enterprise document QA

## Code pointers (evidence)

- ORM models (Entry + UserMemory + McpServer + DataStore): `src/khoj/database/models/__init__.py:787,855,846,839`
- Vector field import: `src/khoj/database/models/__init__.py:14` (`from pgvector.django import VectorField`)
- Memory adapters (save/pull/search/delete): `src/khoj/database/adapters/__init__.py:2286-2374`
- Chunking: `src/khoj/processor/content/text_to_entries.py:60` (`split_entries_by_max_tokens`, line 72: `RecursiveCharacterTextSplitter`)
- Vector retrieval: `src/khoj/search_type/text_search.py:99` (`async def query`)
- Cross-encoder reranker: `src/khoj/processor/embeddings.py:117` (`class CrossEncoderModel`)
- Embeddings model: `src/khoj/processor/embeddings.py:29` (default `thenlper/gte-small`)
- Memory extractor: `src/khoj/routers/helpers.py:979-1058` (`MemoryUpdates`, `extract_facts_from_query`, `ai_update_memories`)
- Muninn prompt: `src/khoj/processor/conversation/prompts.py:1306` (`extract_facts_from_query`)
- MCP client: `src/khoj/processor/tools/mcp.py` (`MCPClient` — stdio + SSE)
- Memory API endpoints: `src/khoj/routers/api_memories.py` (GET/PUT/DELETE)
- Source adapters (8): `src/khoj/processor/content/{org_mode,markdown,pdf,docx,plaintext,images,github,notion}/`
- Computer-use agent: `src/khoj/processor/operator/`
- Most useful single file to read first: `src/khoj/database/models/__init__.py` (lines 770-865 — schema is the architecture)

## Open questions

- The default embed model `thenlper/gte-small` is dated (2023). Is there a config knob to swap to BGE-M3 or `nomic-embed-text-v1.5`? (The `SearchModelConfig` model suggests yes, but the upgrade path for existing embeddings is non-obvious — likely requires re-embedding.)
- `pgserver` is a fascinating "embedded Postgres" pattern — does the same code path scale to managed RDS without changes? The model imports look identical, so probably yes
- The "Muninn" prompt instructs delete-then-create instead of update. Has there been a measured improvement in fact-consistency vs an update-in-place baseline? Worth a benchmark study
- No graph store, but `Agent` model has skill/persona attachments — could a future graph layer slot in beside pgvector without breaking existing schema?

---

*Surveyed via the `curating-agentic-kbs` skill. Re-survey scheduled after 30 days of last `pushed_at` change.*

*Audit 2026-05-02: clone-verified against [`pyproject.toml`](https://github.com/khoj-ai/khoj/blob/master/pyproject.toml) (AGPL, dynamic version), [`src/khoj/processor/content/`](https://github.com/khoj-ai/khoj/tree/master/src/khoj/processor/content) (8 source adapter dirs: docx, github, images, markdown, notion, org_mode, pdf, plaintext), [`LICENSE`](https://github.com/khoj-ai/khoj/blob/master/LICENSE) (AGPL). **All major claims verified verbatim:** core dep pins all exact (`pgvector == 0.2.4`, `django == 5.1.15`, `sentence-transformers == 3.4.1`, `anthropic == 0.75.0`, `openai >= 2.0.0,< 3.0.0`, `google-genai == 1.52.0`, `mcp >= 1.23.0`, `pymupdf == 1.24.11`, `rapidocr-onnxruntime == 1.4.4`, `docx2txt == 0.8`, `e2b-code-interpreter ~= 1.0.0`, `pgserver == 0.1.4` in `local` extra), 8 source adapters (org-mode / markdown / pdf / docx / plaintext / images / github / notion), AGPL-3.0 license, single-Postgres-stack property (no Redis / MongoDB / Elasticsearch). Added version (dynamic) + license to header. **No corrections needed** — survey quality matches cognee / microsoft-graphrag / deepwiki-open / MemOS / OpenHands tier.*
