import fnmatch
import subprocess
import sys


REQUIRED_IGNORED_PATHS = [
    "apps/flutter_app/.dart_tool/",
    "apps/flutter_app/build/",
    "apps/flutter_app/.flutter-plugins",
    "apps/flutter_app/.flutter-plugins-dependencies",
    "apps/flutter_app/.packages",
]

FORBIDDEN_TRACKED_PATTERNS = [
    "apps/flutter_app/.dart_tool/*",
    "apps/flutter_app/build/*",
    "apps/flutter_app/.flutter-plugins",
    "apps/flutter_app/.flutter-plugins-dependencies",
    "apps/flutter_app/.packages",
]


def _run(cmd: list[str]) -> subprocess.CompletedProcess[str]:
    return subprocess.run(cmd, text=True, capture_output=True, check=False)


def main() -> int:
    ok = True

    for path in REQUIRED_IGNORED_PATHS:
        result = _run(["git", "check-ignore", "-q", path])
        if result.returncode != 0:
            print(f"[FAIL] Missing ignore rule for: {path}")
            ok = False

    tracked = _run(["git", "ls-files"])
    if tracked.returncode != 0:
        print(f"[FAIL] Could not list tracked files: {tracked.stderr.strip()}")
        return 1

    tracked_files = [line.strip() for line in tracked.stdout.splitlines() if line.strip()]
    for pattern in FORBIDDEN_TRACKED_PATTERNS:
        matches = [path for path in tracked_files if fnmatch.fnmatch(path, pattern)]
        if matches:
            ok = False
            print(f"[FAIL] Generated artifact is tracked ({pattern}):")
            for path in matches[:10]:
                print(f"  - {path}")

    if not ok:
        return 1

    print("[PASS] Repository hygiene check passed.")
    return 0


if __name__ == "__main__":
    sys.exit(main())

