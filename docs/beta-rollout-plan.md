# Beta Rollout Plan (Controlled)

## Objective

Validate reliability, safety, and user comprehension before broad public release.

## Rollout phases

### Phase 1: Internal staging validation (1-2 weeks)

1. Deploy latest `main` to staging.
2. Run scheduled workflows:
- `quality.yml`
- `security-gate.yml`
- `maintenance-cleanup.yml`
- `safety-drill.yml`
3. Validate no stale heartbeat and no critical incidents.

### Phase 2: Closed beta cohort (2-4 weeks)

Target 20-50 users across:

1. crypto-heavy users
2. cloud-heavy users
3. legal-office-assisted users

### Phase 3: Harden and expand

1. Fix top incident classes.
2. Re-run release checklist.
3. Expand invite pool gradually.

## Required controls before beta invite

1. legal disclaimer flow enabled
2. emergency pause tested
3. unlock rate limits active
4. security events monitored
5. global safety switch validated

## Metrics to track weekly

1. reminder-to-alive-check confirmation rate
2. unlock success rate
3. invalid verification/TOTP event rate
4. rate-limit trigger rate
5. stale heartbeat incidents
6. false positive release incidents

## Go/No-Go gate for expansion

Go only if all are true in the latest 30-day window:

1. critical incidents: `0`
2. stale heartbeat incidents: `0`
3. unlock success rate above internal threshold
4. false positive release incidents under threshold
5. no unresolved high-severity security issue
