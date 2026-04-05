param(
  [Parameter(Mandatory = $true)]
  [string]$ProjectRef,
  [string]$AnonKey = ""
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
      status = [int]$resp.StatusCode
      body = Read-ResponseBody $resp
    }
  } catch {
    $statusCode = 0
    if ($_.Exception.Response -and $_.Exception.Response.StatusCode) {
      $statusCode = [int]$_.Exception.Response.StatusCode
    }
    return @{
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

Write-Host "== Adversarial: method misuse on open-delivery-link ==" -ForegroundColor Cyan
try {
  $getResponse = Invoke-WebRequest -Uri "$baseUrl/open-delivery-link" -Method Get -Headers $headers
  $getStatus = [int]$getResponse.StatusCode
  $getBody = Read-ResponseBody $getResponse
} catch {
  $getStatus = [int]$_.Exception.Response.StatusCode
  $getBody = Read-ResponseBody $_.Exception.Response
}
Write-Host "GET status: $getStatus"
Write-Host $getBody
if ($getStatus -ne 405) {
  throw "Expected 405 for GET on open-delivery-link, got $getStatus"
}

Write-Host ""
Write-Host "== Adversarial: malformed payload ==" -ForegroundColor Cyan
$badPayload = @{ action = "unlock" } | ConvertTo-Json
$badResult = Invoke-JsonPost -url "$baseUrl/open-delivery-link" -headers $headers -jsonBody $badPayload
Write-Host "Malformed payload status: $($badResult.status)"
Write-Host $badResult.body
if ($badResult.status -ne 400) {
  throw "Expected 400 for malformed payload, got $($badResult.status)"
}

Write-Host ""
Write-Host "== Adversarial: brute-force style request_code spam (expect rate limit) ==" -ForegroundColor Cyan
$fakeAccessId = "11111111-1111-1111-1111-111111111111"
$fakeAccessKey = "invalid-key"
$rateLimited = $false
for ($i = 1; $i -le 7; $i++) {
  $body = @{
    action = "request_code"
    access_id = $fakeAccessId
    access_key = $fakeAccessKey
  } | ConvertTo-Json
  $attempt = Invoke-JsonPost -url "$baseUrl/open-delivery-link" -headers $headers -jsonBody $body
  Write-Host "Attempt $i status: $($attempt.status)"
  if ($attempt.body -match "Too many attempts") {
    $rateLimited = $true
    break
  }
}
if (-not $rateLimited) {
  throw "Rate-limit threshold was not observed in adversarial request_code loop."
}

Write-Host ""
Write-Host "== Adversarial: handoff endpoint unauthorized without internal key ==" -ForegroundColor Cyan
$handoffBody = @{
  case_id = "adversarial-case"
  owner_ref = "00000000-0000-0000-0000-000000000000"
  mode = "legacy"
  trigger_timestamp = "2026-04-05T00:00:00.000Z"
  handoff_disclaimer = "Legal entitlement verification must be completed directly with the destination app/provider."
} | ConvertTo-Json
$handoffResult = Invoke-JsonPost -url "$baseUrl/handoff-notice" -headers $headers -jsonBody $handoffBody
Write-Host "handoff status: $($handoffResult.status)"
Write-Host $handoffResult.body
if ($handoffResult.status -ne 401) {
  throw "Expected 401 for handoff-notice without internal key, got $($handoffResult.status)"
}

Write-Host ""
Write-Host "Adversarial checks passed." -ForegroundColor Green
