param(
  [int]$RetentionDays = 30
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

$supabaseUrl = Require-Env "SUPABASE_URL"
$serviceRole = Require-Env "SUPABASE_SERVICE_ROLE_KEY"

if ($RetentionDays -lt 7) {
  throw "RetentionDays must be >= 7"
}

$body = @{ p_retention_days = $RetentionDays } | ConvertTo-Json

Write-Host "Running maintenance cleanup (retention=$RetentionDays days)..." -ForegroundColor Cyan
$result = Invoke-SupabaseRest -Method Post -BaseUrl $supabaseUrl -ServiceRoleKey $serviceRole -PathAndQuery "rpc/run_maintenance_cleanup" -Body $body
$result | ConvertTo-Json -Depth 10
