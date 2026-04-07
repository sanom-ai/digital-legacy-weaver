from __future__ import annotations

import argparse
import re
import subprocess
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]

TEXT_FILE_SUFFIXES = {
    ".dart",
    ".py",
    ".md",
    ".txt",
    ".json",
    ".yaml",
    ".yml",
    ".toml",
    ".ps1",
    ".sh",
    ".js",
    ".ts",
    ".html",
    ".css",
    ".svg",
    ".xml",
}

SUSPICIOUS_MOJIBAKE_PATTERNS = [
    re.compile(r"Ã Â¸"),
    re.compile(r"Ã Â¹"),
    re.compile(r"Ãƒ."),
    re.compile(r"Ã‚."),
    re.compile(r"Ã¢â‚¬[^\s]?"),
    re.compile(r"Ã°Å¸"),
]

EXCLUDED_PATHS = {
    "tools/check_text_encoding_hygiene.py",
}


def _git_tracked_files() -> list[Path]:
    result = subprocess.run(
        ["git", "ls-files"],
        cwd=ROOT,
        text=True,
        capture_output=True,
        check=False,
    )
    if result.returncode != 0:
        raise RuntimeError(f"Unable to list tracked files: {result.stderr.strip()}")
    tracked = []
    for line in result.stdout.splitlines():
        rel = line.strip()
        if not rel:
            continue
        tracked.append(ROOT / rel)
    return tracked


def _is_text_candidate(path: Path) -> bool:
    return path.suffix.lower() in TEXT_FILE_SUFFIXES


def _scan_file(path: Path) -> list[str]:
    rel = path.relative_to(ROOT).as_posix()
    if rel in EXCLUDED_PATHS:
        return []

    raw = path.read_bytes()
    issues: list[str] = []
    try:
        text = raw.decode("utf-8")
    except UnicodeDecodeError as exc:
        issues.append(f"{rel}: not valid UTF-8 ({exc})")
        return issues

    if "\uFFFD" in text:
        issues.append(f"{rel}: contains replacement character (� / U+FFFD)")

    for pattern in SUSPICIOUS_MOJIBAKE_PATTERNS:
        if pattern.search(text):
            issues.append(f"{rel}: contains suspicious mojibake pattern `{pattern.pattern}`")
            break
    return issues


def run_check() -> list[str]:
    issues: list[str] = []
    for path in _git_tracked_files():
        if not path.exists() or not _is_text_candidate(path):
            continue
        issues.extend(_scan_file(path))
    return issues


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Fail when tracked text files are not UTF-8 or contain mojibake artifacts."
    )
    parser.parse_args()

    issues = run_check()
    if issues:
        print("[FAIL] Text encoding hygiene check failed:")
        for issue in issues:
            print(f"- {issue}")
        return 1

    print("[PASS] Text encoding hygiene check passed.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
