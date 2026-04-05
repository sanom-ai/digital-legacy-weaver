# Release Readiness Checklist (Go/No-Go)

Use this checklist before opening beta or production release.

## 1) Code Quality Gate

1. `quality.yml` passed on latest commit
2. `flutter-quality.yml` passed on latest commit
3. `python tools/ptn_smoke_test.py` passed
4. `python tools/check_naming_clean.py` passed
5. local gate passed:

```powershell
python -m pip install -r requirements-dev.txt
.\scripts\run_local_quality_gate.ps1
```

## 2) Security Gate

1. `security-gate.yml` executed successfully in last 24h
2. No `critical` events in `security_events` for release window
3. No stale or unhealthy dispatch heartbeat
4. `beta-gate.yml` latest run is PASS with no unresolved gate failure

Command:

```powershell
.\scripts\security_triage_report.ps1 -Hours 24 -FailOnCritical -WarnEventThreshold 50
```

## 3) Operational Health

1. Scheduler invokes `dispatch-trigger` as expected
2. `system_heartbeats` has fresh `ok` record (<26h)
3. `health_checks.sql` reviewed and no blocking anomalies
4. `e2e-runtime.yml` latest run on test project completed and artifact evidence is available

## 4) Delivery Safety Flow

1. Reminder stages observed (14/7/1) on test account timeline
2. Final release sends secure access link (no plaintext secret in email)
3. Unlock requires verification code and consumes access key one-time
4. Rate-limit behavior verified (`delivery_access_rate_limits`)

## 5) Mobile/Web Access Path

1. Web `/unlock` route works with query params
2. Mobile deep link `legacyweaver://unlock?...` opens unlock flow
3. Android/iOS native scheme config applied (if mobile target included)

## 6) Data Lifecycle

1. Cleanup RPC exists and runs successfully
2. Retention policy validated (`>= 30 days` recommended)
3. `maintenance-cleanup.yml` configured and scheduled

Command:

```powershell
.\scripts\run_maintenance_cleanup.ps1 -RetentionDays 30
```

## 7) Legal and Product Safeguards

1. Legal disclaimer/consent flow enabled in app
2. Emergency pause and grace period settings tested
3. Incident playbook reviewed by on-call owner
4. Product messaging uses responsible language: assistive delivery workflow, no guaranteed outcome claim
5. High-assurance architecture controls reviewed against `docs/high-assurance-architecture.md`

## 8) Release Decision

Mark each item as:

- `PASS`
- `WAIVER` (with explicit owner + rationale + expiry date)
- `FAIL`

Release decision rule:

1. `GO` only when no `FAIL` remains
2. `GO with WAIVER` allowed only with explicit owner sign-off
3. `NO-GO` if any unresolved security/reliability critical issue exists
