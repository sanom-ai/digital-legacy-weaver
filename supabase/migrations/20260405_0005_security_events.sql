-- Security event stream for incident response and forensic visibility.

create table if not exists public.security_events (
  id uuid primary key default gen_random_uuid(),
  event_type text not null,
  severity text not null check (severity in ('info', 'warn', 'critical')),
  actor_scope text,
  actor_hash text,
  access_id uuid,
  owner_id uuid,
  mode public.recovery_kind,
  details jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create index if not exists idx_security_events_created on public.security_events(created_at desc);
create index if not exists idx_security_events_type on public.security_events(event_type, created_at desc);
create index if not exists idx_security_events_owner on public.security_events(owner_id, created_at desc);
