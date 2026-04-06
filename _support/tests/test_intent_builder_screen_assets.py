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
    readiness_model = ROOT / "apps" / "flutter_app" / "lib" / "features" / "intent_builder" / "intent_runtime_readiness_model.dart"
    readiness_screen = ROOT / "apps" / "flutter_app" / "lib" / "features" / "intent_builder" / "intent_runtime_readiness_screen.dart"
    artifact_review = ROOT / "apps" / "flutter_app" / "lib" / "features" / "intent_builder" / "intent_artifact_review_screen.dart"
    artifact_compare = ROOT / "apps" / "flutter_app" / "lib" / "features" / "intent_builder" / "intent_artifact_compare_screen.dart"
    artifact_history = ROOT / "apps" / "flutter_app" / "lib" / "features" / "intent_builder" / "intent_artifact_history_screen.dart"
    trace_preview = ROOT / "apps" / "flutter_app" / "lib" / "features" / "intent_builder" / "intent_trace_preview.dart"
    contract_spec = ROOT / "specs" / "intent-compiler-contract.md"
    artifact_sample = ROOT / "examples" / "intent-canonical-artifact.sample.json"
    dashboard = ROOT / "apps" / "flutter_app" / "lib" / "features" / "dashboard" / "dashboard_screen.dart"
    config_landing = ROOT / "apps" / "flutter_app" / "lib" / "features" / "auth" / "config_landing_screen.dart"
    demo_scenarios = ROOT / "apps" / "flutter_app" / "lib" / "features" / "auth" / "demo_scenarios.dart"
    pubspec = ROOT / "apps" / "flutter_app" / "pubspec.yaml"
    assert screen.exists()
    assert preview.exists()
    assert model.exists()
    assert repository.exists()
    assert provider.exists()
    assert artifact_model.exists()
    assert artifact_repository.exists()
    assert artifact_provider.exists()
    assert readiness_model.exists()
    assert readiness_screen.exists()
    assert artifact_review.exists()
    assert artifact_compare.exists()
    assert artifact_history.exists()
    assert trace_preview.exists()
    assert contract_spec.exists()
    assert artifact_sample.exists()
    assert dashboard.exists()
    assert config_landing.exists()
    assert demo_scenarios.exists()
    assert pubspec.exists()

    screen_src = _read(screen)
    preview_src = _read(preview)
    model_src = _read(model)
    repository_src = _read(repository)
    provider_src = _read(provider)
    artifact_model_src = _read(artifact_model)
    artifact_repository_src = _read(artifact_repository)
    artifact_provider_src = _read(artifact_provider)
    readiness_model_src = _read(readiness_model)
    readiness_screen_src = _read(readiness_screen)
    artifact_review_src = _read(artifact_review)
    artifact_compare_src = _read(artifact_compare)
    artifact_history_src = _read(artifact_history)
    trace_preview_src = _read(trace_preview)
    contract_spec_src = _read(contract_spec)
    artifact_sample_src = _read(artifact_sample)
    dashboard_src = _read(dashboard)
    config_landing_src = _read(config_landing)
    demo_scenarios_src = _read(demo_scenarios)
    pubspec_src = _read(pubspec)
    settings_src = _read(ROOT / "apps" / "flutter_app" / "lib" / "features" / "settings" / "safety_settings_screen.dart")
    profile_model_src = _read(ROOT / "apps" / "flutter_app" / "lib" / "features" / "profile" / "profile_model.dart")
    unlock_src = _read(ROOT / "apps" / "flutter_app" / "lib" / "features" / "unlock" / "unlock_delivery_screen.dart")
    compiler_report_src = _read(ROOT / "apps" / "flutter_app" / "lib" / "features" / "intent_builder" / "intent_compiler_report_model.dart")

    assert "class IntentBuilderScreen" in screen_src
    assert "ConsumerStatefulWidget" in screen_src
    assert "User-defined legacy intent" in screen_src
    assert "Add intent entry" in screen_src
    assert "Edit intent entry" in screen_src
    assert "Reset local draft" in screen_src
    assert "Encrypted draft stored on this device" in screen_src
    assert "Encrypted local draft persistence" in screen_src
    assert "Guardian quorum & emergency access" in screen_src
    assert "Enable guardian quorum" in screen_src
    assert "Guardian pool size" in screen_src
    assert "Required guardian approvals" in screen_src
    assert "Enable emergency access override" in screen_src
    assert "Require beneficiary request" in screen_src
    assert "Require guardian quorum" in screen_src
    assert "Emergency access grace window:" in screen_src
    assert "Restored encrypted local draft from this device." in screen_src
    assert "Legacy delivery" in screen_src
    assert "Self-recovery" in screen_src
    assert 'child: const Text("Edit")' in screen_src
    assert 'child: const Text("Remove")' in screen_src
    assert 'child: Text(entry.status == \'active\' ? "Move to draft" : "Activate")' in screen_src
    assert "DropdownButtonFormField<String>" in screen_src
    assert "SwitchListTile.adaptive" in screen_src
    assert "Recipient channel:" in screen_src
    assert "Visibility before trigger:" in screen_src
    assert "Visibility after trigger:" in screen_src
    assert "Value disclosure:" in screen_src
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
    assert "pre_trigger_visibility" in model_src
    assert "post_trigger_visibility" in model_src
    assert "value_disclosure_mode" in model_src
    assert "guardian_quorum_enabled" in model_src
    assert "guardian_quorum_required" in model_src
    assert "guardian_quorum_pool_size" in model_src
    assert "emergency_access_enabled" in model_src
    assert "emergency_access_requires_beneficiary_request" in model_src
    assert "emergency_access_requires_guardian_quorum" in model_src
    assert "emergency_access_grace_hours" in model_src
    assert "device_rebind_in_progress" in model_src
    assert "device_rebind_grace_hours" in model_src
    assert "recovery_key_enabled" in model_src
    assert "delivery_access_ttl_hours" in model_src
    assert "payload_retention_days" in model_src
    assert "audit_log_retention_days" in model_src
    assert "document: _document" in screen_src
    assert "missing_partner_path" in _read(ROOT / "apps" / "flutter_app" / "lib" / "features" / "intent_builder" / "intent_compiler_report_model.dart")
    assert "class IntentCanonicalArtifactModel" in artifact_model_src
    assert "class SealedReleaseCandidateModel" in artifact_model_src
    assert "class SealedReleaseEntryModel" in artifact_model_src
    assert "contractVersion" in artifact_model_src
    assert "IntentArtifactState" in artifact_model_src
    assert "artifactId" in artifact_model_src
    assert "promotedFromArtifactId" in artifact_model_src
    assert "artifactState" in artifact_model_src
    assert "sourceDraftSignature" in artifact_model_src
    assert "activeEntryCount" in artifact_model_src
    assert "sealedReleaseCandidate" in artifact_model_src
    assert "preTriggerVisibility" in artifact_model_src
    assert "postTriggerVisibility" in artifact_model_src
    assert "valueDisclosureMode" in artifact_model_src
    assert "class IntentCanonicalArtifactRepository" in artifact_repository_src
    assert "encrypted_intent_canonical_artifact" in artifact_repository_src
    assert "loadArtifactHistory" in artifact_repository_src
    assert "clearArtifactVersion" in artifact_repository_src
    assert "promoteArtifactVersion" in artifact_repository_src
    assert "intent_canonical_artifact_history" in artifact_repository_src
    assert "intentCanonicalArtifactRepositoryProvider" in artifact_provider_src
    assert "intentCanonicalArtifactProvider" in artifact_provider_src
    assert "intentCanonicalArtifactHistoryProvider" in artifact_provider_src
    assert "intentRuntimeReadinessProvider" in artifact_provider_src
    assert "class IntentRuntimeReadinessModel" in readiness_model_src
    assert "Ready for runtime" in readiness_model_src
    assert "Needs attention" in readiness_model_src
    assert "Draft only" in readiness_model_src
    assert "class IntentRuntimeReadinessScreen" in readiness_screen_src
    assert "Runtime Readiness" in readiness_screen_src
    assert "Runtime criteria" in readiness_screen_src
    assert "Readiness metrics" in readiness_screen_src
    assert "Current blockers" in readiness_screen_src
    assert "Three-layer map" in readiness_screen_src
    assert "Runtime blockers" in dashboard_src
    assert "Runtime readiness" in dashboard_src
    assert "Control room" in dashboard_src
    assert "Most Concrete Product Status" in dashboard_src
    assert "Available now" in dashboard_src
    assert "Next milestone" in dashboard_src
    assert "KPI snapshot" in dashboard_src
    assert "Scenario focus:" in dashboard_src
    assert "Primary action:" in dashboard_src
    assert "Action plan" in dashboard_src
    assert "Guided next steps" in dashboard_src
    assert "Draft workspace only" in dashboard_src
    assert "Blocking compiler issues" in dashboard_src
    assert "No active entries yet" in dashboard_src
    assert "Export completed" in dashboard_src
    assert "Reviewed but stale" in dashboard_src
    assert "Reviewed and in sync" in dashboard_src
    assert "Ready artifact drifted" in dashboard_src
    assert "Runtime candidate is healthy" in dashboard_src
    assert "Best next move:" in dashboard_src
    assert 'actionLabel: "Open builder"' in dashboard_src
    assert 'actionLabel: "Fix in builder"' in dashboard_src
    assert 'actionLabel: "Open review"' in dashboard_src
    assert 'actionLabel: "Open history"' in dashboard_src
    assert 'actionLabel: "Review artifact"' in dashboard_src
    assert "Live backend mode" in dashboard_src
    assert "Setup still incomplete" in dashboard_src
    assert "Next action:" in dashboard_src
    assert "primaryActionLabel" in dashboard_src
    assert "onPrimaryAction" in dashboard_src
    assert "review_exported_artifact" in dashboard_src
    assert "Open readiness details" in dashboard_src
    assert "Complete beta setup" in dashboard_src
    assert "Draft in sync" in dashboard_src
    assert "Draft changed" in dashboard_src
    assert "Warnings:" in dashboard_src
    assert "class _ControlRoomCard" in dashboard_src
    assert "class _MetricChip" in dashboard_src
    assert "class _StateHelperCard" in dashboard_src
    assert "IntentArtifactHistoryScreen" in dashboard_src
    assert "onOpenArtifactReview" in dashboard_src
    assert "onOpenArtifactHistory" in dashboard_src
    assert "currentScenarioTitle" in readiness_model_src
    assert "currentScenarioSummary" in readiness_model_src
    assert "currentScenarioNextStep" in readiness_model_src
    assert "primaryActionLabel" in readiness_model_src
    assert "primaryActionKey" in readiness_model_src
    assert "actionPlan" in readiness_model_src
    assert "Guardian quorum requirement exceeds guardian pool" in readiness_model_src
    assert "Emergency access should require an explicit beneficiary request" in readiness_model_src
    assert "Cross-device rebind window is active" in readiness_model_src
    assert "Recovery key fallback is enabled" in readiness_model_src
    assert "Retention policy: delivery link TTL" in readiness_model_src
    assert "Draft sync: current draft still matches the latest exported artifact." in dashboard_src
    assert "Draft sync: current draft changed since the latest export." in dashboard_src
    assert 'child: const Text("Readiness details")' in dashboard_src
    assert 'child: const Text("Open Intent Builder")' in dashboard_src
    assert "class ConfigLandingScreen" in config_landing_src
    assert "Finish backend setup or start a guided demo" in config_landing_src
    assert "Backend setup required" in config_landing_src
    assert "Start with a guided scenario" in config_landing_src
    assert "What happens in demo mode" in config_landing_src
    assert "Open demo workspace" in config_landing_src
    assert "Show setup reminder" in config_landing_src
    assert "Technical companion only" in config_landing_src
    assert "class DemoScenario" in demo_scenarios_src
    assert "const demoScenarios" in demo_scenarios_src
    assert "Family beneficiary handoff" in demo_scenarios_src
    assert "Owner self-recovery" in demo_scenarios_src
    assert "Private-first archive" in demo_scenarios_src
    assert "Start family handoff demo" in demo_scenarios_src
    assert "Start self-recovery demo" in demo_scenarios_src
    assert "Start private archive demo" in demo_scenarios_src
    assert "demoScenarioById" in demo_scenarios_src
    assert "demo_next_step" in demo_scenarios_src
    assert "screenTitle" in screen_src
    assert "screenSubtitle" in screen_src
    assert 'final demoScenarioTitle = _document.metadata["demo_title"] as String?;' in screen_src
    assert 'final demoScenarioNextStep = _document.metadata["demo_next_step"] as String?;' in screen_src
    assert 'Text(screenTitle)' in screen_src
    assert 'Text(screenSubtitle)' in screen_src
    assert 'Demo scenario: $demoScenarioTitle' in screen_src
    assert "Scenario preset" in screen_src
    assert "Preset active:" in screen_src
    assert "Preset next step:" in screen_src
    assert "_applyScenarioPreset" in screen_src
    assert "Registered beneficiary:" in screen_src
    assert "Verification hint:" in screen_src
    assert "Fallback channels:" in screen_src
    assert "Registered beneficiary name" in screen_src
    assert "Visibility before trigger" in screen_src
    assert "Visibility after trigger" in screen_src
    assert "Value disclosure" in screen_src
    assert "Email fallback" in screen_src
    assert "SMS fallback" in screen_src
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
    assert "Sealed release candidate" in artifact_review_src
    assert "Sealed release mode:" in artifact_review_src
    assert "Secret residency:" in artifact_review_src
    assert "Pre-trigger visibility:" in artifact_review_src
    assert "Post-trigger visibility:" in artifact_review_src
    assert "Value disclosure:" in artifact_review_src
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
    assert "Proof-of-life confirmation" in settings_src
    assert "Enable server heartbeat fallback" in settings_src
    assert "Acknowledge iOS/background limits" in settings_src
    assert "Guardian quorum" in settings_src
    assert "Enable guardian quorum for legacy release" in settings_src
    assert "Current quorum:" in settings_src
    assert "Emergency access override" in settings_src
    assert "Enable emergency access override" in settings_src
    assert "Emergency access grace window (hours)" in settings_src
    assert "Cross-device rebind & recovery" in settings_src
    assert "Device rebind in progress" in settings_src
    assert "Rebind grace window (hours)" in settings_src
    assert "Enable recovery key fallback" in settings_src
    assert "Retention policy" in settings_src
    assert "Delivery access link TTL (hours)" in settings_src
    assert "Payload retention (days)" in settings_src
    assert "Audit log retention (days)" in settings_src
    assert "proofOfLifeCheckMode" in settings_src
    assert "beneficiaryName" in profile_model_src
    assert "beneficiaryVerificationPhraseHash" in profile_model_src
    assert "hasBeneficiaryIdentityKit" in profile_model_src
    assert "Registered beneficiary name" in unlock_src
    assert "Verification phrase" in unlock_src
    assert "beneficiary_name" in unlock_src
    assert "verification_phrase" in unlock_src
    assert "Beneficiary Receipt Flow" in unlock_src
    assert "Confirm the access link" in unlock_src
    assert "Confirm your beneficiary identity" in unlock_src
    assert "Verify and unlock" in unlock_src
    assert "Secure web-link default" in unlock_src
    assert "App optional" in unlock_src
    assert "What the beneficiary needs" in unlock_src
    assert "Not the intended recipient?" in unlock_src
    assert "This receipt is not mine" in unlock_src
    assert "Stop here and re-verify the recipient path" in unlock_src or "Stop here and re-verify the recipient path with the owner, guardian, operator, or designated partner first." in unlock_src
    assert "Need help?" in unlock_src
    assert "fallback path such as email plus SMS" in unlock_src
    assert "One-time code sent through the active fallback channel." in unlock_src
    assert "Must match the owner-prepared beneficiary record." in unlock_src
    assert "The secure link remains the default path." in unlock_src
    assert "Request Receipt Code" in unlock_src
    assert "Open Delivery Bundle" in unlock_src
    assert "Delivery Bundle Receipt" in unlock_src
    assert "Safe next steps" in unlock_src
    assert "Receipt status" in unlock_src
    assert "Verification route:" in unlock_src
    assert "Verify balances, legal status, or account details directly with the relevant partner, institution, or law office." in unlock_src
    assert "Complete any legal or service-specific verification outside this technical receipt flow." in unlock_src
    assert "If you think this receipt reached the wrong person, stop and re-verify the recipient path before sharing anything." in unlock_src
    assert 'title: const Text("Beneficiary Receipt")' in dashboard_src
    assert 'subtitle: const Text("Secure link, receipt code, and pre-registered identity flow")' in dashboard_src
    assert "missing_beneficiary_identity" in compiler_report_src
    assert "missing_beneficiary_verification_hint" in compiler_report_src
    assert "missing_multi_channel_fallback" in compiler_report_src
    assert "pretrigger_visibility_too_open" in compiler_report_src
    assert "value_disclosure_too_open" in compiler_report_src
    assert "short_grace_period" in compiler_report_src
    assert "server_heartbeat_fallback_disabled" in compiler_report_src
    assert "guardian_quorum_invalid" in compiler_report_src
    assert "guardian_quorum_weak" in compiler_report_src
    assert "emergency_access_without_guardian_quorum" in compiler_report_src
    assert "emergency_access_without_beneficiary_request" in compiler_report_src
    assert "device_rebind_window_active" in compiler_report_src
    assert "recovery_key_fallback_disabled" in compiler_report_src
    assert "delivery_access_ttl_too_long" in compiler_report_src
    assert "payload_retention_exceeds_audit_retention" in compiler_report_src
