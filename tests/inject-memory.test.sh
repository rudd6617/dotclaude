#!/bin/bash
# Tests for .claude/hooks/inject-memory.sh. Run: bash tests/inject-memory.test.sh
HOOK="$(cd "$(dirname "$0")/.." && pwd)/.claude/hooks/inject-memory.sh"
FAILS=0

check() { # name, condition-exit-code
  if [ "$2" -eq 0 ]; then echo "ok   $1"; else echo "FAIL $1"; FAILS=$((FAILS + 1)); fi
}

new_project() {
  local dir; dir=$(mktemp -d)
  mkdir -p "$dir/.claude"
  echo "$dir"
}

run_hook() { CLAUDE_PROJECT_DIR="$1" bash "$HOOK"; }

# Model-visible context for SessionStart is hookSpecificOutput.additionalContext;
# systemMessage is shown to the user only.
context_of() {
  python3 -c 'import sys,json
d=json.load(sys.stdin)["hookSpecificOutput"]
assert d["hookEventName"]=="SessionStart"
print(d["additionalContext"])'
}

# 1. Learning content reaches the model's context
p=$(new_project)
printf '## 不要用 rm -rf 清 build\n改用 make clean。\n' > "$p/.claude/Learning.md"
out=$(run_hook "$p" | context_of 2>/dev/null)
grep -q '不要用 rm -rf 清 build' <<<"$out"; check "learning in additionalContext" $?

# 2. Placeholder-only files inject nothing
p=$(new_project)
printf '# Learning\n\n（尚無條目）\n' > "$p/.claude/Learning.md"
out=$(run_hook "$p")
[ -z "$out" ]; check "placeholder-only injects nothing" $?

# 3. Oversized content puts the convergence nudge first, inside the 2,000-char preview
p=$(new_project)
for i in $(seq 1 30); do
  printf '## 教訓 %d\n%s\n' "$i" "$(printf '這是一段很長的教訓內容%.0s' $(seq 1 40))"
done > "$p/.claude/Learning.md"
out=$(run_hook "$p" | context_of 2>/dev/null)
head -c 2000 <<<"$out" | grep -q '^\[learning\]'; check "oversize nudge within preview" $?

[ "$FAILS" -eq 0 ] && echo "all passed" || { echo "$FAILS failed"; exit 1; }
