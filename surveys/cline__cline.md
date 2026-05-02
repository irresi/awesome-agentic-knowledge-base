# Survey: cline/cline

**Date:** 2026-05-01
**Stars:** 61,229 · **Last push:** 2026-05-01 · **Created:** 2024-07-06 · **Version:** v3.82.0 · **NPM package:** `claude-dev` (legacy name) · **License:** Apache-2.0
**Category:** coding-agent
**Slug:** [cline/cline](https://github.com/cline/cline)

---

## TL;DR (3 lines)

- **What it is:** **VSCode (+ JetBrains + CLI) extension** for an autonomous coding agent — TypeScript core extension + React webview UI + Plan ↔ Act mode separation. The cohort's most-deployed IDE-side coding agent at ★61k.
- **How its KB works:** No vector store, no SQL DB. Knowledge lives in **`.clinerules/*.md`** (project rules), **`@file` mentions** (explicit-include), **`~/.cline/data/{globalState,secrets,workspaceState}.json`** atomic file-backed JSON stores, and **git-based checkpoints** for conversation rollback. The `ContextManager` does sophisticated message-history truncation with `EditType`-tagged updates so checkpoints can replay state precisely.
- **Verdict:** Pick when you want **Claude/Codex/OpenRouter inside VSCode** with cross-client (VSCode/JetBrains/CLI) state portability and no operational footprint beyond a folder in `~`. Skip if you need persistent semantic memory across sessions — Cline doesn't extract or index past work.

## KB Architecture

### Storage
- **Vector store:** **none** — Cline doesn't do similarity-based recall
- **Graph store:** none
- **Metadata / structured:** **file-backed JSON** — `~/.cline/data/{globalState,secrets,workspaceState}.json`. **Two storage backends** in [`src/shared/storage/`](https://github.com/cline/cline/tree/main/src/shared/storage): `ClineFileStorage.ts` (atomic write-then-rename for state JSON) + `ClineBlobStorage.ts` (binary blobs). `StateManager` adds an in-memory cache + debounce-flush.
- **Per-task data:** task-scoped files + history under `~/.cline/data/`
- **Checkpoints:** **git** — every conversation step is committed; rollback via `git reset` to a checkpoint. The repo's own working tree is the checkpoint medium.
- **Cache:** in-process JSON cache (StateManager)
- **Cross-client portability:** "value written by Cline-VSCode can be read by Cline-CLI" — explicit design contract; **do NOT** use VSCode's `ExtensionContext.globalState` because CLI/JetBrains can't see it

### Ingestion / Extraction
- **Source types accepted:** workspace files (the dev's editor); `@file` / `@url` / `@problems` / `@terminal` mentions for explicit-include
- **Chunking strategy:** none — files are referenced whole or as line ranges via mentions
- **Entity / fact extraction:** **none** — no LLM extraction layer
- **Schema:** `.clinerules/*.md` is the closest thing — markdown with no required frontmatter; rules are concatenated into the system prompt
- **Tree-sitter:** `src/services/tree-sitter/queries/` — used for mentions-resolution and code-aware navigation, not for memory
- **Hooks system:** `src/core/hooks/` — `HookProcess`, `HookProcessRegistry`, `pre-tool-use` hook with cancellation, `precompact-executor` for context compaction; hooks discovered from filesystem on startup

### Retrieval
- **Modes:** **none semantic** — Cline gives the model *exactly* what the user `@`-mentions plus the system prompt + active conversation. Truncation only when context window fills.
- **Context-window management:** `ContextManager` keeps `[messageIndex, EditType, [blockIndex, [[timestamp, updateType, update, metadata], ...]]]` tuples so any past edit can be replayed/un-replayed at checkpoint time. Five edit types: `NO_FILE_READ`, `READ_FILE_TOOL`, `ALTER_FILE_TOOL`, `FILE_MENTION`, `UNDEFINED`.
- **Reranker:** none

### Memory model
- **Tiers:** transient conversation messages + workspace state JSON + globalState JSON + git checkpoint history
- **Bi-temporal:** no, but git provides a real history if the user commits the working tree
- **Self-update mechanism:** **explicit** — user types `@file` to include a file; Cline doesn't decide for them
- **Decay / forgetting:** files are forgotten when the conversation truncates; nothing crosses sessions automatically (besides `.clinerules/` and the JSON stores)
- **Cross-session memory:** **none built-in** — the user's `.clinerules/` files are the persistent layer; no extraction, no recall

### MCP / connectors
- **MCP server exposed:** **NO** — Cline is **MCP client only**. This is the first cohort entry to break the 100% MCP-server pattern.
- **MCP client used:** **yes** — `src/services/mcp/{McpHub,McpOAuthManager,StreamableHttpReconnectHandler}.ts`. McpHub manages multiple connected MCP servers; OAuth flow built in.
- **Native API providers:** Anthropic, OpenRouter, AWS Bedrock, OpenAI, Gemini, Cerebras, DeepSeek, Mistral, plus local (Ollama / LM Studio) — most provider breadth in cohort
- **Tool-call surface:** built-in (file ops, terminal, browser, mentions) + every tool from connected MCP servers
- **Slash commands (7 default):** `SUPPORTED_DEFAULT_COMMANDS` in [`src/core/slash-commands/index.ts`](https://github.com/cline/cline/blob/main/src/core/slash-commands/index.ts) lists `newtask`, `smol`, `compact`, `newrule`, `reportbug`, `deep-planning`, `explain-changes`.

### Notable design choices
- **No semantic memory layer at all** — Cline is the cohort's clearest "context-engineering, not knowledge-base" agent. The user is responsible for what Cline knows.
- **`.clinerules/` is plain markdown, no frontmatter** — much simpler than OpenHands microagents (which require `triggers:`)
- **Cross-client file storage** — the same `~/.cline/data/` works across VSCode, JetBrains plugin, and CLI; intentional design choice (`storage.md` rule explicitly forbids using VSCode's own state APIs)
- **Git as the checkpoint store** — leverages an already-installed tool instead of inventing one
- **Plan ↔ Act mode** — first-class separation; agent thinks in Plan, mutates in Act
- **Hooks system with discovery** — like Claude Code's hooks, but living in `~/.cline/hooks/` and discovered each startup
- **Apache-2.0** — diverges from the AGPL trio (basic-memory, OpenHands, claude-mem); Cline is a *library / extension* to embed an agent, not a memory product
- **Multi-client mention syntax** — `@file:line-range`, `@url`, `@problems`, `@terminal` — composable explicit-include grammar

## Dependencies (KB-relevant)

From `package.json` (root, partial):

```
"@anthropic-ai/sdk"     "openai"     "@google/genai"       # provider SDKs
"@modelcontextprotocol/sdk"                                # MCP client
"tree-sitter"           tree-sitter language packs         # code parsing
"clone-deep"            # for ContextManager safe-mutation
"esbuild"               # bundler
"react"  "react-dom"    # webview UI
```

`go.work.sum` at root suggests a Go workspace too (likely the CLI side / native parts).

## Tradeoffs

**Pros:**
- Smallest operational footprint of any surveyed agent — no Postgres, no Redis, no vector DB
- Cross-client state portability is real engineering — file storage + StateManager + migration path
- Git checkpoints are powerful and *natural* for an IDE workflow
- Mentions grammar (`@file:lines`, `@url`, `@problems`) is a precise way to compose context
- Apache-2.0 license is enterprise-friendly
- Hooks system enables custom pre/post-tool-use behavior without touching the extension

**Cons:**
- **No persistent semantic memory** — every new task starts cold unless the user manually `@`-mentions relevant files or maintains `.clinerules/`
- No MCP server exposed — other agents can't call Cline as a tool (asymmetric integration)
- Trust-the-user-to-mention model is high cognitive load on long projects
- Tightly coupled to VSCode extension lifecycle (despite the cross-client work) — the React webview UI assumes a host
- No analytics or eval harness in the open repo (separate `evals/` dir is light)

## When to use it

- **Good fit:** developers who want an IDE-native agent and prefer explicit-include over auto-recall; teams with `.clinerules/` discipline; orgs needing Apache-2.0 license; cross-IDE deployments (VSCode + JetBrains + CLI users on one team)
- **Bad fit:** semantic-memory-first workflows (use mem0 or claude-mem alongside); server-side multi-tenant deployments (use OpenHands); domains where the user can't be expected to know what to `@`-mention (use a memory-extracting agent)
- **Closest alternatives (in this cohort):**
  - **OpenHands** — server-side coding agent; both share Plan ↔ Act and microagent/rules patterns
  - **claude-mem** — claude-mem adds the *memory layer* that Cline lacks; the two are complementary, not competing

## Code pointers (evidence)

- Architecture overview: `.clinerules/cline-overview.md` (mermaid diagrams)
- Storage contract: `.clinerules/storage.md`
- File + Blob storage backends: `src/shared/storage/{ClineFileStorage,ClineBlobStorage,ClineStorage,storage-context,adapters}.ts`
- StateManager (cache + flush): `src/core/storage/StateManager.ts`
- ContextManager (truncation + checkpoint replay): `src/core/context/context-management/ContextManager.ts`
- Mentions resolver: `src/core/mentions/`
- Hooks system: `src/core/hooks/{HookProcessRegistry,hook-executor,hook-factory,precompact-executor}.ts`
- MCP client hub: `src/services/mcp/McpHub.ts`
- Tree-sitter: `src/services/tree-sitter/{index,languageParser}.ts` + `queries/`
- Slash commands: `src/core/slash-commands/`
- VSCode → file-storage migration: `src/hosts/vscode/vscode-to-file-migration.ts`
- Most useful single file to read first: `.clinerules/cline-overview.md` + `.clinerules/storage.md`

## Open questions

- The Plan ↔ Act mode is referenced in docs but the actual gating logic isn't clear from a 30-min skim — where does the mode flip happen, and is it a hard transition?
- Cross-client `~/.cline/data/` works because all three clients live on the same machine — what's the story for cloud-hosted Cline (if any)?
- ContextManager keeps full edit history for replay — at what message-count or token-budget does this become a memory hog? The migrations + tests would clarify.
- Is there a story for syncing `.clinerules/` across team members beyond "commit them to the repo"?

---

*Surveyed via the `curating-agentic-kbs` skill. Re-survey scheduled after 30 days of last `pushed_at` change.*

*Audit 2026-05-02: clone-verified against [`package.json`](https://github.com/cline/cline/blob/main/package.json) (NPM name `claude-dev` legacy, version `3.82.0`, Apache-2.0), [`src/shared/storage/`](https://github.com/cline/cline/tree/main/src/shared/storage), [`src/core/context/context-management/`](https://github.com/cline/cline/tree/main/src/core/context/context-management), [`src/core/hooks/`](https://github.com/cline/cline/tree/main/src/core/hooks) (14 hook-related files), [`src/services/mcp/`](https://github.com/cline/cline/tree/main/src/services/mcp), [`src/core/slash-commands/`](https://github.com/cline/cline/tree/main/src/core/slash-commands), [`.clinerules/`](https://github.com/cline/cline/tree/main/.clinerules). **Corrections:** version `3.81.0` → **`3.82.0`**; slash commands "/newtask, /smol, etc." → exact 7 commands `[newtask, smol, compact, newrule, reportbug, deep-planning, explain-changes]`; storage layer description was incomplete — actual is **two backends**: `ClineFileStorage.ts` (state JSON) + `ClineBlobStorage.ts` (binary blobs). **Bonus discoveries:** NPM package name is **`claude-dev`** (legacy from pre-rename), 14 hook-related files (richer than survey's 4 examples — incl. `HookDiscoveryCache`, `notification-hook`, `templates.ts`, `shell-escape.ts`, `hook-model-context.ts`). **Verified verbatim:** Apache-2.0, MCP client only (no server), Cross-client storage contract, ContextManager truncation/replay, `.clinerules/` markdown rules.*
