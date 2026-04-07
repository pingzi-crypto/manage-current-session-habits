param(
  [string]$RepositoryUrl = "https://github.com/pingzi-crypto/manage-current-session-habits.git",
  [string]$InstallRoot,
  [string]$CodexSkillsRoot,
  [string]$BackendRepoPath,
  [string]$BackendPackageSpec = "user-habit-pipeline",
  [switch]$SkipSmokeTest,
  [switch]$CheckOnly,
  [switch]$ForceRelink
)

$ErrorActionPreference = "Stop"
$repoName = "manage-current-session-habits"

function Get-HomeDirectory {
  if ($env:HOME) {
    return $env:HOME
  }

  if ($env:USERPROFILE) {
    return $env:USERPROFILE
  }

  throw "Unable to determine the user home directory. Set HOME or USERPROFILE, or pass -InstallRoot."
}

function Get-DefaultInstallRoot {
  $codexRoot = if ($env:CODEX_HOME) {
    $env:CODEX_HOME
  } else {
    Join-Path (Get-HomeDirectory) ".codex"
  }

  return (Join-Path (Join-Path $codexRoot "repos") $repoName)
}

function Test-IsGitRepository {
  param(
    [string]$Path
  )

  return (Test-Path -LiteralPath (Join-Path $Path ".git"))
}

function Resolve-CheckoutPath {
  param(
    [string]$ProvidedPath
  )

  if (-not $ProvidedPath) {
    return (Get-DefaultInstallRoot)
  }

  $resolvedCandidate = [System.IO.Path]::GetFullPath($ProvidedPath)
  if ((Split-Path -Leaf $resolvedCandidate) -eq $repoName) {
    return $resolvedCandidate
  }

  return (Join-Path $resolvedCandidate $repoName)
}

function Ensure-RepositoryCheckout {
  param(
    [string]$Path,
    [string]$RepoUrl
  )

  $gitCommand = Get-Command git -ErrorAction Stop

  if (!(Test-Path -LiteralPath $Path)) {
    $parentPath = Split-Path -Parent $Path
    if ($parentPath -and !(Test-Path -LiteralPath $parentPath)) {
      New-Item -ItemType Directory -Path $parentPath -Force | Out-Null
    }

    & $gitCommand.Source clone $RepoUrl $Path
    if ($LASTEXITCODE -ne 0) {
      throw "git clone failed for $RepoUrl"
    }
    return "cloned"
  }

  $resolvedPath = (Resolve-Path -LiteralPath $Path).Path

  if (!(Test-IsGitRepository -Path $resolvedPath)) {
    throw "Install root already exists but is not a git repository: $resolvedPath"
  }

  $repoStatus = & $gitCommand.Source -C $resolvedPath status --porcelain
  if ($LASTEXITCODE -ne 0) {
    throw "Unable to inspect repository status at $resolvedPath"
  }

  if ($repoStatus) {
    throw "Install root contains local changes: $resolvedPath. Commit or clean them before bootstrap update."
  }

  $originUrl = (& $gitCommand.Source -C $resolvedPath remote get-url origin).Trim()
  if ($LASTEXITCODE -ne 0) {
    throw "Unable to read origin remote for $resolvedPath"
  }

  if ($originUrl -ne $RepoUrl) {
    throw "Install root points to a different origin: $originUrl"
  }

  & $gitCommand.Source -C $resolvedPath pull --ff-only origin main
  if ($LASTEXITCODE -ne 0) {
    throw "git pull --ff-only failed for $resolvedPath"
  }

  return "updated"
}

$resolvedInstallRoot = Resolve-CheckoutPath -ProvidedPath $InstallRoot
$checkoutAction = Ensure-RepositoryCheckout -Path $resolvedInstallRoot -RepoUrl $RepositoryUrl
$installScriptPath = Join-Path $resolvedInstallRoot "install.ps1"

if (!(Test-Path -LiteralPath $installScriptPath)) {
  throw "Expected install.ps1 inside the repository checkout at $installScriptPath"
}

Write-Output ("Repository {0}: {1}" -f $checkoutAction, $resolvedInstallRoot)

$installParams = @{
  BackendPackageSpec = $BackendPackageSpec
}

if ($CodexSkillsRoot) {
  $installParams.CodexSkillsRoot = $CodexSkillsRoot
}

if ($BackendRepoPath) {
  $installParams.BackendRepoPath = $BackendRepoPath
}

if ($SkipSmokeTest) {
  $installParams.SkipSmokeTest = $true
}

if ($CheckOnly) {
  $installParams.CheckOnly = $true
}

if ($ForceRelink) {
  $installParams.ForceRelink = $true
}

& $installScriptPath @installParams
exit $LASTEXITCODE
