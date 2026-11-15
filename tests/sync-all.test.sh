#!/bin/bash
# Tests for sync.sh --all. Run: bash tests/sync-all.test.sh
SYNC="$(cd "$(dirname "$0")/.." && pwd)/sync.sh"
FAILS=0

check() { # name, condition-exit-code
  if [ "$2" -eq 0 ]; then echo "ok   $1"; else echo "FAIL $1"; FAILS=$((FAILS + 1)); fi
}

# new_project <dir> <has-template> <git>
new_project() {
  mkdir -p "$1/.claude/hooks"
  [ "$2" = yes ] && echo '# old hook' > "$1/.claude/hooks/inject-memory.sh"
  echo '# old rules' > "$1/AGENTS.md"
  if [ "$3" = yes ]; then
    git -C "$1" init -q && git -C "$1" add -A && git -C "$1" -c user.name=t -c user.email=t@t commit -qm init
  fi
}
synced() { ! grep -q '^# old rules$' "$1/AGENTS.md"; }

root=$(mktemp -d)
export HOME="$root/home"   # skills link into ~/.claude/skills; keep the real one out of it
new_project "$root/clean"    yes yes
new_project "$root/dirty"    yes yes; echo wip > "$root/dirty/wip.txt"
new_project "$root/nogit"    yes no
new_project "$root/stranger" no  yes

# 1. Dry run lists targets and writes nothing
out=$("$SYNC" --all "$root" --dry-run)
grep -q "^sync   .*/clean$" <<<"$out" && ! synced "$root/clean"; check "dry-run writes nothing" $?

# 2. Answering no aborts without writing
echo n | "$SYNC" --all "$root" >/dev/null 2>&1
! synced "$root/clean"; check "answer no aborts" $?

# 3. Answering yes syncs only the clean template project
out=$(echo y | "$SYNC" --all "$root")
synced "$root/clean"; check "clean template project synced" $?
! synced "$root/dirty" && grep -q "skip   .*/dirty (uncommitted changes)" <<<"$out"; check "dirty project skipped" $?
! synced "$root/nogit" && grep -q "skip   .*/nogit (not a git repo)" <<<"$out"; check "non-git project skipped" $?
! synced "$root/stranger"; check "project without the template untouched" $?

# 4. Verify.md is seeded when missing and kept when present
[ -f "$root/clean/.claude/Verify.md" ]; check "Verify.md seeded" $?
echo '# mine' > "$root/clean/.claude/Verify.md"
git -C "$root/clean" add -A && git -C "$root/clean" -c user.name=t -c user.email=t@t commit -qm synced
echo y | "$SYNC" --all "$root" >/dev/null
grep -q '^# mine$' "$root/clean/.claude/Verify.md"; check "existing Verify.md kept" $?

# 5. Single-target form still works
"$SYNC" "$root/stranger" >/dev/null && synced "$root/stranger"; check "single target still syncs" $?

# 6. A project's own Project Context survives a sync; the placeholder does not stick
printf '# old rules\n\n## Project Context\n\n店面營運系統（自訂簡介）。\n' > "$root/stranger/AGENTS.md"
"$SYNC" "$root/stranger" >/dev/null
grep -q '^店面營運系統（自訂簡介）。$' "$root/stranger/AGENTS.md" \
  && ! grep -q '請依專案填寫' "$root/stranger/AGENTS.md" \
  && [ "$(grep -c '^## Project Context$' "$root/stranger/AGENTS.md")" -eq 1 ] \
  && synced "$root/stranger"; check "project's own Project Context kept" $?

printf '# old rules\n' > "$root/stranger/AGENTS.md"
"$SYNC" "$root/stranger" >/dev/null
grep -q '請依專案填寫' "$root/stranger/AGENTS.md"; check "no Project Context gets the template's" $?

[ "$FAILS" -eq 0 ] && echo "all passed" || { echo "$FAILS failed"; exit 1; }
