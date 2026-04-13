# manage-current-session-habits v0.3.4

`manage-current-session-habits` is a Codex skill for scanning the current conversation for user habit phrase candidates and confirming them in place through `user-habit-pipeline`.

This release turns the skill's install surface into a real dual-entrypoint path: Windows users can keep using PowerShell, while macOS and Linux users now get native shell entrypoints backed by the same shared implementation.

## Highlights

- added native POSIX entrypoints for install, uninstall, bootstrap, backend invocation, and smoke validation
- moved install and wrapper logic onto shared Node-based core scripts instead of maintaining separate platform-specific implementations
- kept existing Windows `ps1` entrypoints as thin wrappers so current usage does not break
- updated the skill README, lifecycle checklist, release checklist, runbook, and CI workflow to validate the public Windows and POSIX paths
- revalidated package-mode and repo-mode smoke against backend `user-habit-pipeline v0.7.8`

## Why This Release Exists

Before `v0.3.4`, the repository already claimed cross-platform intent, but the most visible public install path still centered on PowerShell entrypoints.

That left a practical gap:

- Windows users had a direct path
- macOS and Linux users could still benefit from the shared logic, but the public install surface was not shaped around their default shell
- CI validated cross-platform behavior, but the external entrypoints were still more Windows-oriented than they needed to be

This release closes that gap by making the public skill surface match the project's actual cross-platform direction.

## Typical Prompts

- `扫描这次会话里的习惯候选`
- `添加第1条`
- `忽略第1条`
- `列出用户习惯短句`

## Product Boundary

This skill does:

- scan visible conversation context
- forward requests to the configured `user-habit-pipeline` backend
- keep explicit user confirmation for durable changes

This skill does not:

- auto-save habits during scan-only flows
- execute downstream workflows
- require users to locate private transcript files on disk

## Validation

This release was validated with:

- backend `user-habit-pipeline` `npm run release-check`
- skill PowerShell smoke: `pwsh -File .\scripts\ci-smoke.ps1 -BackendRepoPath E:\user-habit-pipeline`
- skill POSIX smoke: `bash ./scripts/ci-smoke.sh --backend-repo-path /e/user-habit-pipeline`
- direct Windows wrapper chain validation for `install.ps1 -> invoke-backend.ps1 -> uninstall.ps1`

## Compatibility Note

Current intended backend baseline for this skill release:

- `user-habit-pipeline v0.7.8`
