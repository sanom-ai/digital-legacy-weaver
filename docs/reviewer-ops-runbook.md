# Reviewer Ops Runbook

## Scope

Runbook for internal evidence reviewers handling legal verification queue.

## Daily workflow

App option:

1. Launch Flutter with `REVIEWER_API_KEY` and open `Reviewer Ops` from dashboard.
2. Open `Timeline` per evidence to inspect reviewer history before final decision.

API option:

1. Open queue with `review-legal-evidence` action `queue` (default `under_review`).
2. Triage `submitted` records first, then `under_review` backlog.
3. Use action `summary` to verify existing decision history.
4. Apply decision with action `review`:
- `approved`
- `rejected`
- `needs_info`
5. Confirm aggregate status with action `summary`.

## 4-eyes rule

Evidence reaches `verified` only when:

1. At least 2 distinct reviewers approve
2. No rejection exists for that evidence

Any rejection forces aggregate status to `rejected`.

## Operational checks

Use SQL dashboard:

- `ops/sql/legal_review_dashboard.sql`

Monitor:

1. Queue size by status
2. Aging items older than 24 hours
3. Reviewer throughput over 7 days

## Incident response hints

1. If queue spikes suddenly, move to incident mode and increase reviewer capacity.
2. If reviewer API key leaks, rotate `REVIEWER_API_KEY` immediately.
3. For disputed cases, set decision `needs_info` and attach notes before final approval.

## Key lifecycle

Use:

- `docs/reviewer-key-rotation.md`

for add/deactivate/rotate flow with `manage-reviewer-keys` endpoint.
