from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path
import sys
from typing import Iterable

from ptn_parser import PTNError, parse_ptn, validate_ptn


ROOT = Path(__file__).resolve().parents[1]


@dataclass(frozen=True)
class MappingCheck:
  path: Path
  required_terms: tuple[str, ...]


def _read(path: Path) -> str:
  return path.read_text(encoding="utf-8")


def _require_terms(path: Path, terms: Iterable[str]) -> list[str]:
  src = _read(path)
  missing = [term for term in terms if term not in src]
  return [f"{path}: missing '{term}'" for term in missing]


def run_check() -> list[str]:
  issues: list[str] = []

  ptn_path = ROOT / "examples" / "pdpa-policy-pack.ptn"
  try:
    doc = parse_ptn(_read(ptn_path))
    issues.extend(validate_ptn(doc))
  except (OSError, PTNError) as exc:
    issues.append(f"ptn parse failed: {exc}")
    return issues

  checks = [
    MappingCheck(
      path=ROOT / "supabase" / "functions" / "dispatch-trigger" / "index.ts",
      required_terms=(
        "Legal entitlement verification must be completed directly with the destination app/provider.",
      ),
    ),
    MappingCheck(
      path=ROOT / "examples" / "pdpa-policy-pack.ptn",
      required_terms=(
        "consent_active",
        "provider_legal_verification_handoff",
        "cooldown_24h",
      ),
    ),
    MappingCheck(
      path=ROOT / "docs" / "pdpa-policy-mapping.md",
      required_terms=(
        "technical layer",
        "provider_legal_verification_handoff",
        "destination app/provider",
      ),
    ),
    MappingCheck(
      path=ROOT / "scripts" / "run_maintenance_cleanup.ps1",
      required_terms=(
        "run_maintenance_cleanup",
      ),
    ),
    MappingCheck(
      path=ROOT / "docs" / "legal-companion-mode.md",
      required_terms=(
        "legal companion",
        "not a legal replacement",
        "does not collect legal evidence",
      ),
    ),
    MappingCheck(
      path=ROOT / "docs" / "legal-evidence-gate.md",
      required_terms=(
        "does **not** collect or adjudicate legal evidence",
        "must submit legal documents directly to destination apps/providers",
      ),
    ),
  ]

  for check in checks:
    if not check.path.exists():
      issues.append(f"missing required file: {check.path}")
      continue
    issues.extend(_require_terms(check.path, check.required_terms))

  return issues


def main() -> int:
  issues = run_check()
  if issues:
    print("[FAIL] PDPA control check failed:")
    for issue in issues:
      print(f" - {issue}")
    return 1
  print("[PASS] PDPA control check passed.")
  return 0


if __name__ == "__main__":
  raise SystemExit(main())
