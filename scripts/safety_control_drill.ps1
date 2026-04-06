param(
  [Parameter(Mandatory = $true)]
  [string]$ProjectRef,
  [string]$AnonKey = "",
  [string]$UpdatedBy = "on-call-drill",
  [string]$OutputDir = "ops/reports"
)

$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.Net.Http

function Require-Env([string]$key) {
  $value = [Environment]::GetEnvironmentVariable($key)
  if ([string]::IsNullOrWhiteSpace($value)) {
    throw "Missing environment variable: $key"
  }
  return $value
}

function Ensure-AnonKey([string]$value) {
  if (-not [string]::IsNullOrWhiteSpace($value)) { return $value }
  $envKey = [Environment]::GetEnvironmentVariable("SUPABASE_ANON_KEY")
  if ([string]::IsNullOrWhiteSpace($envKey)) {
    throw "Missing Anon key. Pass -AnonKey or set SUPABASE_ANON_KEY."
  }
  return $envKey
}

$supabaseUrl = Require-Env "SUPABASE_URL"
$serviceRole = Require-Env "SUPABASE_SERVICE_ROLE_KEY"
$anon = Ensure-AnonKey $AnonKey
$baseFn = "https://$ProjectRef.supabase.co/functions/v1"
$workspace = (Get-Location).Path
$reportRoot = Join-Path $workspace $OutputDir
New-Item -ItemType Directory -Force -Path $reportRoot | Out-Null
$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$reportPath = Join-Path $reportRoot "safety-control-drill-$timestamp.md"
$result = "FAIL"
$failureReason = ""

$serviceHeaders = @{
  "apikey"        = $serviceRole
  "Authorization" = "Bearer $serviceRole"
  "Content-Type"  = "application/json"
}

$fnHeaders = @{
  "apikey"        = $anon
  "Authorization" = "Bearer $anon"
  "Content-Type"  = "application/json"
}

function Set-Safety([bool]$dispatchEnabled, [bool]$unlockEnabled, [string]$reason) {
  $uri = "$supabaseUrl/rest/v1/rpc/set_system_safety_controls"
  $body = @{
    p_dispatch_enabled = $dispatchEnabled
    p_unlock_enabled = $unlockEnabled
    p_reason = $reason
    p_updated_by = $UpdatedBy
  } | ConvertTo-Json
  Invoke-RestMethod -Method Post -Uri $uri -Headers $serviceHeaders -Body $body | Out-Null
}

function Try-Invoke([string]$url, [string]$body) {
  $anon = $fnHeaders["apikey"]
  $client = [System.Net.Http.HttpClient]::new()
  try {
    $request = [System.Net.Http.HttpRequestMessage]::new([System.Net.Http.HttpMethod]::Post, $url)
    $request.Headers.Add("apikey", $anon)
    $request.Headers.Authorization = [System.Net.Http.Headers.AuthenticationHeaderValue]::new("Bearer", $anon)
    $request.Content = [System.Net.Http.StringContent]::new($body, [System.Text.Encoding]::UTF8, "application/json")
    $response = $client.SendAsync($request).Result
    $content = $response.Content.ReadAsStringAsync().Result
    return @{
      status = [int]$response.StatusCode
      body = [string]$content
    }
  } catch {
    return @{
      status = -1
      body = [string]$_
    }
  } finally {
    $client.Dispose()
  }
}

Write-Host "== Safety Control Drill ==" -ForegroundColor Cyan
$disabled = $false
try {
  Write-Host "Step 1: Disable dispatch/unlock globally" -ForegroundColor Yellow
  Set-Safety -dispatchEnabled:$false -unlockEnabled:$false -reason "safety drill"
  $disabled = $true

  Write-Host "Step 2: Verify dispatch is skipped" -ForegroundColor Yellow
  $dispatch = Try-Invoke -url "$baseFn/dispatch-trigger" -body "{}"
  Write-Host "dispatch status: $($dispatch.status)"
  Write-Host $dispatch.body
  if ([int]$dispatch.status -ne 200) {
    throw "Drill failed: dispatch-trigger did not return HTTP 200 while disabled."
  }
  if ($dispatch.body -notmatch "skipped" -and $dispatch.body -notmatch '"ok"\s*:\s*true') {
    throw "Drill failed: dispatch-trigger response did not indicate safe no-op mode while disabled."
  }

  Write-Host "Step 3: Verify unlock is blocked (503 expected)" -ForegroundColor Yellow
  $unlockPayload = @{
    action = "request_code"
    access_id = "00000000-0000-0000-0000-000000000000"
    access_key = "invalid"
  } | ConvertTo-Json -Compress
  $unlock = Try-Invoke -url "$baseFn/open-delivery-link" -body $unlockPayload
  Write-Host "unlock status: $($unlock.status)"
  Write-Host $unlock.body
  if ([int]$unlock.status -ne 503) {
    throw "Drill failed: open-delivery-link did not return HTTP 503 while disabled."
  }

  Write-Host "Drill checks passed." -ForegroundColor Green
  $result = "PASS"
}
finally {
  if ($result -ne "PASS") {
    $failureReason = "Drill ended before all checks completed."
  }
  if ($disabled) {
    Write-Host "Step 4: Re-enable dispatch/unlock globally" -ForegroundColor Yellow
    Set-Safety -dispatchEnabled:$true -unlockEnabled:$true -reason "safety drill completed"
    Write-Host "Safety controls restored." -ForegroundColor Green
  }

  $lines = @()
  $lines += "# Safety Control Drill Report"
  $lines += ""
  $lines += "- Timestamp: $(Get-Date -Format o)"
  $lines += "- ProjectRef: $ProjectRef"
  $lines += "- UpdatedBy: $UpdatedBy"
  $lines += "- Result: $result"
  if (-not [string]::IsNullOrWhiteSpace($failureReason)) {
    $lines += "- FailureReason: $failureReason"
  }
  Set-Content -LiteralPath $reportPath -Value ($lines -join "`r`n") -Encoding UTF8
  Write-Host "Safety drill report written: $reportPath" -ForegroundColor Green
}
