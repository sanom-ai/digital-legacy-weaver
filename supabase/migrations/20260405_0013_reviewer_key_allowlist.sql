-- Reviewer key allowlist and admin controls.

create table if not exists public.reviewer_api_keys (
  id uuid primary key default gen_random_uuid(),
  key_hash text not null unique,
  reviewer_ref text not null,
  role text not null default 'reviewer' check (role in ('reviewer', 'admin')),
  label text not null,
  is_active boolean not null default true,
  expires_at timestamptz,
  rotated_from uuid references public.reviewer_api_keys(id) on delete set null,
  created_by text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

drop trigger if exists trg_reviewer_api_keys_updated_at on public.reviewer_api_keys;
create trigger trg_reviewer_api_keys_updated_at
before update on public.reviewer_api_keys
for each row execute function public.set_updated_at();

create index if not exists idx_reviewer_api_keys_active_role
on public.reviewer_api_keys(is_active, role, expires_at);

alter table public.reviewer_api_keys enable row level security;

drop policy if exists reviewer_api_keys_no_direct_access on public.reviewer_api_keys;
create policy reviewer_api_keys_no_direct_access on public.reviewer_api_keys
for all
using (false)
with check (false);
