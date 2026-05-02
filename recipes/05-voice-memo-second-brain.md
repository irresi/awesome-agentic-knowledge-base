# Recipe 05 — Voice memo → second-brain

> Daily voice memos transcribed into a markdown vault. Agent answers
> "what did my manager say about the deadline?" with date-cited quotes.

## Data flow

| # | Input | Transform | Output | Status |
|---|---|---|---|---|
| 1 | Daily voice memos (Apple Voice Memos on **macOS 15 Sequoia or later + Apple Silicon (M1+); English-only at launch** for native transcription, OR whisper.cpp on a watch folder for older systems) | AppleScript pulls native on-device transcripts; or whisper.cpp transcribes WAV → text with timestamps | One `YYYY-MM-DD.md` per day with `## HH:MM — title` timestamped sections per memo | 🟢 |
| 2 | Daily-note markdown files | basic-memory parses observation grammar (`- [tag] statement`) and `[[Wiki Links]]` relations into its SQLite-backed graph; arbitrary markdown is accepted alongside | basic-memory vault — the markdown files ARE the database (no separate index store) | 🟢 |
| 3 | User question (e.g. "what did my manager say about the deadline?") | Claude Code session opens in vault directory; Claude Code's built-in Read / Glob / Grep tools (NOT claude-mem's) handle exact-substring queries; claude-mem records the Q&A via its `PostToolUse` (per-observation) and `Stop` (session-summarize) hooks as typed observations (`facts` / `narrative` / `concepts` / `files_read` / `files_modified`) | Answer with date-anchored exact quotes (lossless citations); cross-session memory of past Q&A | 🟢 |
| 4 | Telegram message from user | `python-telegram-bot` wrapper invokes `claude` CLI in headless mode with vault path as working directory | Reply in Telegram chat | 🔴 |

## Build path

1. **Transcribe** — for macOS 15+ on Apple Silicon (M1 or newer; English-only at launch): AppleScript pulls native transcripts (gist'ed pattern). Older macOS, Intel, or non-English: whisper.cpp on a watch folder (whisper.cpp is actively maintained at `ggml-org/whisper.cpp` as of 2026). Output one daily note per day with timestamped sections.
2. **Vault structure** — basic-memory accepts arbitrary markdown; layer your own daily-note convention (`YYYY-MM-DD.md` + `## HH:MM` headings) on top — that convention is *yours*, not a basic-memory primitive. The basic-memory primitives that *do* hook in are observations (`- [tag] statement`) and `[[Wiki Link]]` relations, which work alongside arbitrary prose.
3. **Search via grep, not embeddings** — Claude Code's built-in Read / Glob / Grep tools handle most queries; vector search loses citation precision. claude-mem captures the session for cross-session memory via its `Stop` summarize hook (claude-mem does not expose its own Read/Glob/Grep — those are Claude Code built-ins).
4. **Telegram front-end** — `python-telegram-bot` (LGPLv3, actively maintained as of 2026) wraps `claude` CLI in headless mode; user sends a question, bot routes to Claude with vault as context.

## Why this combo

File-system-first beats vectorizing for a personal voice-memo corpus — memos are short, dated, and citation requires exact quotes. Claude Code's built-in Grep keeps "find that one thing" queries instant and lossless; claude-mem layers cross-session memory of past Q&A on top. Adding Pinecone/Qdrant here would be cargo-culting.

## Glue you write

- Voice-memo → daily-note formatter (~80 LoC: AppleScript + plist parser, or whisper.cpp watcher)
- Telegram bot wrapper around `claude` CLI (~100 LoC)
- Optional: weekly summary cron that reads last 7 days and writes a digest page

## Signal

`needs.md` Scenario 5 — Strong (HN Show Telegram-Claude voice bot, Apple Voice Memos gist, Granola briefing posts).
