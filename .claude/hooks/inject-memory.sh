#!/bin/bash
# SessionStart hook: inject project memory (Learning + Memory) into Claude's context.
# Strips HTML comment blocks (template instructions) and skips a file that has no
# real content (only headings / （尚無…） placeholders).
# Also nudges a convergence pass when Learning.md grows past the threshold.
CLAUDE_DIR="$CLAUDE_PROJECT_DIR/.claude"
LEARNING="$CLAUDE_DIR/Learning.md"
MEMORY="$CLAUDE_DIR/Memory.md"

# Convergence threshold: entries (## headings), total lines, or injected characters.
# Claude Code replaces context over 10,000 chars with a file path and a 2,000-char
# preview, so the nudge goes first to survive that cut.
MAX_ENTRIES=40
MAX_LINES=400
MAX_CHARS=9000

strip_comments() {
  # Single-line comments first: a same-line <!-- --> would open a sed range
  # that never closes and swallow the rest of the file.
  sed -e '/<!--.*-->/d' -e '/<!--/,/-->/d' "$1"
}

# Meaningful = any line that is not blank, not a heading, not a （尚無…） placeholder.
has_content() {
  grep -qvE '^[[:space:]]*$|^#|^（尚無.*）$' <<<"$1"
}

CONTENT=""
NUDGE=""

if [ -f "$LEARNING" ]; then
  stripped=$(strip_comments "$LEARNING")
  if has_content "$stripped"; then
    CONTENT="$CONTENT=== Learning (past mistakes & lessons) ===
$stripped
"
    entries=$(grep -c '^## ' "$LEARNING")
    lines=$(wc -l < "$LEARNING")
    if [ "$entries" -ge "$MAX_ENTRIES" ] || [ "$lines" -ge "$MAX_LINES" ]; then
      NUDGE="[learning] Learning.md 已 ${entries} 條 / ${lines} 行，超過收斂門檻（${MAX_ENTRIES} 條 / ${MAX_LINES} 行）。建議收斂：合併重複、把反覆出現的教訓升級成 AGENTS.md 原則、刪過期條目（判準見 docs/MAINTENANCE.md §4）。
"
    fi
  fi
fi

if [ -f "$MEMORY" ]; then
  stripped=$(strip_comments "$MEMORY")
  if has_content "$stripped"; then
    CONTENT="$CONTENT
=== Memory (where to pick up) ===
$stripped
"
  fi
fi

[ -z "$CONTENT" ] && exit 0

chars=$(printf '%s' "$CONTENT" | python3 -c 'import sys; print(len(sys.stdin.read()))')
if [ -z "$NUDGE" ] && [ "$chars" -ge "$MAX_CHARS" ]; then
  NUDGE="[learning] 注入內容已 ${chars} 字元，超過 ${MAX_CHARS}；超過 10,000 會被截成 2,000 字預覽。建議收斂 Learning.md、精簡 Memory.md（判準見 docs/MAINTENANCE.md §4）。
"
fi
CONTENT="$NUDGE$CONTENT"

# SessionStart: additionalContext reaches the model; systemMessage only reaches the user.
printf '%s' "$CONTENT" | python3 -c 'import sys,json; print(json.dumps({"hookSpecificOutput": {"hookEventName": "SessionStart", "additionalContext": sys.stdin.read()}}))'
