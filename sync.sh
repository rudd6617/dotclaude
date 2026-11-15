#!/usr/bin/env bash
# Sync this dotclaude template into a target project.
#
# Overwrites template-managed files (AGENTS.md but its Project Context section,
# CLAUDE.md, hooks). Template skills are linked into ~/.claude/skills instead of
# copied, and any project copies of them are removed; project-only skills stay.
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

# AGENTS.md is the template's except its last section, ## Project Context,
# which describes the project. Remember the project's own text before the
# overwrite and put it back after. Relies on that section staying last.
CONTEXT_HEAD='## Project Context'
project_context() { awk -v h="$CONTEXT_HEAD" '$0==h{on=1} on' "$1"; }
before_context() { awk -v h="$CONTEXT_HEAD" '$0==h{exit} {print}' "$1"; }
OLD_CONTEXT=""
[ -f "$DST/AGENTS.md" ] && OLD_CONTEXT="$(project_context "$DST/AGENTS.md")"
TEMPLATE_CONTEXT="$(project_context "$SRC/AGENTS.md")"

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
if [ -n "$OLD_CONTEXT" ] && [ "$OLD_CONTEXT" != "$TEMPLATE_CONTEXT" ]; then
  if [ "$DRY" -eq 0 ]; then
    { before_context "$SRC/AGENTS.md"; printf '%s\n' "$OLD_CONTEXT"; } > "$DST/AGENTS.md"
  fi
  echo "  keep   AGENTS.md $CONTEXT_HEAD (the project's own)"
fi

# Skills are not copied. Each template skill is linked into ~/.claude/skills,
# so every project sees the latest one without a sync. A project keeps only its
# own skills: copies of template skills, current or retired, are removed from it.
template_skills() { for d in "$SRC"/.claude/skills/*/; do basename "$d"; done; }
retired_skills() {
  git -C "$SRC" log --diff-filter=D --name-only --format= -- '.claude/skills/r-*/SKILL.md' | awk -F/ '{print $3}'
}

echo "skills (linked into ~/.claude/skills):"
GLOBAL="$HOME/.claude/skills"
run "mkdir -p '$GLOBAL'"
for name in $(template_skills); do
  link="$GLOBAL/$name"
  if [ -e "$link" ] && [ ! -L "$link" ]; then echo "  skip   $link (not a link; left alone)"; continue; fi
  run "ln -sfn '$SRC/.claude/skills/$name' '$link'"
  echo "  link   $name"
done
for link in "$GLOBAL"/*; do
  [ -L "$link" ] && [ ! -e "$link" ] || continue
  case "$(readlink "$link")" in "$SRC/.claude/skills/"*) ;; *) continue ;; esac
  run "rm '$link'"
  echo "  unlink $(basename "$link") (dropped from template)"
done

echo "skills (template copies removed from project):"
SKILLS_DST="$DST/.claude/skills"
MANIFEST="$SKILLS_DST/.template-skills"
for name in $( { template_skills; retired_skills; cat "$MANIFEST" 2>/dev/null; } | sort -u); do
  [ -e "$SKILLS_DST/$name" ] || continue
  run "rm -rf '$SKILLS_DST/$name'"
  echo "  remove $name"
done
if [ -f "$MANIFEST" ]; then run "rm '$MANIFEST'"; fi

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
