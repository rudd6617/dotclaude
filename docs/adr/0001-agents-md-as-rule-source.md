# ADR-0001: 家規以根層 AGENTS.md 為唯一源頭，CLAUDE.md 降為 Claude 專屬層

- **Status**: Accepted
- **Date**: 2026-09-07

## Context

規則原本全寫在 `.claude/CLAUDE.md`（101 行）。但各 agent 讀的檔名是各自寫死的：

| 工具 | 本機版本 | 專案指引檔 | 讀 AGENTS.md | 讀 CLAUDE.md |
|---|---|---|---|---|
| Claude Code | 2.1.263 | `CLAUDE.md` | 否（實測；2.1.277 起原生支援，但同目錄鏈上有 `CLAUDE.md` 時預設不讀，見下） | 是 |
| Codex CLI | 0.153.2 | `AGENTS.override.md` → `AGENTS.md` → fallback（預設空） | 是 | 否 |
| Gemini CLI | 0.54.4 | `GEMINI.md`（`contextFileName` 可改） | 否 | 否 |

實測（空 repo，只放含暗號的 AGENTS.md）：`claude -p` 問暗號答不出來；加一個內容為 `@AGENTS.md` 的 CLAUDE.md 後答出暗號。

後果是規則放哪一邊，另一邊都讀不到。實際已長出三種手工橋接：kindness 寫 9 行 AGENTS.md 叫 Codex「去讀 `.claude/CLAUDE.md`」、career-ops 指向根層 CLAUDE.md、open-slide 讓 CLAUDE.md symlink 到 AGENTS.md。同時 `thec-crm` 已對 Codex 設 trusted 卻沒有 AGENTS.md，等於零規範下跑。

第二個壓力來自角色。目前主要用法是 Claude 主導、`codex exec` / `codex review` 被派工審碼（近兩天 20 場 Codex session 有 19 場是 exec/review 子代理）。審查員的價值來自不帶實作方的記憶與假設，但 kindness 的 AGENTS.md 預設叫 Codex 先讀 Memory，於是每次派工 prompt 都得反向寫「禁讀 Memory／Learning／前審檔」。

2026-10-04 以 2.1.289 重測：只放 AGENTS.md 已能答出暗號。但[官方文件](https://code.claude.com/docs/zh-TW/memory#agents-md)說明預設值 `claude-md-or-agents-md`——工作目錄或其上方有 `CLAUDE.md`、`.claude/CLAUDE.md` 或 `CLAUDE.local.md` 時只讀 CLAUDE.md，不讀 AGENTS.md；改成兩者都讀的設定只認使用者層與組織層，專案層設定會被忽略。用 `@` 匯入 AGENTS.md 則保證不會重複載入。

## Decision

工具無關的規則（原則、模式、流程、Git 慣例）搬到專案根層 `AGENTS.md`，成為唯一源頭；`.claude/CLAUDE.md` 第一行 `@../AGENTS.md` 吸入家規，本體只留 Claude 專屬機制（skill 路由、SessionStart hook）。角色不進工具入口檔，改以 `AGENTS.md` 內一段「模式」表達（預設模式 / 審查員模式），派工方在指令裡點名模式。

## Alternatives Considered

1. **維持 CLAUDE.md 為源，模板化 kindness 的指針式 AGENTS.md** — 改動最小，但 Codex／Gemini 每場多一次讀檔的間接跳轉，弱模型可能不跟；且它們讀到的是滿是 slash command 與 hook 敘述的檔案，對非 Claude 的 agent 是雜訊。
2. **open-slide 模式：AGENTS.md 為本體，CLAUDE.md symlink 過去** — 適合「多 agent 平等直接服務使用者」的專案，但本模板 Claude 有 skill 路由與 hook 需要獨立段落，symlink 無處可放；且 sync.sh 複製 symlink 到各專案的行為比複製兩個實體檔更難預測。
3. **把「你是審查員，不要讀 Memory」直接寫進 AGENTS.md** — 這是本 ADR 的第一版設計，被否決：角色寫死在工具入口檔，等 Codex 換成主導者那句就是錯的，得改檔。
4. **角色獨立成 `docs/roles/*.md` 目錄** — 概念最乾淨，但為兩段短文字新開一個目錄，資訊分散、檢索成本高於收益。改成 `AGENTS.md` 內的一段；長到礙眼時再拆。

## Consequences

- 正面：任何 agent 一跳讀到全部家規，不必手工橋接；`thec-crm` 這類已對 Codex trusted 的專案 sync 後立即有規範；審查員模式派工不必每次重寫禁讀清單。
- 正面：`AGENTS.md` 是 agents.md 開放格式，Codex 每次呼叫（含子代理）自動全文注入，零額外設定。
- 負面：`.claude/CLAUDE.md` 第一行的 `@../AGENTS.md` 是隱性依賴——刪掉那行、或 AGENTS.md 沒被 sync 過去，Claude 會靜默失去全部原則。Claude Code 原生支援 AGENTS.md 後依然成立：只要 CLAUDE.md 存在，預設就不讀 AGENTS.md。緩解：兩檔同列 `sync.sh` MANAGED，`docs/MAINTENANCE.md` §0 明寫不要刪那行。
- 負面：規則從一個檔變兩個檔，「這條該寫哪」多一次判斷。緩解：MAINTENANCE §0 的一句判準（工具無關 → AGENTS.md）。
- 負面：各專案既有的手寫 AGENTS.md 會被 sync 覆蓋（kindness 已知；career-ops、open-slide 非模板管理專案，不受影響）。
- 觸發重評估的條件：CLAUDE.md 不再有 Claude 專屬內容（則可整檔退役，交給原生讀取）；或使用方式轉為多工具平等主導（則 skill 路由也該搬進 AGENTS.md）。原條件「Claude Code 原生支援讀 AGENTS.md」已於 2.1.277 成立，2026-10-04 評估後維持本決定：CLAUDE.md 仍放 skill 路由與 hook 說明，存在即擋下原生讀取，匯入行不可省。
