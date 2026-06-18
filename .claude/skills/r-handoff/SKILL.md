---
name: r-handoff
description: |
  Compact the current conversation into .claude/Memory.md so the next session
  (or future-you) can pick up the work without re-deriving context.
  Use at the end of a long session or before context compression.
disable-model-invocation: true
argument-hint: "[what the next session will focus on]"
---

把當前對話壓成交接，**更新 `.claude/Memory.md`**（揮發狀態，已 gitignore）。覆蓋既有的「當前進展 / 待辦 / 下次入口」段，補充「已確認結論」。

## 寫入對應

| 對話內容 | 寫進 Memory.md 的段 |
|---|---|
| 目標 + 已完成 / 進行中 / 未開始 | 當前進展 |
| 本次拍板、還沒沉澱進 CLAUDE.md/Wiki/ADR 的決定 | 已確認結論 |
| 卡住的點、未解問題、下一步要做的事 | 待辦 |
| 下個 session 第一件該做的事、建議的 skill（`/r-grill` / `/r-plan` / `/r-diagnose` / `/r-review` …） | 下次入口 |

## 規則

1. **不複製其他 artifact 已有的內容** — PRD、plan、ADR、commit、diff 用路徑/URL 引用，不重貼
2. **redact 敏感資訊** — API key、密碼、PII
3. **若有 $ARGUMENTS** — 視為「下個 session 的聚焦點」，依此裁剪內容並寫入「下次入口」
4. **長度上限** — Memory.md 一頁可讀完。冗長 = 等於沒寫；舊進展直接覆蓋，不要堆積
5. **穩定的偏好/規則不進 Memory** — 那屬於 `.claude/CLAUDE.md`；穩定的領域知識屬於 `.claude/Wiki.md`

## 輸出

更新 `.claude/Memory.md` 後，把更新後的「下次入口」段印出來給用戶確認。
