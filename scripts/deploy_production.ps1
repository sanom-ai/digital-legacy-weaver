param(
  [Parameter(Mandatory = $true)]
  [string]$ProjectRef,
  [switch]$SkipDbPush
)

$ErrorActionPreference = "Stop"

function Require-Cli([string]$name) {
  if (-not (Get-Command $name -ErrorAction SilentlyContinue)) {
    throw "Required CLI not found: $name"
  }
}

function Require-Env([string]$key) {
  $value = [Environment]::GetEnvironmentVariable($key)
  if ([string]::IsNullOrWhiteSpace($value)) {
    throw "Missing environment variable: $key"
  }
  return $value
}

Write-Host "== Digital Legacy Weaver Production Deploy ==" -ForegroundColor Cyan
Require-Cli "supabase"

$supabaseUrl = Require-Env "SUPABASE_URL"
$anonKey = Require-Env "SUPABASE_ANON_KEY"
$serviceRole = Require-Env "SUPABASE_SERVICE_ROLE_KEY"
$deliveryBase = Require-Env "DELIVERY_BASE_URL"
$reviewerApiKey = Require-Env "REVIEWER_API_KEY"
$reviewerAdminApiKey = Require-Env "REVIEWER_ADMIN_API_KEY"
$handoffInternalKey = Require-Env "HANDOFF_INTERNAL_KEY"
$handoffWebhook = [Environment]::GetEnvironmentVariable("HANDOFF_PROVIDER_WEBHOOK_URL")
$handoffSigningSecret = [Environment]::GetEnvironmentVariable("HANDOFF_SIGNING_SECRET")

# At least one provider key is required
$resendKey = [Environment]::GetEnvironmentVariable("RESEND_API_KEY")
$sendgridKey = [Environment]::GetEnvironmentVariable("SENDGRID_API_KEY")
if ([string]::IsNullOrWhiteSpace($resendKey) -and [string]::IsNullOrWhiteSpace($sendgridKey)) {
  throw "Set RESEND_API_KEY or SENDGRID_API_KEY."
}

Write-Host "Linking Supabase project..." -ForegroundColor Yellow
supabase link --project-ref $ProjectRef

if (-not $SkipDbPush) {
  Write-Host "Applying migrations..." -ForegroundColor Yellow
  supabase db push
} else {
  Write-Host "Skipping db push by request." -ForegroundColor DarkYellow
}

Write-Host "Deploying edge functions..." -ForegroundColor Yellow
supabase functions deploy dispatch-trigger
supabase functions deploy open-delivery-link
supabase functions deploy manage-totp-factor
supabase functions deploy review-legal-evidence
supabase functions deploy manage-reviewer-keys
supabase functions deploy handoff-notice

Write-Host "Setting function secrets..." -ForegroundColor Yellow
supabase secrets set `
  SUPABASE_URL=$supabaseUrl `
  SUPABASE_ANON_KEY=$anonKey `
  SUPABASE_SERVICE_ROLE_KEY=$serviceRole `
  DELIVERY_BASE_URL=$deliveryBase `
  REVIEWER_API_KEY=$reviewerApiKey `
  REVIEWER_ADMIN_API_KEY=$reviewerAdminApiKey `
  HANDOFF_INTERNAL_KEY=$handoffInternalKey `
  HANDOFF_PROVIDER_WEBHOOK_URL=$handoffWebhook `
  HANDOFF_SIGNING_SECRET=$handoffSigningSecret `
  RESEND_API_KEY=$resendKey `
  SENDGRID_API_KEY=$sendgridKey

Write-Host ""
Write-Host "== Next manual step: Scheduler ==" -ForegroundColor Cyan
Write-Host "Create a daily schedule to invoke function 'dispatch-trigger' (UTC recommended)." -ForegroundColor White
Write-Host ""
Write-Host "== Post-deploy checks ==" -ForegroundColor Cyan
Write-Host "Run SQL from ops/sql/health_checks.sql in Supabase SQL editor."
