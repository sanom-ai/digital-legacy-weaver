param(
  [string]$FlutterAppDir = "apps/flutter_app"
)

$ErrorActionPreference = "Stop"

$androidManifest = Join-Path $FlutterAppDir "android/app/src/main/AndroidManifest.xml"
$iosInfoPlist = Join-Path $FlutterAppDir "ios/Runner/Info.plist"

$androidSnippetPath = Join-Path $FlutterAppDir "native/android/AndroidManifest.deep-link.xml"
$iosSnippetPath = Join-Path $FlutterAppDir "native/ios/Info.plist.deep-link.xml"

if (-not (Test-Path $androidSnippetPath)) { throw "Missing snippet: $androidSnippetPath" }
if (-not (Test-Path $iosSnippetPath)) { throw "Missing snippet: $iosSnippetPath" }

if (-not (Test-Path $androidManifest) -or -not (Test-Path $iosInfoPlist)) {
  Write-Host "Native folders not found yet." -ForegroundColor Yellow
  Write-Host "Run in app directory first: flutter create ." -ForegroundColor Yellow
  exit 1
}

$androidManifestContent = Get-Content $androidManifest -Raw
$androidSnippet = Get-Content $androidSnippetPath -Raw
$androidMarker = 'android:host="unlock"'

if ($androidManifestContent -notmatch [regex]::Escape($androidMarker)) {
  $mainActivityClose = "</activity>"
  $idx = $androidManifestContent.IndexOf($mainActivityClose)
  if ($idx -lt 0) { throw "Could not find </activity> in AndroidManifest.xml" }
  $updatedAndroid = $androidManifestContent.Insert($idx, "`r`n$androidSnippet`r`n")
  Set-Content -Path $androidManifest -Value $updatedAndroid -NoNewline
  Write-Host "Applied Android deep link snippet." -ForegroundColor Green
} else {
  Write-Host "Android deep link already configured." -ForegroundColor DarkYellow
}

$iosInfoPlistContent = Get-Content $iosInfoPlist -Raw
$iosSnippet = Get-Content $iosSnippetPath -Raw
$iosMarker = "<string>legacyweaver</string>"

if ($iosInfoPlistContent -notmatch [regex]::Escape($iosMarker)) {
  $dictClose = "</dict>"
  $idx = $iosInfoPlistContent.LastIndexOf($dictClose)
  if ($idx -lt 0) { throw "Could not find closing </dict> in Info.plist" }
  $updatedIos = $iosInfoPlistContent.Insert($idx, "`r`n$iosSnippet`r`n")
  Set-Content -Path $iosInfoPlist -Value $updatedIos -NoNewline
  Write-Host "Applied iOS deep link snippet." -ForegroundColor Green
} else {
  Write-Host "iOS deep link already configured." -ForegroundColor DarkYellow
}

Write-Host "Done." -ForegroundColor Cyan
