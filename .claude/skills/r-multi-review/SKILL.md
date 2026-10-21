---
name: r-multi-review
description: |
  Multi-model grounded + adversarial review to catch hallucinations and requirement gaps
  before finalizing an output. Runs 2 blind grounded verifiers (opus + sonnet) then an
  adversarial refuter, consolidates, and hands disputes to the user.
  Use before committing code, publishing a doc, or locking a design — especially when
  hallucinated facts or missed requirements would be costly.
argument-hint: "[file path | (empty = git diff)]"
---

Multi-model review of a產出物。目標：抓**事實幻覺**與**需求缺漏**，不是重跑 `/r-review`。

核心信念：**接地 > 意見，獨立 > 輪數**。壓事實幻覺靠「真的拿工具對照現實」＋「模型互不重疊的盲點」，不是多找幾個模型讀我的文字投票。

## Phase 0 — 準備輸入

**需求（意圖）** — 查漏的地基，沒有就先問用戶一句話重述。缺需求時 R1/R2 只能查內部一致性，抓不出「漏做了什麼」。

**產出物** — 依 `$ARGUMENTS` 解析來源：
- **空** → `git diff HEAD`（無未提交變更則 `git diff main...HEAD`），`artifactKind: "diff"`
- **是路徑** → 讀該檔內容，`artifactKind: "file"`
- **其他（如「上一則方案」）** → 取本次對話剛產出的文字，`artifactKind: "text"`

**斷言清單** — 我從產出物抽出可查證的事實斷言，編號成 `claims: [{ id: "c1", claim }]`。兩個接地員查同一份清單、按 `id` 回覆，Phase 2 才能逐條對票（各自抽斷言時措辭不同，對不上）。

把 `requirement` / `artifact` / `artifactKind` / `claims` 四者備妥，作為 workflow 的 `args`。

## Phase 1 — 跑 Workflow（R1 接地 → R2 反駁）

用 Workflow 工具跑下面腳本（子代理的 grep/測試輸出隔離在主上下文外，省 context）。透過 `args` 傳入 Phase 0 的四個值。

**Fallback（工具清單裡沒有 Workflow 時）**：不要硬跑。改用 Agent 工具平行 spawn 等價的 subagent——R1 兩個盲審（一個 `model: opus`、一個 `model: sonnet`，各給下方 R1 prompt、斷言清單與 artifact，互不知對方存在），收齊後再 spawn R2 反駁者（`model: opus`，給下方 R2 prompt 與 R1 結果）。回報格式照舊。

```js
export const meta = {
  name: 'r-multi-review',
  description: 'Grounded + adversarial multi-model review for hallucinations and gaps',
  phases: [
    { title: 'R1-Ground', detail: '2 blind grounded verifiers (opus + sonnet)' },
    { title: 'R2-Refute', detail: 'adversarial refuter over surviving claims' },
  ],
}

const { requirement, artifact, artifactKind, claims } = args

const CLAIM_SCHEMA = {
  type: 'object', additionalProperties: false, required: ['claims'],
  properties: {
    claims: {
      type: 'array',
      items: {
        type: 'object', additionalProperties: false,
        required: ['id', 'claim', 'verdict', 'evidence'],
        properties: {
          id:       { type: 'string', description: '斷言清單的 id；清單外自行補的用 new-1、new-2…' },
          claim:    { type: 'string', description: '產出物中一個可查證的事實斷言' },
          verdict:  { enum: ['true', 'false', 'unverifiable'] },
          evidence: { type: 'string', description: 'file:line 或指令輸出；unverifiable 說明為何查不到' },
          severity: { enum: ['fatal', 'major', 'minor'] },
        },
      },
    },
    gaps: { type: 'array', items: { type: 'string', description: '需求有、產出物沒覆蓋的點' } },
  },
}

const REFUTE_SCHEMA = {
  type: 'object', additionalProperties: false, required: ['rulings'],
  properties: {
    rulings: {
      type: 'array',
      items: {
        type: 'object', additionalProperties: false,
        required: ['id', 'stands', 'reason'],
        properties: {
          id:     { type: 'string' },
          stands: { type: 'boolean', description: '嘗試反駁後，此斷言是否仍成立' },
          reason: { type: 'string', description: '反駁證據或為何無法推翻' },
        },
      },
    },
    extraGaps: { type: 'array', items: { type: 'string' } },
  },
}

const groundPrompt = `你是接地驗證員。對照現實查核以下產出物的每個事實斷言——不要用推理，用工具：grep 找檔案/函數/API 是否存在、跑相關測試、讀原始碼確認行號。

產出類型：${artifactKind}
需求（意圖）：
${requirement}

產出物：
${artifact}

斷言清單（逐條按 id 回覆，一條都不能漏；清單漏掉的可查證斷言用 id new-1、new-2… 補上）：
${claims.map(c => `${c.id}. ${c.claim}`).join('\n')}

每條標 verdict：
- true：已用工具確認為真（evidence 附 file:line 或指令輸出）
- false：已用工具確認為假（這是幻覺，evidence 說明真相）
- unverifiable：無法用工具查（evidence 說明為何）
另列 gaps：需求要求、但產出物沒做到的點。盲審，不要臆測其他 reviewer 的結論。`

phase('R1-Ground')
const r1 = (await parallel([
  () => agent(groundPrompt, { label: 'ground:opus',   phase: 'R1-Ground', model: 'opus',   schema: CLAIM_SCHEMA }),
  () => agent(groundPrompt, { label: 'ground:sonnet', phase: 'R1-Ground', model: 'sonnet', schema: CLAIM_SCHEMA }),
])).filter(Boolean)
  // 兩邊各自補的 new-1 是不同斷言，加 reviewer 前綴避免撞號
  .map((r, i) => ({ ...r, claims: r.claims.map(c => c.id.startsWith('new-') ? { ...c, id: `r${i}-${c.id}` } : c) }))

// 存活斷言 = 沒有任何接地員判 false 的（要拿去對抗反駁）
const text = new Map([...claims.map(c => [c.id, c.claim]), ...r1.flatMap(r => r.claims.map(c => [c.id, c.claim]))])
const falseIds = new Set(r1.flatMap(r => r.claims.filter(c => c.verdict === 'false').map(c => c.id)))
const surviving = [...text.keys()].filter(id => !falseIds.has(id))

let r2 = null
if (surviving.length) {
  const refutePrompt = `你是對抗反駁員，預設每個斷言「有罪」直到無法推翻。用工具主動找反例來推翻下列存活斷言；同時對照需求找遺漏。

需求（意圖）：
${requirement}

產出物：
${artifact}

待反駁的存活斷言：
${surviving.map(id => `${id}. ${text.get(id)}`).join('\n')}

對每個斷言按 id 給 ruling：stands=false 表示你成功找到反例（reason 附證據）；stands=true 表示盡力仍無法推翻。另列 extraGaps。`
  phase('R2-Refute')
  r2 = await agent(refutePrompt, { label: 'refute', phase: 'R2-Refute', model: 'opus', schema: REFUTE_SCHEMA })
}

return { r1, r2, surviving, falseIds: [...falseIds] }
```

## Phase 2 — 統合（我做，不交給模型）

合併 workflow 回傳的 `r1` / `r2`，按 `id` 收票：兩個接地員的 `verdict` 各一票，R2 的 `stands:false` 記 false、`stands:true` 記 true；`unverifiable` 不算票。每條斷言只落一類：

| 分類 | 判定 | 處置 |
|---|---|---|
| ✅ **CONFIRMED** | 斷言有 false 票、沒有 true 票（＝確認的幻覺）；或兩個接地員都指出的 gap | 列為必修，等用戶確認才動 |
| ⚠️ **DISPUTED** | 斷言同時有 false 票與 true 票；或只有單一 reviewer 提出的 major+ gap | **交給用戶裁決**，附雙方證據 |
| ❌ **REJECTED** | 斷言沒有 false 票（查證成立或查不到）；或無實害的單方 gap | 丟棄，**只留一行計數**（不靜默吞掉） |

輸出格式：先給 CONFIRMED 清單（含 `file:line` 證據）→ DISPUTED 逐項列選項讓用戶選 → 末尾一行 `REJECTED: N 項（已丟棄）`。

## Phase 3 — 停止與迭代

- 某輪**零 verified issue**（CONFIRMED 為空且無 DISPUTED）→ 立即回報「通過」，停。
- 有 CONFIRMED → 提修法，**等用戶確認才改**（符合 `AGENTS.md` workflow）。改完想重審 → 重跑本 skill，**最多 3 個 pass**。迭代由用戶 gate，不自走。

## 守則

- **不自動改 code**——只產清單，用戶拍板。
- **模型分工**：對錯判斷用 opus/sonnet 互審（已內建）；不要用弱模型審核心判斷。
- REJECTED 必留計數，讓用戶看得到 reviewer 是否在亂報。
