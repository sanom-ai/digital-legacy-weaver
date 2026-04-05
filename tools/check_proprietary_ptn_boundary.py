from __future__ import annotations

from pathlib import Path
import sys


ROOT = Path(__file__).resolve().parents[1]
PRIVATE_LEGACY_DIR = ROOT / "ptn" / "legacy" / "private"

ALLOWED_STUB_FILENAMES = {
    ".gitkeep",
    "README.md",
}


def run_check() -> list[str]:
    issues: list[str] = []

    if not PRIVATE_LEGACY_DIR.exists():
        return issues

    for path in PRIVATE_LEGACY_DIR.rglob("*"):
        if not path.is_file():
            continue
        if path.name in ALLOWED_STUB_FILENAMES:
            continue
        if path.suffix.lower() == ".ptn":
            rel = path.relative_to(ROOT)
            issues.append(
                f"{rel}: proprietary PTN file detected in public repository boundary",
            )
            continue
        rel = path.relative_to(ROOT)
        issues.append(
            f"{rel}: unexpected file in proprietary boundary path",
        )

    return issues


def main() -> int:
    issues = run_check()
    if issues:
        print("[FAIL] Proprietary PTN boundary check failed:")
        for issue in issues:
            print(f" - {issue}")
        return 1
    print("[PASS] Proprietary PTN boundary check passed.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
