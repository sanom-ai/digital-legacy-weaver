from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]


def _read(path: Path) -> str:
    return path.read_text(encoding="utf-8")


def _assert_contains_any(src: str, choices: list[str]) -> None:
    assert any(choice in src for choice in choices), f"Expected one of {choices!r}"


def test_intent_review_card_assets_exist() -> None:
    model = ROOT / "apps" / "flutter_app" / "lib" / "features" / "intent_builder" / "intent_compiler_report_model.dart"
    card = ROOT / "apps" / "flutter_app" / "lib" / "features" / "intent_builder" / "intent_review_card.dart"
    onboarding = ROOT / "apps" / "flutter_app" / "lib" / "features" / "onboarding" / "onboarding_setup_screen.dart"
    assert model.exists()
    assert card.exists()
    assert onboarding.exists()

    model_src = _read(model)
    card_src = _read(card)
    onboarding_src = _read(onboarding)

    assert "class IntentCompilerReportModel" in model_src
    assert "buildDraftIntentCompilerReport" in model_src
    assert "IntentCompilerReportModel.fromMap" in model_src
    assert "IntentCompilerIssueModel.fromMap" in model_src
    assert '"error_count"' in model_src
    assert '"warning_count"' in model_src
    assert "class IntentReviewCard" in card_src
    assert "Intent check" in card_src
    assert "IntentReviewCard(report: draftReport)" in onboarding_src
    assert "_warningAcknowledged" in onboarding_src
    _assert_contains_any(
        onboarding_src,
        ["Resolve blocking intent review items before saving.", "กรุณาแก้รายการที่ติดบล็อกก่อนบันทึก"],
    )
    _assert_contains_any(
        onboarding_src,
        ["Acknowledge intent review warnings before saving.", "กรุณายืนยันว่าได้ตรวจคำเตือนแล้วก่อนบันทึก"],
    )
