param(
  [switch]$SkipPubGet,
  [switch]$SkipBuild
)

$ErrorActionPreference = "Stop"

function Run-Step([string]$Label, [scriptblock]$Command) {
  Write-Host $Label -ForegroundColor Yellow
  & $Command
  if ($LASTEXITCODE -ne 0) {
    throw "Step failed: $Label (exit code $LASTEXITCODE)"
  }
}

Write-Host "== Flutter Toolchain Validation ==" -ForegroundColor Cyan

$flutter = Get-Command flutter -ErrorAction SilentlyContinue
if (-not $flutter) {
  throw "Flutter is not in PATH. Add <flutter_sdk>\bin to PATH, then re-run this script."
}

$appDir = Join-Path $PSScriptRoot "..\apps\flutter_app"
Push-Location $appDir
try {
  Run-Step "[1/5] flutter --version" { flutter --version }
  if (-not $SkipPubGet) {
    Run-Step "[2/5] flutter pub get" { flutter pub get }
  } else {
    Write-Host "[2/5] flutter pub get (skipped)" -ForegroundColor DarkYellow
  }
  Run-Step "[3/5] flutter analyze" { flutter analyze }
  Run-Step "[4/5] flutter test" { flutter test }
  if (-not $SkipBuild) {
    Run-Step "[5/5] flutter build windows --debug" { flutter build windows --debug }
  } else {
    Write-Host "[5/5] flutter build windows --debug (skipped)" -ForegroundColor DarkYellow
  }
} finally {
  Pop-Location
}

Write-Host "Flutter toolchain validation passed." -ForegroundColor Green
