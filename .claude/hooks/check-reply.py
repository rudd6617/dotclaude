#!/usr/bin/env python3
"""Stop hook: enforce the language rule that text alone did not hold, and nudge a handoff.

1. Language (AGENTS.md "Language"): a reply that is mostly English is sent back for a rewrite.
2. Long session: once context passes 200k tokens, tell the user to hand off (user-only
   message; it does not continue the turn).

A blocked reply is retried once: when stop_hook_active is true the check is skipped.

No line-count check on purpose: replayed over a month of transcripts, replies the user
accepted and replies the user called unreadable had the same length distribution.
"""
import json
import os
import re
import sys
import tempfile

MAX_EN_WORDS = 80          # observed: bad replies 290-580 English words, good ones <= 51
NUDGE_START = 200_000      # context tokens
NUDGE_STEP = 100_000
TRANSCRIPT_TAIL_BYTES = 8_000_000


def prose(message):
    """The reply without code: fenced blocks and inline code are exempt from the rule."""
    without_fences = re.sub(r"```.*?```", "", message, flags=re.S)
    return re.sub(r"`[^`\n]*`", "", without_fences)


def language_problem(text):
    en_words = len(re.findall(r"[A-Za-z]{3,}", text))
    zh_chars = len(re.findall(r"[一-鿿]", text))
    if en_words < MAX_EN_WORDS or zh_chars >= en_words:
        return None
    return (
        f"這則回覆主要是英文（{en_words} 個英文詞、{zh_chars} 個中文字）。"
        "AGENTS.md 規定給使用者看的文字一律用繁體中文。"
        "請把整則改寫成繁體中文再送出；程式碼、路徑、指令維持原樣。"
    )


def context_tokens(transcript_path):
    """Context size of the latest main-thread assistant turn, 0 when unknown."""
    if not transcript_path or not os.path.isfile(transcript_path):
        return 0
    with open(transcript_path, "rb") as f:
        f.seek(max(0, os.path.getsize(transcript_path) - TRANSCRIPT_TAIL_BYTES))
        tail = f.read().decode("utf-8", "replace")
    for line in reversed(tail.splitlines()):
        if '"usage"' not in line:
            continue
        try:
            entry = json.loads(line)
        except json.JSONDecodeError:
            continue  # first line of the tail may be cut mid-record
        if entry.get("type") != "assistant" or entry.get("isSidechain"):
            continue
        usage = entry["message"].get("usage") or {}
        return sum(usage.get(k, 0) for k in (
            "input_tokens", "cache_read_input_tokens", "cache_creation_input_tokens"))
    return 0


def handoff_nudge(session_id, tokens):
    """One message per 100k band, so a long session is not nagged on every stop."""
    if tokens < NUDGE_START:
        return None
    band = (tokens - NUDGE_START) // NUDGE_STEP
    state = os.path.join(tempfile.gettempdir(), f"claude-handoff-nudge-{session_id}")
    if os.path.isfile(state) and int(open(state).read() or -1) >= band:
        return None
    with open(state, "w") as f:
        f.write(str(band))
    return (
        f"[handoff] 這個對話已經用了約 {tokens // 10_000} 萬 token。"
        "對話越長，回覆越容易變英文、變難懂。建議現在跑 /r-handoff，然後 /clear。"
    )


def main():
    event = json.load(sys.stdin)
    if not event.get("stop_hook_active"):
        text = prose(event.get("last_assistant_message") or "")
        problem = language_problem(text)
        if problem:
            print(json.dumps({"decision": "block", "reason": problem}, ensure_ascii=False))
            return
    nudge = handoff_nudge(event.get("session_id", ""), context_tokens(event.get("transcript_path")))
    if nudge:
        print(json.dumps({"systemMessage": nudge}, ensure_ascii=False))


if __name__ == "__main__":
    main()
