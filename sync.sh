#!/usr/bin/env bash
# Sync this dotclaude template into a target project.
#
# Overwrites template-managed files (AGENTS.md, CLAUDE.md, hooks) and the
# template's own skills; project-only skills are left alone.
# Seeds project-specific files only if missing — never clobbers the knowledge
# you fill in per project (Wiki.md, Learning.md). Leaves volatile/local files
# untouched (Memory.md, settings.local.json).
#
# Usage:
#   /path/to/dotclaude/sync.sh <target-project-dir> [-n|--dry-run]
#
# Re-run any time the template updates to pull the latest in.

set -euo pipefail

SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

DRY=0; DST=""
for a in "$@"; do
  case "$a" in
    -n|--dry-run) DRY=1 ;;
    -*) echo "unknown flag: $a" >&2; exit 2 ;;
    *)  DST="$a" ;;
  esac
done
[ -n "$DST" ] || { echo "usage: sync.sh <target-project-dir> [-n|--dry-run]" >&2; exit 2; }
DST="$(cd "$DST" && pwd)"
[ "$SRC" != "$DST" ] || { echo "refusing to sync onto the template itself" >&2; exit 1; }

# Template-managed → overwrite (single source of truth).
MANAGED=(
  "AGENTS.md"                  # 家規（工具無關規則源頭）；.claude/CLAUDE.md 靠 @../AGENTS.md 吸入
  ".claude/CLAUDE.md"
  ".claude/hooks"
  ".claude/settings.json"      # project-specific overrides go in settings.local.json
  "docs/ADR-FORMAT.md"
  "docs/MAINTENANCE.md"
  "docs/adr/README.md"
)
# statusline.sh intentionally NOT synced: it lives in this repo only and the
# global ~/.claude/settings.json statusLine points here (see README §Status Line).

# Seed only if absent → never overwrite filled-in project knowledge.
SEED=(
  ".claude/Wiki.md"
  ".claude/Learning.md"
)

run() { [ "$DRY" -eq 1 ] && echo "  [dry-run] $*" || eval "$*"; }

[ "$DRY" -eq 1 ] && tag=" (dry-run)" || tag=""
echo "sync: $SRC  ->  $DST$tag"
echo "overwrite (template):"
for rel in "${MANAGED[@]}"; do
  [ -e "$SRC/$rel" ] || { echo "  skip   $rel (missing in template)"; continue; }
  run "mkdir -p '$DST/$(dirname "$rel")'"
  if [ -d "$SRC/$rel" ]; then
    run "rm -rf '$DST/$rel'"          # mirror deletions (e.g. a removed skill)
    run "cp -a '$SRC/$rel' '$DST/$rel'"
  else
    run "cp -a '$SRC/$rel' '$DST/$rel'"
  fi
  echo "  ok     $rel"
done

# Skills are synced per skill, not as a whole dir, so project-only skills
# (e.g. a project's own doc skill) survive. A manifest records which skills the
# template owns, so a skill removed from the template is removed here too.
echo "skills (template-owned only):"
SKILLS_DST="$DST/.claude/skills"
MANIFEST="$SKILLS_DST/.template-skills"
run "mkdir -p '$SKILLS_DST'"
if [ -f "$MANIFEST" ]; then
  while IFS= read -r old; do
    [ -n "$old" ] || continue
    [ -d "$SRC/.claude/skills/$old" ] && continue
    run "rm -rf '$SKILLS_DST/$old'"
    echo "  remove $old (dropped from template)"
  done < "$MANIFEST"
fi
names=()
for dir in "$SRC"/.claude/skills/*/; do
  name="$(basename "$dir")"
  names+=("$name")
  run "rm -rf '$SKILLS_DST/$name'"
  run "cp -a '$SRC/.claude/skills/$name' '$SKILLS_DST/$name'"
  echo "  ok     $name"
done
run "printf '%s\\n' ${names[*]} > '$MANIFEST'"

echo "seed (only if missing):"
for rel in "${SEED[@]}"; do
  [ -e "$SRC/$rel" ] || { echo "  skip   $rel (missing in template)"; continue; }
  if [ -e "$DST/$rel" ]; then
    echo "  keep   $rel (already exists)"
  else
    run "mkdir -p '$DST/$(dirname "$rel")'"
    run "cp -a '$SRC/$rel' '$DST/$rel'"
    echo "  seed   $rel"
  fi
done

echo "untouched: .claude/Memory.md, .claude/settings.local.json (volatile/local)"
echo "done."
