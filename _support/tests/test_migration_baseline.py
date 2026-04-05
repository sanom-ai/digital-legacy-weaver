from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
MIGRATIONS = ROOT / "supabase" / "migrations"


def _read(name: str) -> str:
    return (MIGRATIONS / name).read_text(encoding="utf-8")


def test_required_migration_files_exist() -> None:
    required = [
        "20260405_0001_init.sql",
        "20260405_0002_risk_controls.sql",
        "20260405_0003_delivery_challenge.sql",
        "20260405_0004_unlock_rate_limit.sql",
        "20260405_0005_security_events.sql",
        "20260405_0006_maintenance_cleanup.sql",
        "20260405_0007_global_safety_controls.sql",
        "20260405_0008_partner_connectors.sql",
        "20260405_0009_totp_factor.sql",
        "20260405_0010_multisignal_guardian.sql",
        "20260405_0011_legal_evidence_gate.sql",
        "20260405_0012_legal_evidence_reviewers.sql",
        "20260405_0013_reviewer_key_allowlist.sql",
        "20260405_0014_external_legal_handoff_default.sql",
        "20260405_0015_partner_handoff_notices.sql",
        "20260405_0016_beta_feedback.sql",
        "20260405_0017_private_first_trace_controls.sql",
        "20260405_0018_trace_privacy_profile.sql",
    ]
    existing = {p.name for p in MIGRATIONS.glob("*.sql")}
    for name in required:
        assert name in existing, f"missing migration: {name}"


def test_unlock_rate_limit_table_defined() -> None:
    src = _read("20260405_0004_unlock_rate_limit.sql")
    assert "create table if not exists public.delivery_access_rate_limits" in src


def test_security_events_table_defined() -> None:
    src = _read("20260405_0005_security_events.sql")
    assert "create table if not exists public.security_events" in src


def test_cleanup_rpc_defined() -> None:
    src = _read("20260405_0006_maintenance_cleanup.sql")
    assert "create or replace function public.run_maintenance_cleanup" in src


def test_global_safety_controls_defined() -> None:
    src = _read("20260405_0007_global_safety_controls.sql")
    assert "create table if not exists public.system_safety_controls" in src
    assert "create or replace function public.set_system_safety_controls" in src


def test_partner_connector_tables_defined() -> None:
    src = _read("20260405_0008_partner_connectors.sql")
    assert "create table if not exists public.partner_connectors" in src
    assert "create table if not exists public.legacy_asset_refs" in src


def test_totp_factor_and_unlock_requirement_defined() -> None:
    src = _read("20260405_0009_totp_factor.sql")
    assert "create table if not exists public.user_totp_factors" in src
    assert "add column if not exists require_totp_unlock boolean" in src


def test_multisignal_and_guardian_tables_defined() -> None:
    src = _read("20260405_0010_multisignal_guardian.sql")
    assert "create table if not exists public.owner_life_signals" in src
    assert "create table if not exists public.guardian_approvals" in src
    assert "add column if not exists require_multisignal_before_release" in src
    assert "add column if not exists require_guardian_approval_legacy" in src


def test_legal_evidence_gate_defined() -> None:
    src = _read("20260405_0011_legal_evidence_gate.sql")
    assert "create table if not exists public.legal_evidence_records" in src
    assert "review_status" in src
    assert "add column if not exists require_legal_evidence_legacy" in src


def test_legal_evidence_reviewer_workflow_defined() -> None:
    src = _read("20260405_0012_legal_evidence_reviewers.sql")
    assert "create table if not exists public.legal_evidence_reviews" in src
    assert "create or replace function public.apply_legal_evidence_review" in src
    assert "approvals >= 2" in src


def test_reviewer_key_allowlist_defined() -> None:
    src = _read("20260405_0013_reviewer_key_allowlist.sql")
    assert "create table if not exists public.reviewer_api_keys" in src
    assert "key_hash text not null unique" in src
    assert "role in ('reviewer', 'admin')" in src


def test_external_legal_handoff_default_defined() -> None:
    src = _read("20260405_0014_external_legal_handoff_default.sql")
    assert "require_legal_evidence_legacy set default false" in src


def test_partner_handoff_notice_table_defined() -> None:
    src = _read("20260405_0015_partner_handoff_notices.sql")
    assert "create table if not exists public.partner_handoff_notices" in src
    assert "delivery_status" in src
    assert "unique(owner_id, case_id)" in src


def test_beta_feedback_table_defined() -> None:
    src = _read("20260405_0016_beta_feedback.sql")
    assert "create table if not exists public.beta_feedback_reports" in src
    assert "category in ('ux', 'bug', 'security', 'reliability', 'other')" in src
    assert "severity in ('low', 'medium', 'high', 'critical')" in src


def test_private_first_trace_controls_defined() -> None:
    src = _read("20260405_0017_private_first_trace_controls.sql")
    assert "add column if not exists private_first_mode boolean not null default true" in src
    assert "add column if not exists minimize_trace_metadata boolean not null default true" in src
    assert "add column if not exists trace_retention_days int not null default 14" in src
    assert "metadata = metadata - 'requirementTrace'" in src


def test_trace_privacy_profile_defined() -> None:
    src = _read("20260405_0018_trace_privacy_profile.sql")
    assert "add column if not exists trace_privacy_profile text not null default 'minimal'" in src
    assert "trace_privacy_profile in ('confidential', 'minimal', 'audit-heavy')" in src
