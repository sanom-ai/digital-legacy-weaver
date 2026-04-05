# PTN v2 Profile (High-Assurance)

## Purpose

PTN v2 extends PTN v1 with richer control metadata so policy requirements can be:

1. Classified by risk
2. Enforced with explicit mode (strict/advisory)
3. Mapped to evidence and ownership

PTN v2 remains backward-compatible with PTN v1 syntax.

## Compatibility

1. Existing v1 statements remain valid.
2. v2 adds metadata support to `require ... for ...` statements.
3. Runtime may ignore unknown metadata, but validator should reject unsupported keys/values.
4. v2 may declare a document-wide `privacy_profile` header for trace minimization behavior.

## Privacy profile header

Optional header:

```text
privacy_profile: confidential | minimal | audit-heavy
```

Profiles:

1. `confidential`: do not persist requirement trace details; keep only minimal status markers
2. `minimal`: persist sanitized control-state only
3. `audit-heavy`: persist sanitized control-state plus evidence/owner references, but never secrets

## v2 require syntax

```text
require <requirement_id>[<k>=<v>, <k>=<v>] for <action_id>
```

Examples:

```ptn
require consent_active[risk=high, mode=strict, owner=privacy-core] for trigger_legacy_delivery
require cooldown_24h[risk=medium, mode=strict, evidence=dispatch_events] for trigger_legacy_delivery
require provider_legal_verification_handoff[risk=high, mode=advisory] for trigger_legacy_delivery
```

## v2 metadata keys

Allowed keys:

1. `risk`: `low | medium | high | critical`
2. `mode`: `strict | advisory`
3. `evidence`: free-form identifier for evidence source
4. `owner`: logical control owner/team marker

## Validation guidance

1. Requirement identifiers should use lowercase snake/kebab style.
2. Unsupported metadata keys must fail validation.
3. Unsupported `risk` or `mode` values must fail validation.
4. Parsers should preserve compatibility with v1 files that omit metadata.
5. If `privacy_profile` is present, it must be one of `confidential | minimal | audit-heavy`.

## Runtime guidance

1. `mode=strict` controls should block execution when unsatisfied.
2. `mode=advisory` controls may proceed with audit warning and explicit reason.
3. Runtime should emit requirement-level audit records for traceability.
4. Runtime should emit a decision trace object per requirement containing:
- `name`
- `mode`
- `risk`
- `evidence`
- `owner`
- `satisfied`
- `enforcement` (`block` or `warn`)
5. Runtime should apply the effective trace profile from PTN policy and user safety settings before persisting trace metadata.

## Conformance baseline

A PTN v2 file is conformant when:

1. PTN v1 structural checks pass
2. all v2 metadata keys are in allow-list
3. `risk` and `mode` values are valid
4. required controls are resolvable in runtime or explicitly marked advisory
5. optional `privacy_profile` is valid when present
