param(
  [string]$SkillRepoPath,
  [string]$BackendRepoPath,
  [string]$CodexHome,
  [switch]$SkipRepoMode
)

$ErrorActionPreference = "Stop"

if (-not $SkillRepoPath) {
  $SkillRepoPath = Join-Path $PSScriptRoot ".."
}

$resolvedSkillRepoPath = (Resolve-Path -LiteralPath $SkillRepoPath).Path
$installScriptPath = Join-Path $resolvedSkillRepoPath "install.ps1"
$uninstallScriptPath = Join-Path $resolvedSkillRepoPath "uninstall.ps1"

if (-not $CodexHome) {
  $CodexHome = Join-Path ([System.IO.Path]::GetTempPath()) ("manage-current-session-habits-ci-" + [System.Guid]::NewGuid().ToString("N"))
}

$resolvedCodexHome = [System.IO.Path]::GetFullPath($CodexHome)
$previousCodexHome = $env:CODEX_HOME
$env:CODEX_HOME = $resolvedCodexHome

$steps = New-Object System.Collections.Generic.List[string]

function Add-Step {
  param(
    [string]$Detail
  )

  $steps.Add($Detail) | Out-Null
  Write-Output $Detail
}

try {
  if (-not (Test-Path -LiteralPath $resolvedCodexHome)) {
    New-Item -ItemType Directory -Path $resolvedCodexHome -Force | Out-Null
  }

  Add-Step "package-mode install + smoke"
  & $installScriptPath -SkipSmokeTest:$false -ForceRelink
  if ($LASTEXITCODE -ne 0) {
    throw "Package-mode install failed."
  }

  Add-Step "package-mode refresh + smoke"
  & $installScriptPath -SkipSmokeTest:$false -ForceRelink
  if ($LASTEXITCODE -ne 0) {
    throw "Package-mode refresh failed."
  }

  Add-Step "package-mode uninstall"
  & $uninstallScriptPath
  if ($LASTEXITCODE -ne 0) {
    throw "Package-mode uninstall failed."
  }

  if (-not $SkipRepoMode) {
    if (-not $BackendRepoPath) {
      throw "Repo-mode smoke requires -BackendRepoPath unless -SkipRepoMode is set."
    }

    $resolvedBackendRepoPath = (Resolve-Path -LiteralPath $BackendRepoPath).Path

    Add-Step "repo-mode install + smoke"
    & $installScriptPath -BackendRepoPath $resolvedBackendRepoPath -SkipSmokeTest:$false -ForceRelink
    if ($LASTEXITCODE -ne 0) {
      throw "Repo-mode install failed."
    }

    Add-Step "repo-mode uninstall"
    & $uninstallScriptPath
    if ($LASTEXITCODE -ne 0) {
      throw "Repo-mode uninstall failed."
    }
  }

  Write-Output (@{
    ok = $true
    skill_repo = $resolvedSkillRepoPath
    codex_home = $resolvedCodexHome
    repo_mode = (-not $SkipRepoMode)
    steps = $steps
  } | ConvertTo-Json -Depth 4)
} finally {
  if ($previousCodexHome) {
    $env:CODEX_HOME = $previousCodexHome
  } else {
    Remove-Item Env:CODEX_HOME -ErrorAction SilentlyContinue
  }

  if (Test-Path -LiteralPath $resolvedCodexHome) {
    Remove-Item -LiteralPath $resolvedCodexHome -Recurse -Force
  }
}
