-- 1) Unlock success rate (7d)
with base as (
  select
    event_type,
    count(*) as total
  from public.security_events
  where created_at > now() - interval '7 days'
    and event_type in ('unlock_success', 'unlock_error')
  group by event_type
)
select
  coalesce((select total from base where event_type = 'unlock_success'), 0) as unlock_success_count,
  coalesce((select total from base where event_type = 'unlock_error'), 0) as unlock_error_count,
  case
    when coalesce((select total from base where event_type = 'unlock_success'), 0)
       + coalesce((select total from base where event_type = 'unlock_error'), 0) = 0 then null
    else
      coalesce((select total from base where event_type = 'unlock_success'), 0)::numeric
      /
      (
        coalesce((select total from base where event_type = 'unlock_success'), 0)
        + coalesce((select total from base where event_type = 'unlock_error'), 0)
      )::numeric
  end as unlock_success_rate
;

-- 2) Verification failures by type (7d)
select event_type, count(*) as total
from public.security_events
where created_at > now() - interval '7 days'
  and event_type in ('invalid_code', 'invalid_totp', 'access_denied')
group by event_type
order by total desc;

-- 3) Rate-limit pressure (7d)
select event_type, count(*) as total
from public.security_events
where created_at > now() - interval '7 days'
  and event_type = 'rate_limited'
group by event_type;

-- 4) Heartbeat freshness and status (7d)
select status, count(*) as total, max(created_at) as latest
from public.system_heartbeats
where source = 'dispatch-trigger'
  and created_at > now() - interval '7 days'
group by status
order by status;

-- 5) Reminder-to-alive approximation (30d)
-- proxy metric: reminder dispatch events vs owner alive checks in profile updates.
select
  (select count(*) from public.trigger_dispatch_events
   where stage in ('reminder_14d', 'reminder_7d', 'reminder_1d')
     and created_at > now() - interval '30 days') as reminder_events_30d,
  (select count(*) from public.trigger_logs
   where action = 'ack_alive_check'
     and triggered_at > now() - interval '30 days') as alive_checks_30d;
