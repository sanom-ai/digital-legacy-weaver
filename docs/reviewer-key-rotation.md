# Reviewer Key Rotation

## Objective

Rotate reviewer keys safely without downtime by using DB allowlist entries.

## Components

1. Key store table:
- `reviewer_api_keys`

2. Admin endpoint:
- `supabase/functions/manage-reviewer-keys`

3. Reviewer endpoint:
- `supabase/functions/review-legal-evidence`

## Rotation steps

1. Add new key (keep old key active temporarily)
- call `manage-reviewer-keys` action `add_key`
- pass:
  - `key_plaintext`
  - `reviewer_ref`
  - `role`
  - `label`
  - `rotated_from` (optional old key id)

2. Update reviewer clients to use new key
- set `x-reviewer-key` with the new plaintext key

3. Validate reviewer flow
- run queue and review actions successfully

4. Deactivate old key
- call `manage-reviewer-keys` action `deactivate_key` with old `key_id`

## Emergency revoke

If key leak is suspected:

1. Immediately deactivate affected key IDs
2. Add replacement key(s)
3. Confirm access with new keys only
4. Review legal evidence timeline for suspicious actions
