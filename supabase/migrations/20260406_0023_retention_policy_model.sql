-- Retention policy controls for delivery links, payload artifacts, and audit traces.

alter table public.user_safety_settings
add column if not exists delivery_access_ttl_hours int not null default 72
check (delivery_access_ttl_hours between 24 and 168);

alter table public.user_safety_settings
add column if not exists payload_retention_days int not null default 30
check (payload_retention_days between 7 and 180);

alter table public.user_safety_settings
add column if not exists audit_log_retention_days int not null default 30
check (audit_log_retention_days between 7 and 365);
