# Beta Gate Operations

## Purpose

Automate daily go/no-go checks for controlled beta expansion decisions.

## Workflow

1. `.github/workflows/beta-gate.yml`
2. Runs daily and supports manual execution.
3. Produces artifact set `beta-gate-reports`.

## What is evaluated

1. Critical security event presence.
2. Dispatch heartbeat freshness and health.
3. Unlock success rate against threshold.
4. Final release sent/error trends.
5. Cohort readiness coverage:
- beneficiary configured coverage
- legal companion consent coverage

## Script

1. `scripts/beta_gate_report.ps1`

Manual run example:

```powershell
.\scripts\beta_gate_report.ps1 -Days 30 -MinUnlockSuccessRate 0.90 -MinUnlockSampleSize 10 -FailOnGate
```

Example with coverage gates:

```powershell
.\scripts\beta_gate_report.ps1 -Days 30 -MinUnlockSuccessRate 0.90 -MinUnlockSampleSize 10 -MinBeneficiaryCoverage 0.90 -MinConsentCoverage 0.90 -MinCohortSizeForCoverageGate 10 -FailOnGate
```

## Output

Report file:

1. `ops/reports/beta-gate-<timestamp>.md`

Dashboard SQL:

1. `ops/sql/beta_gate_pack.sql`

## Decision use

1. Use with `docs/closed-beta-checklist.md`.
2. Expand cohort only when gate remains healthy over repeated runs.
