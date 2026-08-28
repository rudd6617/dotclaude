---
name: r-grill
description: |
  Pre-implementation alignment via relentless interview.
  Walk the design tree in rounds, asking the whole answerable frontier each time.
  Use when requirements are fuzzy or before any non-trivial /r-plan.
disable-model-invocation: true
argument-hint: "[need or feature description]"
---

Grill: $ARGUMENTS

把這個需求畫成**設計樹**：每個決定都分岔出掛在它下面的決定。質問到我們達成共同理解。

## 輪次與 frontier

**frontier** = 所有「前置條件已定案」的決定，也就是不必猜測未知答案就能問的題。

**一輪問完整個 frontier**：每題編號、附推薦答案，然後停下來等我回答。我的回答會重塑樹形——已定案的決定把 frontier 往外推，解鎖依賴它們的題。重算 frontier，問下一輪。

**答案依賴本輪其他未決題的問題，屬於後面的輪次**，不是這輪。

## 輪次格式

```
❓ **Q1** - **<題目標題>**：<題目內容，可含多個選項>

➡️ <我的推薦答案與理由>

---

❓ **Q2** - **<題目標題>**：<題目內容>

➡️ <我的推薦答案與理由>
```

## 規則

1. **每題附我的推薦答案**——不只問「你想 X 還是 Y？」而是「我傾向 X，因為 Z；你？」
2. **找事實是我的工作，不是你的**——frontier 上的題需要環境事實（代碼、檔案、工具輸出）時，自己去查或派 subagent。**不要因此卡住整輪**：正在跑的調查只是一個未定前置條件，只有下游的題要等它，frontier 其餘的題現在就問。**決定是你的**，逐題交給你等回答。
3. **拒絕模糊措辭**：你說「account」時逼問「Customer 還是 User？這是兩個不同 entity」。
4. **用具體情境壓測**：邊界、極端、衝突情境。「若 A 和 B 同時發生，誰贏？」
5. **前面決定改變後面選項時，回頭重訪**已問過的分支。

## 何時停

**frontier 空了**：設計樹每個分支都走過，沒有任何東西是默默假設的。此時用一段話總結需求給你確認，確認前不動工。

## 與 /r-plan 的銜接

grill 結束後，若需求複雜到需要架構選擇，呼叫 `/r-plan` 進入收斂。簡單變更可直接動工。
