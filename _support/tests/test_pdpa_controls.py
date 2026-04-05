from pathlib import Path
import sys


ROOT = Path(__file__).resolve().parents[2]
TOOLS = ROOT / "tools"
if str(TOOLS) not in sys.path:
    sys.path.insert(0, str(TOOLS))

from pdpa_control_check import run_check  # noqa: E402


def test_pdpa_control_check_passes() -> None:
    issues = run_check()
    assert issues == []
