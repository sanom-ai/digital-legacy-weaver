-- 1) Latest scheduler heartbeat
select source, status, created_at, details
from public.system_heartbeats
where source = 'dispatch-trigger'
order by created_at desc
limit 5;

-- 2) Stale heartbeat detector (should return false)
select
  now() - coalesce(max(created_at), to_timestamp(0)) > interval '26 hours' as is_stale
from public.system_heartbeats
where source = 'dispatch-trigger';

-- 3) Recent dispatch events by stage
select cycle_date, mode, stage, status, count(*) as total
from public.trigger_dispatch_events
where created_at > now() - interval '7 days'
group by cycle_date, mode, stage, status
order by cycle_date desc, mode, stage, status;

-- 4) Token safety check (expired but unconsumed)
select id, owner_id, mode, expires_at, consumed_at
from public.delivery_access_keys
where expires_at < now()
  and consumed_at is null
order by expires_at desc
limit 50;

-- 5) Challenge abuse signal
select access_key_id, attempts, max_attempts, expires_at, consumed_at, created_at
from public.delivery_access_challenges
where attempts >= max_attempts
order by created_at desc
limit 50;

-- 6) Active rate-limit blocks
select scope, subject, attempt_count, blocked_until, last_attempt_at
from public.delivery_access_rate_limits
where blocked_until is not null
  and blocked_until > now()
order by blocked_until desc
limit 100;

-- 7) Recent security events
select event_type, severity, mode, created_at, details
from public.security_events
where created_at > now() - interval '72 hours'
order by created_at desc
limit 200;

-- 8) Global safety controls (dispatch/unlock switch)
select id, dispatch_enabled, unlock_enabled, reason, updated_by, updated_at
from public.system_safety_controls
limit 1;
