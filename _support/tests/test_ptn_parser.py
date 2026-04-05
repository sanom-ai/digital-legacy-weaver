from pathlib import Path
import sys


ROOT = Path(__file__).resolve().parents[2]
TOOLS = ROOT / "tools"
if str(TOOLS) not in sys.path:
    sys.path.insert(0, str(TOOLS))

from ptn_parser import parse_ptn, validate_ptn  # noqa: E402


def test_default_policy_is_valid() -> None:
    source = (ROOT / "examples" / "default-policy.ptn").read_text(encoding="utf-8")
    doc = parse_ptn(source)
    issues = validate_ptn(doc)
    assert issues == []


def test_pdpa_policy_pack_is_valid() -> None:
    source = (ROOT / "examples" / "pdpa-policy-pack.ptn").read_text(encoding="utf-8")
    doc = parse_ptn(source)
    issues = validate_ptn(doc)
    assert issues == []


def test_missing_required_headers_is_reported() -> None:
    source = """
module: digital_legacy_weaver
version: 1.0.0
owner: test-owner

role owner {
  label: "Owner"
}

authority owner {
  allow: trigger_self_recovery_delivery
}

policy p {
  when action == "trigger_self_recovery_delivery"
  then send
}
"""
    doc = parse_ptn(source)
    issues = validate_ptn(doc)
    assert any("missing required headers" in issue for issue in issues)
