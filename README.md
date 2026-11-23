# my-claude

Personal Claude Code template — development principles, custom skills, hooks, ADR scaffolding, and a self-improvement loop.

## What's in here

```
.
├── global/                       # Loaded machine-wide, never copied into projects
│   ├── AGENTS.md                 # House rules — principles, modes, workflow, git. Tool-agnostic; linked as ~/.codex/AGENTS.md
│   └── CLAUDE.md                 # Claude-only layer: skill routing, hooks. Linked as ~/.claude/CLAUDE.md; imports global/AGENTS.md
├── AGENTS.md                     # This repo's own Project Context (every project has one)
├── tools/                        # usage-*.py: mine ~/.claude transcripts for usage stats, corrections, hook sizes
├── sync.sh                       # Install the global links + hooks; tidy a project down to its own files
├── docs/
│   ├── ADR-FORMAT.md             # ADR template
│   ├── MAINTENANCE.md            # How institutional files get edited (zones, proposal format, sync)
│   ├── adr/
│   │   └── README.md             # When to write an ADR (three conditions)
│   ├── harness-diagnosis-2026-07-04.md   # One-off audit: top harness weaknesses + evidence
│   └── letter-to-future-sessions.md      # Read once per new machine/major model change
├── .out-of-scope/                # Rejected proposals (why NOT to do X)
└── .claude/
    ├── CLAUDE.md                 # One line `@../AGENTS.md`: pulls in this repo's Project Context
    ├── Wiki.md                   # Long-term knowledge: background, stack, dirs, API, glossary
    ├── Verify.md                 # Walkthrough playbook: launch, login, isolation, evidence, cleanup
    ├── Memory.md                 # Volatile session state — where to pick up (gitignored in this repo; per-project choice)
    ├── Learning.md               # Accumulated mistakes & lessons (auto-injected)
    ├── settings.local.json       # Local permissions
    ├── hooks/
    │   ├── inject-memory.sh      # Auto-inject Learning + Memory; nudge a convergence pass past threshold
    │   └── check-reply.py        # Stop hook: send a mostly-English reply back for a rewrite; nudge a handoff past 200k tokens
    └── skills/
        ├── r-grill/SKILL.md            # /r-grill — alignment in frontier rounds (+ Wiki/ADR upkeep)
        ├── r-plan/SKILL.md             # /r-plan — architecture planning (4 sections)
        ├── r-review/SKILL.md           # /r-review — single-file/PR quality check
        ├── r-multi-review/SKILL.md     # /r-multi-review — multi-model grounded + adversarial review
        ├── r-design/SKILL.md           # /r-design — frontend design anti-pattern checklist
        ├── r-deepen/SKILL.md           # /r-deepen — codebase-level refactor opportunities
        ├── r-eli5/SKILL.md             # /r-eli5 — explain to an outsider, big pictures few words
        ├── r-make/SKILL.md             # /r-make — root Makefile as a thin, guarded front door to existing commands
        ├── r-handoff/SKILL.md          # /r-handoff — compact conversation into Memory.md
        └── r-backlog/SKILL.md          # /r-backlog — update open-todo-backlog.md, then list every remaining item
```

## Core Principles

Encoded in `AGENTS.md`:

1. **Solve real problems** — complexity must match severity
2. **Conservative dependencies** — stdlib over third-party
3. **Test-first bug fixes** — write a failing test before fixing; missing test seam is itself an architectural finding
4. **Isolate changes only when needed** — work on the current branch by default; ask about a git worktree only when production runs from this folder or another session is editing the same repo
5. **Ask when ambiguous** — list options, don't silently pick
6. **Output is an interface** — conclusion first; at most two options and one question when asking for a decision; three lines after "I don't follow"
7. **Done has a definition** — verification run (result pasted), effect seen with your own eyes, verification entry point given, audit-type tasks list checked vs unchecked; missing any one means reporting progress, not completion
8. **A correction is a spec** — one observed symptom is a hard rule applied to every like case inside the current change; the same correction twice means the verification method is broken, fix that first

## Document Roles

| File | Purpose | When |
|---|---|---|
| `global/AGENTS.md` | **House rules** — principles, modes, workflow, git conventions. Tool-agnostic: Claude and Codex both load it machine-wide | Rules change (edit here, commit — live everywhere) |
| `global/CLAUDE.md` | Claude-only layer: skill routing, hook mechanics. Imports `global/AGENTS.md` on its first line | Claude-specific mechanics change |
| project `AGENTS.md` | The project's own `## Project Context`; its `.claude/CLAUDE.md` is just `@../AGENTS.md` | Project scope or stack changes |
| `docs/MAINTENANCE.md` | Edit zones, proposal format, sync discipline for institutional files | Before editing CLAUDE.md / skills / hooks |
| `.claude/Memory.md` | Volatile session state — where to pick up | End of session (`/r-handoff`) or progress changes |
| `.claude/Learning.md` | Recurring failure patterns & lessons | You got corrected, it could happen again, and no structure / check / test can block it (`docs/MAINTENANCE.md` §3) |
| `.claude/Wiki.md` | Long-term knowledge: background, stack, dirs, API, glossary | Aligning on a term / resolving a new concept |
| `.claude/Verify.md` | Walkthrough playbook: launch, login, isolation, evidence, cleanup | Before the first UI walkthrough; when a step goes stale |
| `docs/adr/NNNN-*.md` | Architecture decisions (why X not Y) | All three ADR conditions hold |
| `.out-of-scope/*.md` | Rejected proposals (why NOT to do X) | The same proposal could resurface |

## Why the rules live in two files

Claude Code only reads `CLAUDE.md`; Codex only reads `AGENTS.md`; Gemini CLI only reads `GEMINI.md` unless reconfigured. Those filenames are hardcoded per tool, so one file can never serve all of them.

So the rules split by **audience, not by tool**:

- **`global/AGENTS.md`** — everything tool-agnostic. Codex reads it as `~/.codex/AGENTS.md`; Claude Code pulls it in via the `@~/Documents/dotclaude/global/AGENTS.md` import on the first line of `global/CLAUDE.md`.
- **`global/CLAUDE.md`** — only what is Claude-specific: the `/r-*` skill table and the hooks. Linked as `~/.claude/CLAUDE.md`.

Both are user-level, so one edit here reaches every project with no sync. The project's own description stays in the project: root `AGENTS.md` (read by Codex directly, by Claude through the project's one-line `.claude/CLAUDE.md`).

Roles are **not** baked into either file. `AGENTS.md` carries a short **Modes** section instead — *default mode* (serving the user directly: read Memory/Learning, confirm before changing code) and *reviewer mode* (dispatched to audit code: read none of that, no edits, no commits). The dispatcher names the mode in its prompt, e.g. *"review X in reviewer mode per AGENTS.md"*. `codex exec` and `codex review` auto-load `~/.codex/AGENTS.md` and the project's root `AGENTS.md` on every call, so nothing else has to be wired up. Add a mode by adding a short subsection — not a new directory.

## Custom Skills

| Skill | Trigger | Purpose |
|---|---|---|
| `/r-grill` | Requirements are fuzzy | Frontier rounds: ask every answerable question, recompute; keeps Wiki/ADR current when terms resolve |
| `/r-plan` | Architecture or multi-file changes (after alignment) | Data flow, complexity, risks, go/no-go |
| `/r-review` | Single file or PR | Taste rating, fatal issues, complexity, data structures |
| `/r-multi-review` | Before finalizing; hallucinations would be costly | Two blind grounded verifiers + an adversarial refuter |
| `/r-design` | Building or reviewing frontend UI | Anti-pattern checklist against AI-looking design |
| `/r-deepen` | Codebase-level architecture review | Find shallow modules, weak seams, locality issues |
| `/r-eli5` | Explaining something to an outsider | HTML artifact: big pictures, very few words |
| `/r-make` | Collecting dev / check / deploy commands | Root Makefile wrapping existing commands, guards scaled to risk |
| `/r-handoff` | End of a long session / before compaction | Compact into `.claude/Memory.md`; if `open-todo-backlog.md` exists, update it and move long-lived to-dos there |
| `/r-backlog` | Asking what is left / updating remaining work | Update `open-todo-backlog.md` from commits, tickets and the conversation; list every item and a suggested next one |

Typical flows:
- Simple: just do it
- Medium: `/r-grill` → implement → `/r-review`
- Complex: `/r-grill` → `/r-plan` → implement → `/r-review`
- Bug: failing test first, then fix (`AGENTS.md` principle 3)
- Periodic: `/r-deepen`

## Self-Improvement Loop

1. **SessionStart hook** runs `inject-memory.sh` — injects `.claude/Learning.md` and `.claude/Memory.md` as system context
2. When Claude gets corrected, the fix goes to the strongest layer that holds: structure → types / lint / hook → test. Only a lesson none of those can block is appended to `.claude/Learning.md` (one `##` heading per lesson, with why no stronger layer works). Each text rule's enforcer is tracked in `docs/MAINTENANCE.md` §3
3. When `Learning.md` grows past the threshold (≥40 entries / ≥400 lines / ≥9,000 injected characters — Claude Code cuts context past 10,000 to a 2,000-char preview), the hook nudges a convergence pass — merge duplicates, promote recurring lessons into `AGENTS.md` principles, prune stale entries (criteria in `docs/MAINTENANCE.md` §4)
4. `/r-handoff` compacts the conversation into `Memory.md` so the next session picks up where you left off, and moves long-lived to-dos into `open-todo-backlog.md` when that file exists

ADRs in `docs/adr/` are loaded on demand (not auto-injected) — they record one-shot decisions, not recurring patterns.

## User-Level Tools

This repo holds the house rules, skills and hooks. Machine-wide Claude Code tools — the status line and mods (e.g. the `ports-backlog` pane) — live in the [dotfiles](https://github.com/rudd6617/dotfiles) repo under `claude/`, installed by its `install.sh`.

## Usage

Clone this repo to `~/Documents/dotclaude` (the rules reference that path), then install it machine-wide once:

```bash
~/Documents/dotclaude/sync.sh --global      # ~/.claude/CLAUDE.md, ~/.codex/AGENTS.md, skills, hooks; add --dry-run to preview
```

After that, editing anything under `global/`, `.claude/skills/` or `.claude/hooks/` takes effect in every project at once — no sync. Re-run `--global` only after adding or removing a skill.

**A project** holds only its own files. Set one up, or tidy a project from the old copy-everything layout:

```bash
~/Documents/dotclaude/sync.sh /path/to/your-project         # add --dry-run to preview
~/Documents/dotclaude/sync.sh --all ~/Documents ~/services   # every clean git project that carries the template
```

| | Files | On sync |
|---|---|---|
| **Rules** | `AGENTS.md` | Cut down to its `## Project Context` section (the rules are global now) |
| **Claude entry** | `.claude/CLAUDE.md` | Becomes `@../AGENTS.md` |
| **Old template copies** | `.claude/hooks/`, `.claude/settings.json`, `docs/ADR-FORMAT.md`, `docs/MAINTENANCE.md`, `.claude/skills/r-*` | **Removed** — kept with a warning if they hold the project's own hooks or settings |
| **Project knowledge** | `Wiki.md`, `Learning.md`, `Verify.md`, `docs/adr/README.md` | **Seeded only if missing** — never clobbered |
| **Volatile / local** | `Memory.md`, `settings.local.json` | **Untouched** |

Whether `.claude/Memory.md` is version-controlled is **each project's call** — `sync.sh` never touches it and `.gitignore` is not synced. This repo ignores it; a project handed off across machines may commit it instead, at the cost of merge conflicts between parallel sessions. Check which you have with `git ls-files .claude/Memory.md`.

Rule of thumb: house rules, skills and hooks are edited here only; a project's own `AGENTS.md`, Wiki and Learning are edited in the project (details: `docs/MAINTENANCE.md`).
