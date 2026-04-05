from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
WORKFLOW = ROOT / ".github" / "workflows" / "e2e-runtime.yml"


def _read(path: Path) -> str:
    return path.read_text(encoding="utf-8")


def test_e2e_runtime_workflow_exists() -> None:
    assert WORKFLOW.exists()


def test_e2e_runtime_workflow_runs_expected_scripts() -> None:
    src = _read(WORKFLOW)
    assert "run_integration_unlock_flow.ps1" in src
    assert "run_adversarial_unlock_checks.ps1" in src
    assert "SUPABASE_TEST_PROJECT_REF" in src
    assert "SUPABASE_TEST_ANON_KEY" in src
    assert "E2E_TEST_ACCESS_ID" in src
    assert "E2E_TEST_ACCESS_KEY" in src
    assert "E2E_TEST_VERIFICATION_CODE" in src
    assert "E2E_REQUIRE_POSITIVE_UNLOCK" in src
    assert "-RequirePositiveUnlock" in src
    assert "Strict mode requires secret: E2E_TEST_ACCESS_ID" in src
    assert "Strict mode requires secret: E2E_TEST_ACCESS_KEY" in src
    assert "Strict mode requires secret: E2E_TEST_VERIFICATION_CODE" in src
    assert "id: integration" in src
    assert "id: adversarial" in src
    assert "continue-on-error: true" in src
    assert "steps.integration.outcome" in src
    assert "steps.adversarial.outcome" in src
    assert "Enforce runtime check gate" in src
    assert "Tee-Object -FilePath ops/reports/e2e-runtime-integration.txt" in src
    assert "Tee-Object -FilePath ops/reports/e2e-runtime-adversarial.txt" in src
    assert "actions/upload-artifact@v4" in src
    assert "e2e-runtime-summary.md" in src
    assert "GITHUB_STEP_SUMMARY" in src
    assert "Missing required secret: SUPABASE_TEST_PROJECT_REF" in src
    assert "Missing required secret: SUPABASE_TEST_ANON_KEY" in src


def test_e2e_runtime_workflow_is_scheduled() -> None:
    src = _read(WORKFLOW)
    assert 'cron: "25 */6 * * *"' in src
