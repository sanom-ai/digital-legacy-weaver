# Ecosystem Strategy

## North Star

Digital Legacy Weaver should grow as a private-first digital legacy coordination ecosystem.

The ecosystem must stay anchored to four rules:

1. `private-first` comes before convenience
2. `technical companion` comes before legal ambition
3. `policy-as-code` comes before hardcoded partner logic
4. `partner-ready` comes before partner-dependent

## What the ecosystem is

The ecosystem is not a marketplace-first strategy.

It is a layered product strategy built around one stable coordination core and a set of optional modules that can grow around it without weakening the product boundary.

## Layer 1: Core product

This is the permanent center of the system and should remain in the main repository.

Core responsibilities:

1. owner self-recovery workflow
2. beneficiary delivery workflow
3. private-first safety settings
4. PTN parsing, validation, and runtime enforcement
5. trigger, reminder, grace, and unlock orchestration
6. auditability, incident controls, rate limits, and safety gates
7. clear legal-boundary messaging in app and docs

Core outcome:

1. a safe, understandable, policy-driven technical companion

## Layer 2: PTN ecosystem

PTN is the strategic language layer of the ecosystem.

PTN should become the way modules, operators, and future partners express:

1. release requirements
2. privacy posture
3. evidence expectations
4. control ownership
5. audit and operational profiles

PTN ecosystem components:

1. public PTN format and runtime compatibility
2. public starter packs such as default, PDPA, and privacy profiles
3. conformance tooling and smoke tests
4. premium or proprietary PTN legacy packs under `LICENSE-PTN`

PTN outcome:

1. the ecosystem grows through policy packs and control profiles, not through ad hoc feature branching

## Layer 3: Workflow modules

Workflow modules sit around the core and should remain optional.

Examples:

1. partner-ready destination paths
2. handoff notice templates
3. legal companion templates
4. reviewer operations
5. beta operations and reliability scorecards
6. self-host deployment adapters

These modules should use the core policy and safety model instead of inventing their own workflow rules.

## Layer 4: Partner-facing surface

Partners should connect to stable contracts, not to internal app assumptions.

Partner-facing surface should be limited to:

1. partner-ready API contracts
2. handoff templates
3. destination path models
4. evidence and audit expectations
5. operational runbooks for controlled rollout

The product should stay useful even when no partner is connected.

That is the key ecosystem rule.

## Product map

### Keep in the main repository

These define the identity and trust posture of the product:

1. Flutter app and core user flows
2. Supabase schema and edge functions for trigger, unlock, TOTP, reviewer keys, and handoff notice
3. PTN parser, validator, smoke tests, runtime enforcement, and public examples
4. safety controls, runbooks, CI gates, beta ops, and release workflows
5. self-host scaffold and core dispatch adapter
6. public positioning, threat model, testing strategy, and release readiness docs

### Split into ecosystem modules when mature

These can evolve faster outside the core once the contracts are stable:

1. destination-specific path packs
2. industry-specific PTN packs
3. legal office workflow kits
4. family office or trustee operation kits
5. premium reviewer and governance extensions
6. enterprise self-host packages
7. hardware-backed PTN runtime or attestation modules

### Keep proprietary by design

These are strong candidates for private modules or commercial licensing:

1. PTN legacy premium packs
2. advanced policy libraries
3. enterprise governance controls
4. hardware-bound PTN execution components
5. certified deployment profiles and high-assurance control bundles

## Sequencing

The ecosystem should expand in this order:

1. stabilize core reliability and release quality
2. strengthen PTN as the common control language
3. harden partner-ready contracts and destination path abstractions
4. package repeatable workflow modules
5. open selective ecosystem modules and premium PTN layers

## Decision rule for future work

A new feature belongs in the core only if it strengthens at least one of these:

1. private-first trust posture
2. policy runtime capability
3. secure delivery or recovery workflow
4. operational safety and incident readiness

If it is destination-specific, operator-specific, or commercial-profile specific, it should usually become an ecosystem module instead.

## Final framing

Digital Legacy Weaver should grow as:

1. a `private-first coordination core`
2. a `PTN-driven policy ecosystem`
3. a `partner-ready workflow foundation`

It should not grow as:

1. a legal authority platform
2. a giant integration marketplace before the core is stable
3. a cloud secret vault
