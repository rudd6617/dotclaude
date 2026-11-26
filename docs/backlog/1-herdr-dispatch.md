# 1 — 用 herdr 派工：主管 tab 開單，每張單一個 tab 加一個 worktree

狀態：只規劃，未實作（2026-11-15）。使用者目前用不到，等需要時再動工。

## 需求

- 一個專案一個 herdr workspace，一張單一個 tab。
- 一個常駐的主管 workspace。使用者把需求丟給它，它判斷單子屬於哪個專案，開 worktree 和 tab，寫任務書 `BRIEF.md`，再起一個 agent。
- 單子做完後，關掉 worktree 和 tab。

## 已確認的事實

- `herdr worktree create` 一定另開一個新的 workspace，加 `--workspace` 也一樣。`--workspace` 只指定從哪個 repo 開。`herdr worktree remove` 會一起關掉那個 workspace。（2026-11-15 在暫存 repo 實測，herdr 0.9.4）
- herdr 的 workspace 清單是平的，不能分組。所以「一張單一個 workspace」在單子多時看不出歸屬，**不採用**。
- 改用 `git worktree add` 加 `herdr tab create --workspace <專案> --cwd <worktree>`。
- herdr skill 規定：除非使用者明確要求，否則不開 workspace、tab、worktree。主管的授權要寫進 skill。而且主管必須跑在 herdr 裡（`HERDR_ENV=1`）。
- agent 名稱必須符合 `[a-z][a-z0-9_-]{0,31}`，slug 只能用小寫英數。tab 名稱可以用中文。

## 和 Matt Pocock 做法的差異

- 相同：先寫任務書；一張單一個隔離分支；做完就清掉。
- 不同：Pocock 的派工者是 TypeScript 程式（Sandcastle `run()`），不是 agent；實作 agent 預設 AFK。本設計由 agent 派工，而且有 ask-first，人一直在迴圈裡。
- 借用：Pocock 的票以「驗收條件」為核心，所以 BRIEF 加上這一段。
- 來源：github.com/mattpocock/sandcastle、github.com/mattpocock/skills

## 和 DeepSeek Super-Agent 的差異

- 來源：github.com/deepseek-ai/dsh-superagent-prototype（2026-11-16 讀 `docs/000`–`004` 與 `prompts/`）
- 相同：一個主管負責分派；每張單有自己的 session 和目錄（他們也用 `git worktree`）；預設由人合併。
- 不同：它服務一個團隊，入口是 GitHub 和飛書，目標是盡量不需要人看著；實作者不能直接問人。本設計只服務一個人，使用者在場，每一步都確認。
- 借用（2026-11-16 使用者同意）：
  1. 主管不寫需求：BRIEF 原文照貼使用者的話，驗收條件只寫使用者確認過的（出自 `prompts/dispatch.md`）
  2. 固定的回報狀態：`ready` / `blocked` / `failed` / `dropped`，草稿沒做完算 `blocked`（出自 `prompts/work.md`）
  3. 中斷後重開：先查 git 再動手，不重做（出自 `docs/003-execution.md` Restart 段）
  4. 主管不輪詢（出自 `prompts/orchestrator.md`）
- 不借：允許名單與自動接單、自建資料庫與面板、實作者不能問人、結束後重新開啟同一張單。理由是只有一個人在用，而且人在場。

## 檔案樹

```
dotclaude/
├── AGENTS.md                          改：「模式」段加「實作者模式」
├── .claude/skills/r-dispatch/SKILL.md 新：主管的流程手冊（收單 → 歸屬 → BRIEF → 開單 → 收單）
├── dispatch/
│   ├── ticket.sh                      新：open / close 兩個子指令，負責 git 與 herdr 的動作
│   └── BRIEF.template.md              新：任務書範本
└── tests/ticket.test.sh               新：用暫存 repo 加假的 herdr 測 open / close
```

主管 workspace 開在 `~/Documents`，這樣看得到所有專案。

## 數據結構

不另外建專案清單和單據清單。狀態已經在 git 和 herdr 裡：

| 問題 | 答案從哪裡來 |
|---|---|
| 有哪些專案 | `~/Documents/*` 裡有 `AGENTS.md` 的 git repo；主管讀各自的 Project Context 判斷歸屬 |
| 某張單在哪 | 專案 workspace 底下的 tab，名稱是 `slug 中文短名` |
| 某張單的程式碼在哪 | `git worktree list`，路徑 `~/Documents/.worktrees/<專案>/<slug>`，分支 `t/<slug>` |

**開單**（`ticket.sh open <專案> <slug> <BRIEF 檔>`）：
1. `git worktree add`
2. 把 BRIEF.md 放進 worktree，並寫進 `.git/info/exclude`，所以永遠不會被 commit
3. 找到專案的 workspace（沒有就建一個）→ `herdr tab create`
4. `herdr agent start <專案>-<slug> --kind claude`
5. 用 prompt 叫它「以實作者模式讀 BRIEF.md 開工」

**收單**（`ticket.sh close <專案> <slug>`）：
1. 檢查 worktree 沒有未提交的改動，而且分支已經合進 main。任何一項不成立就停下來，不刪
2. `herdr tab close` → `git worktree remove` → `git branch -d`。先關 tab：實作者的 shell 開在 worktree 裡，先移除 worktree 那個 shell 會壞掉

**合併**（已定：方案 A）：主管在本機跑 `git merge --ff-only`，合併前問使用者。不開 PR。

**BRIEF 分八段**：使用者原話／目標／驗收條件／scope／out-of-scope／ask-first／驗證指令／回報格式
- 「使用者原話」一字不改照貼。實作者以原話為準，其他段落和原話衝突時照原話做。
- 驗收條件、scope、out-of-scope 只能寫使用者親口確認過的內容。主管不得自行補充需求、實作計畫或檢查清單。

**主管不輪詢**：開單後，這一輪就結束。主管不用 `sleep`、迴圈或 `herdr` 指令去看實作者的 tab。實作者的回報靠 herdr 通知送到使用者手上，使用者再回主管 tab 說要收單。

**實作者模式**：
- scope 以內：直接改、跑驗證，然後在自己的分支 commit，不用每一步都先提案
- 碰到 ask-first 或 out-of-scope：停下來，在自己的 tab 問使用者（herdr 會亮 Done 通知）
- 不准做的事：merge、push、刪 worktree
- BRIEF 寫的驗收條件就是全部門檻：不自己加檢查、審查輪或簽核（借自 pstack `worker.md`）
- 開工前先看 `git log` 和 `git status`。如果分支上已經有 commit 或改動，代表前一個 agent 中途斷了；先弄清楚做到哪，再接著做，不重做已完成的部分
- 結束時回報一個狀態，只能從下表選：

| 狀態 | 意思 |
|---|---|
| `ready` | 做完了，自我審查過，驗證指令都跑過而且通過。等使用者看 |
| `blocked` | 需要使用者決定或提供東西才能繼續。草稿沒做完也算這個，就算部分測試已經通過 |
| `failed` | 做不到，附原因和試過的方法 |
| `dropped` | 查過之後發現不用做，例如問題重現不了、已經有人修過了。附依據 |

回報內容：狀態、改了什麼、實際跑過的驗證和結果、風險。

## 風險點

| 風險 | 處理 |
|---|---|
| `AGENTS.md` 會同步到所有專案 | 只是新增一個模式。沒指定模式的 session 行為不變 |
| 合併進 main 會改到主資料夾的檔案；thec-ocr-service 的正式服務就從主資料夾跑，合併等於直接上線 | 合併一律問使用者；`r-dispatch` 裡把這種專案特別標出來 |
| worktree 裡沒有 `Memory.md`（它不進版控） | 實作 agent 靠 BRIEF 就夠 |
| 實作 agent 寫進 `Learning.md` 的內容，會跟著分支合回 main | 合併時會一起看到 |
| 不是 git repo 的專案（例如 thec-devflow） | 主管拒收，並告訴使用者原因 |
| 測試碰到真的 herdr | 測試用假的 `herdr` 放在 PATH 最前面 |

## 動工前要再確認

- herdr 版本是否還是 0.9.4；新版的 `worktree create` 可能可以開成 tab，那就改用原生指令。
