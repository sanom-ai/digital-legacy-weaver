from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]


def _read(path: Path) -> str:
    return path.read_text(encoding="utf-8")


def test_intent_builder_screen_assets_exist() -> None:
    screen = ROOT / "apps" / "flutter_app" / "lib" / "features" / "intent_builder" / "intent_builder_screen.dart"
    preview = ROOT / "apps" / "flutter_app" / "lib" / "features" / "intent_builder" / "intent_ptn_preview.dart"
    dashboard = ROOT / "apps" / "flutter_app" / "lib" / "features" / "dashboard" / "dashboard_screen.dart"
    assert screen.exists()
    assert preview.exists()
    assert dashboard.exists()

    screen_src = _read(screen)
    preview_src = _read(preview)
    dashboard_src = _read(dashboard)

    assert "class IntentBuilderScreen" in screen_src
    assert "User-defined legacy intent" in screen_src
    assert "Add draft entry" in screen_src
    assert "Edit intent entry" in screen_src
    assert 'child: const Text("Edit")' in screen_src
    assert 'child: Text(entry.status == \'active\' ? "Move to draft" : "Activate")' in screen_src
    assert "DropdownButtonFormField<String>" in screen_src
    assert "Compiler bridge" in screen_src
    assert "buildDraftIntentPtnPreview" in screen_src
    assert "Draft canonical preview generated from the current intent document" in screen_src
    assert "String buildDraftIntentPtnPreview" in preview_src
    assert 'language: PTN' in preview_src
    assert 'policy ${_slug(entry.entryId)}_policy {' in preview_src
    assert "Intent Builder" in dashboard_src
    assert "Draft user-defined legacy intent before compiling it into PTN" in dashboard_src
