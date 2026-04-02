# Backend Contract

## Backend Location

This skill reads its machine-local backend path from:

- `config/local-config.json`

The install script writes that file and currently stores:

- `backend_repo_path`
- `bridge_cli_path`

Example tracked template:

- `config/example.local-config.json`

Use [install-skill.ps1](../scripts/install-skill.ps1) to generate or refresh the real local config.
Use [check-install.ps1](../scripts/check-install.ps1) to verify the local install and optionally run a wrapper smoke test.

Helpful install modes:

- `-CheckOnly` resolves paths and reports what would happen without changing files
- `-ForceRelink` recreates the installed junction even if it already points at the current repo

The install script resolves the backend repo in this order:

1. `-BackendRepoPath`
2. `USER_HABIT_PIPELINE_REPO`
3. a sibling folder named `user-habit-pipeline`

## Current Scan Command

Use this when the user wants to scan the current Codex conversation:

```powershell
$transcript | & .\scripts\invoke-backend.ps1 -Request "扫描这次会话里的习惯候选" -ThreadStdin
```

For Codex shell calls, prefer the more stable explicit parameter form:

```powershell
$transcript = @'
user: 以后我说“收尾一下”就是 close_session
assistant: 收到。
user: 收尾一下
'@
& .\scripts\invoke-backend.ps1 -Request "扫描这次会话里的习惯候选" -Transcript $transcript
```

The transcript should be built from the current visible thread context and should include role prefixes like:

- `user:`
- `assistant:`
- `system:`
- `tool:`

## Current Follow-Up Commands

Use these after a successful scan:

```powershell
& .\scripts\invoke-backend.ps1 -Request "添加第1条"
& .\scripts\invoke-backend.ps1 -Request "把第1条加到 session_close 场景"
```

The bridge CLI reuses the latest local suggestion cache, so these requests do not need transcript input unless the cache is missing.

## Local Install Target

The preferred installed location is:

- `%CODEX_HOME%\skills\manage-current-session-habits`
- or `%USERPROFILE%\.codex\skills\manage-current-session-habits` when `CODEX_HOME` is unset

Use the install script in [install-skill.ps1](../scripts/install-skill.ps1) to point that location at this repository and to refresh `config/local-config.json`.
