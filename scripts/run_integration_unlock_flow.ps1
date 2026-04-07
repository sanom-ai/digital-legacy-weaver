param(
  [Parameter(Mandatory = $true)]
  [string]$ProjectRef,
  [string]$AnonKey = "",
  [string]$AccessId = "",
  [string]$AccessKey = "",
  [string]$VerificationCode = "",
  [string]$TotpCode = "",
  [switch]$RequirePositiveUnlock
)

$ErrorActionPreference = "Stop"

function Read-ResponseBody([object]$response) {
  if ($null -eq $response) { return "" }
  if ($response.PSObject.Properties.Name -contains "Content") {
    return [string]$response.Content
  }
  return [string]$response
}

function Invoke-JsonPost([string]$url, [hashtable]$headers, [string]$jsonBody) {
  try {
    $resp = Invoke-WebRequest -Uri $url -Method Post -Headers $headers -Body $jsonBody
    return @{
      ok = $true
      status = [int]$resp.StatusCode
      body = Read-ResponseBody $resp
    }
  } catch {
    $statusCode = 0
    if ($_.Exception.Response -and $_.Exception.Response.StatusCode) {
      $statusCode = [int]$_.Exception.Response.StatusCode
    }
    return @{
      ok = $false
      status = $statusCode
      body = Read-ResponseBody $_.Exception.Response
    }
  }
}

if ([string]::IsNullOrWhiteSpace($AnonKey)) {
  $AnonKey = [Environment]::GetEnvironmentVariable("SUPABASE_ANON_KEY")
}
if ([string]::IsNullOrWhiteSpace($AnonKey)) {
  throw "Missing Anon key. Pass -AnonKey or set SUPABASE_ANON_KEY."
}

$baseUrl = "https://$ProjectRef.supabase.co/functions/v1"
$headers = @{
  "apikey"        = $AnonKey
  "Authorization" = "Bearer $AnonKey"
  "Content-Type"  = "application/json"
}

Write-Host "== Integration: dispatch-trigger ==" -ForegroundColor Cyan
$dispatch = Invoke-JsonPost -url "$baseUrl/dispatch-trigger" -headers $headers -jsonBody "{}"
Write-Host "dispatch status: $($dispatch.status)"
Write-Host $dispatch.body
if ($dispatch.status -ne 200) {
  throw "dispatch-trigger failed with HTTP $($dispatch.status)"
}

if ([string]::IsNullOrWhiteSpace($AccessId) -or [string]::IsNullOrWhiteSpace($AccessKey)) {
  if ($RequirePositiveUnlock) {
    throw "RequirePositiveUnlock is enabled but AccessId/AccessKey are missing."
  }
  Write-Host ""
  Write-Host "No AccessId/AccessKey provided, integration unlock flow skipped." -ForegroundColor DarkYellow
  Write-Host "Pass -AccessId and -AccessKey from test trigger logs to continue." -ForegroundColor DarkYellow
  exit 0
}

Write-Host ""
Write-Host "== Integration: request_code ==" -ForegroundColor Cyan
$requestCodeBody = @{
  action = "request_code"
  access_id = $AccessId
  access_key = $AccessKey
} | ConvertTo-Json

$requestCode = Invoke-JsonPost -url "$baseUrl/open-delivery-link" -headers $headers -jsonBody $requestCodeBody
Write-Host "request_code status: $($requestCode.status)"
Write-Host $requestCode.body
if ($requestCode.status -ne 200) {
  throw "request_code failed with HTTP $($requestCode.status)"
}

Write-Host ""
Write-Host "== Integration: unlock negative-path (expected error with fake code) ==" -ForegroundColor Cyan
$negativeUnlockBody = @{
  action = "unlock"
  access_id = $AccessId
  access_key = $AccessKey
  verification_code = "000000"
} | ConvertTo-Json

$negativeUnlock = Invoke-JsonPost -url "$baseUrl/open-delivery-link" -headers $headers -jsonBody $negativeUnlockBody
Write-Host "negative unlock status: $($negativeUnlock.status)"
Write-Host $negativeUnlock.body
if ($negativeUnlock.status -eq 200) {
  throw "negative unlock unexpectedly succeeded with fake verification code."
}

if ([string]::IsNullOrWhiteSpace($VerificationCode)) {
  if ($RequirePositiveUnlock) {
    throw "RequirePositiveUnlock is enabled but VerificationCode is missing."
  }
  Write-Host ""
  Write-Host "No VerificationCode provided, positive unlock check skipped." -ForegroundColor DarkYellow
  Write-Host "Re-run with -VerificationCode <real code> to verify end-to-end success path." -ForegroundColor DarkYellow
  exit 0
}

$positivePayload = @{
  action = "unlock"
  access_id = $AccessId
  access_key = $AccessKey
  verification_code = $VerificationCode
}
if (-not [string]::IsNullOrWhiteSpace($TotpCode)) {
  $positivePayload.totp_code = $TotpCode
}
$positiveUnlockBody = $positivePayload | ConvertTo-Json

Write-Host ""
Write-Host "== Integration: unlock positive-path ==" -ForegroundColor Cyan
$positiveUnlock = Invoke-JsonPost -url "$baseUrl/open-delivery-link" -headers $headers -jsonBody $positiveUnlockBody
Write-Host "positive unlock status: $($positiveUnlock.status)"
Write-Host $positiveUnlock.body
if ($positiveUnlock.status -ne 200) {
  throw "positive unlock failed with HTTP $($positiveUnlock.status)"
}

try {
  $positiveJson = $positiveUnlock.body | ConvertFrom-Json
} catch {
  throw "positive unlock response is not valid JSON."
}

if ($positiveJson.delivery_context.source -ne "live_runtime") {
  throw "positive unlock response missing live runtime delivery context."
}

Write-Host ""
Write-Host "Integration unlock flow passed." -ForegroundColor Green
