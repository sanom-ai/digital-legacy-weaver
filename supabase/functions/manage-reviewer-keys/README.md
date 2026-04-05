# manage-reviewer-keys

Admin endpoint for reviewer-key allowlist lifecycle.

## Authorization

Requires header:

`x-reviewer-admin-key: <REVIEWER_ADMIN_API_KEY>`

## Actions

1. `list_keys`
- lists reviewer key metadata (never returns plaintext key)

2. `add_key`
- required fields:
  - `key_plaintext`
  - `reviewer_ref`
  - `label`
- optional:
  - `role` (`reviewer` | `admin`)
  - `expires_at` (ISO datetime)
  - `rotated_from` (prior key id)
- stores `SHA-256` hash only

3. `deactivate_key`
- required fields:
  - `key_id`
- marks key as inactive
