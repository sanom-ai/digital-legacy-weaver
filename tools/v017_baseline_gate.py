from __future__ import annotations

import argparse
import re
import subprocess
import sys
from dataclasses import dataclass
from datetime import datetime, timezone
from pathlib import Path
from typing import Iterable


ROOT = Path(__file__).resolve().parents[1]
DEFAULT_REPORT_DIR = ROOT / "ops" / "reports"
BASELINE_TAG = "v0.1.7"


@dataclass
class CheckResult:
    title: str
    ok: bool
    detail: str


def _run(
    args: list[str],
    *,
    cwd: Path | None = None,
) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        args,
        cwd=str(cwd or ROOT),
        capture_output=True,
        text=True,
        check=False,
    )


def _check_git_tag_exists(tag: str) -> CheckResult:
    proc = _run(["git", "tag", "--list", tag])
    if proc.returncode != 0:
        detail = proc.stderr.strip() or proc.stdout.strip() or "git tag lookup failed"
        return CheckResult("Baseline tag exists", False, detail)
    exists = bool(proc.stdout.strip())
    if not exists:
        return CheckResult("Baseline tag exists", False, f"Missing tag: {tag}")
    return CheckResult("Baseline tag exists", True, f"Found tag: {tag}")


def _check_required_paths(paths: Iterable[Path]) -> list[CheckResult]:
    results: list[CheckResult] = []
    for path in paths:
        rel = path.relative_to(ROOT)
        if path.exists():
            results.append(CheckResult(f"Required file: {rel}", True, "present"))
        else:
            results.append(CheckResult(f"Required file: {rel}", False, "missing"))
    return results


def _migration_slug(name: str) -> str:
    if "_" not in name:
        return name
    return name.split("_", 1)[1]


def _check_migration_naming(migration_dir: Path) -> CheckResult:
    files = sorted(migration_dir.glob("*.sql"))
    if not files:
        return CheckResult(
            "Migration naming format",
            False,
            "No migration files found",
        )

    invalid: list[str] = []
    pattern = re.compile(r"^\d{14}_[a-z0-9_]+\.sql$")
    for path in files:
        if not pattern.match(path.name):
            invalid.append(path.name)
    if invalid:
        return CheckResult(
            "Migration naming format",
            False,
            "Invalid filenames: " + ", ".join(invalid),
        )
    return CheckResult(
        "Migration naming format",
        True,
        f"All {len(files)} migration files use 14-digit version format",
    )


def _check_required_migration_slugs(migration_dir: Path) -> CheckResult:
    expected = {
        "init.sql",
        "risk_controls.sql",
        "delivery_challenge.sql",
        "unlock_rate_limit.sql",
        "security_events.sql",
        "maintenance_cleanup.sql",
        "global_safety_controls.sql",
        "partner_connectors.sql",
        "totp_factor.sql",
        "multisignal_guardian.sql",
        "legal_evidence_gate.sql",
        "legal_evidence_reviewers.sql",
        "reviewer_key_allowlist.sql",
        "external_legal_handoff_default.sql",
        "partner_handoff_notices.sql",
        "beta_feedback.sql",
        "private_first_trace_controls.sql",
        "trace_privacy_profile.sql",
        "reliability_and_beneficiary_identity.sql",
        "guardian_quorum_emergency_access.sql",
        "recovery_item_visibility_policy.sql",
        "proof_of_life_device_rebind.sql",
        "retention_policy_model.sql",
        "wrong_recipient_guardrails.sql",
        "remote_history_alignment.sql",
        "runtime_dispatch_schedules.sql",
    }
    actual = {_migration_slug(path.name) for path in migration_dir.glob("*.sql")}
    missing = sorted(expected - actual)
    if missing:
        return CheckResult(
            "Migration baseline coverage",
            False,
            "Missing migration slugs: " + ", ".join(missing),
        )
    return CheckResult(
        "Migration baseline coverage",
        True,
        f"All required migration slugs present ({len(expected)})",
    )


def _check_release_preflight(max_age_days: int) -> CheckResult:
    proc = _run(
        [
            sys.executable,
            str(ROOT / "tools" / "release_gate_preflight.py"),
            "--max-age-days",
            str(max_age_days),
        ]
    )
    if proc.returncode != 0:
        detail = (proc.stdout.strip() + "\n" + proc.stderr.strip()).strip()
        return CheckResult("Release preflight", False, detail or "release preflight failed")
    return CheckResult("Release preflight", True, proc.stdout.strip() or "passed")


def _check_git_clean() -> CheckResult:
    proc = _run(["git", "status", "--short"])
    if proc.returncode != 0:
        return CheckResult(
            "Git worktree clean",
            False,
            proc.stderr.strip() or "failed to read git status",
        )
    if proc.stdout.strip():
        return CheckResult("Git worktree clean", False, "Uncommitted changes detected")
    return CheckResult("Git worktree clean", True, "clean")


def _render_report(
    *,
    generated_at: datetime,
    checks: list[CheckResult],
    baseline_tag: str,
) -> str:
    status = "PASS" if all(item.ok for item in checks) else "FAIL"
    lines: list[str] = []
    lines.append(f"# v0.1.7 Baseline Gate Report")
    lines.append("")
    lines.append(f"- Baseline tag: {baseline_tag}")
    lines.append(f"- Timestamp: {generated_at.isoformat().replace('+00:00', 'Z')}")
    lines.append(f"- Result: {status}")
    lines.append("")
    lines.append("## Checks")
    lines.append("")
    for item in checks:
        mark = "PASS" if item.ok else "FAIL"
        lines.append(f"- [{mark}] {item.title}")
        lines.append(f"  - {item.detail}")
    lines.append("")
    lines.append("## Decision")
    lines.append("")
    lines.append("1. PASS: baseline stability/security/docs package is ready for controlled release operation.")
    lines.append("2. FAIL: resolve failed checks before advancing release scope.")
    lines.append("")
    return "\n".join(lines)


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Validate v0.1.7 baseline readiness for core flow, security/key hygiene, and docs completeness."
    )
    parser.add_argument("--report-dir", default=str(DEFAULT_REPORT_DIR))
    parser.add_argument("--max-age-days", type=int, default=30)
    parser.add_argument("--require-clean-tree", action="store_true")
    args = parser.parse_args()

    report_dir = Path(args.report_dir)
    if not report_dir.is_absolute():
        report_dir = ROOT / report_dir
    report_dir.mkdir(parents=True, exist_ok=True)

    migration_dir = ROOT / "supabase" / "migrations"
    required_docs = [
        ROOT / "docs" / "release-readiness-checklist.md",
        ROOT / "docs" / "runtime-secrets-setup.md",
        ROOT / "docs" / "reviewer-key-rotation.md",
        ROOT / "docs" / "production-deploy-runbook.md",
        ROOT / "docs" / "incident-response.md",
        ROOT / "docs" / "store-readiness.md",
        ROOT / "docs" / "releases" / "v0.1.7-baseline.md",
    ]
    required_workflows = [
        ROOT / ".github" / "workflows" / "quality.yml",
        ROOT / ".github" / "workflows" / "flutter-quality.yml",
        ROOT / ".github" / "workflows" / "security-gate.yml",
        ROOT / ".github" / "workflows" / "app-release.yml",
        ROOT / ".github" / "workflows" / "runtime-dispatch-ai-ops.yml",
    ]

    checks: list[CheckResult] = []
    checks.append(_check_git_tag_exists(BASELINE_TAG))
    checks.extend(_check_required_paths(required_docs))
    checks.extend(_check_required_paths(required_workflows))
    checks.append(_check_migration_naming(migration_dir))
    checks.append(_check_required_migration_slugs(migration_dir))
    checks.append(_check_release_preflight(args.max_age_days))
    if args.require_clean_tree:
        checks.append(_check_git_clean())

    now = datetime.now(timezone.utc)
    report_path = report_dir / f"v0.1.7-baseline-gate-{now.strftime('%Y%m%d-%H%M%S')}.md"
    report_path.write_text(
        _render_report(generated_at=now, checks=checks, baseline_tag=BASELINE_TAG),
        encoding="utf-8",
    )

    all_ok = all(item.ok for item in checks)
    result = "PASS" if all_ok else "FAIL"
    print(f"[{result}] v0.1.7 baseline gate")
    print(f"- Report: {report_path}")
    for item in checks:
        prefix = "PASS" if item.ok else "FAIL"
        print(f"- {prefix}: {item.title} | {item.detail}")
    return 0 if all_ok else 1


if __name__ == "__main__":
    raise SystemExit(main())
