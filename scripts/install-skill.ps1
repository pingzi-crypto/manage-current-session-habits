param(
  [string]$SkillRepoPath = "E:\manage-current-session-habits",
  [string]$CodexSkillsRoot = "C:\Users\pz\.codex\skills"
)

$ErrorActionPreference = "Stop"

$resolvedRepoPath = (Resolve-Path -LiteralPath $SkillRepoPath).Path
$skillName = Split-Path -Path $resolvedRepoPath -Leaf
$targetPath = Join-Path $CodexSkillsRoot $skillName

if (!(Test-Path -LiteralPath $CodexSkillsRoot)) {
  New-Item -ItemType Directory -Path $CodexSkillsRoot -Force | Out-Null
}

if (Test-Path -LiteralPath $targetPath) {
  $existing = Get-Item -LiteralPath $targetPath -Force

  if ($existing.LinkType -and $existing.Target -contains $resolvedRepoPath) {
    Write-Output "Skill link already points to $resolvedRepoPath"
    exit 0
  }

  Remove-Item -LiteralPath $targetPath -Recurse -Force
}

New-Item -ItemType Junction -Path $targetPath -Target $resolvedRepoPath | Out-Null
Write-Output "Installed skill link: $targetPath -> $resolvedRepoPath"
