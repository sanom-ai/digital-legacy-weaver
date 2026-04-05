# handoff-notice

Records and optionally forwards provider handoff notices for legacy/self-recovery release flows.

## Request

`POST /functions/v1/handoff-notice`

Headers:

- `Content-Type: application/json`
- `x-handoff-internal-key: <HANDOFF_INTERNAL_KEY>` (required when env key is configured)

Body:

```json
{
  "case_id": "owner-cycle-2026-04-05-legacy",
  "owner_ref": "11111111-2222-3333-4444-555555555555",
  "beneficiary_ref": "beneficiary@example.com",
  "mode": "legacy",
  "trigger_timestamp": "2026-04-05T09:30:00.000Z",
  "handoff_disclaimer": "Legal entitlement verification must be completed directly with the destination app/provider.",
  "audit_reference": "dispatch-trigger:2026-04-05:legacy"
}
```

## Environment Variables

- `SUPABASE_URL`
- `SUPABASE_SERVICE_ROLE_KEY`
- `HANDOFF_INTERNAL_KEY` (recommended)
- `HANDOFF_PROVIDER_WEBHOOK_URL` (optional; if missing, notice is logged but outbound call is skipped)
- `HANDOFF_SIGNING_SECRET` (optional HMAC signature for outbound webhook)

## Behavior

1. Validates payload contract.
2. Writes/updates audit row in `partner_handoff_notices`.
3. Attempts outbound webhook if configured.
4. Writes trigger log action `submit_partner_handoff_notice`.
5. Returns OpenAPI-compatible response keys: `ok`, `case_id`, `accepted_at`.
