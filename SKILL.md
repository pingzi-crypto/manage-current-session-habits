---
name: manage-current-session-habits
description: Scan the current Codex conversation for user habit phrase candidates and confirm add/remove/list actions for the user-habit-pipeline backend. Use when the user says things like `扫描这次会话里的习惯候选`, `根据这次会话建议我新增哪些用户习惯短句`, `添加第1条`, `把第1条加到 session_close 场景`, `删除用户习惯短句`, or asks to inspect current user habit phrases from inside the current Codex app thread.
---

# Manage Current Session Habits

Use this skill to keep the user inside the current Codex conversation while driving the `user-habit-pipeline` backend at `E:\user-habit-pipeline`.

Read [backend-contract.md](./references/backend-contract.md) when you need the exact bridge command contract or install layout.

## Workflow

1. Treat the current conversation itself as the source transcript.
2. Do not ask the user to locate Codex session files on disk.
3. For suggestion scans, build a concise role-prefixed transcript from the visible thread context and pass it to the bridge CLI.
4. For follow-up confirmations such as `添加第1条`, reuse the latest local suggestion cache and do not ask for the transcript again unless the cache is missing.

## Scan The Current Conversation

When the user asks to scan the current conversation for habit candidates:

1. Gather only the relevant turns from the current thread.
2. Keep role prefixes such as `user:` and `assistant:`.
3. Prefer a focused excerpt containing explicit phrase definitions, user corrections, repeated short phrases, and nearby assistant clarifications.
4. Run:

```powershell
$transcript = @'
user: 以后我说“收尾一下”就是 close_session
assistant: 收到。
user: 收尾一下
'@
$transcript | node E:\user-habit-pipeline\src\codex-session-habits-cli.js --request "扫描这次会话里的习惯候选" --thread-stdin
```

5. Summarize the returned candidates in plain language: candidate id, phrase, suggested intent if any, confidence, and risk flags.
6. Do not auto-add anything during the scan step.

## Confirm A Candidate

When the user explicitly chooses a candidate, run the same natural-language request through the bridge CLI:

```powershell
node E:\user-habit-pipeline\src\codex-session-habits-cli.js --request "添加第1条"
node E:\user-habit-pipeline\src\codex-session-habits-cli.js --request "把第1条加到 session_close 场景"
```

If the candidate is review-only and the user supplies meaning explicitly, keep that override in the request:

```powershell
node E:\user-habit-pipeline\src\codex-session-habits-cli.js --request "把第1条加到 session_close 场景; intent=close_session"
```

If the cache is missing, tell the user to scan the current conversation first.

## Other Requests

This skill can also forward other lightweight management prompts without leaving the conversation, for example:

```powershell
node E:\user-habit-pipeline\src\codex-session-habits-cli.js --request "列出用户习惯短句"
node E:\user-habit-pipeline\src\codex-session-habits-cli.js --request "删除用户习惯短句: 收尾一下"
```

Use the bridge CLI for these requests so the same prompt parser remains the source of truth.
