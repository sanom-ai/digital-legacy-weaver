param(
  [switch]$SkipCompile
)

$ErrorActionPreference = "Stop"

Write-Host "== Local Quality Gate ==" -ForegroundColor Cyan

function Run-Step([string]$label, [scriptblock]$cmd) {
  Write-Host $label -ForegroundColor Yellow
  & $cmd
  if ($LASTEXITCODE -ne 0) {
    throw "Step failed: $label (exit code $LASTEXITCODE)"
  }
}

if (-not $SkipCompile) {
  Run-Step "[1/6] Python compile check..." { python -m compileall -q . }
}

Run-Step "[2/6] PTN smoke test..." { python tools\ptn_smoke_test.py }
Run-Step "[3/6] PDPA control mapping check..." { python tools\pdpa_control_check.py }
Run-Step "[4/6] Naming cleanliness check..." { python tools\check_naming_clean.py }
Run-Step "[5/6] Proprietary PTN boundary check..." { python tools\check_proprietary_ptn_boundary.py }
Run-Step "[6/6] Unit tests..." { python -m pytest _support/tests }

Write-Host "Local quality gate passed." -ForegroundColor Green
