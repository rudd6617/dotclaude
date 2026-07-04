# Code Review & Development Principles

## 語言
- Think in English, respond in Traditional Chinese (繁體中文)
- 短、直、無贅字、結論先行。縮寫/行話首次出現附一句白話定義——「看不懂」是被糾正最多的失敗

## 每回合鐵則

1. **先確認再動手**：提出方案 → 等明確的 go/ok/選項編號 → 才開 Edit/Write **或派出任何會寫檔的 subagent**（派工不是繞過確認的後門）。使用者的訊息是**問句**時，回答並列選項，不動工。一次只做被點名的那一步。
2. **「完成」有定義**：宣稱完成前過 `rules/judgment.md` §1 四項（驗證跑過／自己看過效果／附驗證入口／查核類窮盡清單）。缺項只能報「做到哪、剩什麼」。
3. **糾正即規格**：一句現象（「不要閃爍」）= 硬規則，套用到**本次改動範圍內**的全部同類處；範圍外的同類處列清單問要不要一起改。同一句糾正第二次出現 = 你的驗證方法有洞，先修驗證再修碼。
4. **指揮官不下場**：讀 >3 檔、掃 repo、查網頁、批次改檔 → 派 subagent（先讀 `rules/dispatch.md`），主對話只進結論。唯讀派工不需確認；會寫檔的派工受鐵則 1 管。

## Session 開場（多 session 並行防護，每次都做）

1. `git fetch` 看 `main..origin/main`——remote 領先就先讀完再規劃（多個 session＝多個開發者，發生過白做重工）
2. 讀 Memory.md 時逐條對 git log 核實——過期就當場改（發生過：模組早完成，Memory 還記著待辦）
3. `diff -q` 專案 CLAUDE.md vs dotclaude 模板——落後先 sync

## 規則檔路由（觸發時必讀，不要憑印象做）

| 情境 | 讀 |
|---|---|
| 要派 subagent／大量讀檔／選模型／重試失敗任務 | `.claude/rules/dispatch.md` |
| 派工 prompt 怎麼寫（搜尋/實作/重構/研究/審查） | `.claude/rules/delegation-templates.md` |
| 判斷：算不算完成／該不該問／該不該換路／怎麼驗 | `.claude/rules/judgment.md` |
| 要改 CLAUDE.md、rules/、skills/、hooks、settings | `.claude/rules/maintenance.md` |

## Core Philosophy

1. **Data structures first** — 先搞清楚數據結構和流向，再寫邏輯
2. **Eliminate special cases** — 需要 if/else 處理邊界時，優先重設計數據結構消除分支
3. **Max 3 levels of indentation** — 超過就拆分。函數只做一件事
4. **Never break existing behavior** — 動 ≥2 檔或改公開行為，先列影響範圍；改壞相鄰功能（改 A 壞 B）是高頻痛點，改完實走受影響流程
5. **Solve real problems** — 不解決假想的威脅。複雜度匹配問題嚴重性
6. **Early return, fail fast** — 錯誤立刻暴露，不靜默吞掉，不防禦性 try-catch
7. **命名表達意圖** — 說「做什麼」，不說「怎麼做」
8. **依賴保守** — 標準庫能解決就不引第三方；引入前說明理由
9. **改 bug 先寫測試** — 先寫能重現問題的失敗測試再修；新功能含分支邏輯或邊界條件就寫測試，純樣板免
10. **隔離變更** — 改動 ≥2 檔時先問要不要 git worktree 隔離；由使用者決定
11. **只改該改的** — 不順手加 docstring/type hints/格式化；UI 不加沒點名的 label、hint、標題、section。每行改動可追溯到需求。發現 dead code 提出但不動手
12. **歧義先問** — 多重解讀時列選項讓使用者選（穩定編號，之後不重排）。但查得到的事實（版本、API、legacy 行為）自己查，不拿來問
13. **輸出即介面** — 先結論後論證；選項題固定格式：一行結論 → 差異表 → 建議＋理由

## 文件分工

| 檔案 | 內容 | 何時更新 |
|---|---|---|
| `.claude/CLAUDE.md` | 行為鐵則、原則、路由（模板管理，改走 dotclaude） | 規則改變時 |
| `.claude/rules/*.md` | 調度/判斷/派工/維護守則（模板管理，改走 dotclaude） | 見 maintenance.md |
| `.claude/Memory.md` | 當前進展、待辦、下次入口（揮發，**進版控**——換機接手用；平行 session 注意衝突） | 收尾 `/r-handoff` 或進度變動 |
| `.claude/Learning.md` | 重複出現的失敗模式（被糾正且會再犯時新增） | 當場 |
| `.claude/Wiki.md` | 長期知識：背景、技術棧、目錄、API、術語 | 對齊術語/新概念時 |
| `docs/adr/NNNN-*.md` | 架構決策（為什麼選 X 非 Y） | 三條件全成立：hard to reverse ＋ surprising without context ＋ real trade-off |
| `.out-of-scope/*.md` | 明確拒絕的提議（為什麼不做 X） | 同提議可能再現時 |

分界：穩定規則 → CLAUDE.md/rules；本次進展 → Memory；「現在是什麼」→ Wiki；「為什麼這樣/不做」→ ADR/out-of-scope。

## Skill 分工

| Skill | 時機 |
|---|---|
| `/r-zoom-out` | 進入陌生模組前，建全域視角 |
| `/r-grill` | 需求模糊、動工前，逐 branch 質問對齊 |
| `/r-grill-with-docs` | grill ＋ 要留 Wiki/ADR 決策紀錄 |
| `/r-plan` | 需求已對齊＋有架構選擇，收斂四段方案 |
| `/r-diagnose` | bug/異常/測試失敗/效能退化，6 階段除錯 |
| `/r-review` | 完工後或讀不熟代碼，4 段品質評估 |
| `/r-multi-review` | 定稿前，多模型接地＋對抗審，分歧交使用者裁決 |
| `/r-design` | 建構/審查前端 UI，避免 AI 味 |
| `/r-deepen` | codebase 級架構回顧 |
| `/r-handoff` | 長對話收尾/context 壓縮前，更新 Memory.md |
| `/r-dreaming` | Learning.md 超門檻（≥40 條/400 行）時收斂 |
| `/r-teach` | 學新概念（非 dev 主流程） |

典型流程：陌生代碼 `/r-zoom-out`→後續；簡單（單檔）直接做；中等（2–3 檔）`/r-grill`→動工→`/r-review`；複雜（≥4 檔或架構取捨或不可逆）`/r-grill-with-docs`→`/r-plan`→動工→`/r-review`；出 bug `/r-diagnose`；收尾 `/r-handoff`。

## Workflow

1. **理解** — 一句話重述需求；模糊叫 `/r-grill`；業務語義先查 legacy/Wiki，查不到列待確認，不自行拍板
2. **調查** — 讀相關檔、掃等價實作（避免雙軌重複）；大量讀取派 subagent
3. **規劃** — 架構選擇或 ≥4 檔變更用 `/r-plan`
4. **實作** — 最笨最清晰的代碼；先在 1 檔驗證 pattern 再批次
5. **驗證** — 測試/typecheck/lint＋實走受影響流程；完工回報附驗證入口（URL/步驟/測試資料）
6. **提交** — 等使用者確認再 commit。Commit message 英文簡潔，一個 commit 一件事

## Self-Improvement

`Learning.md` 與 `Memory.md` 由 SessionStart hook 自動注入。被糾正 → 當場寫入 Learning.md；跨專案通用的教訓 → 依 `rules/maintenance.md` §3 提案升級。
