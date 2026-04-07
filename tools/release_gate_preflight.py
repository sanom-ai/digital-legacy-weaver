from __future__ import annotations

import argparse
import re
import subprocess
import sys
from datetime import datetime, timedelta, timezone
from pathlib import Path
from typing import Iterable


ROOT = Path(__file__).resolve().parents[1]
DEFAULT_REPORT_DIR = ROOT / "ops" / "reports"


def _latest_report(report_dir: Path, pattern: str) -> Path | None:
    files = sorted(report_dir.glob(pattern), key=lambda p: p.stat().st_mtime, reverse=True)
    return files[0] if files else None


def _extract_line_value(text: str, label: str) -> str | None:
    match = re.search(rf"^- {re.escape(label)}:\s*(.+)$", text, flags=re.MULTILINE)
    if not match:
        return None
    return match.group(1).strip()


def _parse_iso8601(value: str) -> datetime | None:
    try:
        normalized = value.replace("Z", "+00:00")
        dt = datetime.fromisoformat(normalized)
        if dt.tzinfo is None:
            dt = dt.replace(tzinfo=timezone.utc)
        return dt.astimezone(timezone.utc)
    except ValueError:
        return None


def _check_report(report_path: Path, max_age_days: int) -> list[str]:
    issues: list[str] = []
    text = report_path.read_text(encoding="utf-8")
    result = _extract_line_value(text, "Result")
    if result != "PASS":
        issues.append(f"{report_path.name}: Result must be PASS (found: {result or 'missing'})")
    ts_raw = _extract_line_value(text, "Timestamp")
    if not ts_raw:
        issues.append(f"{report_path.name}: Timestamp line is missing")
        return issues
    ts = _parse_iso8601(ts_raw)
    if ts is None:
        issues.append(f"{report_path.name}: Timestamp is not valid ISO8601 ({ts_raw})")
        return issues
    age = datetime.now(timezone.utc) - ts
    if age > timedelta(days=max_age_days):
        issues.append(
            f"{report_path.name}: report is stale ({age.days} days old, max allowed {max_age_days})"
        )
    return issues


def _check_required_files(paths: Iterable[Path]) -> list[str]:
    missing = [str(path.relative_to(ROOT)) for path in paths if not path.exists()]
    if not missing:
        return []
    return [f"Required file missing: {item}" for item in missing]


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Release preflight gate: require fresh PASS evidence for backup/restore and safety drill."
    )
    parser.add_argument("--report-dir", default=str(DEFAULT_REPORT_DIR))
    parser.add_argument("--max-age-days", type=int, default=30)
    args = parser.parse_args()

    report_dir = Path(args.report_dir)
    if not report_dir.is_absolute():
        report_dir = ROOT / report_dir

    issues: list[str] = []
    issues.extend(
        _check_required_files(
            [
                ROOT / "docs" / "release-readiness-checklist.md",
                ROOT / "docs" / "incident-response.md",
                ROOT / "scripts" / "backup_restore_smoke_test.ps1",
                ROOT / "scripts" / "safety_control_drill.ps1",
            ]
        )
    )
    encoding_check = subprocess.run(
        [sys.executable, str(ROOT / "tools" / "check_text_encoding_hygiene.py")],
        text=True,
        capture_output=True,
        check=False,
    )
    if encoding_check.returncode != 0:
        issues.append("Text encoding hygiene check failed (see details below).")
        details = encoding_check.stdout.strip() or encoding_check.stderr.strip()
        if details:
            issues.append(details)

    backup_report = _latest_report(report_dir, "backup-restore-smoke-*.md")
    if backup_report is None:
        issues.append("Missing backup/restore report in ops/reports (backup-restore-smoke-*.md)")
    else:
        issues.extend(_check_report(backup_report, args.max_age_days))

    drill_report = _latest_report(report_dir, "safety-control-drill-*.md")
    if drill_report is None:
        issues.append("Missing safety drill report in ops/reports (safety-control-drill-*.md)")
    else:
        issues.extend(_check_report(drill_report, args.max_age_days))

    if issues:
        print("[FAIL] Release gate preflight failed:")
        for issue in issues:
            print(f"- {issue}")
        return 1

    print("[PASS] Release gate preflight passed.")
    print(f"- Backup report: {backup_report}")
    print(f"- Safety drill report: {drill_report}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
