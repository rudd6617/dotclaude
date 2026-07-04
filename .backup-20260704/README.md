# my-claude

Personal Claude Code template — development principles, custom skills, hooks, ADR scaffolding, and a self-improvement loop.

## What's in here

```
.
├── sync.sh                       # Push template updates into another project (overwrite managed, keep yours)
├── docs/
│   ├── ADR-FORMAT.md             # ADR template
│   └── adr/
│       └── README.md             # When to write an ADR (three conditions)
├── .out-of-scope/                # Rejected proposals (why NOT to do X)
└── .claude/
    ├── CLAUDE.md                 # Principles, file/skill mapping, workflow
    ├── Wiki.md                   # Long-term knowledge: background, stack, dirs, API, glossary
    ├── Memory.md                 # Volatile session state — where to pick up (gitignored)
    ├── Learning.md               # Accumulated mistakes & lessons (auto-injected)
    ├── settings.json             # Hooks (SessionStart memory injection)
    ├── settings.local.json       # Local permissions
    ├── launch.json               # Editor launch config
    ├── statusline.sh             # Status bar: git branch · model · token usage · context usage · session price
    ├── hooks/
    │   └── inject-memory.sh      # Auto-inject Learning + Memory; nudge /r-dreaming past threshold
    └── skills/
        ├── r-zoom-out/SKILL.md         # /r-zoom-out — map an unfamiliar module
        ├── r-grill/SKILL.md            # /r-grill — pre-implementation alignment
        ├── r-grill-with-docs/SKILL.md  # /r-grill-with-docs — alignment + Wiki/ADR
        ├── r-plan/SKILL.md             # /r-plan — architecture planning (4 sections)
        ├── r-diagnose/SKILL.md         # /r-diagnose — 6-phase debugging
        ├── r-review/SKILL.md           # /r-review — single-file/PR quality check
        ├── r-deepen/SKILL.md           # /r-deepen — codebase-level refactor opportunities
        ├── r-handoff/SKILL.md          # /r-handoff — compact conversation into Memory.md
        └── r-teach/SKILL.md            # /r-teach — turn the workspace into a teaching environment
```

## Core Principles

Encoded in `.claude/CLAUDE.md`:

1. **Data structures first** — design the data, then write the logic
2. **Eliminate special cases** — reshape data instead of adding branches
3. **Max 3 levels of indentation** — functions do one thing
4. **Never break existing behavior** — list impact before changing
5. **Solve real problems** — complexity must match severity
6. **Early return, fail fast** — errors surface immediately
7. **Name the intent** — names say *what*, not *how*
8. **Conservative dependencies** — stdlib over third-party
9. **Test-first bug fixes** — write a failing test before fixing; missing test seam is itself an architectural finding
10. **Isolate cross-file refactors** — use git worktree
11. **Touch only what's necessary** — no drive-by refactor / formatting / docstring
12. **Ask when ambiguous** — list options, don't silently pick
13. **Output is an interface** — structure replies for the reader's decision: conclusion first, tables over walls of prose, claims backed by evidence

## Document Roles

| File | Purpose | When |
|---|---|---|
| `.claude/CLAUDE.md` | Rules, process, stable preferences | Rules change |
| `.claude/Memory.md` | Volatile session state — where to pick up (gitignored) | End of session (`/r-handoff`) or progress changes |
| `.claude/Learning.md` | Recurring failure patterns & lessons | You got corrected and it could happen again |
| `.claude/Wiki.md` | Long-term knowledge: background, stack, dirs, API, glossary | Aligning on a term / resolving a new concept |
| `docs/adr/NNNN-*.md` | Architecture decisions (why X not Y) | All three ADR conditions hold |
| `.out-of-scope/*.md` | Rejected proposals (why NOT to do X) | The same proposal could resurface |

## Custom Skills

| Skill | Trigger | Purpose |
|---|---|---|
| `/r-grill` | Requirements are fuzzy | One-question-at-a-time alignment |
| `/r-grill-with-docs` | Domain decisions need to be recorded | grill + Wiki/ADR maintenance |
| `/r-plan` | Architecture or multi-file changes (after alignment) | Data flow, complexity, risks, go/no-go |
| `/r-diagnose` | Bug, regression, test failure, perf issue | 6-phase loop: feedback loop → reproduce → hypothesise → instrument → fix → post-mortem |
| `/r-review` | Single file or PR | Taste rating, fatal issues, complexity, data structures |
| `/r-deepen` | Codebase-level architecture review | Find shallow modules, weak seams, locality issues |
| `/r-teach` | You want to learn a new concept or skill | Teaching workspace: storage strength, ZPD, cite high-trust sources |

Typical flows:
- Simple: just do it
- Medium: `/r-grill` → implement → `/r-review`
- Complex: `/r-grill-with-docs` → `/r-plan` → implement → `/r-review`
- Bug: `/r-diagnose`
- Periodic: `/r-deepen`

## Self-Improvement Loop

1. **SessionStart hook** runs `inject-memory.sh` — injects `.claude/Learning.md` and `.claude/Memory.md` as system context
2. When Claude gets corrected, the lesson is appended to `.claude/Learning.md` (one `##` heading per lesson)
3. When `Learning.md` grows past the threshold (≥40 entries / ≥400 lines), the hook nudges you to run `/r-dreaming` to converge — merge duplicates, promote recurring lessons into CLAUDE.md, prune stale entries
4. `/r-handoff` compacts the conversation into `Memory.md` so the next session picks up where you left off

ADRs in `docs/adr/` are loaded on demand (not auto-injected) — they record one-shot decisions, not recurring patterns.

## Status Line

`.claude/statusline.sh` renders: **git branch · model · token usage (↑in ↓out) · context usage (% of window) · session price ($)**, with the context figure coloured green / yellow / red as it fills.

It reads the session JSON from stdin (parsed with `python3`, falling back to `jq`) and asks `git` directly for the branch. No nerd-font glyphs, so it renders anywhere.

**Set it up once per machine (global — every project picks it up):** in `~/.claude/settings.json` point `statusLine` at this repo's script via an absolute path. Clone the repo to the *same* path on each machine (e.g. `~/dotclaude`) so the global config stays portable:

```json
{ "statusLine": { "type": "command", "command": "/home/you/dotclaude/.claude/statusline.sh" } }
```

To update it later: `git pull` in your clone — the change applies to all projects on that machine. (This is why the script lives here, not in each project's `.claude/`.)

## Usage

Clone this repo and open it with Claude Code. The `.claude/` config is picked up automatically.

**First time in another project** — run the sync script from the target project (or pass its path):

```bash
/path/to/dotclaude/sync.sh /path/to/your-project        # add --dry-run to preview
```

Then fill `.claude/Wiki.md` (stack, glossary, etc.) and add ADRs as decisions arise.

**Updating an existing project** — re-run the same command after pulling template changes. `sync.sh` is the single source of truth for what travels:

| | Files | On sync |
|---|---|---|
| **Template** | `CLAUDE.md`, `skills/`, `hooks/`, `statusline.sh`, `settings.json`, `docs/ADR-FORMAT.md`, `docs/adr/README.md` | **Overwritten** (project overrides go in `settings.local.json`) |
| **Project knowledge** | `Wiki.md`, `Learning.md` | **Seeded only if missing** — never clobbered |
| **Volatile / local** | `Memory.md`, `settings.local.json` | **Untouched** |

`.claude/Memory.md` is gitignored — it accumulates per-project as you work.
