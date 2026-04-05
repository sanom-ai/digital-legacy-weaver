-- Beta gate SQL pack.
-- Run blocks independently in Supabase SQL editor.

-- 1) Cohort size and beneficiary coverage (last 30 days)
with cohort as (
  select id, beneficiary_email
  from public.profiles
  where created_at > now() - interval '30 days'
)
select
  count(*) as cohort_count,
  count(*) filter (where nullif(trim(beneficiary_email), '') is not null) as beneficiary_configured_count,
  case
    when count(*) = 0 then 1.0
    else round((count(*) filter (where nullif(trim(beneficiary_email), '') is not null))::numeric / count(*)::numeric, 4)
  end as beneficiary_coverage
from cohort;

-- 2) Cohort legal-consent coverage (last 30 days)
with cohort as (
  select id
  from public.profiles
  where created_at > now() - interval '30 days'
)
select
  count(*) as cohort_count,
  count(*) filter (where s.legal_disclaimer_accepted is true) as consent_accepted_count,
  case
    when count(*) = 0 then 1.0
    else round((count(*) filter (where s.legal_disclaimer_accepted is true))::numeric / count(*)::numeric, 4)
  end as consent_coverage
from cohort c
left join public.user_safety_settings s
  on s.owner_id = c.id;

-- 3) Unlock success rate (last 30 days)
with unlock_events as (
  select event_type
  from public.security_events
  where created_at > now() - interval '30 days'
    and event_type in ('unlock_success', 'unlock_error')
)
select
  count(*) as unlock_total,
  count(*) filter (where event_type = 'unlock_success') as unlock_success_count,
  count(*) filter (where event_type = 'unlock_error') as unlock_error_count,
  case
    when count(*) = 0 then 1.0
    else round((count(*) filter (where event_type = 'unlock_success'))::numeric / count(*)::numeric, 4)
  end as unlock_success_rate
from unlock_events;

-- 4) Dispatch heartbeat freshness
select
  status,
  created_at,
  case
    when created_at > now() - interval '26 hours' then false
    else true
  end as is_stale
from public.system_heartbeats
where source = 'dispatch-trigger'
order by created_at desc
limit 1;

-- 5) Final release outcomes (last 30 days)
select
  status,
  count(*) as total
from public.trigger_dispatch_events
where created_at > now() - interval '30 days'
  and stage = 'final_release'
group by status
order by status;
