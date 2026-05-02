# Survey: Aider-AI/aider

**Date:** 2026-05-01
**Stars:** 44,183 · **Last push:** 2026-04-25 · **Created:** 2023-05-09
**Category:** coding-agent
**Slug:** [Aider-AI/aider](https://github.com/Aider-AI/aider)

---

## TL;DR (3 lines)

- **What it is:** Terminal-native AI pair-programming tool — the original "AI in your shell" coding agent. Pure-Python, ★44k, runs against ~any LLM via LiteLLM.
- **How its KB works:** **A "repo-map" computed from tree-sitter symbol tags** (~41 languages across two query dirs: primary `tree-sitter-language-pack/` + fallback `tree-sitter-languages/`), ranked by `networkx.pagerank`, cached in **`.aider.tags.cache.v4/`** (diskcache → SQLite). Token-budget-aware (`map_tokens=1024` default). No vector store, no LLM extraction, no MCP — everything is mechanical: tree-sitter + git + prompt assembly.
- **Verdict:** Pick when you want **the leanest possible terminal coding agent** with a strong codebase-aware context layer. Skip if you need cross-session memory, MCP integration, or anything beyond git + symbol-tag context.

## KB Architecture

### Storage
- **Vector store:** **none**
- **Graph store:** **none** (the symbol graph lives in-process via NetworkX-style PageRank but isn't persisted as a graph)
- **Metadata / structured:** **diskcache** under `.aider.tags.cache.v4/` (SQLite-backed) for parsed tag entries; cache version bumps when grammar pack changes
- **Source of truth for code state:** **git** (the user's existing repo). Aider commits each accepted change.
- **Cache:** in-process + diskcache for tags

### Ingestion / Extraction
- **Source types accepted:** files in the user's git repo (added via `/add`, `/read-only`, or auto-discovered)
- **Chunking strategy:** none — files are read whole or referenced via repo-map summary
- **Entity / fact extraction:** **mechanical via tree-sitter** — no LLM. `aider/queries/tree-sitter-language-pack/{python,go,rust,ts,java,c,cpp,...}-tags.scm` queries extract `Tag(rel_fname, fname, line, name, kind)` tuples
- **Schema:** `Tag` namedtuple (`rel_fname`, `fname`, `line`, `name`, `kind`)
- **~41 supported languages across two query directories** ([`aider/repomap.py:808-821`](https://github.com/Aider-AI/aider/blob/main/aider/repomap.py#L808-L821) — primary `tree-sitter-language-pack/`, fallback `tree-sitter-languages/`):
  - **Primary pack (30 languages):** Arduino, C, C#, C++, Chatito, Clojure, CommonLisp, D, Dart, Elisp, Elixir, Elm, Gleam, Go, Java, JavaScript, Lua, Matlab, OCaml (+ OCaml interface), Pony, Properties, Python, R, Racket, Ruby, Rust, Solidity, Swift, Udev
  - **Fallback pack (11 languages-only-here):** TypeScript, Haskell, Kotlin, Scala, PHP, Julia, Fortran, Zig, HCL, QL, c_sharp variant
  - (Verilog is **not** supported — earlier survey draft mistakenly listed it.)

### Retrieval
- **Modes:** **PageRank-weighted symbol selection** within `map_tokens` budget; multiplied by `map_mul_no_files=8` when no files are in context (so the LLM gets more codebase signal)
- **Reranker:** none
- **`/commands`:** `/add`, `/drop`, `/read-only`, `/architect`, `/code`, `/ask`, `/web`, `/diff`, `/lint`, `/test`, `/run`, `/git`, `/commit`, `/undo`, `/reset`, `/clear`, `/tokens`, `/voice`, `/paste`, `/context`, `/model`, `/editor-model`, `/weak-model`
- **Context-window management:** `ChatSummary` class summarizes older chat turns when total tokens exceed `max_tokens`, splits at half-budget, recurses up to depth 3
- **Source navigation:** repo-map shows function/class signatures and class members, NOT bodies — LLM asks for full file via tool-use if needed

### Memory model
- **Tiers:** active conversation messages + summarized older turns + repo-map (rebuilt each query) + `~/.aider.input.history` for input prompt history
- **Bi-temporal:** no, but git history is the user's audit trail
- **Self-update mechanism:** **none** — every session starts cold. The `.aider.tags.cache.v4/` is rebuilt as files change but nothing carries from session to session beyond what git records.
- **Decay / forgetting:** chat summarized when over budget; cache invalidated on file mtime change

### MCP / connectors
- **MCP server exposed:** **NO**
- **MCP client used:** **NO** — `grep -r 'modelcontextprotocol' aider/` returns zero hits. Aider is **the only surveyed repo with no MCP integration** as of this date.
- **Native API providers:** via **LiteLLM** — Anthropic, OpenAI, Gemini, Mistral, Cohere, AWS Bedrock, Azure, OpenRouter, Together, Groq, DeepSeek, Ollama, LM Studio, vLLM, etc. Most provider breadth in cohort by sheer count.
- **Native connectors:** Web scraping (`Scraper` + Playwright), voice input (`/voice`), clipboard (`pyperclip`), images (Pillow + `ImageGrab`)

### Notable design choices
- **Repo-map is the entire KB** — no vectors, no embeddings, no extraction LLM call. The "knowledge" is "where do symbols X, Y, Z live in the code, and how connected are they?"
- **Tree-sitter for everything** — code parsing, tag extraction, symbol references; no fall-back to substring matching
- **PageRank on the symbol graph** — given the user's task and any mentioned files, score every symbol by graph centrality and pack the top-N into the map under a token budget
- **No abstraction over MCP / agents / memory frameworks** — Aider is intentionally a *minimalist* coding agent
- **Git is the only persistence layer** — every commit is the source of truth; aider commits each accepted change automatically
- **`/architect` mode** — separate planning model + execution model; cheap thought, careful action
- **Apache-2.0 license** — same as cline, different from the AGPL trio (claude-mem, OpenHands, basic-memory)
- **Three coder formats:** `whole-file`, `udiff`, and `editblock` — chosen per-model based on demonstrated reliability

## Dependencies (KB-relevant)

From `requirements.txt` (compiled by uv from `requirements/requirements.in`):

```
litellm                              # multi-provider LLM client
tree_sitter   tree-sitter-language-pack   tree-sitter-languages   grep_ast
diskcache                            # SQLite-backed tag cache
gitpython                            # git ops
networkx                             # PageRank
pygments                             # syntax-aware tokenization for tags
pydub  sounddevice                   # voice (optional)
Pillow                               # image / clipboard
prompt_toolkit  rich                 # CLI UI
```

No MCP packages anywhere. No vector DB packages. No LLM-extraction prompts (just chat).

## Tradeoffs

**Pros:**
- **Zero infrastructure** — diskcache is the only persistence; runs on a laptop offline (with a local LLM)
- **PageRank repo-map gives surprisingly good codebase awareness** without paying for embedding compute
- ~41 languages tree-sitter-supported out of the box (primary 30 + fallback 11)
- LiteLLM means any LLM provider works without per-vendor code
- Mechanical extraction is fast, deterministic, and free
- Built-in voice / clipboard / web-scrape integrations are convenient

**Cons:**
- **No cross-session memory** — every conversation starts cold
- **No MCP integration at all** — incompatible with the rapidly-growing MCP server ecosystem
- Repo-map is a **point-in-time snapshot** — nothing remembers what changed across sessions, why decisions were made, or what worked / didn't
- ~41 languages are tree-sitter-supported (primary + fallback packs); if your language isn't in either you fall back to filename hints
- Single-user, single-machine — no multi-tenant or shared-team-memory story

## When to use it

- **Good fit:** solo developers; offline / air-gapped use with local LLMs; teams that already use git heavily and don't need shared agent memory; integration-light workflows; when you want to *minimize* moving parts
- **Bad fit:** workflows that benefit from cross-session memory (use claude-mem); workflows needing MCP servers (use Cline or OpenHands); document-heavy KBs (use a memory framework)
- **Closest alternatives (in this cohort):**
  - **cline** — terminal cousin, also no extraction, but adds MCP client + checkpoint via git + `.clinerules/`
  - **claude-mem** — opposite design point: claude-mem extracts and remembers; aider doesn't
  - **OpenHands** — server-side equivalent of "no extraction" but uses microagents for human-curated knowledge

## Code pointers (evidence)

- Repo-map core: `aider/repomap.py` — `RepoMap` class, `Tag` namedtuple, PageRank logic
- Tree-sitter queries (~41 languages, two-dir layout):
  - Primary: [`aider/queries/tree-sitter-language-pack/*.scm`](https://github.com/Aider-AI/aider/tree/main/aider/queries/tree-sitter-language-pack) — 31 `.scm` files (30 languages + ocaml_interface variant)
  - Fallback: [`aider/queries/tree-sitter-languages/*.scm`](https://github.com/Aider-AI/aider/tree/main/aider/queries/tree-sitter-languages) — 27 `.scm` files (TypeScript, Haskell, Kotlin, Scala, PHP, Julia, Fortran, Zig, HCL, QL, c_sharp + others overlapping with primary)
  - Selection logic in [`aider/repomap.py:808-821`](https://github.com/Aider-AI/aider/blob/main/aider/repomap.py#L808-L821)
- Git wrapper: `aider/repo.py` (`GitRepo`, automatic commit on accepted change)
- Conversation summarization: `aider/history.py` (`ChatSummary` class)
- Coders (edit formats): `aider/coders/{whole_file,udiff,editblock,architect}_coder.py`
- LLM router: `aider/llm.py` + LiteLLM
- Slash commands: `aider/commands.py` (~30+ commands)
- Most useful single file to read first: `aider/repomap.py`

## Open questions

- The `map_mul_no_files=8` constant suggests aider's "no files attached" mode tries to compensate by surfacing more of the repo. What's the empirical hit-rate of including the right symbol vs not?
- Any plan to add MCP support? (Not visible in the public roadmap, and the surveyed v0.x repo has no MCP imports.)
- The `architect` coder uses two models — does it pass repo-map context to both? Worth tracing through `aider/coders/architect_coder.py`.

---

*Surveyed via the `curating-agentic-kbs` skill. Re-survey scheduled after 30 days of last `pushed_at` change.*

*Audit 2026-05-02: clone-verified against [`aider/repomap.py`](https://github.com/Aider-AI/aider/blob/main/aider/repomap.py), [`aider/queries/`](https://github.com/Aider-AI/aider/tree/main/aider/queries) (both `tree-sitter-language-pack/` and `tree-sitter-languages/`), [`pyproject.toml`](https://github.com/Aider-AI/aider/blob/main/pyproject.toml) (PyPI name `aider-chat`). **Corrections:** language coverage **"30+" → "~41 across two query dirs"** (primary `tree-sitter-language-pack/` 30 + fallback `tree-sitter-languages/` adds 11 unique: TypeScript, Haskell, Kotlin, Scala, PHP, Julia, Fortran, Zig, HCL, QL, c_sharp variant); **removed false Verilog claim** (no `*verilog*.scm` file in either directory); fixed example list to include actual `Chatito` and remove false `Verilog`. **Verified:** No MCP at all (grep returns 0), `nx.pagerank()` at `repomap.py:525,529`, two-tier query directory selection at `repomap.py:808-821` (primary preferred, fallback for older grammars). PyPI package name is `aider-chat`, not `aider`. **Cohort implication:** code-review-graph's "second-largest after aider's 30+" claim should be re-evaluated — aider's actual coverage is ~41, code-review-graph is 32. Aider remains the largest, but the gap is narrower (and code-review-graph wins on niche grammars like notebooks, gdscript, luau).*
