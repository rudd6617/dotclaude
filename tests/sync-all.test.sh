#!/bin/bash
# Tests for sync.sh: global install, project tidy-up, and --all.
# Run: bash tests/sync-all.test.sh
SRC="$(cd "$(dirname "$0")/.." && pwd)"
SYNC="$SRC/sync.sh"
FAILS=0

check() { # name, condition-exit-code
  if [ "$2" -eq 0 ]; then echo "ok   $1"; else echo "FAIL $1"; FAILS=$((FAILS + 1)); fi
}
commit() { git -C "$1" add -A && git -C "$1" -c user.name=t -c user.email=t@t commit -qm "${2:-wip}"; }

# old_project <dir> <git>: a project as the old copy-everything sync left it.
old_project() {
  mkdir -p "$1/.claude/hooks" "$1/docs"
  printf '@../AGENTS.md\n\n# Claude Code 專屬設定\n' > "$1/.claude/CLAUDE.md"
  printf '# 家規 — 開發原則與流程\n\nrules\n\n## Project Context\n\n店面營運系統（自訂簡介）。\n' > "$1/AGENTS.md"
  echo '# hook' > "$1/.claude/hooks/inject-memory.sh"
  echo '# hook' > "$1/.claude/hooks/check-reply.py"
  echo '{"hooks":{"Stop":[{"hooks":[{"type":"command","command":"python3 \"$CLAUDE_PROJECT_DIR/.claude/hooks/check-reply.py\""}]}]}}' > "$1/.claude/settings.json"
  echo old > "$1/docs/MAINTENANCE.md"; echo old > "$1/docs/ADR-FORMAT.md"
  echo '# mine' > "$1/.claude/Verify.md"
  echo 'memory' > "$1/.claude/Memory.md"
  if [ "$2" = yes ]; then git -C "$1" init -q && commit "$1" init; fi
}
migrated() { [ "$(cat "$1/.claude/CLAUDE.md")" = '@../AGENTS.md' ]; }

root=$(mktemp -d)
export HOME="$root/home"
mkdir -p "$HOME/.claude"
echo '{"theme":"dark","hooks":{"SessionStart":[{"matcher":"startup","hooks":[{"type":"command","command":"bash other.sh"}]}]}}' > "$HOME/.claude/settings.json"
old_project "$root/clean" yes
old_project "$root/dirty" yes; echo wip > "$root/dirty/wip.txt"
old_project "$root/nogit" no
mkdir -p "$root/stranger/.claude" && echo '# own' > "$root/stranger/.claude/CLAUDE.md" && git -C "$root/stranger" init -q && commit "$root/stranger" init

# 1. Dry run lists targets and writes nothing, globally or in projects
out=$("$SYNC" --all "$root" --dry-run)
grep -q "^sync   .*/clean$" <<<"$out" && ! migrated "$root/clean" && [ ! -e "$HOME/.claude/CLAUDE.md" ]
check "dry-run writes nothing" $?

# 2. Answering no aborts without writing
echo n | "$SYNC" --all "$root" >/dev/null 2>&1
! migrated "$root/clean"; check "answer no aborts" $?

# 3. Answering yes migrates only the clean template project
out=$(echo y | "$SYNC" --all "$root")
migrated "$root/clean"; check "clean project migrated" $?
! migrated "$root/dirty" && grep -q "skip   .*/dirty (uncommitted changes)" <<<"$out"; check "dirty project skipped" $?
! migrated "$root/nogit" && grep -q "skip   .*/nogit (not a git repo)" <<<"$out"; check "non-git project skipped" $?
[ "$(cat "$root/stranger/.claude/CLAUDE.md")" = '# own' ] && ! grep -q stranger <<<"$out"; check "non-template project untouched" $?

# 4. The migrated project keeps only its own files
p="$root/clean"
[ "$(cat "$p/AGENTS.md")" = "$(printf '## Project Context\n\n店面營運系統（自訂簡介）。')" ]; check "AGENTS.md trimmed to Project Context" $?
[ ! -e "$p/.claude/hooks" ] && [ ! -e "$p/.claude/settings.json" ] && [ ! -e "$p/docs/MAINTENANCE.md" ] && [ ! -e "$p/docs/ADR-FORMAT.md" ]
check "template copies removed" $?
grep -q '^# mine$' "$p/.claude/Verify.md" && grep -q '^memory$' "$p/.claude/Memory.md" && [ -f "$p/.claude/Wiki.md" ] && [ -f "$p/docs/adr/README.md" ]
check "own files kept, missing seeds added" $?

# 5. Global install: links and hooks, existing settings kept
[ "$(readlink "$HOME/.claude/CLAUDE.md")" = "$SRC/global/CLAUDE.md" ] && [ "$(readlink "$HOME/.codex/AGENTS.md")" = "$SRC/global/AGENTS.md" ]
check "global CLAUDE.md and codex AGENTS.md linked" $?
hooks() { python3 -c 'import json,sys; d=json.load(open(sys.argv[1])); print(" ".join(h["command"] for gs in d["hooks"].values() for g in gs for h in g["hooks"]), d.get("theme"))' "$HOME/.claude/settings.json"; }
h="$(hooks)"
grep -q "bash '$SRC/.claude/hooks/inject-memory.sh'" <<<"$h" && grep -q "python3 '$SRC/.claude/hooks/check-reply.py'" <<<"$h" && grep -q 'bash other.sh' <<<"$h" && grep -q 'dark$' <<<"$h"
check "hooks registered, other settings kept" $?

# 6. Re-running changes nothing
commit "$p" migrated
"$SYNC" --global >/dev/null && "$SYNC" "$p" >/dev/null
[ "$(hooks)" = "$h" ] && [ -z "$(git -C "$p" status --porcelain)" ]; check "second run is a no-op" $?

# 7. A project settings.json with its own settings is kept
old_project "$root/custom" no
echo '{"permissions":{"allow":["Bash(ls)"]},"hooks":{}}' > "$root/custom/.claude/settings.json"
echo '# mine' > "$root/custom/.claude/hooks/own.sh"
"$SYNC" "$root/custom" >/dev/null
[ -f "$root/custom/.claude/settings.json" ] && [ -f "$root/custom/.claude/hooks/own.sh" ]; check "project's own settings and hooks kept" $?

# 8. Template placeholder context is not carried over; missing AGENTS.md is seeded
mkdir -p "$root/bare/.claude"
printf '# 家規\n\n## Project Context\n\n通用模板（請依專案填寫）。\n' > "$root/bare/AGENTS.md"
"$SYNC" "$root/bare" >/dev/null
grep -q '請填' "$root/bare/AGENTS.md" && ! grep -q '請依專案填寫' "$root/bare/AGENTS.md"; check "placeholder context replaced" $?
mkdir -p "$root/empty"; "$SYNC" "$root/empty" >/dev/null
grep -q '^## Project Context$' "$root/empty/AGENTS.md" && migrated "$root/empty"; check "missing AGENTS.md seeded" $?

rm -rf "$root"
[ "$FAILS" -eq 0 ] && echo "all passed" || { echo "$FAILS failed"; exit 1; }
