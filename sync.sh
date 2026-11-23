#!/usr/bin/env bash
# Install this dotclaude template machine-wide, and tidy projects to hold only
# their own files.
#
# Global (every run): ~/.claude/CLAUDE.md and ~/.codex/AGENTS.md link to
# global/; template skills link into ~/.claude/skills; the hooks are registered
# in ~/.claude/settings.json and run straight from this repo. Nothing rule-like
# is copied into projects, so editing dotclaude takes effect everywhere at once.
#
# Project: keeps only what is the project's own. AGENTS.md is cut down to its
# ## Project Context section, .claude/CLAUDE.md becomes `@../AGENTS.md`, and old
# template copies (hooks, settings.json, docs, skills) are removed. Wiki.md,
# Learning.md, Verify.md and docs/adr/README.md are seeded only if missing.
# Memory.md and settings.local.json are never touched.
#
# Usage:
#   /path/to/dotclaude/sync.sh --global [-n|--dry-run]
#   /path/to/dotclaude/sync.sh <target-project-dir> [-n|--dry-run]
#   /path/to/dotclaude/sync.sh --all <parent-dir>... [-n|--dry-run]
#
# --all handles every project directly under the given parent dirs whose
# .claude/CLAUDE.md starts with `@../AGENTS.md`. It skips a project that is not
# a clean git repo, so every change can be reviewed and reverted, and asks once
# before writing.

set -euo pipefail

SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

DRY=0; ALL=0; GLOBAL_ONLY=0; DIRS=()
for a in "$@"; do
  case "$a" in
    -n|--dry-run) DRY=1 ;;
    --all) ALL=1 ;;
    --global) GLOBAL_ONLY=1 ;;
    -*) echo "unknown flag: $a" >&2; exit 2 ;;
    *)  DIRS+=("$a") ;;
  esac
done
usage() { echo "usage: sync.sh --global [-n|--dry-run]
       sync.sh <target-project-dir> [-n|--dry-run]
       sync.sh --all <parent-dir>... [-n|--dry-run]" >&2; exit 2; }

run() { if [ "$DRY" -eq 1 ]; then echo "  [dry-run] $*"; else "$@"; fi; }
write() { # path, content
  if [ "$DRY" -eq 1 ]; then echo "  [dry-run] write $1"; else printf '%s' "$2" > "$1"; fi
}

PROJECT_CLAUDE='@../AGENTS.md'
HOOK_NAMES=(inject-memory.sh check-reply.py)
LEGACY_DOCS=(docs/ADR-FORMAT.md docs/MAINTENANCE.md)
SEED=(.claude/Wiki.md .claude/Learning.md .claude/Verify.md docs/adr/README.md)
CONTEXT_HEAD='## Project Context'
CONTEXT_PLACEHOLDER="$CONTEXT_HEAD

（請填：這個專案是什麼、給誰用、技術棧一兩句。長期知識見 \`.claude/Wiki.md\`。）
"

is_template_project() { head -n1 "$1/.claude/CLAUDE.md" 2>/dev/null | grep -qxF "$PROJECT_CLAUDE"; }

if [ "$ALL" -eq 1 ]; then
  [ "${#DIRS[@]}" -ge 1 ] || usage
  targets=()
  for parent in "${DIRS[@]}"; do
    for claude in "$parent"/*/.claude/CLAUDE.md; do
      [ -e "$claude" ] || continue
      dir="$(cd "$(dirname "$claude")/.." && pwd)"
      [ "$dir" != "$SRC" ] || continue
      is_template_project "$dir" || continue
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

link() { # target, link-path
  if [ -e "$2" ] && [ ! -L "$2" ]; then echo "  skip   $2 (a real file; left alone)"; return; fi
  [ "$(readlink "$2" 2>/dev/null)" = "$1" ] && { echo "  ok     $2"; return; }
  run mkdir -p "$(dirname "$2")"
  run ln -sfn "$1" "$2"
  echo "  link   $2 -> $1"
}

register_hooks() {
  local settings="$HOME/.claude/settings.json"
  if [ "$DRY" -eq 1 ]; then echo "  [dry-run] register hooks in $settings"; return; fi
  mkdir -p "$(dirname "$settings")"
  python3 - "$settings" "$SRC/.claude/hooks" <<'PY'
import json, os, sys
path, hooks_dir = sys.argv[1], sys.argv[2]
data = json.load(open(path)) if os.path.exists(path) else {}
wanted = {
    "SessionStart": f"bash '{hooks_dir}/inject-memory.sh'",
    "Stop": f"python3 '{hooks_dir}/check-reply.py'",
}
changed = False
for event, command in wanted.items():
    groups = data.setdefault("hooks", {}).setdefault(event, [])
    name = os.path.basename(command.split("'")[1])
    present = [h for g in groups for h in g.get("hooks", []) if name in h.get("command", "")]
    if any(h["command"] == command for h in present):
        print(f"  ok     {event} {name}")
        continue
    for g in groups:
        g["hooks"] = [h for h in g.get("hooks", []) if name not in h.get("command", "")]
    groups[:] = [g for g in groups if g["hooks"]]
    groups.append({"matcher": "", "hooks": [{"type": "command", "command": command, "timeout": 10}]})
    changed = True
    print(f"  hook   {event} {name}")
if changed:
    tmp = path + ".tmp"
    with open(tmp, "w") as f:
        json.dump(data, f, indent=2, ensure_ascii=False)
        f.write("\n")
    os.replace(tmp, path)
PY
}

template_skills() { for d in "$SRC"/.claude/skills/*/; do basename "$d"; done; }
retired_skills() {
  git -C "$SRC" log --diff-filter=D --name-only --format= -- '.claude/skills/r-*/SKILL.md' | awk -F/ '{print $3}'
}

install_global() {
  echo "global:"
  link "$SRC/global/CLAUDE.md" "$HOME/.claude/CLAUDE.md"
  link "$SRC/global/AGENTS.md" "$HOME/.codex/AGENTS.md"
  register_hooks
  echo "skills (linked into ~/.claude/skills):"
  local skills_dir="$HOME/.claude/skills" name l
  run mkdir -p "$skills_dir"
  for name in $(template_skills); do
    l="$skills_dir/$name"
    if [ -e "$l" ] && [ ! -L "$l" ]; then echo "  skip   $l (not a link; left alone)"; continue; fi
    run ln -sfn "$SRC/.claude/skills/$name" "$l"
    echo "  link   $name"
  done
  for l in "$skills_dir"/*; do
    [ -L "$l" ] && [ ! -e "$l" ] || continue
    case "$(readlink "$l")" in "$SRC/.claude/skills/"*) ;; *) continue ;; esac
    run rm "$l"
    echo "  unlink $(basename "$l") (dropped from template)"
  done
}

# A project settings.json is the template's when its only content is hooks that
# run the template's hook scripts; anything else is the project's own.
template_settings() {
  python3 - "$1" "${HOOK_NAMES[@]}" <<'PY'
import json, sys
data = json.load(open(sys.argv[1]))
names = sys.argv[2:]
cmds = [h.get("command", "") for gs in data.get("hooks", {}).values() for g in gs for h in g.get("hooks", [])]
ok = set(data) <= {"hooks"} and all(any(n in c for n in names) for c in cmds)
sys.exit(0 if ok else 1)
PY
}

sync_project() {
  local dst="$1" rel f own context
  echo "project: $dst"

  if [ -f "$dst/AGENTS.md" ] && grep -q '^# 家規' "$dst/AGENTS.md"; then
    context="$(awk -v h="$CONTEXT_HEAD" '$0==h{on=1} on' "$dst/AGENTS.md")"
    if [ -z "$context" ] || grep -q '請依專案填寫' <<<"$context"; then context="$CONTEXT_PLACEHOLDER"; else context="$context
"; fi
    write "$dst/AGENTS.md" "$context"
    echo "  trim   AGENTS.md (kept $CONTEXT_HEAD only)"
  elif [ ! -e "$dst/AGENTS.md" ]; then
    write "$dst/AGENTS.md" "$CONTEXT_PLACEHOLDER"
    echo "  seed   AGENTS.md"
  else
    echo "  keep   AGENTS.md (the project's own)"
  fi

  if [ ! -e "$dst/.claude/CLAUDE.md" ] || grep -q '^# Claude Code 專屬設定' "$dst/.claude/CLAUDE.md"; then
    run mkdir -p "$dst/.claude"
    write "$dst/.claude/CLAUDE.md" "$PROJECT_CLAUDE
"
    echo "  write  .claude/CLAUDE.md ($PROJECT_CLAUDE)"
  else
    echo "  keep   .claude/CLAUDE.md (the project's own)"
  fi

  if [ -d "$dst/.claude/hooks" ]; then
    own=""
    for f in "$dst/.claude/hooks"/*; do
      [ -e "$f" ] || continue
      case " ${HOOK_NAMES[*]} " in *" $(basename "$f") "*) ;; *) own="$own $(basename "$f")" ;; esac
    done
    if [ -z "$own" ]; then run rm -rf "$dst/.claude/hooks"; echo "  remove .claude/hooks (template copy)"
    else echo "  keep   .claude/hooks (has the project's own:$own)"; fi
  fi
  if [ -f "$dst/.claude/settings.json" ]; then
    if template_settings "$dst/.claude/settings.json"; then run rm "$dst/.claude/settings.json"; echo "  remove .claude/settings.json (template copy)"
    else echo "  keep   .claude/settings.json (has the project's own settings; drop its template hooks by hand)"; fi
  fi
  for rel in "${LEGACY_DOCS[@]}"; do
    [ -e "$dst/$rel" ] || continue
    run rm "$dst/$rel"
    echo "  remove $rel (read from dotclaude now)"
  done

  local skills_dst="$dst/.claude/skills" manifest="$dst/.claude/skills/.template-skills" name
  for name in $( { template_skills; retired_skills; cat "$manifest" 2>/dev/null; } | sort -u); do
    [ -e "$skills_dst/$name" ] || continue
    run rm -rf "$skills_dst/$name"
    echo "  remove skill $name (template copy)"
  done
  if [ -f "$manifest" ]; then run rm "$manifest"; fi

  for rel in "${SEED[@]}"; do
    [ -e "$SRC/$rel" ] || continue
    [ -e "$dst/$rel" ] && continue
    run mkdir -p "$(dirname "$dst/$rel")"
    run cp -a "$SRC/$rel" "$dst/$rel"
    echo "  seed   $rel"
  done
  echo "  untouched: .claude/Memory.md, .claude/settings.local.json"
}

[ "$DRY" -eq 1 ] && echo "(dry-run)"
if [ "$GLOBAL_ONLY" -eq 1 ]; then
  [ "${#DIRS[@]}" -eq 0 ] || usage
  install_global
  echo "done."
  exit 0
fi

[ "${#DIRS[@]}" -eq 1 ] || usage
DST="$(cd "${DIRS[0]}" && pwd)"
[ "$SRC" != "$DST" ] || { echo "refusing to sync onto the template itself" >&2; exit 1; }
install_global
sync_project "$DST"
echo "done."
