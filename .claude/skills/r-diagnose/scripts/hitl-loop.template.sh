#!/usr/bin/env bash
# Human-in-the-loop 重現腳本樣板。
# 複製本檔、改寫下方步驟、執行。agent 跑腳本，人類在自己的終端照提示操作。
#
# Usage:
#   bash hitl-loop.template.sh
#
# 兩個 helper：
#   step "<指示>"              → 顯示指示，等 Enter
#   capture VAR "<問題>"       → 顯示問題，把回答讀進 VAR
#
# 結尾以 KEY=VALUE 印出擷取到的值，供 agent 解析。
# capture 會把值印回終端讓 agent 讀到，所以只用它擷取「觀察結果」；
# 登入之類會帶憑證的動作留給 step，不要 capture。

set -euo pipefail

step() {
  printf '\n>>> %s\n' "$1"
  read -r -p "    [完成後按 Enter] " _
}

capture() {
  local var="$1" question="$2" answer
  printf '\n>>> %s\n' "$question"
  read -r -p "    > " answer
  printf -v "$var" '%s' "$answer"
}

# --- 以下改寫 -----------------------------------------------------------

step "打開 http://localhost:3000 並登入。"

capture ERRORED "點『匯出』按鈕。有噴錯嗎？(y/n)"

capture ERROR_MSG "貼上錯誤訊息（沒有就填 none）："

# --- 以上改寫 -----------------------------------------------------------

printf '\n--- Captured ---\n'
printf 'ERRORED=%s\n' "$ERRORED"
printf 'ERROR_MSG=%s\n' "$ERROR_MSG"
