# Ecosystem Execution Roadmap

This roadmap translates the ecosystem strategy into the order of execution.

The rule is simple:

1. stabilize the core
2. strengthen PTN
3. harden partner-ready contracts
4. open ecosystem layers selectively

## Phase 1: Make the core stable

Goal:

1. make the product trustworthy as a private-first technical companion before widening scope

Must win:

1. sustained green quality, runtime, and release workflows
2. stronger unlock and dispatch integration evidence
3. reliable reminder, grace, pause, and cleanup behavior
4. consistent legal-boundary and private-first messaging in app, docs, and release assets
5. better evidence for local-first reliability on supported client environments

Primary workstreams:

1. close remaining beta-to-stable reliability gaps
2. increase end-to-end test depth for trigger and unlock lifecycle
3. keep incident response and safety drill practice current
4. keep app wording and settings aligned with responsible product posture

Exit criteria:

1. stable gates in `docs/release-readiness-checklist.md` are satisfied
2. reliability evidence meets the threshold in `docs/testing-strategy.md`
3. core user flows are understandable without partner assumptions

## Phase 2: Make the PTN ecosystem strong

Goal:

1. turn PTN into the common language for product controls, privacy posture, and workflow modules

Must win:

1. stronger PTN enforcement coverage in runtime
2. clearer pack structure for public, premium, and proprietary PTN assets
3. reusable profile packs for privacy, risk, and operating modes
4. stronger conformance testing and policy attack-case coverage

Primary workstreams:

1. expand PTN runtime enforcement beyond current trigger path
2. add more policy packs with clean versioning and ownership rules
3. document PTN authoring and module boundaries
4. prepare PTN for future hardware-backed or enterprise execution contexts

Exit criteria:

1. PTN is the default way to express release controls
2. public and proprietary PTN boundaries are clear and enforced
3. policy modules can be added without changing core orchestration logic

## Phase 3: Make partner-ready contracts and specs clear

Goal:

1. provide stable contracts for destination-facing workflows without making the product partner-dependent

Must win:

1. stable partner-facing spec language
2. clear destination path model
3. repeatable handoff template and operational guardrails
4. better separation between core workflow and destination-specific assumptions

Primary workstreams:

1. refine `specs/partner-api.openapi.yaml`
2. evolve `docs/legacy-connector-spec.md` into a cleaner contract package
3. standardize destination path terminology across app, docs, and API
4. define minimum reliability, security, and audit expectations for partner-ready modules

Exit criteria:

1. partner-ready contracts are readable without internal knowledge
2. the product remains useful with zero partners connected
3. no partner-facing contract weakens the private-first or technical-companion posture

## Phase 4: Open ecosystem layers one section at a time

Goal:

1. expand carefully through optional modules after the core and contracts are ready

Open in this order:

1. PTN policy packs
2. workflow kits and destination path modules
3. operator and legal-office kits
4. enterprise and self-host extensions
5. hardware-backed PTN execution modules

Guardrails:

1. no module should force sensitive payload custody into the core
2. no module should blur the legal boundary
3. no module should bypass PTN and safety controls
4. no ecosystem launch should happen before the relevant core contract is stable

## Decision table

Use this rule before building anything new:

1. if it improves trust, safety, delivery, recovery, or PTN runtime, keep it in core
2. if it is destination-specific, operator-specific, or commercial-profile specific, move it toward a module
3. if it expresses policy, make PTN the first integration surface
4. if it increases legal ambiguity, narrow the scope before building

## Current recommendation

Focus order from now:

1. core stability
2. PTN strength
3. partner-ready contract clarity
4. ecosystem opening

That order protects the product identity while still building toward a real ecosystem.
