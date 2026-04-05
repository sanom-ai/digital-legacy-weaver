# Contributing Guide

Thank you for helping build Digital Legacy Weaver.

## Project stage

Current line (`v0.1.x`) is a strong prototype/foundation.  
Contributions should optimize for reliability and auditability first, then feature growth.

## Core principles

1. Private-first by design
2. Reliability over feature speed for trigger workflows
3. Security and legal clarity before convenience
4. Technical companion posture, never legal-authority posture

## Branching and pull requests

1. Create feature branches from `main`.
2. Keep PR scope small and focused on one risk domain when possible.
3. Use commit messages in imperative style, e.g. `feat: add dispatch idempotency guard`.
4. Do not mix refactor-only changes with safety-critical logic changes in one PR unless unavoidable.

## Required checks before merge

Run locally:

1. `python tools\check_naming_clean.py`
2. `python tools\ptn_smoke_test.py`
3. `python tools\pdpa_control_check.py`
4. `python tools\check_proprietary_ptn_boundary.py`
5. `python -m pytest _support/tests`

## PTN legacy proprietary boundary

1. `ptn/legacy/private` is reserved for proprietary PTN legacy assets.
2. Do not commit real proprietary `.ptn` files to public branches.
3. Use stubs/metadata only in public repository paths.
4. Any proprietary PTN usage, copy, or redistribution requires prior written approval.

If schema changes are included, also provide:

1. Migration rationale
2. Roll-forward plan
3. Rollback/fallback note
4. Operational impact note for on-call

## Testing matrix expectations

For safety-sensitive PRs, include evidence for relevant layers:

1. Unit/contract checks (`_support/tests`)
2. Edge-function auth and failure paths
3. Dispatch lifecycle behavior (reminder, grace, final release, fail-safe)
4. Docs and runbook updates for changed operations

Reference: `docs/testing-strategy.md`

## Ownership and review

Critical-path files require maintainer review:

1. `supabase/functions/**`
2. `supabase/migrations/**`
3. `scripts/deploy_production.ps1`
4. `scripts/post_deploy_smoke.ps1`
5. `SECURITY.md`

See `.github/CODEOWNERS`.

## Architecture decision flow

Use short design notes in PR descriptions for non-trivial changes:

1. Problem/risk
2. Chosen approach
3. Alternatives rejected
4. Operational and legal-boundary impact

## Release process (summary)

1. Merge only when required checks pass.
2. Run post-deploy smoke in target environment.
3. Record release notes with risk and rollback hints.
4. Tag release only after runbook checklist is green.

## License expectations

Current licensing model:

By submitting a contribution, you agree that:

1. Open-core repository code can be distributed under MIT (`LICENSE`).
2. PTN Legacy proprietary assets are governed by `LICENSE-PTN`.
3. Any future license transition is a maintainer governance decision and must be documented publicly before release changes are made.

## Policy references

1. Revenue share: `docs/revenue-sharing-policy.md`
2. Co-founder track: `docs/cofounder-track-policy.md`
3. Security disclosure: `SECURITY.md`
