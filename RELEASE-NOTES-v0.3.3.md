# manage-current-session-habits v0.3.3

`manage-current-session-habits` is a Codex skill for scanning the current conversation for user habit phrase candidates and confirming them in place through `user-habit-pipeline`.

This release aligns the skill's public install and release surface with the backend's newer current-session starter path instead of leaving the skill documentation anchored to an older backend baseline.

## Highlights

- updated the skill release baseline to `user-habit-pipeline v0.7.4`
- aligned skill-side release docs to the backend's packaged `--host codex` starter path
- kept the skill install surface focused on the in-thread scan / apply flow instead of transcript-file hunting
- revalidated package-mode install preview and installed wrapper smoke against the current backend

## Why This Release Exists

Since `v0.3.2`, the most important change has not been a new skill runtime command.

The backend now ships a formal current-session host starter, so the skill release surface needed to catch up:

- the backend contract baseline moved forward
- the release docs needed to reference the new starter path
- the public story around how the skill relates to the backend needed to stay coherent

This release makes that alignment explicit.

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
- skill `scripts/install-skill.ps1 -CheckOnly`
- skill `scripts/check-install.ps1 -SmokeTest`

## Compatibility Note

Current intended backend baseline for this skill release:

- `user-habit-pipeline v0.7.4`
