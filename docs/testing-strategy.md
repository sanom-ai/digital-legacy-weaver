# Testing and Reliability Strategy

## Current reality

`v0.1.x` has a strong foundation but is not yet a full production confidence profile for a high-stakes digital legacy platform.

Architecture target:

1. `docs/high-assurance-architecture.md`
2. private-first + responsible technical companion posture

Current strengths:

1. PTN validation and policy smoke checks
2. Migration baseline guards
3. Edge-function contract checks for critical auth and flow strings
4. Ops scripts for deploy and smoke checks

Current gaps to close:

1. Full integration tests for unlock flow against live Supabase test project
2. Adversarial tests (replay, forged handoff, brute-force simulation)
3. Continuous reliability drills for dead-man-switch lifecycle
4. Recovery-time objective (RTO) and incident drill evidence over time
5. local-first reliability evidence on constrained client environments (mobile/desktop background behavior)

## Test layers

1. Static and contract tests
- parser, schema, docs and endpoint contracts

2. Integration tests (target)
- create test owner profile
- trigger reminder/final-release paths
- request code + unlock with valid and invalid attempts
- verify idempotency and one-time consume behavior
- execution script: `scripts/run_integration_unlock_flow.ps1`

3. Adversarial tests (target)
- malformed payload and signature tampering
- rate-limit exhaustion and block-window assertions
- forged internal headers and stale credentials
- execution script: `scripts/run_adversarial_unlock_checks.ps1`

4. Reliability drills (target)
- dispatch disabled -> verify no release
- provider outage simulation -> ensure fail-safe behavior
- heartbeat stale detection and incident response exercise
- local timer drift and wake-up tolerance checks on supported clients

## Stable gate proposal

Do not market as stable until all are true:

1. 14 consecutive days of green scheduled reliability drills
2. Integration suite pass rate >= 99% on CI target environment
3. No open critical/high security findings
4. Incident response dry-run completed and documented
5. Legal-boundary wording verified across app, emails, and partner flows
6. Responsible claim boundary remains explicit ("designed to assist delivery", no universal guarantee language)

## Evidence artifacts

Track evidence in:

1. `docs/release-readiness-checklist.md`
2. `docs/closed-beta-checklist.md`
3. `ops/sql/beta_dashboard_pack.sql`
4. CI logs for quality/security workflows
