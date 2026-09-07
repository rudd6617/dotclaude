@../AGENTS.md

<!--
家規（原則、模式、流程、Git 慣例）在上面那行 import 的 `AGENTS.md`——工具無關，任何 agent 都讀。
本檔只放 Claude Code 專屬的東西：skill 路由、hook 機制。規則本體不寫這裡，寫 AGENTS.md。
本檔是模板管理檔，隨 sync.sh 進各專案（見 docs/MAINTENANCE.md §0）。
-->

# Claude Code 專屬設定

## Skill 分工

| Skill | 時機 | 用法 |
|---|---|---|
| `/r-zoom-out` | 進入陌生模組前 | 建立全域視角（角色/邊界/數據流） |
| `/r-grill` | 需求模糊、動工前 | 一輪問完可答的 frontier，逐輪收斂；解析出術語 / 觸發三條件時順帶維護 Wiki/ADR |
| `/r-wayfinder` | 巨大模糊工程、一個 session 裝不下 | GitHub 決策地圖，逐票解到路徑清晰；只規劃不建構 |
| `/r-plan` | 需求已對齊 + 涉及架構選擇 | 收斂為四段方案 |
| `/r-ticket` | 需求已對齊、要拆成可獨立交付的切片 | 產出 GitHub spec issue + tracer-bullet 子票（含阻塞順序） |
| `/r-diagnose` | bug / 異常行為 / 測試失敗 / 效能退化 | 6 階段除錯 |
| `/r-review` | 完工後 / 讀不熟代碼 | 4 段品質評估 |
| `/r-multi-review` | 定稿前、怕幻覺/漏需求 | 多模型接地＋對抗審，分歧交你裁決 |
| `/r-design` | 建構 / 審查前端 UI | 設計 anti-pattern 清單，避免 AI 味 |
| `/r-deepen` | codebase 級架構回顧 | 找深化機會 |
| `/r-audit` | 定期 / 大改制度後 / harness 感覺不對 | 健檢：文件vs現實＋痛點挖掘，發現附驗證指令，裁決後修 |
| `/r-handoff` | 長對話收尾 / context 壓縮前 | 壓成交接、更新 `.claude/Memory.md` |
| `/r-teach` | 想學新概念 / 技能（非 dev 主流程） | 建教學工作區，依 storage strength + ZPD 教學 |
| `/r-eli5` | 要把某個東西解釋給外行 / 主管 / 同事 | 大圖極少字的 HTML artifact，一次性不留檔 |

典型流程（Workflow 六步的 skill 路由；步驟本體見 `AGENTS.md`）：
- 陌生代碼：`/r-zoom-out` → 後續
- 簡單（單檔、無架構選擇）：直接做
- 中等（2–3 檔、無架構取捨）：`/r-grill` → 動工 → `/r-review`
- 複雜（≥4 檔 或 有架構取捨 或 不可逆）：`/r-grill` → `/r-plan` → 動工 → `/r-review`
- GitHub ticket 流程（多切片）：`/r-grill`（或 `/r-plan`）→ `/r-ticket` → 逐票走「實作段」→ 關 issue
- 巨大模糊工程（多 session）：`/r-wayfinder`（畫地圖 / 逐票解決策）→ 霧散後 `/r-ticket` → 逐票實作
- 出 bug：`/r-diagnose`
- 中後期回顧：`/r-deepen`
- 對話收尾：`/r-handoff`

跑 ticket 流程時，每張票獨立走 Workflow 迴圈：抓一張 `ready-for-agent` 票 → 實作段（4–6）→ `/r-review` → commit → `gh issue close`，票與票之間清空 context。

## 派工其他 agent

非 Claude 的 agent 讀不到本檔，但讀得到 `AGENTS.md`。派工時在指令裡點名模式即可，例如「以 `AGENTS.md` 的審查員模式審 X」——`codex exec` / `codex review` 每次都會自動載入專案根的 `AGENTS.md`。

## Self-Improvement
`.claude/Learning.md` 與 `.claude/Memory.md` 會透過 SessionStart hook 自動注入，不需手動讀取。
被糾正時，將教訓寫入 `.claude/Learning.md`（一條一個 `##` 標題）。
條目累積過量時，hook 會提醒收斂（合併重複、升級成 `AGENTS.md` 原則、刪過期條目；判準見 `docs/MAINTENANCE.md` §4）。
