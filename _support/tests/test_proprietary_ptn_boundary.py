from pathlib import Path
import sys


ROOT = Path(__file__).resolve().parents[2]
TOOLS = ROOT / "tools"
if str(TOOLS) not in sys.path:
    sys.path.insert(0, str(TOOLS))

from check_proprietary_ptn_boundary import run_check  # noqa: E402


def test_proprietary_ptn_boundary_passes() -> None:
    issues = run_check()
    assert issues == []
