from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
SECURITY = ROOT / "SECURITY.md"
CONTRIBUTING = ROOT / "CONTRIBUTING.md"
CODEOWNERS = ROOT / ".github" / "CODEOWNERS"
TESTING_STRATEGY = ROOT / "docs" / "testing-strategy.md"
POSITIONING_GUIDE = ROOT / "docs" / "positioning-audience-guide.md"


def _read(path: Path) -> str:
    return path.read_text(encoding="utf-8")


def test_security_policy_contains_private_channel_and_sla() -> None:
    src = _read(SECURITY)
    assert "security@legacyweaver.app" in src
    assert "Acknowledgment: within 72 hours" in src
    assert "Critical: 7 days" in src
    assert "Safe harbor" in src


def test_contributing_includes_testing_matrix_and_release_flow() -> None:
    src = _read(CONTRIBUTING)
    assert "Testing matrix expectations" in src
    assert "Required checks before merge" in src
    assert "Release process (summary)" in src
    assert "docs/testing-strategy.md" in src


def test_codeowners_covers_security_critical_paths() -> None:
    src = _read(CODEOWNERS)
    assert "/supabase/functions/" in src
    assert "/supabase/migrations/" in src
    assert "/SECURITY.md" in src
    assert "/scripts/deploy_production.ps1" in src


def test_testing_strategy_declares_current_gaps_and_stable_gate() -> None:
    src = _read(TESTING_STRATEGY)
    assert "Current gaps to close" in src
    assert "Stable gate proposal" in src
    assert "14 consecutive days of green scheduled reliability drills" in src


def test_positioning_guide_exists_with_audience_sections() -> None:
    src = _read(POSITIONING_GUIDE)
    assert "Developer audience" in src
    assert "Partner / operations audience" in src
    assert "Investor / strategic audience" in src
