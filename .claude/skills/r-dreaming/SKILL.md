---
name: r-dreaming
description: |
  Consolidate .claude/Learning.md — merge duplicates, promote recurring lessons
  into CLAUDE.md principles, retire entries that no longer bite.
  Use when the SessionStart hook flags the convergence threshold, or when
  Learning.md has stopped being read because it got too long.
disable-model-invocation: true
argument-hint: "[leave blank; optionally a theme to focus on]"
---

收斂 `.claude/Learning.md`：$ARGUMENTS

Learning.md 每個 session 都被注入，所以它的長度是**持續成本**。條目累積到沒人讀，這個機制就死了。這支 skill 是它的睡眠週期：把散落的教訓壓成更少、更硬的東西。

## 鐵律

**只做收斂，不新增教訓。** 過程中想到的新教訓另外提出，不趁機塞進去。

**每一條的處置都要我點頭。** 刪除與升級都不可逆（升級會改 CLAUDE.md），逐批提案、等確認。

## 步驟

### 1. 讀齊三個檔

`.claude/Learning.md`（全部條目）、`.claude/CLAUDE.md`（現有原則）、`docs/adr/`（已編號的一次性決策）。

### 2. 分類每一條

| 分類 | 判準 | 處置 |
|---|---|---|
| **升級** | 這條的根因反覆出現在多個條目裡，或它其實是一條**通則**而非個案 | 提議改寫成 CLAUDE.md 的原則（或併進既有原則），Learning.md 那幾條一併刪除 |
| **合併** | 多條講的是同一個失敗模式的不同表象 | 合成一條，情境欄列出各表象 |
| **退役** | 代碼/工具/流程已改，這個坑不存在了；或是一次性事件，不會再犯 | 刪除 |
| **保留** | 仍會再犯、但還不夠通則化 | 原文不動 |

判準核心問題：**這條還會咬到我嗎？** 不會就退役，會且會咬很多次就升級。

### 3. 檢查歸屬錯位

- 條目其實是**一次性架構決策** → 那屬於 `docs/adr/`，不是 Learning。提議搬。
- 條目其實是**明確拒絕過的提議** → 那屬於 `.out-of-scope/`。提議搬。
- 條目其實是**領域知識**（術語、業務口徑）→ 那屬於 `.claude/Wiki.md`。提議搬。

### 4. 提案給我

一張表：條目標題 / 分類 / 處置後長什麼樣 / 一句理由。升級類要**寫出提議的 CLAUDE.md 原則文字**，我要看到最終措辭才能判斷。

### 5. 執行

我點頭後才動筆。同時更新 Learning.md 與 CLAUDE.md（若有升級）。

## 收斂目標

**條目數要真的下降。** 收斂完只少一兩條，等於沒收斂——那要回頭問是不是判準用得太寬鬆（多數條目都被歸進「保留」）。

一條升級進 CLAUDE.md 通常能吃掉 Learning.md 的 3–5 條，這是最大的槓桿；優先找升級機會，再處理合併與退役。

## 何時停

Learning.md 回到門檻以下（門檻見 `.claude/hooks/inject-memory.sh` 的 `MAX_ENTRIES` / `MAX_LINES`），且每一條留下來的都能答出「它還會咬我」。把收斂前後的條目數與升級了哪幾條原則印出來。
