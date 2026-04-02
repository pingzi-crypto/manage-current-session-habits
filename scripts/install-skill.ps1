param(
  [string]$SkillRepoPath = "E:\manage-current-session-habits",
  [string]$CodexSkillsRoot = "C:\Users\pz\.codex\skills",
  [string]$BackendRepoPath = "E:\user-habit-pipeline"
)

$ErrorActionPreference = "Stop"

$resolvedRepoPath = (Resolve-Path -LiteralPath $SkillRepoPath).Path
$resolvedBackendRepoPath = (Resolve-Path -LiteralPath $BackendRepoPath).Path
$skillName = Split-Path -Path $resolvedRepoPath -Leaf
$targetPath = Join-Path $CodexSkillsRoot $skillName
$configDir = Join-Path $resolvedRepoPath "config"
$configPath = Join-Path $configDir "local-config.json"
$bridgeCliPath = Join-Path $resolvedBackendRepoPath "src\\codex-session-habits-cli.js"

if (!(Test-Path -LiteralPath $bridgeCliPath)) {
  throw "Bridge CLI was not found at $bridgeCliPath"
}

if (!(Test-Path -LiteralPath $configDir)) {
  New-Item -ItemType Directory -Path $configDir -Force | Out-Null
}

$config = @{
  backend_repo_path = $resolvedBackendRepoPath
  bridge_cli_path = $bridgeCliPath
} | ConvertTo-Json

$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllText($configPath, $config + [Environment]::NewLine, $utf8NoBom)

if (!(Test-Path -LiteralPath $CodexSkillsRoot)) {
  New-Item -ItemType Directory -Path $CodexSkillsRoot -Force | Out-Null
}

if (Test-Path -LiteralPath $targetPath) {
  $existing = Get-Item -LiteralPath $targetPath -Force

  if ($existing.LinkType -and $existing.Target -contains $resolvedRepoPath) {
    Write-Output "Wrote local config: $configPath"
    Write-Output "Skill link already points to $resolvedRepoPath"
    exit 0
  }

  Remove-Item -LiteralPath $targetPath -Recurse -Force
}

New-Item -ItemType Junction -Path $targetPath -Target $resolvedRepoPath | Out-Null
Write-Output "Installed skill link: $targetPath -> $resolvedRepoPath"
Write-Output "Wrote local config: $configPath"
