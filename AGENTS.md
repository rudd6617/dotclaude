## Project Context

dotclaude：個人 agent 家規的唯一源頭。`global/` 是全域載入的家規（`~/.claude/CLAUDE.md`、`~/.codex/AGENTS.md` 都連到這裡），`.claude/skills/` 連到 `~/.claude/skills/`，`.claude/hooks/` 由 `~/.claude/settings.json` 直接執行。`sync.sh` 建立這些全域連結，並把專案整理成只留專案自己的檔。維護規則見 `docs/MAINTENANCE.md`；長期知識見 `.claude/Wiki.md`。
