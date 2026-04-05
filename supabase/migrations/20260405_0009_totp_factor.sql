-- TOTP factor baseline for stronger unlock verification.

create table if not exists public.user_totp_factors (
  owner_id uuid primary key references auth.users(id) on delete cascade,
  secret_base32 text not null,
  digits int not null default 6 check (digits in (6, 8)),
  period_seconds int not null default 30 check (period_seconds in (30, 60)),
  algorithm text not null default 'SHA1' check (algorithm in ('SHA1')),
  enabled boolean not null default false,
  confirmed_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

drop trigger if exists trg_user_totp_factors_updated_at on public.user_totp_factors;
create trigger trg_user_totp_factors_updated_at
before update on public.user_totp_factors
for each row execute function public.set_updated_at();

alter table public.user_totp_factors enable row level security;

drop policy if exists user_totp_factors_owner_rw on public.user_totp_factors;
create policy user_totp_factors_owner_rw on public.user_totp_factors
for all
using (auth.uid() = owner_id)
with check (auth.uid() = owner_id);

alter table public.user_safety_settings
add column if not exists require_totp_unlock boolean not null default false;
