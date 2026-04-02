param(
  [string]$SkillRepoPath,
  [string]$CodexSkillsRoot,
  [string]$ConfigPath,
  [switch]$SmokeTest
)

function Get-DefaultCodexSkillsRoot {
  if ($env:CODEX_HOME) {
    return (Join-Path $env:CODEX_HOME "skills")
  }

  if ($env:USERPROFILE) {
    return (Join-Path $env:USERPROFILE ".codex\\skills")
  }

  throw "Unable to determine Codex skills root. Set CODEX_HOME or pass -CodexSkillsRoot."
}

$ErrorActionPreference = "Stop"

if (-not $SkillRepoPath) {
  $SkillRepoPath = (Join-Path $PSScriptRoot "..")
}

if (-not $CodexSkillsRoot) {
  $CodexSkillsRoot = Get-DefaultCodexSkillsRoot
}

$resolvedRepoPath = (Resolve-Path -LiteralPath $SkillRepoPath).Path
$skillName = Split-Path -Path $resolvedRepoPath -Leaf
$installedSkillPath = Join-Path $CodexSkillsRoot $skillName

if (-not $ConfigPath) {
  $ConfigPath = Join-Path $resolvedRepoPath "config\\local-config.json"
}

$resolvedConfigPath = [System.IO.Path]::GetFullPath($ConfigPath)

$checks = New-Object System.Collections.Generic.List[object]

function Add-Check {
  param(
    [string]$Name,
    [string]$Status,
    [string]$Detail
  )

  $checks.Add([pscustomobject]@{
    name = $Name
    status = $Status
    detail = $Detail
  }) | Out-Null
}

Add-Check -Name "skill_repo" -Status "ok" -Detail $resolvedRepoPath

if (!(Test-Path -LiteralPath $installedSkillPath)) {
  throw "Installed skill entry was not found at $installedSkillPath"
}

$installedSkill = Get-Item -LiteralPath $installedSkillPath -Force
if (-not $installedSkill.LinkType) {
  Add-Check -Name "skill_link" -Status "warn" -Detail "Installed path exists but is not a link/junction: $installedSkillPath"
} elseif ($installedSkill.Target -notcontains $resolvedRepoPath) {
  Add-Check -Name "skill_link" -Status "warn" -Detail "Installed skill points to $($installedSkill.Target -join ', '), expected $resolvedRepoPath"
} else {
  Add-Check -Name "skill_link" -Status "ok" -Detail "$installedSkillPath -> $resolvedRepoPath"
}

if (!(Test-Path -LiteralPath $resolvedConfigPath)) {
  throw "Missing local config at $resolvedConfigPath"
}

$config = Get-Content -Raw -LiteralPath $resolvedConfigPath | ConvertFrom-Json
Add-Check -Name "local_config" -Status "ok" -Detail $resolvedConfigPath

if ([string]::IsNullOrWhiteSpace($config.backend_repo_path)) {
  throw "local-config.json is missing backend_repo_path"
}

$resolvedBackendRepoPath = [System.IO.Path]::GetFullPath([string]$config.backend_repo_path)
if (!(Test-Path -LiteralPath $resolvedBackendRepoPath)) {
  throw "Configured backend repo was not found at $resolvedBackendRepoPath"
}
Add-Check -Name "backend_repo" -Status "ok" -Detail $resolvedBackendRepoPath

if ([string]::IsNullOrWhiteSpace($config.bridge_cli_path)) {
  throw "local-config.json is missing bridge_cli_path"
}

$resolvedBridgeCliPath = [System.IO.Path]::GetFullPath([string]$config.bridge_cli_path)
if (!(Test-Path -LiteralPath $resolvedBridgeCliPath)) {
  throw "Configured bridge CLI was not found at $resolvedBridgeCliPath"
}
Add-Check -Name "bridge_cli" -Status "ok" -Detail $resolvedBridgeCliPath

$nodeCommand = Get-Command node -ErrorAction Stop
Add-Check -Name "node" -Status "ok" -Detail $nodeCommand.Source

if ($SmokeTest) {
  $tempDir = Join-Path $env:TEMP ('manage-current-session-habits-check-' + [System.Guid]::NewGuid().ToString('N'))
  New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
  $tempRegistry = Join-Path $tempDir "user_habits.json"
  $invokeScriptPath = Join-Path $resolvedRepoPath "scripts\\invoke-backend.ps1"

  try {
    $smokeOutput = & $invokeScriptPath -Request "列出用户习惯短句" -UserRegistryPath $tempRegistry
    $parsed = $smokeOutput | ConvertFrom-Json
    if ($parsed.action -ne "list") {
      throw "Smoke test returned unexpected action: $($parsed.action)"
    }
    Add-Check -Name "smoke_test" -Status "ok" -Detail "Wrapper invocation succeeded."
  } finally {
    if (Test-Path -LiteralPath $tempDir) {
      Remove-Item -LiteralPath $tempDir -Recurse -Force
    }
  }
}

$checks | ForEach-Object {
  Write-Output ("[{0}] {1} - {2}" -f $_.status.ToUpperInvariant(), $_.name, $_.detail)
}
