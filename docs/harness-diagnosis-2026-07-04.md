# Harness 診斷報告（2026-07-04，Fable 5 session 產出）

<!--
一次性審計報告，供 rules/ 各檔引用證據。不隨 sync 進專案、不需維護。
資料基礎：
- Session log：kindness 36 場（~350 則實質訊息）、kindness-demo 12 場（~183 則）、
  kindness-app + 其他專案（~78 則）。全部 user 訊息逐則讀完，非抽樣。
- 設定審計：dotclaude 模板 + kindness .claude + ~/.claude 全檔比對。
-->

## 前三名弱點

### 第一名（最漏 token）：閉環沒關上——「完成」不含驗證

**現象**：宣稱完成但沒驗證，使用者發現後追問，一來一回把 token 燒在返工對話上。

**證據（次數 = user 訊息裡的糾正輪）**：
- 驗證環境搞錯（改了碼但瀏覽器看不到：build vs dev、舊 container、port）：**8 輪**
- 首輪檢查不完整、被要求「再檢查一次」：**7 輪**（同一 DNS 檢查被連講兩次「再幫我完成檢查一次」）
- UI 改 A 壞 B、首發即帶 bug：**7 輪**
- 完工不給驗證入口（「我要去哪裡驗證」）：**3 輪**
- 同一糾正要講兩次才生效（「側欄是常駐式」×2、「不要閃爍」×2、「commit」×2）：**7 組**
- 三個專案合計 `[Request interrupted by user]` **26 次**、糾正類佔實質訊息 **15–23%**

一個假完成平均引發 2–8 輪追問，每輪都載著整段 context——這是整個 harness 最大的 token 漏洞，比任何單次讀檔浪費都大。

**修法**（已落檔 `rules/judgment.md` §1、§4）：完成 = 驗證跑過＋自己看過效果＋附驗證入口＋查核類任務窮盡清單，缺一項只能報「做到哪、剩什麼」。前端改動第一步先確認 dev/watch 與 port。

### 第二名（最容易失焦）：搶跑——把討論當指令、把局部當全部

**現象**：使用者還在問問題，Claude 已伸手改碼；或做了字面上的局部版漏掉整體意圖。

**證據**：
- 問句被當指令執行（「merge?」被執行、「建議改嗎？」時已動工）、討論未收斂就動工：kindness 6 輪 + demo 4 次攔截（26 次 interrupt 中約 10 次是動工前被攔）
- 步驟越權（一次鋪太廣，被迫用「先…」「只…」拉回單步）：**6 輪**
- 自行拍板業務口徑、不查 legacy，事後被逐條翻案（「你做了什麼決策」）：**3 輪**
- 需求理解偏窄（要「一次看全部」做成「一間一間找」）：**3 串**
- 主動加料（沒點名的 label/hint/section/功能）：demo **6 輪** + portfolio **3 輪**

**結構性根因（審計發現 #7）**：CLAUDE.md 寫「所有程式碼變更必須經過我確認」，但全域 `defaultMode: "auto"` 且無任何 PreToolUse gate——這條規則在 harness 層零強制，純靠模型自律，而弱模型自律不可靠。

**修法**：`rules/judgment.md` §2（問句=提問不是指令；業務語義先查 legacy 再問；默默決定=最貴的決定）。硬性 gate 屬使用者裁決項，見附錄一 #7。

### 第三名（最容易出錯）：文件宣稱的機制不存在——制度腐蝕

**現象**：文件說「會自動 X」但沒有任何東西在跑。強模型會起疑去查，弱模型會直接信文件，在壞地圖上導航。

**證據（審計實錘）**：
- `/r-dreaming` 被 README、CLAUDE.md、Learning.md、hook 共 4 處引用，**skill 不存在**——hook 超門檻時會叫使用者跑一個不存在的指令
- README 宣稱的 statusline（token/context/價格）**沒在跑**：全域 settings 指向 3 月的舊版獨立腳本
- Memory.md 「gitignored」宣稱與實況（進版控）矛盾，且 kindness 的修正**會被下次 sync 洗掉**（模板未 backport）
- README skill 清單缺 4 個實際存在的 skill；`.claude/lessons/` 空目錄殘留
- r-multi-review 依賴 `Workflow` 工具，該工具非所有環境都有，skill 無 fallback

**修法**：本次已修（見附錄一處置欄）＋ `rules/maintenance.md` §4 立規：「宣稱有自動化就當場驗證它存在」；模板管理檔只改 dotclaude、改完即 sync。

## 附錄一：審計發現清單（現況 → 修法 → 驗證指令 → 本次處置）

1. **[b] /r-dreaming 不存在**卻被 4 處引用 → 建 skill → `ls dotclaude/.claude/skills/r-dreaming`（修前：No such file）→ **✅ 本次已建**
2. **[a] Memory.md gitignore 宣稱 vs 進版控實況**（README ×3、模板 CLAUDE.md、r-handoff SKILL.md）→ 統一為「進版控」→ `cd kindness && git ls-files .claude/Memory.md`（有輸出=tracked）→ **✅ 本次已統一**
3. **[a] kindness CLAUDE.md 的「進版控」修正未 backport 模板**，下次 sync 會倒退 → backport → `diff dotclaude/.claude/CLAUDE.md kindness/.claude/CLAUDE.md`（修後：無差異）→ **✅ 本次隨 CLAUDE.md 重寫解決**
4. **[a] README skill 清單缺 r-design/r-multi-review 等 4 個** → 補齊 → `grep -c "r-design\|r-multi-review" dotclaude/README.md`（修前：0）→ **✅ 本次已補**
5. **[a] 全域 statusline 指向舊版腳本**，README 宣稱功能沒在跑 → 把 `~/.claude/settings.json` 的 statusLine.command 改成 `/Users/rudolfchen/Documents/dotclaude/.claude/statusline.sh` → `grep -A2 statusLine ~/.claude/settings.json` → **⏸ 使用者裁決**（動全域設定=紅區；一行指令可修）
6. **[a] statusline.sh 同時宣稱「住在 repo」又被 sync 進各專案**成死副本 → 從 MANAGED 移除 → `grep -n statusline dotclaude/sync.sh` → **✅ 本次已移除**
7. **[a] 「先確認再動手」harness 層零強制**（defaultMode=auto、無 PreToolUse gate）→ 選項：(a) 接受純行為約束（現狀，靠 rules 強化）(b) 加 PreToolUse hook 攔 Edit/Write 未確認即擋 → `python3 -c "import json;print(json.load(open('$HOME/.claude/settings.json'))['permissions'])"` → **⏸ 使用者裁決**（gate 會顯著增加互動成本）
8. **[b] r-multi-review 依賴 Workflow 工具無 fallback** → SKILL.md 加「無 Workflow 時用 Agent 平行 spawn」→ `grep -c "fallback\|Agent" dotclaude/.claude/skills/r-multi-review/SKILL.md` → **✅ 本次已加**

## 附錄二：痛點模式總表（跨專案合併，次數 ≥3）

| 模式 | 次數 | 對應新規則 |
|---|---|---|
| 解釋太抽象/術語不翻譯（「看不懂」） | 9+2 | judgment §5 |
| 驗證環境搞錯（build vs dev/port） | 8 | judgment §1-2 |
| 檢查/實作不完整就宣稱完成 | 7 | judgment §1-4 |
| UI 改 A 壞 B | 7 | judgment §1-2、§4 |
| 同一糾正/指令要講兩次 | 7 組 | judgment §3 |
| 搶跑（問句當指令、未收斂就動工） | ~10 | judgment §2 |
| 步驟越權（一次鋪太廣） | 6 | judgment §2、CLAUDE.md workflow |
| UI 加料（沒點名的 label/hint/section） | 6+3 | CLAUDE.md 原則 11 強化 |
| 沒對照 demo 就動手 | 6 | 專案 Wiki 層規則（demo = source of truth） |
| 調查不足，使用者手動餵事實 | 5 | dispatch §1（派工先查）＋judgment §2 |
| 修一處不修同類 | 3 | judgment §5（糾正即規格） |
| 新版型直接取代舊版（該做 tweak 切換） | 3–4 | demo 專案 Learning（專案特有） |
| 業務口徑自行拍板 | 3 | judgment §2 |
| 完工不給驗證入口 | 3 | judgment §1-3 |
| 文件/Memory 過期交接 | 2 | judgment §4（交接列） |
| 憑過時記憶答外部服務現況 | 1（高殺傷） | judgment §2（查得到就查） |
| 架構級重複實作（雙軌 controller） | 1（高殺傷） | dispatch §1（動工前掃等價實作） |

## 附錄三：使用者溝通風格校準（弱模型必讀）

1. **極短指令、單字元裁決**（go/ok/A/1/commit）：選項要給穩定編號且不重排；「next?」= 把排程主導權交給你，回覆給可挑選的候選清單。
2. **糾正即規格、不解釋原因**：一句現象（「不要閃爍」）= 硬規格，立刻套用到全部同類處；同一句第二次出現 = 你上輪的驗證有洞，先修驗證方法。
3. **疑問句是真的在問**：「merge?」「建議改嗎?」是徵詢。回答＋選項，等裁決，不動工。
4. **看得懂 > 技術正確**：結論先行、白話、表格。縮寫首現必附一句白話定義。
5. **期待驗證手段留在 repo**（「把測試固化進 repo」）：驗證腳本/測試不要跑完即丟。
