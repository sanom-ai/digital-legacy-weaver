from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
DISPATCH_FN = ROOT / "supabase" / "functions" / "dispatch-trigger" / "index.ts"
UNLOCK_FN = ROOT / "supabase" / "functions" / "open-delivery-link" / "index.ts"
TOTP_FN = ROOT / "supabase" / "functions" / "manage-totp-factor" / "index.ts"
LEGAL_REVIEW_FN = ROOT / "supabase" / "functions" / "review-legal-evidence" / "index.ts"
MANAGE_REVIEWER_KEYS_FN = ROOT / "supabase" / "functions" / "manage-reviewer-keys" / "index.ts"
HANDOFF_NOTICE_FN = ROOT / "supabase" / "functions" / "handoff-notice" / "index.ts"


def _read(path: Path) -> str:
    return path.read_text(encoding="utf-8")


def test_dispatch_uses_access_link_query_contract() -> None:
    src = _read(DISPATCH_FN)
    assert "access_id=" in src
    assert "access_key=" in src


def test_dispatch_respects_global_safety_control() -> None:
    src = _read(DISPATCH_FN)
    assert "system_safety_controls" in src
    assert "dispatch_enabled" in src
    assert "skipped" in src


def test_dispatch_supports_multisignal_proof_of_life_gate() -> None:
    src = _read(DISPATCH_FN)
    assert "owner_life_signals" in src
    assert "require_multisignal_before_release" in src
    assert "recent multi-signal proof-of-life detected" in src


def test_dispatch_supports_guardian_approval_gate() -> None:
    src = _read(DISPATCH_FN)
    assert "guardian_approvals" in src
    assert "require_guardian_approval_legacy" in src
    assert "guardian approval missing for legacy release" in src


def test_dispatch_mentions_external_legal_verification_handoff() -> None:
    src = _read(DISPATCH_FN)
    assert "Legal entitlement verification must be completed directly with the destination app/provider." in src
    assert "Provider handoff checklist:" in src
    assert "technical coordination layer only" in src


def test_dispatch_emits_requirement_trace_metadata() -> None:
    src = _read(DISPATCH_FN)
    assert "requirementTrace" in src
    assert "strictMissing" in src
    assert "advisoryUnmet" in src
    assert "enforcement" in src
    assert "privateFirstMode" in src
    assert "traceRetentionDays" in src
    assert "sanitizeRequirementTrace" in src
    assert "tracePrivacyProfile" in src
    assert "effectiveTraceProfile" in src


def test_dispatch_runtime_supports_compiler_emitted_requirement_controls() -> None:
    src = _read(DISPATCH_FN)
    assert 'requirement === "multisignal_recent"' in src
    assert 'requirement === "guardian_approval"' in src
    assert 'requirement === "verification_code"' in src
    assert 'requirement === "totp_factor"' in src
    assert 'requirement === "beneficiary_identity_match"' in src
    assert 'requirement === "fallback_channels_ready"' in src
    assert 'requirement === "server_heartbeat_fallback"' in src


def test_dispatch_runtime_supports_inactivity_and_exact_date_schedules() -> None:
    src = _read(DISPATCH_FN)
    assert "delivery_trigger_schedules" in src
    assert 'triggerMode === "exact_date"' in src
    assert 'triggerMode === "inactivity"' in src
    assert 'triggerMode === "manual_release"' in src


def test_unlock_accepts_request_code_and_unlock_actions() -> None:
    src = _read(UNLOCK_FN)
    assert "request_code" in src
    assert "unlock" in src


def test_unlock_returns_503_when_globally_disabled() -> None:
    src = _read(UNLOCK_FN)
    assert "unlock_enabled" in src
    assert "status: 503" in src


def test_unlock_contains_rate_limit_scopes() -> None:
    src = _read(UNLOCK_FN)
    required_scopes = [
        "request_code_by_ip",
        "request_code_by_access_id",
        "unlock_by_ip",
        "unlock_by_access_id",
    ]
    for scope in required_scopes:
        assert scope in src


def test_unlock_enforces_challenge_reuse_and_temporary_lock() -> None:
    src = _read(UNLOCK_FN)
    assert "challenge_reuse_guard" in src
    assert "temporary_lock_until" in src
    assert "unlock_temporary_lock" in src


def test_unlock_logs_key_security_events() -> None:
    src = _read(UNLOCK_FN)
    required_events = [
        "rate_limited",
        "access_denied",
        "invalid_code",
        "unlock_success",
        "unlock_error",
        "unlock_disabled",
        "invalid_totp",
    ]
    for event_name in required_events:
        assert event_name in src


def test_unlock_supports_totp_code_contract() -> None:
    src = _read(UNLOCK_FN)
    assert "totp_code" in src
    assert "require_totp_unlock" in src
    assert "beneficiary_name" in src
    assert "verification_phrase" in src
    assert "verifyLegacyBeneficiaryIdentity" in src
    assert "pre-registered name" in src or "pre-registered identity" in src


def test_unlock_returns_live_delivery_context() -> None:
    src = _read(UNLOCK_FN)
    assert "delivery_context" in src
    assert "source: \"live_runtime\"" in src
    assert "trigger_dispatch_events" in src


def test_totp_management_actions_present() -> None:
    src = _read(TOTP_FN)
    required_actions = [
        "status",
        "begin_setup",
        "confirm_setup",
        "disable",
    ]
    for action in required_actions:
        assert action in src


def test_totp_management_requires_authorization() -> None:
    src = _read(TOTP_FN)
    assert "Authorization" in src
    assert "client.auth.getUser()" in src


def test_legal_review_function_requires_reviewer_key() -> None:
    src = _read(LEGAL_REVIEW_FN)
    assert "x-reviewer-key" in src
    assert "REVIEWER_API_KEY" in src
    assert "Reviewer authorization failed." in src
    assert "reviewer_api_keys" in src
    assert "key_hash" in src


def test_legal_review_function_supports_review_and_summary() -> None:
    src = _read(LEGAL_REVIEW_FN)
    assert "\"review\"" in src
    assert "\"summary\"" in src
    assert "\"queue\"" in src
    assert "apply_legal_evidence_review" in src
    assert "approvals" in src
    assert "rejections" in src
    assert "needs_info_count" in src


def test_manage_reviewer_keys_requires_admin_key() -> None:
    src = _read(MANAGE_REVIEWER_KEYS_FN)
    assert "x-reviewer-admin-key" in src
    assert "REVIEWER_ADMIN_API_KEY" in src
    assert "Reviewer admin authorization failed." in src


def test_manage_reviewer_keys_supports_allowlist_actions() -> None:
    src = _read(MANAGE_REVIEWER_KEYS_FN)
    assert "\"list_keys\"" in src
    assert "\"add_key\"" in src
    assert "\"deactivate_key\"" in src
    assert "reviewer_api_keys" in src


def test_handoff_notice_requires_internal_key_header() -> None:
    src = _read(HANDOFF_NOTICE_FN)
    assert "x-handoff-internal-key" in src
    assert "HANDOFF_INTERNAL_KEY" in src
    assert "Handoff authorization failed." in src


def test_handoff_notice_tracks_audit_and_delivery_status() -> None:
    src = _read(HANDOFF_NOTICE_FN)
    assert "partner_handoff_notices" in src
    assert "delivery_status" in src
    assert "submit_partner_handoff_notice" in src
