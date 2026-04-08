param(
  [string]$FlutterRoot = "D:\flutter",
  [string]$DeviceId = ""
)

$ErrorActionPreference = "Stop"

function Resolve-Flutter {
  $fromPath = Get-Command "flutter" -ErrorAction SilentlyContinue
  if ($fromPath) {
    return $fromPath.Source
  }

  $fallback = Join-Path $FlutterRoot "bin\flutter.bat"
  if (Test-Path $fallback) {
    return $fallback
  }

  throw "Flutter CLI not found. Set PATH or pass -FlutterRoot."
}

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$appDir = Join-Path $repoRoot "apps\flutter_app"
$flutter = Resolve-Flutter

Write-Host "== Run Local Closed Beta Mode ==" -ForegroundColor Cyan
Write-Host "Flutter: $flutter" -ForegroundColor DarkGray
Write-Host "App dir:  $appDir" -ForegroundColor DarkGray

Push-Location $appDir
try {
  & $flutter "pub" "get"
  if ($LASTEXITCODE -ne 0) {
    throw "flutter pub get failed"
  }

  $args = @(
    "run",
    "--dart-define=LOCAL_CLOSED_BETA_MODE=true",
    "--dart-define=CLOSED_BETA_MANUAL_CODE=true"
  )
  if (-not [string]::IsNullOrWhiteSpace($DeviceId)) {
    $args += @("-d", $DeviceId)
  }

  & $flutter @args
  if ($LASTEXITCODE -ne 0) {
    throw "flutter run failed"
  }
}
finally {
  Pop-Location
}
