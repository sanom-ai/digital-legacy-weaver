# Ops: Heartbeat Monitoring

Use `system_heartbeats` as internal proof that scheduler is alive.

## Recommended external checks

1. UptimeRobot/Cron-job.org calls `dispatch-trigger` on schedule.
2. Secondary monitor checks heartbeat freshness:
- Query latest row where `source = 'dispatch-trigger'`
- Alert if no `status='ok'` within 26 hours

## SQL probe

```sql
select source, status, created_at, details
from public.system_heartbeats
where source = 'dispatch-trigger'
order by created_at desc
limit 1;
```

## Alert policy

- `warn`: notify maintainer channel
- `error` or stale heartbeat: escalate immediately and pause final release if needed
