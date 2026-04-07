# manage-current-session-habits v0.3.1

This release tightens the skill's release readiness and install-time validation against the current backend contract.

It does not change the basic in-thread interaction model.
It makes the published skill safer to ship alongside `user-habit-pipeline v0.4.2`.

## Highlights

- aligned the example local config to backend `user-habit-pipeline v0.4.2`
- expanded install smoke validation to cover cached follow-up apply, not only list and scan
- added a skill-side release checklist
- added a skill-side release runbook

## Why This Release Exists

`v0.3.0` improved the install lifecycle, but it still left two practical gaps:

- release preparation still depended too much on memory and cross-repo context switching
- skill smoke validation stopped at scan and did not prove that cached follow-up apply still worked through the installed wrapper

This release closes those gaps so the skill can be released more confidently against the current backend bridge contract.

## Validation

This release was validated with:

- backend `user-habit-pipeline` `npm run release-check`
- skill `install.ps1 -CheckOnly`
- skill `scripts/check-install.ps1 -SmokeTest`
- skill repo-override preview through `install.ps1 -BackendRepoPath <path> -CheckOnly`

## Compatibility Note

Current intended backend baseline for this skill release:

- `user-habit-pipeline v0.4.2`

If the backend contract moves again, update the skill release checklist, runbook, and release notes in the same change set.
