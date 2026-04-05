param(
  [int]$Days = 30,
  [double]$MinUnlockSuccessRate = 0.90,
  [int]$MinUnlockSampleSize = 10,
  [double]$MinBeneficiaryCoverage = 0.90,
  [double]$MinConsentCoverage = 0.90,
  [int]$MinCohortSizeForCoverageGate = 10,
  [int]$WarnEventThreshold = 50,
  [string]$OutputDir = "ops/reports",
  [switch]$FailOnStatus
)

$ErrorActionPreference = "Stop"

New-Item -ItemType Directory -Force $OutputDir | Out-Null

$stamp = (Get-Date).ToUniversalTime().ToString("yyyyMMdd-HHmmss")
$snapshotPath = Join-Path $OutputDir "beta-status-$stamp.md"

$triageOk = $true
$betaGateOk = $true
$triageError = ""
$betaGateError = ""

try {
  & "$PSScriptRoot/security_triage_report.ps1" -Hours 24 -OutputDir $OutputDir -FailOnCritical -WarnEventThreshold $WarnEventThreshold
} catch {
  $triageOk = $false
  $triageError = "$($_.Exception.Message)"
}

try {
  & "$PSScriptRoot/beta_gate_report.ps1" `
    -Days $Days `
    -MinUnlockSuccessRate $MinUnlockSuccessRate `
    -MinUnlockSampleSize $MinUnlockSampleSize `
    -MinBeneficiaryCoverage $MinBeneficiaryCoverage `
    -MinConsentCoverage $MinConsentCoverage `
    -MinCohortSizeForCoverageGate $MinCohortSizeForCoverageGate `
    -OutputDir $OutputDir `
    -FailOnGate
} catch {
  $betaGateOk = $false
  $betaGateError = "$($_.Exception.Message)"
}

$latestTriage = Get-ChildItem $OutputDir -Filter "security-triage-*.md" -ErrorAction SilentlyContinue |
  Sort-Object LastWriteTime -Descending |
  Select-Object -First 1

$latestBetaGate = Get-ChildItem $OutputDir -Filter "beta-gate-*.md" -ErrorAction SilentlyContinue |
  Sort-Object LastWriteTime -Descending |
  Select-Object -First 1

$overallPass = $triageOk -and $betaGateOk

$lines = New-Object System.Collections.Generic.List[string]
$lines.Add("# Beta Status Snapshot")
$lines.Add("")
$lines.Add("- Generated (UTC): $((Get-Date).ToUniversalTime().ToString("yyyy-MM-dd HH:mm:ss"))")
$lines.Add("- Window days: $Days")
$lines.Add("- Overall status: $(if ($overallPass) { 'PASS' } else { 'FAIL' })")
$lines.Add("")
$lines.Add("## Gate outcomes")
$lines.Add("")
$lines.Add("- Security triage gate: $(if ($triageOk) { 'PASS' } else { 'FAIL' })")
if (-not $triageOk) {
  $lines.Add("- Security triage error: $triageError")
}
$lines.Add("- Beta gate: $(if ($betaGateOk) { 'PASS' } else { 'FAIL' })")
if (-not $betaGateOk) {
  $lines.Add("- Beta gate error: $betaGateError")
}
$lines.Add("")
$lines.Add("## Latest report files")
$lines.Add("")
$lines.Add("- Security triage report: $(if ($null -ne $latestTriage) { $latestTriage.Name } else { 'not found' })")
$lines.Add("- Beta gate report: $(if ($null -ne $latestBetaGate) { $latestBetaGate.Name } else { 'not found' })")
$lines.Add("")
$lines.Add("## Thresholds")
$lines.Add("")
$lines.Add("- Min unlock success rate: $MinUnlockSuccessRate")
$lines.Add("- Min unlock sample size: $MinUnlockSampleSize")
$lines.Add("- Min beneficiary coverage: $MinBeneficiaryCoverage")
$lines.Add("- Min consent coverage: $MinConsentCoverage")
$lines.Add("- Min cohort size for coverage gate: $MinCohortSizeForCoverageGate")
$lines.Add("- Warn event threshold (triage): $WarnEventThreshold")

Set-Content -Path $snapshotPath -Value ($lines -join "`r`n") -Encoding UTF8
Write-Host "Snapshot written: $snapshotPath" -ForegroundColor Green

if ($FailOnStatus -and -not $overallPass) {
  exit 2
}
