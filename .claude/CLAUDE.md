# Code Review & Development Principles

## Language
- Think in English, respond in Traditional Chinese (繁體中文)
- Be direct and concise — no filler, no sugarcoating

## Core Philosophy

1. **Data structures first** — "Bad programmers worry about the code. Good programmers worry about data structures." 先搞清楚數據結構和流向，再寫邏輯。
2. **Eliminate special cases** — 如果需要 if/else 來處理邊界情況，優先考慮重新設計數據結構來消除分支，而不是堆條件判斷。
3. **Max 3 levels of indentation** — 超過就拆分。函數只做一件事。
4. **Never break existing behavior** — 任何改動都不能破壞現有功能。改之前先列出影響範圍。
5. **Solve real problems** — 不解決假想的威脅。方案的複雜度必須匹配問題的嚴重性。
6. **Early return, fail fast** — 錯誤應該立刻暴露，不靜默吞掉。不做防禦性編程，不在內部函數裡用 try-catch 包一切。
7. **命名表達意圖** — 命名要表達「做什麼」，不要表達「怎麼做」。
8. **依賴保守** — 能用標準庫解決的不引入第三方。引入新依賴前須說明理由。
9. **改 bug 先寫測試** — 修 bug 前先寫一個能重現問題的失敗測試，再修；無正確 test seam 時記錄為架構問題（見 `/r-diagnose` Phase 5）。新功能視複雜度決定。
10. **隔離變更** — 涉及多檔案架構改動時，用 worktree 隔離開發，避免污染主分支。
11. **只改該改的** — 不順手加 docstring、type hints、改 formatting。不重構沒壞的代碼。每一行改動都要能追溯到需求。發現無關的 dead code，提出但不動手。
12. **歧義先問** — 需求有多重解讀時，列出選項讓我選，不要靜默挑一個做下去。
13. **輸出即介面** — 回應結構服務於讀者決策：先結論後論證，能用表格/清單就不用長段落，技術判斷附依據不空談。

## 文件分工

| 檔案 | 內容 | 何時建/更新 |
|---|---|---|
| `.claude/CLAUDE.md` | 行為規則、原則、流程指引、穩定用戶偏好 | 規則改變時 |
| `.claude/Memory.md` | 當前進展、待辦、下次入口（揮發狀態，**gitignore**） | 對話收尾（`/r-handoff`）或進度變動時 |
| `.claude/Learning.md` | 重複出現的失敗模式 / 教訓（單檔） | 被糾正且推測會再犯時 |
| `.claude/Wiki.md` | 長期知識：項目背景、技術棧、目錄結構、API、業務口徑、術語 | 對齊術語 / 解析新概念時 |
| `docs/adr/NNNN-*.md` | 架構決策（為什麼選 X 而非 Y） | 三條件全成立時建（見 ADR 機制段） |
| `.out-of-scope/*.md` | 明確拒絕的提議（為什麼不做 X） | 同樣的提議可能再被提出時 |

語義分界：
- **CLAUDE.md vs Memory.md**：穩定偏好/規則 → CLAUDE.md；本次揮發進展 → Memory.md
- **Wiki.md vs ADR/out-of-scope**：「現在是什麼」→ Wiki；「為什麼這樣 / 為什麼不做」→ 決策日誌
- **ADR vs Learning**：ADR 一次性決策、有編號、不刪、有 Status 流轉；Learning 可演化、可整併、SessionStart 注入，累積過量由 `/r-dreaming` 收斂

## Skill 分工

| Skill | 時機 | 用法 |
|---|---|---|
| `/r-zoom-out` | 進入陌生模組前 | 建立全域視角（角色/邊界/數據流） |
| `/r-grill` | 需求模糊、動工前 | 逐個 branch 質問對齊 |
| `/r-grill-with-docs` | 需求模糊 + 涉及領域 / 想留決策紀錄 | grill + Wiki/ADR 維護 |
| `/r-plan` | 需求已對齊 + 涉及架構選擇 | 收斂為四段方案 |
| `/r-diagnose` | bug / 異常行為 / 測試失敗 / 效能退化 | 6 階段除錯 |
| `/r-review` | 完工後 / 讀不熟代碼 | 4 段品質評估 |
| `/r-deepen` | codebase 級架構回顧 | 找深化機會 |
| `/r-handoff` | 長對話收尾 / context 壓縮前 | 壓成交接、更新 `.claude/Memory.md` |
| `/r-teach` | 想學新概念 / 技能（非 dev 主流程） | 建教學工作區，依 storage strength + ZPD 教學 |

典型流程：
- 陌生代碼：`/r-zoom-out` → 後續
- 簡單需求：直接做
- 中等：`/r-grill` → 動工 → `/r-review`
- 複雜：`/r-grill-with-docs` → `/r-plan` → 動工 → `/r-review`
- 出 bug：`/r-diagnose`
- 中後期回顧：`/r-deepen`
- 對話收尾：`/r-handoff`

## ADR 機制

三條件**全成立**才建 ADR：
1. **Hard to reverse** — 改回去成本高
2. **Surprising without context** — 未來讀者會問「為什麼這樣做」
3. **Real trade-off** — 真有替代方案

格式見 `docs/ADR-FORMAT.md`，目錄說明見 `docs/adr/README.md`。

## Workflow

IMPORTANT: 所有程式碼變更必須經過我確認後才可以執行。提出方案 → 等待確認 → 再動手。

1. **理解需求** — 用一句話重述需求。模糊時呼叫 `/r-grill` 對齊
2. **調查** — 讀相關檔案、了解現有架構。複雜場景用 subagents
3. **規劃** — 涉及架構或多檔案變更時，用 `/r-plan` 產出四段摘要
4. **實作** — 寫最笨但最清晰的代碼。避免過度抽象和過度設計
5. **驗證** — 跑測試、typecheck、lint。確保零破壞性
6. **提交** — 等我確認後再 commit

## Git Conventions
- Commit message 用英文，簡潔明確
- 一個 commit 做一件事

## Project Context

通用模板。技術棧與長期知識見 `.claude/Wiki.md`（請依專案填寫）。

## Self-Improvement
`.claude/Learning.md` 與 `.claude/Memory.md` 會透過 SessionStart hook 自動注入，不需手動讀取。
被糾正時，將教訓寫入 `.claude/Learning.md`（一條一個 `##` 標題）。
條目累積過量時，hook 會提醒跑 `/r-dreaming` 收斂。
