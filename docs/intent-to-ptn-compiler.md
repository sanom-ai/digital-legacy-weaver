# Intent-to-PTN Compiler

## Purpose

The compiler turns structured legacy intent into canonical PTN.

This is the bridge that makes the product model work:

1. users define intent in normal language
2. the app captures that intent as structured data
3. the compiler emits PTN as the canonical policy artifact

## Compiler source

Current compiler foundation:

1. `tools/intent_to_ptn.py`

## Input

The compiler accepts a structured intent document shaped by:

1. `docs/ptn-intent-schema.md`
2. `apps/flutter_app/lib/features/intent_builder/intent_builder_model.dart`

## Output

The compiler emits:

1. PTN headers
2. base actor roles
3. baseline authorities
4. compiled safeguard constraints
5. one policy block per active intent entry

## Compile rules (current foundation)

1. only `active` entries compile into policy output
2. `legacy_delivery` maps to `trigger_legacy_delivery`
3. `self_recovery` maps to `trigger_self_recovery_delivery`
4. privacy profile compiles into PTN header and policy effect labels
5. delivery requirements compile into explicit safeguard requirements where possible
6. contradictory or incomplete intent fails before PTN generation

## Current validation

The compiler rejects:

1. missing top-level identifiers
2. unsupported privacy profiles
3. unsupported entry kinds
4. unsupported delivery methods
5. missing asset or recipient references
6. invalid inactivity thresholds

## Current limitation

This first compiler pass is deterministic and intentionally conservative.

It does not yet:

1. optimize PTN block reuse
2. infer advanced partner-path requirements automatically
3. compile every runtime safety control in the platform
4. emit human-facing warnings separate from hard errors

## Next step

The next compiler improvements should add:

1. warning channels for ambiguous intent
2. richer mapping from safeguards to PTN requirement metadata
3. compiler trace output from `entry_id` to generated PTN block identifiers
