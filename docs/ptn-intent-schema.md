# PTN Intent Schema

## Purpose

This document defines the structured intent model that sits between human language and canonical PTN.

The design rule is:

1. users express intent in normal language
2. the product structures that intent
3. PTN becomes the canonical policy artifact

This schema is not a runtime format and not a user-facing syntax.

It is the product-level contract for turning user intent into policy-as-code.

## Design goals

1. keep the user model understandable in plain language
2. keep PTN as the final canonical output
3. separate business intent from UI implementation details
4. support private-first delivery and recovery flows
5. support partner-ready workflows without making them mandatory

## Intent object

An intent document is a collection of owner-defined instructions for self-recovery and legacy delivery.

Top-level shape:

```json
{
  "intent_id": "intent_primary",
  "version": "0.1.0",
  "owner_ref": "owner_primary",
  "default_privacy_profile": "minimal",
  "entries": [],
  "global_safeguards": {},
  "metadata": {}
}
```

## Top-level fields

### `intent_id`

1. stable identifier for the intent document
2. used for traceability between app state, compiler output, and PTN artifacts

### `version`

1. intent schema version
2. independent from PTN document version

### `owner_ref`

1. logical owner identifier
2. does not need to expose personally identifying information

### `default_privacy_profile`

Allowed values:

1. `confidential`
2. `minimal`
3. `audit-heavy`

Purpose:

1. provides the default trace posture for entries that do not override privacy directly

### `entries`

1. ordered list of delivery or recovery intent entries
2. each entry becomes one or more PTN policies, requirements, or constraints

### `global_safeguards`

1. cross-entry protections
2. examples: grace windows, reminder cadence, emergency pause behavior, guardian requirements

### `metadata`

1. non-execution hints
2. examples: labels, notes, source channel, draft state
3. must never contain plaintext secrets

## Intent entry

Each entry describes one protected outcome defined by the owner.

Shape:

```json
{
  "entry_id": "legacy_wallet_a",
  "kind": "legacy_delivery",
  "asset": {},
  "recipient": {},
  "trigger": {},
  "delivery": {},
  "safeguards": {},
  "privacy": {},
  "partner_path": {},
  "status": "active"
}
```

## Entry fields

### `entry_id`

1. stable identifier for the entry
2. used to map compiler warnings, PTN blocks, and audit traces back to user intent

### `kind`

Allowed values:

1. `legacy_delivery`
2. `self_recovery`

Purpose:

1. determines whether the entry is intended for beneficiary delivery or owner recovery

### `asset`

Describes what the owner is protecting or referencing.

Shape:

```json
{
  "asset_id": "wallet_primary",
  "asset_type": "wallet",
  "display_name": "Primary Wallet",
  "payload_mode": "secure_link",
  "payload_ref": "vault://wallet_primary",
  "notes": "Optional human-readable note"
}
```

Rules:

1. `asset_id` must be stable
2. `asset_type` should use canonical categories where possible
3. `payload_mode` must avoid plaintext secret delivery by default
4. `payload_ref` points to a protected reference, not raw secret content

### `recipient`

Describes who should receive or access the outcome.

Shape:

```json
{
  "recipient_id": "beneficiary_anna",
  "relationship": "spouse",
  "delivery_channel": "email",
  "destination_ref": "anna@example.com",
  "role": "beneficiary"
}
```

Rules:

1. `recipient_id` must be stable within the intent
2. `role` is logical and should map cleanly to PTN actor roles
3. `destination_ref` must be treated as contact or routing information, not entitlement proof

### `trigger`

Describes when the entry becomes eligible.

Shape:

```json
{
  "mode": "inactivity",
  "inactivity_days": 90,
  "require_unconfirmed_alive_status": true,
  "grace_days": 7,
  "reminders_days_before": [14, 7, 1]
}
```

Rules:

1. trigger settings should compile into explicit policy conditions
2. reminder and grace settings should map to safety controls, not informal UI-only behavior

### `delivery`

Describes how the system should deliver the protected outcome.

Shape:

```json
{
  "method": "secure_link",
  "require_verification_code": true,
  "require_totp": false,
  "one_time_access": true
}
```

Allowed methods:

1. `secure_link`
2. `notification_only`
3. `self_recovery_route`

Rules:

1. plaintext delivery should not be a standard method
2. delivery requirements should compile into PTN requirements or runtime obligations

### `safeguards`

Describes entry-specific control requirements.

Shape:

```json
{
  "require_guardian_approval": false,
  "require_multisignal": true,
  "cooldown_hours": 24,
  "legal_disclaimer_required": true
}
```

Rules:

1. safeguards should compile to PTN requirements when possible
2. safeguards may inherit from `global_safeguards` and override locally

### `privacy`

Describes the privacy posture for the entry.

Shape:

```json
{
  "profile": "confidential",
  "minimize_trace_metadata": true
}
```

Rules:

1. `profile` maps directly to PTN `privacy_profile` or entry-specific compiler decisions
2. privacy settings should always prefer the stricter option when merged with global settings

### `partner_path`

Optional structure for destination-facing workflows.

Shape:

```json
{
  "path_id": "path_wallet_support",
  "path_type": "destination_service",
  "handoff_template": "default_provider_handoff",
  "required_context": ["service_contact", "asset_reference"]
}
```

Rules:

1. this block is optional
2. the entry must remain meaningful even when no partner path is configured
3. partner path settings must not replace legal entitlement verification

### `status`

Allowed values:

1. `draft`
2. `active`
3. `paused`
4. `archived`

Purpose:

1. controls whether the entry should compile into active PTN output

## Global safeguards

Shape:

```json
{
  "emergency_pause_enabled": true,
  "default_grace_days": 3,
  "default_reminders_days_before": [14, 7, 1],
  "require_multisignal_before_release": true,
  "require_guardian_approval_for_legacy": false
}
```

Purpose:

1. define safety defaults that apply across the intent document

## Compiler expectations

The intent-to-PTN compiler should:

1. normalize missing fields with safe defaults
2. reject contradictory or unsafe combinations
3. emit deterministic PTN for the same intent input
4. preserve links between `entry_id` and generated PTN blocks
5. warn when a user-defined intent is incomplete but not invalid

## Example

```json
{
  "intent_id": "intent_primary",
  "version": "0.1.0",
  "owner_ref": "owner_primary",
  "default_privacy_profile": "minimal",
  "entries": [
    {
      "entry_id": "legacy_wallet_a",
      "kind": "legacy_delivery",
      "asset": {
        "asset_id": "wallet_primary",
        "asset_type": "wallet",
        "display_name": "Primary Wallet",
        "payload_mode": "secure_link",
        "payload_ref": "vault://wallet_primary"
      },
      "recipient": {
        "recipient_id": "beneficiary_anna",
        "relationship": "spouse",
        "delivery_channel": "email",
        "destination_ref": "anna@example.com",
        "role": "beneficiary"
      },
      "trigger": {
        "mode": "inactivity",
        "inactivity_days": 90,
        "require_unconfirmed_alive_status": true,
        "grace_days": 7,
        "reminders_days_before": [14, 7, 1]
      },
      "delivery": {
        "method": "secure_link",
        "require_verification_code": true,
        "require_totp": false,
        "one_time_access": true
      },
      "safeguards": {
        "require_guardian_approval": false,
        "require_multisignal": true,
        "cooldown_hours": 24,
        "legal_disclaimer_required": true
      },
      "privacy": {
        "profile": "confidential",
        "minimize_trace_metadata": true
      },
      "partner_path": {
        "path_id": "path_wallet_support",
        "path_type": "destination_service",
        "handoff_template": "default_provider_handoff",
        "required_context": ["service_contact", "asset_reference"]
      },
      "status": "active"
    }
  ],
  "global_safeguards": {
    "emergency_pause_enabled": true,
    "default_grace_days": 3,
    "default_reminders_days_before": [14, 7, 1],
    "require_multisignal_before_release": true,
    "require_guardian_approval_for_legacy": false
  },
  "metadata": {
    "source": "intent_builder"
  }
}
```

## Decision

This schema should be treated as:

1. human-intent contract
2. compiler input contract
3. bridge between product UX and canonical PTN

It should not be treated as:

1. a direct replacement for PTN
2. a UI state dump
3. a payload vault
