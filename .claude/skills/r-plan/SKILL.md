---
name: r-plan
description: |
  Propose an implementation plan for architecture changes or multi-file modifications.
  Use when planning significant code changes after requirements are aligned.
disable-model-invocation: true
argument-hint: "[description of the change]"
---

Plan the implementation for: $ARGUMENTS

## 前置條件

需求須已對齊。若仍有歧義，先呼叫 `/r-grill`。

## 思考方式

比較可行方案，選最簡單的那個。

## 輸出格式

## 數據結構
最關鍵的數據關係與流向。

## 複雜度
可以消除的複雜性。如果沒有，說明為什麼當前方案已是最簡。

## 風險點
最大的破壞性風險。列出受影響的現有功能。

## 測試 seam
在哪一層測：用既有、最高的 seam，越少越好，最好只有一個。每個 seam 附一行：它抓得到什麼、漏掉什麼。沒有合適的 seam 時明說，記成架構問題交 `/r-deepen`（原則 3）。
≥4 檔的變更另列切片：每片是端到端可驗證的一小段，不是按層拆（先全部 model、再全部 API）；寬範圍改名或改 schema 用 expand → 遷移呼叫端 → contract 三步。

## 核心判斷
✅ 值得做 / ❌ 不值得做 — 附原因。
如果不值得做，指出真正的問題是什麼。
