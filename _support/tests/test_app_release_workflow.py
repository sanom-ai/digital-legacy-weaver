from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
WORKFLOW = ROOT / ".github" / "workflows" / "app-release.yml"
DOC = ROOT / "docs" / "app-release-pack.md"
RELEASE_TEMPLATE = ROOT / "docs" / "releases" / "v0.1.0-release-notes-template.md"
RELEASE_PREFLIGHT = ROOT / "tools" / "release_gate_preflight.py"


def _read(path: Path) -> str:
    return path.read_text(encoding="utf-8")


def test_app_release_workflow_exists() -> None:
    assert WORKFLOW.exists()


def test_app_release_workflow_builds_android_and_windows_and_publishes_release() -> None:
    src = _read(WORKFLOW)
    assert "subosito/flutter-action@v2" in src
    assert "flutter build apk --release" in src
    assert "flutter build windows --release" in src
    assert "softprops/action-gh-release@v2" in src
    assert "app-release.apk" in src
    assert "digital-legacy-weaver-windows.zip" in src
    assert "release_gate_preflight.py" in src


def test_app_release_pack_doc_exists() -> None:
    assert DOC.exists()
    src = _read(DOC)
    assert "App Release Pack" in src
    assert "app-release.yml" in src


def test_release_notes_template_exists_with_download_links() -> None:
    assert RELEASE_TEMPLATE.exists()
    src = _read(RELEASE_TEMPLATE)
    assert "Android APK" in src
    assert "Windows ZIP" in src
    assert "technical coordination layer" in src


def test_release_preflight_script_exists_with_backup_and_drill_requirements() -> None:
    assert RELEASE_PREFLIGHT.exists()
    src = _read(RELEASE_PREFLIGHT)
    assert "backup-restore-smoke-*.md" in src
    assert "safety-control-drill-*.md" in src
    assert "Result must be PASS" in src
