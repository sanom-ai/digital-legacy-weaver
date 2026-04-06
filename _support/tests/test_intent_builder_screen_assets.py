from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]


def _read(path: Path) -> str:
    return path.read_text(encoding="utf-8")


def test_intent_builder_core_assets_exist() -> None:
    screen = ROOT / "apps" / "flutter_app" / "lib" / "features" / "intent_builder" / "intent_builder_screen.dart"
    model = ROOT / "apps" / "flutter_app" / "lib" / "features" / "intent_builder" / "intent_builder_model.dart"
    report = ROOT / "apps" / "flutter_app" / "lib" / "features" / "intent_builder" / "intent_compiler_report_model.dart"
    review = ROOT / "apps" / "flutter_app" / "lib" / "features" / "intent_builder" / "intent_review_card.dart"
    history = ROOT / "apps" / "flutter_app" / "lib" / "features" / "intent_builder" / "intent_artifact_history_screen.dart"
    compare = ROOT / "apps" / "flutter_app" / "lib" / "features" / "intent_builder" / "intent_artifact_compare_screen.dart"
    artifact_review = ROOT / "apps" / "flutter_app" / "lib" / "features" / "intent_builder" / "intent_artifact_review_screen.dart"
    readiness_model = ROOT / "apps" / "flutter_app" / "lib" / "features" / "intent_builder" / "intent_runtime_readiness_model.dart"
    readiness_screen = ROOT / "apps" / "flutter_app" / "lib" / "features" / "intent_builder" / "intent_runtime_readiness_screen.dart"
    ptn_preview = ROOT / "apps" / "flutter_app" / "lib" / "features" / "intent_builder" / "intent_ptn_preview.dart"
    dashboard = ROOT / "apps" / "flutter_app" / "lib" / "features" / "dashboard" / "dashboard_screen.dart"

    for path in [
        screen,
        model,
        report,
        review,
        history,
        compare,
        artifact_review,
        readiness_model,
        readiness_screen,
        ptn_preview,
        dashboard,
    ]:
        assert path.exists(), f"Missing required asset: {path}"

    screen_src = _read(screen)
    model_src = _read(model)
    report_src = _read(report)
    review_src = _read(review)
    history_src = _read(history)
    compare_src = _read(compare)
    artifact_review_src = _read(artifact_review)
    readiness_model_src = _read(readiness_model)
    readiness_screen_src = _read(readiness_screen)
    ptn_preview_src = _read(ptn_preview)
    dashboard_src = _read(dashboard)

    # Intent Builder product surface
    assert "class IntentBuilderScreen" in screen_src
    assert "_addDraftEntry" in screen_src
    assert "_exportCanonicalArtifact" in screen_src
    assert "_statePolicyMessage" in screen_src
    assert "Add route" in screen_src
    assert "Edit route details" in screen_src
    assert "Export current version" in screen_src
    assert "Policy preview" in screen_src
    assert "Version history:" in screen_src
    assert "Release status:" in screen_src

    # Intent model and compiler signals
    assert "IntentDocumentModel" in model_src
    assert "IntentEntryModel" in model_src
    assert "guardian_quorum_enabled" in model_src
    assert "emergency_access_requires_beneficiary_request" in model_src
    assert "device_rebind_in_progress" in model_src

    assert "class IntentCompilerReportModel" in report_src
    assert "missing_beneficiary_identity" in report_src
    assert "server_heartbeat_fallback_disabled" in report_src
    assert "guardian_quorum_invalid" in report_src
    assert "emergency_access_without_beneficiary_request" in report_src

    # Supporting screens still wired
    assert "class IntentReviewCard" in review_src
    assert "Intent check" in review_src
    assert "class IntentArtifactHistoryScreen" in history_src
    assert "Exported Version History" in history_src
    assert "class IntentArtifactCompareScreen" in compare_src
    assert "Exported Version Compare" in compare_src
    assert "class IntentArtifactReviewScreen" in artifact_review_src
    assert "Exported Version Review" in artifact_review_src

    # Readiness flow
    assert "class IntentRuntimeReadinessModel" in readiness_model_src
    assert "Ready for release" in readiness_model_src
    assert "Needs attention" in readiness_model_src
    assert "class IntentRuntimeReadinessScreen" in readiness_screen_src
    assert "Release Readiness" in readiness_screen_src

    # PTN preview and dashboard integration
    assert "String buildDraftIntentPtnPreview" in ptn_preview_src
    assert "language: PTN" in ptn_preview_src
    assert "Control room" in dashboard_src
    assert "Runtime readiness" in dashboard_src
