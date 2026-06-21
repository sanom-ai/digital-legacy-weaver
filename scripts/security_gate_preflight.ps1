param(
  [switch]$CheckTables = $true
)

$ErrorActionPreference = "Stop"
. "$PSScriptRoot/supabase_rest.ps1"

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
  return Invoke-SupabaseRest -Method Get -BaseUrl $BaseUrl -ServiceRoleKey $ServiceRoleKey -PathAndQuery $PathAndQuery
}

Write-Host "== Security Gate Preflight ==" -ForegroundColor Cyan
$supabaseUrl = Require-Env "SUPABASE_URL"
$serviceRole = Require-Env "SUPABASE_SERVICE_ROLE_KEY"

if ($supabaseUrl -notmatch "^https://") {
  throw "SUPABASE_URL must start with https://"
}

Write-Host "Checking REST connectivity..." -ForegroundColor Yellow
$hb = Invoke-SupabaseGet -BaseUrl $supabaseUrl -ServiceRoleKey $serviceRole -PathAndQuery "system_heartbeats?select=id&limit=1"
Write-Host "REST connectivity OK." -ForegroundColor Green

if ($CheckTables) {
  Write-Host "Checking required tables..." -ForegroundColor Yellow
  $checks = @(
    "security_events?select=id&limit=1",
    "delivery_access_rate_limits?select=scope&limit=1",
    "system_heartbeats?select=id&limit=1",
    "trigger_dispatch_events?select=id&limit=1"
  )
  foreach ($query in $checks) {
    Invoke-SupabaseGet -BaseUrl $supabaseUrl -ServiceRoleKey $serviceRole -PathAndQuery $query | Out-Null
  }
  Write-Host "Required tables reachable." -ForegroundColor Green
}

Write-Host "Preflight passed." -ForegroundColor Green
