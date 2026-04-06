# Provider Handoff Template

## Purpose

Standard outbound message template for beneficiary and destination provider coordination.

## Boundary statement (must include)

Digital Legacy Weaver is a technical coordination layer only.  
It does not adjudicate legal entitlement or replace provider legal/compliance decisions.

## Beneficiary-facing template

Subject:

- `Digital Legacy Weaver notice: pre-arranged legacy handoff`

Body:

1. You received this because you were pre-assigned by the owner.
2. This notice never asks for money transfer, password reset, or private account fees.
3. You do not need to act immediately. If unsure, confirm with another guardian/family member first.
4. Recommended safe path: open the app yourself and enter the handoff packet (`access_id` + `access_key`) instead of clicking unknown links.
5. Contact the destination app/provider directly for legal entitlement verification.
6. Submit legal documents to destination provider process (not to this platform).
7. Complete any provider security checks (KYC/AML/2FA).
8. This platform only coordinates workflow and does not decide legal ownership.

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
