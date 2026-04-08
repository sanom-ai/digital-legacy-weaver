-- Multi-signal life proof and guardian approval gates.

create table if not exists public.owner_life_signals (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references auth.users(id) on delete cascade,
  signal_type text not null check (signal_type in ('alive_button', 'app_session', 'email_confirm', 'push_ack')),
  occurred_at timestamptz not null default now(),
  details jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create index if not exists idx_owner_life_signals_owner_occurred
on public.owner_life_signals(owner_id, occurred_at desc);

alter table public.owner_life_signals enable row level security;
drop policy if exists owner_life_signals_owner_rw on public.owner_life_signals;
create policy owner_life_signals_owner_rw on public.owner_life_signals
for all
using (auth.uid() = owner_id)
with check (auth.uid() = owner_id);

create table if not exists public.guardian_approvals (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references auth.users(id) on delete cascade,
  mode public.recovery_kind not null,
  cycle_date date not null,
  guardian_email text not null,
  approved boolean not null default false,
  approved_at timestamptz,
  notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(owner_id, mode, cycle_date, guardian_email)
);

drop trigger if exists trg_guardian_approvals_updated_at on public.guardian_approvals;
create trigger trg_guardian_approvals_updated_at
before update on public.guardian_approvals
for each row execute function public.set_updated_at();

alter table public.guardian_approvals enable row level security;
drop policy if exists guardian_approvals_owner_rw on public.guardian_approvals;
create policy guardian_approvals_owner_rw on public.guardian_approvals
for all
using (auth.uid() = owner_id)
with check (auth.uid() = owner_id);

alter table public.user_safety_settings
add column if not exists require_multisignal_before_release boolean not null default true;

alter table public.user_safety_settings
add column if not exists recent_signal_window_hours int not null default 72
check (recent_signal_window_hours between 24 and 720);

alter table public.user_safety_settings
add column if not exists minimum_recent_signal_types int not null default 2
check (minimum_recent_signal_types between 1 and 4);

alter table public.user_safety_settings
add column if not exists require_guardian_approval_legacy boolean not null default false;

alter table public.user_safety_settings
add column if not exists guardian_grace_hours int not null default 72
check (guardian_grace_hours between 24 and 720);
