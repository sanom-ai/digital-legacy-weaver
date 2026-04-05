from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]


def _read(path: Path) -> str:
    return path.read_text(encoding="utf-8")


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
    assert "class IntentReviewCard" in card_src
    assert "Intent review" in card_src
    assert "IntentReviewCard(report: draftReport)" in onboarding_src
