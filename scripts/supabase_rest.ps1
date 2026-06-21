$ErrorActionPreference = "Stop"

function New-SupabaseRestHeaders {
  param(
    [Parameter(Mandatory = $true)]
    [string]$ServiceRoleKey
  )

  $headers = @{
    "Content-Type" = "application/json"
  }

  if ($ServiceRoleKey -like "eyJ*") {
    $headers["apikey"] = $ServiceRoleKey
    $headers["Authorization"] = "Bearer $ServiceRoleKey"
  } else {
    # Supabase secret API keys (sb_secret_...) are not JWT bearer tokens.
    # Sending them as Authorization can make REST reject the request as browser use.
    $headers["apikey"] = $ServiceRoleKey
  }

  return $headers
}

function Invoke-SupabaseRest {
  param(
    [Parameter(Mandatory = $true)]
    [ValidateSet("Get", "Post", "Patch", "Delete")]
    [string]$Method,
    [Parameter(Mandatory = $true)]
    [string]$BaseUrl,
    [Parameter(Mandatory = $true)]
    [string]$ServiceRoleKey,
    [Parameter(Mandatory = $true)]
    [string]$PathAndQuery,
    [object]$Body = $null
  )

  $headers = New-SupabaseRestHeaders -ServiceRoleKey $ServiceRoleKey
  $uri = "$BaseUrl/rest/v1/$PathAndQuery"
  if ($null -eq $Body) {
    return Invoke-RestMethod -Method $Method -Uri $uri -Headers $headers
  }

  return Invoke-RestMethod -Method $Method -Uri $uri -Headers $headers -Body $Body
}
