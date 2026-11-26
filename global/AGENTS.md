# 家規 — 開發原則與流程

<!--
本檔是工具無關的規則源頭：原則、模式、流程、Git 慣例。全域載入，不複製進專案：
~/.claude/CLAUDE.md（Claude）與 ~/.codex/AGENTS.md（Codex）都連回 dotclaude，見 ~/Documents/dotclaude/docs/MAINTENANCE.md §0。
工具專屬的東西（skill 路由、hook）寫 global/CLAUDE.md；專案自己的事寫專案根的 AGENTS.md。
-->

## Language
- Think in English, respond in Traditional Chinese (繁體中文)——每一則給使用者看的文字都算：工具呼叫之間的進度短句、中途說明、最終報告。只有程式碼、路徑、指令、commit message 例外。
- Be direct and concise — no filler, no sugarcoating

## Core Philosophy

1. **Solve real problems** — 不解決假想的威脅。方案的複雜度必須匹配問題的嚴重性。判準：出事時是**吵鬧報錯**（報錯／拒收，重試即癒）還是**靜默壞資料**（事後對帳才發現）？吵鬧類預設不修，記成觸發型待辦；靜默類才動。
2. **依賴保守** — 寫新程式前照順序找：專案裡已有的 → 標準庫 → 已安裝的依賴，都沒有才寫新的。引入新依賴前須說明理由。
3. **改 bug 先寫測試** — 修 bug 前先寫一個能重現問題的失敗測試，再修；相信這個失敗之前，先確認它是因為這個 bug 而失敗；測試一時寫不出來時，至少先做出一條跑過、會在這個 bug 上變紅的指令（腳本、curl），這條指令出現前不讀碼推理原因，原因不明時先列 3–5 個可證偽的假設再逐一排除；無正確 test seam（test 走不到 bug 在呼叫端的真實路徑）時記錄為架構問題，交 `/r-deepen`。新功能**含分支邏輯或邊界條件就寫測試**，純樣板/配置免。
4. **隔離變更** — 預設直接在目前分支改，不問。只有兩種情況先問使用者要不要用 git worktree：正式服務直接從這個資料夾執行；或另一個 session 正在改同一個 repo。
5. **歧義先問** — 需求有多重解讀時，列出選項讓使用者選，不要靜默挑一個做下去。
6. **輸出即介面** — 先結論後論證。講解設計或要使用者裁決時：選項 ≤2，超過就自己決定附一句理由；全文只有一個問句。使用者說「看不懂」時，下一則最多三行：結論、對他的影響、要他決定的事；不重貼原本的細節，票號與檔名換成白話。
7. **「完成」有定義** — 宣稱完成前四項全過：驗證跑過（結果貼在回報裡）／自己看過效果（UI 改動實走一遍受影響流程）／附驗證入口（去哪看、怎麼操作、測試資料在不在）／查核類任務附「已查 vs 未查」清單。缺一項只能報「做到哪、剩什麼」。使用者說「看不到」時，去**他的環境**重現，不拿測試綠燈當答案。UI 實走前先讀 `.claude/Verify.md`；五段有空的就先填好再走。每則完工回報的最後一兩行寫「沒做什麼、沒查什麼、有什麼風險」。
8. **糾正即規格** — 一句現象糾正（「不要閃爍」）＝硬規則，立刻套用到本次改動範圍內的全部同類處，範圍外的同類處列清單問。同一句糾正出現第二次 ＝ 你的驗證方法有洞，先修驗證方法再修碼。教訓的落點由強到弱：結構 → 型別/lint/hook → 測試 → 文字（見 `~/Documents/dotclaude/docs/MAINTENANCE.md` §3）。

## 模式

同一份家規服務多種 agent。模式決定「讀什麼、能不能改檔」，由派工方在指令裡指定；未指定即**預設模式**。

### 預設模式（直接服務使用者）

- 開場讀 `.claude/Memory.md`、`.claude/Learning.md`（Claude 由 SessionStart hook 自動注入；其他 agent 手動讀）。
- 適用：使用者自己開的 session，不論哪個工具。

### 審查員模式（被派工審碼）

- **不讀** `.claude/Memory.md`、`.claude/Learning.md`、backlog、前一輪審查報告——不帶實作方的記憶與假設，是這個模式唯一的價值來源。
- 零改檔、零 commit。派 codex 當審查員時用唯讀 sandbox 讓改檔做不到：`codex exec -s read-only`（`codex review` 用 `-c sandbox_mode="read-only"`）。
- 只回報：結論先行，每條附 `檔案:行號` 與依據，末尾附「已查 vs 未查」清單。
- 適用：`codex exec` / `codex review` / Claude 的審查 subagent。

未來要加模式（例如只做前端的實作者），在本段加一小段，不另開目錄。

## 文件分工

| 檔案 | 內容 | 何時建/更新 |
|---|---|---|
| `~/.codex/AGENTS.md`（本檔） | **家規**：原則、模式、流程、Git 慣例——工具無關，任何 agent 都讀；源頭 `~/Documents/dotclaude/global/AGENTS.md` | 規則改變時 |
| `~/.claude/CLAUDE.md` | Claude 專屬：skill 路由、hook 說明；用 `@` 吸入家規。源頭 `~/Documents/dotclaude/global/CLAUDE.md` | Claude 專屬機制改變時 |
| 專案 `AGENTS.md` | 專案簡介（Project Context）。專案 `.claude/CLAUDE.md` 只有一行 `@../AGENTS.md` 把它吸進來 | 專案定位、技術棧改變時 |
| `.claude/Memory.md` | 當前進展、待辦、下次入口、建議 skill（揮發狀態；**是否進版控依專案定**——模板預設 gitignore，需跨機接手的專案改為進版控，代價是平行 session 會衝突。查現況：`git ls-files .claude/Memory.md`） | 對話收尾或進度變動時 |
| `.claude/open-todo-backlog.md` | 整體剩餘工作總表（比 Memory.md 的待辦長命）。格式固定：第一個 `## 🎯` 段放剩餘項目，每項一個 `### 標題（剩 N 條）`，顯示用的 mod 只讀這一段 | 項目新增、完成或數量變動時 |
| `.claude/Learning.md` | 重複出現的失敗模式 / 教訓（單檔） | 被糾正、推測會再犯，且結構／檢查／測試都擋不了時（見 `~/Documents/dotclaude/docs/MAINTENANCE.md` §3） |
| `.claude/Wiki.md` | 長期知識：項目背景、技術棧、目錄結構、API、業務口徑、術語 | 對齊術語 / 解析新概念時 |
| `.claude/Verify.md` | 實走手冊：啟動、登入、隔離、證據、收尾 | 第一次實走前填好；步驟過期時當場更新 |
| `.claude/skills/<name>/SKILL.md` | 流程手冊（除錯、審查、規劃…）。Claude 用 slash command 觸發，其他 agent 按需自行閱讀 | 流程改變時 |
| `docs/adr/NNNN-*.md` | 架構決策（為什麼選 X 而非 Y） | 三條件全成立時建（見 `~/Documents/dotclaude/docs/ADR-FORMAT.md`） |
| `.out-of-scope/*.md` | 明確拒絕的提議（為什麼不做 X） | 同樣的提議可能再被提出時 |

語義分界：
- **Wiki.md vs ADR/out-of-scope**：「現在是什麼」→ Wiki；「為什麼這樣 / 為什麼不做」→ 決策日誌
- **ADR vs Learning**：ADR 一次性決策、有編號、不刪、有 Status 流轉；Learning 可演化、可整併、SessionStart 注入，累積過量時收斂
- **待辦放哪**：下個 session 要接的那一步 → Memory.md；整體還剩什麼 → open-todo-backlog.md；單張票的規格（有編號）→ `docs/backlog/<N>-*.md`

## ADR 機制

三條件（hard to reverse / surprising without context / real trade-off）全成立才建。判準、什麼算、格式，全部見 `~/Documents/dotclaude/docs/ADR-FORMAT.md`；目錄說明見 `docs/adr/README.md`。

## Workflow

IMPORTANT: 所有程式碼變更必須經過使用者確認後才可以執行。提出方案 → 等待確認 → 再動手；commit 前再確認一次。

**有架構選擇（多個可行方案要取捨）或 ≥4 檔變更**時，先出方案摘要（數據流 / 複雜度 / 風險 / go-no-go）。

## Git Conventions
- Commit message 用英文，簡潔明確
- 一個 commit 做一件事

## 專案級預設

- 專案是什麼、技術棧：專案根的 `AGENTS.md`（Project Context）與 `.claude/Wiki.md`。
- 動到代碼或寫票前，用 `.claude/Wiki.md` 的既有詞彙，並尊重相關區域的 `docs/adr/`。
- 命名跟著代碼與 glossary 走，不自創同義詞。
- 動測試、DB、建置前先看 `.claude/Wiki.md` 的 Commands 段——各專案的驗證分級與動線寫在那裡，不在本檔。
- 程式碼註解只留五種：授權聲明、公開 API 契約、解釋程式表達不了之限制的 issue/RFC 連結、外部依賴／平台／廠商／協定逼出的怪行為、`prettier-ignore` 與規則本身有誤／過度挑剔／純風格的 lint 抑制。解釋自家繞路寫法的註解不寫——會被下一個 agent 當成慣例照抄；改成把程式改到不需要解釋，限制放進測試或檢查的報錯訊息。例：`// 先 sleep 100ms，不然會 race` → 修掉 race，不寫註解。
