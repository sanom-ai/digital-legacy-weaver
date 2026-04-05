# Intent Builder Model

## Purpose

The app should help users define legacy intent in normal language without exposing PTN syntax directly.

This model is the app-facing representation of that idea.

It sits between:

1. user-facing forms and flows
2. the structured intent schema in `docs/ptn-intent-schema.md`
3. the future intent-to-PTN compiler

## Design rule

The intent builder model should be:

1. readable in product language
2. stable enough for compiler input
3. separate from runtime-only concerns
4. strict enough to prevent unsafe ambiguity

## Current app model

Flutter model source:

1. `apps/flutter_app/lib/features/intent_builder/intent_builder_model.dart`

Main objects:

1. `IntentDocumentModel`
2. `IntentEntryModel`
3. `IntentAssetModel`
4. `IntentRecipientModel`
5. `IntentTriggerModel`
6. `IntentDeliveryModel`
7. `IntentSafeguardsModel`
8. `IntentPrivacyModel`
9. `IntentPartnerPathModel`
10. `IntentGlobalSafeguardsModel`

## Why this matters

This keeps three layers clean:

1. user input stays human-friendly
2. intent stays structured and reviewable
3. PTN stays canonical and executable

## Next step

The next PR should introduce:

1. validation helpers for incomplete or contradictory intent
2. compiler mapping from intent models to PTN output
