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

### 3. 起草切片（tracer-bullet）
每張子票是一條**垂直切片**——穿透所有相關層（schema / API / UI / 測試），可獨立 demo，且**一個 context window 裝得完**。
- 不要按技術層切（「先做完所有 schema」是反例）。
- 標題表達交付物，不表達步驟。
- 每張標明：交付物、阻塞於哪些票（blocked by #N）。

### 4. 質問粒度（動工前對齊）
把切片清單（編號 + 標題 + 阻塞邊 + 交付物）給我，逐點壓測：
- 這張是否真能獨立 demo？
- 阻塞順序對嗎？有沒有隱藏依賴？
- 顆粒是否過大（裝不下）或過小（該合併）？

我點頭前不 publish。

### 5. 發到 GitHub
依賴順序發（blocker 先），用 `gh`：
- **Spec issue**：Problem / Solution / User Stories / Out of Scope。內含子票 checklist（`- [ ] #N`）。貼 `ready-for-agent` 標籤。
- **子票**：body 首行寫 `Blocked by #<spec 或前置票>`，接交付物與驗收條件。同貼 `ready-for-agent`。

範例：
```
gh issue create --title "..." --label ready-for-agent --body "..."
```

## 銜接

- 上游：`/r-plan` 的四段方案 / `/r-wayfinder` 霧散後的 hand off。
- 下游：逐票實作走 CLAUDE.md 主流程（實作→驗證→`/r-review`→commit→`gh issue close`）。
