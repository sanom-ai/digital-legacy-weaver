from __future__ import annotations

import json
from pathlib import Path
import sys


ROOT = Path(__file__).resolve().parents[2]
TOOLS = ROOT / "tools"
if str(TOOLS) not in sys.path:
    sys.path.insert(0, str(TOOLS))

from intent_to_ptn import (  # noqa: E402
    IntentCompilerError,
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
    assert result["trace"]["intent_id"] == "intent_primary"
    assert result["trace"]["entries"]["legacy_wallet_a"]["policy_block_id"] == "legacy_wallet_a_policy"
