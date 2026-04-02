param(
  [string]$SkillRepoPath,
  [string]$CodexSkillsRoot,
  [string]$BackendRepoPath,
  [switch]$CheckOnly,
  [switch]$ForceRelink
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

function Resolve-BackendRepoPath {
  param(
    [string]$ProvidedPath,
    [string]$SkillRepoPath
  )

  if ($ProvidedPath) {
    return (Resolve-Path -LiteralPath $ProvidedPath).Path
  }

  if ($env:USER_HABIT_PIPELINE_REPO) {
    return (Resolve-Path -LiteralPath $env:USER_HABIT_PIPELINE_REPO).Path
  }

  $siblingCandidate = Join-Path (Split-Path -Path $SkillRepoPath -Parent) "user-habit-pipeline"
  if (Test-Path -LiteralPath $siblingCandidate) {
    return (Resolve-Path -LiteralPath $siblingCandidate).Path
  }

  throw "Backend repo path is required. Pass -BackendRepoPath or set USER_HABIT_PIPELINE_REPO."
}

$ErrorActionPreference = "Stop"

if (-not $SkillRepoPath) {
  $SkillRepoPath = (Join-Path $PSScriptRoot "..")
}

if (-not $CodexSkillsRoot) {
  $CodexSkillsRoot = Get-DefaultCodexSkillsRoot
}

$resolvedRepoPath = (Resolve-Path -LiteralPath $SkillRepoPath).Path
$resolvedBackendRepoPath = Resolve-BackendRepoPath -ProvidedPath $BackendRepoPath -SkillRepoPath $resolvedRepoPath
$skillName = Split-Path -Path $resolvedRepoPath -Leaf
$targetPath = Join-Path $CodexSkillsRoot $skillName
$configDir = Join-Path $resolvedRepoPath "config"
$configPath = Join-Path $configDir "local-config.json"
$bridgeCliPath = Join-Path $resolvedBackendRepoPath "src\\codex-session-habits-cli.js"

if (!(Test-Path -LiteralPath $bridgeCliPath)) {
  throw "Bridge CLI was not found at $bridgeCliPath"
}

$config = @{
  backend_repo_path = $resolvedBackendRepoPath
  bridge_cli_path = $bridgeCliPath
} | ConvertTo-Json

$existing = $null
if (Test-Path -LiteralPath $targetPath) {
  $existing = Get-Item -LiteralPath $targetPath -Force
}

if ($CheckOnly) {
  Write-Output "Check-only mode: no files will be modified."
  Write-Output "Skill repo: $resolvedRepoPath"
  Write-Output "Codex skills root: $CodexSkillsRoot"
  Write-Output "Install target: $targetPath"
  Write-Output "Config path: $configPath"
  Write-Output "Backend repo: $resolvedBackendRepoPath"
  Write-Output "Bridge CLI: $bridgeCliPath"

  if ($existing) {
    if ($existing.LinkType -and $existing.Target -contains $resolvedRepoPath) {
      Write-Output "Existing install target already points to this repository."
    } elseif ($existing.LinkType) {
      Write-Output "Existing install target points elsewhere: $($existing.Target -join ', ')"
    } else {
      Write-Output "Existing install target is a normal directory/file and would require replacement."
    }
  } else {
    Write-Output "Install target does not exist yet."
  }

  exit 0
}

$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
if (!(Test-Path -LiteralPath $configDir)) {
  New-Item -ItemType Directory -Path $configDir -Force | Out-Null
}
[System.IO.File]::WriteAllText($configPath, $config + [Environment]::NewLine, $utf8NoBom)

if (!(Test-Path -LiteralPath $CodexSkillsRoot)) {
  New-Item -ItemType Directory -Path $CodexSkillsRoot -Force | Out-Null
}

if ($existing) {
  if ($existing.LinkType -and $existing.Target -contains $resolvedRepoPath) {
    if ($ForceRelink) {
      Remove-Item -LiteralPath $targetPath -Recurse -Force
      New-Item -ItemType Junction -Path $targetPath -Target $resolvedRepoPath | Out-Null
      Write-Output "Recreated skill link: $targetPath -> $resolvedRepoPath"
      Write-Output "Wrote local config: $configPath"
      Write-Output "Using backend repo: $resolvedBackendRepoPath"
      exit 0
    }

    Write-Output "Wrote local config: $configPath"
    Write-Output "Skill link already points to $resolvedRepoPath"
    exit 0
  }

  Remove-Item -LiteralPath $targetPath -Recurse -Force
}

New-Item -ItemType Junction -Path $targetPath -Target $resolvedRepoPath | Out-Null
Write-Output "Installed skill link: $targetPath -> $resolvedRepoPath"
Write-Output "Wrote local config: $configPath"
Write-Output "Using backend repo: $resolvedBackendRepoPath"
