# 制度檔維護協議

<!--
讀者：未來 session 的主模型。規定這套制度檔（global/AGENTS.md、global/CLAUDE.md、skills/、hooks/）
怎麼被安全地更新，避免退化成互相矛盾的規則堆。
本檔只存在 dotclaude，不進專案；各處以 ~/Documents/dotclaude/docs/MAINTENANCE.md 引用。
-->

## 0. 唯一源頭：dotclaude（全域載入）

dotclaude 固定 clone 在 `~/Documents/dotclaude`（家規裡的引用都寫死這個路徑；新機器照放，再跑一次 `sync.sh --global`）。制度檔**不複製進專案**，全部從這裡全域載入：

| 源頭 | 怎麼生效 |
|---|---|
| `global/AGENTS.md`（家規） | `~/.codex/AGENTS.md` symlink；Claude 經 `global/CLAUDE.md` 第一行 `@` import |
| `global/CLAUDE.md`（Claude 專屬） | `~/.claude/CLAUDE.md` symlink |
| `.claude/skills/r-*` | 逐個 symlink 進 `~/.claude/skills/` |
| `.claude/hooks/*` | `~/.claude/settings.json` 的 SessionStart / Stop 直接執行這裡的腳本 |
| `docs/MAINTENANCE.md`、`docs/ADR-FORMAT.md` | 以絕對路徑引用 |

**鐵則：改 dotclaude 那份，commit，立刻對所有專案生效**——不用 sync。專案裡只留專案自己的檔：`AGENTS.md`（只有 `## Project Context`）、`.claude/CLAUDE.md`（只有一行 `@../AGENTS.md`）、`Wiki.md`、`Learning.md`、`Memory.md`、`Verify.md`、`docs/adr/`、專案自有 skill。

`sync.sh` 只做兩件事：建立上表的全域連結（`--global`），以及把舊結構的專案整理成上面那樣（`sync.sh <專案>`、`--all <資料夾>`）。

**規則寫哪一檔**：工具無關的規則（原則、模式、流程、Git 慣例）寫 `global/AGENTS.md`——Codex 等其他 agent 只讀得到它。`global/CLAUDE.md` 只放 Claude 專屬機制（skill 路由、hook），第一行的 import 負責把家規吸進來，**不要刪那行**（刪了 Claude 就讀不到任何原則）。專案專屬的事寫專案 `AGENTS.md` 的 Project Context 或 `Wiki.md`；專案專屬的教訓寫專案 `Learning.md`。

## 1. 修改權限分區

| 區 | 檔案 | 規則 |
|---|---|---|
| **綠區**（自行改，事後在回報提一句） | 專案的 `Memory.md`（handoff 更新）、`Learning.md`（新增教訓條目）、`Wiki.md`（補充事實性知識）；AGENTS.md 原則與 skill 條文的**驗證標註**（§5，只追加〔✓/✗〕不動條文，改 dotclaude 那份）；skill 內事實性錯誤的修正（工具名、路徑、型號——同樣改 dotclaude 那份） | 照各檔頭註解的格式寫；只增改事實，不寫規則 |
| **黃區**（先提案，使用者一句 ok 才改） | `global/AGENTS.md`、`global/CLAUDE.md`、`skills/`、`hooks/`、專案 `settings.json`、`.claude/agents/*.md`（自訂 agent 定義；要跨專案沿用就建在 dotclaude——但讓 sync.sh 把它裝到全域是紅區動作，需使用者明確指示） | 提案格式見 §2 |
| **紅區**（使用者明確指示才動） | `sync.sh`、全域 `~/.claude/settings.json`、**刪除**任何制度檔、改 `.backup-*` | 沒有指示就完全不碰 |

## 2. 黃區提案格式

一次一條，讓使用者能單字元裁決：

```
提議修改 skills/r-review/SKILL.md：
- 現況：<引用現有條文或「無此規則」>
- 觸發事件：<今天發生了什麼，檔案:行號或引文>
- 新條文：<逐字條文>
- 衝突檢查：grep 過 AGENTS.md + CLAUDE.md + skills/，與 <條目> 不衝突／需同步改 <條目>
改嗎？(y/n)
```

## 3. 踩坑教訓寫回哪裡

被糾正時，由強到弱找去處，能用上一層就不寫下一層：

1. **結構**：讓錯做不出來——一件事只留一種寫法、刪掉會被照抄的舊寫法、單一事實來源。
2. **機器擋**：型別、lint、hook、CI。報錯訊息寫明該改用什麼。壞寫法已普遍時，只擋新增的。
3. **行為測試**：測使用者看得到的行為，行為壞了會失敗、只改內部不失敗。
4. **文字**：只留給需要臨場判斷的事，照下表寫進對應檔案。跳過文字規則不會讓任何東西失敗，所以排最後。

| 文字教訓性質 | 寫到 | 格式 |
|---|---|---|
| 這個專案特有（環境、指令、業務口徑） | 專案 `Learning.md` 或 `Wiki.md` | 照檔頭註解格式 |
| 跨專案的流程/行為教訓（會在別的 repo 再犯） | 先記進專案 `Learning.md`，並**同回合提案**升級進 dotclaude 的 `AGENTS.md` 或對應 skill（黃區流程） | §2 提案格式 |
| 一次性架構決策 | `docs/adr/` | ADR-FORMAT.md |
| 被否決的提議 | `.out-of-scope/*.md` | 為什麼不做 X |

自動檢查上線前，先用歷史資料重放，確認它抓得到真實的舊錯誤、誤擋少。範例：`check-reply.py` 擋英文回覆（語言規則升級進 `AGENTS.md` 之後仍復發）。來源教訓寫進檢查的報錯訊息或測試名稱，不寫成註解。

**規則強制表**：每條文字規則都標明由什麼強制。模板規則記在下表；專案規則記在 `Learning.md` 條目的「強制」欄。
- 規則已存在、沒東西強制、又被再犯 → 在同一次改動裡升到更強的一層，不再補文字。
- 錯已經不可能發生 → 刪掉那條文字。
- 需要破例 → 說明寫在違規那一行旁，附理由與到期日，並經使用者同意；不開整份放行。

| 模板規則 | 強制 |
|---|---|
| `AGENTS.md` Language：回覆用繁體中文 | Stop hook `check-reply.py`（主要是英文就擋下改寫） |
| 開場讀 `Memory.md`、`Learning.md` | SessionStart hook `inject-memory.sh` 自動注入 |
| `Learning.md` 過量要收斂（§4 門檻） | `inject-memory.sh` 超過門檻時提醒 |
| `AGENTS.md` 專案級預設：註解只留五種 | `/r-review` 標準軸 subagent 抽查（要手動觸發，不是機器擋；專案有 lint 時改成 lint 規則） |
| 其餘 `AGENTS.md` 原則 | 無——需要判斷；被再犯時照上面規則升級 |

判斷「會不會在別的 repo 再犯」：教訓裡若不含任何專案專名（檔名、業務詞）仍然成立 → 跨專案。

## 4. 品質守則（防退化）

- **收規則要有三件**：觸發條件（何時適用）、判準（怎麼算違反）、範例。抽象口號（「保持高品質」「小心謹慎」）不收——寫不出違反範例的規則等於沒寫。
- **只增不減 = 退化**。新增一條前先 grep 既有檔找同主題條目：能合併就合併，衝突就明寫哪條作廢，不能新舊並存。
- **行數上限**：`global/AGENTS.md` ≤100 行；`global/CLAUDE.md` ≤60 行；每個 skill 檔 ≤160 行；專案 `Learning.md` ≥40 條或 ≥400 行、或 hook 注入內容 ≥9,000 字元時跑收斂（合併重複、把重複出現的教訓提案升級成規則、刪過期條目）；字元門檻是因為 Claude Code 會把超過 10,000 字元的注入內容截成 2,000 字預覽。超限就精簡，把細節下放引用檔。
- **改前留備份**：dotclaude 是 git repo——動模板檔前確認 working tree 乾淨（`git status`），改完立刻 commit（英文、一個 commit 一件事）。git 歷史就是備份；不要另建散落的 `.bak` 檔。
- **文件宣稱的機制必須存在**：任何檔案裡寫到「會自動 X」「跑 /某skill」時，當場驗證那個 hook/skill 真的存在（`ls .claude/skills/`、讀 settings.json）。宣稱有而實際沒有的自動化，比沒有更糟——它讓所有人以為有人在把關。

## 5. 規則生命週期（防止規則堆成信仰）

- 所有規則（`AGENTS.md` 原則與各 skill 條文）初始狀態＝**未驗證**。某條規則在真實 session 裡實際起作用（防住一次失敗，或反而擋錯路）時，在該條末尾追加標註：`〔✓ 2026-07-10 一句情境〕` 或 `〔✗ 2026-07-10 一句情境〕`。這是綠區動作，改 dotclaude 那份。
- 同一條規則累積 **2 個 ✗** → 提案（§2 格式）降級為「建議」或刪除，不得帶著失效紀錄繼續當鐵則。
- 新增規則時的合併/刪除檢查見 §4（新增與清理成對發生，禁止只增不刪）。

## 6. 同步紀律

- 改 dotclaude 的制度檔 → commit → push。這台機器的所有專案立刻生效；別台機器 `git pull` 即生效。
- 新增或移除模板 skill、改 hook 的註冊方式後，跑一次 `./sync.sh --global` 更新全域連結與 `~/.claude/settings.json`。
- 新專案或舊結構的專案：跑 `./sync.sh <專案路徑>`（先 `--dry-run`）。它只刪模板副本：hooks 夾裡有專案自己的腳本、`settings.json` 有模板 hook 以外的設定時，會保留並提示手動處理。
