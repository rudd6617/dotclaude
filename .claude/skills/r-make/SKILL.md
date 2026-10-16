---
name: r-make
description: |
  Create or update a project's root Makefile as a thin, guarded front door to the
  commands it already has (pnpm / uv / npm / docker compose). Use when the user asks
  for make commands, an ops cheat sheet, or "one command" for dev / check / deploy.
argument-hint: "[what the Makefile should cover]"
---

給專案根目錄寫（或更新）一份 Makefile：**一個入口、同一組名字、該擋的地方擋住**。它是現有指令的薄包裝，不是新的建置系統。

## 動工前先查（每項都寫進提案）

| 要查的 | 去哪查 | 決定什麼 |
|---|---|---|
| 現有指令 | `package.json` scripts、`pyproject.toml`、`compose.yaml`／`docker-compose.yml`、既有腳本（`*.sh`、`*.ps1`） | 每個 target 呼叫哪一條 |
| 指令寫在哪份文件 | `.claude/Wiki.md` 的 Commands 段、`docs/deployment.md` 或 README——**照專案現況，不自己指定** | 完工後改哪份 |
| 正式站從哪個目錄跑 | 問使用者或查部署文件；跟開發目錄比 | 要不要 `DEPLOY_DIR` 守衛 |
| 正式站怎麼更新 | 從工作目錄建？`git pull` 後建？ | deploy 前的關卡與「髒樹」檢查的範圍 |
| compose 專案名 | compose 檔裡的 `name:` | 開發目錄跑 `up` 會不會蓋掉正式容器 |

## 規則

1. **薄包裝**：每個 target 只呼叫專案已有的指令，不寫自己的邏輯，一件事只有一個真相來源。把容易踩坑的旗標與路徑寫死在 target 裡正是重點（`uv run --with pytest`、`ruff check app tests` 而不是 `.`——掃 `.` 會掃進 `.venv`），那仍算「現有指令」。
2. **只打 `make` ＝說明**：`.DEFAULT_GOAL := help`；每個 target 同一行寫 `## 一句中文說明`，help 用 awk 解析印出；用 `##@ 分組名` 分段（開發／驗證／正式站／資料庫／維運）。
3. **共用字彙**，同一個詞在每個 repo 意思一樣；專案只挑用得到的，可另加自己的：

   | 名字 | 意思 |
   |---|---|
   | `setup` | 裝相依（`pnpm install`、`uv sync`、`npm ci`） |
   | `dev` | 起本地開發 |
   | `test`／`lint` | 單跑測試／lint |
   | `check` | 完工前全套驗證（typecheck＋lint＋測試），任一步失敗就停 |
   | `deploy` | 更新正式站（含前後關卡，見規則 4） |
   | `up`／`restart` | 只起／只重啟正式容器，不更新程式 |
   | `status`／`logs` | 容器狀態／追日誌（`S=<服務>` 換服務） |
   | `migrate`／`psql` | 套 migration／開 SQL（有資料庫才放） |
   | `backup`／`backups` | 立刻備份一次／列出現有備份 |

4. **防呆照風險加，不全套照抄**：
   - **目錄守衛**：開發與正式在同一台機器、不同目錄時，每個正式站 target 先比 `$(CURDIR)` 與 `DEPLOY_DIR ?= <正式目錄>`，不同就拒絕。compose 寫死 `name:` 時這條必加——從開發目錄 `up` 會把正式容器換成掛開發目錄的版本。同一目錄就不放。
   - **髒樹檢查只看專案宣告的原始碼路徑**（`SRC_PATHS := server web/src`），不看整棵樹：有些系統會合法地把設定寫回部署目錄。只有「正式站從工作目錄建」時才需要；從 `git pull --ff-only` 更新的，pull 本身在衝突時就會停。
   - **deploy 前的關卡由專案定**：開發目錄能跑完 `check` 就讓 deploy 先跑它；部署目錄沒有開發相依時，關卡是「推上去前在開發端跑過 `check`」，deploy 不硬跑。**兩種都要有部署後的健康檢查**（`status` 或打 health 端點），失敗就報錯。
   - **會覆蓋資料的 target 要輸入 `yes`**，並在動手前後各印一次筆數或大小。
   - **連正式庫的 SQL 一律唯讀**（Postgres 用 `PGOPTIONS='-c default_transaction_read_only=on'`）。
5. **必要參數缺了就停**，印出一行用法：`make admin LOGIN=… NAME=… EMAIL=…`。
6. **刻意不包**：還原正式庫、一打錯就不可逆的動作、要在已登入瀏覽器裡做的步驟——維持文件裡的手動步驟，Makefile 的 help 末尾可以提一句去哪看。
7. **既有的其他入口不動**（`run.ps1`、`*.sh`）：不刪、不改寫。Makefile 以 macOS／Linux 為準。
8. 寫法：所有 target 列進 `.PHONY`；配方行用 tab；需要整段一起跑的（`cd` 後再執行、`read` 確認）寫成一行並用 `set -e;` 開頭，不加 `.ONESHELL`。

## 流程

1. 照「動工前先查」查完，列出 target 表（名字／做什麼／呼叫哪條指令／有哪些防呆），交使用者確認。這是 ≥2 檔變更（Makefile＋指令文件），照 `AGENTS.md` 原則 7 先問要不要 worktree。
2. 寫 Makefile。
3. 改指令文件：每列換成 make 指令，原本的完整指令留在旁邊（make 壞了還有路走）。
4. 驗證（全部要跑，結果貼進回報）：
   - `make` 印出 help，每個 target 都有說明。
   - `make check` 跑完。
   - 至少一個唯讀 target（`status`、`backups`、`logs` 開幾秒）。
   - **每一道防呆都實際觸發一次拒絕**：缺參數、從錯的目錄跑正式站 target、原始碼路徑有改動時 `deploy`、`yes` 打別的字。只看到它放行，不算驗過防呆。
   - 不跑會真的改正式站的 target（`deploy`、`backup` 以外的寫入），除非使用者當下要求。

## 範例骨架

（awk 用 `$NF`／`$(NF-1)` 而不是錢號接數字：skill 帶參數呼叫時，錢號接數字會被換成參數，骨架就壞了。）

```make
.DEFAULT_GOAL := help
.PHONY: help dev check deploy status logs

DEPLOY_DIR ?= $(HOME)/services/myapp
SRC_PATHS  := app web/src

help: ## 列出所有指令
	@awk 'BEGIN{FS=":.*## "} /^##@/{printf "\n%s\n",substr($$NF,5)} /^[a-z-]+:.*## /{printf "  make %-12s %s\n",$$(NF-1),$$NF}' $(MAKEFILE_LIST)

##@ 正式站
guard-deploy-dir:
	@[ "$(CURDIR)" = "$(DEPLOY_DIR)" ] || { echo "要在 $(DEPLOY_DIR) 跑，現在在 $(CURDIR)"; exit 1; }

deploy: guard-deploy-dir ## 更新正式站並確認健康
	git pull --ff-only
	docker compose up -d --build
	@$(MAKE) --no-print-directory status
```
