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

## Runtime guidance

1. `mode=strict` controls should block execution when unsatisfied.
2. `mode=advisory` controls may proceed with audit warning and explicit reason.
3. Runtime should emit requirement-level audit records for traceability.

## Conformance baseline

A PTN v2 file is conformant when:

1. PTN v1 structural checks pass
2. all v2 metadata keys are in allow-list
3. `risk` and `mode` values are valid
4. required controls are resolvable in runtime or explicitly marked advisory
