-- Digital Legacy Weaver baseline schema (Private-first + PTN-ready)

create extension if not exists pgcrypto;

do $$
begin
  if not exists (select 1 from pg_type where typname = 'recovery_kind') then
    create type public.recovery_kind as enum ('legacy', 'self_recovery');
  end if;
end$$;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text,
  backup_email text not null,
  beneficiary_email text,
  legacy_inactivity_days int not null default 180 check (legacy_inactivity_days between 90 and 3650),
  self_recovery_inactivity_days int not null default 45 check (self_recovery_inactivity_days between 30 and 180),
  last_active_at timestamptz not null default now(),
  timezone text not null default 'UTC',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.recovery_items (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references auth.users(id) on delete cascade,
  kind public.recovery_kind not null,
  title text not null,
  encrypted_payload text not null,
  release_notes text,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists idx_recovery_items_owner_kind on public.recovery_items(owner_id, kind);

create table if not exists public.policy_documents (
  id uuid primary key default gen_random_uuid(),
  policy_name text not null unique,
  ptn_source text not null,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.trigger_logs (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references auth.users(id) on delete cascade,
  mode public.recovery_kind not null,
  action text not null,
  status text not null default 'pending' check (status in ('pending', 'sent', 'skipped', 'error')),
  reason text,
  metadata jsonb not null default '{}'::jsonb,
  triggered_at timestamptz not null default now(),
  processed_at timestamptz
);

create index if not exists idx_trigger_logs_owner_status on public.trigger_logs(owner_id, status);

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists trg_profiles_updated_at on public.profiles;
create trigger trg_profiles_updated_at
before update on public.profiles
for each row execute function public.set_updated_at();

drop trigger if exists trg_recovery_items_updated_at on public.recovery_items;
create trigger trg_recovery_items_updated_at
before update on public.recovery_items
for each row execute function public.set_updated_at();

drop trigger if exists trg_policy_documents_updated_at on public.policy_documents;
create trigger trg_policy_documents_updated_at
before update on public.policy_documents
for each row execute function public.set_updated_at();

alter table public.profiles enable row level security;
alter table public.recovery_items enable row level security;
alter table public.trigger_logs enable row level security;
alter table public.policy_documents enable row level security;

drop policy if exists profiles_owner_rw on public.profiles;
create policy profiles_owner_rw on public.profiles
for all
using (auth.uid() = id)
with check (auth.uid() = id);

drop policy if exists recovery_items_owner_rw on public.recovery_items;
create policy recovery_items_owner_rw on public.recovery_items
for all
using (auth.uid() = owner_id)
with check (auth.uid() = owner_id);

drop policy if exists trigger_logs_owner_read on public.trigger_logs;
create policy trigger_logs_owner_read on public.trigger_logs
for select
using (auth.uid() = owner_id);

drop policy if exists policy_documents_authenticated_read on public.policy_documents;
create policy policy_documents_authenticated_read on public.policy_documents
for select
using (auth.role() = 'authenticated');

insert into public.policy_documents (policy_name, ptn_source, is_active)
values (
  'default',
  $ptn$
language: PTN
module: digital_legacy_weaver
version: 1.0.0
owner: legacy-core
context: production

role owner {
  label: "Primary Account Owner"
  level: 10
}

role beneficiary {
  label: "Registered Beneficiary"
  level: 2
}

role system_scheduler {
  label: "Automated Trigger Scheduler"
  level: 9
}

authority owner {
  allow: upsert_recovery_item, delete_recovery_item, ack_alive_check
  allow: trigger_self_recovery_delivery
  deny: trigger_legacy_delivery
  require mfa for trigger_self_recovery_delivery
}

authority beneficiary {
  allow: read_legacy_delivery
  deny: upsert_recovery_item, delete_recovery_item
}

authority system_scheduler {
  allow: trigger_self_recovery_delivery, trigger_legacy_delivery
  require cooldown_24h for trigger_legacy_delivery
}

constraint delivery_guardrails {
  forbid beneficiary to trigger_legacy_delivery
  require email_verified for trigger_self_recovery_delivery
}

policy legacy_release_policy {
  when action == "trigger_legacy_delivery"
  and profile.inactive_days >= 180
  and profile.last_alive_check_confirmed == false
  then send_legacy_email
  and log_trigger_event
}

policy self_recovery_policy {
  when action == "trigger_self_recovery_delivery"
  and profile.inactive_days >= 45
  then send_self_recovery_email
  and log_trigger_event
}
  $ptn$,
  true
)
on conflict (policy_name) do update
set ptn_source = excluded.ptn_source,
    is_active = excluded.is_active,
    updated_at = now();
