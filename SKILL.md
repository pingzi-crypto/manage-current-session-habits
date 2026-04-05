---
name: manage-current-session-habits
description: Scan the current Codex conversation for user habit phrase candidates and confirm add/remove/list/ignore actions for the user-habit-pipeline backend. Use when the user says things like `扫描这次会话里的习惯候选`, `根据这次会话建议我新增哪些用户习惯短句`, `添加第1条`, `把第1条加到 session_close 场景`, `忽略第1条`, `删除用户习惯短句`, or asks to inspect current user habit phrases from inside the current Codex app thread.
---

# Manage Current Session Habits

Use this skill to keep the user inside the current Codex conversation while driving the configured `user-habit-pipeline` backend.

If the configured backend checkout includes `docs/codex-current-session-contract.md`, treat that backend document as the upstream source of truth for the current-session bridge contract and keep this skill aligned to it.

## Workflow

1. Treat the current conversation itself as the source transcript.
2. Do not ask the user to locate Codex session files on disk.
3. For suggestion scans, build a concise role-prefixed transcript from the visible thread context and pass it to the wrapper script in this repository.
4. For follow-up confirmations such as `添加第1条`, reuse the latest local suggestion cache and do not ask for the transcript again unless the cache is missing.
5. If the wrapper script reports missing local config, tell the user to refresh the install with `scripts/install-skill.ps1 -BackendRepoPath <path>`.
6. Never ask the user to inspect or guess Codex private thread-storage paths.

## Response Priority

When the bridge returns successful JSON:

1. If `assistant_reply_markdown` is present, use it as the primary user-facing reply.
2. If `suggested_follow_ups` is present, surface those prompts directly instead of inventing different wording.
3. If `next_step_assessment` is present, honor it instead of overriding the bridge's stop/continue judgment with a new improvised suggestion.
4. Only synthesize your own wording when the bridge did not provide presentation fields or when a tiny clarification is required for local context.

Do not restate the full raw JSON unless the user explicitly asks for it.
Do not replace backend wording with a looser paraphrase unless the backend reply is clearly insufficient for the current turn.

## Low-ROI Stop Rule

If the next step is clearly low-return relative to the user's likely effort:

1. Say that directly.
2. Offer a one-word stop option such as `停` or `跳过`.
3. Tell the user you can switch to a higher-value TODO after that stop word.

Do this instead of pushing more polish or low-signal follow-up work.
Keep the wording short and decisive.

Before proposing a next step, run this quick checklist:

1. Is the next step delivering real user value or just extra polish?
2. Will it require manual commands, extra review, or attention that feels disproportionate?
3. Is there a higher-value TODO already available?
4. If yes, should you offer `停` or `跳过` instead of pushing forward?

If the checklist comes out low ROI, prefer the stop template over another procedural suggestion.

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
   Prefer the backend-provided `assistant_reply_markdown` and `suggested_follow_ups` fields when present.
   If the bridge also returns `next_step_assessment`, preserve that direction in the visible reply.
6. End the message with natural follow-up prompts the user can say next, such as `添加第1条`, `把第2条加到 session_close 场景`, or `忽略第3条`.
7. Do not auto-add anything during the scan step.

Preferred scan reply behavior:

- first choice: return `assistant_reply_markdown` directly
- optional extra line: add one short sentence only if you need to connect the reply to the immediate thread context
- never auto-append unrelated operational advice after a successful scan

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
Prefer the backend-provided `assistant_reply_markdown` when present so the confirmation wording stays consistent with the bridge output.

Preferred apply reply behavior:

- first choice: return `assistant_reply_markdown` directly
- if the backend also returned `suggested_follow_ups`, prefer those follow-ups over newly invented ones
- if the backend returned `next_step_assessment.level = low_roi`, do not append more busywork after the bridge already offered a stop path
- do not imply the phrase will execute any downstream workflow automatically

## Other Requests

This skill can also forward other lightweight management prompts without leaving the conversation, for example:

```powershell
& .\scripts\invoke-backend.ps1 -Request "列出用户习惯短句"
& .\scripts\invoke-backend.ps1 -Request "删除用户习惯短句: 收尾一下"
```

Use the bridge CLI for these requests so the same prompt parser remains the source of truth.

For `list`, `remove`, and `ignore` requests, follow the same rule:

- prefer `assistant_reply_markdown` when present
- otherwise keep the reply short, explicit, and action-oriented
- if the wrapper surfaces a bridge contract error such as conflicting thread sources or missing thread input for a scan, report that error directly instead of paraphrasing it into a looser suggestion
