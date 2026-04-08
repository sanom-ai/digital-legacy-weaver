-- Rate limiting guard for access-link endpoints.

create table if not exists public.delivery_access_rate_limits (
  scope text not null,
  subject text not null,
  window_started_at timestamptz not null default now(),
  attempt_count int not null default 0,
  blocked_until timestamptz,
  last_attempt_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  primary key (scope, subject)
);

drop trigger if exists trg_delivery_access_rate_limits_updated_at on public.delivery_access_rate_limits;
create trigger trg_delivery_access_rate_limits_updated_at
before update on public.delivery_access_rate_limits
for each row execute function public.set_updated_at();

create index if not exists idx_delivery_access_rate_limits_blocked
  on public.delivery_access_rate_limits(blocked_until);
