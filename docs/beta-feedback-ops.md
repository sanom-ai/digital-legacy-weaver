# Beta Feedback Operations

## Purpose

Capture structured user feedback and incident reports directly from the app during beta.

## Data model

Table:

1. `public.beta_feedback_reports`

Fields include:

1. category (`ux`, `bug`, `security`, `reliability`, `other`)
2. severity (`low`, `medium`, `high`, `critical`)
3. summary/details
4. status lifecycle (`open`, `triaged`, `resolved`, `wontfix`)

## App entry point

Dashboard card:

1. `Beta Feedback`

Screen:

1. `apps/flutter_app/lib/features/beta/beta_feedback_screen.dart`

## Daily triage recommendation

1. Review all `open` feedback items.
2. Escalate `security` and `critical` immediately.
3. Convert recurring `bug`/`reliability` items into engineering tasks.
4. Track closure rate week-over-week.
