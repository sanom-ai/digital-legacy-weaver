-- Beta feedback and incident intake table for controlled rollout learning.

create table if not exists public.beta_feedback_reports (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references auth.users(id) on delete cascade,
  category text not null check (category in ('ux', 'bug', 'security', 'reliability', 'other')),
  severity text not null default 'medium' check (severity in ('low', 'medium', 'high', 'critical')),
  summary text not null,
  details text,
  app_version text,
  status text not null default 'open' check (status in ('open', 'triaged', 'resolved', 'wontfix')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

drop trigger if exists trg_beta_feedback_reports_updated_at on public.beta_feedback_reports;
create trigger trg_beta_feedback_reports_updated_at
before update on public.beta_feedback_reports
for each row execute function public.set_updated_at();

create index if not exists idx_beta_feedback_reports_owner_created
on public.beta_feedback_reports(owner_id, created_at desc);

create index if not exists idx_beta_feedback_reports_status_severity
on public.beta_feedback_reports(status, severity);

alter table public.beta_feedback_reports enable row level security;

drop policy if exists beta_feedback_owner_rw on public.beta_feedback_reports;
create policy beta_feedback_owner_rw on public.beta_feedback_reports
for all
using (auth.uid() = owner_id)
with check (auth.uid() = owner_id);
