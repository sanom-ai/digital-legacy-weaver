param(
  [string]$OutputDir = "ops/reports",
  [string]$BackupDir = "ops/backups"
)

$ErrorActionPreference = "Stop"

function Get-RelativeHashMap([string]$RootPath) {
  $root = (Resolve-Path $RootPath).Path
  $files = Get-ChildItem -LiteralPath $root -File -Recurse
  $map = @{}
  foreach ($file in $files) {
    $hash = (Get-FileHash -Algorithm SHA256 -LiteralPath $file.FullName).Hash
    $relative = $file.FullName.Substring($root.Length).TrimStart('\','/')
    $map[$relative] = $hash
  }
  return $map
}

function Merge-HashMaps([hashtable]$left, [hashtable]$right, [string]$prefix) {
  foreach ($key in $right.Keys) {
    $left["$prefix/$key"] = $right[$key]
  }
}

$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$workspace = (Get-Location).Path
$backupRoot = Join-Path $workspace $BackupDir
$reportRoot = Join-Path $workspace $OutputDir
New-Item -ItemType Directory -Force -Path $backupRoot | Out-Null
New-Item -ItemType Directory -Force -Path $reportRoot | Out-Null

$sources = @(
  "supabase/migrations",
  "ops/sql",
  "scripts"
)

$zipPath = Join-Path $backupRoot "backup-smoke-$timestamp.zip"
$restoreRoot = Join-Path $env:TEMP "digital-legacy-weaver-restore-$timestamp"
$stagingRoot = Join-Path $env:TEMP "digital-legacy-weaver-backup-src-$timestamp"

if (Test-Path $restoreRoot) {
  Remove-Item -LiteralPath $restoreRoot -Recurse -Force
}
New-Item -ItemType Directory -Force -Path $restoreRoot | Out-Null

if (Test-Path $stagingRoot) {
  Remove-Item -LiteralPath $stagingRoot -Recurse -Force
}
New-Item -ItemType Directory -Force -Path $stagingRoot | Out-Null

foreach ($source in $sources) {
  $sourcePath = Join-Path $workspace $source
  $targetPath = Join-Path $stagingRoot $source
  New-Item -ItemType Directory -Force -Path (Split-Path -Parent $targetPath) | Out-Null
  Copy-Item -LiteralPath $sourcePath -Destination $targetPath -Recurse -Force
}

Compress-Archive -Path (Join-Path $stagingRoot '*') -DestinationPath $zipPath -Force
Expand-Archive -LiteralPath $zipPath -DestinationPath $restoreRoot -Force

$sourceHashes = @{}
$restoreHashes = @{}

foreach ($source in $sources) {
  $sourcePath = Join-Path $workspace $source
  $restoredPath = Join-Path $restoreRoot $source

  $sourceMap = Get-RelativeHashMap -RootPath $sourcePath
  $restoreMap = Get-RelativeHashMap -RootPath $restoredPath

  Merge-HashMaps -left $sourceHashes -right $sourceMap -prefix $source
  Merge-HashMaps -left $restoreHashes -right $restoreMap -prefix $source
}

$allKeys = @($sourceHashes.Keys + $restoreHashes.Keys | Sort-Object -Unique)
$mismatches = @()
foreach ($key in $allKeys) {
  $left = $sourceHashes[$key]
  $right = $restoreHashes[$key]
  if ($left -ne $right) {
    $mismatches += $key
  }
}

$status = if ($mismatches.Count -eq 0) { "PASS" } else { "FAIL" }
$reportPath = Join-Path $reportRoot "backup-restore-smoke-$timestamp.md"

$lines = @()
$lines += "# Backup/Restore Smoke Test Report"
$lines += ""
$lines += "- Timestamp: $(Get-Date -Format o)"
$lines += "- Workspace: $workspace"
$lines += "- Backup archive: $zipPath"
$lines += "- Restore root: $restoreRoot"
$lines += "- Source paths: $($sources -join ', ')"
$lines += "- Files compared: $($allKeys.Count)"
$lines += "- Result: $status"
$lines += ""

if ($mismatches.Count -gt 0) {
  $lines += "## Mismatches"
  foreach ($item in $mismatches) {
    $lines += "- $item"
  }
} else {
  $lines += "## Verification"
  $lines += "- All source files matched restored files by SHA256."
}

Set-Content -LiteralPath $reportPath -Value ($lines -join "`r`n") -Encoding UTF8
Write-Host "Backup/restore smoke report written: $reportPath" -ForegroundColor Green

if ($status -ne "PASS") {
  throw "Backup/restore smoke test failed. See report: $reportPath"
}
