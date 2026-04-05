-- Risk controls: reliability, secure delivery links, legal consent, and trigger safety stages.

create table if not exists public.system_heartbeats (
  id uuid primary key default gen_random_uuid(),
  source text not null,
  status text not null check (status in ('ok', 'warn', 'error')),
  details jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create index if not exists idx_system_heartbeats_source_created on public.system_heartbeats(source, created_at desc);

create table if not exists public.trigger_dispatch_events (
  id uuid primary key default gen_random_uuid(),
  cycle_date date not null,
  owner_id uuid not null references auth.users(id) on delete cascade,
  mode public.recovery_kind not null,
  stage text not null check (stage in ('reminder_14d', 'reminder_7d', 'reminder_1d', 'final_release')),
  status text not null default 'pending' check (status in ('pending', 'sent', 'skipped', 'error')),
  reason text,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  unique(cycle_date, owner_id, mode, stage)
);

create table if not exists public.delivery_access_keys (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references auth.users(id) on delete cascade,
  mode public.recovery_kind not null,
  access_key_hash text not null,
  expires_at timestamptz not null,
  consumed_at timestamptz,
  delivery_channel text not null default 'email',
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create index if not exists idx_delivery_access_keys_owner_mode on public.delivery_access_keys(owner_id, mode, created_at desc);

create table if not exists public.user_safety_settings (
  owner_id uuid primary key references auth.users(id) on delete cascade,
  reminders_enabled boolean not null default true,
  reminder_channels text[] not null default array['email']::text[],
  reminder_offsets_days int[] not null default array[14,7,1]::int[],
  grace_period_days int not null default 3 check (grace_period_days between 1 and 14),
  legal_disclaimer_accepted boolean not null default false,
  legal_disclaimer_accepted_at timestamptz,
  emergency_pause_until timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

drop trigger if exists trg_user_safety_settings_updated_at on public.user_safety_settings;
create trigger trg_user_safety_settings_updated_at
before update on public.user_safety_settings
for each row execute function public.set_updated_at();

alter table public.user_safety_settings enable row level security;
drop policy if exists user_safety_settings_owner_rw on public.user_safety_settings;
create policy user_safety_settings_owner_rw on public.user_safety_settings
for all
using (auth.uid() = owner_id)
with check (auth.uid() = owner_id);
