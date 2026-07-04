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
    ├── CLAUDE.md                 # Principles, file/skill mapping, workflow
    ├── Wiki.md                   # Long-term knowledge: background, stack, dirs, API, glossary
    ├── Memory.md                 # Volatile session state — where to pick up (gitignored)
    ├── Learning.md               # Accumulated mistakes & lessons (auto-injected)
    ├── settings.json             # Hooks (SessionStart memory injection)
    ├── settings.local.json       # Local permissions
    ├── launch.json               # Editor launch config
    ├── statusline.sh             # Status bar (lives here only — NOT synced; global settings point at it)
    ├── hooks/
    │   └── inject-memory.sh      # Auto-inject Learning + Memory; nudge /r-dreaming past threshold
    └── skills/
        ├── r-fable/                    # /r-fable — institutional layer (2026-07-04 Fable session)
        │   ├── SKILL.md                #   iron rules, session-start checklist, routing to booklets
        │   ├── dispatch.md             #   model/subagent dispatch, escalation ladder
        │   ├── judgment.md             #   done-definition, ask-or-decide, wrong-direction signals
        │   ├── delegation-templates.md #   fill-in-the-blank subagent prompts
        │   └── maintenance.md          #   green/yellow/red edit zones, rule lifecycle
        ├── r-zoom-out/SKILL.md         # /r-zoom-out — map an unfamiliar module
        ├── r-grill/SKILL.md            # /r-grill — alignment in frontier rounds (+ Wiki/ADR upkeep)
        ├── r-wayfinder/SKILL.md        # /r-wayfinder — decision map for multi-session efforts
        ├── r-plan/SKILL.md             # /r-plan — architecture planning (4 sections)
        ├── r-ticket/SKILL.md           # /r-ticket — spec issue + tracer-bullet slices
        ├── r-diagnose/SKILL.md         # /r-diagnose — 6-phase debugging (+ HITL loop template)
        ├── r-review/SKILL.md           # /r-review — single-file/PR quality check
        ├── r-multi-review/SKILL.md     # /r-multi-review — multi-model grounded + adversarial review
        ├── r-design/SKILL.md           # /r-design — frontend design anti-pattern checklist
        ├── r-deepen/SKILL.md           # /r-deepen — codebase-level refactor opportunities
        ├── r-eli5/SKILL.md             # /r-eli5 — explain to an outsider, big pictures few words
        ├── r-handoff/SKILL.md          # /r-handoff — compact conversation into Memory.md
        ├── r-dreaming/SKILL.md         # /r-dreaming — converge Learning.md
        ├── r-audit/SKILL.md            # /r-audit — harness health check: doc-vs-reality + pain mining
        └── r-teach/SKILL.md            # /r-teach — turn the workspace into a teaching environment
```

## Core Principles

Encoded in `.claude/CLAUDE.md`:

1. **Programming taste** — design the data then the logic; reshape data instead of adding branches; max 3 levels of indentation, functions do one thing; names say *what*, not *how*
2. **Never break existing behavior** — list impact before changing
3. **Solve real problems** — complexity must match severity
4. **Early return, fail fast** — errors surface immediately, no defensive try-catch
5. **Conservative dependencies** — stdlib over third-party
6. **Test-first bug fixes** — write a failing test before fixing; missing test seam is itself an architectural finding
7. **Isolate cross-file refactors** — ask about a git worktree first
8. **Touch only what's necessary** — no drive-by refactor / formatting / docstring
9. **Ask when ambiguous** — list options, don't silently pick
10. **Output is an interface** — conclusion first, tables over walls of prose, claims backed by evidence

Plus four per-turn iron rules (confirm-before-edit, done-has-a-definition, correction-is-spec, commander-doesn't-grind) — packaged in the `/r-fable` skill together with the dispatch/judgment/delegation/maintenance booklets.

## /r-fable — institutional layer (added 2026-07-04)

`CLAUDE.md` keeps its original shape; the institutional layer lives in one skill, `/r-fable`, whose SKILL.md routes to booklets in the same directory:

| Trigger | Booklet |
|---|---|
| Spawning subagents, choosing model, retry/escalation | `skills/r-fable/dispatch.md` |
| Writing a delegation prompt | `skills/r-fable/delegation-templates.md` |
| Is it done? Should I ask? Wrong direction? | `skills/r-fable/judgment.md` |
| Editing CLAUDE.md / skills / hooks | `skills/r-fable/maintenance.md` |

Evidence base: `docs/harness-diagnosis-2026-07-04.md` (session-log mining of ~600 user messages + config audit).

## Document Roles

| File | Purpose | When |
|---|---|---|
| `.claude/CLAUDE.md` | Rules, process, stable preferences | Rules change (edit in this repo, then sync) |
| `.claude/skills/r-fable/*.md` | Iron rules + dispatch / judgment / delegation / maintenance | Per `skills/r-fable/maintenance.md` |
| `.claude/Memory.md` | Volatile session state — where to pick up (gitignored) | End of session (`/r-handoff`) or progress changes |
| `.claude/Learning.md` | Recurring failure patterns & lessons | You got corrected and it could happen again |
| `.claude/Wiki.md` | Long-term knowledge: background, stack, dirs, API, glossary | Aligning on a term / resolving a new concept |
| `docs/adr/NNNN-*.md` | Architecture decisions (why X not Y) | All three ADR conditions hold |
| `.out-of-scope/*.md` | Rejected proposals (why NOT to do X) | The same proposal could resurface |

## Custom Skills

| Skill | Trigger | Purpose |
|---|---|---|
| `/r-fable` | Before delegating, claiming done, retrying, asking the user, or editing `.claude` files | Iron rules + dispatch, judgment, delegation templates, maintenance zones |
| `/r-zoom-out` | Entering an unfamiliar module | Global view: roles, boundaries, data flow |
| `/r-grill` | Requirements are fuzzy | Frontier rounds: ask every answerable question, recompute; keeps Wiki/ADR current when terms resolve |
| `/r-wayfinder` | Effort too big for one session | Decision map of tickets on GitHub, resolved one at a time |
| `/r-plan` | Architecture or multi-file changes (after alignment) | Data flow, complexity, risks, go/no-go |
| `/r-ticket` | Aligned work needs independently shippable slices | Spec issue + tracer-bullet tickets with blocking order |
| `/r-diagnose` | Bug, regression, test failure, perf issue | 6-phase loop: feedback loop → reproduce → hypothesise → instrument → fix → post-mortem |
| `/r-review` | Single file or PR | Taste rating, fatal issues, complexity, data structures |
| `/r-multi-review` | Before finalizing; hallucinations would be costly | Two blind grounded verifiers + an adversarial refuter |
| `/r-design` | Building or reviewing frontend UI | Anti-pattern checklist against AI-looking design |
| `/r-deepen` | Codebase-level architecture review | Find shallow modules, weak seams, locality issues |
| `/r-eli5` | Explaining something to an outsider | HTML artifact: big pictures, very few words |
| `/r-handoff` | End of a long session / before compaction | Compact into `.claude/Memory.md` |
| `/r-dreaming` | `Learning.md` past the threshold | Merge, promote to principles, retire stale entries |
| `/r-audit` | Periodic / after big institutional changes | Doc-vs-reality audit + pain mining; findings carry verification commands, fixes only after approval |
| `/r-teach` | You want to learn a new concept or skill | Teaching workspace: storage strength, ZPD, cite high-trust sources |

Typical flows:
- Simple: just do it
- Medium: `/r-grill` → implement → `/r-review`
- Complex: `/r-grill` → `/r-plan` → implement → `/r-review`
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
| **Template** | `CLAUDE.md`, `skills/`, `hooks/`, `settings.json`, `docs/ADR-FORMAT.md`, `docs/adr/README.md` | **Overwritten** (project overrides go in `settings.local.json`) |
| **Project knowledge** | `Wiki.md`, `Learning.md` | **Seeded only if missing** — never clobbered |
| **Volatile / local** | `Memory.md`, `settings.local.json` | **Untouched** |

`.claude/Memory.md` is gitignored — it accumulates per-project as you work.

Rule of thumb: never edit template-managed files inside a project — edit them here, commit, re-sync (details: `.claude/skills/r-fable/maintenance.md`).
