param(
  [string]$CodexSkillsRoot,
  [string]$BackendRepoPath,
  [string]$BackendPackageSpec = "user-habit-pipeline@latest",
  [switch]$SkipSmokeTest,
  [switch]$CheckOnly,
  [switch]$ForceRelink
)

$ErrorActionPreference = "Stop"
$nodeCommand = Get-Command node -ErrorAction Stop
$scriptPath = Join-Path (Split-Path -Parent $MyInvocation.MyCommand.Path) "scripts/install-entry.js"

$arguments = @($scriptPath)
if ($CodexSkillsRoot) {
  $arguments += @("--codex-skills-root", $CodexSkillsRoot)
}
if ($BackendRepoPath) {
  $arguments += @("--backend-repo-path", $BackendRepoPath)
}
if ($BackendPackageSpec) {
  $arguments += @("--backend-package-spec", $BackendPackageSpec)
}
if ($SkipSmokeTest) {
  $arguments += "--skip-smoke-test"
}
if ($CheckOnly) {
  $arguments += "--check-only"
}
if ($ForceRelink) {
  $arguments += "--force-relink"
}

& $nodeCommand.Source @arguments
exit $LASTEXITCODE
