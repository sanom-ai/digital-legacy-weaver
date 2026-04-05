# E2E and Adversarial Test Pack

## Purpose

Run repeatable environment-level checks for high-risk legacy release flows.

## Scripts

1. Integration unlock flow:
- `scripts/run_integration_unlock_flow.ps1`
- Covers: dispatch trigger, request code, unlock negative path, optional unlock positive path

2. Adversarial checks:
- `scripts/run_adversarial_unlock_checks.ps1`
- Covers: method misuse, malformed payload handling, rate-limit behavior, internal handoff auth boundary

## Usage

Integration baseline:

```powershell
.\scripts\run_integration_unlock_flow.ps1 -ProjectRef <project_ref>
```

Integration with real test access credentials:

```powershell
.\scripts\run_integration_unlock_flow.ps1 -ProjectRef <project_ref> -AccessId <access_id> -AccessKey <access_key> -VerificationCode <code>
```

If TOTP is required:

```powershell
.\scripts\run_integration_unlock_flow.ps1 -ProjectRef <project_ref> -AccessId <access_id> -AccessKey <access_key> -VerificationCode <code> -TotpCode <totp>
```

Adversarial suite:

```powershell
.\scripts\run_adversarial_unlock_checks.ps1 -ProjectRef <project_ref>
```

## Operational expectation

1. Run integration script on every release candidate.
2. Run adversarial script at least daily in beta and before every production rollout.
3. Record pass/fail evidence in release checklist and incident timeline.

## CI automation

Automated workflow:

1. `.github/workflows/e2e-runtime.yml`
2. Runs every 6 hours and supports manual run.
3. Uses isolated test-project secrets:
- `SUPABASE_TEST_PROJECT_REF`
- `SUPABASE_TEST_ANON_KEY`
4. Uploads runtime evidence artifacts:
- `ops/reports/e2e-runtime-integration.txt`
- `ops/reports/e2e-runtime-adversarial.txt`
- `ops/reports/e2e-runtime-summary.md`
5. Fails fast if required test secrets are missing.
6. Supports strict positive unlock mode via:
- secrets: `E2E_TEST_ACCESS_ID`, `E2E_TEST_ACCESS_KEY`, `E2E_TEST_VERIFICATION_CODE`, `E2E_TEST_TOTP_CODE`
- repository variable: `E2E_REQUIRE_POSITIVE_UNLOCK=true`
7. Writes summary to GitHub Actions step summary for quick status review.
8. Always uploads runtime artifacts, then enforces pass/fail gate at the end.

Setup reference:

1. `docs/github-test-secrets-setup.md`

## Notes

1. This test pack validates runtime behavior on deployed infrastructure.
2. It does not replace legal process verification at destination providers.
3. Platform remains technical coordination layer only.
