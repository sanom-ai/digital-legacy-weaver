from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]


def _read(path: Path) -> str:
    return path.read_text(encoding="utf-8")


def test_intent_schema_doc_exists_with_core_sections() -> None:
    path = ROOT / "docs" / "ptn-intent-schema.md"
    assert path.exists()
    src = _read(path)
    assert "Intent entry" in src
    assert "Compiler expectations" in src
    assert "partner_path" in src


def test_intent_builder_model_doc_exists() -> None:
    path = ROOT / "docs" / "intent-builder-model.md"
    assert path.exists()
    src = _read(path)
    assert "IntentDocumentModel" in src
    assert "future intent-to-PTN compiler" in src


def test_flutter_intent_builder_model_exists_with_core_types() -> None:
    path = ROOT / "apps" / "flutter_app" / "lib" / "features" / "intent_builder" / "intent_builder_model.dart"
    assert path.exists()
    src = _read(path)
    assert "class IntentDocumentModel" in src
    assert "class IntentEntryModel" in src
    assert "legacyDeliveryDraft" in src
    assert "\"default_privacy_profile\"" in src
