# Backend Contract

## Backend Location

This skill currently operates the backend in:

- `E:\user-habit-pipeline`

The skill depends on:

- `E:\user-habit-pipeline\src\codex-session-habits-cli.js`
- `E:\user-habit-pipeline\src\manage-habits-cli.js`

## Current Scan Command

Use this when the user wants to scan the current Codex conversation:

```powershell
$transcript | node E:\user-habit-pipeline\src\codex-session-habits-cli.js --request "扫描这次会话里的习惯候选" --thread-stdin
```

The transcript should be built from the current visible thread context and should include role prefixes like:

- `user:`
- `assistant:`
- `system:`
- `tool:`

## Current Follow-Up Commands

Use these after a successful scan:

```powershell
node E:\user-habit-pipeline\src\codex-session-habits-cli.js --request "添加第1条"
node E:\user-habit-pipeline\src\codex-session-habits-cli.js --request "把第1条加到 session_close 场景"
```

The bridge CLI reuses the latest local suggestion cache, so these requests do not need transcript input unless the cache is missing.

## Local Install Target

The preferred installed location is:

- `C:\Users\pz\.codex\skills\manage-current-session-habits`

Use the install script in [install-skill.ps1](../scripts/install-skill.ps1) to point that location at this repository.
