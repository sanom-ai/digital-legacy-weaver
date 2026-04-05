-- Partner connector and legacy asset reference baseline.

create table if not exists public.partner_connectors (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references auth.users(id) on delete cascade,
  connector_id text not null,
  name text not null,
  supported_asset_types text[] not null default array[]::text[],
  supports_webhooks boolean not null default false,
  supported_second_factors text[] not null default array[]::text[],
  status text not null default 'active' check (status in ('active', 'paused', 'disabled')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(owner_id, connector_id)
);

drop trigger if exists trg_partner_connectors_updated_at on public.partner_connectors;
create trigger trg_partner_connectors_updated_at
before update on public.partner_connectors
for each row execute function public.set_updated_at();

create table if not exists public.legacy_asset_refs (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references auth.users(id) on delete cascade,
  connector_ref_id uuid not null references public.partner_connectors(id) on delete cascade,
  asset_id text not null,
  asset_type text not null,
  display_name text not null,
  encrypted_payload_ref text not null,
  integrity_hash text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(owner_id, connector_ref_id, asset_id)
);

drop trigger if exists trg_legacy_asset_refs_updated_at on public.legacy_asset_refs;
create trigger trg_legacy_asset_refs_updated_at
before update on public.legacy_asset_refs
for each row execute function public.set_updated_at();

alter table public.partner_connectors enable row level security;
alter table public.legacy_asset_refs enable row level security;

drop policy if exists partner_connectors_owner_rw on public.partner_connectors;
create policy partner_connectors_owner_rw on public.partner_connectors
for all
using (auth.uid() = owner_id)
with check (auth.uid() = owner_id);

drop policy if exists legacy_asset_refs_owner_rw on public.legacy_asset_refs;
create policy legacy_asset_refs_owner_rw on public.legacy_asset_refs
for all
using (auth.uid() = owner_id)
with check (auth.uid() = owner_id);
