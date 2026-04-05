-- Disable internal legal-evidence enforcement by default.
-- Platform acts as technical coordination layer; legal entitlement is verified by destination providers.

alter table public.user_safety_settings
alter column require_legal_evidence_legacy set default false;

update public.user_safety_settings
set require_legal_evidence_legacy = false
where require_legal_evidence_legacy = true;
