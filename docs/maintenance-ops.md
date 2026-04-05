# Maintenance Ops

## Purpose

Operational tables grow quickly (`security_events`, heartbeat, dispatch, rate limits, access challenges).
Run periodic cleanup to keep performance stable.

## Cleanup RPC

Database function:

- `public.run_maintenance_cleanup(p_retention_days int default 30)`

## Run once (manual)

```powershell
.\scripts\run_maintenance_cleanup.ps1 -RetentionDays 30
```

Required env:

1. `SUPABASE_URL`
2. `SUPABASE_SERVICE_ROLE_KEY`

## Recommended schedule

1. Run daily during low-traffic window
2. Keep retention >= 30 days for forensic value
3. Use longer retention for compliance environments

## Safety note

Do not set retention below 7 days (guarded by function).
