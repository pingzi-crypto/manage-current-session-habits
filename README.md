# manage-current-session-habits

Codex skill for scanning the current conversation for user habit phrase candidates and confirming them in place through `user-habit-pipeline`.

If you want habit management to happen inside the normal Codex thread instead of through transcript-file hunting or manual backend commands, this is the thin integration layer for that flow.

![README short demo](assets/readme-short-demo.gif)

## Quick Start

Fastest install from any PowerShell 7 window:

```powershell
$bootstrap = Join-Path $env:TEMP "manage-current-session-habits-bootstrap.ps1"
Invoke-WebRequest https://raw.githubusercontent.com/pingzi-crypto/manage-current-session-habits/main/bootstrap-install.ps1 -OutFile $bootstrap
& $bootstrap
```

Prerequisites for this path:
`git`, `pwsh`, and `node` must be available on `PATH`.

This clones or refreshes the skill into a default local checkout, installs it into Codex, and runs the smoke check.
It prefers the public HTTPS GitHub clone path and automatically retries with SSH when HTTPS clone is blocked but SSH access is available.

If you prefer to inspect the repository first, use the manual path:

1. Clone this repository.
2. Make sure `git`, `pwsh`, and `node` are available on `PATH`.
3. Run:

```powershell
& .\install.ps1
```

4. In a normal Codex conversation, say:

- `扫描这次会话里的习惯候选`
- `添加第1条`
- `忽略第1条`
- `列出用户习惯短句`

This installs the skill and runs the smoke check in one step.
If the smoke check passes, the current-session bridge is installed correctly.

If you want to keep using a local backend checkout instead of the published npm package, install with:

```powershell
& .\install.ps1 -BackendRepoPath /path/to/user-habit-pipeline
```

If you want bootstrap mode but with an explicit local checkout path:

```powershell
$bootstrap = Join-Path $env:TEMP "manage-current-session-habits-bootstrap.ps1"
Invoke-WebRequest https://raw.githubusercontent.com/pingzi-crypto/manage-current-session-habits/main/bootstrap-install.ps1 -OutFile $bootstrap
& $bootstrap -InstallRoot "$HOME/.codex/repos"
```

If you only want a preview of what would be installed:

```powershell
& .\install.ps1 -CheckOnly
```

Non-Windows note:
the install and check scripts now support PowerShell 7 on macOS and Linux, but the repository is currently only smoke-verified on Windows.

## What It Does

- scans the current visible Codex thread for habit candidates
- lets the user confirm or ignore candidates with short follow-up prompts
- lists or removes already saved user habit phrases
- keeps the interaction inside the conversation UI

Typical flow:

```text
user: 扫描这次会话里的习惯候选
assistant: 这次会话共发现 1 条习惯候选……
user: 添加第1条
assistant: 已添加用户习惯短句「收尾一下」……
user: 停
assistant: 当前这个方向先停。
```

## Product Boundary

This skill does not auto-save habits during scan-only flows.
It does not execute downstream workflow actions.
It forwards current-thread context to the backend, and the user still explicitly confirms durable changes.

## More Details

- [bootstrap-install.ps1](/E:/manage-current-session-habits/bootstrap-install.ps1)
- [install.ps1](/E:/manage-current-session-habits/install.ps1)
- [SKILL.md](/E:/manage-current-session-habits/SKILL.md)
- [scripts/install-skill.ps1](/E:/manage-current-session-habits/scripts/install-skill.ps1)
- [scripts/check-install.ps1](/E:/manage-current-session-habits/scripts/check-install.ps1)
