-- Cross-device proof-of-life rebind and recovery-key posture.

alter table public.user_safety_settings
add column if not exists device_rebind_in_progress boolean not null default false;

alter table public.user_safety_settings
add column if not exists device_rebind_started_at timestamptz;

alter table public.user_safety_settings
add column if not exists device_rebind_grace_hours int not null default 72
check (device_rebind_grace_hours between 24 and 168);

alter table public.user_safety_settings
add column if not exists recovery_key_enabled boolean not null default true;

create table if not exists public.device_rebind_events (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references auth.users(id) on delete cascade,
  action text not null check (action in ('start_rebind', 'complete_rebind', 'cancel_rebind', 'rotate_recovery_key')),
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create index if not exists idx_device_rebind_events_owner_created
on public.device_rebind_events(owner_id, created_at desc);

alter table public.device_rebind_events enable row level security;

drop policy if exists device_rebind_events_owner_rw on public.device_rebind_events;
create policy device_rebind_events_owner_rw on public.device_rebind_events
for all
using (auth.uid() = owner_id)
with check (auth.uid() = owner_id);
