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
2. `compile_intent_document_with_trace(...)` for compiler-side trace mapping
3. `build_intent_compiler_report(...)` for UI-facing validation and warning output

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
6. optional compiler trace mapping from `entry_id` to generated PTN blocks

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

## Warning layer

The compiler now separates:

1. hard errors that must block compilation
2. soft warnings that should be surfaced to operators or UI flows

Report shape:

1. `ok`
2. `error_count`
3. `warning_count`
4. `issues[]`

Each issue contains:

1. `severity`
2. `code`
3. `message`
4. optional `entry_id`

Current warning examples:

1. active entry has no `payload_ref`
2. active entry has no `partner_path`
3. active entry has no multisignal safeguard
4. privacy posture may conflict with trace-minimization expectations

## Current limitation

This first compiler pass is deterministic and intentionally conservative.

It does not yet:

1. optimize PTN block reuse
2. infer advanced partner-path requirements automatically
3. compile every runtime safety control in the platform
4. classify warnings beyond the current error/warning split for UX presentation

## Next step

The next compiler improvements should add:

1. severity-ranked warning channels for ambiguous intent
2. richer mapping from safeguards to PTN requirement metadata
3. runtime consumption of compiler trace output from `entry_id` to generated PTN block identifiers
