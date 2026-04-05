param(
  [int]$RetentionDays = 30
)

$ErrorActionPreference = "Stop"

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

$headers = @{
  "apikey"        = $serviceRole
  "Authorization" = "Bearer $serviceRole"
  "Content-Type"  = "application/json"
}

$body = @{ p_retention_days = $RetentionDays } | ConvertTo-Json
$uri = "$supabaseUrl/rest/v1/rpc/run_maintenance_cleanup"

Write-Host "Running maintenance cleanup (retention=$RetentionDays days)..." -ForegroundColor Cyan
$result = Invoke-RestMethod -Method Post -Uri $uri -Headers $headers -Body $body
$result | ConvertTo-Json -Depth 10
