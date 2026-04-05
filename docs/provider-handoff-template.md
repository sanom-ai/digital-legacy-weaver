# Provider Handoff Template

## Purpose

Standard outbound message template for beneficiary and destination provider coordination.

## Boundary statement (must include)

Digital Legacy Weaver is a technical coordination layer only.  
It does not adjudicate legal entitlement or replace provider legal/compliance decisions.

## Beneficiary-facing template

Subject:

- `Legacy Handoff Notice (Technical Coordination)`

Body:

1. A policy-approved legacy handoff notice has been issued.
2. Use the one-time secure link from this notice.
3. Contact the destination app/provider directly for entitlement verification.
4. Submit legal documents to destination provider process (not to this platform).
5. Complete any provider security checks (KYC/AML/2FA).
6. This platform only coordinates workflow and does not decide legal ownership.

## Provider-facing summary fields

When sending handoff context to partners, include:

1. `case_id`
2. `owner_ref`
3. `beneficiary_ref` (if available)
4. `mode` (`legacy` | `self_recovery`)
5. `trigger_timestamp`
6. `handoff_disclaimer`
7. `audit_reference`

Do not include plaintext secrets.
