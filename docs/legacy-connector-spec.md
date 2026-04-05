# Legacy Connector Spec (v0.1)

This specification defines how external apps can collaborate with Digital Legacy Weaver as a digital legacy orchestration layer.

## Connector goals

1. Standardize how partner apps register legacy assets and release instructions.
2. Keep sensitive content encrypted end-to-end.
3. Enable policy-driven, auditable release workflows across multiple providers.

## Connector roles

1. `owner_app`: app used directly by the end user.
2. `connector_app`: partner system that provides asset metadata and encrypted payload references.
3. `weaver_core`: orchestration service handling policy, scheduling, and release controls.

## Data model (connector-facing)

### LegacyAssetRef

1. `connector_id` (string): unique partner connector ID.
2. `asset_id` (string): partner-side stable asset reference.
3. `asset_type` (string): e.g. `wallet`, `exchange`, `cloud_storage`, `bank_portal`, `social`.
4. `display_name` (string): user-facing label.
5. `encrypted_payload_ref` (string): pointer/token to encrypted material.
6. `integrity_hash` (string): checksum/hash for tamper detection.
7. `created_at` / `updated_at` (timestamp).

### ReleaseInstruction

1. `instruction_id` (string)
2. `mode` (`self_recovery` | `legacy`)
3. `beneficiary_ref` (optional string)
4. `unlock_requirements` (array): e.g. `verification_code`, `totp`.
5. `retention_days` (integer)

## Connector capabilities

Each connector must declare:

1. Supported `asset_type` values
2. Whether it supports push webhooks for state change
3. Supported second-factor methods
4. Max payload size and rate limits

## Security requirements

1. No plaintext secret transfer over connector API.
2. All payloads must be encrypted before handoff.
3. Connector authentication must use signed API keys or OAuth2 client credentials.
4. All connector requests must include request ID for traceability.

## Reliability requirements

1. Idempotent upsert on partner asset registration.
2. Retry-safe webhooks with signature verification.
3. Explicit connector health endpoint.

## Compliance and legal requirements

1. Connector must not claim legal will replacement.
2. Connector UI must show legal disclaimer where release policy is enabled.
3. Connector events must be auditable for incident review.

## Minimal connector lifecycle

1. Register connector
2. Register or update assets
3. Link assets to release instructions
4. Receive policy-qualified release event
5. Confirm delivery and audit outcome
