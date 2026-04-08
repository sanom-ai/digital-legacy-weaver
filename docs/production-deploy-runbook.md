# Production Deploy Runbook

## Preconditions

1. Supabase project created and reachable
2. Supabase CLI installed and authenticated
3. Runtime secrets prepared. See [Runtime Secrets Setup](./runtime-secrets-setup.md)
4. Environment variables are set:
- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`
- `SUPABASE_SERVICE_ROLE_KEY`
- `DELIVERY_BASE_URL`
- `REVIEWER_API_KEY`
- `REVIEWER_ADMIN_API_KEY`
- `HANDOFF_INTERNAL_KEY`
- at least one of: `RESEND_API_KEY`, `SENDGRID_API_KEY`
- optional: `HANDOFF_PROVIDER_WEBHOOK_URL`, `HANDOFF_SIGNING_SECRET`

## Deploy command

```powershell
.\scripts\deploy_production.ps1 -ProjectRef <your_project_ref>
```

Optional:

```powershell
.\scripts\deploy_production.ps1 -ProjectRef <your_project_ref> -SkipDbPush
```

## What the script does

1. Validates required env vars and CLI
2. Links Supabase project
3. Applies migrations (`supabase db push`)
4. Deploys functions:
- `dispatch-trigger`
- `open-delivery-link`
- `manage-totp-factor`
- `review-legal-evidence`
- `manage-reviewer-keys`
- `handoff-notice`
5. Sets function secrets

## Scheduler setup (manual)

Choose one primary scheduler for `dispatch-trigger`:

1. GitHub Actions workflow `Runtime Dispatch AI Ops` (recommended, hourly).
2. External scheduler (UptimeRobot/Cron-job.org) calling the function endpoint.

Recommended cadence: hourly with alerting if missed.

## Post-deploy verification

1. Run SQL in `ops/sql/health_checks.sql`
2. Confirm fresh heartbeat (`status='ok'`)
3. Confirm no stale heartbeat (`is_stale=false`)
4. Trigger a non-production test account flow end-to-end:
- reminder stage log
- final release secure link
- unlock via verification code
5. Confirm recipient link opens `/unlock` route directly in web app
6. Confirm mobile deep link opens unlock flow:
- `legacyweaver://unlock?access_id=<id>&access_key=<key>`
7. Verify maintenance RPC exists and can run:
- `.\scripts\run_maintenance_cleanup.ps1 -RetentionDays 30`

## Automated smoke check

Run:

```powershell
.\scripts\post_deploy_smoke.ps1 -ProjectRef <your_project_ref>
```

Optional with real access credentials from test flow:

```powershell
.\scripts\post_deploy_smoke.ps1 -ProjectRef <your_project_ref> -AccessId <access_id> -AccessKey <access_key>
```

Notes:

1. Without real access credentials, `open-delivery-link` checks run as negative-path validation (expected controlled errors).
2. With real credentials, `request_code` should succeed and `unlock` should require the real verification code.

## Incident fallback

If heartbeat is stale or dispatch fails:

1. Enable emergency pause for impacted users
2. Investigate function logs and provider outage
3. Switch email provider fallback key if needed
4. Re-run dispatch manually after fix
