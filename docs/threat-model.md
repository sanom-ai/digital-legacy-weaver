# Threat Model (v1)

## Assets

1. Encrypted recovery payload (`recovery_items.encrypted_payload`)
2. One-time access credentials (`delivery_access_keys`)
3. Verification challenges (`delivery_access_challenges`)
4. Trigger execution integrity (`trigger_dispatch_events`, `trigger_logs`, `system_heartbeats`)

## Trust boundaries

1. Client app (untrusted environment)
2. Edge functions (trusted execution)
3. Database with RLS (trusted policy boundary)
4. Email channel (partially trusted; can be intercepted)

## Top threats and mitigations

1. Link interception / replay
- Threat: attacker gets access link from email.
- Mitigation: one-time `access_key`, hashed at rest, expiry, consume-on-success.

2. Brute-force verification code
- Threat: attacker guesses 6-digit code.
- Mitigation: challenge expiry, attempt limit (`max_attempts`), consumed state, IP/access-ID rate limits with temporary blocking.

3. False-positive final release
- Threat: owner inactive for benign reason, unintended release happens.
- Mitigation: reminder stages (14/7/1), grace period, emergency pause, legal consent gate.

4. Duplicate dispatch events
- Threat: scheduler retries trigger duplicate sends.
- Mitigation: unique key on `(cycle_date, owner_id, mode, stage)` for idempotency.

5. Scheduler outage / silent failure
- Threat: dispatch never runs and no one notices.
- Mitigation: heartbeat writes + external monitor against stale heartbeat.

6. Active incident requires immediate containment
- Threat: continuing unlock/dispatch during incident increases blast radius.
- Mitigation: global safety controls (`system_safety_controls`) to disable dispatch and/or unlock centrally.

7. Unauthorized cross-user data access
- Threat: user reads or modifies another user records.
- Mitigation: RLS owner policies on profile/items/settings/logs.

8. Low observability during active attacks
- Threat: brute-force/abuse happens without clear event trail.
- Mitigation: dedicated `security_events` stream for access denial, invalid code, rate limiting, and successful unlock.

## Residual risks

1. Email account compromise still exposes verification code channel.
2. Access key displayed on user device can be shoulder-surfed.
3. Operational misconfiguration (missing scheduler/secrets) can degrade reliability.

## Next hardening steps

1. Add per-IP rate limit and temporary blocklist for unlock endpoint.
2. Add optional stronger second factor (TOTP/SMS provider integration).
3. Add signed audit trail for high-assurance compliance.
