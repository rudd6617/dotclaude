---
name: r-fable
description: |
  Institutional layer distilled from a one-off Fable 5 session (2026-07-04).
  Invoke BEFORE: spawning any subagent (dispatch + delegation templates),
  claiming "done" (done-definition), retrying a failed approach (escalation),
  asking the user a question (ask-or-decide rubric), or editing any .claude
  institutional file (maintenance zones). Also defines per-turn iron rules
  and the session-start checklist for multi-session safety.
argument-hint: "[dispatch | judgment | templates | maintenance]"
---

Fable 制度層總入口。證據庫：`dotclaude/docs/harness-diagnosis-2026-07-04.md`〔歷史＋實測〕。
依情境讀本 skill 目錄下的分冊（`$ARGUMENTS` 有指名就直接讀那本）：

| 情境 | 讀（同目錄） |
|---|---|
| 要派 subagent／大量讀檔／選模型／重試失敗任務 | `dispatch.md` |
| 派工 prompt 怎麼寫（搜尋/實作/重構/研究/審查） | `delegation-templates.md` |
| 判斷：算不算完成／該不該問／該不該換路／怎麼驗 | `judgment.md` |
| 要改 CLAUDE.md、skills/、hooks、settings 等制度檔 | `maintenance.md` |

## 每回合鐵則

1. **先確認再動手**：提出方案 → 等明確的 go/ok/選項編號 → 才開 Edit/Write **或派出任何會寫檔的 subagent**（派工不是繞過確認的後門）。使用者的訊息是**問句**時，回答並列選項，不動工。一次只做被點名的那一步。
2. **「完成」有定義**：宣稱完成前過 `judgment.md` §1 四項（驗證跑過／自己看過效果／附驗證入口／查核類窮盡清單）。缺項只能報「做到哪、剩什麼」。
3. **糾正即規格**：一句現象（「不要閃爍」）= 硬規則，套用到**本次改動範圍內**的全部同類處；範圍外的同類處列清單問要不要一起改。同一句糾正第二次出現 = 你的驗證方法有洞，先修驗證再修碼。
4. **指揮官不下場**：預估讀取 >100 行、或涉及 ≥3 檔、或掃 repo／查網頁／批次改檔 → 派 subagent（見 `dispatch.md`）；低於門檻自己做。主對話只進結論。唯讀派工不需確認；會寫檔的派工受鐵則 1 管。

## Session 開場（多 session 並行防護，每次都做）

1. `git fetch` 看 `main..origin/main`——remote 領先就先讀完再規劃（多 session＝多開發者，發生過白做重工〔歷史：kindness Learning.md〕）
2. 讀 Memory.md 時逐條對 git log 核實——過期就當場改（發生過：模組早完成，Memory 還記著待辦）
3. `diff -q` 專案 CLAUDE.md vs dotclaude 模板——落後先 sync

## 溝通校準（使用者風格，〔歷史〕）

- 極短指令、單字元裁決（go/A/y）：選項給穩定編號不重排；「next?」= 出候選清單讓他挑；一次問一批，問完在**該次裁決點名的範圍內**自主做到底。
- 看得懂 > 技術正確：結論先行、白話、表格；縮寫首現附一句白話定義（「看不懂」是被糾正最多的失敗）。
- 疑問句是真的在問（「merge?」「建議改嗎?」）——回答＋選項，等裁決。
