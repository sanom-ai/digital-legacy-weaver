-- Maintenance cleanup for operational tables.

create or replace function public.run_maintenance_cleanup(p_retention_days int default 30)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_cutoff timestamptz;
  v_deleted_security_events int := 0;
  v_deleted_rate_limits int := 0;
  v_deleted_challenges int := 0;
  v_deleted_access_keys int := 0;
  v_deleted_dispatch_events int := 0;
  v_deleted_trigger_logs int := 0;
  v_deleted_heartbeats int := 0;
begin
  if p_retention_days < 7 then
    raise exception 'retention_days must be >= 7';
  end if;

  v_cutoff := now() - make_interval(days => p_retention_days);

  delete from public.security_events
  where created_at < v_cutoff;
  get diagnostics v_deleted_security_events = row_count;

  delete from public.delivery_access_rate_limits
  where coalesce(blocked_until, window_started_at) < v_cutoff;
  get diagnostics v_deleted_rate_limits = row_count;

  delete from public.delivery_access_challenges
  where (
      consumed_at is not null
      and consumed_at < v_cutoff
    )
    or (
      expires_at < v_cutoff
      and consumed_at is null
    );
  get diagnostics v_deleted_challenges = row_count;

  delete from public.delivery_access_keys
  where (
      consumed_at is not null
      and consumed_at < v_cutoff
    )
    or (
      expires_at < v_cutoff
      and consumed_at is null
    );
  get diagnostics v_deleted_access_keys = row_count;

  delete from public.trigger_dispatch_events
  where created_at < v_cutoff;
  get diagnostics v_deleted_dispatch_events = row_count;

  delete from public.trigger_logs
  where triggered_at < v_cutoff;
  get diagnostics v_deleted_trigger_logs = row_count;

  delete from public.system_heartbeats
  where created_at < v_cutoff;
  get diagnostics v_deleted_heartbeats = row_count;

  return jsonb_build_object(
    'retention_days', p_retention_days,
    'cutoff', v_cutoff,
    'deleted', jsonb_build_object(
      'security_events', v_deleted_security_events,
      'delivery_access_rate_limits', v_deleted_rate_limits,
      'delivery_access_challenges', v_deleted_challenges,
      'delivery_access_keys', v_deleted_access_keys,
      'trigger_dispatch_events', v_deleted_dispatch_events,
      'trigger_logs', v_deleted_trigger_logs,
      'system_heartbeats', v_deleted_heartbeats
    )
  );
end;
$$;
