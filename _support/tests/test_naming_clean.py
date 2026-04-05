from pathlib import Path
import sys


ROOT = Path(__file__).resolve().parents[2]
TOOLS = ROOT / "tools"
if str(TOOLS) not in sys.path:
    sys.path.insert(0, str(TOOLS))

from check_naming_clean import find_issues  # noqa: E402


def test_find_issues_detects_blocked_terms(tmp_path: Path) -> None:
    blocked_name = "token" + "_id"
    (tmp_path / "bad.txt").write_text(f"{blocked_name}=abc", encoding="utf-8")
    issues = find_issues(tmp_path)
    assert issues
    assert "blocked term" in issues[0]


def test_find_issues_passes_clean_content(tmp_path: Path) -> None:
    (tmp_path / "ok.txt").write_text("access_id=abc access_key=def", encoding="utf-8")
    issues = find_issues(tmp_path)
    assert issues == []
