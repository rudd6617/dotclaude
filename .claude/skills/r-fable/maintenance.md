# 制度檔維護協議（maintenance.md）

<!--
讀者：未來 session 的主模型。規定這套制度檔（CLAUDE.md、skills/（含本 r-fable）、hooks）
怎麼被安全地更新，避免退化成互相矛盾的規則堆。
-->

## 0. 唯一源頭：dotclaude

`CLAUDE.md`、`skills/`（含 r-fable 各分冊）、`hooks/`、`settings.json` 是**模板管理檔**，源頭在
`/Users/rudolfchen/Documents/dotclaude/`，由 `sync.sh` 覆蓋同步到各專案。

**鐵則：改模板管理檔一律改 dotclaude 那份，再跑 `sync.sh <專案路徑>` 推過去。**
直接改專案內副本 = 下次 sync 被無聲蓋掉。如果情急之下改了專案內副本，同一回合內必須回寫 dotclaude，否則等於沒改。

哪些檔案歸誰管，以 `dotclaude/sync.sh` 裡的 `MANAGED` / `SEED` 清單為準（不要憑記憶，先看那個檔）。

## 1. 修改權限分區

| 區 | 檔案 | 規則 |
|---|---|---|
| **綠區**（自行改，事後在回報提一句） | 專案的 `Memory.md`（handoff 更新）、`Learning.md`（新增教訓條目）、`Wiki.md`（補充事實性知識）；r-fable 條目的**驗證標註**（§5，只追加〔✓/✗〕不動條文，改 dotclaude 那份）；dispatch.md 型號表的事實修正（同樣改 dotclaude 那份） | 照各檔頭註解的格式寫；只增改事實，不寫規則 |
| **黃區**（先提案，使用者一句 ok 才改） | `CLAUDE.md`、`skills/`（含 r-fable 各分冊）、`hooks/`、專案 `settings.json`、`.claude/agents/*.md`（自訂 agent 定義；要跨專案沿用就建在 dotclaude——但把它加進 sync.sh MANAGED 是紅區動作，需使用者明確指示） | 提案格式見 §2 |
| **紅區**（使用者明確指示才動） | `sync.sh`、全域 `~/.claude/settings.json`、**刪除**任何制度檔、改 `.backup-*` | 沒有指示就完全不碰 |

## 2. 黃區提案格式

一次一條，讓使用者能單字元裁決：

```
提議修改 skills/r-fable/judgment.md：
- 現況：<引用現有條文或「無此規則」>
- 觸發事件：<今天發生了什麼，檔案:行號或引文>
- 新條文：<逐字條文>
- 衝突檢查：grep 過 CLAUDE.md + skills/r-fable/，與 <條目> 不衝突／需同步改 <條目>
改嗎？(y/n)
```

## 3. 踩坑教訓寫回哪裡

| 教訓性質 | 寫到 | 格式 |
|---|---|---|
| 這個專案特有（環境、指令、業務口徑） | 專案 `Learning.md` 或 `Wiki.md` | 照檔頭註解格式 |
| 跨專案的流程/行為教訓（會在別的 repo 再犯） | 先記進專案 `Learning.md`，並**同回合提案**升級進 dotclaude 的 `skills/r-fable/judgment.md` 或 `CLAUDE.md`（黃區流程） | §2 提案格式 |
| 一次性架構決策 | `docs/adr/`（三條件見 CLAUDE.md） | ADR-FORMAT.md |
| 被否決的提議 | `.out-of-scope/*.md` | 為什麼不做 X |

判斷「會不會在別的 repo 再犯」：教訓裡若不含任何專案專名（檔名、業務詞）仍然成立 → 跨專案。

## 4. 品質守則（防退化）

- **收規則要有三件**：觸發條件（何時適用）、判準（怎麼算違反）、範例。抽象口號（「保持高品質」「小心謹慎」）不收——寫不出違反範例的規則等於沒寫。
- **只增不減 = 退化**。新增一條前先 grep 既有檔找同主題條目：能合併就合併，衝突就明寫哪條作廢，不能新舊並存。
- **行數上限**：`CLAUDE.md` ≤100 行；r-fable 每分冊 ≤160 行；專案 `Learning.md` ≥40 條或 ≥400 行時跑收斂（合併重複、把重複出現的教訓提案升級成規則、刪過期條目）。超限就精簡，把細節下放引用檔。
- **改前留備份**：dotclaude 是 git repo——動模板檔前確認 working tree 乾淨（`git status`），改完立刻 commit（英文、一個 commit 一件事）。git 歷史就是備份；不要另建散落的 `.bak` 檔。
- **文件宣稱的機制必須存在**：任何檔案裡寫到「會自動 X」「跑 /某skill」時，當場驗證那個 hook/skill 真的存在（`ls .claude/skills/`、讀 settings.json）。宣稱有而實際沒有的自動化，比沒有更糟——它讓所有人以為有人在把關。

## 5. 規則生命週期（防止規則堆成信仰）

- 所有規則（r-fable 鐵則與各分冊條目）初始狀態＝**未驗證**。某條規則在真實 session 裡實際起作用（防住一次失敗，或反而擋錯路）時，在該條末尾追加標註：`〔✓ 2026-07-10 一句情境〕` 或 `〔✗ 2026-07-10 一句情境〕`。這是綠區動作，但要改 dotclaude 那份再 sync。
- 同一條規則累積 **2 個 ✗** → 提案（§2 格式）降級為「建議」或刪除，不得帶著失效紀錄繼續當鐵則。
- 新增規則時的合併/刪除檢查見 §4（新增與清理成對發生，禁止只增不刪）。

## 6. 同步紀律

- 在 dotclaude 改完模板檔 → commit → 對**當前工作的專案**跑 `./sync.sh <專案路徑>`（先 `--dry-run` 看一眼要蓋什麼）。
- 其他專案不用主動巡迴同步；下次在那個專案工作時，開場發現模板落後（`diff -q` CLAUDE.md 即知）再 sync。
- sync 會**覆蓋**專案內所有 MANAGED 檔（以 `sync.sh` 清單為準——含 `CLAUDE.md`、`skills/`、`hooks/`、`settings.json` 與 docs 兩檔）：若專案副本有未回寫 dotclaude 的本地修改，sync 前先 diff 搶救。
