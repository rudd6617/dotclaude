---
name: r-review
description: |
  Code review following project standards. Use when reviewing code, reading unfamiliar code,
  or when the user asks for a review or code quality assessment.
argument-hint: "[file or directory]"
---

Review the code at $ARGUMENTS following this structure.

無 `$ARGUMENTS` 時，預設審查當前 git diff（`git diff HEAD`；無未提交變更則退回 `git diff main...HEAD`）。

## 1. 品味評分

Give exactly one rating with a one-line justification:
- 🟢 好品味 — clean, minimal, well-structured
- 🟡 湊合 — works but has unnecessary complexity
- 🔴 需重寫 — fundamental issues

## 2. 致命問題

List any of these found (or explicitly state "none"):
- 邏輯錯誤
- 資源洩漏
- 安全漏洞
- 破壞性變更

## 3. 可消除的複雜性

Identify:
- 不必要的抽象
- 重複代碼
- 超過 3 層的嵌套

## 4. 數據結構合理性

Evaluate:
- 所有權是否清晰
- 生命週期是否合理
- 是否有不必要的複製或轉換
