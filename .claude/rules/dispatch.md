# 模型調度守則（dispatch.md）

<!--
讀者：未來 session 的主模型（Sonnet 等級為預設假設）。
何時讀：要派 subagent 前、要開始大量讀檔前、subagent 失敗要重試前。
維護規則見 rules/maintenance.md。
-->

## 0. 可用資源盤點（2026-07-04 寫定；開場以 system prompt 實況為準，不要憑本檔假設）

**模型**（Agent 工具 `model` 參數）：

| 參數值 | 型號 | 定位 |
|---|---|---|
| `haiku` | Haiku 4.5 | 機械批次：已驗證 pattern 的套用、格式轉換、grep 結果彙整 |
| `sonnet` | Sonnet 5 | 預設主力：搜尋、實作、研究、一般審查 |
| `opus` | Opus 4.8 | 難題：架構取捨、對抗審查、第二意見、卡關 debug |

`fable`（Fable 5）只在特殊 session 存在，不要假設可用。

**subagent_type**（以 system prompt 的 available agents 清單為準）：
- `Explore` — 唯讀搜索，適合「掃 repo 找所有 X」「這功能在哪」
- `general-purpose` — 讀寫皆可，適合實作、研究、批次改檔
- `Plan` — 產出實作計畫（唯讀）
- `claude-code-guide` — Claude Code / API 本身的問題

**effort**：Agent 工具**沒有** effort 參數。effort 來自 session 設定（`~/.claude/settings.json` 的 `effortLevel`）或自訂 agent 定義檔（`.claude/agents/*.md` frontmatter）。需要對特定子任務固定 model+effort 時，建自訂 agent 定義，不要在 prompt 裡喊「請用高 effort」（無效）。

## 1. 指揮官不下場

主對話的 context 是整個 session 最貴的資源。塞滿檔案內容 = 後半段失焦 + 變貴。

**必派 subagent**（符合任一條）：
- 為了回答一個問題預計要讀 >3 個檔案 → `Explore`
- 「掃整個 repo / 找出所有 X / 這個 pattern 出現在哪」 → `Explore`
- 查網頁、讀外部文件做研究 → `general-purpose`
- 機械性批次修改 ≥3 檔 → 先自己在 1 檔驗證 pattern，再派 `general-purpose`（或 `haiku`）套用其餘

**自己做**（不要為派而派）：
- 單一已知檔案的讀取或小修改
- 目標檔案已在 context 內
- 對話性回答、判斷題

判準：派工開銷（寫 prompt + 等待 + 整合回報）小於自做的 context 汙染，才派。

**主對話只進結論。** subagent 傳回的原始檔案內容不要複述進回覆。

## 2. 派工三件套

每個派工 prompt 必含三件，少一件就是不合格 prompt：

1. **目標與動機** — 做什麼＋為什麼要做（動機讓 agent 遇到意外時能自行取捨）
2. **驗收條件** — 可檢查的判準（「找到全部 call site」→「回報數量＋grep 指令讓我複核」）
3. **回報格式** — 明確欄位；規定長度上限

填空模板見 [rules/delegation-templates.md](delegation-templates.md)。

## 3. 顯式指定 model

每次 Agent 呼叫都寫明 `model`，不留給預設。選錯方向的成本不對稱：**該用 opus 卻用 haiku = 返工＋兩份 token；該用 haiku 卻用 opus = 只多花一點錢**。不確定就往上選。

## 4. 回報合約（寫進每個派工 prompt）

- 回報只含**結論與證據指標**（`檔案:行號`、數字、判斷），不得貼大段檔案內容
- 長產物（報告、diff、清單 >50 行）落檔到指定路徑，回報只傳路徑
- 回報第一句話 = 結果（完成/失敗/部分完成＋一句原因）
- 失敗時必須回：試了什麼、卡在哪、完整錯誤訊息原文——沒有這些就無法升級處理

## 5. 升降級路徑

| 情況 | 動作 |
|---|---|
| `haiku` 錯 1 次 | 直接升 `sonnet` 重派（同 prompt＋附上錯誤輸出） |
| `sonnet` 同一子任務連錯 2 次 | 升 `opus`，帶**完整失敗軌跡**：原 prompt、兩次的輸出、每次錯在哪 |
| `opus` 也解不掉 | 停下來問使用者，附軌跡摘要。不要第三次重試 |
| 難題已解出、剩機械套用 | 降回 `haiku`/`sonnet` 批次執行（把解出的 pattern 寫成具體步驟） |

**同一件事最多重試 2 輪。** 第 3 次嘗試前必須改變其中之一：模型、方法、或問題本身的拆法。原樣重跑第三次是被禁止的。

## 6. 驗證不自驗

做的人不驗自己的工作——包括你自己。

| 產出類型 | 驗法 |
|---|---|
| 檔案產出（文件、設定） | 派 fresh-context agent read-back：給它驗收條件與檔案路徑，讓它獨立核對。prompt 不可透露「這是我寫的、應該沒問題」 |
| 程式碼 | 跑測試或實跑觸發改動的路徑。「看起來對」不是驗證 |
| 高風險判斷（架構、不可逆操作、對外行為） | `opus` 第二意見；或多答案評審：3 個獨立 agent 各給答案 → 1 個評審比較選優 |

驗證 agent 回報「不通過」時，回到 §5 的升降級路徑處理，不要跟驗證者辯論。
