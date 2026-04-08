-- Wrong-recipient reporting and temporary access-key hold model.

alter table public.delivery_access_keys
  add column if not exists blocked_at timestamptz,
  add column if not exists blocked_reason text;

create table if not exists public.delivery_wrong_recipient_reports (
  id uuid primary key default gen_random_uuid(),
  access_key_id uuid not null references public.delivery_access_keys(id) on delete cascade,
  owner_id uuid not null references auth.users(id) on delete cascade,
  mode public.recovery_kind not null,
  source text not null default 'beneficiary_secure_link',
  reported_ip_hash text,
  details jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create index if not exists idx_delivery_wrong_recipient_reports_owner_created
  on public.delivery_wrong_recipient_reports(owner_id, created_at desc);

create index if not exists idx_delivery_wrong_recipient_reports_access_key
  on public.delivery_wrong_recipient_reports(access_key_id, created_at desc);
