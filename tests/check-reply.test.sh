#!/bin/bash
# Tests for .claude/hooks/check-reply.py. Run: bash tests/check-reply.test.sh
HOOK="$(cd "$(dirname "$0")/.." && pwd)/.claude/hooks/check-reply.py"
FAILS=0
export TMPDIR; TMPDIR=$(mktemp -d)

check() { # name, condition-exit-code
  if [ "$2" -eq 0 ]; then echo "ok   $1"; else echo "FAIL $1"; FAILS=$((FAILS + 1)); fi
}

# run_hook <message> [stop_hook_active] [transcript_path] [session_id]
run_hook() {
  MSG="$1" ACTIVE="${2:-false}" TRANSCRIPT="${3:-}" SID="${4:-s1}" python3 -c '
import json, os
print(json.dumps({"last_assistant_message": os.environ["MSG"],
                  "stop_hook_active": os.environ["ACTIVE"] == "true",
                  "transcript_path": os.environ["TRANSCRIPT"],
                  "session_id": os.environ["SID"]}))' | python3 "$HOOK"
}

english=$(printf 'The feature is done in the worktree and it is not committed yet. %.0s' $(seq 1 12))
chinese=$(printf '功能已經做完，還沒有提交。測試全部通過。\n%.0s' $(seq 1 5))

# 1. A mostly-English reply is blocked, and the reason tells the model to rewrite in Chinese
out=$(run_hook "$english")
grep -q '"decision": "block"' <<<"$out" && grep -q '繁體中文' <<<"$out"; check "english reply blocked" $?

# 2. A Chinese reply passes with no output
out=$(run_hook "$chinese")
[ -z "$out" ]; check "chinese reply passes" $?

# 3. English inside code blocks does not count
code=$(printf '改好了，指令如下：\n```\n%s\n```\n' "$english")
out=$(run_hook "$code")
[ -z "$out" ]; check "english in code block ignored" $?

# 4. A long Chinese reply ending in a question passes: length is not checked
long=$(printf '這是一行說明。\n%.0s' $(seq 1 30); echo '要照這個做嗎？')
out=$(run_hook "$long")
[ -z "$out" ]; check "long chinese question passes" $?

# 5. stop_hook_active skips the checks, so a rewrite is asked for only once
out=$(run_hook "$english" true)
[ -z "$out" ]; check "no second block when stop_hook_active" $?

# 6. Long context nudges the user once per band, without blocking
transcript="$TMPDIR/t.jsonl"
usage_line() { printf '{"type":"assistant","message":{"usage":{"input_tokens":10,"cache_read_input_tokens":%d,"cache_creation_input_tokens":0}}}\n' "$1"; }
usage_line 250000 > "$transcript"
out=$(run_hook "$chinese" false "$transcript" s8)
grep -q '"systemMessage"' <<<"$out" && grep -q 'r-handoff' <<<"$out" && ! grep -q 'decision' <<<"$out"
check "handoff nudge at 250k" $?
out=$(run_hook "$chinese" false "$transcript" s8)
[ -z "$out" ]; check "no repeat nudge in same band" $?
usage_line 320000 >> "$transcript"
out=$(run_hook "$chinese" false "$transcript" s8)
grep -q '"systemMessage"' <<<"$out"; check "nudge again in next band" $?

# 7. Short context stays silent
usage_line 90000 > "$transcript"
out=$(run_hook "$chinese" false "$transcript" s9)
[ -z "$out" ]; check "no nudge under 200k" $?

[ "$FAILS" -eq 0 ] && echo "all passed" || { echo "$FAILS failed"; exit 1; }
