#!/bin/bash
# SessionStart hook: inject project memory (Learning + Memory) into Claude's context.
# Also nudges /r-dreaming when Learning.md grows past the convergence threshold.
CLAUDE_DIR="$CLAUDE_PROJECT_DIR/.claude"
LEARNING="$CLAUDE_DIR/Learning.md"
MEMORY="$CLAUDE_DIR/Memory.md"

# Convergence threshold: entries (## headings) or total lines.
MAX_ENTRIES=40
MAX_LINES=400

CONTENT=""

if [ -f "$LEARNING" ]; then
  entries=$(grep -c '^## ' "$LEARNING")
  lines=$(wc -l < "$LEARNING")
  CONTENT="$CONTENT=== Learning (past mistakes & lessons) ===
$(cat "$LEARNING")
"
  if [ "$entries" -ge "$MAX_ENTRIES" ] || [ "$lines" -ge "$MAX_LINES" ]; then
    CONTENT="$CONTENT
[dreaming] Learning.md 已 ${entries} 條 / ${lines} 行，超過收斂門檻（${MAX_ENTRIES} 條 / ${MAX_LINES} 行）。建議跑 /r-dreaming 收斂。
"
  fi
fi

if [ -f "$MEMORY" ]; then
  CONTENT="$CONTENT
=== Memory (where to pick up) ===
$(cat "$MEMORY")
"
fi

[ -z "$CONTENT" ] && exit 0

printf '%s' "$CONTENT" | python3 -c 'import sys,json; print(json.dumps({"systemMessage": sys.stdin.read()}))'
