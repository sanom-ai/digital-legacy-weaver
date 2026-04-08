# runtime-status

Runtime monitoring endpoint for operations/reviewer team.

## What it returns

- `dispatch_health`: `healthy` | `degraded` | `down`
- `heartbeat_status`: latest `system_heartbeats.status` from `dispatch-trigger`
- `last_run_at`: latest runtime heartbeat timestamp
- `fail_reason`: best-effort reason from heartbeat details or latest error event
- `stats`: dispatch event totals (window, by status, by stage)
- `recent_events`: latest dispatch events (limited list for quick triage)

## Access control

- Requires `x-reviewer-key` header.
- Accepts active keys from `reviewer_api_keys` table.
- Keeps backward-compatible fallback to `REVIEWER_API_KEY` env for transition.

## Request

```json
{
  "window_hours": 24
}
```

`window_hours` is optional, clamped to `1..168`.

## Deploy

```bash
supabase functions deploy runtime-status
```
