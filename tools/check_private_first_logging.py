from __future__ import annotations

from pathlib import Path
import sys


ROOT = Path(__file__).resolve().parents[1]

TARGET_FILES = [
    ROOT / "supabase" / "functions" / "dispatch-trigger" / "index.ts",
    ROOT / "supabase" / "functions" / "open-delivery-link" / "index.ts",
    ROOT / "supabase" / "functions" / "manage-totp-factor" / "index.ts",
    ROOT / "supabase" / "functions" / "handoff-notice" / "index.ts",
]

BLOCKED_TERMS = (
    "seed phrase",
    "seed_phrase",
    "private_key",
    "private key",
    "mnemonic",
    "passphrase",
)


def run_check() -> list[str]:
    issues: list[str] = []
    for path in TARGET_FILES:
        if not path.exists():
            issues.append(f"missing required file: {path}")
            continue
        source = path.read_text(encoding="utf-8").lower()
        for term in BLOCKED_TERMS:
            if term in source:
                issues.append(f"{path.relative_to(ROOT)}: blocked logging term '{term}' detected")
    return issues


def main() -> int:
    issues = run_check()
    if issues:
      print("[FAIL] Private-first logging guard failed:")
      for issue in issues:
          print(f" - {issue}")
      return 1
    print("[PASS] Private-first logging guard passed.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
