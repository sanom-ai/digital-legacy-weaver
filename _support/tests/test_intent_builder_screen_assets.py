from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]


def _read(path: Path) -> str:
    return path.read_text(encoding="utf-8")


def test_intent_builder_screen_assets_exist() -> None:
    screen = ROOT / "apps" / "flutter_app" / "lib" / "features" / "intent_builder" / "intent_builder_screen.dart"
    preview = ROOT / "apps" / "flutter_app" / "lib" / "features" / "intent_builder" / "intent_ptn_preview.dart"
    model = ROOT / "apps" / "flutter_app" / "lib" / "features" / "intent_builder" / "intent_builder_model.dart"
    repository = ROOT / "apps" / "flutter_app" / "lib" / "features" / "intent_builder" / "intent_draft_repository.dart"
    provider = ROOT / "apps" / "flutter_app" / "lib" / "features" / "intent_builder" / "intent_draft_provider.dart"
    artifact_model = ROOT / "apps" / "flutter_app" / "lib" / "features" / "intent_builder" / "intent_canonical_artifact_model.dart"
    artifact_repository = ROOT / "apps" / "flutter_app" / "lib" / "features" / "intent_builder" / "intent_canonical_artifact_repository.dart"
    artifact_provider = ROOT / "apps" / "flutter_app" / "lib" / "features" / "intent_builder" / "intent_canonical_artifact_provider.dart"
    artifact_review = ROOT / "apps" / "flutter_app" / "lib" / "features" / "intent_builder" / "intent_artifact_review_screen.dart"
    artifact_compare = ROOT / "apps" / "flutter_app" / "lib" / "features" / "intent_builder" / "intent_artifact_compare_screen.dart"
    artifact_history = ROOT / "apps" / "flutter_app" / "lib" / "features" / "intent_builder" / "intent_artifact_history_screen.dart"
    trace_preview = ROOT / "apps" / "flutter_app" / "lib" / "features" / "intent_builder" / "intent_trace_preview.dart"
    contract_spec = ROOT / "specs" / "intent-compiler-contract.md"
    artifact_sample = ROOT / "examples" / "intent-canonical-artifact.sample.json"
    dashboard = ROOT / "apps" / "flutter_app" / "lib" / "features" / "dashboard" / "dashboard_screen.dart"
    pubspec = ROOT / "apps" / "flutter_app" / "pubspec.yaml"
    assert screen.exists()
    assert preview.exists()
    assert model.exists()
    assert repository.exists()
    assert provider.exists()
    assert artifact_model.exists()
    assert artifact_repository.exists()
    assert artifact_provider.exists()
    assert artifact_review.exists()
    assert artifact_compare.exists()
    assert artifact_history.exists()
    assert trace_preview.exists()
    assert contract_spec.exists()
    assert artifact_sample.exists()
    assert dashboard.exists()
    assert pubspec.exists()

    screen_src = _read(screen)
    preview_src = _read(preview)
    model_src = _read(model)
    repository_src = _read(repository)
    provider_src = _read(provider)
    artifact_model_src = _read(artifact_model)
    artifact_repository_src = _read(artifact_repository)
    artifact_provider_src = _read(artifact_provider)
    artifact_review_src = _read(artifact_review)
    artifact_compare_src = _read(artifact_compare)
    artifact_history_src = _read(artifact_history)
    trace_preview_src = _read(trace_preview)
    contract_spec_src = _read(contract_spec)
    artifact_sample_src = _read(artifact_sample)
    dashboard_src = _read(dashboard)
    pubspec_src = _read(pubspec)

    assert "class IntentBuilderScreen" in screen_src
    assert "ConsumerStatefulWidget" in screen_src
    assert "User-defined legacy intent" in screen_src
    assert "Add intent entry" in screen_src
    assert "Edit intent entry" in screen_src
    assert "Reset local draft" in screen_src
    assert "Encrypted draft stored on this device" in screen_src
    assert "Encrypted local draft persistence" in screen_src
    assert "Restored encrypted local draft from this device." in screen_src
    assert "Legacy delivery" in screen_src
    assert "Self-recovery" in screen_src
    assert 'child: const Text("Edit")' in screen_src
    assert 'child: const Text("Remove")' in screen_src
    assert 'child: Text(entry.status == \'active\' ? "Move to draft" : "Activate")' in screen_src
    assert "DropdownButtonFormField<String>" in screen_src
    assert "SwitchListTile.adaptive" in screen_src
    assert "Recipient channel:" in screen_src
    assert "Safeguards:" in screen_src
    assert "Remove draft entry" in screen_src
    assert "Compiler bridge" in screen_src
    assert "Canonical export" in screen_src
    assert "Export canonical PTN" in screen_src
    assert "Clear exported artifact" in screen_src
    assert "Review artifact" in screen_src
    assert "Mark reviewed" in screen_src
    assert "Mark ready" in screen_src
    assert "Export history" in screen_src
    assert "ChoiceChip(" in screen_src
    assert 'label: const Text("All")' in screen_src
    assert 'label: const Text("Ready")' in screen_src
    assert 'label: const Text("Promoted")' in screen_src
    assert 'label: const Text("Has issues")' in screen_src
    assert 'DropdownMenuItem(value: \'newest\', child: Text("Newest first"))' in screen_src
    assert 'DropdownMenuItem(value: \'oldest\', child: Text("Oldest first"))' in screen_src
    assert 'DropdownMenuItem(value: \'state\', child: Text("Sort by state"))' in screen_src
    assert "_visibleArtifactHistory" in screen_src
    assert "_historyFilter" in screen_src
    assert "_historySort" in screen_src
    assert "No artifact versions match the current history filter." in screen_src
    assert 'child: const Text("View full history")' in screen_src
    assert 'child: const Text("Compare")' in screen_src
    assert 'child: const Text("Promote")' in screen_src
    assert "Remove version" in screen_src
    assert "Artifact versions:" in screen_src
    assert "_artifactBadges" in screen_src
    assert 'badges.add("Latest")' in screen_src
    assert 'badges.add("Promoted")' in screen_src
    assert 'badges.add("Ready")' in screen_src
    assert 'badges.add("Has issues")' in screen_src
    assert "State policy:" in screen_src
    assert "_canMarkReviewed" in screen_src
    assert "_canMarkReady" in screen_src
    assert "_statePolicyMessage" in screen_src
    assert "buildDraftIntentTrace" in screen_src
    assert "Activation status: draft and exported artifact are in sync." in screen_src
    assert "Activation status: draft changed since the last canonical export." in screen_src
    assert "No canonical artifact exported yet for the current active draft." in screen_src
    assert "Activate at least one entry to make canonical export meaningful." in screen_src
    assert "buildDraftIntentPtnPreview" in screen_src
    assert "Draft canonical preview generated from the current intent document" in screen_src
    assert "buildDraftIntentCompilerReport(" in screen_src
    assert "String buildDraftIntentPtnPreview" in preview_src
    assert 'language: PTN' in preview_src
    assert 'authority owner {' in preview_src
    assert 'authority system_scheduler {' in preview_src
    assert 'route_to_${_slug(entry.recipient.recipientId)}' in preview_src
    assert 'label_asset_${_slug(entry.asset.assetId)}' in preview_src
    assert "_dedupe" in preview_src
    assert 'policy ${_slug(entry.entryId)}_policy {' in preview_src
    assert "factory IntentDocumentModel.fromMap" in model_src
    assert "factory IntentEntryModel.fromMap" in model_src
    assert "factory IntentEntryModel.selfRecoveryDraft" in model_src
    assert "document: _document" in screen_src
    assert "missing_partner_path" in _read(ROOT / "apps" / "flutter_app" / "lib" / "features" / "intent_builder" / "intent_compiler_report_model.dart")
    assert "class IntentCanonicalArtifactModel" in artifact_model_src
    assert "contractVersion" in artifact_model_src
    assert "IntentArtifactState" in artifact_model_src
    assert "artifactId" in artifact_model_src
    assert "promotedFromArtifactId" in artifact_model_src
    assert "artifactState" in artifact_model_src
    assert "sourceDraftSignature" in artifact_model_src
    assert "activeEntryCount" in artifact_model_src
    assert "class IntentCanonicalArtifactRepository" in artifact_repository_src
    assert "encrypted_intent_canonical_artifact" in artifact_repository_src
    assert "loadArtifactHistory" in artifact_repository_src
    assert "clearArtifactVersion" in artifact_repository_src
    assert "promoteArtifactVersion" in artifact_repository_src
    assert "intent_canonical_artifact_history" in artifact_repository_src
    assert "intentCanonicalArtifactRepositoryProvider" in artifact_provider_src
    assert "intentCanonicalArtifactProvider" in artifact_provider_src
    assert "intentCanonicalArtifactHistoryProvider" in artifact_provider_src
    assert "class IntentArtifactReviewScreen" in artifact_review_src
    assert "class IntentArtifactCompareScreen" in artifact_compare_src
    assert "class IntentArtifactHistoryScreen" in artifact_history_src
    assert "Canonical Artifact History" in artifact_history_src
    assert "Full artifact history" in artifact_history_src
    assert "Stored versions:" in artifact_history_src
    assert "Latest pinned artifact:" in artifact_history_src
    assert "Review compares and promotions happen locally on this device" in artifact_history_src
    assert "Promote artifact version" in artifact_history_src
    assert "Remove artifact version" in artifact_history_src
    assert "Historical artifact promoted into a fresh exported version." in artifact_history_src
    assert "Artifact version removed from local history." in artifact_history_src
    assert 'child: const Text("Review")' in artifact_history_src
    assert 'child: const Text("Compare")' in artifact_history_src
    assert 'child: const Text("Promote")' in artifact_history_src
    assert 'child: const Text("Remove version")' in artifact_history_src
    assert "Canonical Artifact Compare" in artifact_compare_src
    assert "Comparison summary" in artifact_compare_src
    assert "Changed fields" in artifact_compare_src
    assert "Artifact state changed" in artifact_compare_src
    assert "Promotion lineage" in artifact_compare_src
    assert "Diff details" in artifact_compare_src
    assert "Added:" in artifact_compare_src
    assert "Removed:" in artifact_compare_src
    assert "PTN comparison" in artifact_compare_src
    assert "Current artifact PTN" in artifact_compare_src
    assert "Compared artifact PTN" in artifact_compare_src
    assert "Canonical Artifact Review" in artifact_review_src
    assert "Artifact summary" in artifact_review_src
    assert "Artifact:" in artifact_review_src
    assert "Promoted from:" in artifact_review_src
    assert "Badge: Has issues" in artifact_review_src
    assert "State:" in artifact_review_src
    assert "State policy:" in artifact_review_src
    assert "Historical artifacts may be promoted into a fresh exported version" in artifact_review_src
    assert "Compiler report" in artifact_review_src
    assert "Trace" in artifact_review_src
    assert "PTN" in artifact_review_src
    assert "Map<String, dynamic> buildDraftIntentTrace" in trace_preview_src
    assert '"policy_block_id"' in trace_preview_src
    assert "intent-compiler-contract/v1" in artifact_sample_src
    assert "Intent Compiler Contract" in contract_spec_src
    assert "`intent-compiler-contract/v1`" in contract_spec_src
    assert "class IntentDraftRepository" in repository_src
    assert "SharedPreferences.getInstance()" in repository_src
    assert "FlutterSecureStorage" in repository_src
    assert "AesGcm.with256bits" in repository_src
    assert "local_device_draft_encrypted" in repository_src
    assert "encrypted_intent_draft" in repository_src
    assert "intentDraftRepositoryProvider" in provider_src
    assert "Intent Builder" in dashboard_src
    assert "Draft user-defined legacy intent before compiling it into PTN" in dashboard_src
    assert "Canonical artifact status" in dashboard_src
    assert "Compare latest with previous" in dashboard_src
    assert "Older versions can also be promoted again from Intent Builder without deleting history." in dashboard_src
    assert "Latest artifact was promoted from history." in dashboard_src
    assert "No local canonical PTN artifact exported yet." in dashboard_src
    assert "State ${artifact.artifactState.name}" in dashboard_src
    assert "artifact versions." in dashboard_src
    assert "Reviewed artifacts must stay in sync before they can be treated as ready." in dashboard_src
    assert "cryptography:" in pubspec_src
    assert "flutter_secure_storage:" in pubspec_src
    assert "shared_preferences:" in pubspec_src
