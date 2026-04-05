from __future__ import annotations

from typing import Any, Dict, List


PRIVACY_PROFILE_ALLOWED = {"confidential", "minimal", "audit-heavy"}
ENTRY_KIND_ALLOWED = {"legacy_delivery", "self_recovery"}
DELIVERY_METHOD_ALLOWED = {"secure_link", "notification_only", "self_recovery_route"}
STATUS_ALLOWED = {"draft", "active", "paused", "archived"}
COMPILER_CONTRACT_VERSION = "intent-compiler-contract/v1"


class IntentCompilerError(Exception):
    pass


def _make_issue(
    severity: str,
    code: str,
    message: str,
    entry_id: str | None = None,
) -> Dict[str, str]:
    issue = {
        "severity": severity,
        "code": code,
        "message": message,
    }
    if entry_id is not None:
        issue["entry_id"] = entry_id
    return issue


def _slug(value: str) -> str:
    chars: List[str] = []
    for ch in value.lower():
      if ch.isalnum():
        chars.append(ch)
      elif ch in {" ", "-", "_", ":"}:
        chars.append("_")
    slug = "".join(chars).strip("_")
    while "__" in slug:
      slug = slug.replace("__", "_")
    return slug or "unknown"


def _quote(value: str) -> str:
    return value.replace('"', '\\"')


def _require_line(name: str, action: str, risk: str, mode: str, evidence: str, owner: str) -> str:
    return (
        f"  require {name}[risk={risk}, mode={mode}, evidence={evidence}, owner={owner}] for {action}"
    )


def validate_intent_document(intent: Dict[str, Any]) -> List[str]:
    issues: List[str] = []
    if not intent.get("intent_id"):
        issues.append("missing intent_id")
    if not intent.get("version"):
        issues.append("missing version")
    if not intent.get("owner_ref"):
        issues.append("missing owner_ref")

    default_profile = intent.get("default_privacy_profile", "minimal")
    if default_profile not in PRIVACY_PROFILE_ALLOWED:
        issues.append(f"unsupported default_privacy_profile '{default_profile}'")

    entries = intent.get("entries", [])
    if not isinstance(entries, list) or not entries:
        issues.append("intent must include at least one entry")
        return issues

    for index, entry in enumerate(entries):
        label = f"entry[{index}]"
        entry_id = entry.get("entry_id") or label
        kind = entry.get("kind")
        if kind not in ENTRY_KIND_ALLOWED:
            issues.append(f"{entry_id}: unsupported kind '{kind}'")

        status = entry.get("status", "draft")
        if status not in STATUS_ALLOWED:
            issues.append(f"{entry_id}: unsupported status '{status}'")

        asset = entry.get("asset") or {}
        if not asset.get("asset_id"):
            issues.append(f"{entry_id}: missing asset.asset_id")
        if not asset.get("display_name"):
            issues.append(f"{entry_id}: missing asset.display_name")

        recipient = entry.get("recipient") or {}
        if not recipient.get("recipient_id"):
            issues.append(f"{entry_id}: missing recipient.recipient_id")
        if not recipient.get("destination_ref"):
            issues.append(f"{entry_id}: missing recipient.destination_ref")

        trigger = entry.get("trigger") or {}
        inactivity_days = trigger.get("inactivity_days")
        if not isinstance(inactivity_days, int) or inactivity_days <= 0:
            issues.append(f"{entry_id}: trigger.inactivity_days must be a positive integer")

        delivery = entry.get("delivery") or {}
        method = delivery.get("method")
        if method not in DELIVERY_METHOD_ALLOWED:
            issues.append(f"{entry_id}: unsupported delivery.method '{method}'")

        privacy = entry.get("privacy") or {}
        profile = privacy.get("profile", default_profile)
        if profile not in PRIVACY_PROFILE_ALLOWED:
            issues.append(f"{entry_id}: unsupported privacy.profile '{profile}'")

    return issues


def collect_intent_warnings(intent: Dict[str, Any]) -> List[str]:
    warnings: List[str] = []
    default_profile = intent.get("default_privacy_profile", "minimal")
    global_safeguards = intent.get("global_safeguards") or {}

    if (global_safeguards.get("proof_of_life_check_mode") or "biometric_tap") not in {"biometric_tap", "single_tap"}:
        warnings.append("global: proof-of-life confirmation is heavier than a single tap flow; false-negative risk may increase")

    fallback_channels = global_safeguards.get("proof_of_life_fallback_channels") or []
    if len(set(fallback_channels)) < 2:
        warnings.append("global: proof-of-life fallback relies on fewer than two channels; add both email and SMS to reduce missed check-ins")

    if global_safeguards.get("server_heartbeat_fallback_enabled") is False:
        warnings.append("global: server heartbeat fallback is disabled; mobile background limits can increase false-trigger risk")

    if global_safeguards.get("ios_background_risk_acknowledged") is False:
        warnings.append("global: iOS/background execution risk is not acknowledged yet; review fallback posture before treating this workspace as reliable")

    for index, entry in enumerate(intent.get("entries", [])):
        label = f"entry[{index}]"
        entry_id = entry.get("entry_id") or label
        if entry.get("status") != "active":
            warnings.append(f"{entry_id}: entry is not active and will not compile into PTN output")
            continue

        recipient = entry.get("recipient") or {}
        if entry.get("kind") == "legacy_delivery" and not recipient.get("registered_legal_name"):
            warnings.append(f"{entry_id}: registered beneficiary identity is empty; configure a pre-registered recipient before delivery")

        if entry.get("kind") == "legacy_delivery" and not recipient.get("verification_hint"):
            warnings.append(f"{entry_id}: beneficiary verification hint is empty; recipient authentication will be weaker at unlock time")

        recipient_fallbacks = recipient.get("fallback_channels") or []
        if entry.get("kind") == "legacy_delivery" and len(set(recipient_fallbacks)) < 2:
            warnings.append(f"{entry_id}: beneficiary flow only has one fallback channel; add email plus SMS before treating proof-of-life as resilient")

        asset = entry.get("asset") or {}
        if not asset.get("payload_ref"):
            warnings.append(f"{entry_id}: asset.payload_ref is empty; delivery may be incomplete")

        trigger = entry.get("trigger") or {}
        if isinstance(trigger.get("grace_days"), int) and trigger.get("grace_days", 0) < 7:
            warnings.append(f"{entry_id}: grace_days is below 7; false triggers become harder to recover from")

        partner_path = entry.get("partner_path")
        if not partner_path:
            warnings.append(f"{entry_id}: no partner_path defined; workflow will remain core-only")

        privacy = entry.get("privacy") or {}
        profile = privacy.get("profile", default_profile)
        if profile == "audit-heavy" and privacy.get("minimize_trace_metadata", True):
            warnings.append(
                f"{entry_id}: audit-heavy profile with minimize_trace_metadata=true may reduce operational detail",
            )

        safeguards = entry.get("safeguards") or {}
        delivery = entry.get("delivery") or {}
        if delivery.get("method") == "notification_only" and safeguards.get("require_guardian_approval", False):
            warnings.append(
                f"{entry_id}: notification_only with guardian approval may need clearer operator messaging",
            )

        if not global_safeguards.get("require_multisignal_before_release", False) and not safeguards.get(
            "require_multisignal",
            False,
        ):
            warnings.append(f"{entry_id}: no multisignal safeguard configured for this active entry")

    return warnings


def build_intent_compiler_report(intent: Dict[str, Any]) -> Dict[str, Any]:
    errors = validate_intent_document(intent)
    warnings = collect_intent_warnings(intent)

    issues: List[Dict[str, str]] = []
    for error in errors:
        entry_id = error.split(":", 1)[0] if ":" in error else None
        issues.append(_make_issue("error", "intent_validation_error", error, entry_id))

    for warning in warnings:
        entry_id = warning.split(":", 1)[0] if ":" in warning else None
        code = "intent_warning"
        if "payload_ref is empty" in warning:
            code = "missing_payload_ref"
        elif "no partner_path defined" in warning:
            code = "missing_partner_path"
        elif "no multisignal safeguard configured" in warning:
            code = "missing_multisignal_safeguard"
        elif "audit-heavy profile" in warning:
            code = "privacy_trace_tension"
        elif "not active and will not compile" in warning:
            code = "inactive_entry_skipped"
        elif "registered beneficiary identity is empty" in warning:
            code = "missing_beneficiary_identity"
        elif "beneficiary verification hint is empty" in warning:
            code = "missing_beneficiary_verification_hint"
        elif "only has one fallback channel" in warning:
            code = "missing_multi_channel_fallback"
        elif "grace_days is below 7" in warning:
            code = "short_grace_period"
        elif "proof-of-life confirmation is heavier" in warning:
            code = "heavy_proof_of_life_check"
        elif "fallback relies on fewer than two channels" in warning:
            code = "single_channel_proof_of_life_fallback"
        elif "server heartbeat fallback is disabled" in warning:
            code = "server_heartbeat_fallback_disabled"
        elif "iOS/background execution risk is not acknowledged" in warning:
            code = "ios_background_risk_unacknowledged"
        issues.append(_make_issue("warning", code, warning, entry_id))

    return {
        "ok": len(errors) == 0,
        "error_count": len(errors),
        "warning_count": len(warnings),
        "issues": issues,
    }


def compile_intent_document(intent: Dict[str, Any]) -> str:
    issues = validate_intent_document(intent)
    if issues:
        raise IntentCompilerError("; ".join(issues))

    default_profile = intent.get("default_privacy_profile", "minimal")
    owner_ref = str(intent["owner_ref"])
    version = str(intent["version"])
    module = f"digital_legacy_weaver_intent_{_slug(intent['intent_id'])}"
    owner_slug = _slug(owner_ref)

    lines: List[str] = [
        "language: PTN",
        f"module: {module}",
        f"version: {version}",
        f"owner: {owner_slug}",
        "context: intent_compiled",
        f"privacy_profile: {default_profile}",
        "",
        "role owner {",
        '  label: "Primary Account Owner"',
        "  level: 10",
        "}",
        "",
        "role beneficiary {",
        '  label: "Registered Beneficiary"',
        "  level: 2",
        "}",
        "",
        "role system_scheduler {",
        '  label: "Automated Trigger Scheduler"',
        "  level: 9",
        "}",
        "",
        "authority owner {",
        "  allow: upsert_recovery_item, delete_recovery_item, ack_alive_check",
        "  allow: trigger_self_recovery_delivery",
        "  require mfa for trigger_self_recovery_delivery",
        "}",
        "",
        "authority beneficiary {",
        "  allow: read_legacy_delivery",
        "  deny: upsert_recovery_item, delete_recovery_item",
        "}",
        "",
        "authority system_scheduler {",
        "  allow: trigger_self_recovery_delivery, trigger_legacy_delivery",
    ]

    constraint_lines: List[str] = []
    policy_blocks: List[List[str]] = []

    global_safeguards = intent.get("global_safeguards") or {}
    if global_safeguards.get("require_multisignal_before_release", False):
        lines.append(
            _require_line(
                "multisignal_recent",
                "trigger_legacy_delivery",
                "high",
                "advisory",
                "global_multisignal_guard",
                "safety-core",
            ),
        )
    if global_safeguards.get("require_guardian_approval_for_legacy", False):
        lines.append(
            _require_line(
                "guardian_approval",
                "trigger_legacy_delivery",
                "high",
                "strict",
                "global_guardian_requirement",
                "safety-core",
            ),
        )
    if global_safeguards.get("server_heartbeat_fallback_enabled", True):
        lines.append(
            _require_line(
                "server_heartbeat_fallback",
                "trigger_legacy_delivery",
                "medium",
                "advisory",
                "global_server_heartbeat_fallback",
                "runtime-core",
            ),
        )
    lines.append("}")
    lines.append("")

    for entry in intent["entries"]:
        if entry.get("status") != "active":
            continue

        entry_id = _slug(entry["entry_id"])
        kind = entry["kind"]
        asset = entry["asset"]
        recipient = entry["recipient"]
        trigger = entry["trigger"]
        delivery = entry["delivery"]
        safeguards = entry["safeguards"]
        privacy = entry.get("privacy") or {}
        profile = privacy.get("profile", default_profile)

        action = "trigger_legacy_delivery" if kind == "legacy_delivery" else "trigger_self_recovery_delivery"
        event = "send_legacy_secure_link" if kind == "legacy_delivery" else "send_self_recovery_secure_link"
        if delivery["method"] == "notification_only":
            event = "send_notification_only"
        elif delivery["method"] == "self_recovery_route":
            event = "send_self_recovery_route"

        if delivery.get("require_verification_code", False):
            constraint_lines.append(
                _require_line(
                    "verification_code",
                    action,
                    "high",
                    "strict",
                    f"entry:{entry_id}:delivery",
                    "delivery-core",
                ),
            )
        if delivery.get("require_totp", False):
            constraint_lines.append(
                _require_line(
                    "totp_factor",
                    action,
                    "high",
                    "strict",
                    f"entry:{entry_id}:delivery",
                    "delivery-core",
                ),
            )
        if safeguards.get("legal_disclaimer_required", False):
            constraint_lines.append(
                _require_line(
                    "consent_active",
                    action,
                    "high",
                    "strict",
                    f"entry:{entry_id}:safeguards",
                    "privacy-core",
                ),
            )
        if safeguards.get("require_multisignal", False) and not global_safeguards.get(
            "require_multisignal_before_release",
            False,
        ):
            constraint_lines.append(
                _require_line(
                    "multisignal_recent",
                    action,
                    "high",
                    "advisory",
                    f"entry:{entry_id}:safeguards",
                    "safety-core",
                ),
            )
        if safeguards.get("require_guardian_approval", False):
            constraint_lines.append(
                _require_line(
                    "guardian_approval",
                    action,
                    "high",
                    "strict",
                    f"entry:{entry_id}:safeguards",
                    "safety-core",
                ),
            )
        cooldown_hours = safeguards.get("cooldown_hours")
        if isinstance(cooldown_hours, int) and cooldown_hours > 0:
            constraint_lines.append(
                _require_line(
                    f"cooldown_{cooldown_hours}h",
                    action,
                    "medium",
                    "strict",
                    f"entry:{entry_id}:safeguards",
                    "safety-core",
                ),
            )

        recipient_fallbacks = (recipient.get("fallback_channels") or [])
        if kind == "legacy_delivery":
            constraint_lines.append(
                _require_line(
                    "beneficiary_identity_match",
                    action,
                    "high",
                    "strict",
                    f"entry:{entry_id}:beneficiary_identity",
                    "delivery-core",
                ),
            )
            if len(set(recipient_fallbacks)) >= 2:
                constraint_lines.append(
                    _require_line(
                        "fallback_channels_ready",
                        action,
                        "medium",
                        "advisory",
                        f"entry:{entry_id}:recipient_fallbacks",
                        "delivery-core",
                    ),
                )

        policy_block = [
            f"policy {entry_id}_policy {{",
            f'  when action == "{action}"',
            f'  and intent.entry_id == "{_quote(entry["entry_id"])}"',
            f"  and profile.inactive_days >= {trigger['inactivity_days']}",
        ]
        if trigger.get("require_unconfirmed_alive_status", False):
            policy_block.append("  and profile.last_alive_check_confirmed == false")
        policy_block.extend(
            [
                f"  then {event}",
                "  and append_audit_log",
                f'  and set_privacy_profile_{profile.replace("-", "_")}',
                f'  and route_to_{_slug(recipient["recipient_id"])}',
                f'  and label_asset_{_slug(asset["asset_id"])}',
                "}",
                "",
            ],
        )
        policy_blocks.append(policy_block)

    if constraint_lines:
        lines.extend(["constraint compiled_intent_safeguards {"])
        deduped = []
        seen = set()
        for line in constraint_lines:
            if line in seen:
                continue
            seen.add(line)
            deduped.append(line)
        lines.extend(deduped)
        lines.extend(["}", ""])

    if not policy_blocks:
        raise IntentCompilerError("intent has no active entries to compile")

    for block in policy_blocks:
        lines.extend(block)

    return "\n".join(lines).strip() + "\n"


def compile_intent_document_with_trace(intent: Dict[str, Any]) -> Dict[str, Any]:
    compiled = compile_intent_document(intent)
    warnings = collect_intent_warnings(intent)
    report = build_intent_compiler_report(intent)
    active_entries = [entry for entry in intent["entries"] if entry.get("status") == "active"]
    entry_map = {
        entry["entry_id"]: {
            "policy_block_id": f"{_slug(entry['entry_id'])}_policy",
            "action": "trigger_legacy_delivery"
            if entry["kind"] == "legacy_delivery"
            else "trigger_self_recovery_delivery",
            "privacy_profile": (entry.get("privacy") or {}).get(
                "profile",
                intent.get("default_privacy_profile", "minimal"),
            ),
        }
        for entry in active_entries
    }
    return {
        "contract_version": COMPILER_CONTRACT_VERSION,
        "ptn": compiled,
        "trace": {
            "intent_id": intent["intent_id"],
            "owner_ref": intent["owner_ref"],
            "entries": entry_map,
        },
        "report": report,
        "warnings": warnings,
    }


def build_intent_canonical_artifact(intent: Dict[str, Any], generated_at: str) -> Dict[str, Any]:
    compiled = compile_intent_document_with_trace(intent)
    return {
        "contract_version": COMPILER_CONTRACT_VERSION,
        "intent_id": intent["intent_id"],
        "owner_ref": intent["owner_ref"],
        "generated_at": generated_at,
        "ptn": compiled["ptn"],
        "trace": compiled["trace"],
        "report": compiled["report"],
    }
