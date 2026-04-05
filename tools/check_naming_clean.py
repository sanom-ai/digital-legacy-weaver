from __future__ import annotations

from pathlib import Path
import re
import sys


ROOT = Path(__file__).resolve().parents[1]

# Legacy terms that must not return after hard-cut migration.
BLOCKED_PATTERNS = [
    re.compile(r"\btoken_id\b"),
    re.compile(r"\btoken_hash\b"),
    re.compile(r"\bTokenId\b"),
    re.compile(r"\btoken\s*=\s*"),
]

# Skip heavy/binary or irrelevant paths.
SKIP_DIRS = {
    ".git",
    ".dart_tool",
    "build",
    "__pycache__",
}

SKIP_SUFFIXES = {
    ".png",
    ".jpg",
    ".jpeg",
    ".gif",
    ".pdf",
    ".zip",
    ".pack",
    ".idx",
    ".rev",
}


def should_skip(path: Path) -> bool:
    if any(part in SKIP_DIRS for part in path.parts):
        return True
    if path.suffix.lower() in SKIP_SUFFIXES:
        return True
    return False


def iter_text_files(root: Path):
    for path in root.rglob("*"):
        if not path.is_file():
            continue
        if should_skip(path):
            continue
        yield path


def find_issues(root: Path) -> list[str]:
    issues: list[str] = []
    for file_path in iter_text_files(root):
        try:
            content = file_path.read_text(encoding="utf-8")
        except Exception:
            continue

        for pattern in BLOCKED_PATTERNS:
            for match in pattern.finditer(content):
                rel = file_path.relative_to(root)
                issues.append(f"{rel}: blocked term '{match.group(0)}'")
    return issues


def main() -> int:
    issues = find_issues(ROOT)

    if issues:
        print("[FAIL] Naming cleanliness check failed:")
        for issue in issues:
            print(f" - {issue}")
        return 1

    print("[PASS] Naming cleanliness check passed.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
