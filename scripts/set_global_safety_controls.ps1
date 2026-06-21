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

$body = @{
  p_dispatch_enabled = ($Dispatch -eq "on")
  p_unlock_enabled = ($Unlock -eq "on")
  p_reason = (if ([string]::IsNullOrWhiteSpace($Reason)) { $null } else { $Reason })
  p_updated_by = $UpdatedBy
} | ConvertTo-Json

Write-Host "Updating global safety controls..." -ForegroundColor Cyan
$result = Invoke-SupabaseRest -Method Post -BaseUrl $supabaseUrl -ServiceRoleKey $serviceRole -PathAndQuery "rpc/set_system_safety_controls" -Body $body
$result | ConvertTo-Json -Depth 5
