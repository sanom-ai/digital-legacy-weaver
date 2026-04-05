from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]


def _read(path: Path) -> str:
    return path.read_text(encoding="utf-8")


def test_closed_beta_checklist_exists_with_core_sections() -> None:
    path = ROOT / "docs" / "closed-beta-checklist.md"
    assert path.exists()
    src = _read(path)
    assert "Entry criteria" in src
    assert "Daily operations" in src
    assert "Exit criteria" in src


def test_beta_dashboard_pack_exists_with_key_queries() -> None:
    path = ROOT / "ops" / "sql" / "beta_dashboard_pack.sql"
    assert path.exists()
    src = _read(path)
    assert "Daily dispatch outcomes" in src
    assert "Unlock success/error trend" in src
    assert "False-trigger candidate list" in src


def test_beta_gate_sql_pack_exists_with_coverage_queries() -> None:
    path = ROOT / "ops" / "sql" / "beta_gate_pack.sql"
    assert path.exists()
    src = _read(path)
    assert "beneficiary_coverage" in src
    assert "consent_coverage" in src
    assert "unlock_success_rate" in src


def test_first_launch_execution_playbook_exists() -> None:
    path = ROOT / "docs" / "first-launch-execution.md"
    assert path.exists()
    src = _read(path)
    assert "Phase 1: CI and runtime readiness" in src
    assert "E2E Runtime Checks" in src
    assert "App Release Pack" in src


def test_beta_gate_assets_exist() -> None:
    workflow = ROOT / ".github" / "workflows" / "beta-gate.yml"
    script = ROOT / "scripts" / "beta_gate_report.ps1"
    doc = ROOT / "docs" / "beta-gate-ops.md"
    assert workflow.exists()
    assert script.exists()
    assert doc.exists()

    workflow_src = _read(workflow)
    assert "security_triage_report.ps1" in workflow_src
    assert "beta_gate_report.ps1" in workflow_src
    assert "beta-gate-reports" in workflow_src
    assert "MIN_BENEFICIARY_COVERAGE" in workflow_src
    assert "MIN_CONSENT_COVERAGE" in workflow_src
    assert "MIN_COHORT_SIZE_FOR_COVERAGE_GATE" in workflow_src


def test_beta_status_snapshot_assets_exist() -> None:
    workflow = ROOT / ".github" / "workflows" / "beta-status.yml"
    script = ROOT / "scripts" / "beta_status_snapshot.ps1"
    doc = ROOT / "docs" / "beta-status-ops.md"
    assert workflow.exists()
    assert script.exists()
    assert doc.exists()

    workflow_src = _read(workflow)
    assert "beta_status_snapshot.ps1" in workflow_src
    assert "beta-status-reports" in workflow_src
    assert "Enforce snapshot gate" in workflow_src
