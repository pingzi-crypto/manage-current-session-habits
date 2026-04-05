param(
  [string]$SkillRepoPath,
  [string]$CodexSkillsRoot,
  [string]$BackendRepoPath,
  [switch]$CheckOnly,
  [switch]$ForceRelink
)

function Get-HomeDirectory {
  if ($env:HOME) {
    return $env:HOME
  }

  if ($env:USERPROFILE) {
    return $env:USERPROFILE
  }

  throw "Unable to determine the user home directory. Set HOME, USERPROFILE, CODEX_HOME, or pass -CodexSkillsRoot."
}

function Get-DefaultCodexSkillsRoot {
  if ($env:CODEX_HOME) {
    return (Join-Path $env:CODEX_HOME "skills")
  }

  return (Join-Path (Join-Path (Get-HomeDirectory) ".codex") "skills")
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

function Get-LinkTargetDetail {
  param(
    [System.IO.FileSystemInfo]$Item
  )

  if (-not $Item -or -not $Item.LinkType) {
    return $null
  }

  if ($null -eq $Item.Target) {
    return "<unknown>"
  }

  if ($Item.Target -is [System.Array]) {
    return ($Item.Target -join ", ")
  }

  return [string]$Item.Target
}

function Resolve-InstalledTargetPaths {
  param(
    [string]$InstalledPath,
    [System.IO.FileSystemInfo]$Item
  )

  if (-not $Item -or -not $Item.LinkType) {
    return @()
  }

  $linkParentPath = Split-Path -Path $InstalledPath -Parent
  $resolvedTargets = New-Object System.Collections.Generic.List[string]

  foreach ($rawTarget in @($Item.Target)) {
    if ([string]::IsNullOrWhiteSpace([string]$rawTarget)) {
      continue
    }

    $candidateTarget = [string]$rawTarget
    if (-not [System.IO.Path]::IsPathRooted($candidateTarget)) {
      $candidateTarget = Join-Path $linkParentPath $candidateTarget
    }

    try {
      $resolvedTargets.Add((Resolve-Path -LiteralPath $candidateTarget).Path) | Out-Null
    } catch {
      $resolvedTargets.Add([System.IO.Path]::GetFullPath($candidateTarget)) | Out-Null
    }
  }

  return $resolvedTargets
}

function Remove-ExistingInstallTarget {
  param(
    [string]$Path,
    [System.IO.FileSystemInfo]$ExistingItem
  )

  if (-not $ExistingItem) {
    return
  }

  if ($ExistingItem.LinkType) {
    Remove-Item -LiteralPath $Path -Force
    return
  }

  Remove-Item -LiteralPath $Path -Recurse -Force
}

function New-SkillLink {
  param(
    [string]$Path,
    [string]$Target
  )

  if ($IsWindows) {
    New-Item -ItemType Junction -Path $Path -Target $Target | Out-Null
    return "Junction"
  }

  New-Item -ItemType SymbolicLink -Path $Path -Target $Target | Out-Null
  return "SymbolicLink"
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
$bridgeCliPath = Join-Path (Join-Path $resolvedBackendRepoPath "src") "codex-session-habits-cli.js"

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
$resolvedInstalledTargetPaths = Resolve-InstalledTargetPaths -InstalledPath $targetPath -Item $existing

if ($CheckOnly) {
  Write-Output "Check-only mode: no files will be modified."
  Write-Output "Skill repo: $resolvedRepoPath"
  Write-Output "Codex skills root: $CodexSkillsRoot"
  Write-Output "Install target: $targetPath"
  Write-Output "Config path: $configPath"
  Write-Output "Backend repo: $resolvedBackendRepoPath"
  Write-Output "Bridge CLI: $bridgeCliPath"

  if ($existing) {
    if ($existing.LinkType -and $resolvedInstalledTargetPaths -contains $resolvedRepoPath) {
      Write-Output "Existing install target already points to this repository."
    } elseif ($existing.LinkType) {
      Write-Output "Existing install target points elsewhere: $(Get-LinkTargetDetail -Item $existing)"
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
  if ($existing.LinkType -and $resolvedInstalledTargetPaths -contains $resolvedRepoPath) {
    if ($ForceRelink) {
      Remove-ExistingInstallTarget -Path $targetPath -ExistingItem $existing
      $linkType = New-SkillLink -Path $targetPath -Target $resolvedRepoPath
      Write-Output "Recreated skill link ($linkType): $targetPath -> $resolvedRepoPath"
      Write-Output "Wrote local config: $configPath"
      Write-Output "Using backend repo: $resolvedBackendRepoPath"
      exit 0
    }

    Write-Output "Wrote local config: $configPath"
    Write-Output "Skill link already points to $resolvedRepoPath"
    exit 0
  }

  Remove-ExistingInstallTarget -Path $targetPath -ExistingItem $existing
}

$linkType = New-SkillLink -Path $targetPath -Target $resolvedRepoPath
Write-Output "Installed skill link ($linkType): $targetPath -> $resolvedRepoPath"
Write-Output "Wrote local config: $configPath"
Write-Output "Using backend repo: $resolvedBackendRepoPath"
