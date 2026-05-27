---
name: handoff
description: |
  Compact the current conversation into a handoff document so another agent
  (or future-you) can pick up the work without re-deriving context.
  Use at the end of a long session or before context compression.
disable-model-invocation: true
argument-hint: "[what the next session will focus on]"
---

Write a handoff doc summarising the current conversation. **Save to the OS temp dir**（`$TMPDIR` 或 `/tmp`），不污染 workspace。

## 內容

- **目標** — 這串對話想完成什麼
- **進度** — 已完成 / 進行中 / 未開始
- **關鍵決策** — 選了什麼、為什麼（不是「做了什麼」，commit 已記）
- **未解問題** — 卡住的點、未對齊處
- **建議下一步 skill** — `/grill` / `/plan` / `/diagnose` / `/review` …
- **參考連結** — PR、issue、ADR、CONTEXT.md 條目（**用路徑/URL 引用，不重複貼內容**）

## 規則

1. **不複製其他 artifact 已有的內容** — PRD、plan、ADR、commit、diff 用引用
2. **redact 敏感資訊** — API key、密碼、PII
3. **若有 $ARGUMENTS** — 視為「下個 session 的聚焦點」，依此裁剪內容
4. **長度上限** — 一頁可讀完。冗長 = 等於沒寫

## 輸出

檔案路徑印出來給用戶（如 `/tmp/handoff-YYYYMMDD-HHMM.md`），方便他複製到下個 session。
