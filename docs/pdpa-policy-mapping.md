# PDPA Policy Mapping (Technical Layer)

## Boundary statement (important)

Digital Legacy Weaver is a **technical layer** for policy enforcement, auditability, and secure workflow orchestration.  
It is **not** a legal decision authority and does not replace legal counsel, court orders, or statutory procedures.

## Policy pack source

1. PTN file:
- `examples/pdpa-policy-pack.ptn`

2. Core legal companion reference:
- `docs/legal-companion-mode.md`

## Control mapping

1. Consent and legal gate
- PTN controls:
  - `explicit_consent`
  - `consent_active`
  - `provider_legal_verification_handoff`
- Schema/runtime mapping:
  - `user_safety_settings.legal_disclaimer_accepted`
  - dispatch release notice includes legal-verification handoff:
    - `Legal entitlement verification must be completed directly with the destination app/provider.`
  - legal boundary docs:
    - `docs/legal-companion-mode.md`
    - `docs/legal-evidence-gate.md`

2. Data minimization and no secret-by-email
- PTN controls:
  - `data_minimization`
- Schema/runtime mapping:
  - `recovery_items.encrypted_payload`
  - unlock flow sends one-time link + code, not plaintext vault secret

3. Audit trail and incident response
- PTN controls:
  - `security_event_logging`
  - `incident_escalation`
- Schema/runtime mapping:
  - `security_events`
  - `trigger_logs`
  - ops docs:
    - `docs/incident-response.md`
    - `docs/production-deploy-runbook.md`
  - ops scripts:
    - `scripts/security_triage_report.ps1`
    - `scripts/security_gate_preflight.ps1`

4. Retention and cleanup
- PTN controls:
  - `run_retention_cleanup`
  - `purge_expired_access_material`
- Schema/runtime mapping:
  - migration `20260405_0006_maintenance_cleanup.sql`
  - RPC `run_maintenance_cleanup`
  - script `scripts/run_maintenance_cleanup.ps1`

## End-to-end verification command

Run:

```powershell
python tools\pdpa_control_check.py
```

This check verifies:

1. `examples/pdpa-policy-pack.ptn` is syntactically and semantically valid.
2. Required schema/runtime/ops references for mapped controls are present.
