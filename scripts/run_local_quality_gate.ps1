param(
  [switch]$SkipCompile,
  [switch]$SkipFlutter
)

$ErrorActionPreference = "Stop"

Write-Host "== Local Quality Gate ==" -ForegroundColor Cyan

function Ensure-PythonUserSiteOnPath {
  $userSite = (python -c "import site; print(site.getusersitepackages())").Trim()
  if (-not $userSite) {
    return
  }

  if (-not (Test-Path $userSite)) {
    return
  }

  if ($env:PYTHONPATH) {
    $paths = $env:PYTHONPATH -split ';'
    if ($paths -contains $userSite) {
      return
    }
    $env:PYTHONPATH = "$userSite;$env:PYTHONPATH"
  } else {
    $env:PYTHONPATH = $userSite
  }

  Write-Host "Python user site added to PYTHONPATH: $userSite" -ForegroundColor DarkGray
}

function Run-Step([string]$label, [scriptblock]$cmd) {
  Write-Host $label -ForegroundColor Yellow
  & $cmd
  if ($LASTEXITCODE -ne 0) {
    throw "Step failed: $label (exit code $LASTEXITCODE)"
  }
}

Ensure-PythonUserSiteOnPath

if (-not $SkipCompile) {
  Run-Step "[1/8] Python compile check..." { python -m compileall -q . }
}

if (-not $SkipFlutter) {
  Run-Step "[2/8] Flutter toolchain validation..." { .\scripts\run_flutter_toolchain_validation.ps1 -SkipBuild }
} else {
  Write-Host "[2/8] Flutter toolchain validation (skipped)" -ForegroundColor DarkYellow
}

Run-Step "[3/8] PTN smoke test..." { python tools\ptn_smoke_test.py }
Run-Step "[4/8] PDPA control mapping check..." { python tools\pdpa_control_check.py }
Run-Step "[5/8] Naming cleanliness check..." { python tools\check_naming_clean.py }
Run-Step "[6/8] Proprietary PTN boundary check..." { python tools\check_proprietary_ptn_boundary.py }
Run-Step "[7/8] Private-first logging guard..." { python tools\check_private_first_logging.py }
Run-Step "[8/9] Repository hygiene check..." { python tools\check_repo_hygiene.py }
Run-Step "[9/9] Unit tests..." { python -m pytest _support/tests }

Write-Host "Local quality gate passed." -ForegroundColor Green
