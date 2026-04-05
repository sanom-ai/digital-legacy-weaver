# GitHub Test Secrets Setup

Use a dedicated Supabase test project for CI runtime checks.

## Required repository secrets

1. `SUPABASE_TEST_PROJECT_REF`
2. `SUPABASE_TEST_ANON_KEY`

## Optional strict-mode secrets

Use these when you want CI to require positive unlock success:

1. `E2E_TEST_ACCESS_ID`
2. `E2E_TEST_ACCESS_KEY`
3. `E2E_TEST_VERIFICATION_CODE`
4. `E2E_TEST_TOTP_CODE` (only when TOTP is enabled)

Repository variable:

1. `E2E_REQUIRE_POSITIVE_UNLOCK=true`

Strict mode requirements:

1. `E2E_TEST_ACCESS_ID` must be set
2. `E2E_TEST_ACCESS_KEY` must be set
3. `E2E_TEST_VERIFICATION_CODE` must be set
4. Workflow preflight will fail immediately if any required strict secret is missing

## Setup steps

1. Open GitHub repository settings.
2. Go to `Secrets and variables` -> `Actions`.
3. Add both required secrets.
4. (Optional) Add strict-mode secrets and set `E2E_REQUIRE_POSITIVE_UNLOCK=true`.
5. Trigger workflow `E2E Runtime Checks` manually once.
6. Verify artifact `e2e-runtime-reports` is uploaded.

## Safety notes

1. Never point test secrets to production project.
2. Use a dedicated test tenant with synthetic data only.
3. Rotate test keys regularly (recommended every 30-90 days).
