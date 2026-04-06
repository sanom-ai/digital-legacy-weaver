# Digital Legacy Weaver : Legacy logistics, privately coordinated.

Legacy logistics, privately coordinated.

![Digital Legacy Weaver Header](docs/assets/social/repo-header-banner.png)

Private-first digital legacy coordination for secure self-recovery, beneficiary delivery, and partner-ready continuity workflows.

## Overview

Digital Legacy Weaver is a private-first technical companion for digital continuity.

It helps owners prepare secure legacy routes without forcing early disclosure, and it helps intended recipients move through sensitive handoff moments with more clarity, structure, and restraint.

The product is built around three ideas:

1. `Owner-first control` while the owner is alive.
2. `Policy-driven release` through PTN as the canonical control plane.
3. `Careful beneficiary handoff` after qualified trigger conditions are met.

In practice, Digital Legacy Weaver coordinates:

1. `Self-recovery` for the owner.
2. `Legacy delivery` for intended recipients.
3. `Private-first` release posture, where secrets stay local whenever possible.
4. `Partner-ready` verification routes for institutions, legal offices, and trusted service providers.

## Boundary

This project is:

1. A technical coordination layer.
2. A private-first runtime and policy foundation.
3. A partner-ready workflow core.

This project is not:

1. A legal will replacement.
2. A legal decision authority.
3. A plaintext secret-sharing tool.
4. A guarantee of success under every device or network condition.

See [docs/legal-companion-mode.md](docs/legal-companion-mode.md), [docs/legal-evidence-gate.md](docs/legal-evidence-gate.md), and [docs/provider-handoff-template.md](docs/provider-handoff-template.md) for the legal boundary and handoff posture.

## Start Here

1. See [`docs/three-layer-architecture.md`](docs/three-layer-architecture.md) for the core system model.
2. See [`docs/high-assurance-architecture.md`](docs/high-assurance-architecture.md) for the runtime architecture.
3. See [`docs/pr-roadmap.md`](docs/pr-roadmap.md) for the current build sequence.
4. See [`docs/testing-strategy.md`](docs/testing-strategy.md) for validation coverage.
5. See [`docs/release-readiness-checklist.md`](docs/release-readiness-checklist.md) for stable-release gates.
6. Run `python tools/release_gate_preflight.py --max-age-days 30` before creating a release tag.

## Product Direction

1. See [`docs/ecosystem-strategy.md`](docs/ecosystem-strategy.md) for the long-term ecosystem model.
2. See [`docs/ecosystem-execution-roadmap.md`](docs/ecosystem-execution-roadmap.md) for phased execution.
3. See [`docs/positioning-audience-guide.md`](docs/positioning-audience-guide.md) for audience language.
4. See [`docs/first-launch-execution.md`](docs/first-launch-execution.md) for launch sequencing.
5. See [`docs/closed-beta-checklist.md`](docs/closed-beta-checklist.md) for beta discipline.

## PTN And Intent System

1. See [`specs/ptn-format.md`](specs/ptn-format.md) for the baseline PTN format.
2. See [`specs/ptn-v2.md`](specs/ptn-v2.md) for PTN v2 semantics.
3. See [`specs/intent-compiler-contract.md`](specs/intent-compiler-contract.md) for the shared compiler contract.
4. See [`docs/ptn-intent-schema.md`](docs/ptn-intent-schema.md) for the intent schema before compilation.
5. See [`docs/intent-builder-model.md`](docs/intent-builder-model.md) for the app-facing intent model.
6. See [`docs/intent-to-ptn-compiler.md`](docs/intent-to-ptn-compiler.md) for compiler rules.
7. See [`docs/pdpa-policy-mapping.md`](docs/pdpa-policy-mapping.md) for PDPA mappings.
8. See [`docs/ptn-licensing-boundary.md`](docs/ptn-licensing-boundary.md) for PTN open/proprietary boundaries.

## Architecture

The working architecture has three main layers:

1. `User layer`: UX/UI captures intent in normal language.
2. `PTN core layer`: PTN governs policy, security, runtime, and controls.
3. `Output layer`: approved results are delivered to configured recipients or routes.

See [`docs/three-layer-architecture.md`](docs/three-layer-architecture.md) for the full layer map.

## Current Status

Current line is `v0.1.x`.

That means:

1. The foundation is strong enough for controlled beta testing.
2. The app, PTN compiler flow, artifact history, and runtime-readiness flow are real.
3. The project should still be described as a technical companion, not a full production-stable legal or custodial platform.

## Current App Surface

The Flutter app currently covers:

1. Onboarding and safety settings.
2. Intent Builder with local encrypted draft persistence.
3. Canonical PTN artifact export.
4. Artifact review, compare, promote, and history flows.
5. Runtime readiness summary and detail views.
6. Demo / setup-backend landing for builds without live Supabase configuration.

## Operations And Security

1. See [`docs/production-deploy-runbook.md`](docs/production-deploy-runbook.md) for deployment operations.
2. See [`docs/incident-response.md`](docs/incident-response.md) for incident handling.
3. See [`docs/threat-model.md`](docs/threat-model.md) for threat assumptions.
4. See [`docs/e2e-test-pack.md`](docs/e2e-test-pack.md) for runtime checks.
5. See [`docs/github-test-secrets-setup.md`](docs/github-test-secrets-setup.md) for CI secret setup.
6. See [`docs/beta-gate-ops.md`](docs/beta-gate-ops.md), [`docs/beta-status-ops.md`](docs/beta-status-ops.md), and [`docs/beta-feedback-ops.md`](docs/beta-feedback-ops.md) for beta operations.
7. See [SECURITY.md](SECURITY.md) for the security policy.

## Release And Delivery

1. See [`docs/app-release-pack.md`](docs/app-release-pack.md) for release packaging.
2. See [`docs/releases/v0.1.0-release-notes-template.md`](docs/releases/v0.1.0-release-notes-template.md) for the release-note template.
3. See [`docs/releases/v0.1.0.md`](docs/releases/v0.1.0.md) for the baseline release notes.
4. See [`docs/releases/v0.1.0-beta.4.md`](docs/releases/v0.1.0-beta.4.md) for the current beta note.
5. The app release workflow lives at [`.github/workflows/app-release.yml`](.github/workflows/app-release.yml).

## Local Development

Local quality gate:

```powershell
python -m pip install -r requirements-dev.txt
.\scripts\run_local_quality_gate.ps1
```

Backend deploy:

```powershell
.\scripts\deploy_production.ps1 -ProjectRef <your_project_ref>
.\scripts\post_deploy_smoke.ps1 -ProjectRef <your_project_ref>
.\scripts\security_gate_preflight.ps1
```

Runtime checks:

```powershell
.\scripts\run_integration_unlock_flow.ps1 -ProjectRef <project_ref>
.\scripts\run_adversarial_unlock_checks.ps1 -ProjectRef <project_ref>
```

## Repository Guide

Main implementation areas:

1. App: [`apps/flutter_app`](apps/flutter_app)
2. PTN and contracts: [`specs`](specs)
3. Architecture and runbooks: [`docs`](docs)
4. Backend schema and functions: [`supabase/migrations`](supabase/migrations) and [`supabase/functions`](supabase/functions)
5. Release and operations scripts: [`scripts`](scripts)
6. Beta SQL packs: [`ops/sql`](ops/sql)

Useful file groups:

1. Intent Builder: [`apps/flutter_app/lib/features/intent_builder`](apps/flutter_app/lib/features/intent_builder)
2. Dispatch runtime: [`supabase/functions/dispatch-trigger`](supabase/functions/dispatch-trigger)
3. Partner API surface: [`specs/partner-api.openapi.yaml`](specs/partner-api.openapi.yaml)
4. Proprietary PTN legacy boundary: [`ptn/legacy`](ptn/legacy)

## Contributing And Licensing

1. See [CONTRIBUTING.md](CONTRIBUTING.md) for contribution guidance.
2. See [`.github/CODEOWNERS`](.github/CODEOWNERS) for ownership rules.
3. Open-core repository code and public examples are under [LICENSE](LICENSE).
4. PTN legacy proprietary modules and premium policy assets are governed by [LICENSE-PTN](LICENSE-PTN).

## Private-First Runtime Posture

1. Sensitive payload is intended to remain on user-controlled devices.
2. Intent drafts can be cached locally with device-side encryption before PTN activation.
3. Canonical PTN artifacts can be exported into encrypted local history instead of overwriting a single latest draft.
4. Runtime traces are minimized to policy-control metadata.
5. CI blocks known secret-bearing logging patterns before merge.
