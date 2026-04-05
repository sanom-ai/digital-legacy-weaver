# Source Audit (Project Documents)

## Files audited

- `Digital Legacy Weaver.docx`
- `PTAG_Book.docx`

## What is immediately reusable

1. Product problem statement and target outcomes
- Digital legacy loss and forgotten credentials are clearly defined.
- Two explicit operating modes already exist:
  - Legacy delivery mode (beneficiaries)
  - Self-recovery mode (owner fallback email)

2. MVP feature scope
- Login
- Inactivity thresholds
- Recovery vault split by purpose
- Trigger countdown dashboard
- Alive-check action
- Test delivery flow

3. Operational architecture concept
- Flutter client + Supabase backend + scheduled trigger
- Minimal data model (`profiles`, `recovery_items`, `trigger_logs`)
- RLS-first posture and encryption recommendation

4. Policy language foundation
- PTAG block model (`role`, `authority`, `constraint`, `policy`, optional `dictionary`, `decision`)
- Header contract (`language`, `module`, `version`, `owner`, optional `context`)
- Parse -> validate -> analyze pipeline concept

## What is partially reusable (needs implementation detail)

1. Security controls
- Documents state security intent but do not define cryptographic key lifecycle, rotation, and recovery process.

2. Trigger proof and anti-false-positive design
- Reminder/confirmation behavior is mentioned, but no exact state machine or escalation sequence is defined.

3. Compliance evidence model
- Audit intent exists, but no event schema, retention policy, or tamper-evident strategy is specified.

4. Policy-runtime binding
- PTAG syntax is rich, but no concrete binding contract to app/service endpoints exists yet.

## Historical gaps (now addressed)

1. Flutter app runtime source is now present in `apps/flutter_app`.
2. Supabase schema + edge functions are now present in `supabase/migrations` and `supabase/functions`.
3. PTN parser, validation checks, and CI quality gates are now integrated under `tools/` and `.github/workflows/`.

## Remaining gaps toward stable

1. CI baseline still requires fully green push workflows on every commit.
2. Runtime operations workflows need production secrets configured to run continuously.
3. Flutter widget/integration test depth must be expanded for high-stakes flows.

## Recommendation

Use `.ptn` as the policy source-of-truth from day one. Keep business workflow in app code, but evaluate permissions/constraints/triggers via `.ptn` parsing + semantic checks in CI and at runtime.
