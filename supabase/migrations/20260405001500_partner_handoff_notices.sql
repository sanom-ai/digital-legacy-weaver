-- Provider handoff notice audit trail and delivery status log.

create table if not exists public.partner_handoff_notices (
  id uuid primary key default gen_random_uuid(),
  case_id text not null,
  owner_id uuid not null references auth.users(id) on delete cascade,
  beneficiary_ref text,
  mode public.recovery_kind not null,
  trigger_timestamp timestamptz not null,
  handoff_disclaimer text not null,
  audit_reference text,
  delivery_status text not null default 'queued' check (delivery_status in ('queued', 'sent', 'failed', 'skipped')),
  delivery_http_status int,
  provider_request_id text,
  delivery_response text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(owner_id, case_id)
);

drop trigger if exists trg_partner_handoff_notices_updated_at on public.partner_handoff_notices;
create trigger trg_partner_handoff_notices_updated_at
before update on public.partner_handoff_notices
for each row execute function public.set_updated_at();

create index if not exists idx_partner_handoff_notices_owner_created
on public.partner_handoff_notices(owner_id, created_at desc);

alter table public.partner_handoff_notices enable row level security;

drop policy if exists partner_handoff_notices_owner_read on public.partner_handoff_notices;
create policy partner_handoff_notices_owner_read on public.partner_handoff_notices
for select
using (auth.uid() = owner_id);
