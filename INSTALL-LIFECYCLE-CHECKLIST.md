# Install Lifecycle Checklist

Use this checklist when you want a fast acceptance pass for the public install surface of `manage-current-session-habits`.

This is the smallest practical lifecycle check:

- first install
- upgrade / refresh
- uninstall
- reinstall

It is intentionally short.
It is meant for release-time confidence, not exhaustive platform coverage.

## Prerequisites

Make sure these are available on `PATH`:

- `git`
- `pwsh`
- `node`

If your environment blocks GitHub HTTPS clone, confirm SSH clone works for GitHub.

---

## 1. First Install

Run the public quick start:

```powershell
$repo = Join-Path $HOME ".codex/repos/manage-current-session-habits"
if (Test-Path -LiteralPath $repo) {
  git -C $repo pull --ff-only origin main
} else {
  git clone https://github.com/pingzi-crypto/manage-current-session-habits.git $repo
  if ($LASTEXITCODE -ne 0) {
    git clone git@github.com:pingzi-crypto/manage-current-session-habits.git $repo
  }
}
& (Join-Path $repo "install.ps1")
```

Pass criteria:

- install completes without manual file edits
- smoke output shows `skill_link`, `local_config`, `smoke_test_scan`, and `smoke_test_apply` as `[OK]`
- the installed skill entry exists under the Codex skills root

---

## 2. Upgrade / Refresh

Run the same public quick start again from the same machine.

Expected result:

- the repo refreshes cleanly
- the skill remains installed
- the smoke check still passes
- no duplicate skill entry is created

---

## 3. Uninstall

Run:

```powershell
& .\uninstall.ps1
```

Pass criteria:

- the Codex skill link is removed
- `config/local-config.json` is removed
- `config/npm-backend/` is removed unless you intentionally kept it
- the repository checkout itself remains present

Preview-only variant:

```powershell
& .\uninstall.ps1 -CheckOnly
```

Keep-generated-backend variant:

```powershell
& .\uninstall.ps1 -KeepGeneratedBackend
```

---

## 4. Reinstall

From the same repository checkout, run:

```powershell
& .\install.ps1
```

Pass criteria:

- the Codex skill link is recreated
- `config/local-config.json` is recreated
- package-mode smoke passes again

---

## 5. Optional Local Backend Override

If local-checkout compatibility matters for this release, also run:

```powershell
& .\install.ps1 -BackendRepoPath <path-to-user-habit-pipeline>
```

Pass criteria:

- install succeeds without editing config by hand
- smoke passes
- the generated config uses `backend_source = "repo"`

---

## 6. Stop Conditions

Do not treat the install surface as healthy if any of these happen:

- the quick start only works with hidden machine-specific path edits
- uninstall removes the repository checkout unexpectedly
- reinstall requires manual cleanup in the Codex skills directory
- the public README path differs from the path you actually validated

If one of these happens, fix the install surface before doing more outward-facing polish.
