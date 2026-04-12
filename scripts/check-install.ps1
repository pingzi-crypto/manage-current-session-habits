param(
  [string]$SkillRepoPath,
  [string]$CodexSkillsRoot,
  [string]$ConfigPath,
  [switch]$SmokeTest
)

$ErrorActionPreference = "Stop"
$nodeCommand = Get-Command node -ErrorAction Stop
$scriptPath = Join-Path $PSScriptRoot "check-install.js"

$arguments = @($scriptPath)
if ($SkillRepoPath) {
  $arguments += @("--skill-repo-path", $SkillRepoPath)
}
if ($CodexSkillsRoot) {
  $arguments += @("--codex-skills-root", $CodexSkillsRoot)
}
if ($ConfigPath) {
  $arguments += @("--config-path", $ConfigPath)
}
if ($SmokeTest) {
  $arguments += "--smoke-test"
}

& $nodeCommand.Source @arguments
exit $LASTEXITCODE
