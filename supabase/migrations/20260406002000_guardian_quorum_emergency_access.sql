-- Guardian quorum and emergency access controls for real-world beta operation.

alter table public.user_safety_settings
add column if not exists guardian_quorum_enabled boolean not null default false;

alter table public.user_safety_settings
add column if not exists guardian_quorum_required int not null default 2
check (guardian_quorum_required between 1 and 5);

alter table public.user_safety_settings
add column if not exists guardian_quorum_pool_size int not null default 3
check (guardian_quorum_pool_size between 2 and 5);

alter table public.user_safety_settings
add column if not exists emergency_access_enabled boolean not null default false;

alter table public.user_safety_settings
add column if not exists emergency_access_requires_beneficiary_request boolean not null default true;

alter table public.user_safety_settings
add column if not exists emergency_access_requires_guardian_quorum boolean not null default true;

alter table public.user_safety_settings
add column if not exists emergency_access_grace_hours int not null default 48
check (emergency_access_grace_hours between 24 and 168);

create table if not exists public.emergency_access_requests (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references auth.users(id) on delete cascade,
  beneficiary_email text,
  beneficiary_name text,
  requested_by text not null default 'beneficiary',
  request_reason text,
  status text not null default 'pending'
    check (status in ('pending', 'under_review', 'approved', 'denied', 'expired')),
  requires_beneficiary_request boolean not null default true,
  requires_guardian_quorum boolean not null default true,
  required_guardian_approvals int not null default 2
    check (required_guardian_approvals between 1 and 5),
  granted_guardian_approvals int not null default 0
    check (granted_guardian_approvals between 0 and 5),
  grace_hours int not null default 48
    check (grace_hours between 24 and 168),
  requested_at timestamptz not null default now(),
  resolved_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

drop trigger if exists trg_emergency_access_requests_updated_at on public.emergency_access_requests;
create trigger trg_emergency_access_requests_updated_at
before update on public.emergency_access_requests
for each row execute function public.set_updated_at();

alter table public.emergency_access_requests enable row level security;

drop policy if exists emergency_access_requests_owner_rw on public.emergency_access_requests;
create policy emergency_access_requests_owner_rw on public.emergency_access_requests
for all
using (auth.uid() = owner_id)
with check (auth.uid() = owner_id);
