-- Second-factor challenge for secure delivery link unlocking.

create table if not exists public.delivery_access_challenges (
  id uuid primary key default gen_random_uuid(),
  access_key_id uuid not null references public.delivery_access_keys(id) on delete cascade,
  code_hash text not null,
  expires_at timestamptz not null,
  consumed_at timestamptz,
  attempts int not null default 0,
  max_attempts int not null default 5,
  created_at timestamptz not null default now()
);

create index if not exists idx_delivery_challenges_access_key_created
  on public.delivery_access_challenges(access_key_id, created_at desc);

create index if not exists idx_delivery_challenges_access_key_expires
  on public.delivery_access_challenges(access_key_id, expires_at desc);
