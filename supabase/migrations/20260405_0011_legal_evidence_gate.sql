-- Legal evidence gate for legacy release workflows.

create table if not exists public.legal_evidence_records (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references auth.users(id) on delete cascade,
  document_type text not null check (document_type in ('death_certificate', 'family_registry', 'court_order', 'other')),
  document_ref_encrypted text not null,
  document_hash text not null,
  issuer_country text not null default 'TH',
  review_status text not null default 'submitted' check (review_status in ('submitted', 'under_review', 'verified', 'rejected')),
  review_notes text,
  reviewed_by text,
  reviewed_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(owner_id, document_type, document_hash)
);

drop trigger if exists trg_legal_evidence_records_updated_at on public.legal_evidence_records;
create trigger trg_legal_evidence_records_updated_at
before update on public.legal_evidence_records
for each row execute function public.set_updated_at();

alter table public.legal_evidence_records enable row level security;

drop policy if exists legal_evidence_records_owner_rw on public.legal_evidence_records;
create policy legal_evidence_records_owner_rw on public.legal_evidence_records
for all
using (auth.uid() = owner_id)
with check (auth.uid() = owner_id);

alter table public.user_safety_settings
add column if not exists require_legal_evidence_legacy boolean not null default true;
