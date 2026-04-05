# review-legal-evidence

Internal reviewer endpoint for legal evidence decisions with 4-eyes workflow.

## Authorization

Requires header:

`x-reviewer-key: <REVIEWER_API_KEY>`

Primary auth path is `reviewer_api_keys` allowlist (hashed keys, active/expiry checks).  
`REVIEWER_API_KEY` is retained only as transitional fallback.

## Actions

1. `review`
- required fields:
  - `evidence_id`
  - `reviewer_ref`
  - `decision` (`approved` | `rejected` | `needs_info`)
- calls SQL function `apply_legal_evidence_review`
- updates aggregate evidence status:
  - `verified` when approvals >= 2 and no rejection
  - `rejected` when any rejection exists
  - `under_review` when only one approval exists

2. `summary`
- required fields:
  - `evidence_id`
- returns evidence row + all reviewer decisions

3. `queue`
- optional fields:
  - `status` (`submitted` | `under_review` | `verified` | `rejected`), default `under_review`
  - `limit` (1..200), default 50
- returns reviewer queue list ordered by oldest updated first
- includes per-evidence counters:
  - `approvals`
  - `rejections`
  - `needs_info_count`
