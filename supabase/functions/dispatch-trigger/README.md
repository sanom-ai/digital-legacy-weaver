# dispatch-trigger

Edge Function to run dead-man-switch checks for both modes:

- `self_recovery`
- `legacy`

## Behavior

1. Load latest active PTN from `policy_documents`
2. Compile PTN and evaluate action permissions for `system_scheduler`
3. Write scheduler heartbeat into `system_heartbeats`
4. Load runtime trigger schedule from `delivery_trigger_schedules` (supports `inactivity`, `exact_date`, and `manual_release`)
5. Apply user safety controls (`user_safety_settings`):
- legal consent gate
- emergency pause
- reminder stages (14/7/1 default)
- final grace period before release
6. Enforce idempotent dispatch via `trigger_dispatch_events` unique key
7. Generate one-time secure delivery link (`delivery_access_keys`)
8. Send via provider fallback (Resend -> SendGrid)
9. Submit provider handoff notice via `handoff-notice`
10. Append result in `trigger_logs`

Companion endpoint:

- `open-delivery-link`: verifies second factor and consumes one-time access key before releasing encrypted bundle.
- `handoff-notice`: records handoff context and optionally forwards signed webhook to destination provider workflow.

Global safety control:

- If `system_safety_controls.dispatch_enabled = false`, dispatcher exits safely and records heartbeat warning.

## Required environment variables

- `SUPABASE_URL`
- `SUPABASE_SERVICE_ROLE_KEY`
- `DELIVERY_BASE_URL` (link target for one-time delivery access)

Optional:

- `RESEND_API_KEY`
- `SENDGRID_API_KEY`
- `HANDOFF_INTERNAL_KEY` (enables authenticated call to `handoff-notice`; if missing, handoff submission is skipped and logged)

## Deploy example

```bash
supabase functions deploy dispatch-trigger
supabase secrets set SUPABASE_URL=... SUPABASE_SERVICE_ROLE_KEY=... DELIVERY_BASE_URL=... HANDOFF_INTERNAL_KEY=... RESEND_API_KEY=... SENDGRID_API_KEY=...
```
