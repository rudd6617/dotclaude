# my-claude

Personal Claude Code template — development principles, custom skills, hooks, ADR scaffolding, and a self-improvement loop.

## What's in here

```
.
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

## Usage

Clone this repo and open it with Claude Code. The `.claude/` config is picked up automatically.

To use in another project: copy `.claude/` and `docs/` into that project's root, then fill `.claude/Wiki.md` (stack, glossary, etc.) and add ADRs as decisions arise. `.claude/Memory.md` is gitignored — it accumulates per-project as you work.
