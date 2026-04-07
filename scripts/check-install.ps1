param(
  [string]$SkillRepoPath,
  [string]$CodexSkillsRoot,
  [string]$ConfigPath,
  [switch]$SmokeTest
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

$ErrorActionPreference = "Stop"

if (-not $SkillRepoPath) {
  $SkillRepoPath = (Join-Path $PSScriptRoot "..")
}

if (-not $CodexSkillsRoot) {
  $CodexSkillsRoot = Get-DefaultCodexSkillsRoot
}

$resolvedRepoPath = (Resolve-Path -LiteralPath $SkillRepoPath).Path
$skillName = Split-Path -Path $resolvedRepoPath -Leaf
$installedSkillPath = Join-Path $CodexSkillsRoot $skillName

if (-not $ConfigPath) {
  $ConfigPath = Join-Path (Join-Path $resolvedRepoPath "config") "local-config.json"
}

$resolvedConfigPath = [System.IO.Path]::GetFullPath($ConfigPath)

$checks = New-Object System.Collections.Generic.List[object]

function Add-Check {
  param(
    [string]$Name,
    [string]$Status,
    [string]$Detail
  )

  $checks.Add([pscustomobject]@{
    name = $Name
    status = $Status
    detail = $Detail
  }) | Out-Null
}

Add-Check -Name "skill_repo" -Status "ok" -Detail $resolvedRepoPath

if (!(Test-Path -LiteralPath $installedSkillPath)) {
  throw "Installed skill entry was not found at $installedSkillPath"
}

$installedSkill = Get-Item -LiteralPath $installedSkillPath -Force
$resolvedInstalledTargetPaths = Resolve-InstalledTargetPaths -InstalledPath $installedSkillPath -Item $installedSkill
if (-not $installedSkill.LinkType) {
  Add-Check -Name "skill_link" -Status "warn" -Detail "Installed path exists but is not a link: $installedSkillPath"
} elseif ($resolvedInstalledTargetPaths -notcontains $resolvedRepoPath) {
  $targetDetail = if ($null -eq $installedSkill.Target) { "<unknown>" } elseif ($installedSkill.Target -is [System.Array]) { $installedSkill.Target -join ", " } else { [string]$installedSkill.Target }
  Add-Check -Name "skill_link" -Status "warn" -Detail "Installed skill points to $targetDetail, expected $resolvedRepoPath"
} else {
  Add-Check -Name "skill_link" -Status "ok" -Detail "$installedSkillPath -> $resolvedRepoPath"
}

if (!(Test-Path -LiteralPath $resolvedConfigPath)) {
  throw "Missing local config at $resolvedConfigPath"
}

$config = Get-Content -Raw -LiteralPath $resolvedConfigPath | ConvertFrom-Json
Add-Check -Name "local_config" -Status "ok" -Detail $resolvedConfigPath

$backendSource = if ([string]::IsNullOrWhiteSpace([string]$config.backend_source)) { "repo" } else { [string]$config.backend_source }

if ($backendSource -eq "repo") {
  if ([string]::IsNullOrWhiteSpace($config.backend_repo_path)) {
    throw "local-config.json is missing backend_repo_path"
  }

  $resolvedBackendRepoPath = [System.IO.Path]::GetFullPath([string]$config.backend_repo_path)
  if (!(Test-Path -LiteralPath $resolvedBackendRepoPath)) {
    throw "Configured backend repo was not found at $resolvedBackendRepoPath"
  }
  Add-Check -Name "backend_repo" -Status "ok" -Detail $resolvedBackendRepoPath
} elseif ($backendSource -eq "package") {
  if ([string]::IsNullOrWhiteSpace([string]$config.backend_install_root)) {
    throw "local-config.json is missing backend_install_root"
  }

  $resolvedBackendInstallRoot = [System.IO.Path]::GetFullPath([string]$config.backend_install_root)
  if (!(Test-Path -LiteralPath $resolvedBackendInstallRoot)) {
    throw "Configured backend install root was not found at $resolvedBackendInstallRoot"
  }

  if ([string]::IsNullOrWhiteSpace([string]$config.backend_package_name)) {
    throw "local-config.json is missing backend_package_name"
  }

  $resolvedInstalledPackagePath = Join-Path (Join-Path $resolvedBackendInstallRoot "node_modules") ([string]$config.backend_package_name)
  if (!(Test-Path -LiteralPath $resolvedInstalledPackagePath)) {
    throw "Configured backend package was not found at $resolvedInstalledPackagePath"
  }

  Add-Check -Name "backend_package" -Status "ok" -Detail $resolvedInstalledPackagePath
} else {
  throw "Unsupported backend_source `"$backendSource`"."
}

if ([string]::IsNullOrWhiteSpace($config.bridge_cli_path)) {
  throw "local-config.json is missing bridge_cli_path"
}

$resolvedBridgeCliPath = [System.IO.Path]::GetFullPath([string]$config.bridge_cli_path)
if (!(Test-Path -LiteralPath $resolvedBridgeCliPath)) {
  throw "Configured bridge CLI was not found at $resolvedBridgeCliPath"
}
Add-Check -Name "bridge_cli" -Status "ok" -Detail $resolvedBridgeCliPath

$nodeCommand = Get-Command node -ErrorAction Stop
Add-Check -Name "node" -Status "ok" -Detail $nodeCommand.Source

if ($SmokeTest) {
  $tempDir = Join-Path ([System.IO.Path]::GetTempPath()) ('manage-current-session-habits-check-' + [System.Guid]::NewGuid().ToString('N'))
  New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
  $tempRegistry = Join-Path $tempDir "user_habits.json"
  $invokeScriptPath = Join-Path (Join-Path $resolvedRepoPath "scripts") "invoke-backend.ps1"
  $sampleTranscript = @'
user: 以后我说“收尾一下”就是 close_session 场景=session_close
assistant: 收到。
user: 收尾一下
'@

  try {
    $listOutput = & $invokeScriptPath -Request "列出用户习惯短句" -UserRegistryPath $tempRegistry
    $listParsed = $listOutput | ConvertFrom-Json
    if ($listParsed.action -ne "list") {
      throw "Smoke test list step returned unexpected action: $($listParsed.action)"
    }

    $scanOutput = & $invokeScriptPath -Request "扫描这次会话里的习惯候选" -Transcript $sampleTranscript -UserRegistryPath $tempRegistry
    $scanParsed = $scanOutput | ConvertFrom-Json
    if ($scanParsed.action -ne "suggest") {
      throw "Smoke test scan step returned unexpected action: $($scanParsed.action)"
    }

    if ($scanParsed.candidate_count -lt 1) {
      throw "Smoke test scan step returned no candidates."
    }

    if (-not $scanParsed.assistant_reply_markdown) {
      throw "Smoke test scan step did not return assistant_reply_markdown."
    }

    if (-not $scanParsed.suggested_follow_ups) {
      throw "Smoke test scan step did not return suggested_follow_ups."
    }

    if (-not $scanParsed.next_step_assessment) {
      throw "Smoke test scan step did not return next_step_assessment."
    }

    $applyOutput = & $invokeScriptPath -Request "添加第1条" -UserRegistryPath $tempRegistry
    $applyParsed = $applyOutput | ConvertFrom-Json
    if ($applyParsed.action -ne "apply-candidate") {
      throw "Smoke test apply step returned unexpected action: $($applyParsed.action)"
    }

    if ($applyParsed.applied_rule.phrase -ne "收尾一下") {
      throw "Smoke test apply step returned unexpected phrase: $($applyParsed.applied_rule.phrase)"
    }

    if ($applyParsed.applied_rule.normalized_intent -ne "close_session") {
      throw "Smoke test apply step returned unexpected intent: $($applyParsed.applied_rule.normalized_intent)"
    }

    if (-not $applyParsed.assistant_reply_markdown) {
      throw "Smoke test apply step did not return assistant_reply_markdown."
    }

    if (-not $applyParsed.next_step_assessment) {
      throw "Smoke test apply step did not return next_step_assessment."
    }

    Add-Check -Name "smoke_test_list" -Status "ok" -Detail "Wrapper list invocation succeeded."
    Add-Check -Name "smoke_test_scan" -Status "ok" -Detail "Wrapper scan invocation succeeded with chat-ready bridge fields."
    Add-Check -Name "smoke_test_apply" -Status "ok" -Detail "Wrapper apply invocation succeeded by reusing the cached suggestion."
  } finally {
    if (Test-Path -LiteralPath $tempDir) {
      Remove-Item -LiteralPath $tempDir -Recurse -Force
    }
  }
}

$checks | ForEach-Object {
  Write-Output ("[{0}] {1} - {2}" -f $_.status.ToUpperInvariant(), $_.name, $_.detail)
}
