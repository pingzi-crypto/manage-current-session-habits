param(
  [string]$CodexSkillsRoot,
  [switch]$KeepGeneratedBackend,
  [switch]$CheckOnly
)

$ErrorActionPreference = "Stop"
$nodeCommand = Get-Command node -ErrorAction Stop
$scriptPath = Join-Path (Split-Path -Parent $MyInvocation.MyCommand.Path) "scripts/uninstall-entry.js"

$arguments = @($scriptPath)
if ($CodexSkillsRoot) {
  $arguments += @("--codex-skills-root", $CodexSkillsRoot)
}
if ($KeepGeneratedBackend) {
  $arguments += "--keep-generated-backend"
}
if ($CheckOnly) {
  $arguments += "--check-only"
}

& $nodeCommand.Source @arguments
exit $LASTEXITCODE
