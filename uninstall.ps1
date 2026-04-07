param(
  [string]$CodexSkillsRoot,
  [switch]$KeepGeneratedBackend,
  [switch]$CheckOnly
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

$ErrorActionPreference = "Stop"

if (-not $CodexSkillsRoot) {
  $CodexSkillsRoot = Get-DefaultCodexSkillsRoot
}

$repoRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$resolvedRepoPath = (Resolve-Path -LiteralPath $repoRoot).Path
$skillName = Split-Path -Path $resolvedRepoPath -Leaf
$installedSkillPath = Join-Path $CodexSkillsRoot $skillName
$configPath = Join-Path (Join-Path $resolvedRepoPath "config") "local-config.json"
$backendInstallRoot = Join-Path (Join-Path $resolvedRepoPath "config") "npm-backend"

$actions = New-Object System.Collections.Generic.List[string]

if (Test-Path -LiteralPath $installedSkillPath) {
  $installedSkill = Get-Item -LiteralPath $installedSkillPath -Force
  $resolvedTargets = Resolve-InstalledTargetPaths -InstalledPath $installedSkillPath -Item $installedSkill

  if ($installedSkill.LinkType -and $resolvedTargets -contains $resolvedRepoPath) {
    $actions.Add("remove skill link: $installedSkillPath") | Out-Null
  } elseif ($installedSkill.LinkType) {
    $targetText = if ($installedSkill.Target -is [System.Array]) { $installedSkill.Target -join ", " } else { [string]$installedSkill.Target }
    Write-Output "Skipping installed skill path because it points elsewhere: $targetText"
  } else {
    Write-Output "Skipping installed skill path because it is not a link: $installedSkillPath"
  }
}

if (Test-Path -LiteralPath $configPath) {
  $actions.Add("remove generated config: $configPath") | Out-Null
}

if ((-not $KeepGeneratedBackend) -and (Test-Path -LiteralPath $backendInstallRoot)) {
  $actions.Add("remove generated backend runtime: $backendInstallRoot") | Out-Null
}

if ($actions.Count -eq 0) {
  Write-Output "Nothing to remove."
  exit 0
}

if ($CheckOnly) {
  Write-Output "Check-only mode: no files will be modified."
  $actions | ForEach-Object { Write-Output $_ }
  exit 0
}

foreach ($action in $actions) {
  Write-Output $action
}

if (Test-Path -LiteralPath $installedSkillPath) {
  $installedSkill = Get-Item -LiteralPath $installedSkillPath -Force
  $resolvedTargets = Resolve-InstalledTargetPaths -InstalledPath $installedSkillPath -Item $installedSkill
  if ($installedSkill.LinkType -and $resolvedTargets -contains $resolvedRepoPath) {
    Remove-Item -LiteralPath $installedSkillPath -Force
  }
}

if (Test-Path -LiteralPath $configPath) {
  Remove-Item -LiteralPath $configPath -Force
}

if ((-not $KeepGeneratedBackend) -and (Test-Path -LiteralPath $backendInstallRoot)) {
  Remove-Item -LiteralPath $backendInstallRoot -Recurse -Force
}

Write-Output "Uninstall complete."
