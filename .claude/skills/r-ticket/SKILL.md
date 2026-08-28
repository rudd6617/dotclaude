---
name: r-ticket
description: |
  Turn an aligned plan or conversation into GitHub issues — one spec issue plus
  tracer-bullet vertical-slice tickets with explicit blocking order.
  Use after requirements are aligned (via /r-grill or /r-plan) and work needs
  to be split into independently shippable slices.
disable-model-invocation: true
argument-hint: "[feature / plan reference, or leave blank to use conversation]"
---

Break into tickets: $ARGUMENTS

把已對齊的需求/plan 拆成 GitHub issue：一張 spec issue + 若干 tracer-bullet 子票。

## 前置條件

- 需求已對齊（先 `/r-grill`；有架構取捨先 `/r-plan`）。仍模糊就退回去，別在這裡補問設計。
- 環境需有 `gh` CLI 且已 `gh auth login`。缺就停下來請我先裝。

## 步驟

### 1. 收集上下文
從對話取材；若 `$ARGUMENTS` 給了 issue 編號/URL 或 plan 路徑，先讀進來。

### 2. 對照代碼
掃相關檔案，用專案既有詞彙（`.claude/Wiki.md`）與既有決策（`docs/adr/`）。命名跟著代碼走，不自創。

順手找 **prefactor 機會**：先讓改動變容易，再做那個容易的改動（make the change easy, then make the easy change）。有的話排成第一張票。

### 3. 選定測試 seam
草擬切片前，先畫出「這個 feature 要在哪些 seam 上測」。

- **優先用既有 seam**，不新建。
- **用能用的最高層 seam**；非得新建就提在能提的最高點。
- **seam 越少越好，理想是一個**。

把選定的 seam 給我確認再往下——seam 選錯會讓後面每張票的驗收條件都失準。

### 4. 起草切片（tracer-bullet）
每張子票是一條**垂直切片**——穿透所有相關層（schema / API / UI / 測試），可獨立 demo，且**一個 context window 裝得完**。
- 不要按技術層切（「先做完所有 schema」是反例）。
- 標題表達交付物，不表達步驟。
- 每張標明：交付物、阻塞於哪些票（blocked by #N）。
- prefactor 票排最前面。

#### 寬重構是垂直切片的例外

**寬重構** = 一個機械式改動（改欄位名、換共用型別的定義），其 **blast radius** 扇形擴散到整個 codebase：單一次編輯同時炸掉上千個呼叫點，**沒有任何垂直切片能綠著落地**。不要硬塞成 tracer bullet，改用 **expand–contract** 排序：

1. **Expand** — 新形式加在舊形式旁邊，什麼都不壞。一張票。
2. **Migrate** — 呼叫點依 blast radius 分批遷移（一批一個 package / 一個目錄），**每批一張票**、都 blocked by expand。因為舊形式還在，CI 批批保持綠。
3. **Contract** — 沒有呼叫者了才刪掉舊形式。一張票，blocked by 每一張 migrate 票。

連分批都無法各自保持綠時：保留這個順序，但讓這些票共用一條 integration branch，全部 blocked 到最後一張 **integrate-and-verify** 票——綠只在那裡承諾。

### 5. 質問粒度（動工前對齊）
把切片清單（編號 + 標題 + 阻塞邊 + 交付物）給我，逐點壓測：
- 這張是否真能獨立 demo？
- 阻塞順序對嗎？有沒有隱藏依賴？
- 顆粒是否過大（裝不下）或過小（該合併）？

我點頭前不 publish。

### 6. 發到 GitHub
依賴順序發（blocker 先），用 `gh`：
- **Spec issue**：Problem / Solution / User Stories / Out of Scope。內含子票 checklist（`- [ ] #N`）。貼 `ready-for-agent` 標籤。
- **子票**：body 首行寫 `Blocked by #<spec 或前置票>`，接交付物與驗收條件。同貼 `ready-for-agent`。

範例：
```
gh issue create --title "..." --label ready-for-agent --body "..."
```

**不要關閉或修改 parent issue。**

**票裡避免寫具體檔案路徑與程式碼片段**——它們過期得很快，而票是給未來的 agent 讀的。唯一例外：某個片段（state machine、reducer、schema、型別形狀）比散文更精確地編碼了一個決定，那就內嵌它，並註明來源；只留決策密度高的那幾行，不是一個能跑的 demo。

## 銜接

- 上游：`/r-plan` 的四段方案 / `/r-wayfinder` 霧散後的 hand off。
- 下游：逐票實作走 CLAUDE.md 主流程（實作→驗證→`/r-review`→commit→`gh issue close`）。走 **frontier**：任何 blocker 全部完成的票都可以抓；純線性鏈就是從上到下。
