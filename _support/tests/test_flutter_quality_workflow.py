from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
WORKFLOW = ROOT / ".github" / "workflows" / "flutter-quality.yml"


def _read(path: Path) -> str:
    return path.read_text(encoding="utf-8")


def test_flutter_quality_workflow_exists() -> None:
    assert WORKFLOW.exists()


def test_flutter_quality_workflow_runs_analyze_and_test() -> None:
    src = _read(WORKFLOW)
    assert "subosito/flutter-action@v2" in src
    assert "flutter pub get" in src
    assert "flutter analyze" in src
    assert "flutter test" in src
