param(
  [string]$SkillRepoPath,
  [string]$CodexSkillsRoot,
  [string]$BackendRepoPath,
  [string]$BackendPackageSpec = "user-habit-pipeline@latest",
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

  return $null
}

function Write-Utf8NoBomFile {
  param(
    [string]$Path,
    [string]$Content
  )

  $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
  [System.IO.File]::WriteAllText($Path, $Content + [Environment]::NewLine, $utf8NoBom)
}

function Install-BackendPackage {
  param(
    [string]$InstallRoot,
    [string]$PackageSpec
  )

  $npmCommand = Get-Command npm -ErrorAction Stop
  if (!(Test-Path -LiteralPath $InstallRoot)) {
    New-Item -ItemType Directory -Path $InstallRoot -Force | Out-Null
  }

  $packageJsonPath = Join-Path $InstallRoot "package.json"
  if (!(Test-Path -LiteralPath $packageJsonPath)) {
    Write-Utf8NoBomFile -Path $packageJsonPath -Content (@{
      name = "manage-current-session-habits-backend-runtime"
      private = $true
    } | ConvertTo-Json)
  }

  & $npmCommand.Source install --prefix $InstallRoot $PackageSpec
  if ($LASTEXITCODE -ne 0) {
    throw "npm install failed for backend package spec `"$PackageSpec`"."
  }

  $installedPackageJsonPath = Join-Path (Join-Path (Join-Path $InstallRoot "node_modules") "user-habit-pipeline") "package.json"
  if (!(Test-Path -LiteralPath $installedPackageJsonPath)) {
    throw "Installed backend package metadata was not found at $installedPackageJsonPath"
  }

  return (Get-Content -Raw -LiteralPath $installedPackageJsonPath | ConvertFrom-Json)
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
$backendInstallRoot = Join-Path $configDir "npm-backend"

if ($resolvedBackendRepoPath) {
  $backendSource = "repo"
  $bridgeCliPath = Join-Path (Join-Path $resolvedBackendRepoPath "src") "codex-session-habits-cli.js"

  if (!(Test-Path -LiteralPath $bridgeCliPath)) {
    throw "Bridge CLI was not found at $bridgeCliPath"
  }

  $configObject = @{
    backend_source = $backendSource
    backend_repo_path = $resolvedBackendRepoPath
    bridge_cli_path = $bridgeCliPath
  }
} else {
  $backendSource = "package"
  $installedPackage = Install-BackendPackage -InstallRoot $backendInstallRoot -PackageSpec $BackendPackageSpec
  $bridgeBinName = if ($IsWindows) { "codex-session-habits.cmd" } else { "codex-session-habits" }
  $bridgeCliPath = Join-Path (Join-Path (Join-Path $backendInstallRoot "node_modules") ".bin") $bridgeBinName

  if (!(Test-Path -LiteralPath $bridgeCliPath)) {
    throw "Installed backend bridge CLI was not found at $bridgeCliPath"
  }

  $configObject = @{
    backend_source = $backendSource
    backend_package_name = "user-habit-pipeline"
    backend_package_version = [string]$installedPackage.version
    backend_install_root = $backendInstallRoot
    bridge_cli_path = $bridgeCliPath
  }
}

$config = $configObject | ConvertTo-Json

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
  if ($backendSource -eq "repo") {
    Write-Output "Backend source: repo"
    Write-Output "Backend repo: $resolvedBackendRepoPath"
  } else {
    Write-Output "Backend source: npm package"
    Write-Output "Backend package spec: $BackendPackageSpec"
    Write-Output "Backend install root: $backendInstallRoot"
  }
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

if (!(Test-Path -LiteralPath $configDir)) {
  New-Item -ItemType Directory -Path $configDir -Force | Out-Null
}
Write-Utf8NoBomFile -Path $configPath -Content $config

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
      if ($backendSource -eq "repo") {
        Write-Output "Using backend repo: $resolvedBackendRepoPath"
      } else {
        Write-Output "Using backend package: $($configObject.backend_package_name)@$($configObject.backend_package_version)"
      }
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
if ($backendSource -eq "repo") {
  Write-Output "Using backend repo: $resolvedBackendRepoPath"
} else {
  Write-Output "Using backend package: $($configObject.backend_package_name)@$($configObject.backend_package_version)"
}
