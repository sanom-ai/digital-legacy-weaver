from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]


def _read(path: Path) -> str:
    return path.read_text(encoding="utf-8")


def test_integration_script_exists_with_unlock_flow_steps() -> None:
    path = ROOT / "scripts" / "run_integration_unlock_flow.ps1"
    assert path.exists()
    src = _read(path)
    assert "dispatch-trigger" in src
    assert "request_code" in src
    assert "unlock" in src
    assert "RequirePositiveUnlock" in src


def test_adversarial_script_exists_with_rate_limit_and_handoff_auth_checks() -> None:
    path = ROOT / "scripts" / "run_adversarial_unlock_checks.ps1"
    assert path.exists()
    src = _read(path)
    assert "Too many attempts" in src
    assert "handoff-notice" in src
    assert "401" in src


def test_e2e_test_pack_doc_exists_with_usage_examples() -> None:
    path = ROOT / "docs" / "e2e-test-pack.md"
    assert path.exists()
    src = _read(path)
    assert "run_integration_unlock_flow.ps1" in src
    assert "run_adversarial_unlock_checks.ps1" in src
    assert "technical coordination layer only" in src
