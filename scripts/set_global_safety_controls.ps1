param(
  [Parameter(Mandatory = $true)]
  [ValidateSet("on", "off")]
  [string]$Dispatch,
  [Parameter(Mandatory = $true)]
  [ValidateSet("on", "off")]
  [string]$Unlock,
  [string]$Reason = "",
  [string]$UpdatedBy = "ops"
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

$headers = @{
  "apikey"        = $serviceRole
  "Authorization" = "Bearer $serviceRole"
  "Content-Type"  = "application/json"
}

$body = @{
  p_dispatch_enabled = ($Dispatch -eq "on")
  p_unlock_enabled = ($Unlock -eq "on")
  p_reason = (if ([string]::IsNullOrWhiteSpace($Reason)) { $null } else { $Reason })
  p_updated_by = $UpdatedBy
} | ConvertTo-Json

$uri = "$supabaseUrl/rest/v1/rpc/set_system_safety_controls"
Write-Host "Updating global safety controls..." -ForegroundColor Cyan
$result = Invoke-RestMethod -Method Post -Uri $uri -Headers $headers -Body $body
$result | ConvertTo-Json -Depth 5
