from pathlib import Path
import sys


ROOT = Path(__file__).resolve().parents[2]
TOOLS = ROOT / "tools"
if str(TOOLS) not in sys.path:
    sys.path.insert(0, str(TOOLS))

from ptn_parser import parse_ptn, validate_ptn  # noqa: E402


def test_high_assurance_v2_policy_is_valid() -> None:
    source = (ROOT / "examples" / "high-assurance-v2-policy.ptn").read_text(encoding="utf-8")
    doc = parse_ptn(source)
    issues = validate_ptn(doc)
    assert issues == []


def test_invalid_v2_risk_value_is_reported() -> None:
    source = """
language: PTN
module: demo
version: 2.0.0
owner: core

role system_scheduler {
  label: "Scheduler"
}

authority system_scheduler {
  allow: trigger_legacy_delivery
  require consent_active[risk=severe, mode=strict] for trigger_legacy_delivery
}

policy p {
  when action == "trigger_legacy_delivery"
  then send
}
"""
    issues = validate_ptn(parse_ptn(source))
    assert any("unsupported risk value 'severe'" in issue for issue in issues)


def test_unsupported_v2_metadata_key_is_reported() -> None:
    source = """
language: PTN
module: demo
version: 2.0.0
owner: core

role system_scheduler {
  label: "Scheduler"
}

authority system_scheduler {
  allow: trigger_legacy_delivery
  require consent_active[risk=high, mode=strict, foo=bar] for trigger_legacy_delivery
}

policy p {
  when action == "trigger_legacy_delivery"
  then send
}
"""
    issues = validate_ptn(parse_ptn(source))
    assert any("unsupported require metadata key 'foo'" in issue for issue in issues)
