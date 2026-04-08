# First Launch Execution (Operator Playbook)

Use this playbook to move from repository-ready to first controlled public usage.

## Phase 1: CI and runtime readiness

1. Configure GitHub test secrets:
- `SUPABASE_TEST_PROJECT_REF`
- `SUPABASE_TEST_ANON_KEY`

2. Optional strict mode:
- secrets: `E2E_TEST_ACCESS_ID`, `E2E_TEST_ACCESS_KEY`, `E2E_TEST_VERIFICATION_CODE`, `E2E_TEST_TOTP_CODE`
- variable: `E2E_REQUIRE_POSITIVE_UNLOCK=true`

3. Run workflow `E2E Runtime Checks` manually once.
4. Confirm artifact `e2e-runtime-reports` exists with:
- `e2e-runtime-integration.txt`
- `e2e-runtime-adversarial.txt`
- `e2e-runtime-summary.md`
5. Confirm `flutter-quality.yml` is green on latest `main`.

## Phase 1.5: App onboarding readiness

1. Confirm dashboard shows "Complete setup for beta" card for new users.
2. Confirm setup wizard saves:
- beneficiary email
- inactivity thresholds
- legal companion consent
3. Confirm setup card disappears after completion.

## Phase 2: App artifact release

1. Run workflow `App Release Pack`.
2. Input tag (example `v0.1.0`) and prerelease mode.
3. Confirm GitHub Release contains:
- `app-release.aab`
- `app-release.apk`
- `digital-legacy-weaver-windows.zip`

## Phase 3: Controlled beta launch

1. Start with 20-50 users max.
2. Assign on-call owner and backup.
3. Verify:
- heartbeat freshness
- unlock success/error trend
- rate-limit and security event trend

Use:

1. `docs/closed-beta-checklist.md`
2. `docs/release-readiness-checklist.md`
3. `docs/e2e-test-pack.md`

## Decision rule

1. Do not claim production-stable until release readiness is green and runtime evidence remains healthy over time.
2. Keep legal boundary messaging explicit in app, docs, and partner handoff.
