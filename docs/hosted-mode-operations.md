# Hosted Mode Operations

Goal: make the app usable like a normal downloadable app without asking users to self-host backend infrastructure.

## Hosted mode definition

1. Project team runs and monitors shared backend.
2. End users only install app and sign in.
3. Safety controls, scheduler, and incident handling are operated centrally.

## Minimum hosted requirements

1. Dedicated Supabase production and staging projects.
2. Scheduler and heartbeats active.
3. Security triage and incident runbooks active.
4. Release workflow and rollback path documented.

## User experience requirement

1. User signs in and sees setup wizard directly in dashboard.
2. User completes beneficiary, trigger, and consent setup in-app.
3. User does not need to configure secrets or infrastructure.

## Operator checklist

1. Run `docs/first-launch-execution.md` before first cohort.
2. Keep `e2e-runtime.yml` green on test project.
3. Keep release checklist green before stable expansion.

## Boundary reminder

Hosted mode does not change legal boundary:

1. Platform is a technical coordination layer.
2. Legal entitlement verification is still handled with destination app/provider and legal process.
