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

- **只規劃，不建構**。霧散、可動工了就 hand off，不自己寫實作。想直接動手的衝動通常是訊號：你已經走到地圖邊緣，該交棒了。
- **一個 session 只解一張決策票**（research 票除外）。避免一次崩太多決策失焦。

---

## 地圖

地圖是**單一** GitHub issue（貼 `wayfinder:map` 標籤），決策票是它的子票。

地圖是**索引，不是倉庫**：一個決定只活在一個地方——它自己的票裡。地圖只記一句 gist 加連結，絕不轉述細節。未解的票**不列在地圖上**，用 query 找（open + 未認領 + blocker 全關）。

### 地圖 body

```markdown
## Destination
<走到這張地圖的盡頭長什麼樣：這趟要找到的 spec、決定、或改動。一兩行；每個 session 選票前先對準它。>

## Notes
<領域；每個 session 該讀的 skill；這趟工程的長期偏好>

## Decisions so far
<!-- 索引：每張已關的票一行，足以判斷相關性，細節點連結進去 -->
- [<已關票標題>](link)：<答案的一句 gist>

## Not yet specified
<!-- fog：在範圍內、但還問不夠銳利、開不成票的區域；frontier 推進時畢業成票 -->

## Out of scope
<!-- 明確判定超出 destination 的工作；關掉，永不畢業 -->
```

### 決策票

每張票是地圖的**子票**，body 就是那個問題，大小抓「一個 session 解得完」：

```markdown
## Question
<這張票要解掉的決定或調查>
```

**認領**：一個 session 要動這張票，**先** `gh issue edit --add-assignee @me`，**動工之前**——assignee 就是認領，這樣並行的 session 會跳過它。open 且未 assign = 未認領。

**阻塞**用 GitHub 原生 blocking 關係（沒有時退回 body 寫 `Blocked by #N`）。一張票的所有 blocker 都關掉 = **unblocked**。**frontier** = open + unblocked + 未認領的子票，也就是已知的邊界。

答案不寫在 body，解掉時才記（見模式 B）。過程產出的 artifact 用連結掛在票上，不貼進去。

## 票種

每張票都是 **HITL**（human in the loop，跟真人來回）或 **AFK**（agent 自己跑完）。**HITL 票只能透過那場真實對話解掉，agent 絕不代替人類那一方發言**——一個自己問自己答的 grilling agent 已經違反了這條。

| 票種 | 模式 | 用在 | 怎麼解 |
|---|---|---|---|
| `research` | AFK | 需要當前工作目錄之外的知識：文件、第三方 API、外部資料 | 派 subagent 平行查，findings 回貼票上 |
| `grilling` | **HITL** | 設計決策——**預設就是這種** | `/r-grill`，涉及領域詞彙/決策紀錄用 `/r-grill-with-docs` |
| `task` | HITL 或 AFK | 決策前非得先發生的**人工動作**：註冊服務才能評 API、開權限、搬資料才看得到形狀 | 能自己做就自己做；否則給我一張精確 checklist。答案記「做了什麼」與後續票依賴的事實（憑證放哪、新 URL、資料筆數） |

`task` 是唯一「做事」而非「決策」的票種，它的正當性來自**解鎖一個決定**，不是交付終點。

## Fog / Not yet specified / Out of scope

地圖**刻意不完整**：看不見的別畫。

- **開票**：問題**現在就能精確陳述**，即使被 block、現在還不能動。
- **Not yet specified**：還問不夠銳利。判準是「現在能不能把問題講清楚」，**不是**「現在能不能答」。**不要預先把 fog 切成票大小的塊**——它比票更粗，一塊 fog 可能畢業成好幾張票，也可能一張都不變。
- **Out of scope**：**範圍**問題而非銳利度問題——你有意識地判定它超出這趟的 destination。fog 只會朝 destination 聚集，超出 destination 的東西不是 fog。

Out of scope **永不畢業**（frontier 停在 destination）；除非重畫 destination，而那是一趟新工程，不是續攤。

已存在的票被發現超出 destination 時（畫圖時誤收，或被某個決議揭露）：**關掉它**（關掉的票明確不在 frontier 上），在 **Out of scope** 留一行 gist + 為什麼超出範圍 + 連到那張關掉的票。它**不進 Decisions so far**——那裡記的是真正走過的路線，範圍邊界不是路線上的一步。

---

## 模式 A：畫地圖（$ARGUMENTS 是想法）

1. **命名終點**：用 `/r-grill` 或 `/r-grill-with-docs` 逼出「做完長什麼樣」。destination 定住了範圍，所以先定它。
2. **鋪開邊界**：再 grill 一次，這次 **breadth-first**——橫向掃過整個空間，不在任何一條線上深挖，撈出所有未定決策與現在就能動的第一步。**若這步撈不出 fog**（路徑已清晰、整趟一個 session 裝得下），就不需要地圖：停下來問我怎麼走。
3. **建 map issue**（貼 `wayfinder:map` 標籤）：Destination 與 Notes 寫滿，Decisions so far 留空，fog 草寫進 Not yet specified。
4. **開現在就能明確化的票**（標好票種），**第二輪**再接阻塞邊（issue 要先有 id 才能互相引用）。接完邊自然分出 frontier 與 blocked；還不能明確化的留在 Not yet specified。
5. **發 research subagent**：剛開的每張 `research` 票各派一個 subagent 平行解掉。
6. **停**。畫圖就是一個 session 的工作，它不手解任何決策票。

## 模式 B：走地圖（$ARGUMENTS 是 map issue #/URL）

1. 讀 **map** 的低解析全貌（Destination + Notes + Decisions so far + 兩個 section），不是每張票的 body。
2. **選票**：我指定就用我指定的；否則取 frontier 第一張。**先認領**（動任何工之前 assign 給自己）。
3. **解它**：按票種走上表。需要時才 **zoom**——臨時抓相關或已關票的完整 body；`## Notes` 指名的 skill 要讀。
4. **記錄**：答案貼成 **resolution comment** → `gh issue close` → 在地圖 Decisions so far **append 一行指標**。三步都要做。
5. **推進 fog**：新浮現的票（先建再接邊）；這次答案讓某塊 fog 變得可明確化就讓它**畢業**成票，並把那塊從 Not yet specified **清掉**——它此後只以票的形式存在。若答案顯示某張票（這張或別張）超出 destination，**判它 out of scope**，不要在路線上把它解掉。若這個決定讓地圖其他部分失效，更新或刪掉那些票。
6. 一張就停（純 research 票除外）。

我可能會平行跑多張 unblocked 票，所以要預期其他 session 同時在改這個 tracker。

## 銜接

決策地圖解到路徑清晰 → hand off `/r-ticket` 把可動工的部分拆成 tracer-bullet 子票。wayfinder 自己絕不進到實作。
