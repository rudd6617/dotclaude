# Drill：選定候選之後

用 SKILL.md 的詞彙（module、interface、seam、adapter）。改編自 Matt Pocock `codebase-design` 的 DEEPENING 與 DESIGN-IT-TWICE。

## 1. 依賴分類決定怎麼測

先把候選的依賴歸類，類別決定深化後的 module 跨 seam 怎麼測：

| 類別 | 例子 | 做法 |
|---|---|---|
| 行程內 | 純計算、記憶體狀態，無 I/O | 直接合併成一個 module，從新 interface 測，不需要 adapter |
| 本機可替身 | Postgres → PGLite、檔案系統 → 記憶體檔案系統 | 測試時跑替身；seam 留在內部，不開到 interface 上 |
| 遠端但自家的 | 自己的微服務、內部 API | 在 seam 定 port；production 用 HTTP／queue adapter，測試用記憶體 adapter |
| 真外部 | 金流、簡訊等第三方 | port 注入外部依賴，測試給 mock adapter |

只有一種 adapter 的 port 只是多一層間接（Two-adapter rule）。內部 seam 給 module 自己的測試用就好，不要因為測試要用就開到 interface 上。

## 2. 測試：替換，不疊加

- interface 就是測試面：在新 interface 上寫測試，斷言從 interface 看得到的結果，不斷言內部狀態。
- 新測試到位後，舊的淺 module 單元測試刪掉，不要兩套並存。
- 內部重構就要改的測試，代表它測穿了 interface。

## 3. 介面設計兩次以上（使用者想比較介面時）

1. 先寫一段給使用者看的問題空間：新介面要滿足的限制、依賴類別、一小段示意碼（只用來說明限制，不是提案）。
2. 平行派 3 個以上 subagent，各給同一份技術 brief（檔案、耦合、依賴類別、seam 後面藏什麼）加上不同限制：
   - 介面最小：1–3 個入口，每個入口的槓桿最大
   - 彈性最大：支援多種用法與擴充
   - 最常見的呼叫端最簡單：預設情境一行搞定
   - （跨 seam 依賴多時）以 port 和 adapter 為中心
3. 每份輸出：interface（型別、不變式、順序、錯誤模式）、呼叫範例、seam 後面藏了什麼、依賴策略、槓桿高與薄的地方。
4. 依序呈現，再用 depth、locality、seam 位置比較，最後給明確推薦（可以混搭）。不要只丟選單。

## 4. 和既有 ADR 衝突

候選違反既有 ADR 時，只有摩擦真的大到值得重議才提，並標明「違反 ADR-NNNN，值得重開因為……」。ADR 禁止的理論重構不逐條列。
