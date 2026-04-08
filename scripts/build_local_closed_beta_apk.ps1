param(
  [string]$FlutterRoot = "D:\flutter",
  [switch]$SkipPubGet
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

function Resolve-AndroidSdk {
  $fromEnv = [Environment]::GetEnvironmentVariable("ANDROID_HOME")
  if (-not [string]::IsNullOrWhiteSpace($fromEnv) -and (Test-Path $fromEnv)) {
    return $fromEnv
  }

  $fromSdkRoot = [Environment]::GetEnvironmentVariable("ANDROID_SDK_ROOT")
  if (-not [string]::IsNullOrWhiteSpace($fromSdkRoot) -and (Test-Path $fromSdkRoot)) {
    return $fromSdkRoot
  }

  $defaultPath = Join-Path $env:LOCALAPPDATA "Android\Sdk"
  if (Test-Path $defaultPath) {
    return $defaultPath
  }

  throw @"
Android SDK not found.
Install Android SDK (free) via Android Studio or Command-line Tools, then set:
- ANDROID_HOME=<sdk_path>
- ANDROID_SDK_ROOT=<sdk_path>
Expected default path: $defaultPath
"@
}

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$appDir = Join-Path $repoRoot "apps\flutter_app"
$flutter = Resolve-Flutter
$androidSdk = Resolve-AndroidSdk

Write-Host "== Build Local Closed Beta APK ==" -ForegroundColor Cyan
Write-Host "Flutter: $flutter" -ForegroundColor DarkGray
Write-Host "SDK:     $androidSdk" -ForegroundColor DarkGray
Write-Host "App dir:  $appDir" -ForegroundColor DarkGray

Push-Location $appDir
try {
  if (-not $SkipPubGet) {
    Write-Host "Running flutter pub get..." -ForegroundColor Yellow
    & $flutter "pub" "get"
    if ($LASTEXITCODE -ne 0) {
      throw "flutter pub get failed"
    }
  }

  Write-Host "Building release APK (local closed beta flags)..." -ForegroundColor Yellow
  & $flutter "build" "apk" "--release" `
    "--dart-define=LOCAL_CLOSED_BETA_MODE=true" `
    "--dart-define=CLOSED_BETA_MANUAL_CODE=true"
  if ($LASTEXITCODE -ne 0) {
    throw "flutter build apk failed"
  }
}
finally {
  Pop-Location
}

$apkPath = Join-Path $appDir "build\app\outputs\flutter-apk\app-release.apk"
if (-not (Test-Path $apkPath)) {
  throw "APK not found: $apkPath"
}

$releaseDir = Join-Path $repoRoot "ops\reports\apk-builds"
New-Item -ItemType Directory -Path $releaseDir -Force | Out-Null
$stamp = Get-Date -Format "yyyyMMdd-HHmmss"
$copyPath = Join-Path $releaseDir "app-release-local-closed-beta-$stamp.apk"
Copy-Item -LiteralPath $apkPath -Destination $copyPath -Force

Write-Host "" 
Write-Host "[PASS] Local closed beta APK built." -ForegroundColor Green
Write-Host "- Primary APK: $apkPath"
Write-Host "- Archived APK: $copyPath"
