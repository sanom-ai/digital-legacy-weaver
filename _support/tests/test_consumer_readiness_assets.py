from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]


def _read(path: Path) -> str:
    return path.read_text(encoding="utf-8")


def test_onboarding_setup_screen_exists_with_setup_copy() -> None:
    path = ROOT / "apps" / "flutter_app" / "lib" / "features" / "onboarding" / "onboarding_setup_screen.dart"
    assert path.exists()
    src = _read(path)
    assert "Complete Setup" in src
    assert "I understand legal companion mode" in src
    assert "Setup completed." in src


def test_hosted_mode_operations_doc_exists() -> None:
    path = ROOT / "docs" / "hosted-mode-operations.md"
    assert path.exists()
    src = _read(path)
    assert "Hosted mode definition" in src
    assert "technical coordination layer" in src


def test_beta_feedback_screen_exists_with_submit_copy() -> None:
    path = ROOT / "apps" / "flutter_app" / "lib" / "features" / "beta" / "beta_feedback_screen.dart"
    assert path.exists()
    src = _read(path)
    assert "Beta Feedback" in src
    assert "Submit feedback" in src
    assert "Feedback submitted. Thank you." in src
