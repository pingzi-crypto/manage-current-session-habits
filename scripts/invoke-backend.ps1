param(
  [Parameter(Mandatory = $true)]
  [string]$Request,
  [string]$ThreadPath,
  [string]$Transcript,
  [switch]$ThreadStdin,
  [string]$UserRegistryPath,
  [int]$MaxCandidates,
  [string]$ConfigPath = (Join-Path $PSScriptRoot "..\\config\\local-config.json")
)

$ErrorActionPreference = "Stop"

$threadSources = @(
  [bool]$ThreadPath,
  [bool]$Transcript,
  [bool]$ThreadStdin
) | Where-Object { $_ }

if ($threadSources.Count -gt 1) {
  throw "Use only one thread source: -ThreadPath, -Transcript, or -ThreadStdin."
}

$resolvedConfigPath = [System.IO.Path]::GetFullPath($ConfigPath)
if (!(Test-Path -LiteralPath $resolvedConfigPath)) {
  throw "Missing local config at $resolvedConfigPath. Run scripts/install-skill.ps1 first."
}

$config = Get-Content -Raw -LiteralPath $resolvedConfigPath | ConvertFrom-Json
$bridgeCliPath = $config.bridge_cli_path

if ([string]::IsNullOrWhiteSpace($bridgeCliPath)) {
  throw "local-config.json must include bridge_cli_path."
}

$resolvedBridgeCliPath = [System.IO.Path]::GetFullPath($bridgeCliPath)
if (!(Test-Path -LiteralPath $resolvedBridgeCliPath)) {
  throw "Configured bridge CLI was not found at $resolvedBridgeCliPath."
}

$null = Get-Command node -ErrorAction Stop

$commandArgs = @(
  "--request",
  $Request
)

if ($ThreadStdin) {
  $commandArgs += "--thread-stdin"
}

if ($ThreadPath) {
  $commandArgs += @("--thread", $ThreadPath)
}

if ($Transcript) {
  $commandArgs += "--thread-stdin"
}

if ($UserRegistryPath) {
  $commandArgs += @("--user-registry", $UserRegistryPath)
}

if ($PSBoundParameters.ContainsKey("MaxCandidates")) {
  $commandArgs += @("--max-candidates", [string]$MaxCandidates)
}

if ($Transcript) {
  if ([string]::IsNullOrWhiteSpace($Transcript)) {
    throw "-Transcript requires non-empty text."
  }

  if ([System.IO.Path]::GetExtension($resolvedBridgeCliPath) -ieq ".js") {
    $Transcript | & node $resolvedBridgeCliPath @commandArgs
  } else {
    $Transcript | & $resolvedBridgeCliPath @commandArgs
  }
  exit $LASTEXITCODE
}

if ($ThreadStdin) {
  $stdinText = [Console]::In.ReadToEnd()

  if ([string]::IsNullOrWhiteSpace($stdinText)) {
    throw "-ThreadStdin requires non-empty stdin input."
  }

  if ([System.IO.Path]::GetExtension($resolvedBridgeCliPath) -ieq ".js") {
    $stdinText | & node $resolvedBridgeCliPath @commandArgs
  } else {
    $stdinText | & $resolvedBridgeCliPath @commandArgs
  }
  exit $LASTEXITCODE
}

if ([System.IO.Path]::GetExtension($resolvedBridgeCliPath) -ieq ".js") {
  & node $resolvedBridgeCliPath @commandArgs
} else {
  & $resolvedBridgeCliPath @commandArgs
}
exit $LASTEXITCODE
