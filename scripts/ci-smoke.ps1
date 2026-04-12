param(
  [string]$SkillRepoPath,
  [string]$BackendRepoPath,
  [string]$CodexHome,
  [switch]$SkipRepoMode
)

$ErrorActionPreference = "Stop"
$nodeCommand = Get-Command node -ErrorAction Stop
$scriptPath = Join-Path $PSScriptRoot "ci-smoke.js"

$arguments = @($scriptPath)
if ($SkillRepoPath) {
  $arguments += @("--skill-repo-path", $SkillRepoPath)
}
if ($BackendRepoPath) {
  $arguments += @("--backend-repo-path", $BackendRepoPath)
}
if ($CodexHome) {
  $arguments += @("--codex-home", $CodexHome)
}
if ($SkipRepoMode) {
  $arguments += "--skip-repo-mode"
}

& $nodeCommand.Source @arguments
exit $LASTEXITCODE
