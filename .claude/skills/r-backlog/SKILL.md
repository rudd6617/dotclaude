---
name: r-backlog
description: |
  Update .claude/open-todo-backlog.md from what changed since it was last touched,
  then show every remaining item. Use when the user asks what is left or what to do
  next: "還有哪些 backlog", "剩下哪些 backlog", "顯示所有 backlog", "remain backlog",
  "update backlog", "next backlog", "check all backlog".
argument-hint: "[要特別注意的範圍，例如：採購]"
---

先更新 `.claude/open-todo-backlog.md`，再把剩下的項目**全部**列給使用者看。格式由 `AGENTS.md` 的〈文件分工〉規定，顯示用的 mod 只讀第一個 `## 🎯` 段，所以格式不能改。

## 1. 讀現況

- 讀 `.claude/open-todo-backlog.md`。不存在就照下面的骨架建一份，再繼續：
  ```markdown
  # 剩餘工作總表

  > 整體還剩什麼。有編號的票規格在 `docs/backlog/<N>-*.md`；下個 session 要接的那一步在 `.claude/Memory.md`。

  ## 🎯 剩餘項目
  ```
- 有 `$ARGUMENTS` 就先看那個範圍，其他分類照樣更新。

## 2. 找變動

照順序查，每一筆變動都要有依據：

| 來源 | 怎麼查 |
|---|---|
| backlog 上次修改後的 commit | `git log --oneline $(git log -1 --format=%h -- .claude/open-todo-backlog.md)..HEAD`；檔案沒進過版控就看最近 30 個 commit |
| 還沒提交的改動 | `git status --short` |
| 票檔 | `docs/backlog/` 新增或刪除的票（`git log --diff-filter=AD --name-status` 同一段範圍） |
| 這次對話 | 本 session 做完、新提出、被使用者否決的事 |
| `.claude/Memory.md` 的待辦 | 只找「比下一個 session 長命」的項目，列為**建議移入**，不自動搬 |

## 3. 改檔規則

1. **完成就刪除。** 不留 ✓，git 有歷史。部分完成的項目改寫成「剩下什麼」。
2. **沒有依據不動。** 找不到 commit、票或對話證明完成，就不標完成，也不改寫。
3. **新增項目放進對應的 `###` 分類。** 沒有合適分類就放「其他」。
4. **每一條寫「是什麼＋卡在哪」。** 有票號就帶 `#N`。細節留在票檔，不貼進 backlog。只改這次動到的條目，其他條目的寫法不動。
5. **重數每一類的「剩 N 條」。** 沒有子項的第一層 `- ` 算 1 條；有子項的，算子項的數量。分類變成 0 條就刪掉整個 `###`。
6. `## 🎯` 以外的段落照原樣保留。

## 4. 顯示

改完檔，輸出以下三段，不省略任何一條：

```
## 剩餘 backlog（共 N 條，M 類）

### 分類名稱（剩 n 條）
- #102 船貨預訂：剩三個權限鍵、顯示單位、超賣風險
- …（每條一行，超過 60 個字就截斷，結尾加「…」）

## 本次變動
- 刪除：#99 品類工作區（依據：`c6a9473`）
- 新增：…（依據：本次對話）
- 改寫：…
（沒有變動就寫「本次沒有變動」）

## 建議下一個
#N 標題：一句理由（沒被別的事卡住、只差收尾、或使用者標過優先）
```

`Memory.md` 有建議移入的項目時，最後只問一句：「這幾條要移進 backlog 嗎？」

## 不做的事

- 不 commit、不 push。使用者另外說才做。
- 不開新票檔、不改票檔內容。
- 不重新排列分類的順序。
