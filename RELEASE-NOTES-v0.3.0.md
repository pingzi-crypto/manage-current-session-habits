# manage-current-session-habits v0.3.0

This release upgrades the public install surface from a repo-internal script flow to a fuller install lifecycle:

- one-step install from the repo root
- bootstrap install for cold-start setup
- safer clone fallback when GitHub HTTPS clone is blocked
- safe uninstall for generated local skill/runtime state
- a public lifecycle acceptance checklist for install, upgrade, uninstall, and reinstall

## Highlights

- added `install.ps1` as the main one-step install entrypoint
- added `bootstrap-install.ps1` for cold-start setup from outside the repo
- added SSH fallback for bootstrap clone when HTTPS GitHub clone fails but SSH is available
- added `uninstall.ps1` to remove the installed skill link and generated local runtime files without deleting the repo checkout
- added `INSTALL-LIFECYCLE-CHECKLIST.md` as the public acceptance path for install lifecycle validation
- updated `README.md` to prefer the most reliable clone-based quick start and document uninstall/reinstall paths

## Why This Release Exists

`v0.2.0` made the skill package-first for the backend install path.

This release focuses on the next practical gap:

- first-time setup should be simpler
- reinstall should not require manual cleanup
- uninstall should be explicit and safe
- release-time acceptance should follow one public checklist instead of scattered ad hoc steps

## Validation

This release was validated with:

- package-mode install and smoke through `install.ps1`
- repo-override install and smoke through `install.ps1 -BackendRepoPath <path>`
- uninstall preview through `uninstall.ps1 -CheckOnly`
- uninstall and reinstall round trip through `uninstall.ps1` followed by `install.ps1`
- cold-start clone/install in a temporary directory using the public README quick-start path
