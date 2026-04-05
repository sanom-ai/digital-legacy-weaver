-- Legal evidence reviewer workflow with 4-eyes approval rule.

create table if not exists public.legal_evidence_reviews (
  id uuid primary key default gen_random_uuid(),
  evidence_id uuid not null references public.legal_evidence_records(id) on delete cascade,
  reviewer_ref text not null,
  decision text not null check (decision in ('approved', 'rejected', 'needs_info')),
  notes text,
  reviewed_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  unique(evidence_id, reviewer_ref)
);

create index if not exists idx_legal_evidence_reviews_evidence on public.legal_evidence_reviews(evidence_id, reviewed_at desc);

alter table public.legal_evidence_reviews enable row level security;

drop policy if exists legal_evidence_reviews_owner_read on public.legal_evidence_reviews;
create policy legal_evidence_reviews_owner_read on public.legal_evidence_reviews
for select
using (
  exists (
    select 1
    from public.legal_evidence_records r
    where r.id = legal_evidence_reviews.evidence_id
      and r.owner_id = auth.uid()
  )
);

create or replace function public.apply_legal_evidence_review(
  p_evidence_id uuid,
  p_reviewer_ref text,
  p_decision text,
  p_notes text default null
)
returns table(review_status text, approvals int, rejections int)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_approvals int;
  v_rejections int;
  v_status text;
begin
  if p_decision not in ('approved', 'rejected', 'needs_info') then
    raise exception 'unsupported decision: %', p_decision;
  end if;

  insert into public.legal_evidence_reviews (evidence_id, reviewer_ref, decision, notes)
  values (p_evidence_id, p_reviewer_ref, p_decision, p_notes)
  on conflict (evidence_id, reviewer_ref)
  do update set
    decision = excluded.decision,
    notes = excluded.notes,
    reviewed_at = now();

  select
    count(*) filter (where decision = 'approved'),
    count(*) filter (where decision = 'rejected')
  into v_approvals, v_rejections
  from public.legal_evidence_reviews
  where evidence_id = p_evidence_id;

  if v_rejections > 0 then
    v_status := 'rejected';
  elsif v_approvals >= 2 then
    v_status := 'verified';
  elsif v_approvals = 1 then
    v_status := 'under_review';
  else
    v_status := 'submitted';
  end if;

  update public.legal_evidence_records
  set
    review_status = v_status,
    reviewed_by = p_reviewer_ref,
    reviewed_at = now(),
    review_notes = p_notes
  where id = p_evidence_id;

  return query
  select v_status, v_approvals, v_rejections;
end;
$$;

revoke all on function public.apply_legal_evidence_review(uuid, text, text, text) from public;
grant execute on function public.apply_legal_evidence_review(uuid, text, text, text) to service_role;
