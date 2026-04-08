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

function Ensure-JavaHome {
  $javaFromPath = Get-Command "java" -ErrorAction SilentlyContinue
  if ($javaFromPath) {
    return
  }

  $localJdkRoot = Join-Path $env:LOCALAPPDATA "Programs\DLW\jdk-21"
  $localJavaExe = Join-Path $localJdkRoot "bin\java.exe"
  if (Test-Path $localJavaExe) {
    $env:JAVA_HOME = $localJdkRoot
    $env:Path = "$localJdkRoot\bin;$env:Path"
    return
  }

  throw @"
Java runtime not found.
Install JDK first (recommended):
  .\scripts\setup_local_android_toolchain.ps1
Then run this build script again.
"@
}

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$appDir = Join-Path $repoRoot "apps\flutter_app"
$flutter = Resolve-Flutter
$androidSdk = Resolve-AndroidSdk
Ensure-JavaHome
$bootstrapCreated = $false
$bootstrapGeneratedPaths = @(
  ".gitignore",
  ".metadata",
  "README.md",
  "android",
  "test\widget_test.dart",
  ".idea",
  "digital_legacy_weaver.iml"
)
$preExistingPaths = @{}
foreach ($relativePath in $bootstrapGeneratedPaths) {
  $preExistingPaths[$relativePath] = Test-Path (Join-Path $appDir $relativePath)
}

Write-Host "== Build Local Closed Beta APK ==" -ForegroundColor Cyan
Write-Host "Flutter: $flutter" -ForegroundColor DarkGray
Write-Host "SDK:     $androidSdk" -ForegroundColor DarkGray
Write-Host "App dir:  $appDir" -ForegroundColor DarkGray

Push-Location $appDir
try {
  if (-not (Test-Path (Join-Path $appDir "android\app\build.gradle"))) {
    Write-Host "Android project scaffold not found. Bootstrapping with flutter create..." -ForegroundColor Yellow
    & $flutter "create" "--platforms=android" "--project-name" "digital_legacy_weaver" "."
    if ($LASTEXITCODE -ne 0) {
      throw "flutter create --platforms=android failed"
    }
    $bootstrapCreated = $true
  }

  if (-not $SkipPubGet) {
    Write-Host "Running flutter pub get..." -ForegroundColor Yellow
    & $flutter "pub" "get"
    if ($LASTEXITCODE -ne 0) {
      throw "flutter pub get failed"
    }
  }

  Write-Host "Building release APK (local closed beta flags)..." -ForegroundColor Yellow
  # Stabilize local Windows builds: avoid Kotlin daemon incremental cache
  # errors that can appear after successful APK assembly.
  $gradleTuning = "-Dkotlin.incremental=false -Dkotlin.compiler.execution.strategy=in-process"
  if ([string]::IsNullOrWhiteSpace($env:GRADLE_OPTS)) {
    $env:GRADLE_OPTS = $gradleTuning
  }
  elseif (-not $env:GRADLE_OPTS.Contains("kotlin.incremental=false")) {
    $env:GRADLE_OPTS = "$env:GRADLE_OPTS $gradleTuning"
  }
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

if ($bootstrapCreated) {
  foreach ($relativePath in $bootstrapGeneratedPaths) {
    if ($preExistingPaths[$relativePath]) {
      continue
    }
    $fullPath = Join-Path $appDir $relativePath
    if (Test-Path $fullPath) {
      Remove-Item -LiteralPath $fullPath -Recurse -Force
    }
  }
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
