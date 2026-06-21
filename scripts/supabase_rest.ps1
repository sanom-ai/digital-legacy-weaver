$ErrorActionPreference = "Stop"

function New-SupabaseRestHeaders {
  param(
    [Parameter(Mandatory = $true)]
    [string]$ServiceRoleKey,
    [string]$AnonKey = [Environment]::GetEnvironmentVariable("SUPABASE_ANON_KEY")
  )

  $headers = @{
    "Content-Type" = "application/json"
  }

  if ($ServiceRoleKey -like "eyJ*") {
    $headers["apikey"] = $ServiceRoleKey
    $headers["Authorization"] = "Bearer $ServiceRoleKey"
  } else {
    # Supabase secret API keys (sb_secret_...) are server-only bearer tokens.
    # REST still requires a public apikey header, so pair the anon key with service bearer auth.
    if ([string]::IsNullOrWhiteSpace($AnonKey)) {
      throw "Missing environment variable: SUPABASE_ANON_KEY is required when SUPABASE_SERVICE_ROLE_KEY is a secret API key."
    }
    $headers["apikey"] = $AnonKey
    $headers["Authorization"] = "Bearer $ServiceRoleKey"
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

function Test-SupabaseRestAuthUnsupported {
  param(
    [Parameter(Mandatory = $true)]
    [object]$ErrorRecord
  )

  $rawParts = @()
  if ($ErrorRecord.Exception -and $ErrorRecord.Exception.Message) {
    $rawParts += $ErrorRecord.Exception.Message
  }
  if ($ErrorRecord.ErrorDetails -and $ErrorRecord.ErrorDetails.Message) {
    $rawParts += $ErrorRecord.ErrorDetails.Message
  }
  $raw = ($rawParts -join " | ").ToLowerInvariant()

  return $raw.Contains("forbidden use of secret api key in browser") -or
    $raw.Contains("expected 3 parts in jwt") -or
    $raw.Contains("no api key found in request")
}
