# my-claude

Personal Claude Code project configuration — development principles, custom skills, hooks, and a self-improvement loop.

## What's in here

```
.claude/
├── CLAUDE.md                  # Development principles & workflow
├── stack.md                   # Tech stack definition
├── settings.json              # Hooks (SessionStart lesson injection)
├── settings.local.json        # Local permissions
├── launch.json                # Vite dev server launch config
├── hooks/
│   └── inject-lessons.sh      # Auto-inject lessons from past sessions
├── skills/
│   ├── plan/SKILL.md          # /plan — architecture planning
│   └── review/SKILL.md        # /review — structured code review
└── lessons/                   # Accumulated lessons (auto-injected)
```

## Core Principles

Encoded in `CLAUDE.md`:

1. **Data structures first** — design the data, then write the logic
2. **Eliminate special cases** — reshape data instead of adding branches
3. **Max 3 levels of indentation** — functions do one thing
4. **Never break existing behavior** — list impact before changing
5. **Solve real problems** — complexity must match severity
6. **Early return, fail fast** — errors surface immediately
7. **Name the intent** — names say *what*, not *how*
8. **Conservative dependencies** — stdlib over third-party

## Custom Skills

| Skill | Trigger | Purpose |
|-------|---------|---------|
| `/plan` | Architecture or multi-file changes | Outputs data flow, complexity, risks, and a go/no-go verdict |
| `/review` | Code review | Rates taste, flags fatal issues, finds unnecessary complexity, evaluates data structures |

## Self-Improvement Loop

1. **SessionStart hook** runs `inject-lessons.sh` — reads all `.claude/lessons/*.md` and injects them as system context
2. When Claude makes a mistake or gets corrected, the lesson is saved to `.claude/lessons/`
3. Next session automatically picks up all accumulated lessons

## Usage

Clone this repo, then open it with Claude Code. The `.claude/` config is picked up automatically.

To use in another project, copy the `.claude/` directory into that project's root.
