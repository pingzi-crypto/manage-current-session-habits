param(
  [Parameter(Mandatory = $true)]
  [string]$Request,
  [string]$ThreadPath,
  [string]$Transcript,
  [switch]$ThreadStdin,
  [string]$UserRegistryPath,
  [int]$MaxCandidates,
  [string]$ConfigPath = (Join-Path (Join-Path (Join-Path $PSScriptRoot "..") "config") "local-config.json")
)

$ErrorActionPreference = "Stop"
$nodeCommand = Get-Command node -ErrorAction Stop
$scriptPath = Join-Path $PSScriptRoot "invoke-backend.js"

$arguments = @($scriptPath, "--request", $Request, "--config-path", $ConfigPath)
if ($ThreadPath) {
  $arguments += @("--thread-path", $ThreadPath)
}
if ($Transcript) {
  $arguments += @("--transcript", $Transcript)
}
if ($ThreadStdin) {
  $arguments += "--thread-stdin"
}
if ($UserRegistryPath) {
  $arguments += @("--user-registry-path", $UserRegistryPath)
}
if ($PSBoundParameters.ContainsKey("MaxCandidates")) {
  $arguments += @("--max-candidates", [string]$MaxCandidates)
}

& $nodeCommand.Source @arguments
exit $LASTEXITCODE
