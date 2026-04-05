# Closed Beta Checklist

## Goal

Run a controlled beta with clear operational safety gates and measurable outcomes.

## Pre-beta setup

1. Select a controlled cohort (20-50 users max for first wave).
2. Assign on-call owner and incident backup owner.
3. Confirm scheduler, heartbeat, and global safety switch are active.
4. Confirm release notification templates include provider handoff disclaimer.

## Entry criteria

1. `python tools\check_naming_clean.py` passes.
2. `python tools\ptn_smoke_test.py` passes.
3. `python tools\pdpa_control_check.py` passes.
4. `python -m pytest _support/tests` passes.
5. `security_triage_report.ps1 -FailOnCritical` has no critical findings.

## Daily operations

1. Review heartbeat freshness and dispatch status.
2. Review unlock success/error ratio.
3. Review rate-limit events and invalid-code spikes.
4. Review handoff notices and partner ack backlog.
5. Review incident queue and run emergency pause if needed.
6. Review latest `e2e-runtime-reports` artifact set from CI.
7. Review latest `beta-gate-reports` artifact set from CI.
8. Review latest `beta-status-reports` snapshot artifact from CI.

## Weekly review

1. Reminder-to-alive interaction trend.
2. Unlock success trend.
3. False-trigger candidate review (manual sampling).
4. Partner handoff completion trend.
5. Open incidents by severity and age.

## Exit criteria (expand cohort)

1. Critical incidents in 30 days: `0`.
2. Stale heartbeat incidents in 30 days: `0`.
3. Unlock success rate above internal threshold.
4. No unresolved high-severity security issue.
5. On-call runbook completeness verified.
6. Beneficiary setup coverage and consent coverage both meet beta gate threshold.
