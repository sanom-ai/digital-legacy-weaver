-- Beta dashboard query pack.
-- Run blocks independently in Supabase SQL editor.

-- 1) Daily dispatch outcomes (last 30 days)
select
  date_trunc('day', created_at) as day,
  stage,
  status,
  count(*) as total
from public.trigger_dispatch_events
where created_at > now() - interval '30 days'
group by 1, 2, 3
order by day desc, stage, status;

-- 2) Unlock success/error trend (last 30 days)
select
  date_trunc('day', created_at) as day,
  event_type,
  count(*) as total
from public.security_events
where created_at > now() - interval '30 days'
  and event_type in ('unlock_success', 'unlock_error', 'invalid_code', 'invalid_totp')
group by 1, 2
order by day desc, event_type;

-- 3) Dispatch heartbeat health (last 30 days)
select
  date_trunc('day', created_at) as day,
  status,
  count(*) as total
from public.system_heartbeats
where source = 'dispatch-trigger'
  and created_at > now() - interval '30 days'
group by 1, 2
order by day desc, status;

-- 4) Partner handoff and ack (last 30 days, proxy via trigger_logs)
select
  date_trunc('day', triggered_at) as day,
  mode,
  status,
  count(*) as total
from public.trigger_logs
where triggered_at > now() - interval '30 days'
  and action in ('trigger_legacy_delivery', 'trigger_self_recovery_delivery', 'unlock_delivery_bundle')
group by 1, 2, 3
order by day desc, mode, status;

-- 5) False-trigger candidate list (manual review queue)
-- Candidate heuristic:
--  - legacy final release sent
--  - owner has a recent life signal in prior 7 days (possible false-positive signal)
with sent_releases as (
  select
    owner_id,
    created_at as release_at
  from public.trigger_dispatch_events
  where mode = 'legacy'
    and stage = 'final_release'
    and status = 'sent'
    and created_at > now() - interval '30 days'
),
recent_signals as (
  select
    owner_id,
    occurred_at
  from public.owner_life_signals
  where occurred_at > now() - interval '37 days'
)
select
  s.owner_id,
  s.release_at,
  max(r.occurred_at) as latest_signal_before_release
from sent_releases s
join recent_signals r
  on r.owner_id = s.owner_id
 and r.occurred_at between s.release_at - interval '7 days' and s.release_at
group by s.owner_id, s.release_at
order by s.release_at desc
limit 200;
