# open-delivery-link

Secure delivery unlock endpoint with second-factor verification.

## Flow

1. `request_code`:
- validate one-time access credentials (`access_id`, `access_key`)
- reuse active unexpired challenge instead of issuing unlimited new codes
- generate 6-digit verification code only when no active challenge exists
- email code to intended recipient

2. `unlock`:
- validate access credentials again
- verify code (hash match, expiry, attempts)
- count failed attempts across verification code, beneficiary identity, and TOTP checks
- apply temporary receipt lock when max challenge attempts are exceeded
- optionally verify TOTP code when `user_safety_settings.require_totp_unlock = true`
- consume challenge and access key (one-time)
- return encrypted recovery bundle items
3. Abuse guard:
- DB-backed rate limits by client IP and access ID
- temporary blocking window on excessive attempts
4. Security event logging:
- logs `rate_limited`, `access_denied`, `invalid_code`, `invalid_totp`, `unlock_temporary_lock`, `unlock_success`, and `unlock_error`
- stored in `security_events` for monitoring and incident response
5. Global safety control:
- if `system_safety_controls.unlock_enabled = false`, endpoint returns `503` and blocks unlock attempts

## Request body

```json
{ "action": "request_code", "access_id": "...", "access_key": "..." }
```

```json
{
  "action": "unlock",
  "access_id": "...",
  "access_key": "...",
  "verification_code": "123456",
  "totp_code": "123456"
}
```

## Required environment variables

- `SUPABASE_URL`
- `SUPABASE_SERVICE_ROLE_KEY`

Optional (but recommended):

- `RESEND_API_KEY`
- `SENDGRID_API_KEY`

## Deploy

```bash
supabase functions deploy open-delivery-link
```
