# safishamsi/graphify

- **Stars:** 40,059 · **Last push:** 2026-05-01 · **Created:** 2026-04-03 (4 weeks old) · **License:** MIT · **Lang:** Python (≥3.10) · **Version:** `graphifyy 0.6.2` *(PyPI typo — double-y, intentional name fallback)*
- **Category:** wiki-compiler (5th cohort entry; code/docs/papers/images/videos → queryable knowledge graph)
- **Author:** safishamsi (single-author project — fastest cohort growth velocity at ★40k in ~4 weeks)

## TL;DR

A Python library *distributed as a Claude Code skill (and 10 sibling-IDE skill bundles)* that turns any folder of code, documentation, papers, images, or videos into a knowledge graph. Pipeline is intentionally linear and stateless: `detect() → extract() → build_graph() → cluster() → analyze() → report() → export()`, each module a single function communicating through plain dicts and NetworkX graphs (no shared state, no side effects outside `graphify-out/`). 22+ tree-sitter language extractors via deps. **Cohort first to type edges by confidence** (`EXTRACTED` / `INFERRED` / `AMBIGUOUS`), with AMBIGUOUS edges flagged for human review in `GRAPH_REPORT.md`. Ships **6 export formats** (Obsidian vault / graph.json / graph.html / graph.svg / GraphML / Neo4j Cypher) plus an MCP stdio server. **11 IDE skill files** (`skill-aider.md` / `skill-claw.md` / `skill-codex.md` / `skill-copilot.md` / `skill-droid.md` / `skill-kiro.md` / `skill-opencode.md` / `skill-trae.md` / `skill-vscode.md` / `skill-windows.md` + base `skill.md`). MIT.

## KB Architecture

### Pipeline (single-pass, stateless)
```
detect()  →  extract()  →  build_graph()  →  cluster()  →  analyze()  →  report()  →  export()
```
Each stage is a single Python function in its own module under `graphify/`. Communicates through plain dicts + NetworkX graphs. No shared state, no side effects outside `graphify-out/`. Documented in [`ARCHITECTURE.md`](https://github.com/safishamsi/graphify/blob/main/ARCHITECTURE.md).

### Storage
- **Output**: `graphify-out/` directory containing 6 export formats (Obsidian vault / `graph.json` / `graph.html` standalone visualizer / `graph.svg` / GraphML / Neo4j Cypher script).
- **Cache**: `cache.py` — semantic file cache (`check_semantic_cache` + `save_semantic_cache`) splits files into `(cached, uncached)` based on content hash so re-runs only re-process changed files.
- **No DB at all** — `graphify-out/` is the database (joins the cohort's "no DB" camp alongside cline / memvid / Understand-Anything / byterover-cli / claude-obsidian).

### Extraction (22+ tree-sitter languages)
- `extract.py` dispatches per file extension to language-specific tree-sitter parsers.
- Tree-sitter language deps in `pyproject.toml`: `tree-sitter-python`, `-javascript`, `-typescript`, `-go`, `-rust`, `-java`, `-c`, `-cpp`, `-ruby`, `-c-sharp`, `-kotlin`, `-scala`, `-php`, `-swift`, `-lua`, `-zig`, `-powershell`, `-elixir`, `-objc`, `-julia`, `-verilog` (21 languages baked in).
- **Cohort-novel typed edge confidence** — every edge carries one of 3 labels:
  - `EXTRACTED` — relationship is explicitly stated in source (e.g., import statement, direct call)
  - `INFERRED` — reasonable deduction (call-graph second pass, co-occurrence in context)
  - `AMBIGUOUS` — uncertain; **flagged for human review in `GRAPH_REPORT.md`**
- `validate.py` enforces extraction schema before `build_graph()` consumes it.

### Build + cluster
- `build.py` — `build_graph(extractions) → nx.Graph` (NetworkX in-memory).
- `cluster.py` — runs **Leiden via [graspologic](https://github.com/microsoft/graspologic)** if available, falls back to **Louvain** (built into NetworkX) — cohort-second use of Leiden alongside [`microsoft/graphrag`](microsoft__graphrag.md) (which uses Hierarchical Leiden via graspologic-native) and [`tirth8205/code-review-graph`](tirth8205__code-review-graph.md). Splits oversized communities for visualization. Suppresses graspologic's stdout/stderr ANSI escape sequences via `_suppress_output()` to fix PowerShell 5.1 scroll-buffer corruption (issue #19) — cohort-first explicit Windows-PowerShell compatibility shim.

### Analyze (`analyze.py` cohort-novel insights)
Builds an analysis dict with three signal types from the clustered graph:
1. **God nodes** — most-connected nodes (centrality)
2. **Surprising connections** — cross-community edges, especially **cross-language-family** edges (the `_LANG_FAMILY` table groups extensions by runtime: `.py/.pyw → python`, `.js/.jsx/.ts/.tsx/.vue/.svelte → js`, `.go → go`, `.rs → rust`, `.java/.kt/.scala → jvm`, `.c/.cpp/.h → c`, etc., 11 families). Cross-language-family edges = polyglot integration points worth investigating. Cohort first to surface "polyglot integration points" as an analysis primitive.
3. **Suggested questions** — auto-generated questions to guide human exploration (`GRAPH_REPORT.md` content)

### Export (`export.py` — 6 formats from one NetworkX graph)
Single source-of-truth NetworkX graph → 6 outputs:
- **Obsidian vault** (markdown + bi-directional links) — joins the cohort's Obsidian-vault camp ([`AgriciDaniel/claude-obsidian`](AgriciDaniel__claude-obsidian.md))
- **graph.json** (NetworkX node-link format)
- **graph.html** standalone visualizer with `MAX_NODES_FOR_VIZ = 5000` cap and 10-color community palette (`#4E79A7`/`#F28E2B`/`#E15759`/...)
- **graph.svg** (vector visualization)
- **GraphML** (XML, for Cytoscape/Gephi)
- **Neo4j Cypher** (script for loading into Neo4j)
- Most decomposed export surface in cohort.
- Diacritic stripping via `_strip_diacritics(text)` for safe label rendering.

### Ingest sources beyond code (`ingest.py`)
- URLs — fetch + save to corpus dir with `safe_fetch` / `safe_fetch_text` (size cap, timeout)
- Documents — incl. PDF (per `pyproject.toml` dependencies)
- Images / videos — via `transcribe.py` (separate module — likely Whisper/VLM-based)

### MCP server (`serve.py`)
- **MCP stdio server** that exposes graph query tools to Claude Code and other agents.
- Loads `graph.json` (the canonical persistent format), validates path resolves inside `graphify-out/`.
- Cohort signal: graphify is both a *skill* (markdown distribution to 11 IDEs) AND an *MCP server* (per-graph tool exposure) — both shapes from one Python library.

### Watch + hooks
- `watch.py` — directory watcher, writes flag file on change for incremental re-runs.
- `hooks.py` — Claude Code hook integration (likely `PostToolUse` for incremental graph updates).

### Security primitives (`security.py`)
- `validate_url()` — http/https only
- `_NoFileRedirectHandler` — blocks `file://` redirects (cohort-first SSRF guard for skill-shaped tools)
- `safe_fetch()` / `safe_fetch_text()` — size cap + timeout
- `validate_graph_path()` — must resolve inside `graphify-out/` (path-traversal guard)
- `sanitize_label()` — strips control chars, caps 256 chars, HTML-escapes
- Full threat model in [`SECURITY.md`](https://github.com/safishamsi/graphify/blob/main/SECURITY.md)

### IDE skill bundles (cohort-novel breadth)
**11 skill markdown files** in same package — graphify is one Python library that ships skill instructions for:
- Claude Code (`skill.md` base)
- Aider (`skill-aider.md`)
- ClawCode/OpenClaw (`skill-claw.md`)
- OpenAI Codex (`skill-codex.md`)
- GitHub Copilot (`skill-copilot.md`)
- Factory Droid (`skill-droid.md`)
- Kiro (`skill-kiro.md`)
- OpenCode (`skill-opencode.md`)
- Trae (`skill-trae.md`)
- VS Code (`skill-vscode.md`)
- Windows context (`skill-windows.md`)

Most cohort entries target 1-3 IDE clients ([`tirth8205/code-review-graph`](tirth8205__code-review-graph.md) ships an `install` command for 11 AI tools but with one shared invocation — graphify ships **per-IDE skill markdown files**, not a shared shim).

## Notable design choices

- **Linear stateless pipeline** (`detect → extract → build → cluster → analyze → report → export`) — each stage a single Python function. Most cohort wiki-compilers have similar shape; graphify is the most explicitly linear (no daemon, no async, no shared state).
- **Typed edge confidence** (`EXTRACTED` / `INFERRED` / `AMBIGUOUS`) — cohort first to surface relationship confidence at the schema layer. AMBIGUOUS edges are flagged for human review in `GRAPH_REPORT.md` — cohort-first explicit human-in-the-loop surface for graph quality.
- **Polyglot-integration-point detection** (`_LANG_FAMILY` table + `_cross_language()` predicate) — cross-community edges that *also* span language families are surfaced as "surprising connections". Cohort first to elevate cross-runtime call patterns as a discoverable insight.
- **Leiden via graspologic** (cohort second after `microsoft/graphrag` and `tirth8205/code-review-graph`) — **graspologic stdout/stderr is suppressed** via `_suppress_output()` to fix Windows PowerShell 5.1 scroll-buffer corruption (cohort-first explicit Windows-PowerShell compatibility shim, with a documented issue link).
- **6 export formats from one NetworkX graph** — Obsidian / JSON / HTML / SVG / GraphML / Neo4j Cypher. Most decomposed export surface in cohort.
- **11 per-IDE skill markdown files** in same package — graphify distributes itself as bespoke skills for 11 different agent harnesses simultaneously. Different from code-review-graph's "one CLI + auto-install MCP config into 11 tools" approach.
- **Skill-as-distribution AND library-as-substrate** — passes L17 check (real KB code under the skill packaging). Comparable to claude-obsidian (Obsidian vault distributed as plugin) and Understand-Anything (Claude Code plugin with TS substrate).
- **Worked examples shipped in repo** (`worked/{example,httpx,karpathy-repos,mixed-corpus}/`) — pre-baked output examples committed to git as documentation. Cohort first to ship "worked examples" as repo artifacts, not just docs links.
- **Single-author rapid-growth project** — ★40k in 4 weeks (created 2026-04-03), fastest cohort growth velocity (vs `tirth8205/code-review-graph`'s ★14.5k since 2026-02-26 = ~6 months for ~36% the velocity).

## Dependencies

Python ≥3.10. Core: `networkx`, `tree-sitter≥0.23.0`. Tree-sitter language packs: 21 (python / javascript / typescript / go / rust / java / c / cpp / ruby / c-sharp / kotlin / scala / php / swift / lua / zig / powershell / elixir / objc / julia / verilog). Optional: `graspologic` for Leiden (Louvain fallback). MCP server is stdio (no extra deps; uses `sys.stdin`/`stdout` directly per `serve.py`). PDF / image / video ingestion has additional optional deps not in the core pin.

## Tradeoffs

- **For**: cohort-first **typed edge confidence** with explicit AMBIGUOUS-for-review flag; cohort-first **polyglot integration point** detection; **6 export formats** (most in cohort); **11 per-IDE skill markdown files** (most in cohort); MIT; explicit linear stateless pipeline (easy to reason about); cohort-second **Leiden** clustering (vs Louvain fallback); **Windows PowerShell 5.1 compatibility shim** (cohort-first explicit Windows quirks handling); committed `worked/` examples; security primitives (URL validation, file:// redirect guard, path-traversal guard, label sanitizer); good documentation (`ARCHITECTURE.md` + `SECURITY.md`).
- **Against**: **single-author project at 4 weeks old** — sustainability + bus-factor risk; PyPI name typo (`graphifyy` double-y) suggests rushed publishing; `MAX_NODES_FOR_VIZ = 5000` cap means very large codebases get visualization-truncated (analysis still runs); no incremental clustering — every full re-run re-clusters from scratch (only file extraction is cached); `transcribe.py` exists but no documented audio/video pipeline benchmarks; 21-language tree-sitter dep stack adds significant install time; rapid 4-week ★40k growth without proportional documentation maturity is a trust signal worth verifying before production deployment.

## When to use vs. cohort

- vs. **tirth8205/code-review-graph** ([survey](tirth8205__code-review-graph.md)) — both are tree-sitter + community-detection wiki-compilers with MCP. code-review-graph has 32 languages (vs graphify's 21), SQLite + FTS5 backend, shipped CLI install for 11 AI tools (one shim). graphify has Leiden-with-Louvain-fallback (vs Leiden-only), 6 export formats (vs code-review-graph's narrower export surface), per-IDE skill markdown files (vs one shared install command), explicit edge confidence labels.
- vs. **AsyncFuncAI/deepwiki-open** ([survey](AsyncFuncAI__deepwiki-open.md)) — deepwiki-open is server-shaped (FastAPI + adalflow + FAISS) for any GitHub/GitLab/BitBucket repo. graphify is library + skill distribution for local code/docs/papers/images/videos.
- vs. **Lum1104/Understand-Anything** ([survey](Lum1104__Understand-Anything.md)) — Understand-Anything is TypeScript Claude Code plugin with `.understand-anything/{knowledge-graph,meta,fingerprints,config}.json` filesystem layout, 8-category lint, React/React-Flow dashboard. graphify is Python with NetworkX + 6 export formats and a stand-alone HTML visualizer.
- vs. **AgriciDaniel/claude-obsidian** ([survey](AgriciDaniel__claude-obsidian.md)) — claude-obsidian is the Obsidian vault distribution + 11 skills + 4 hooks + autoresearch. graphify can *export to* Obsidian vault format but isn't itself one — different shape.

## Code pointers

- Pipeline modules: [`graphify/{detect,extract,build,cluster,analyze,report,export}.py`](https://github.com/safishamsi/graphify/tree/main/graphify).
- Architecture spec: [`ARCHITECTURE.md`](https://github.com/safishamsi/graphify/blob/main/ARCHITECTURE.md).
- Edge-confidence labels: [`graphify/extract.py`](https://github.com/safishamsi/graphify/blob/main/graphify/extract.py) (search for `EXTRACTED` / `INFERRED` / `AMBIGUOUS`); enforced via [`graphify/validate.py`](https://github.com/safishamsi/graphify/blob/main/graphify/validate.py).
- Cross-language detection: [`graphify/analyze.py`](https://github.com/safishamsi/graphify/blob/main/graphify/analyze.py) (`_LANG_FAMILY` + `_cross_language`).
- Leiden + suppression: [`graphify/cluster.py`](https://github.com/safishamsi/graphify/blob/main/graphify/cluster.py) (`_partition` + `_suppress_output`).
- 6-format export: [`graphify/export.py`](https://github.com/safishamsi/graphify/blob/main/graphify/export.py).
- MCP stdio server: [`graphify/serve.py`](https://github.com/safishamsi/graphify/blob/main/graphify/serve.py).
- Security primitives + threat model: [`graphify/security.py`](https://github.com/safishamsi/graphify/blob/main/graphify/security.py) + [`SECURITY.md`](https://github.com/safishamsi/graphify/blob/main/SECURITY.md).
- 11 IDE skill files: [`graphify/skill-{aider,claw,codex,copilot,droid,kiro,opencode,trae,vscode,windows}.md`](https://github.com/safishamsi/graphify/tree/main/graphify) + base `skill.md`.
- Worked examples: [`worked/{example,httpx,karpathy-repos,mixed-corpus}/`](https://github.com/safishamsi/graphify/tree/main/worked).
- Tree-sitter language deps (21): [`pyproject.toml`](https://github.com/safishamsi/graphify/blob/main/pyproject.toml).

## Open questions

- **Sustainability** — single-author project ★40k in 4 weeks. What's the maintainer's bandwidth to handle issue volume / contributor PRs at this growth rate?
- **PyPI name typo** (`graphifyy` double-y) — was this intentional (the `graphify` name was taken) or a release-script typo? `pyproject.toml` says `graphifyy`.
- **Image / video ingestion depth** — `transcribe.py` exists but the architecture doc focuses on code. What's the actual quality of the video → KG pipeline?
- **Incremental clustering** — semantic file cache splits cached/uncached for extraction, but `cluster.py` re-runs Leiden on the full graph every time. At what graph size does this become the bottleneck?
- **Per-IDE skill maintenance** — 11 skill markdown files all need to track skill-spec changes per IDE. How does the team prevent drift across the 11 files?
- **AMBIGUOUS-for-review UX** — are users expected to read `GRAPH_REPORT.md` manually and edit the graph? Is there a tool to accept/reject AMBIGUOUS edges?

---

*Audit 2026-05-02: clone-verified against [safishamsi/graphify@main](https://github.com/safishamsi/graphify) (last commit 2026-05-01 21:19). Version `graphifyy 0.6.2` / MIT confirmed in `pyproject.toml`. 21 tree-sitter language deps enumerated from `pyproject.toml` dependencies. Pipeline `detect → extract → build_graph → cluster → analyze → report → export` verified verbatim from `ARCHITECTURE.md`. Edge confidence labels (`EXTRACTED`, `INFERRED`, `AMBIGUOUS`) verified in `ARCHITECTURE.md` "Confidence labels" table. Polyglot integration point detection (`_LANG_FAMILY` table with 11 language families) verified at `graphify/analyze.py:7-19`. Leiden via graspologic with Louvain fallback verified at `graphify/cluster.py:1-29`. Windows PowerShell 5.1 ANSI suppression verified at `graphify/cluster.py:9-19` (`_suppress_output`). 6 export formats (Obsidian vault / JSON / HTML / SVG / GraphML / Neo4j Cypher) verified at `graphify/export.py:1` ("write graph to HTML, JSON, SVG, GraphML, Obsidian vault, and Neo4j Cypher"). MCP stdio server verified at `graphify/serve.py:1-30`. 11 per-IDE skill markdown files (skill-aider/claw/codex/copilot/droid/kiro/opencode/trae/vscode/windows + base skill.md) verified by `ls graphify/*.md`. Security primitives (`validate_url`, `_NoFileRedirectHandler`, `safe_fetch`, `validate_graph_path`, `sanitize_label`) verified in `ARCHITECTURE.md` Security section. Worked examples verified by `ls worked/`. ★40,059 with `created_at: 2026-04-03` = ~4-week growth velocity, fastest in cohort. Corrections: none (first-pass survey).*
