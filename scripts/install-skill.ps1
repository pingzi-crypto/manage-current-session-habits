param(
  [string]$SkillRepoPath,
  [string]$CodexSkillsRoot,
  [string]$BackendRepoPath,
  [string]$BackendPackageSpec = "user-habit-pipeline@latest",
  [switch]$CheckOnly,
  [switch]$ForceRelink
)

$ErrorActionPreference = "Stop"
$nodeCommand = Get-Command node -ErrorAction Stop
$scriptPath = Join-Path $PSScriptRoot "install-skill.js"

$arguments = @($scriptPath)
if ($SkillRepoPath) {
  $arguments += @("--skill-repo-path", $SkillRepoPath)
}
if ($CodexSkillsRoot) {
  $arguments += @("--codex-skills-root", $CodexSkillsRoot)
}
if ($BackendRepoPath) {
  $arguments += @("--backend-repo-path", $BackendRepoPath)
}
if ($BackendPackageSpec) {
  $arguments += @("--backend-package-spec", $BackendPackageSpec)
}
if ($CheckOnly) {
  $arguments += "--check-only"
}
if ($ForceRelink) {
  $arguments += "--force-relink"
}

& $nodeCommand.Source @arguments
exit $LASTEXITCODE
