# PR Roadmap

## Product thesis

Digital Legacy Weaver is a private-first technical companion for user-defined legacy intent.

The product should evolve around one core idea:

1. users express intent in normal language
2. the system structures that intent
3. PTN becomes the canonical policy layer
4. runtime executes PTN with safety, privacy, and audit controls

## North Star

Use this sentence to keep future work aligned:

`Users define legacy intent in normal language. PTN turns it into safe, auditable execution.`

## What the product is

1. a private-first coordination core
2. a self-recovery and legacy-delivery workflow engine
3. a PTN-powered policy execution system
4. a partner-ready workflow foundation

## What the product is not

1. not a legal will
2. not a legal adjudication platform
3. not a cloud secret vault
4. not an integration marketplace first

## Golden rules for every PR

Before merging work, ask:

1. does this strengthen `private-first` trust posture
2. does this make PTN more clearly the source of truth
3. does this preserve the `technical companion` boundary
4. if all partners disappeared, would the product still have value

If the answer to item 4 is no, the work is likely drifting away from the core.

## Recommended PR sequence

### PR-01: Core Stability

Goal:

1. make the current core trustworthy before widening scope

Include:

1. trigger, reminder, grace, pause, and unlock reliability hardening
2. stronger end-to-end evidence for real release paths
3. stable beta and release workflows
4. wording consistency across app, docs, and release assets

Success signal:

1. core reliability and release gates are consistently green

### PR-02: PTN Intent Schema

Goal:

1. define the structured user intent model that sits before PTN

Include:

1. asset definition
2. recipient definition
3. trigger conditions
4. safeguard controls
5. delivery mode
6. privacy profile
7. ownership and audit hints where needed

Success signal:

1. the team can describe legacy intent without talking about UI screens or backend tables

### PR-03: Intent Builder Model

Goal:

1. make the app speak human language while staying separate from PTN syntax

Include:

1. human-friendly form model
2. plain-language labels and defaults
3. validation rules for incomplete or risky intent
4. clear separation between user input and canonical policy representation

Success signal:

1. users can define intent without seeing PTN directly

### PR-04: Intent-to-PTN Compiler

Goal:

1. compile structured intent into canonical PTN

Include:

1. deterministic mapping rules
2. safe defaults
3. compile warnings for ambiguous intent
4. validation output for unsupported combinations
5. traceable relation between user intent and emitted PTN

Success signal:

1. PTN becomes the canonical source of truth rather than a side artifact

### PR-05: PTN Runtime Expansion

Goal:

1. increase PTN enforcement coverage across the real workflow

Include:

1. stronger enforcement beyond the current trigger path
2. broader use of strict and advisory controls
3. better privacy-profile handling at runtime
4. richer decision trace that still respects private-first minimization

Success signal:

1. PTN controls more of the actual runtime behavior, not just validation and metadata

### PR-06: PTN Pack System

Goal:

1. turn PTN into a usable ecosystem layer

Include:

1. public pack structure
2. premium or proprietary pack boundaries
3. compatibility and versioning rules
4. authoring guidance and pack ownership model

Success signal:

1. new policy behavior can ship through packs without changing the core every time

### PR-07: Partner-ready Contract Cleanup

Goal:

1. make partner-facing language and contracts stable without making the product partner-dependent

Include:

1. destination path terminology
2. handoff route terminology
3. cleaner partner-ready API language
4. clearer boundary between core orchestration and destination-specific logic

Success signal:

1. partner-ready docs and specs read clearly even to someone outside the codebase

### PR-08: Ecosystem Module Boundary

Goal:

1. decide what belongs in the main repo and what should become a module

Include:

1. module boundary rules
2. first candidate modules
3. proprietary PTN boundaries
4. enterprise and self-host extension boundaries

Success signal:

1. the main repo stays focused while the ecosystem can expand safely

### PR-09: Stable Gate

Goal:

1. define when the product can responsibly call itself stable

Include:

1. reliability thresholds
2. incident drill evidence
3. runtime pass-rate requirements
4. wording and legal-boundary verification
5. policy enforcement coverage criteria

Success signal:

1. stable becomes an evidence-backed decision, not a feeling

## What stays in core

1. Flutter app and main user flows
2. PTN parser, compiler, validator, and runtime
3. trigger, unlock, delivery, and recovery logic
4. private-first controls and trace minimization
5. incident, safety, beta, and release operations
6. public positioning, threat model, and readiness docs

## What becomes ecosystem modules

1. destination-specific path packs
2. legal office workflow kits
3. trustee and family office operation kits
4. enterprise governance extensions
5. proprietary PTN legacy packs
6. hardware-backed PTN execution layers

## Professional narrative

Use these phrases consistently:

1. `private-first coordination core`
2. `user-defined legacy intent`
3. `PTN-powered policy execution`
4. `partner-ready workflow foundation`
5. `technical companion, not legal authority`

## Recommended immediate next step

Start with:

1. `PR-02: PTN Intent Schema`
2. `PR-03: Intent Builder Model`
3. `PR-04: Intent-to-PTN Compiler`

These three PRs create the bridge from human language to a powerful PTN system without losing the product boundary.
