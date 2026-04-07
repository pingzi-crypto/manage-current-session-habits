param(
  [string]$CodexSkillsRoot,
  [string]$BackendRepoPath,
  [string]$BackendPackageSpec = "user-habit-pipeline",
  [switch]$SkipSmokeTest,
  [switch]$CheckOnly,
  [switch]$ForceRelink
)

$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$installScriptPath = Join-Path $repoRoot "scripts\install-skill.ps1"
$checkScriptPath = Join-Path $repoRoot "scripts\check-install.ps1"

if (!(Test-Path -LiteralPath $installScriptPath)) {
  throw "Install script was not found at $installScriptPath"
}

if (!(Test-Path -LiteralPath $checkScriptPath)) {
  throw "Check script was not found at $checkScriptPath"
}

$installParams = @{
  SkillRepoPath = $repoRoot
  BackendPackageSpec = $BackendPackageSpec
}

if ($CodexSkillsRoot) {
  $installParams.CodexSkillsRoot = $CodexSkillsRoot
}

if ($BackendRepoPath) {
  $installParams.BackendRepoPath = $BackendRepoPath
}

if ($CheckOnly) {
  $installParams.CheckOnly = $true
}

if ($ForceRelink) {
  $installParams.ForceRelink = $true
}

Write-Output "Installing manage-current-session-habits from $repoRoot"
& $installScriptPath @installParams
if ($LASTEXITCODE -ne 0) {
  exit $LASTEXITCODE
}

if ($CheckOnly) {
  exit 0
}

if ($SkipSmokeTest) {
  Write-Output "Skipped smoke validation."
  exit 0
}

Write-Output "Running install smoke validation..."
$checkParams = @{
  SkillRepoPath = $repoRoot
  SmokeTest = $true
}

if ($CodexSkillsRoot) {
  $checkParams.CodexSkillsRoot = $CodexSkillsRoot
}

& $checkScriptPath @checkParams
exit $LASTEXITCODE
