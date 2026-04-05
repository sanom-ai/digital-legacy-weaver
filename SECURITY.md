# Security Policy

Digital Legacy Weaver handles high-risk legacy and recovery workflows.  
Treat every security report as confidential until fixed.

## Product maturity statement

Current release line (`v0.1.x`) is an early foundation/prototype and not yet production-grade for broad public use.  
Use only controlled test data in non-production environments until stable criteria in `docs/testing-strategy.md` are met.

## Security contact

Do not open public issues for active vulnerabilities.

Use private channels:

1. Primary: `security@legacyweaver.app`
2. Fallback: create a private maintainer contact request and mark it `SECURITY-PRIVATE`

Include:

1. Summary and impact
2. Reproduction steps / PoC
3. Affected endpoint, function, migration, or workflow
4. Suggested mitigation if known
5. Whether user data exposure is confirmed or suspected

## Scope

In-scope components:

1. `supabase/functions/dispatch-trigger`
2. `supabase/functions/open-delivery-link`
3. `supabase/functions/handoff-notice`
4. `supabase/functions/manage-totp-factor`
5. Supabase schema, migrations, RLS, and RPC logic in `supabase/migrations`
6. Unlock flow and deep-link handling in `apps/flutter_app`
7. CI/security scripts under `scripts/`

Out-of-scope examples:

1. Missing hardening recommendation with no exploit path
2. Reports without reproduction detail
3. Social engineering scenarios without technical flaw
4. Findings that require compromised maintainer credentials first

## Response SLA

Target response model:

1. Acknowledgment: within 72 hours
2. Initial severity classification: within 7 days
3. Fix target:
- Critical: 7 days
- High: 14 days
- Medium: 30 days
- Low: best-effort roadmap
4. Coordinated disclosure after patch/recovery guidance is available

## Severity model

1. Critical: unauthorized unlock/release, remote secret exfiltration, policy bypass allowing wrongful delivery
2. High: replay/forgery that materially weakens release integrity, auth bypass with realistic preconditions
3. Medium: partial data exposure, non-default misconfiguration exploit, meaningful audit/forensics gap
4. Low: defense-in-depth issues without practical exploitation path

## Safe harbor

Good-faith research is welcomed when all are true:

1. No deliberate privacy harm or data destruction
2. No disruption of production availability
3. No social engineering or physical attacks
4. Prompt private disclosure to maintainers

## Hard requirements for production rollout

Before claiming production readiness:

1. End-to-end reliability drills pass repeatedly
2. Unlock abuse tests and adverse-path tests are automated
3. Incident runbook + on-call ownership is active
4. External legal-boundary wording remains explicit in user and partner flows
