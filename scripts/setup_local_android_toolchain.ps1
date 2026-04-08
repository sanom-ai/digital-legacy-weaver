param(
  [string]$SdkRoot = "$env:LOCALAPPDATA\Android\Sdk",
  [string]$JdkRoot = "$env:LOCALAPPDATA\Programs\DLW\jdk-21",
  [switch]$SkipLicenseAcceptance
)

$ErrorActionPreference = "Stop"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

function Ensure-Directory {
  param([string]$Path)
  if (-not (Test-Path $Path)) {
    New-Item -ItemType Directory -Path $Path -Force | Out-Null
  }
}

function Download-File {
  param(
    [string]$Url,
    [string]$Destination
  )

  Write-Host "Downloading: $Url" -ForegroundColor Yellow
  Invoke-WebRequest -UseBasicParsing -Uri $Url -OutFile $Destination
}

function Ensure-Jdk {
  param([string]$InstallRoot)

  $javaExe = Join-Path $InstallRoot "bin\java.exe"
  if (Test-Path $javaExe) {
    Write-Host "JDK already installed at $InstallRoot" -ForegroundColor DarkGray
    return
  }

  Ensure-Directory -Path $InstallRoot
  $tempDir = Join-Path $env:TEMP "dlw-jdk-setup"
  if (Test-Path $tempDir) {
    Remove-Item -LiteralPath $tempDir -Recurse -Force
  }
  Ensure-Directory -Path $tempDir

  $zipPath = Join-Path $tempDir "jdk.zip"
  $extractPath = Join-Path $tempDir "extract"
  $jdkUrl = "https://download.oracle.com/java/21/latest/jdk-21_windows-x64_bin.zip"

  Download-File -Url $jdkUrl -Destination $zipPath
  Expand-Archive -Path $zipPath -DestinationPath $extractPath -Force

  $jdkFolder = Get-ChildItem -Path $extractPath -Directory | Select-Object -First 1
  if (-not $jdkFolder) {
    throw "JDK extraction failed: no folder found in $extractPath"
  }

  Copy-Item -Path (Join-Path $jdkFolder.FullName "*") -Destination $InstallRoot -Recurse -Force
  if (-not (Test-Path $javaExe)) {
    throw "JDK install failed: $javaExe not found"
  }
}

function Ensure-AndroidCommandLineTools {
  param([string]$InstallRoot)

  $sdkManager = Join-Path $InstallRoot "cmdline-tools\latest\bin\sdkmanager.bat"
  if (Test-Path $sdkManager) {
    Write-Host "Android command-line tools already present." -ForegroundColor DarkGray
    return
  }

  Ensure-Directory -Path $InstallRoot
  $tempDir = Join-Path $env:TEMP "dlw-android-sdk-setup"
  if (Test-Path $tempDir) {
    Remove-Item -LiteralPath $tempDir -Recurse -Force
  }
  Ensure-Directory -Path $tempDir

  $zipPath = Join-Path $tempDir "cmdline-tools.zip"
  $extractPath = Join-Path $tempDir "extract"
  $toolsUrl = "https://dl.google.com/android/repository/commandlinetools-win-13114758_latest.zip"

  Download-File -Url $toolsUrl -Destination $zipPath
  Expand-Archive -Path $zipPath -DestinationPath $extractPath -Force

  $sourceRoot = Join-Path $extractPath "cmdline-tools"
  if (-not (Test-Path $sourceRoot)) {
    throw "Android command-line tools extraction failed: $sourceRoot not found"
  }

  $targetRoot = Join-Path $InstallRoot "cmdline-tools\latest"
  if (Test-Path $targetRoot) {
    Remove-Item -LiteralPath $targetRoot -Recurse -Force
  }
  Ensure-Directory -Path $targetRoot

  Copy-Item -Path (Join-Path $sourceRoot "*") -Destination $targetRoot -Recurse -Force
  if (-not (Test-Path $sdkManager)) {
    throw "Android command-line tools install failed: $sdkManager not found"
  }
}

function Ensure-SdkPackages {
  param(
    [string]$InstallRoot,
    [switch]$SkipLicenses
  )

  $sdkManager = Join-Path $InstallRoot "cmdline-tools\latest\bin\sdkmanager.bat"
  if (-not (Test-Path $sdkManager)) {
    throw "sdkmanager not found: $sdkManager"
  }

  if (-not $SkipLicenses) {
    Write-Host "Accepting Android SDK licenses..." -ForegroundColor Yellow
    1..40 | ForEach-Object { "y" } | & $sdkManager "--sdk_root=$InstallRoot" "--licenses" | Out-Host
    if ($LASTEXITCODE -ne 0) {
      throw "sdkmanager --licenses failed"
    }
  }

  Write-Host "Installing Android SDK packages..." -ForegroundColor Yellow
  & $sdkManager "--sdk_root=$InstallRoot" `
    "platform-tools" `
    "platforms;android-35" `
    "build-tools;35.0.0"
  if ($LASTEXITCODE -ne 0) {
    throw "sdkmanager package install failed"
  }
}

Write-Host "== Setup Local Android Toolchain (no paid services required) ==" -ForegroundColor Cyan
Write-Host "SDK root: $SdkRoot" -ForegroundColor DarkGray
Write-Host "JDK root: $JdkRoot" -ForegroundColor DarkGray

Ensure-Jdk -InstallRoot $JdkRoot
Ensure-AndroidCommandLineTools -InstallRoot $SdkRoot

$env:JAVA_HOME = $JdkRoot
$env:ANDROID_HOME = $SdkRoot
$env:ANDROID_SDK_ROOT = $SdkRoot
$env:Path = "$JdkRoot\bin;$SdkRoot\platform-tools;$SdkRoot\cmdline-tools\latest\bin;$env:Path"

[Environment]::SetEnvironmentVariable("JAVA_HOME", $JdkRoot, "User")
[Environment]::SetEnvironmentVariable("ANDROID_HOME", $SdkRoot, "User")
[Environment]::SetEnvironmentVariable("ANDROID_SDK_ROOT", $SdkRoot, "User")

Ensure-SdkPackages -InstallRoot $SdkRoot -SkipLicenses:$SkipLicenseAcceptance

Write-Host ""
Write-Host "[PASS] Local Android toolchain is ready." -ForegroundColor Green
Write-Host "Open a new PowerShell window, then run:"
Write-Host "  .\\scripts\\build_local_closed_beta_apk.ps1"
