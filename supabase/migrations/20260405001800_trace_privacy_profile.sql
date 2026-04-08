-- Trace privacy profile controls for private-first runtime and app settings.

alter table public.user_safety_settings
  add column if not exists trace_privacy_profile text not null default 'minimal'
    check (trace_privacy_profile in ('confidential', 'minimal', 'audit-heavy'));
