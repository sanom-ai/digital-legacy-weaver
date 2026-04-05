# Intent Compiler Contract

## Purpose

This contract defines the shared output shape that sits between:

1. structured user intent
2. PTN compilation
3. Flutter review/export flows
4. future backend/runtime artifact consumers

The goal is to reduce drift between Python compiler outputs and Flutter-side draft/export handling.

## Contract identifier

`intent-compiler-contract/v1`

Every canonical compiler report or artifact bundle should include:

1. `contract_version`

## Canonical compile-with-trace output

Top-level fields:

1. `contract_version`
2. `ptn`
3. `trace`
4. `report`
5. `warnings`

## Canonical artifact bundle

Top-level fields:

1. `contract_version`
2. `intent_id`
3. `owner_ref`
4. `generated_at`
5. `ptn`
6. `trace`
7. `report`

## Report shape

Top-level fields:

1. `ok`
2. `error_count`
3. `warning_count`
4. `issues`

Issue fields:

1. `severity`
2. `code`
3. `message`
4. optional `entry_id`

## Trace shape

Top-level fields:

1. `intent_id`
2. `owner_ref`
3. `entries`

Per-entry fields:

1. `policy_block_id`
2. `action`
3. `privacy_profile`

## Current source implementations

Python:

1. `tools/intent_to_ptn.py`

Flutter:

1. `apps/flutter_app/lib/features/intent_builder/intent_compiler_report_model.dart`
2. `apps/flutter_app/lib/features/intent_builder/intent_canonical_artifact_model.dart`
3. `apps/flutter_app/lib/features/intent_builder/intent_trace_preview.dart`

## Current boundary

This contract does not yet mean Flutter and Python run a single shared compiler engine.

It means:

1. both sides now target the same artifact and report shape
2. tests can assert the same fields and identifiers
3. future unification work has a fixed contract to converge on
