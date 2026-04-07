-- Runtime trigger schedules for inactivity and exact-date dispatch.

create table if not exists public.delivery_trigger_schedules (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references auth.users(id) on delete cascade,
  mode public.recovery_kind not null,
  trigger_mode text not null default 'inactivity'
    check (trigger_mode in ('inactivity', 'exact_date', 'manual_release')),
  inactivity_days int check (inactivity_days between 30 and 3650),
  exact_date_utc timestamptz,
  grace_days int not null default 7 check (grace_days between 1 and 30),
  enabled boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(owner_id, mode),
  constraint delivery_trigger_schedule_mode_requirements check (
    (trigger_mode = 'inactivity' and inactivity_days is not null)
    or (trigger_mode = 'exact_date' and exact_date_utc is not null)
    or (trigger_mode = 'manual_release')
  )
);

drop trigger if exists trg_delivery_trigger_schedules_updated_at on public.delivery_trigger_schedules;
create trigger trg_delivery_trigger_schedules_updated_at
before update on public.delivery_trigger_schedules
for each row execute function public.set_updated_at();

alter table public.delivery_trigger_schedules enable row level security;

drop policy if exists delivery_trigger_schedules_owner_rw on public.delivery_trigger_schedules;
create policy delivery_trigger_schedules_owner_rw on public.delivery_trigger_schedules
for all
using (auth.uid() = owner_id)
with check (auth.uid() = owner_id);

insert into public.delivery_trigger_schedules (
  owner_id,
  mode,
  trigger_mode,
  inactivity_days,
  grace_days,
  enabled
)
select
  p.id,
  mode_map.mode,
  'inactivity',
  mode_map.inactivity_days,
  7,
  true
from public.profiles p
cross join lateral (
  values
    ('legacy'::public.recovery_kind, p.legacy_inactivity_days),
    ('self_recovery'::public.recovery_kind, p.self_recovery_inactivity_days)
) as mode_map(mode, inactivity_days)
on conflict (owner_id, mode) do nothing;
