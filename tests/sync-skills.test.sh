#!/bin/bash
# Tests for how sync.sh handles skills: linked into ~/.claude/skills, not copied.
# Run: bash tests/sync-skills.test.sh
SRC="$(cd "$(dirname "$0")/.." && pwd)"
SYNC="$SRC/sync.sh"
FAILS=0

check() { # name, condition-exit-code
  if [ "$2" -eq 0 ]; then echo "ok   $1"; else echo "FAIL $1"; FAILS=$((FAILS + 1)); fi
}

root=$(mktemp -d)
export HOME="$root/home"
GLOBAL="$HOME/.claude/skills"
proj="$root/proj"
mkdir -p "$proj/.claude/skills" "$GLOBAL" "$root/elsewhere/mine"
# Project copies: a current template skill, a retired one, the old manifest, and the project's own.
for s in r-grill r-zoom-out own-docs; do mkdir -p "$proj/.claude/skills/$s"; echo x > "$proj/.claude/skills/$s/SKILL.md"; done
printf 'r-grill\n' > "$proj/.claude/skills/.template-skills"
# Global dir: a stale link into the template, a link elsewhere, a real folder named like a template skill.
ln -s "$SRC/.claude/skills/r-gone" "$GLOBAL/r-gone"
ln -s "$root/elsewhere/mine" "$GLOBAL/mine"
mkdir "$GLOBAL/r-review"

# 1. Dry run writes nothing
"$SYNC" "$proj" --dry-run >/dev/null
[ -d "$proj/.claude/skills/r-grill" ] && [ ! -e "$GLOBAL/r-plan" ]; check "dry-run writes nothing" $?

out=$("$SYNC" "$proj")

# 2. Every template skill is linked globally (except where a real folder holds the name)
ok=0
for dir in "$SRC"/.claude/skills/*/; do
  name="$(basename "$dir")"
  [ "$name" = r-review ] && continue
  [ "$(readlink "$GLOBAL/$name")" = "$SRC/.claude/skills/$name" ] || ok=1
done
check "template skills linked into ~/.claude/skills" $ok

# 3. A real folder with a template name is left alone and reported
[ -d "$GLOBAL/r-review" ] && [ ! -L "$GLOBAL/r-review" ] && grep -q "skip .*r-review (not a link" <<<"$out"
check "real folder in ~/.claude/skills left alone" $?

# 4. Stale template links go; links elsewhere stay
[ ! -L "$GLOBAL/r-gone" ] && [ -L "$GLOBAL/mine" ]; check "stale template link removed, other links kept" $?

# 5. Project copies of current and retired template skills go; the project's own stays
[ ! -e "$proj/.claude/skills/r-grill" ] && [ ! -e "$proj/.claude/skills/r-zoom-out" ] \
  && [ -f "$proj/.claude/skills/own-docs/SKILL.md" ] && [ ! -e "$proj/.claude/skills/.template-skills" ]
check "template copies removed from project, own skill kept" $?

# 6. A second run changes nothing and does not fail
"$SYNC" "$proj" >/dev/null && [ -f "$proj/.claude/skills/own-docs/SKILL.md" ]; check "second run is a no-op" $?

rm -rf "$root"
[ "$FAILS" -eq 0 ] && echo "all passed" || { echo "$FAILS failed"; exit 1; }
