# Skill Release Runbook

Use this runbook when you want the smallest reliable release flow for `manage-current-session-habits`.

This is the practical skill-side execution order.
For deeper coordination with the backend repo, keep using the cross-repo release docs in `user-habit-pipeline`.

---

## Target Baseline

- skill repo: `manage-current-session-habits v0.3.2`
- backend contract baseline: `user-habit-pipeline v0.7.0`

---

## 1. Preflight

Confirm:

- the repository is on the intended branch
- the working tree is clean
- the public files you want users to see are already in place

Current release-facing files:

- [README.md](/E:/manage-current-session-habits/README.md)
- [RELEASE-NOTES-v0.3.2.md](/E:/manage-current-session-habits/RELEASE-NOTES-v0.3.2.md)
- [INSTALL-LIFECYCLE-CHECKLIST.md](/E:/manage-current-session-habits/INSTALL-LIFECYCLE-CHECKLIST.md)
- [assets/readme-short-demo.gif](/E:/manage-current-session-habits/assets/readme-short-demo.gif)

---

## 2. Validate Against The Backend

From the backend repo, run:

```powershell
npm run release-check
```

Treat the skill release as blocked if the backend release gate fails.

---

## 3. Validate The Skill

From this repository, run:

```powershell
& .\install.ps1 -CheckOnly
& .\scripts\check-install.ps1 -SmokeTest
```

If local backend repo compatibility matters for this release, also run:

```powershell
& .\install.ps1 -BackendRepoPath <path-to-user-habit-pipeline>
```

Confirm:

- package-mode install preview works
- package-mode smoke passes
- cached follow-up apply works through the installed wrapper
- repo-mode install still works if promised

---

## 4. Validate Install Lifecycle

Use the public checklist:

- [INSTALL-LIFECYCLE-CHECKLIST.md](/E:/manage-current-session-habits/INSTALL-LIFECYCLE-CHECKLIST.md)

Minimum expectation before release:

- install
- refresh
- uninstall
- reinstall

---

## 5. Create The Skill Release

Recommended tag:

- `v0.3.2`

Suggested commands:

```powershell
git tag v0.3.2
git push origin v0.3.2
```

On GitHub:

1. open the `manage-current-session-habits` releases page
2. create a new release from tag `v0.3.2`
3. use [RELEASE-NOTES-v0.3.2.md](/E:/manage-current-session-habits/RELEASE-NOTES-v0.3.2.md) as the release body
4. attach or reuse [assets/readme-short-demo.gif](/E:/manage-current-session-habits/assets/readme-short-demo.gif) if the release page should mirror the README demo

Recommended title:

- `manage-current-session-habits v0.3.2`

---

## 6. Post-Release Check

After the release is live, confirm:

- the release page points at the intended release body
- the README quick start still matches the install path you actually validated
- the skill still behaves consistently with backend `v0.7.0` bridge output
