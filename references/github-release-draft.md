# Suggested GitHub Release Title

`manage-current-session-habits v0.1.0`

# Suggested GitHub Release Body

`manage-current-session-habits` packages the current-thread habit flow into a shareable Codex skill.

It is built for users who prefer to stay inside the normal Codex conversation UI instead of hunting for transcript files or stitching together backend commands by hand.

With this release, you can:

- scan the current Codex thread for habit candidates
- review explicit phrase definitions and repeated shorthand
- confirm or ignore candidates with short follow-up prompts such as `添加第1条` and `忽略第1条`
- list or remove saved user habit phrases
- stop low-value cleanup quickly with `停`

## What is included

- Codex skill entry through `SKILL.md` and `agents/openai.yaml`
- portable local install flow through `scripts/install-skill.ps1`
- install verification and smoke check through `scripts/check-install.ps1 -SmokeTest`
- backend alignment with the current-session bridge contract in `user-habit-pipeline`
- outward-facing README quick start and embedded demo GIF
- release, publishing, and demo-material templates for future sharing

## Why this exists

The goal is simple: let the user stay in the active Codex thread and say things like:

- `扫描这次会话里的习惯候选`
- `添加第1条`
- `忽略第1条`
- `列出用户习惯短句`

instead of manually locating conversation files or invoking backend scripts directly.

## Important product boundary

This skill does not auto-save habits during scan-only flows.
It does not execute downstream workflow actions.
It forwards visible current-thread context into the backend, and the user still explicitly confirms durable changes.

## Install

```powershell
& .\scripts\install-skill.ps1 -BackendRepoPath <path-to-user-habit-pipeline>
& .\scripts\check-install.ps1 -SmokeTest
```

## Suggested release assets

- attach the README demo GIF: `assets/readme-short-demo.gif`
- reuse outward-facing copy from `references/publishing-kit.md`
- reuse the recording checklist from `references/demo-material-requirements.md`

## Optional closing paragraph

This is the first public packaging pass for the current-session habit flow. It focuses on natural in-thread UX, explicit confirmation, portable install behavior, and lightweight release validation rather than broad workflow automation.
