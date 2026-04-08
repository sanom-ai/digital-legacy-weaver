-- Global safety controls for emergency shutdown.

create table if not exists public.system_safety_controls (
  id boolean primary key default true,
  dispatch_enabled boolean not null default true,
  unlock_enabled boolean not null default true,
  reason text,
  updated_by text,
  updated_at timestamptz not null default now()
);

insert into public.system_safety_controls (id, dispatch_enabled, unlock_enabled, reason, updated_by)
values (true, true, true, null, 'system')
on conflict (id) do nothing;

create or replace function public.set_system_safety_controls(
  p_dispatch_enabled boolean,
  p_unlock_enabled boolean,
  p_reason text default null,
  p_updated_by text default 'ops'
)
returns public.system_safety_controls
language plpgsql
security definer
set search_path = public
as $$
declare
  v_row public.system_safety_controls;
begin
  update public.system_safety_controls
  set
    dispatch_enabled = p_dispatch_enabled,
    unlock_enabled = p_unlock_enabled,
    reason = p_reason,
    updated_by = p_updated_by,
    updated_at = now()
  where id = true
  returning * into v_row;

  return v_row;
end;
$$;
