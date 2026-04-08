alter table public.user_safety_settings
  add column if not exists proof_of_life_check_mode text not null default 'biometric_tap';

alter table public.user_safety_settings
  add column if not exists proof_of_life_fallback_channels text[] not null default array['email', 'sms']::text[];

alter table public.user_safety_settings
  add column if not exists server_heartbeat_fallback_enabled boolean not null default true;

alter table public.user_safety_settings
  add column if not exists ios_background_risk_acknowledged boolean not null default false;

alter table public.user_safety_settings
  drop constraint if exists user_safety_settings_proof_of_life_mode_check;

alter table public.user_safety_settings
  add constraint user_safety_settings_proof_of_life_mode_check
  check (proof_of_life_check_mode in ('biometric_tap', 'single_tap', 'verification_code'));

alter table public.profiles
  add column if not exists beneficiary_name text;

alter table public.profiles
  add column if not exists beneficiary_phone text;

alter table public.profiles
  add column if not exists beneficiary_verification_hint text;

alter table public.profiles
  add column if not exists beneficiary_verification_phrase_hash text;
