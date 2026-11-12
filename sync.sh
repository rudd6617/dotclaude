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
#   /path/to/dotclaude/sync.sh --all <parent-dir>... [-n|--dry-run]
#
# --all syncs every project directly under the given parent dirs that already
# carries the template (.claude/hooks/inject-memory.sh). It skips a project that
# is not a clean git repo, so an overwrite can always be reviewed and reverted,
# and asks once before writing.
#
# Re-run any time the template updates to pull the latest in.

set -euo pipefail

SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

DRY=0; ALL=0; DIRS=()
for a in "$@"; do
  case "$a" in
    -n|--dry-run) DRY=1 ;;
    --all) ALL=1 ;;
    -*) echo "unknown flag: $a" >&2; exit 2 ;;
    *)  DIRS+=("$a") ;;
  esac
done
usage() { echo "usage: sync.sh <target-project-dir> [-n|--dry-run]
       sync.sh --all <parent-dir>... [-n|--dry-run]" >&2; exit 2; }

if [ "$ALL" -eq 1 ]; then
  [ "${#DIRS[@]}" -ge 1 ] || usage
  targets=()
  for parent in "${DIRS[@]}"; do
    for hook in "$parent"/*/.claude/hooks/inject-memory.sh; do
      [ -e "$hook" ] || continue
      dir="$(cd "$(dirname "$hook")/../.." && pwd)"
      [ "$dir" != "$SRC" ] || continue
      if [ ! -d "$dir/.git" ]; then echo "skip   $dir (not a git repo)"; continue; fi
      if [ -n "$(git -C "$dir" status --porcelain)" ]; then echo "skip   $dir (uncommitted changes)"; continue; fi
      echo "sync   $dir"
      targets+=("$dir")
    done
  done
  [ "${#targets[@]}" -ge 1 ] || { echo "nothing to sync"; exit 0; }
  flag=()
  if [ "$DRY" -eq 1 ]; then
    flag=(--dry-run)
  else
    read -r -p "sync these ${#targets[@]} projects? [y/N] " reply
    [[ $reply == [yY]* ]] || { echo "aborted"; exit 1; }
  fi
  for dir in "${targets[@]}"; do "${BASH_SOURCE[0]}" "$dir" ${flag[@]+"${flag[@]}"}; done
  exit 0
fi

[ "${#DIRS[@]}" -eq 1 ] || usage
DST="${DIRS[0]}"
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

# Seed only if absent → never overwrite filled-in project knowledge.
SEED=(
  ".claude/Wiki.md"
  ".claude/Learning.md"
  ".claude/Verify.md"
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
