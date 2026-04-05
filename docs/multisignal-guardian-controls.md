# Multi-Signal and Guardian Controls

## Problem this control solves

1. Owner may forget manual heartbeat for long periods.
2. A pure inactivity threshold can trigger false release.

## Control model

1. Multi-signal proof-of-life gate
- Release is skipped when recent diverse life signals are detected.
- Signal window and minimum signal diversity are configurable in `user_safety_settings`:
  - `recent_signal_window_hours`
  - `minimum_recent_signal_types`
  - `require_multisignal_before_release`

2. Guardian approval gate (legacy mode)
- Optional extra gate before final legacy release.
- Requires approved guardian record for the cycle date:
  - table: `guardian_approvals`
  - setting: `require_guardian_approval_legacy`
  - additional hold: `guardian_grace_hours`

## Data surfaces

1. `owner_life_signals`
- event stream for proof-of-life signals such as:
  - `alive_button`
  - `app_session`
  - `email_confirm`
  - `push_ack`

2. `guardian_approvals`
- explicit approval records for legacy release cycles.

## Dispatch behavior

When final release stage is evaluated:

1. Skip if multi-signal gate indicates owner is active recently.
2. Skip if guardian gate is required but not approved.
3. Proceed only when both controls pass.
