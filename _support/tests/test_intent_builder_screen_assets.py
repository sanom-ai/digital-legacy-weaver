from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]


def _read(path: Path) -> str:
    return path.read_text(encoding="utf-8")


def test_intent_builder_screen_assets_exist() -> None:
    screen = ROOT / "apps" / "flutter_app" / "lib" / "features" / "intent_builder" / "intent_builder_screen.dart"
    dashboard = ROOT / "apps" / "flutter_app" / "lib" / "features" / "dashboard" / "dashboard_screen.dart"
    assert screen.exists()
    assert dashboard.exists()

    screen_src = _read(screen)
    dashboard_src = _read(dashboard)

    assert "class IntentBuilderScreen" in screen_src
    assert "User-defined legacy intent" in screen_src
    assert "Add draft entry" in screen_src
    assert "Compiler bridge" in screen_src
    assert "Intent Builder" in dashboard_src
    assert "Draft user-defined legacy intent before compiling it into PTN" in dashboard_src
