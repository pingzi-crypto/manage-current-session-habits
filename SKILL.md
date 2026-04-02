---
name: manage-current-session-habits
description: Scan the current Codex conversation for user habit phrase candidates and confirm add/remove/list/ignore actions for the user-habit-pipeline backend. Use when the user says things like `扫描这次会话里的习惯候选`, `根据这次会话建议我新增哪些用户习惯短句`, `添加第1条`, `把第1条加到 session_close 场景`, `忽略第1条`, `删除用户习惯短句`, or asks to inspect current user habit phrases from inside the current Codex app thread.
---

# Manage Current Session Habits

Use this skill to keep the user inside the current Codex conversation while driving the configured `user-habit-pipeline` backend.

Read [backend-contract.md](./references/backend-contract.md) when you need the exact bridge command contract or install layout.
Read [interaction-patterns.md](./references/interaction-patterns.md) when you need the response format for scan/apply/list flows.

## Workflow

1. Treat the current conversation itself as the source transcript.
2. Do not ask the user to locate Codex session files on disk.
3. For suggestion scans, build a concise role-prefixed transcript from the visible thread context and pass it to the wrapper script in this repository.
4. For follow-up confirmations such as `添加第1条`, reuse the latest local suggestion cache and do not ask for the transcript again unless the cache is missing.
5. If the wrapper script reports missing local config, tell the user to refresh the install with `scripts/install-skill.ps1 -BackendRepoPath <path>`.

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
& .\scripts\invoke-backend.ps1 -Request "扫描这次会话里的习惯候选" -Transcript $transcript
```

5. Summarize the returned candidates in plain language: candidate id, phrase, suggested intent if any, confidence, and risk flags.
6. End the message with natural follow-up prompts the user can say next, such as `添加第1条`, `把第2条加到 session_close 场景`, or `忽略第3条`.
7. Do not auto-add anything during the scan step.

## Confirm A Candidate

When the user explicitly chooses a candidate, run the same natural-language request through the bridge CLI:

```powershell
& .\scripts\invoke-backend.ps1 -Request "添加第1条"
& .\scripts\invoke-backend.ps1 -Request "把第1条加到 session_close 场景"
& .\scripts\invoke-backend.ps1 -Request "忽略第1条"
```

If the candidate is review-only and the user supplies meaning explicitly, keep that override in the request:

```powershell
& .\scripts\invoke-backend.ps1 -Request "把第1条加到 session_close 场景; intent=close_session"
```

If the cache is missing, tell the user to scan the current conversation first.
After a successful apply, explicitly echo the saved phrase, intent, scenario, and confidence.

## Other Requests

This skill can also forward other lightweight management prompts without leaving the conversation, for example:

```powershell
& .\scripts\invoke-backend.ps1 -Request "列出用户习惯短句"
& .\scripts\invoke-backend.ps1 -Request "删除用户习惯短句: 收尾一下"
```

Use the bridge CLI for these requests so the same prompt parser remains the source of truth.
