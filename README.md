# my-claude

Personal Claude Code template — development principles, custom skills, hooks, ADR/CONTEXT scaffolding, and a self-improvement loop.

## What's in here

```
.
├── CONTEXT.md                    # Domain glossary (fill per-project)
├── docs/
│   ├── ADR-FORMAT.md             # ADR template
│   └── adr/
│       └── README.md             # When to write an ADR (three conditions)
└── .claude/
    ├── CLAUDE.md                 # Principles, file/skill mapping, workflow
    ├── stack.md                  # Tech stack (fill per-project)
    ├── settings.json             # Hooks (SessionStart lesson injection)
    ├── settings.local.json       # Local permissions
    ├── launch.json               # Editor launch config
    ├── hooks/
    │   └── inject-lessons.sh     # Auto-inject lessons from past sessions
    ├── skills/
    │   ├── grill/SKILL.md            # /grill — pre-implementation alignment
    │   ├── grill-with-docs/SKILL.md  # /grill-with-docs — alignment + CONTEXT/ADR
    │   ├── plan/SKILL.md             # /plan — architecture planning (4 sections)
    │   ├── diagnose/SKILL.md         # /diagnose — 6-phase debugging
    │   ├── review/SKILL.md           # /review — single-file/PR quality check
    │   └── deepen/SKILL.md           # /deepen — codebase-level refactor opportunities
    └── lessons/                  # Accumulated lessons (auto-injected)
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

## Document Roles

| File | Purpose | When |
|---|---|---|
| `.claude/CLAUDE.md` | Rules and process | Rules change |
| `CONTEXT.md` | Domain glossary | Second time you need to align on a term |
| `docs/adr/NNNN-*.md` | Architecture decisions | All three ADR conditions hold |
| `.claude/lessons/*.md` | Recurring failure patterns | You got corrected and it could happen again |

## Custom Skills

| Skill | Trigger | Purpose |
|---|---|---|
| `/grill` | Requirements are fuzzy | One-question-at-a-time alignment |
| `/grill-with-docs` | Domain decisions need to be recorded | grill + CONTEXT/ADR maintenance |
| `/plan` | Architecture or multi-file changes (after alignment) | Data flow, complexity, risks, go/no-go |
| `/diagnose` | Bug, regression, test failure, perf issue | 6-phase loop: feedback loop → reproduce → hypothesise → instrument → fix → post-mortem |
| `/review` | Single file or PR | Taste rating, fatal issues, complexity, data structures |
| `/deepen` | Codebase-level architecture review | Find shallow modules, weak seams, locality issues |

Typical flows:
- Simple: just do it
- Medium: `/grill` → implement → `/review`
- Complex: `/grill-with-docs` → `/plan` → implement → `/review`
- Bug: `/diagnose`
- Periodic: `/deepen`

## Self-Improvement Loop

1. **SessionStart hook** runs `inject-lessons.sh` — reads all `.claude/lessons/*.md` and injects them as system context
2. When Claude gets corrected, the lesson is saved to `.claude/lessons/`
3. Next session automatically picks up all accumulated lessons

ADRs in `docs/adr/` are loaded on demand (not auto-injected) — they record one-shot decisions, not recurring patterns.

## Usage

Clone this repo and open it with Claude Code. The `.claude/` config is picked up automatically.

To use in another project: copy `.claude/`, `CONTEXT.md`, and `docs/` into that project's root, then fill `.claude/stack.md`, `CONTEXT.md`, and add ADRs as decisions arise.
