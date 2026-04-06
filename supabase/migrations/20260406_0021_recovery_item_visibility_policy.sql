-- Phase-aware beneficiary receipt visibility policy for recovery items.

alter table public.recovery_items
add column if not exists post_trigger_visibility text not null default 'route_only'
check (post_trigger_visibility in ('existence_only', 'route_only', 'route_and_instructions'));

alter table public.recovery_items
add column if not exists value_disclosure_mode text not null default 'institution_verified_only'
check (value_disclosure_mode in ('hidden', 'institution_verified_only'));
