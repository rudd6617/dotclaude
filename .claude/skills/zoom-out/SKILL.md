---
name: zoom-out
description: |
  Build a higher-level map of unfamiliar code before diving in.
  Show modules, callers, data flow using the project's domain vocabulary.
  Use when entering a section of code you don't know well.
disable-model-invocation: true
argument-hint: "[file, directory, or module name]"
---

Zoom out on: $ARGUMENTS

我不熟這塊代碼。**上升一層抽象**，畫一張地圖：相關 module、呼叫者、數據流——用專案的領域詞彙（若存在 `CONTEXT.md` 先讀過）。

## 不做什麼

- 不寫代碼、不改檔案
- 不深入實作細節
- 不重複貼大段原始碼

## 做什麼

1. **角色** — 這個 module 在系統裡負責什麼唯一責任？
2. **邊界** — 對外介面是什麼？誰呼叫它？它呼叫誰？
3. **數據流** — 主要的數據結構與流向（進來什麼、出去什麼）
4. **不確定** — 一個你目前無法從代碼回答的問題

用 Agent (subagent_type=Explore) 或 grep 找答案，不要憑想像。

## 輸出

5–8 句話的總結 + 一個未解問題。給用戶確認後再進入 `/grill` / `/plan` / 動工。
