param(
  [Parameter(Mandatory = $true)]
  [string]$ProjectRef,
  [string]$AnonKey = "",
  [string]$AccessId = "",
  [string]$AccessKey = ""
)

$ErrorActionPreference = "Stop"

function Require-Cli([string]$name) {
  if (-not (Get-Command $name -ErrorAction SilentlyContinue)) {
    throw "Required CLI not found: $name"
  }
}

function Read-ResponseBody([object]$response) {
  if ($null -eq $response) { return "" }
  if ($response.PSObject.Properties.Name -contains "Content") {
    return [string]$response.Content
  }
  return [string]$response
}

Require-Cli "supabase"

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

Write-Host "== Smoke: dispatch-trigger ==" -ForegroundColor Cyan
$dispatchResponse = Invoke-WebRequest -Uri "$baseUrl/dispatch-trigger" -Method Post -Headers $headers -Body "{}"
Write-Host "Status: $($dispatchResponse.StatusCode)" -ForegroundColor Yellow
Write-Host (Read-ResponseBody $dispatchResponse)

Write-Host ""
Write-Host "== Smoke: open-delivery-link/request_code ==" -ForegroundColor Cyan
if ([string]::IsNullOrWhiteSpace($AccessId) -or [string]::IsNullOrWhiteSpace($AccessKey)) {
  Write-Host "No access credentials provided, running negative-path validation check..." -ForegroundColor DarkYellow
  $requestBody = @{ action = "request_code"; access_id = "00000000-0000-0000-0000-000000000000"; access_key = "invalid" } | ConvertTo-Json
} else {
  $requestBody = @{ action = "request_code"; access_id = $AccessId; access_key = $AccessKey } | ConvertTo-Json
}

try {
  $requestCodeResponse = Invoke-WebRequest -Uri "$baseUrl/open-delivery-link" -Method Post -Headers $headers -Body $requestBody
  Write-Host "Status: $($requestCodeResponse.StatusCode)" -ForegroundColor Yellow
  Write-Host (Read-ResponseBody $requestCodeResponse)
} catch {
  $errorBody = Read-ResponseBody $_.Exception.Response
  Write-Host "Expected error path or invalid access key result:" -ForegroundColor DarkYellow
  Write-Host $errorBody
}

Write-Host ""
Write-Host "== Smoke: open-delivery-link/unlock ==" -ForegroundColor Cyan
$unlockAccessId = if ([string]::IsNullOrWhiteSpace($AccessId)) { "00000000-0000-0000-0000-000000000000" } else { $AccessId }
$unlockAccessKey = if ([string]::IsNullOrWhiteSpace($AccessKey)) { "invalid" } else { $AccessKey }
$unlockBody = @{
  action = "unlock"
  access_id = $unlockAccessId
  access_key = $unlockAccessKey
  verification_code = "000000"
} | ConvertTo-Json

try {
  $unlockResponse = Invoke-WebRequest -Uri "$baseUrl/open-delivery-link" -Method Post -Headers $headers -Body $unlockBody
  Write-Host "Status: $($unlockResponse.StatusCode)" -ForegroundColor Yellow
  Write-Host (Read-ResponseBody $unlockResponse)
} catch {
  $errorBody = Read-ResponseBody $_.Exception.Response
  Write-Host "Expected error path or invalid code/access key result:" -ForegroundColor DarkYellow
  Write-Host $errorBody
}

Write-Host ""
Write-Host "== Smoke: manage-totp-factor/status (auth contract) ==" -ForegroundColor Cyan
$totpBody = @{ action = "status" } | ConvertTo-Json
try {
  $totpResponse = Invoke-WebRequest -Uri "$baseUrl/manage-totp-factor" -Method Post -Headers $headers -Body $totpBody
  Write-Host "Status: $($totpResponse.StatusCode)" -ForegroundColor Yellow
  Write-Host (Read-ResponseBody $totpResponse)
} catch {
  $errorBody = Read-ResponseBody $_.Exception.Response
  Write-Host "Expected auth-required response when no user session token is provided:" -ForegroundColor DarkYellow
  Write-Host $errorBody
}

Write-Host ""
Write-Host "== Smoke: review-legal-evidence/review (reviewer auth contract) ==" -ForegroundColor Cyan
$reviewBody = @{
  action = "review"
  evidence_id = "00000000-0000-0000-0000-000000000000"
  reviewer_ref = "smoke-reviewer"
  decision = "approved"
} | ConvertTo-Json
try {
  $reviewResponse = Invoke-WebRequest -Uri "$baseUrl/review-legal-evidence" -Method Post -Headers $headers -Body $reviewBody
  Write-Host "Status: $($reviewResponse.StatusCode)" -ForegroundColor Yellow
  Write-Host (Read-ResponseBody $reviewResponse)
} catch {
  $errorBody = Read-ResponseBody $_.Exception.Response
  Write-Host "Expected reviewer-auth-required response when x-reviewer-key is missing:" -ForegroundColor DarkYellow
  Write-Host $errorBody
}

Write-Host ""
Write-Host "== Smoke: manage-reviewer-keys/list_keys (admin auth contract) ==" -ForegroundColor Cyan
$reviewerAdminBody = @{ action = "list_keys" } | ConvertTo-Json
try {
  $reviewerAdminResponse = Invoke-WebRequest -Uri "$baseUrl/manage-reviewer-keys" -Method Post -Headers $headers -Body $reviewerAdminBody
  Write-Host "Status: $($reviewerAdminResponse.StatusCode)" -ForegroundColor Yellow
  Write-Host (Read-ResponseBody $reviewerAdminResponse)
} catch {
  $errorBody = Read-ResponseBody $_.Exception.Response
  Write-Host "Expected reviewer-admin-auth-required response when x-reviewer-admin-key is missing:" -ForegroundColor DarkYellow
  Write-Host $errorBody
}

Write-Host ""
Write-Host "== Smoke: runtime-status (reviewer auth contract) ==" -ForegroundColor Cyan
$runtimeBody = @{ window_hours = 24 } | ConvertTo-Json
try {
  $runtimeResponse = Invoke-WebRequest -Uri "$baseUrl/runtime-status" -Method Post -Headers $headers -Body $runtimeBody
  Write-Host "Status: $($runtimeResponse.StatusCode)" -ForegroundColor Yellow
  Write-Host (Read-ResponseBody $runtimeResponse)
} catch {
  $errorBody = Read-ResponseBody $_.Exception.Response
  Write-Host "Expected reviewer-auth-required response when x-reviewer-key is missing:" -ForegroundColor DarkYellow
  Write-Host $errorBody
}

Write-Host ""
Write-Host "== Smoke: handoff-notice (internal auth contract) ==" -ForegroundColor Cyan
$handoffBody = @{
  case_id = "smoke-case-legacy"
  owner_ref = "00000000-0000-0000-0000-000000000000"
  beneficiary_ref = "beneficiary@example.com"
  mode = "legacy"
  trigger_timestamp = "2026-04-05T00:00:00.000Z"
  handoff_disclaimer = "Legal entitlement verification must be completed directly with the destination app/provider."
  audit_reference = "smoke-test"
} | ConvertTo-Json
try {
  $handoffResponse = Invoke-WebRequest -Uri "$baseUrl/handoff-notice" -Method Post -Headers $headers -Body $handoffBody
  Write-Host "Status: $($handoffResponse.StatusCode)" -ForegroundColor Yellow
  Write-Host (Read-ResponseBody $handoffResponse)
} catch {
  $errorBody = Read-ResponseBody $_.Exception.Response
  Write-Host "Expected handoff-auth-required response when x-handoff-internal-key is missing:" -ForegroundColor DarkYellow
  Write-Host $errorBody
}

Write-Host ""
Write-Host "Smoke checks completed." -ForegroundColor Green
