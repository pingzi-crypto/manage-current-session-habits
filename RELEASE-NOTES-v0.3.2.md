# manage-current-session-habits v0.3.2

`manage-current-session-habits` is a Codex skill for scanning the current conversation for user habit phrase candidates and confirming them in place through `user-habit-pipeline`.

This release is a small outward-facing refresh rather than a feature rewrite.
It updates the public skill surface so the repository, install path, and release materials better match how the skill is now meant to be discovered and used.

## Highlights

- refreshed the public README positioning around Codex, current-session scanning, user habit memory, and in-thread confirmation
- tightened the skill description so the trigger surface is easier for Codex and users to understand
- updated skill-side release checklist and runbook baselines to the current backend `user-habit-pipeline v0.7.0` contract
- kept the install flow focused on the normal Codex conversation UI instead of transcript-file hunting or manual backend commands

## Why This Release Exists

Since `v0.3.1`, the biggest change has been public clarity rather than runtime behavior.

The repository now does a better job of explaining:

- what the skill is
- who it is for
- which prompts should trigger it
- what the backend compatibility baseline is today

That makes the skill easier to install, easier to recognize, and easier to recommend without changing its explicit-confirmation model.

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
- skill `install.ps1 -CheckOnly`
- skill `scripts/check-install.ps1 -SmokeTest`
- skill repo-override preview through `install.ps1 -BackendRepoPath <path> -CheckOnly`

## Compatibility Note

Current intended backend baseline for this skill release:

- `user-habit-pipeline v0.7.0`
