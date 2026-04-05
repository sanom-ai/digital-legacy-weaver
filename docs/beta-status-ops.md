# Beta Status Snapshot Ops

## Purpose

Generate one daily `PASS/FAIL` snapshot that combines:

1. Security triage gate
2. Beta gate scorecard

## Workflow

1. `.github/workflows/beta-status.yml`
2. Runs daily and can be started manually.
3. Publishes `beta-status-reports` artifact.

## Script

1. `scripts/beta_status_snapshot.ps1`

Manual run:

```powershell
.\scripts\beta_status_snapshot.ps1 -Days 30 -FailOnStatus
```

## Output

1. `ops/reports/beta-status-<timestamp>.md`
2. References latest triage and beta-gate reports.

## Use in operations

1. Review this snapshot first in daily beta standup.
2. Expand cohort only when status remains PASS consistently.
