# my-claude

Personal Claude Code template — development principles, custom skills, hooks, ADR scaffolding, and a self-improvement loop.

## What's in here

```
.
├── sync.sh                       # Push template updates into another project (overwrite managed, keep yours)
├── docs/
│   ├── ADR-FORMAT.md             # ADR template
│   ├── adr/
│   │   └── README.md             # When to write an ADR (three conditions)
│   ├── harness-diagnosis-2026-07-04.md   # One-off audit: top harness weaknesses + evidence
│   └── letter-to-future-sessions.md      # Read once per new machine/major model change
├── .out-of-scope/                # Rejected proposals (why NOT to do X)
└── .claude/
    ├── CLAUDE.md                 # Per-turn iron rules, principles, routing table
    ├── rules/
    │   ├── dispatch.md           # Model/subagent dispatch doctrine (who does what, escalation)
    │   ├── judgment.md           # Done-definition, when to ask, wrong-direction signals
    │   ├── delegation-templates.md  # Fill-in-the-blank subagent prompts (search/impl/refactor/research/review)
    │   └── maintenance.md        # How these files get updated safely (green/yellow/red zones)
    ├── Wiki.md                   # Long-term knowledge: background, stack, dirs, API, glossary
    ├── Memory.md                 # Volatile session state — where to pick up (git-tracked for cross-machine handoff)
    ├── Learning.md               # Accumulated mistakes & lessons (auto-injected)
    ├── settings.json             # Hooks (SessionStart memory injection)
    ├── settings.local.json       # Local permissions
    ├── launch.json               # Editor launch config
    ├── statusline.sh             # Status bar (lives here only — NOT synced; global settings point at it)
    ├── hooks/
    │   └── inject-memory.sh      # Auto-inject Learning + Memory; nudge /r-dreaming past threshold
    └── skills/
        ├── r-zoom-out/SKILL.md         # /r-zoom-out — map an unfamiliar module
        ├── r-grill/SKILL.md            # /r-grill — alignment in frontier rounds (+ Wiki/ADR upkeep)
        ├── r-wayfinder/SKILL.md        # /r-wayfinder — decision map for multi-session efforts
        ├── r-plan/SKILL.md             # /r-plan — architecture planning (4 sections)
        ├── r-ticket/SKILL.md           # /r-ticket — spec issue + tracer-bullet slices
        ├── r-diagnose/SKILL.md         # /r-diagnose — 6-phase debugging (+ HITL loop template)
        ├── r-review/SKILL.md           # /r-review — single-file/PR quality check
        ├── r-multi-review/SKILL.md     # /r-multi-review — multi-model grounded + adversarial review
        ├── r-design/SKILL.md           # /r-design — frontend anti-AI-slop checklist
        ├── r-deepen/SKILL.md           # /r-deepen — codebase-level refactor opportunities
        ├── r-eli5/SKILL.md             # /r-eli5 — explain to an outsider, big pictures few words
        ├── r-handoff/SKILL.md          # /r-handoff — compact conversation into Memory.md
        ├── r-dreaming/SKILL.md         # /r-dreaming — converge Learning.md past threshold
        └── r-teach/SKILL.md            # /r-teach — turn the workspace into a teaching environment
```

## Core Principles

Encoded in `.claude/CLAUDE.md`:

1. **Data structures first** — design the data, then write the logic
2. **Eliminate special cases** — reshape data instead of adding branches
3. **Max 3 levels of indentation** — functions do one thing
4. **Never break existing behavior** — list impact before changing; re-walk affected flows after
5. **Solve real problems** — complexity must match severity
6. **Early return, fail fast** — errors surface immediately
7. **Name the intent** — names say *what*, not *how*
8. **Conservative dependencies** — stdlib over third-party
9. **Test-first bug fixes** — write a failing test before fixing
10. **Isolate cross-file refactors** — ask about git worktree first
11. **Touch only what's necessary** — no drive-by refactor / formatting / unrequested UI labels
12. **Ask when ambiguous** — list options with stable letters; but look up look-up-able facts yourself
13. **Output is an interface** — conclusion first, tables over prose, claims backed by evidence

Plus four per-turn iron rules (confirm-before-edit, done-has-a-definition, correction-is-spec, commander-doesn't-grind) — see `CLAUDE.md` top section, with details externalized to `.claude/rules/`.

## Rules layer (added 2026-07-04)

`CLAUDE.md` stays short and routes to `.claude/rules/` on trigger:

| Trigger | File |
|---|---|
| Spawning subagents, choosing model, retry/escalation | `rules/dispatch.md` |
| Writing a delegation prompt | `rules/delegation-templates.md` |
| Is it done? Should I ask? Wrong direction? | `rules/judgment.md` |
| Editing CLAUDE.md / rules / skills / hooks | `rules/maintenance.md` |

Evidence base: `docs/harness-diagnosis-2026-07-04.md` (session-log mining of ~600 user messages + config audit).

## Document Roles

| File | Purpose | When |
|---|---|---|
| `.claude/CLAUDE.md` | Iron rules, principles, routing | Rules change (edit in this repo, then sync) |
| `.claude/rules/*.md` | Dispatch / judgment / delegation / maintenance | Per `rules/maintenance.md` |
| `.claude/Memory.md` | Volatile session state — where to pick up (**git-tracked** since 2026-07-03, for cross-machine handoff) | End of session (`/r-handoff`) |
| `.claude/Learning.md` | Recurring failure patterns & lessons | You got corrected and it could happen again |
| `.claude/Wiki.md` | Long-term knowledge: background, stack, dirs, API, glossary | Aligning on a term / new concept |
| `docs/adr/NNNN-*.md` | Architecture decisions (why X not Y) | All three ADR conditions hold |
| `.out-of-scope/*.md` | Rejected proposals (why NOT to do X) | The same proposal could resurface |

## Custom Skills

| Skill | Trigger |
|---|---|
| `/r-zoom-out` | Entering an unfamiliar module |
| `/r-grill` | Requirements are fuzzy |
| `/r-grill-with-docs` | Fuzzy + domain decisions worth recording |
| `/r-plan` | Architecture choice after alignment |
| `/r-diagnose` | Bug, regression, test failure, perf issue |
| `/r-review` | Post-implementation quality check |
| `/r-multi-review` | Before finalizing — hallucination/gap hunt (multi-model) |
| `/r-design` | Building or reviewing frontend UI |
| `/r-deepen` | Codebase-level architecture review |
| `/r-handoff` | End of long session — compact into Memory.md |
| `/r-dreaming` | Learning.md past threshold — converge |
| `/r-teach` | Learning a new concept (not dev flow) |

Typical flows: unfamiliar code `/r-zoom-out` first; simple → just do it; medium (2–3 files) `/r-grill` → implement → `/r-review`; complex (≥4 files / architecture / irreversible) `/r-grill-with-docs` → `/r-plan` → implement → `/r-review`; bug `/r-diagnose`; wrap-up `/r-handoff`.

## Self-Improvement Loop

1. **SessionStart hook** runs `inject-memory.sh` — injects `.claude/Learning.md` and `.claude/Memory.md` as system context
2. When Claude gets corrected, the lesson is appended to `.claude/Learning.md` (one `##` heading per lesson)
3. When `Learning.md` grows past the threshold (≥40 entries / ≥400 lines), the hook nudges you to run `/r-dreaming` — merge duplicates, propose promotions into `rules/`, prune stale entries
4. `/r-handoff` compacts the conversation into `Memory.md` so the next session picks up where you left off

ADRs in `docs/adr/` are loaded on demand (not auto-injected) — they record one-shot decisions, not recurring patterns.

## Status Line

`.claude/statusline.sh` renders: **git branch · model · token usage (↑in ↓out) · context usage (% of window) · session price ($)**.

It lives in this repo only (not synced into projects). **Set it up once per machine** — point the global config at it via an absolute path:

```json
{ "statusLine": { "type": "command", "command": "/Users/you/Documents/dotclaude/.claude/statusline.sh" } }
```

To update later: `git pull` in your clone — applies to all projects on the machine.

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
| **Template** | `CLAUDE.md`, `rules/`, `skills/`, `hooks/`, `settings.json`, `docs/ADR-FORMAT.md`, `docs/adr/README.md` | **Overwritten** (project overrides go in `settings.local.json`) |
| **Project knowledge** | `Wiki.md`, `Learning.md` | **Seeded only if missing** — never clobbered |
| **Volatile / local** | `Memory.md`, `settings.local.json` | **Untouched** |

Rule of thumb: never edit template-managed files inside a project — edit them here, commit, re-sync (details: `.claude/rules/maintenance.md`).
