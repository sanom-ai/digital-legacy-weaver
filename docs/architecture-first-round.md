# Architecture (Risk-Control Round)

## UX principles

- Minimal luxury visual language (warm neutral palette, calm typography, soft cards)
- Private-first by default (owner-only data visibility)
- Low-friction critical actions ("I am still alive", clear countdown)

## Runtime components

1. Flutter app (`apps/flutter_app`)
- Single codebase target for mobile/web/desktop.
- Dashboard, vault section, delivery mode context scaffolded.

2. Supabase database (`supabase/migrations`)
- `profiles`: inactivity thresholds and contact channels
- `recovery_items`: encrypted content container
- `policy_documents`: active `.ptn` source
- `trigger_logs`: auditable trigger events
- `system_heartbeats`: scheduler health signal for external monitoring
- `trigger_dispatch_events`: idempotent reminder/release stage records
- `delivery_access_keys`: one-time secure link access-key hash storage
- `user_safety_settings`: legal consent + reminder/grace/pause controls
- `owner_life_signals`: multi-channel proof-of-life events
- `guardian_approvals`: optional human approval gate for legacy release
- `legal_evidence_records`: optional partner-integration evidence metadata (not entitlement authority)
- RLS enabled on all user-sensitive tables

3. Trigger dispatcher (`supabase/functions/dispatch-trigger`)
- Pulls active policy from `policy_documents`
- Compiles/evaluates PTN rules
- Writes heartbeat on every run
- Applies reminder stages and grace period
- Blocks release when legal consent missing or emergency pause is active
- Blocks release when recent multi-signal life proof is detected
- Blocks legacy release when guardian approval is required but missing
- Includes explicit legal-verification handoff notice to destination providers
- Sends secure access links (not plaintext secret) via provider fallback
- Writes event logs

4. Delivery unlock endpoint (`supabase/functions/open-delivery-link`)
- Receives one-time access credential request from recipient
- Sends short-lived verification code to intended email
- Unlocks encrypted bundle only after access credentials + code verification
- Consumes access key/challenge to prevent replay

5. Legal review endpoint (`supabase/functions/review-legal-evidence`)
- Reviewer-key protected API for legal evidence decisions
- Applies SQL aggregation rule (`apply_legal_evidence_review`) for 4-eyes verification

## PTN integration model

- Author policy in repo as `.ptn`
- Validate in CI with `tools/ptn_parser.py`
- Sync active version to `policy_documents`
- Use compiled policy in dispatch runtime

## Security posture in this round

- No plaintext secret storage in schema contract (`encrypted_payload` required)
- RLS owner isolation for profile/items
- Trigger execution records with reason and metadata
- Policy checks before sending any release email
- Final delivery uses one-time access links, not raw secrets in email

## Next iteration

1. Persist life-signal events from app/web and notification callbacks
2. Guardian approval UX and out-of-band confirmation channels
3. Self-host adapter wiring (`selfhost/core` + DB + PTN runtime)
