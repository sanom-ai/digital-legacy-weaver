param(
  [int]$Hours = 24,
  [string]$OutputDir = "ops/reports",
  [switch]$FailOnCritical,
  [int]$WarnEventThreshold = 50
)

$ErrorActionPreference = "Stop"
$script:ApiDegradedReason = $null

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
    "Content-Type" = "application/json"
  }

  if ($ServiceRoleKey -like "eyJ*") {
    $headers["apikey"] = $ServiceRoleKey
    $headers["Authorization"] = "Bearer $ServiceRoleKey"
  } else {
    # New secret API keys (sb_secret...) are not JWTs.
    # Use them as apikey only, without Authorization bearer token.
    $headers["apikey"] = $ServiceRoleKey
  }

  try {
    return Invoke-RestMethod -Method Get -Uri "$BaseUrl/rest/v1/$PathAndQuery" -Headers $headers
  } catch {
    $rawParts = @()
    if ($_.Exception -and $_.Exception.Message) {
      $rawParts += $_.Exception.Message
    }
    if ($_.ErrorDetails -and $_.ErrorDetails.Message) {
      $rawParts += $_.ErrorDetails.Message
    }
    $raw = ($rawParts -join " | ")
    $lower = $raw.ToLowerInvariant()
    $statusCode = $null
    try {
      if ($_.Exception.Response.StatusCode.value__) {
        $statusCode = [int]$_.Exception.Response.StatusCode.value__
      }
    } catch { }

    if ($lower.Contains("forbidden use of secret api key in browser") -or $statusCode -in @(401, 403)) {
      if (-not $script:ApiDegradedReason) {
        $script:ApiDegradedReason = "Supabase rejected CI Data API access (status=$statusCode). Security triage ran in degraded mode (no live event query)."
      }
      return @()
    }
    throw
  }
}

function Group-Count($items, [string]$property) {
  return $items | Group-Object -Property $property | Sort-Object Count -Descending
}

$supabaseUrl = Require-Env "SUPABASE_URL"
$serviceRole = Require-Env "SUPABASE_SERVICE_ROLE_KEY"

$sinceIso = (Get-Date).ToUniversalTime().AddHours(-$Hours).ToString("yyyy-MM-ddTHH:mm:ssZ")

New-Item -ItemType Directory -Force $OutputDir | Out-Null
$stamp = (Get-Date).ToUniversalTime().ToString("yyyyMMdd-HHmmss")
$reportPath = Join-Path $OutputDir "security-triage-$stamp.md"

Write-Host "Generating security triage report..." -ForegroundColor Cyan

$eventsQuery = "security_events?select=event_type,severity,mode,created_at,details&created_at=gte.$sinceIso&order=created_at.desc&limit=1000"
$events = @(Invoke-SupabaseGet -BaseUrl $supabaseUrl -ServiceRoleKey $serviceRole -PathAndQuery $eventsQuery)

$heartbeatsQuery = "system_heartbeats?select=source,status,created_at,details&source=eq.dispatch-trigger&order=created_at.desc&limit=5"
$heartbeats = @(Invoke-SupabaseGet -BaseUrl $supabaseUrl -ServiceRoleKey $serviceRole -PathAndQuery $heartbeatsQuery)

$blocksQuery = "delivery_access_rate_limits?select=scope,attempt_count,blocked_until,last_attempt_at&blocked_until=gt.$sinceIso&order=blocked_until.desc&limit=200"
$activeBlocks = @(Invoke-SupabaseGet -BaseUrl $supabaseUrl -ServiceRoleKey $serviceRole -PathAndQuery $blocksQuery)

$eventTypeCounts = Group-Count $events "event_type"
$severityCounts = Group-Count $events "severity"

$warnOrCritical = @($events | Where-Object { $_.severity -in @("warn", "critical") })
$criticalEvents = @($events | Where-Object { $_.severity -eq "critical" })
$latestHeartbeat = if ($heartbeats.Count -gt 0) { $heartbeats[0] } else { $null }
$heartbeatStale = $false
$heartbeatUnhealthy = $false
if ($null -ne $latestHeartbeat) {
  $hbTime = [DateTime]::Parse($latestHeartbeat.created_at).ToUniversalTime()
  $heartbeatStale = ((Get-Date).ToUniversalTime() - $hbTime).TotalHours -gt 26
  $heartbeatUnhealthy = ($latestHeartbeat.status -ne "ok")
}

$lines = New-Object System.Collections.Generic.List[string]
$lines.Add("# Security Triage Report")
$lines.Add("")
$lines.Add("- Generated (UTC): $((Get-Date).ToUniversalTime().ToString("yyyy-MM-dd HH:mm:ss"))")
$lines.Add("- Window: last $Hours hour(s)")
$lines.Add("- Total security events: $($events.Count)")
$lines.Add("- Warn/Critical events: $($warnOrCritical.Count)")
$lines.Add("- Critical events: $($criticalEvents.Count)")
$lines.Add("- Active rate-limit blocks: $($activeBlocks.Count)")
$lines.Add("- Heartbeat stale (>26h): $heartbeatStale")
$lines.Add("- Heartbeat unhealthy: $heartbeatUnhealthy")
$lines.Add("- API degraded mode: $([string]::IsNullOrWhiteSpace($script:ApiDegradedReason) -ne $true)")
if (-not [string]::IsNullOrWhiteSpace($script:ApiDegradedReason)) {
  $lines.Add("- Degraded reason: $script:ApiDegradedReason")
}
$lines.Add("")

$lines.Add("## Event Type Counts")
if ($eventTypeCounts.Count -eq 0) {
  $lines.Add("- none")
} else {
  foreach ($g in $eventTypeCounts) {
    $lines.Add("- $($g.Name): $($g.Count)")
  }
}
$lines.Add("")

$lines.Add("## Severity Counts")
if ($severityCounts.Count -eq 0) {
  $lines.Add("- none")
} else {
  foreach ($g in $severityCounts) {
    $lines.Add("- $($g.Name): $($g.Count)")
  }
}
$lines.Add("")

$lines.Add("## Latest Dispatch Heartbeat")
if ($null -eq $latestHeartbeat) {
  $lines.Add("- No heartbeat found")
} else {
  $lines.Add("- status: $($latestHeartbeat.status)")
  $lines.Add("- created_at: $($latestHeartbeat.created_at)")
  $lines.Add("- details: $($latestHeartbeat.details | ConvertTo-Json -Compress)")
}
$lines.Add("")

$lines.Add("## Recent Warn/Critical Events (Top 20)")
if ($warnOrCritical.Count -eq 0) {
  $lines.Add("- none")
} else {
  $top = $warnOrCritical | Select-Object -First 20
  foreach ($e in $top) {
    $lines.Add("- [$($e.created_at)] $($e.severity) $($e.event_type) mode=$($e.mode)")
  }
}
$lines.Add("")

$lines.Add("## Active Block Scopes (Top 20)")
if ($activeBlocks.Count -eq 0) {
  $lines.Add("- none")
} else {
  $topBlocks = $activeBlocks | Select-Object -First 20
  foreach ($b in $topBlocks) {
    $lines.Add("- scope=$($b.scope) attempts=$($b.attempt_count) blocked_until=$($b.blocked_until)")
  }
}
$lines.Add("")

$lines.Add("## Recommended Next Actions")
$lines.Add("1. Check `docs/incident-response.md` for any warn/critical patterns shown above.")
$lines.Add("2. If heartbeat is stale or error, run scheduler/function diagnostics immediately.")
$lines.Add("3. If rate-limit spikes persist, review source patterns and tighten unlock controls.")

Set-Content -Path $reportPath -Value ($lines -join "`r`n") -Encoding UTF8
Write-Host "Report written: $reportPath" -ForegroundColor Green

if ($FailOnCritical) {
  $shouldFail = $false
  $reasons = New-Object System.Collections.Generic.List[string]

  if ($criticalEvents.Count -gt 0) {
    $shouldFail = $true
    $reasons.Add("critical events detected: $($criticalEvents.Count)")
  }
  if ($heartbeatStale) {
    $shouldFail = $true
    $reasons.Add("dispatch heartbeat is stale")
  }
  if ($heartbeatUnhealthy) {
    $shouldFail = $true
    $reasons.Add("latest dispatch heartbeat status is not ok")
  }
  if ($warnOrCritical.Count -ge $WarnEventThreshold) {
    $shouldFail = $true
    $reasons.Add("warn/critical event count exceeded threshold ($WarnEventThreshold)")
  }

  if ($shouldFail) {
    Write-Host "Fail-on-critical triggered:" -ForegroundColor Red
    foreach ($reason in $reasons) {
      Write-Host "- $reason" -ForegroundColor Red
    }
    exit 2
  }
  Write-Host "Fail-on-critical checks passed." -ForegroundColor Green
}
