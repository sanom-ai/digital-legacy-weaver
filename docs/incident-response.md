# Incident Response Playbook (v1)

This playbook defines operational actions for security and reliability incidents.

## Severity model

1. `info`: expected behavior logs
2. `warn`: suspicious or degraded behavior requiring review
3. `critical`: immediate intervention required

## Event-to-action mapping

### `rate_limited` (`warn`)

Meaning:
- A client/IP/access-id exceeded allowed request window.

Action:
1. Check whether spikes come from one source or distributed sources.
2. If abusive, keep temporary blocks and monitor repeat patterns.
3. If false positive for valid user, guide user to retry after block window.

### `access_denied` (`warn`)

Meaning:
- Invalid access credentials, expired key, or already-consumed key.

Action:
1. Check if this appears right after expected successful unlock (normal replay).
2. If repeated mismatches from many IPs, escalate as credential-guessing attempt.
3. Consider forcing shorter expiry for new access links if trend rises.

### `invalid_code` (`warn`)

Meaning:
- Verification code mismatch attempts during unlock.

Action:
1. Check attempts trend per access-id.
2. If sustained retries occur, keep lockout and notify owner about suspicious activity.
3. Consider raising second-factor strictness for affected accounts.

### `unlock_success` (`info`)

Meaning:
- Delivery unlock completed successfully.

Action:
1. Verify expected context (owner/mode/time window).
2. Keep as audit evidence.

### `unlock_error` (`warn`)

Meaning:
- General unlock handler error not mapped to a successful action.

Action:
1. Inspect Edge Function logs immediately.
2. If error-rate spikes, treat as service degradation.
3. Apply emergency pause for impacted users if release integrity is uncertain.

## Reliability incidents

### Stale heartbeat

Trigger:
- No `system_heartbeats` `status='ok'` within 26 hours.

Action:
1. Mark incident as `critical`.
2. Validate scheduler and function deployment status.
3. Re-run dispatch manually after root-cause fix.
4. Keep emergency pause available during unstable period.

### Global emergency switch

Use when release integrity is uncertain or active abuse is ongoing:

```powershell
.\scripts\set_global_safety_controls.ps1 -Dispatch off -Unlock off -Reason "Incident response" -UpdatedBy "on-call"
```

Recovery after mitigation:

```powershell
.\scripts\set_global_safety_controls.ps1 -Dispatch on -Unlock on -Reason "Recovered" -UpdatedBy "on-call"
```

Drill command (recommended weekly):

```powershell
.\scripts\safety_control_drill.ps1 -ProjectRef <your_project_ref>
```

Automation option:

- `.github/workflows/safety-drill.yml` (weekly schedule + manual run)
- drill script auto-restores controls in `finally` even when checks fail

## Communication checklist

1. Incident start time and detection method
2. Impact scope (users, modes, duration)
3. Containment action executed
4. Recovery action and verification query
5. Post-incident prevention task

## Triage report command

Generate a quick report from live Supabase data:

```powershell
.\scripts\security_triage_report.ps1 -Hours 24
```

Use as gate/alert mode:

```powershell
.\scripts\security_triage_report.ps1 -Hours 24 -FailOnCritical -WarnEventThreshold 50
```

`-FailOnCritical` exits with code `2` when:

1. any `critical` event is present
2. latest heartbeat is stale (>26h) or unhealthy
3. warn/critical volume exceeds threshold

## GitHub workflow gate

Use workflow:

- `.github/workflows/security-gate.yml`

Required repository secrets:

1. `SUPABASE_URL`
2. `SUPABASE_SERVICE_ROLE_KEY`

Recommended preflight:

```powershell
.\scripts\security_gate_preflight.ps1
```

Output file:

- `ops/reports/security-triage-<timestamp>.md`
