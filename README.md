# manage-current-session-habits

Codex skill for scanning the current Codex conversation for habit phrase candidates and confirming additions into the `user-habit-pipeline` overlay.

## What This Skill Does

This skill is a thin Codex-app integration layer.

It is designed for the flow where the user wants to stay inside the current conversation and say things like:

- `扫描这次会话里的习惯候选`
- `根据这次会话建议我新增哪些用户习惯短句`
- `添加第1条`
- `把第1条加到 session_close 场景`
- `列出用户习惯短句`
- `删除用户习惯短句: 收尾一下`

The skill itself does not implement habit interpretation logic.
It delegates that work to the backend in `E:\user-habit-pipeline`.

## Repository Layout

- [SKILL.md](/E:/manage-current-session-habits/SKILL.md): skill instructions loaded by Codex
- [agents/openai.yaml](/E:/manage-current-session-habits/agents/openai.yaml): UI-facing skill metadata
- [references/backend-contract.md](/E:/manage-current-session-habits/references/backend-contract.md): backend command contract and install path
- [scripts/install-skill.ps1](/E:/manage-current-session-habits/scripts/install-skill.ps1): local install helper for Codex skill discovery

## Backend Dependency

This skill currently assumes the backend project lives at:

- `E:\user-habit-pipeline`

It calls:

- `E:\user-habit-pipeline\src\codex-session-habits-cli.js`

That bridge CLI forwards prompt-style requests into the existing `manage-habits` backend and reuses the latest cached suggestion snapshot for short follow-up confirmations.

## Local Install

Install or refresh the Codex skill entry with:

```powershell
& E:\manage-current-session-habits\scripts\install-skill.ps1
```

This creates or refreshes:

- `C:\Users\pz\.codex\skills\manage-current-session-habits`

as a junction pointing at this repository.

## Typical Flow

1. In a Codex conversation, ask to scan the current session for habit candidates.
2. The skill builds a role-prefixed transcript from visible thread context.
3. The skill pipes that transcript into the bridge CLI in `user-habit-pipeline`.
4. The backend returns reviewable candidates without auto-writing new rules.
5. The user explicitly confirms a candidate with a short follow-up prompt such as `添加第1条`.

## Notes

- The source of truth for active habit rules remains the user overlay managed by `user-habit-pipeline`.
- This repository intentionally stays small and Codex-facing.
- If the backend path changes, update [SKILL.md](/E:/manage-current-session-habits/SKILL.md) and [references/backend-contract.md](/E:/manage-current-session-habits/references/backend-contract.md) together.
