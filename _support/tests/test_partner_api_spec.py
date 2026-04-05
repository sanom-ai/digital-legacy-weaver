from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
SPEC = ROOT / "specs" / "partner-api.openapi.yaml"


def _src() -> str:
    return SPEC.read_text(encoding="utf-8")


def test_partner_api_spec_exists() -> None:
    assert SPEC.exists()


def test_partner_api_core_paths_present() -> None:
    src = _src()
    required_paths = [
        "/connectors/register:",
        "/assets/upsert:",
        "/release-events/ack:",
        "/verification-signals/legacy:",
        "/handoff-notices/legacy:",
        "/health:",
    ]
    for path_name in required_paths:
        assert path_name in src


def test_partner_api_uses_bearer_auth() -> None:
    src = _src()
    assert "securitySchemes:" in src
    assert "bearerAuth:" in src
    assert "scheme: bearer" in src


def test_partner_api_release_ack_status_enum_present() -> None:
    src = _src()
    assert "enum: [received, completed, failed]" in src


def test_partner_api_legacy_verification_schema_present() -> None:
    src = _src()
    assert "LegacyVerificationSignal:" in src
    assert "document_types_verified:" in src


def test_partner_api_handoff_notice_schema_present() -> None:
    src = _src()
    assert "LegacyHandoffNotice:" in src
    assert "handoff_disclaimer:" in src
