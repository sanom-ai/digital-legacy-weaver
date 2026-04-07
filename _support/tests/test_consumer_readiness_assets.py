from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]


def _read(path: Path) -> str:
    return path.read_text(encoding="utf-8")


def _assert_contains_any(src: str, choices: list[str]) -> None:
    assert any(choice in src for choice in choices), f"Expected one of {choices!r}"


def test_onboarding_setup_screen_exists_with_setup_copy() -> None:
    path = ROOT / "apps" / "flutter_app" / "lib" / "features" / "onboarding" / "onboarding_setup_screen.dart"
    assert path.exists()
    src = _read(path)
    _assert_contains_any(src, ["Finish Setup", "ตั้งค่าเริ่มต้น"])
    _assert_contains_any(src, ["I understand legal companion mode", "ฉันเข้าใจขอบเขตทางกฎหมายของแอป"])
    _assert_contains_any(src, ["Setup complete. Your private-first defaults are now active.", "ตั้งค่าเสร็จแล้ว ระบบพร้อมใช้งานในโหมดความเป็นส่วนตัวสูงสุด"])


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
    _assert_contains_any(src, ["Beta Feedback", "ส่งความคิดเห็น"])
    _assert_contains_any(src, ["Submit feedback", "ส่งความคิดเห็น"])
    _assert_contains_any(src, ["Feedback submitted. Thank you.", "ส่งความคิดเห็นเรียบร้อยแล้ว ขอบคุณมาก"])
