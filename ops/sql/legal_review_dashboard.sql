-- Legal review dashboard queries for operations.

-- 1) Queue size by status
select
  review_status,
  count(*) as total
from public.legal_evidence_records
group by review_status
order by review_status;

-- 2) Aging queue (submitted/under_review older than 24h)
select
  id,
  owner_id,
  document_type,
  review_status,
  created_at,
  updated_at,
  extract(epoch from (now() - updated_at)) / 3600 as age_hours
from public.legal_evidence_records
where review_status in ('submitted', 'under_review')
  and updated_at < now() - interval '24 hours'
order by updated_at asc
limit 200;

-- 3) Reviewer throughput in last 7 days
select
  reviewer_ref,
  count(*) as decisions,
  count(*) filter (where decision = 'approved') as approved_count,
  count(*) filter (where decision = 'rejected') as rejected_count,
  count(*) filter (where decision = 'needs_info') as needs_info_count
from public.legal_evidence_reviews
where reviewed_at >= now() - interval '7 days'
group by reviewer_ref
order by decisions desc;
