from __future__ import annotations

import json
from pathlib import Path
import sys


ROOT = Path(__file__).resolve().parents[2]
TOOLS = ROOT / "tools"
if str(TOOLS) not in sys.path:
    sys.path.insert(0, str(TOOLS))

from intent_to_ptn import (  # noqa: E402
    COMPILER_CONTRACT_VERSION,
    IntentCompilerError,
    build_intent_compiler_report,
    build_intent_canonical_artifact,
    collect_intent_warnings,
    compile_intent_document,
    compile_intent_document_with_trace,
    validate_intent_document,
)
from ptn_parser import parse_ptn, validate_ptn  # noqa: E402


def test_example_intent_compiles_to_valid_ptn() -> None:
    intent = json.loads((ROOT / "examples" / "intent-primary.json").read_text(encoding="utf-8"))
    compiled = compile_intent_document(intent)
    doc = parse_ptn(compiled)
    issues = validate_ptn(doc)
    assert issues == []
    assert "policy legacy_wallet_a_policy {" in compiled
    assert 'and intent.entry_id == "legacy_wallet_a"' in compiled
    assert "evidence=entry:legacy_wallet_a:delivery" in compiled
    assert "owner=delivery-core" in compiled


def test_compiler_rejects_invalid_delivery_method() -> None:
    intent = {
        "intent_id": "intent_primary",
        "version": "0.1.0",
        "owner_ref": "owner_primary",
        "default_privacy_profile": "minimal",
        "entries": [
            {
                "entry_id": "bad_entry",
                "kind": "legacy_delivery",
                "asset": {"asset_id": "asset_1", "display_name": "Asset"},
                "recipient": {"recipient_id": "r1", "destination_ref": "a@example.com"},
                "trigger": {"inactivity_days": 90},
                "delivery": {"method": "plaintext_email"},
                "safeguards": {},
                "privacy": {"profile": "minimal"},
                "status": "active",
            }
        ],
    }
    issues = validate_intent_document(intent)
    assert any("unsupported delivery.method 'plaintext_email'" in issue for issue in issues)
    try:
        compile_intent_document(intent)
    except IntentCompilerError as exc:
        assert "plaintext_email" in str(exc)
    else:
        raise AssertionError("Expected compiler to reject invalid delivery method")


def test_compiler_skips_draft_entries_and_requires_active_output() -> None:
    intent = json.loads((ROOT / "examples" / "intent-primary.json").read_text(encoding="utf-8"))
    intent["entries"][0]["status"] = "draft"
    try:
        compile_intent_document(intent)
    except IntentCompilerError as exc:
        assert "no active entries" in str(exc)
    else:
        raise AssertionError("Expected compiler to fail when no active entries exist")


def test_compiler_can_emit_trace_mapping() -> None:
    intent = json.loads((ROOT / "examples" / "intent-primary.json").read_text(encoding="utf-8"))
    result = compile_intent_document_with_trace(intent)
    assert "ptn" in result
    assert "trace" in result
    assert "report" in result
    assert "warnings" in result
    assert result["contract_version"] == COMPILER_CONTRACT_VERSION
    assert result["trace"]["intent_id"] == "intent_primary"
    assert result["trace"]["entries"]["legacy_wallet_a"]["policy_block_id"] == "legacy_wallet_a_policy"
    assert result["report"]["ok"] is True


def test_compiler_can_emit_canonical_artifact_bundle() -> None:
    intent = json.loads((ROOT / "examples" / "intent-primary.json").read_text(encoding="utf-8"))
    artifact = build_intent_canonical_artifact(intent, generated_at="2026-04-05T00:00:00Z")
    assert artifact["contract_version"] == COMPILER_CONTRACT_VERSION
    assert artifact["intent_id"] == "intent_primary"
    assert artifact["owner_ref"] == "owner_primary"
    assert artifact["generated_at"] == "2026-04-05T00:00:00Z"
    assert artifact["trace"]["entries"]["legacy_wallet_a"]["policy_block_id"] == "legacy_wallet_a_policy"
    assert artifact["report"]["ok"] is True


def test_compiler_collects_soft_warnings_for_core_only_entry() -> None:
    intent = json.loads((ROOT / "examples" / "intent-primary.json").read_text(encoding="utf-8"))
    intent["entries"][0]["asset"]["payload_ref"] = ""
    intent["entries"][0]["partner_path"] = None
    intent["entries"][0]["safeguards"]["require_multisignal"] = False
    intent["global_safeguards"]["require_multisignal_before_release"] = False
    warnings = collect_intent_warnings(intent)
    assert any("asset.payload_ref is empty" in warning for warning in warnings)
    assert any("no partner_path defined" in warning for warning in warnings)
    assert any("no multisignal safeguard configured" in warning for warning in warnings)


def test_compiler_report_has_severity_ranked_issues() -> None:
    intent = json.loads((ROOT / "examples" / "intent-primary.json").read_text(encoding="utf-8"))
    intent["entries"][0]["asset"]["payload_ref"] = ""
    intent["entries"][0]["partner_path"] = None
    report = build_intent_compiler_report(intent)
    assert report["ok"] is True
    assert report["error_count"] == 0
    assert report["warning_count"] >= 2
    codes = {issue["code"] for issue in report["issues"]}
    severities = {issue["severity"] for issue in report["issues"]}
    assert "missing_payload_ref" in codes
    assert "missing_partner_path" in codes
    assert severities == {"warning"}


def test_compiler_report_marks_validation_failures_as_errors() -> None:
    intent = {
        "intent_id": "intent_primary",
        "version": "0.1.0",
        "owner_ref": "owner_primary",
        "default_privacy_profile": "minimal",
        "entries": [
            {
                "entry_id": "bad_entry",
                "kind": "legacy_delivery",
                "asset": {"asset_id": "asset_1", "display_name": "Asset"},
                "recipient": {"recipient_id": "r1", "destination_ref": "a@example.com"},
                "trigger": {"inactivity_days": 0},
                "delivery": {"method": "secure_link"},
                "safeguards": {},
                "privacy": {"profile": "minimal"},
                "status": "active",
            }
        ],
    }
    report = build_intent_compiler_report(intent)
    assert report["ok"] is False
    assert report["error_count"] >= 1
    assert any(issue["severity"] == "error" for issue in report["issues"])
