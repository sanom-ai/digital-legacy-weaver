-- 1) Security events by type in last 24h
select event_type, severity, count(*) as total
from public.security_events
where created_at > now() - interval '24 hours'
group by event_type, severity
order by total desc, event_type;

-- 2) Top suspicious access targets (warn events, 24h)
select access_id, count(*) as warn_events
from public.security_events
where severity = 'warn'
  and access_id is not null
  and created_at > now() - interval '24 hours'
group by access_id
order by warn_events desc
limit 50;

-- 3) Repeated actor patterns by actor hash (72h)
select actor_scope, actor_hash, count(*) as total
from public.security_events
where actor_hash is not null
  and created_at > now() - interval '72 hours'
group by actor_scope, actor_hash
having count(*) >= 10
order by total desc
limit 100;

-- 4) Unlock error spikes (hourly, 24h)
select date_trunc('hour', created_at) as hour_bucket, count(*) as unlock_errors
from public.security_events
where event_type = 'unlock_error'
  and created_at > now() - interval '24 hours'
group by hour_bucket
order by hour_bucket desc;
