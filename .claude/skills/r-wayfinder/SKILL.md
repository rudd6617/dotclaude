---
name: r-wayfinder
description: |
  Plan a huge, foggy effort — too big for one session — as a decision map of
  investigation tickets on GitHub, resolved one at a time until the path is clear.
  Use only when the effort can't be held in a single session; smaller needs go to /r-grill.
  Plans, does not build: hands off to /r-ticket once the fog clears.
disable-model-invocation: true
argument-hint: "[a loose idea (chart mode), or a map issue #/URL (work mode)]"
---

Wayfinder: $ARGUMENTS

把一個「一個 session 裝不下」的巨大模糊工程，畫成 GitHub 上的決策地圖，逐票解到路徑清晰。

## 何時用

- **用**：greenfield 專案、超大 feature，霧狀、多 session。
- **不用**：一個 session 裝得下的想法 → 直接 `/r-grill`。這支只在尺度真的超過時啟動。
- 環境需有 `gh` CLI 且已 `gh auth login`。

## 鐵律

- **只規劃，不建構**。霧散、可動工了就 hand off，不自己寫實作。
- **一個 session 只解一張決策票**（research 票除外）。避免一次崩太多決策失焦。

---

## 模式 A：畫地圖（$ARGUMENTS 是想法）

1. **命名終點**：用 `/r-grill` 或 `/r-grill-with-docs` 逼出「做完長什麼樣」。含糊就先 grill。
2. **鋪開邊界**：breadth-first 掃問題空間，列出所有「還沒定的決策點」（fog）。跨領域知識用 `deep-research` subagent 平行查。
3. **建 map issue**（貼 `wayfinder:map` 標籤）：寫終點、決策索引（已解/未解清單）、目前的 fog。
4. **開決策票**：每個決策點一張子票，body 寫要回答什麼問題；用 `Blocked by #N` 接依賴順序。
5. **停**。地圖畫完就交回給我，不繼續往下解。

## 模式 B：走地圖（$ARGUMENTS 是 map issue #/URL）

1. 讀 map issue 的低解析全貌（終點 + 決策索引 + fog）。
2. **認領**一張未認領的 frontier 票（`gh issue edit --add-assignee @me`）。
3. **解它**：用對的工具——設計決策用 `/r-grill`、知識問題用 `deep-research`、有架構取捨用 `/r-plan`。把答案寫成 resolution comment 貼回票上。
4. **關票**（`gh issue close`），更新 map issue 的決策索引。
5. **fog 升級**：因這次決策而變得「可明確化」的新區域，開成新的決策票。
6. 一張就停（除非是純 research 票）。

## 銜接

決策地圖解到路徑清晰 → hand off `/r-ticket` 把可動工的部分拆成 tracer-bullet 子票。wayfinder 自己絕不進到實作。
