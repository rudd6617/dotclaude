---
name: r-audit
description: |
  Harness health check: find doc-vs-reality contradictions and claimed-but-dead automation,
  mine session logs for repeated user corrections, output findings with runnable verification
  commands, then (after per-item user approval) apply fixes under r-fable maintenance zones.
  Run periodically, after big institutional changes, or when the harness feels off.
disable-model-invocation: true
---

哈奈斯健檢，兩階段：**審計（只讀）→ 裁決 → 修復（逐條）**。
源頭一次性 prompt 見 `docs/fable-prompts/`；本 skill 是其可重複執行版。
「全面重建制度」不在本 skill 範圍——那是強模型專屬一次性動作，用 `docs/fable-prompts/prompt2.md`。

## Phase 1 — 審計（只讀，不動任何檔案）

1. **文件 vs 現實**：讀 CLAUDE.md、settings（專案＋`~/.claude/settings.json`）、hooks、skills，找兩類問題：
   - 互相矛盾：文件 A 說的規則和文件 B / 程式碼實際行為打架
   - 宣稱有但沒在跑：寫著「會自動 X」「跑 /某skill」，但 hook 不存在、路徑失效、或指向舊版檔案
2. **痛點挖掘**：從 `~/.claude/projects/` 的 session log 挖使用者最常打斷、重複糾正的模式，附出現次數。
   這步讀取量大，**派唯讀 subagent**（見 `skills/r-fable/dispatch.md`；唯讀派工免確認），主對話只收結論。
3. **發現格式**（硬性）：每個發現一行——
   `現況 → 建議修法 → 驗證指令（grep/test ＋ 期望值）`
   **寫不出驗證指令的發現直接丟掉**，不得以「建議留意」形式混入。
4. **輸出**：發現清單按嚴重度排序、給穩定編號，交使用者逐條裁決。**到此強制停下**，
   不因發現「看起來很好修」就順手修。

## Phase 2 — 修復（僅執行被核准的編號，一條一條做）

前置：只有使用者逐條（或成批點名編號）核准後才進入。範圍受
`skills/r-fable/maintenance.md` 分區管轄：綠區直接改、黃區用 §2 提案格式再確認一次、紅區必須使用者明確指示。

修復守則（濃縮自 prompt2 方法論）：
- **改前查備份**：dotclaude working tree 要乾淨（git 即備份，不建 .bak）；模板管理檔一律改 dotclaude 源頭再 sync，不改專案內副本。
- **新內容寫新檔**，CLAUDE.md 只放精簡路由；讀者是弱模型——規則要有觸發條件、判準、正反例，抽象口號不寫。
- **隨做隨寫**：每完成一條立刻落檔並用該條的驗證指令自查通過，才做下一條。session 隨時可能中斷，已落檔的才算數。
- **合併不堆疊**：新規則落檔前 grep 既有檔找同主題條目，能合併就合併，衝突就明寫哪條作廢。

## 收尾（Phase 2 有動檔才做）

1. 派 fresh-context subagent 對抗審查本次全部改動：規則互相打架、路徑/工具名錯誤、弱模型會誤讀的模糊語句。
2. read-back：逐檔確認落地、內容完整。
3. 三行總結：修了哪幾條（編號）、跳過哪幾條（原因）、下一步（要不要 sync 到專案）。

## 規則

- Phase 1 重跑是冪等的：上次已裁決「不修」的發現再次出現時，標註「曾否決（日期）」而非重新提出；否決紀錄查 `.out-of-scope/`。
- 痛點挖掘找不到 session log 或量太大讀不完：如實回報覆蓋範圍（讀了哪些專案、哪段時間），不得默默抽樣後宣稱全面。
- 對「宣稱有但沒在跑」的判定必須實測（跑 hook 指令、ls skill 目錄），不得只憑文件內文推斷。
