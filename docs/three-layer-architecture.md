# Three-Layer Architecture

Digital Legacy Weaver is organized around three primary layers:

1. `User Layer`
2. `PTN Core Layer`
3. `Output Layer`

This document defines what each layer is responsible for, what should not live there, and how the current repository maps into that structure.

## North Star

The user should only need to express intent in normal language.

The system should then:

1. capture that intent in a human-friendly UX
2. translate it into canonical PTN policy
3. deliver only the output that PTN authorizes

In short:

`UX captures intent -> PTN governs it -> output delivers the approved result.`

## Layer 1: User Layer

The `User Layer` is the only layer the owner should directly experience.

Responsibilities:

1. collect user intent in plain language
2. reduce policy and security complexity into understandable choices
3. surface review, readiness, and warning states without exposing internal mechanics
4. let the owner manage drafts, activation, history, and review in a private-first way

Should contain:

1. onboarding
2. profile setup
3. safety settings
4. intent builder flows
5. dashboard summaries
6. artifact review, compare, history, and promote UX

Should not contain:

1. hardcoded security decisions that bypass PTN
2. business logic that decides delivery independently of policy
3. direct exposure of secret payloads as part of normal UX

Current module map:

1. `apps/flutter_app/lib/features/onboarding`
2. `apps/flutter_app/lib/features/profile`
3. `apps/flutter_app/lib/features/settings`
4. `apps/flutter_app/lib/features/dashboard`
5. `apps/flutter_app/lib/features/intent_builder`
6. `apps/flutter_app/lib/features/auth`
7. `apps/flutter_app/lib/features/beta`
8. `apps/flutter_app/lib/features/vault`

Current examples inside this layer:

1. encrypted local draft persistence
2. intent review and activation gating
3. canonical artifact export, review, history, compare, and promote
4. runtime readiness summary on the dashboard

## Layer 2: PTN Core Layer

The `PTN Core Layer` is the canonical control plane of the system.

This is the layer we must protect and maintain most carefully.

Responsibilities:

1. define policy semantics
2. encode security and privacy controls
3. compile structured intent into canonical PTN
4. evaluate runtime readiness and control requirements
5. preserve deterministic, auditable behavior across app, backend, and future modules

Should contain:

1. PTN language and format specs
2. intent schema and compiler contracts
3. PTN parser and validator
4. intent-to-PTN compiler logic
5. runtime decision semantics
6. policy packs and control mappings

Should not contain:

1. UX-specific assumptions
2. output-channel-specific hacks
3. legal claims beyond technical coordination boundaries

Current module map:

1. `specs/ptn-format.md`
2. `specs/ptn-v2.md`
3. `specs/intent-compiler-contract.md`
4. `docs/ptn-intent-schema.md`
5. `docs/intent-builder-model.md`
6. `docs/intent-to-ptn-compiler.md`
7. `tools/ptn_parser.py`
8. `tools/intent_to_ptn.py`
9. `examples/*.ptn`
10. `examples/intent-primary.json`
11. `examples/intent-canonical-artifact.sample.json`
12. `supabase/functions/dispatch-trigger/ptn_policy.ts`
13. `supabase/functions/dispatch-trigger/index.ts`
14. `ptn/legacy`

Operational note:

This layer is where policy, security posture, runtime control, trace shape, and enforcement logic should live. The rest of the system should depend on this layer, not redefine it.

## Layer 3: Output Layer

The `Output Layer` is where approved outcomes leave the PTN core and move toward the recipient or route chosen by the owner.

Responsibilities:

1. deliver only what policy authorizes
2. use secure, minimal output forms
3. keep destination-specific behavior out of the user-intent layer when possible
4. preserve auditability without expanding the system into a legal authority

Should contain:

1. secure link delivery
2. unlock flows
3. self-recovery routes
4. handoff notices
5. destination path references
6. partner-ready pathway handling

Should not contain:

1. policy decisions made independently from PTN
2. plaintext secret distribution by convenience channels
3. assumptions that all destinations behave the same way

Current module map:

1. `apps/flutter_app/lib/features/unlock`
2. `apps/flutter_app/lib/features/connectors`
3. `supabase/functions/open-delivery-link`
4. `supabase/functions/handoff-notice`
5. `supabase/functions/manage-totp-factor`
6. `specs/partner-api.openapi.yaml`
7. `docs/provider-handoff-template.md`
8. `docs/legacy-connector-spec.md`

## Layer Boundaries

The intended relationship between layers is:

1. `User Layer` defines intent
2. `PTN Core Layer` governs what is valid, safe, and runnable
3. `Output Layer` executes only the approved result

Boundary rules:

1. users interact with intent, not PTN syntax
2. PTN remains the canonical source of control logic
3. outputs must never exceed what PTN authorizes
4. destination integrations should stay partner-ready, not core-defining

## Repository Map Summary

### User Layer

1. `apps/flutter_app/lib/features/onboarding`
2. `apps/flutter_app/lib/features/profile`
3. `apps/flutter_app/lib/features/settings`
4. `apps/flutter_app/lib/features/dashboard`
5. `apps/flutter_app/lib/features/intent_builder`
6. `apps/flutter_app/lib/features/auth`
7. `apps/flutter_app/lib/features/beta`
8. `apps/flutter_app/lib/features/vault`

### PTN Core Layer

1. `specs/ptn-format.md`
2. `specs/ptn-v2.md`
3. `specs/intent-compiler-contract.md`
4. `docs/ptn-intent-schema.md`
5. `docs/intent-builder-model.md`
6. `docs/intent-to-ptn-compiler.md`
7. `tools/ptn_parser.py`
8. `tools/intent_to_ptn.py`
9. `examples/*.ptn`
10. `supabase/functions/dispatch-trigger`
11. `ptn/legacy`

### Output Layer

1. `apps/flutter_app/lib/features/unlock`
2. `apps/flutter_app/lib/features/connectors`
3. `supabase/functions/open-delivery-link`
4. `supabase/functions/handoff-notice`
5. `supabase/functions/manage-totp-factor`
6. `specs/partner-api.openapi.yaml`
7. `docs/provider-handoff-template.md`

## Design Check For New Work

Every meaningful feature should answer these questions:

1. does the user experience stay in the `User Layer`, or are we leaking PTN complexity upward?
2. does the rule belong in the `PTN Core Layer`, or are we hardcoding policy in the wrong place?
3. does the `Output Layer` only deliver approved outcomes, or is it inventing new logic?

If a change blurs those lines, the architecture is drifting.

## Practical Rule

When in doubt:

1. put human-language interaction in the `User Layer`
2. put control logic in the `PTN Core Layer`
3. put delivery behavior in the `Output Layer`

That keeps the product private-first, policy-driven, and partner-ready without losing clarity.
