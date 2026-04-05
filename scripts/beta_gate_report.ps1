param(
  [int]$Days = 30,
  [double]$MinUnlockSuccessRate = 0.90,
  [int]$MinUnlockSampleSize = 10,
  [double]$MinBeneficiaryCoverage = 0.90,
  [double]$MinConsentCoverage = 0.90,
  [int]$MinCohortSizeForCoverageGate = 10,
  [string]$OutputDir = "ops/reports",
  [switch]$FailOnGate
)

$ErrorActionPreference = "Stop"

function Require-Env([string]$key) {
  $value = [Environment]::GetEnvironmentVariable($key)
  if ([string]::IsNullOrWhiteSpace($value)) {
    throw "Missing environment variable: $key"
  }
  return $value
}

function Invoke-SupabaseGet {
  param(
    [string]$BaseUrl,
    [string]$ServiceRoleKey,
    [string]$PathAndQuery
  )
  $headers = @{
    "apikey"        = $ServiceRoleKey
    "Authorization" = "Bearer $ServiceRoleKey"
    "Content-Type"  = "application/json"
  }
  return Invoke-RestMethod -Method Get -Uri "$BaseUrl/rest/v1/$PathAndQuery" -Headers $headers
}

$supabaseUrl = Require-Env "SUPABASE_URL"
$serviceRole = Require-Env "SUPABASE_SERVICE_ROLE_KEY"

$sinceIso = (Get-Date).ToUniversalTime().AddDays(-$Days).ToString("yyyy-MM-ddTHH:mm:ssZ")

New-Item -ItemType Directory -Force $OutputDir | Out-Null
$stamp = (Get-Date).ToUniversalTime().ToString("yyyyMMdd-HHmmss")
$reportPath = Join-Path $OutputDir "beta-gate-$stamp.md"

Write-Host "Generating beta gate report..." -ForegroundColor Cyan

$securityQuery = "security_events?select=event_type,severity,created_at&created_at=gte.$sinceIso&order=created_at.desc&limit=5000"
$events = @(Invoke-SupabaseGet -BaseUrl $supabaseUrl -ServiceRoleKey $serviceRole -PathAndQuery $securityQuery)

$dispatchQuery = "trigger_dispatch_events?select=status,stage,created_at&created_at=gte.$sinceIso&order=created_at.desc&limit=5000"
$dispatchEvents = @(Invoke-SupabaseGet -BaseUrl $supabaseUrl -ServiceRoleKey $serviceRole -PathAndQuery $dispatchQuery)

$profilesQuery = "profiles?select=id,beneficiary_email,created_at&created_at=gte.$sinceIso&limit=5000"
$profiles = @(Invoke-SupabaseGet -BaseUrl $supabaseUrl -ServiceRoleKey $serviceRole -PathAndQuery $profilesQuery)

$settingsQuery = "user_safety_settings?select=owner_id,legal_disclaimer_accepted&limit=5000"
$settings = @(Invoke-SupabaseGet -BaseUrl $supabaseUrl -ServiceRoleKey $serviceRole -PathAndQuery $settingsQuery)

$heartbeatQuery = "system_heartbeats?select=status,created_at,source&source=eq.dispatch-trigger&order=created_at.desc&limit=1"
$heartbeats = @(Invoke-SupabaseGet -BaseUrl $supabaseUrl -ServiceRoleKey $serviceRole -PathAndQuery $heartbeatQuery)

$latestHeartbeat = if ($heartbeats.Count -gt 0) { $heartbeats[0] } else { $null }
$heartbeatStale = $true
$heartbeatUnhealthy = $true
if ($null -ne $latestHeartbeat) {
  $hbTime = [DateTime]::Parse($latestHeartbeat.created_at).ToUniversalTime()
  $heartbeatStale = ((Get-Date).ToUniversalTime() - $hbTime).TotalHours -gt 26
  $heartbeatUnhealthy = ($latestHeartbeat.status -ne "ok")
}

$criticalEvents = @($events | Where-Object { $_.severity -eq "critical" })
$unlockSuccess = @($events | Where-Object { $_.event_type -eq "unlock_success" }).Count
$unlockError = @($events | Where-Object { $_.event_type -eq "unlock_error" }).Count
$unlockTotal = $unlockSuccess + $unlockError
$unlockRate = if ($unlockTotal -gt 0) { [Math]::Round(($unlockSuccess / $unlockTotal), 4) } else { 1.0 }
$unlockSampleEnough = $unlockTotal -ge $MinUnlockSampleSize
$unlockGatePass = (-not $unlockSampleEnough) -or ($unlockRate -ge $MinUnlockSuccessRate)

$finalReleaseSent = @($dispatchEvents | Where-Object { $_.stage -eq "final_release" -and $_.status -eq "sent" }).Count
$finalReleaseError = @($dispatchEvents | Where-Object { $_.stage -eq "final_release" -and $_.status -eq "error" }).Count

$cohortProfiles = @($profiles)
$cohortCount = $cohortProfiles.Count
$beneficiarySetCount = @(
  $cohortProfiles | Where-Object {
    $email = "$($_.beneficiary_email)".Trim()
    -not [string]::IsNullOrWhiteSpace($email)
  }
).Count

$settingsByOwner = @{}
foreach ($row in $settings) {
  $settingsByOwner["$($row.owner_id)"] = [bool]$row.legal_disclaimer_accepted
}

$consentAcceptedCount = 0
foreach ($profile in $cohortProfiles) {
  $ownerId = "$($profile.id)"
  if ($settingsByOwner.ContainsKey($ownerId) -and $settingsByOwner[$ownerId]) {
    $consentAcceptedCount += 1
  }
}

$beneficiaryCoverage = if ($cohortCount -gt 0) { [Math]::Round(($beneficiarySetCount / $cohortCount), 4) } else { 1.0 }
$consentCoverage = if ($cohortCount -gt 0) { [Math]::Round(($consentAcceptedCount / $cohortCount), 4) } else { 1.0 }
$coverageGateEnabled = $cohortCount -ge $MinCohortSizeForCoverageGate
$beneficiaryGatePass = (-not $coverageGateEnabled) -or ($beneficiaryCoverage -ge $MinBeneficiaryCoverage)
$consentGatePass = (-not $coverageGateEnabled) -or ($consentCoverage -ge $MinConsentCoverage)

$lines = New-Object System.Collections.Generic.List[string]
$lines.Add("# Beta Gate Report")
$lines.Add("")
$lines.Add("- Generated (UTC): $((Get-Date).ToUniversalTime().ToString("yyyy-MM-dd HH:mm:ss"))")
$lines.Add("- Window: last $Days day(s)")
$lines.Add("- Min unlock success threshold: $MinUnlockSuccessRate")
$lines.Add("- Min unlock sample size: $MinUnlockSampleSize")
$lines.Add("- Min beneficiary coverage: $MinBeneficiaryCoverage")
$lines.Add("- Min consent coverage: $MinConsentCoverage")
$lines.Add("- Min cohort size for coverage gate: $MinCohortSizeForCoverageGate")
$lines.Add("")
$lines.Add("## Metrics")
$lines.Add("")
$lines.Add("- Critical security events: $($criticalEvents.Count)")
$lines.Add("- Latest dispatch heartbeat stale (>26h): $heartbeatStale")
$lines.Add("- Latest dispatch heartbeat unhealthy: $heartbeatUnhealthy")
$lines.Add("- Unlock success count: $unlockSuccess")
$lines.Add("- Unlock error count: $unlockError")
$lines.Add("- Unlock sample size: $unlockTotal")
$lines.Add("- Unlock success rate: $unlockRate")
$lines.Add("- Final release sent count: $finalReleaseSent")
$lines.Add("- Final release error count: $finalReleaseError")
$lines.Add("- Cohort profile count: $cohortCount")
$lines.Add("- Beneficiary configured count: $beneficiarySetCount")
$lines.Add("- Beneficiary coverage: $beneficiaryCoverage")
$lines.Add("- Consent accepted count: $consentAcceptedCount")
$lines.Add("- Consent coverage: $consentCoverage")
$lines.Add("- Coverage gate enabled: $coverageGateEnabled")
$lines.Add("")

$gateFailReasons = New-Object System.Collections.Generic.List[string]
if ($criticalEvents.Count -gt 0) { $gateFailReasons.Add("Critical security events detected.") }
if ($heartbeatStale) { $gateFailReasons.Add("Dispatch heartbeat is stale.") }
if ($heartbeatUnhealthy) { $gateFailReasons.Add("Dispatch heartbeat status is not ok.") }
if (-not $unlockGatePass) { $gateFailReasons.Add("Unlock success rate below threshold.") }
if (-not $beneficiaryGatePass) { $gateFailReasons.Add("Beneficiary coverage below threshold.") }
if (-not $consentGatePass) { $gateFailReasons.Add("Consent coverage below threshold.") }

$gatePass = $gateFailReasons.Count -eq 0
$lines.Add("## Gate Verdict")
$lines.Add("")
if ($gatePass) {
  $lines.Add("- PASS")
} else {
  $lines.Add("- FAIL")
  foreach ($reason in $gateFailReasons) {
    $lines.Add("- $reason")
  }
}
$lines.Add("")
$lines.Add("## Notes")
$lines.Add("")
$lines.Add("1. If unlock sample size is below threshold, unlock-rate gate is informational only.")
$lines.Add("2. If cohort size is below threshold, coverage gates are informational only.")
$lines.Add("3. Keep legal-boundary messaging explicit in all release flows.")

Set-Content -Path $reportPath -Value ($lines -join "`r`n") -Encoding UTF8
Write-Host "Report written: $reportPath" -ForegroundColor Green

if ($FailOnGate -and -not $gatePass) {
  Write-Host "Beta gate failed." -ForegroundColor Red
  exit 2
}
