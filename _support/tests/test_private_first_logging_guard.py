from pathlib import Path

from tools.check_private_first_logging import BLOCKED_TERMS, TARGET_FILES


ROOT = Path(__file__).resolve().parents[2]


def test_private_first_logging_guard_targets_runtime_functions() -> None:
    for path in TARGET_FILES:
        assert path.exists(), f"missing runtime file in private-first guard: {path}"


def test_private_first_logging_guard_covers_secret_terms() -> None:
    expected = {"seed_phrase", "private_key", "mnemonic", "passphrase"}
    assert expected.issubset(set(BLOCKED_TERMS))
