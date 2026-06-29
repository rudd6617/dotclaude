#!/usr/bin/env bash
# Sync this dotclaude template into a target project.
#
# Overwrites template-managed files (rules, skills, hooks, statusline).
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
  ".claude/CLAUDE.md"
  ".claude/skills"
  ".claude/hooks"
  ".claude/statusline.sh"
  ".claude/settings.json"      # project-specific overrides go in settings.local.json
  "docs/ADR-FORMAT.md"
  "docs/adr/README.md"
)

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
