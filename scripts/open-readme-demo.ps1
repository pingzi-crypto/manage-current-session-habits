param(
  [string]$ScreenToGifPath = "C:\Users\pz\AppData\Local\Programs\ScreenToGif\ScreenToGif.exe",
  [string]$DemoPagePath = (Join-Path $PSScriptRoot "..\references\readme-short-demo.html")
)

$ErrorActionPreference = "Stop"

$resolvedDemoPagePath = [System.IO.Path]::GetFullPath($DemoPagePath)
if (!(Test-Path -LiteralPath $resolvedDemoPagePath)) {
  throw "Demo page was not found at $resolvedDemoPagePath"
}

$resolvedScreenToGifPath = [System.IO.Path]::GetFullPath($ScreenToGifPath)
if (!(Test-Path -LiteralPath $resolvedScreenToGifPath)) {
  throw "ScreenToGif was not found at $resolvedScreenToGifPath"
}

Start-Process -FilePath $resolvedDemoPagePath | Out-Null
Start-Sleep -Milliseconds 800
Start-Process -FilePath $resolvedScreenToGifPath | Out-Null

Write-Output "Opened demo page: $resolvedDemoPagePath"
Write-Output "Opened ScreenToGif: $resolvedScreenToGifPath"
Write-Output "Suggested capture:"
Write-Output "1. In ScreenToGif choose Recorder."
Write-Output "2. Frame only the browser demo area."
Write-Output "3. Record one 8-15s loop."
Write-Output "4. Export as GIF for README use."
