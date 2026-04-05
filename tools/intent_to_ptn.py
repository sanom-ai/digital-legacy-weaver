from __future__ import annotations

from typing import Any, Dict, List


PRIVACY_PROFILE_ALLOWED = {"confidential", "minimal", "audit-heavy"}
ENTRY_KIND_ALLOWED = {"legacy_delivery", "self_recovery"}
DELIVERY_METHOD_ALLOWED = {"secure_link", "notification_only", "self_recovery_route"}
STATUS_ALLOWED = {"draft", "active", "paused", "archived"}


class IntentCompilerError(Exception):
    pass


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
            "  require multisignal_recent[risk=high, mode=advisory, owner=safety-core] for trigger_legacy_delivery",
        )
    if global_safeguards.get("require_guardian_approval_for_legacy", False):
        lines.append(
            "  require guardian_approval[risk=high, mode=strict, owner=safety-core] for trigger_legacy_delivery",
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
                f"  require verification_code[risk=high, mode=strict, owner=delivery-core] for {action}",
            )
        if delivery.get("require_totp", False):
            constraint_lines.append(
                f"  require totp_factor[risk=high, mode=strict, owner=delivery-core] for {action}",
            )
        if safeguards.get("legal_disclaimer_required", False):
            constraint_lines.append(
                f"  require consent_active[risk=high, mode=strict, owner=privacy-core] for {action}",
            )
        if safeguards.get("require_multisignal", False) and not global_safeguards.get(
            "require_multisignal_before_release",
            False,
        ):
            constraint_lines.append(
                f"  require multisignal_recent[risk=high, mode=advisory, owner=safety-core] for {action}",
            )
        if safeguards.get("require_guardian_approval", False):
            constraint_lines.append(
                f"  require guardian_approval[risk=high, mode=strict, owner=safety-core] for {action}",
            )
        cooldown_hours = safeguards.get("cooldown_hours")
        if isinstance(cooldown_hours, int) and cooldown_hours > 0:
            constraint_lines.append(
                f"  require cooldown_{cooldown_hours}h[risk=medium, mode=strict, owner=safety-core] for {action}",
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
