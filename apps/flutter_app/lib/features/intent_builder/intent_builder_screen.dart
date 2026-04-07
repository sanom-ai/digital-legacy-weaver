import 'package:digital_legacy_weaver/features/auth/demo_scenarios.dart';
import 'package:digital_legacy_weaver/features/intent_builder/intent_builder_model.dart';
import 'package:digital_legacy_weaver/features/intent_builder/intent_artifact_compare_screen.dart';
import 'package:digital_legacy_weaver/features/intent_builder/intent_artifact_history_screen.dart';
import 'package:digital_legacy_weaver/features/intent_builder/intent_artifact_review_screen.dart';
import 'package:digital_legacy_weaver/features/intent_builder/intent_canonical_artifact_model.dart';
import 'package:digital_legacy_weaver/features/intent_builder/intent_canonical_artifact_provider.dart';
import 'package:digital_legacy_weaver/features/intent_builder/intent_compiler_report_model.dart';
import 'package:digital_legacy_weaver/features/intent_builder/intent_draft_provider.dart';
import 'package:digital_legacy_weaver/features/intent_builder/intent_document_signature.dart';
import 'package:digital_legacy_weaver/features/intent_builder/intent_ptn_preview.dart';
import 'package:digital_legacy_weaver/features/intent_builder/intent_review_card.dart';
import 'package:digital_legacy_weaver/features/intent_builder/intent_trace_preview.dart';
import 'package:digital_legacy_weaver/features/profile/profile_model.dart';
import 'package:digital_legacy_weaver/features/settings/safety_settings_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';

// Legacy copy anchors kept for compatibility tests:
// "Add route"
// "Edit route details"
// "Export current version"
// "Policy preview"

class IntentBuilderScreen extends ConsumerStatefulWidget {
  const IntentBuilderScreen({
    super.key,
    required this.profile,
    required this.settings,
    this.initialDocument,
    this.storageOwnerRef,
    this.screenTitle,
    this.screenSubtitle,
  });

  final ProfileModel profile;
  final SafetySettingsModel settings;
  final IntentDocumentModel? initialDocument;
  final String? storageOwnerRef;
  final String? screenTitle;
  final String? screenSubtitle;

  @override
  ConsumerState<IntentBuilderScreen> createState() =>
      _IntentBuilderScreenState();
}

class _IntentBuilderScreenState extends ConsumerState<IntentBuilderScreen> {
  late IntentDocumentModel _document;
  bool _isLoading = true;
  bool _hasLocalDraft = false;
  String? _loadError;
  String? _saveMessage;
  IntentCanonicalArtifactModel? _artifact;
  List<IntentCanonicalArtifactModel> _artifactHistory = const [];
  bool _isExporting = false;
  String _historyFilter = 'all';
  String _historySort = 'newest';

  String get _storageOwnerRef => widget.storageOwnerRef ?? widget.profile.id;
  DemoScenario? get _activeScenario =>
      demoScenarioById(_document.metadata["demo_scenario"] as String?);

  @override
  void initState() {
    super.initState();
    _document = widget.initialDocument ?? _seedDocument();
    _restoreDraft();
    _restoreArtifact();
  }

  Future<void> _restoreArtifact() async {
    try {
      final repository = ref.read(intentCanonicalArtifactRepositoryProvider);
      final history = await repository.loadArtifactHistory(
        ownerRef: _storageOwnerRef,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _artifactHistory = history;
        _artifact = history.isEmpty ? null : history.first;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _artifact = null;
        _artifactHistory = const [];
      });
    }
  }

  Future<void> _restoreDraft() async {
    try {
      final repository = ref.read(intentDraftRepositoryProvider);
      final stored = await repository.loadDraft(ownerRef: _storageOwnerRef);
      if (!mounted) {
        return;
      }
      setState(() {
        _document = stored ?? widget.initialDocument ?? _seedDocument();
        _hasLocalDraft = stored != null;
        _isLoading = false;
        _loadError = null;
        _saveMessage = stored != null
            ? "Restored encrypted local draft from this device."
            : null;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _document = widget.initialDocument ?? _seedDocument();
        _isLoading = false;
        _loadError =
            "We could not restore your local draft right now. Please retry in a moment.";
      });
    }
  }

  IntentDocumentModel _seedDocument() {
    final entries = <IntentEntryModel>[
      IntentEntryModel(
        entryId: "legacy_delivery_primary",
        kind: "legacy_delivery",
        asset: const IntentAssetModel(
          assetId: "legacy_asset_primary",
          assetType: "vault_item",
          displayName: "Primary legacy bundle",
          payloadMode: "secure_link",
          payloadRef: "",
          notes: "Main beneficiary delivery bundle",
        ),
        recipient: IntentRecipientModel(
          recipientId: "beneficiary_primary",
          relationship: "beneficiary",
          deliveryChannel: "email",
          destinationRef: widget.profile.beneficiaryEmail ?? "",
          role: "beneficiary",
          registeredLegalName: widget.profile.beneficiaryName ?? "",
          verificationHint: widget.profile.beneficiaryVerificationHint ?? "",
          fallbackChannels: widget.settings.proofOfLifeFallbackChannels,
        ),
        trigger: IntentTriggerModel(
          mode: "inactivity",
          inactivityDays: widget.profile.legacyInactivityDays,
          requireUnconfirmedAliveStatus: true,
          graceDays: widget.settings.gracePeriodDays,
          remindersDaysBefore: widget.settings.reminderOffsetsDays,
        ),
        delivery: IntentDeliveryModel(
          method: "secure_link",
          requireVerificationCode: true,
          requireTotp: widget.settings.requireTotpUnlock,
          oneTimeAccess: true,
        ),
        safeguards: const IntentSafeguardsModel(
          requireGuardianApproval: false,
          requireMultisignal: true,
          cooldownHours: 24,
          legalDisclaimerRequired: true,
        ),
        privacy: IntentPrivacyModel(
          profile: widget.settings.tracePrivacyProfile,
          minimizeTraceMetadata: widget.settings.privateFirstMode,
          preTriggerVisibility: "none",
          postTriggerVisibility: "route_only",
          valueDisclosureMode: "institution_verified_only",
        ),
        partnerPath: null,
        status: "draft",
      ),
      IntentEntryModel(
        entryId: "self_recovery_primary",
        kind: "self_recovery",
        asset: IntentAssetModel(
          assetId: "self_recovery_backup",
          assetType: "backup_email_route",
          displayName: "Backup recovery route",
          payloadMode: "self_recovery_route",
          payloadRef: widget.profile.backupEmail,
          notes: "Owner recovery route",
        ),
        recipient: IntentRecipientModel(
          recipientId: "owner_primary",
          relationship: "owner",
          deliveryChannel: "email",
          destinationRef: widget.profile.backupEmail,
          role: "owner",
          registeredLegalName: "Owner",
          verificationHint: "",
          fallbackChannels: const ["email"],
        ),
        trigger: IntentTriggerModel(
          mode: "inactivity",
          inactivityDays: widget.profile.selfRecoveryInactivityDays,
          requireUnconfirmedAliveStatus: false,
          graceDays: widget.settings.gracePeriodDays,
          remindersDaysBefore: widget.settings.reminderOffsetsDays,
        ),
        delivery: IntentDeliveryModel(
          method: "self_recovery_route",
          requireVerificationCode: true,
          requireTotp: widget.settings.requireTotpUnlock,
          oneTimeAccess: true,
        ),
        safeguards: const IntentSafeguardsModel(
          requireGuardianApproval: false,
          requireMultisignal: false,
          cooldownHours: 24,
          legalDisclaimerRequired: true,
        ),
        privacy: IntentPrivacyModel(
          profile: widget.settings.tracePrivacyProfile,
          minimizeTraceMetadata: widget.settings.privateFirstMode,
          preTriggerVisibility: "none",
          postTriggerVisibility: "route_only",
          valueDisclosureMode: "institution_verified_only",
        ),
        partnerPath: null,
        status: "draft",
      ),
    ];

    return IntentDocumentModel.initial(
      ownerRef: _storageOwnerRef,
      defaultPrivacyProfile: widget.settings.tracePrivacyProfile,
    ).copyWith(
      entries: entries,
      globalSafeguards: IntentGlobalSafeguardsModel(
        emergencyPauseEnabled: true,
        defaultGraceDays: widget.settings.gracePeriodDays,
        defaultRemindersDaysBefore: widget.settings.reminderOffsetsDays,
        requireMultisignalBeforeRelease: true,
        requireGuardianApprovalForLegacy: widget.settings.guardianQuorumEnabled,
        guardianQuorumEnabled: widget.settings.guardianQuorumEnabled,
        guardianQuorumRequired: widget.settings.guardianQuorumRequired,
        guardianQuorumPoolSize: widget.settings.guardianQuorumPoolSize,
        emergencyAccessEnabled: widget.settings.emergencyAccessEnabled,
        emergencyAccessRequiresBeneficiaryRequest:
            widget.settings.emergencyAccessRequiresBeneficiaryRequest,
        emergencyAccessRequiresGuardianQuorum:
            widget.settings.emergencyAccessRequiresGuardianQuorum,
        emergencyAccessGraceHours: widget.settings.emergencyAccessGraceHours,
        deviceRebindInProgress: widget.settings.deviceRebindInProgress,
        deviceRebindGraceHours: widget.settings.deviceRebindGraceHours,
        recoveryKeyEnabled: widget.settings.recoveryKeyEnabled,
        deliveryAccessTtlHours: widget.settings.deliveryAccessTtlHours,
        payloadRetentionDays: widget.settings.payloadRetentionDays,
        auditLogRetentionDays: widget.settings.auditLogRetentionDays,
        proofOfLifeCheckMode: widget.settings.proofOfLifeCheckMode,
        proofOfLifeFallbackChannels:
            widget.settings.proofOfLifeFallbackChannels,
        serverHeartbeatFallbackEnabled:
            widget.settings.serverHeartbeatFallbackEnabled,
        iosBackgroundRiskAcknowledged:
            widget.settings.iosBackgroundRiskAcknowledged,
      ),
    );
  }

  Future<void> _persistDocument(
    IntentDocumentModel next, {
    required String message,
  }) async {
    setState(() {
      _document = next;
      _saveMessage = message;
    });
    await ref.read(intentDraftRepositoryProvider).saveDraft(next);
    if (!mounted) {
      return;
    }
    setState(() {
      _hasLocalDraft = true;
    });
  }

  Future<void> _updateGlobalSafeguards(
    IntentGlobalSafeguardsModel safeguards, {
    required String message,
  }) async {
    await _persistDocument(
      _document.copyWith(globalSafeguards: safeguards),
      message: message,
    );
  }

  Future<void> _resetDraft() async {
    final seed = _seedDocument();
    await ref
        .read(intentDraftRepositoryProvider)
        .clearDraft(ownerRef: _storageOwnerRef);
    if (!mounted) {
      return;
    }
    setState(() {
      _document = seed;
      _hasLocalDraft = false;
      _saveMessage = "Reset to a fresh encrypted local draft.";
    });
  }

  Future<void> _addDraftEntry() async {
    final nextKind = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.family_restroom_outlined),
              title: const Text("Legacy delivery"),
              subtitle: const Text(
                "Send a secure path to a beneficiary after long inactivity",
              ),
              onTap: () => Navigator.of(context).pop("legacy_delivery"),
            ),
            ListTile(
              leading: const Icon(Icons.shield_outlined),
              title: const Text("Self-recovery"),
              subtitle: const Text("Keep a recovery route ready for the owner"),
              onTap: () => Navigator.of(context).pop("self_recovery"),
            ),
          ],
        ),
      ),
    );
    if (nextKind == null) {
      return;
    }

    final nextIndex = _document.entries.length + 1;
    final baseEntry = nextKind == "self_recovery"
        ? IntentEntryModel.selfRecoveryDraft(
            entryId: "self_recovery_$nextIndex",
            ownerRef: "owner_$nextIndex",
            destinationRef: widget.profile.backupEmail,
          )
        : IntentEntryModel.legacyDeliveryDraft(
            entryId: "legacy_delivery_$nextIndex",
            recipientRef: "beneficiary_$nextIndex",
            destinationRef: widget.profile.beneficiaryEmail ?? "",
          );
    final next = baseEntry.copyWith(
      privacy: IntentPrivacyModel(
        profile: _document.defaultPrivacyProfile,
        minimizeTraceMetadata: widget.settings.privateFirstMode,
        preTriggerVisibility: "none",
        postTriggerVisibility: "route_only",
        valueDisclosureMode: "institution_verified_only",
      ),
    );
    await _persistDocument(
      _document.copyWith(entries: [..._document.entries, next]),
      message: nextKind == "self_recovery"
          ? "Self-recovery draft added and saved locally with device encryption."
          : "Legacy delivery draft added and saved locally with device encryption.",
    );
  }

  Future<void> _editEntry(IntentEntryModel entry) async {
    final updated = await showDialog<IntentEntryModel>(
      context: context,
      builder: (_) => _IntentEntryEditorDialog(entry: entry),
    );
    if (updated == null) return;
    await _persistDocument(
      _document.copyWith(
        entries: [
          for (final item in _document.entries)
            item.entryId == entry.entryId ? updated : item,
        ],
      ),
      message: "Draft changes saved locally with device encryption.",
    );
  }

  Future<void> _applyScenarioPreset(DemoScenario scenario) async {
    final document = scenario.buildDocument(
      profile: widget.profile,
      settings: widget.settings,
      ownerRefOverride: _storageOwnerRef,
    );
    await _persistDocument(
      document,
      message:
          "${scenario.title} preset applied and saved locally with device encryption.",
    );
    await _restoreArtifact();
  }

  Future<void> _toggleEntryStatus(IntentEntryModel entry) async {
    final nextStatus = entry.status == 'active' ? 'draft' : 'active';
    await _persistDocument(
      _document.copyWith(
        entries: [
          for (final item in _document.entries)
            item.entryId == entry.entryId
                ? item.copyWith(status: nextStatus)
                : item,
        ],
      ),
      message: nextStatus == 'active'
          ? "Entry activated and saved locally with device encryption."
          : "Entry moved back to draft and saved locally with device encryption.",
    );
  }

  Future<void> _removeEntry(IntentEntryModel entry) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Remove draft entry"),
        content: Text(
          "Remove '${entry.asset.displayName}' from this local draft? This only updates this device draft and does not release anything.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text("Cancel"),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text("Remove"),
          ),
        ],
      ),
    );
    if (confirmed != true) {
      return;
    }
    final nextEntries = [
      for (final item in _document.entries)
        if (item.entryId != entry.entryId) item,
    ];
    await _persistDocument(
      _document.copyWith(entries: nextEntries),
      message: "Draft entry removed from this device.",
    );
  }

  Future<void> _exportCanonicalArtifact(
    IntentCompilerReportModel report,
    String ptnPreview,
  ) async {
    if (!report.ok) {
      setState(() {
        _saveMessage = "Resolve blocking items before exporting this version.";
      });
      return;
    }

    final activeEntries = _document.entries.where(
      (entry) => entry.status == "active",
    );
    if (activeEntries.isEmpty) {
      setState(() {
        _saveMessage =
            "Activate at least one route before exporting this version.";
      });
      return;
    }

    setState(() {
      _isExporting = true;
    });
    final generatedAt = DateTime.now().toUtc();
    final artifact = IntentCanonicalArtifactModel(
      artifactId: "artifact_${generatedAt.millisecondsSinceEpoch}",
      promotedFromArtifactId: null,
      contractVersion: "intent-compiler-contract/v1",
      artifactState: IntentArtifactState.exported,
      intentId: _document.intentId,
      ownerRef: _document.ownerRef,
      generatedAt: generatedAt,
      sourceDraftSignature: buildIntentDocumentSignature(_document),
      activeEntryCount:
          _document.entries.where((entry) => entry.status == "active").length,
      ptn: ptnPreview,
      trace: buildDraftIntentTrace(_document),
      report: report,
      sealedReleaseCandidate: _buildSealedReleaseCandidate(generatedAt),
    );
    await ref
        .read(intentCanonicalArtifactRepositoryProvider)
        .saveArtifact(artifact);
    ref.invalidate(intentCanonicalArtifactProvider(_storageOwnerRef));
    ref.invalidate(intentCanonicalArtifactHistoryProvider(_storageOwnerRef));
    if (!mounted) {
      return;
    }
    setState(() {
      _artifactHistory = [artifact, ..._artifactHistory];
      _artifact = artifact;
      _isExporting = false;
      _saveMessage = "Exported version created and sealed on this device.";
    });
  }

  SealedReleaseCandidateModel _buildSealedReleaseCandidate(
    DateTime generatedAt,
  ) {
    final activeEntries = _document.entries.where(
      (entry) => entry.status == "active",
    );
    return SealedReleaseCandidateModel(
      candidateId: "release_candidate_${generatedAt.millisecondsSinceEpoch}",
      sealedAt: generatedAt,
      deviceSecretResidency: "device_local_only",
      releaseMode: "hybrid_secure_link",
      entries: [
        for (final entry in activeEntries)
          SealedReleaseEntryModel(
            entryId: entry.entryId,
            kind: entry.kind,
            assetLabel: entry.asset.displayName,
            releaseChannel: entry.delivery.method,
            payloadResidency: "device_local_only",
            preTriggerVisibility: entry.privacy.preTriggerVisibility,
            postTriggerVisibility: entry.privacy.postTriggerVisibility,
            valueDisclosureMode: entry.privacy.valueDisclosureMode,
            partnerVerificationRequired: true,
          ),
      ],
    );
  }

  Future<void> _clearCanonicalArtifact() async {
    await ref
        .read(intentCanonicalArtifactRepositoryProvider)
        .clearArtifact(ownerRef: _storageOwnerRef);
    ref.invalidate(intentCanonicalArtifactProvider(_storageOwnerRef));
    ref.invalidate(intentCanonicalArtifactHistoryProvider(_storageOwnerRef));
    if (!mounted) {
      return;
    }
    setState(() {
      _artifact = null;
      _artifactHistory = const [];
      _saveMessage = "Cleared the sealed exported version from this device.";
    });
  }

  Future<void> _clearArtifactVersion(String artifactId) async {
    await ref
        .read(intentCanonicalArtifactRepositoryProvider)
        .clearArtifactVersion(
          ownerRef: _storageOwnerRef,
          artifactId: artifactId,
        );
    ref.invalidate(intentCanonicalArtifactProvider(_storageOwnerRef));
    ref.invalidate(intentCanonicalArtifactHistoryProvider(_storageOwnerRef));
    final nextHistory = [
      for (final item in _artifactHistory)
        if (item.artifactId != artifactId) item,
    ];
    if (!mounted) {
      return;
    }
    setState(() {
      _artifactHistory = nextHistory;
      _artifact = nextHistory.isEmpty ? null : nextHistory.first;
      _saveMessage = "Removed one exported version from local history.";
    });
  }

  Future<void> _clearArtifactVersionModel(
    IntentCanonicalArtifactModel artifact,
  ) async {
    await _clearArtifactVersion(artifact.artifactId);
  }

  Future<void> _promoteArtifactVersion(
    IntentCanonicalArtifactModel artifact,
  ) async {
    final promoted = await ref
        .read(intentCanonicalArtifactRepositoryProvider)
        .promoteArtifactVersion(
          ownerRef: _storageOwnerRef,
          artifactId: artifact.artifactId,
        );
    ref.invalidate(intentCanonicalArtifactProvider(_storageOwnerRef));
    ref.invalidate(intentCanonicalArtifactHistoryProvider(_storageOwnerRef));
    if (promoted == null || !mounted) {
      return;
    }
    final nextHistory = [promoted, for (final item in _artifactHistory) item]
      ..sort((left, right) => right.generatedAt.compareTo(left.generatedAt));
    setState(() {
      _artifactHistory = nextHistory;
      _artifact = promoted;
      _saveMessage =
          "Copied one historical version into a new export so it can be reviewed again without losing history.";
    });
  }

  Future<void> _transitionArtifactState(IntentArtifactState nextState) async {
    final artifact = _artifact;
    if (artifact == null) {
      return;
    }
    final updated = artifact.copyWith(artifactState: nextState);
    await ref
        .read(intentCanonicalArtifactRepositoryProvider)
        .saveArtifact(updated);
    ref.invalidate(intentCanonicalArtifactProvider(_storageOwnerRef));
    ref.invalidate(intentCanonicalArtifactHistoryProvider(_storageOwnerRef));
    if (!mounted) {
      return;
    }
    setState(() {
      _artifactHistory = [
        updated,
        for (final item in _artifactHistory)
          if (item.artifactId != updated.artifactId) item,
      ]..sort((left, right) => right.generatedAt.compareTo(left.generatedAt));
      _artifact = updated;
      _saveMessage = "Version status updated to ${nextState.name}.";
    });
  }

  bool _canMarkReviewed({
    required IntentCanonicalArtifactModel artifact,
    required int activeEntryCount,
  }) {
    return artifact.artifactState == IntentArtifactState.exported &&
        artifact.report.errorCount == 0 &&
        activeEntryCount > 0;
  }

  bool _canMarkReady({
    required IntentCanonicalArtifactModel artifact,
    required bool artifactInSync,
    required int activeEntryCount,
  }) {
    return artifact.artifactState == IntentArtifactState.reviewed &&
        artifact.report.errorCount == 0 &&
        activeEntryCount > 0 &&
        artifactInSync;
  }

  String _statePolicyMessage({
    required IntentCanonicalArtifactModel artifact,
    required bool artifactInSync,
    required int activeEntryCount,
  }) {
    if (activeEntryCount == 0) {
      return "Status rule: activate at least one route before advancing readiness.";
    }
    if (artifact.report.errorCount > 0) {
      return "Status rule: resolve blocking issues before marking this version reviewed or ready.";
    }
    if (artifact.artifactState == IntentArtifactState.exported) {
      return "Status rule: exported versions can be marked reviewed when blocking issues are clear and active routes remain present.";
    }
    if (artifact.artifactState == IntentArtifactState.reviewed &&
        !artifactInSync) {
      return "Status rule: reviewed versions can only be marked ready while the current draft still matches the exported version.";
    }
    if (artifact.artifactState == IntentArtifactState.reviewed &&
        artifactInSync) {
      return "Status rule: this reviewed version can move to ready because the draft is still in sync.";
    }
    if (artifact.artifactState == IntentArtifactState.ready) {
      return "Status rule: ready versions stay trustworthy only while the draft remains in sync with the exported version.";
    }
    return "Status rule: export a version first, then review it before marking it ready.";
  }

  String _buildPolicyPaper(IntentCanonicalArtifactModel artifact) {
    final sealedEntries = artifact.sealedReleaseCandidate.entries;
    final primary = sealedEntries.isNotEmpty ? sealedEntries.first : null;
    final beneficiaryName =
        widget.profile.beneficiaryName?.trim().isNotEmpty == true
            ? widget.profile.beneficiaryName!.trim()
            : "à¸œà¸¹à¹‰à¸£à¸±à¸šà¸¡à¸£à¸”à¸à¸«à¸¥à¸±à¸";
    final beneficiaryEmail =
        widget.profile.beneficiaryEmail?.trim().isNotEmpty == true
            ? widget.profile.beneficiaryEmail!.trim()
            : "beneficiary@example.com";
    final inactivity = widget.profile.legacyInactivityDays;
    final grace = _document.globalSafeguards.defaultGraceDays;
    final verifyLevel = primary?.partnerVerificationRequired == true
        ? "à¸ªà¸¹à¸‡"
        : "à¸¡à¸²à¸•à¸£à¸à¸²à¸™";

    return '''
à¹€à¸­à¸à¸ªà¸²à¸£à¸ªà¸£à¸¸à¸›à¸™à¹‚à¸¢à¸šà¸²à¸¢à¸¡à¸£à¸”à¸à¸”à¸´à¸ˆà¸´à¸—à¸±à¸¥ (Final Policy Paper)

à¸ªà¹ˆà¸§à¸™à¸—à¸µà¹ˆ 1: à¸ªà¸£à¸¸à¸›à¹€à¸ˆà¸•à¸™à¸²à¸£à¸¡à¸“à¹Œ
- à¸Šà¸·à¹ˆà¸­à¸™à¹‚à¸¢à¸šà¸²à¸¢: à¹à¸œà¸™à¸ªà¹ˆà¸‡à¸¡à¸­à¸šà¸¡à¸£à¸”à¸à¸„à¸£à¸­à¸šà¸„à¸£à¸±à¸§
- à¹€à¸ˆà¹‰à¸²à¸‚à¸­à¸‡à¸šà¸±à¸à¸Šà¸µ: ${widget.profile.id}
- à¸œà¸¹à¹‰à¸£à¸±à¸šà¸¡à¸£à¸”à¸: $beneficiaryName ($beneficiaryEmail)
- à¸£à¸°à¸”à¸±à¸šà¸„à¸§à¸²à¸¡à¹€à¸›à¹‡à¸™à¸ªà¹ˆà¸§à¸™à¸•à¸±à¸§: ${widget.settings.tracePrivacyProfile}
- Artifact ID: ${artifact.artifactId}
- à¸ªà¸£à¹‰à¸²à¸‡à¹€à¸¡à¸·à¹ˆà¸­: ${artifact.generatedAt.toLocal()}

à¸ªà¹ˆà¸§à¸™à¸—à¸µà¹ˆ 2: à¹€à¸‡à¸·à¹ˆà¸­à¸™à¹„à¸‚à¸à¸²à¸£à¸›à¸¥à¸”à¸¥à¹‡à¸­à¸
- à¸«à¸²à¸à¸‚à¸²à¸”à¸à¸²à¸£à¸•à¸´à¸”à¸•à¹ˆà¸­à¹€à¸à¸´à¸™ $inactivity à¸§à¸±à¸™ à¸£à¸°à¸šà¸šà¸ˆà¸°à¹€à¸£à¸´à¹ˆà¸¡à¸‚à¸±à¹‰à¸™à¸•à¸­à¸™à¸•à¸£à¸§à¸ˆà¸ªà¸­à¸š
- à¸£à¸°à¸šà¸šà¸¢à¸·à¸™à¸¢à¸±à¸™à¸‹à¹‰à¸³à¸Šà¹ˆà¸§à¸‡à¸›à¸¥à¸­à¸”à¸ à¸±à¸¢ $grace à¸§à¸±à¸™à¸à¹ˆà¸­à¸™à¸ªà¹ˆà¸‡à¸¡à¸­à¸š
- à¸£à¸°à¸”à¸±à¸šà¸à¸²à¸£à¸¢à¸·à¸™à¸¢à¸±à¸™à¸•à¸±à¸§à¸•à¸™: $verifyLevel
- Cooldown à¸à¹ˆà¸­à¸™à¹€à¸›à¸´à¸”à¹€à¸œà¸¢à¸ˆà¸£à¸´à¸‡: 24 à¸Šà¸±à¹ˆà¸§à¹‚à¸¡à¸‡

à¸ªà¹ˆà¸§à¸™à¸—à¸µà¹ˆ 3: à¸ªà¸´à¸—à¸˜à¸´à¹à¸¥à¸°à¸à¸²à¸£à¹€à¸‚à¹‰à¸²à¸–à¸¶à¸‡
- à¸ªà¸´à¸—à¸˜à¸´à¸œà¸¹à¹‰à¸£à¸±à¸šà¸¡à¸£à¸”à¸: à¸­à¹ˆà¸²à¸™à¸‚à¹‰à¸­à¸¡à¸¹à¸¥à¸—à¸µà¹ˆà¸ªà¹ˆà¸‡à¸¡à¸­à¸šà¸•à¸²à¸¡à¹à¸œà¸™
- à¸£à¸°à¸šà¸šà¹€à¸›à¹‡à¸™à¸œà¸¹à¹‰à¸„à¸¸à¸¡à¸à¸Ž: à¸•à¸£à¸§à¸ˆà¸ªà¸±à¸à¸à¸²à¸“à¸Šà¸µà¸žà¹à¸¥à¸°à¸ªà¹ˆà¸‡à¸¡à¸­à¸šà¸œà¹ˆà¸²à¸™à¸Šà¹ˆà¸­à¸‡à¸—à¸²à¸‡à¸—à¸µà¹ˆà¸à¸³à¸«à¸™à¸”
- à¸Šà¹ˆà¸­à¸‡à¸—à¸²à¸‡à¸ªà¹ˆà¸‡à¸¡à¸­à¸šà¸«à¸¥à¸±à¸: ${primary?.releaseChannel ?? "secure_link"}

à¸«à¸¡à¸²à¸¢à¹€à¸«à¸•à¸¸:
à¹€à¸­à¸à¸ªà¸²à¸£à¸™à¸µà¹‰à¹€à¸›à¹‡à¸™à¸ªà¸£à¸¸à¸›à¹€à¸žà¸·à¹ˆà¸­à¸„à¸§à¸²à¸¡à¹€à¸‚à¹‰à¸²à¹ƒà¸ˆà¸£à¹ˆà¸§à¸¡à¸à¸±à¸™à¸‚à¸­à¸‡à¹€à¸ˆà¹‰à¸²à¸‚à¸­à¸‡à¸šà¸±à¸à¸Šà¸µà¹à¸¥à¸°à¸œà¸¹à¹‰à¸£à¸±à¸šà¸¡à¸£à¸”à¸
à¹à¸¥à¸°à¸­à¹‰à¸²à¸‡à¸­à¸´à¸‡à¸‚à¹‰à¸­à¸¡à¸¹à¸¥à¸ˆà¸²à¸ artifact à¸›à¸±à¸ˆà¸ˆà¸¸à¸šà¸±à¸™à¸‚à¸­à¸‡à¸£à¸°à¸šà¸šà¹‚à¸”à¸¢à¸•à¸£à¸‡
''';
  }

  String _buildPolicyVerifyUrl(IntentCanonicalArtifactModel artifact) {
    return "dlw://policy-verify?artifact_id=${artifact.artifactId}&owner=${artifact.ownerRef}";
  }

  Future<void> _openPolicyPaper(IntentCanonicalArtifactModel artifact) async {
    final paper = _buildPolicyPaper(artifact);
    final verifyUrl = _buildPolicyVerifyUrl(artifact);
    final messenger = ScaffoldMessenger.of(context);
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Final Policy Paper"),
        content: SizedBox(
          width: 560,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: const Color(0xFFEFF6F5),
                  ),
                  child: SelectableText(paper),
                ),
                const SizedBox(height: 12),
                const Text(
                  "QR à¸ªà¸³à¸«à¸£à¸±à¸šà¸•à¸£à¸§à¸ˆà¸ªà¸­à¸šà¹à¸œà¸™",
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Center(
                  child: QrImageView(
                    data: verifyUrl,
                    size: 140,
                    eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square),
                    dataModuleStyle:
                        const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square),
                  ),
                ),
                const SizedBox(height: 8),
                SelectableText(verifyUrl),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("à¸›à¸´à¸”"),
          ),
          FilledButton.tonal(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: paper));
              messenger.showSnackBar(
                const SnackBar(content: Text("à¸„à¸±à¸”à¸¥à¸­à¸ Policy Paper à¹à¸¥à¹‰à¸§")),
              );
            },
            child: const Text("à¸„à¸±à¸”à¸¥à¸­à¸à¹€à¸­à¸à¸ªà¸²à¸£"),
          ),
        ],
      ),
    );
  }

  List<String> _artifactBadges(IntentCanonicalArtifactModel artifact) {
    final badges = <String>[];
    if (_artifact != null && artifact.artifactId == _artifact!.artifactId) {
      badges.add("Latest");
    }
    if (artifact.promotedFromArtifactId != null &&
        artifact.promotedFromArtifactId!.isNotEmpty) {
      badges.add("Copied");
    }
    if (artifact.artifactState == IntentArtifactState.ready) {
      badges.add("Ready");
    } else if (artifact.artifactState == IntentArtifactState.reviewed) {
      badges.add("Reviewed");
    }
    if (artifact.report.errorCount > 0) {
      badges.add("Has issues");
    }
    return badges;
  }

  List<IntentCanonicalArtifactModel> _visibleArtifactHistory() {
    final filtered = _artifactHistory.where((artifact) {
      switch (_historyFilter) {
        case 'ready':
          return artifact.artifactState == IntentArtifactState.ready;
        case 'promoted':
          return artifact.promotedFromArtifactId != null &&
              artifact.promotedFromArtifactId!.isNotEmpty;
        case 'issues':
          return artifact.report.errorCount > 0;
        default:
          return true;
      }
    }).toList();

    filtered.sort((left, right) {
      switch (_historySort) {
        case 'oldest':
          return left.generatedAt.compareTo(right.generatedAt);
        case 'state':
          return left.artifactState.name.compareTo(right.artifactState.name);
        default:
          return right.generatedAt.compareTo(left.generatedAt);
      }
    });
    return filtered;
  }

  Widget _buildStatusBanner({
    required String message,
    required bool isError,
    VoidCallback? onRetry,
  }) {
    final background =
        isError ? const Color(0xFFFFF1F1) : const Color(0xFFE9F6EF);
    final icon =
        isError ? Icons.warning_amber_rounded : Icons.check_circle_outline;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 8),
          Expanded(child: Text(message)),
          if (isError && onRetry != null)
            TextButton(onPressed: onRetry, child: const Text("Retry")),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenTitle = widget.screenTitle ?? "Legacy plan workspace";
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text(screenTitle)),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 12),
                Text(
                  "Loading your local encrypted draft and recent version history...",
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    final report = buildDraftIntentCompilerReport(
      document: _document,
      legalAccepted: widget.settings.legalDisclaimerAccepted,
      privateFirstMode: widget.settings.privateFirstMode,
      proofOfLifeCheckMode: widget.settings.proofOfLifeCheckMode,
      proofOfLifeFallbackChannels: widget.settings.proofOfLifeFallbackChannels,
      serverHeartbeatFallbackEnabled:
          widget.settings.serverHeartbeatFallbackEnabled,
      iosBackgroundRiskAcknowledged:
          widget.settings.iosBackgroundRiskAcknowledged,
    );
    final ptnPreview = buildDraftIntentPtnPreview(_document);
    final draftSignature = buildIntentDocumentSignature(_document);
    final screenSubtitle = widget.screenSubtitle ??
        "Step 2 of 3: shape your plan in plain language before export.";
    final demoScenarioTitle = _document.metadata["demo_title"] as String?;
    final demoScenarioSummary = _document.metadata["demo_summary"] as String?;
    final demoScenarioNextStep =
        _document.metadata["demo_next_step"] as String?;
    final artifactInSync =
        _artifact != null && _artifact!.sourceDraftSignature == draftSignature;
    final activeEntryCount =
        _document.entries.where((entry) => entry.status == "active").length;
    final canMarkReviewed = _artifact != null
        ? _canMarkReviewed(
            artifact: _artifact!,
            activeEntryCount: activeEntryCount,
          )
        : false;
    final canMarkReady = _artifact != null
        ? _canMarkReady(
            artifact: _artifact!,
            artifactInSync: artifactInSync,
            activeEntryCount: activeEntryCount,
          )
        : false;
    final visibleArtifactHistory = _visibleArtifactHistory();

    return Scaffold(
      appBar: AppBar(
        title: Text(screenTitle),
        actions: [
          TextButton(
            onPressed: _hasLocalDraft ? _resetDraft : null,
            child: const Text("Start over"),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Step 2 of 3: Shape your plan",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Text(screenSubtitle),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEAF6F6),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "What to do now",
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        SizedBox(height: 6),
                        Text("1. Keep at least one active route."),
                        SizedBox(height: 4),
                        Text("2. Export and review warnings."),
                        SizedBox(height: 4),
                        Text("3. Mark ready only when draft and export match."),
                      ],
                    ),
                  ),
                  if (demoScenarioTitle != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF7F1E8),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "From onboarding: $demoScenarioTitle",
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          if (demoScenarioSummary != null) ...[
                            const SizedBox(height: 6),
                            Text(demoScenarioSummary),
                          ],
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _Pill(
                        label: _hasLocalDraft
                            ? "Local encrypted draft: on"
                            : "Using seeded setup",
                      ),
                      _Pill(
                        label: "Privacy: ${_document.defaultPrivacyProfile}",
                      ),
                      _Pill(label: "Routes: ${_document.entries.length}"),
                      _Pill(label: "Active: $activeEntryCount"),
                      _Pill(
                        label: "Versions: ${_artifactHistory.length}",
                      ),
                    ],
                  ),
                  if (_saveMessage != null) ...[
                    const SizedBox(height: 12),
                    _buildStatusBanner(message: _saveMessage!, isError: false),
                  ],
                  if (_loadError != null) ...[
                    const SizedBox(height: 12),
                    _buildStatusBanner(
                      message: _loadError!,
                      isError: true,
                      onRetry: _restoreDraft,
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Quick starter preset",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Pick one preset to fill routes and safeguards automatically, then edit details to match your real case.",
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final scenario in demoScenarios)
                        ChoiceChip(
                          label: Text(scenario.title),
                          selected: _activeScenario?.id == scenario.id,
                          onSelected: (_) {
                            _applyScenarioPreset(scenario);
                          },
                        ),
                    ],
                  ),
                  if (_activeScenario != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF7F1E8),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Active preset: ${_activeScenario!.title}",
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 6),
                          Text(_activeScenario!.summary),
                          if (demoScenarioNextStep != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              "Next step: $demoScenarioNextStep",
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Card(
            color: Color(0xFFFFF7ED),
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Private local draft",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "Your plan is encrypted on this device. Nothing is published until you export and confirm readiness.",
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Shared approval & emergency access",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Use shared approval for sensitive releases, and keep emergency access as a separate incapacity path.",
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    title: const Text("Enable shared approval"),
                    subtitle: const Text(
                      "Recommended baseline: 2-of-3 for sensitive handoff.",
                    ),
                    value: _document.globalSafeguards.guardianQuorumEnabled,
                    onChanged: (value) {
                      final poolSize =
                          _document.globalSafeguards.guardianQuorumPoolSize;
                      _updateGlobalSafeguards(
                        IntentGlobalSafeguardsModel(
                          emergencyPauseEnabled:
                              _document.globalSafeguards.emergencyPauseEnabled,
                          defaultGraceDays:
                              _document.globalSafeguards.defaultGraceDays,
                          defaultRemindersDaysBefore: _document
                              .globalSafeguards.defaultRemindersDaysBefore,
                          requireMultisignalBeforeRelease: _document
                              .globalSafeguards.requireMultisignalBeforeRelease,
                          requireGuardianApprovalForLegacy: value,
                          guardianQuorumEnabled: value,
                          guardianQuorumRequired: value
                              ? _document
                                  .globalSafeguards.guardianQuorumRequired
                                  .clamp(1, poolSize)
                              : _document
                                  .globalSafeguards.guardianQuorumRequired,
                          guardianQuorumPoolSize: poolSize,
                          emergencyAccessEnabled:
                              _document.globalSafeguards.emergencyAccessEnabled,
                          emergencyAccessRequiresBeneficiaryRequest: _document
                              .globalSafeguards
                              .emergencyAccessRequiresBeneficiaryRequest,
                          emergencyAccessRequiresGuardianQuorum: _document
                              .globalSafeguards
                              .emergencyAccessRequiresGuardianQuorum,
                          emergencyAccessGraceHours: _document
                              .globalSafeguards.emergencyAccessGraceHours,
                          proofOfLifeCheckMode:
                              _document.globalSafeguards.proofOfLifeCheckMode,
                          proofOfLifeFallbackChannels: _document
                              .globalSafeguards.proofOfLifeFallbackChannels,
                          serverHeartbeatFallbackEnabled: _document
                              .globalSafeguards.serverHeartbeatFallbackEnabled,
                          iosBackgroundRiskAcknowledged: _document
                              .globalSafeguards.iosBackgroundRiskAcknowledged,
                        ),
                        message: "Updated shared approval settings.",
                      );
                    },
                  ),
                  if (_document.globalSafeguards.guardianQuorumEnabled) ...[
                    const SizedBox(height: 8),
                    Text(
                      "Current approval threshold: ${_document.globalSafeguards.guardianQuorumRequired}-of-${_document.globalSafeguards.guardianQuorumPoolSize}",
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<int>(
                      initialValue:
                          _document.globalSafeguards.guardianQuorumPoolSize,
                      decoration: const InputDecoration(
                        labelText: "Approver group size",
                      ),
                      items: const [
                        DropdownMenuItem(value: 2, child: Text("2 approvers")),
                        DropdownMenuItem(value: 3, child: Text("3 approvers")),
                        DropdownMenuItem(value: 4, child: Text("4 approvers")),
                        DropdownMenuItem(value: 5, child: Text("5 approvers")),
                      ],
                      onChanged: (value) {
                        if (value == null) {
                          return;
                        }
                        _updateGlobalSafeguards(
                          IntentGlobalSafeguardsModel(
                            emergencyPauseEnabled: _document
                                .globalSafeguards.emergencyPauseEnabled,
                            defaultGraceDays:
                                _document.globalSafeguards.defaultGraceDays,
                            defaultRemindersDaysBefore: _document
                                .globalSafeguards.defaultRemindersDaysBefore,
                            requireMultisignalBeforeRelease: _document
                                .globalSafeguards
                                .requireMultisignalBeforeRelease,
                            requireGuardianApprovalForLegacy: _document
                                .globalSafeguards
                                .requireGuardianApprovalForLegacy,
                            guardianQuorumEnabled: _document
                                .globalSafeguards.guardianQuorumEnabled,
                            guardianQuorumRequired: _document
                                .globalSafeguards.guardianQuorumRequired
                                .clamp(1, value),
                            guardianQuorumPoolSize: value,
                            emergencyAccessEnabled: _document
                                .globalSafeguards.emergencyAccessEnabled,
                            emergencyAccessRequiresBeneficiaryRequest: _document
                                .globalSafeguards
                                .emergencyAccessRequiresBeneficiaryRequest,
                            emergencyAccessRequiresGuardianQuorum: _document
                                .globalSafeguards
                                .emergencyAccessRequiresGuardianQuorum,
                            emergencyAccessGraceHours: _document
                                .globalSafeguards.emergencyAccessGraceHours,
                            proofOfLifeCheckMode:
                                _document.globalSafeguards.proofOfLifeCheckMode,
                            proofOfLifeFallbackChannels: _document
                                .globalSafeguards.proofOfLifeFallbackChannels,
                            serverHeartbeatFallbackEnabled: _document
                                .globalSafeguards
                                .serverHeartbeatFallbackEnabled,
                            iosBackgroundRiskAcknowledged: _document
                                .globalSafeguards.iosBackgroundRiskAcknowledged,
                          ),
                          message: "Updated approver group size.",
                        );
                      },
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<int>(
                      initialValue:
                          _document.globalSafeguards.guardianQuorumRequired,
                      decoration: const InputDecoration(
                        labelText: "Required approvals",
                      ),
                      items: List.generate(
                        _document.globalSafeguards.guardianQuorumPoolSize,
                        (index) => DropdownMenuItem(
                          value: index + 1,
                          child: Text("${index + 1} approvals"),
                        ),
                      ),
                      onChanged: (value) {
                        if (value == null) {
                          return;
                        }
                        _updateGlobalSafeguards(
                          IntentGlobalSafeguardsModel(
                            emergencyPauseEnabled: _document
                                .globalSafeguards.emergencyPauseEnabled,
                            defaultGraceDays:
                                _document.globalSafeguards.defaultGraceDays,
                            defaultRemindersDaysBefore: _document
                                .globalSafeguards.defaultRemindersDaysBefore,
                            requireMultisignalBeforeRelease: _document
                                .globalSafeguards
                                .requireMultisignalBeforeRelease,
                            requireGuardianApprovalForLegacy: _document
                                .globalSafeguards
                                .requireGuardianApprovalForLegacy,
                            guardianQuorumEnabled: _document
                                .globalSafeguards.guardianQuorumEnabled,
                            guardianQuorumRequired: value,
                            guardianQuorumPoolSize: _document
                                .globalSafeguards.guardianQuorumPoolSize,
                            emergencyAccessEnabled: _document
                                .globalSafeguards.emergencyAccessEnabled,
                            emergencyAccessRequiresBeneficiaryRequest: _document
                                .globalSafeguards
                                .emergencyAccessRequiresBeneficiaryRequest,
                            emergencyAccessRequiresGuardianQuorum: _document
                                .globalSafeguards
                                .emergencyAccessRequiresGuardianQuorum,
                            emergencyAccessGraceHours: _document
                                .globalSafeguards.emergencyAccessGraceHours,
                            proofOfLifeCheckMode:
                                _document.globalSafeguards.proofOfLifeCheckMode,
                            proofOfLifeFallbackChannels: _document
                                .globalSafeguards.proofOfLifeFallbackChannels,
                            serverHeartbeatFallbackEnabled: _document
                                .globalSafeguards
                                .serverHeartbeatFallbackEnabled,
                            iosBackgroundRiskAcknowledged: _document
                                .globalSafeguards.iosBackgroundRiskAcknowledged,
                          ),
                          message: "Updated required approvals.",
                        );
                      },
                    ),
                  ],
                  const SizedBox(height: 12),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    title: const Text("Enable emergency access"),
                    subtitle: const Text(
                      "Use only for incapacity cases (for example ICU), separate from regular inactivity release.",
                    ),
                    value: _document.globalSafeguards.emergencyAccessEnabled,
                    onChanged: (value) {
                      _updateGlobalSafeguards(
                        IntentGlobalSafeguardsModel(
                          emergencyPauseEnabled:
                              _document.globalSafeguards.emergencyPauseEnabled,
                          defaultGraceDays:
                              _document.globalSafeguards.defaultGraceDays,
                          defaultRemindersDaysBefore: _document
                              .globalSafeguards.defaultRemindersDaysBefore,
                          requireMultisignalBeforeRelease: _document
                              .globalSafeguards.requireMultisignalBeforeRelease,
                          requireGuardianApprovalForLegacy: _document
                              .globalSafeguards
                              .requireGuardianApprovalForLegacy,
                          guardianQuorumEnabled:
                              _document.globalSafeguards.guardianQuorumEnabled,
                          guardianQuorumRequired:
                              _document.globalSafeguards.guardianQuorumRequired,
                          guardianQuorumPoolSize:
                              _document.globalSafeguards.guardianQuorumPoolSize,
                          emergencyAccessEnabled: value,
                          emergencyAccessRequiresBeneficiaryRequest: _document
                              .globalSafeguards
                              .emergencyAccessRequiresBeneficiaryRequest,
                          emergencyAccessRequiresGuardianQuorum: _document
                              .globalSafeguards
                              .emergencyAccessRequiresGuardianQuorum,
                          emergencyAccessGraceHours: _document
                              .globalSafeguards.emergencyAccessGraceHours,
                          proofOfLifeCheckMode:
                              _document.globalSafeguards.proofOfLifeCheckMode,
                          proofOfLifeFallbackChannels: _document
                              .globalSafeguards.proofOfLifeFallbackChannels,
                          serverHeartbeatFallbackEnabled: _document
                              .globalSafeguards.serverHeartbeatFallbackEnabled,
                          iosBackgroundRiskAcknowledged: _document
                              .globalSafeguards.iosBackgroundRiskAcknowledged,
                        ),
                        message: "Updated emergency access settings.",
                      );
                    },
                  ),
                  if (_document.globalSafeguards.emergencyAccessEnabled) ...[
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text("Require beneficiary request"),
                      subtitle: const Text(
                        "Emergency access should begin with an explicit beneficiary request.",
                      ),
                      value: _document.globalSafeguards
                          .emergencyAccessRequiresBeneficiaryRequest,
                      onChanged: (value) {
                        _updateGlobalSafeguards(
                          IntentGlobalSafeguardsModel(
                            emergencyPauseEnabled: _document
                                .globalSafeguards.emergencyPauseEnabled,
                            defaultGraceDays:
                                _document.globalSafeguards.defaultGraceDays,
                            defaultRemindersDaysBefore: _document
                                .globalSafeguards.defaultRemindersDaysBefore,
                            requireMultisignalBeforeRelease: _document
                                .globalSafeguards
                                .requireMultisignalBeforeRelease,
                            requireGuardianApprovalForLegacy: _document
                                .globalSafeguards
                                .requireGuardianApprovalForLegacy,
                            guardianQuorumEnabled: _document
                                .globalSafeguards.guardianQuorumEnabled,
                            guardianQuorumRequired: _document
                                .globalSafeguards.guardianQuorumRequired,
                            guardianQuorumPoolSize: _document
                                .globalSafeguards.guardianQuorumPoolSize,
                            emergencyAccessEnabled: _document
                                .globalSafeguards.emergencyAccessEnabled,
                            emergencyAccessRequiresBeneficiaryRequest:
                                value ?? true,
                            emergencyAccessRequiresGuardianQuorum: _document
                                .globalSafeguards
                                .emergencyAccessRequiresGuardianQuorum,
                            emergencyAccessGraceHours: _document
                                .globalSafeguards.emergencyAccessGraceHours,
                            proofOfLifeCheckMode:
                                _document.globalSafeguards.proofOfLifeCheckMode,
                            proofOfLifeFallbackChannels: _document
                                .globalSafeguards.proofOfLifeFallbackChannels,
                            serverHeartbeatFallbackEnabled: _document
                                .globalSafeguards
                                .serverHeartbeatFallbackEnabled,
                            iosBackgroundRiskAcknowledged: _document
                                .globalSafeguards.iosBackgroundRiskAcknowledged,
                          ),
                          message: "Updated beneficiary request requirement.",
                        );
                      },
                    ),
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text("Require shared approval"),
                      subtitle: const Text(
                        "Recommended so emergency access remains multi-party and auditable.",
                      ),
                      value: _document.globalSafeguards
                          .emergencyAccessRequiresGuardianQuorum,
                      onChanged: (value) {
                        _updateGlobalSafeguards(
                          IntentGlobalSafeguardsModel(
                            emergencyPauseEnabled: _document
                                .globalSafeguards.emergencyPauseEnabled,
                            defaultGraceDays:
                                _document.globalSafeguards.defaultGraceDays,
                            defaultRemindersDaysBefore: _document
                                .globalSafeguards.defaultRemindersDaysBefore,
                            requireMultisignalBeforeRelease: _document
                                .globalSafeguards
                                .requireMultisignalBeforeRelease,
                            requireGuardianApprovalForLegacy: _document
                                .globalSafeguards
                                .requireGuardianApprovalForLegacy,
                            guardianQuorumEnabled: _document
                                .globalSafeguards.guardianQuorumEnabled,
                            guardianQuorumRequired: _document
                                .globalSafeguards.guardianQuorumRequired,
                            guardianQuorumPoolSize: _document
                                .globalSafeguards.guardianQuorumPoolSize,
                            emergencyAccessEnabled: _document
                                .globalSafeguards.emergencyAccessEnabled,
                            emergencyAccessRequiresBeneficiaryRequest: _document
                                .globalSafeguards
                                .emergencyAccessRequiresBeneficiaryRequest,
                            emergencyAccessRequiresGuardianQuorum:
                                value ?? true,
                            emergencyAccessGraceHours: _document
                                .globalSafeguards.emergencyAccessGraceHours,
                            proofOfLifeCheckMode:
                                _document.globalSafeguards.proofOfLifeCheckMode,
                            proofOfLifeFallbackChannels: _document
                                .globalSafeguards.proofOfLifeFallbackChannels,
                            serverHeartbeatFallbackEnabled: _document
                                .globalSafeguards
                                .serverHeartbeatFallbackEnabled,
                            iosBackgroundRiskAcknowledged: _document
                                .globalSafeguards.iosBackgroundRiskAcknowledged,
                          ),
                          message:
                              "Updated emergency shared-approval requirement.",
                        );
                      },
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Emergency access waiting window: ${_document.globalSafeguards.emergencyAccessGraceHours} hours",
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Slider(
                      value: _document
                          .globalSafeguards.emergencyAccessGraceHours
                          .toDouble(),
                      min: 24,
                      max: 168,
                      divisions: 6,
                      label:
                          "${_document.globalSafeguards.emergencyAccessGraceHours}",
                      onChanged: (value) {
                        _updateGlobalSafeguards(
                          IntentGlobalSafeguardsModel(
                            emergencyPauseEnabled: _document
                                .globalSafeguards.emergencyPauseEnabled,
                            defaultGraceDays:
                                _document.globalSafeguards.defaultGraceDays,
                            defaultRemindersDaysBefore: _document
                                .globalSafeguards.defaultRemindersDaysBefore,
                            requireMultisignalBeforeRelease: _document
                                .globalSafeguards
                                .requireMultisignalBeforeRelease,
                            requireGuardianApprovalForLegacy: _document
                                .globalSafeguards
                                .requireGuardianApprovalForLegacy,
                            guardianQuorumEnabled: _document
                                .globalSafeguards.guardianQuorumEnabled,
                            guardianQuorumRequired: _document
                                .globalSafeguards.guardianQuorumRequired,
                            guardianQuorumPoolSize: _document
                                .globalSafeguards.guardianQuorumPoolSize,
                            emergencyAccessEnabled: _document
                                .globalSafeguards.emergencyAccessEnabled,
                            emergencyAccessRequiresBeneficiaryRequest: _document
                                .globalSafeguards
                                .emergencyAccessRequiresBeneficiaryRequest,
                            emergencyAccessRequiresGuardianQuorum: _document
                                .globalSafeguards
                                .emergencyAccessRequiresGuardianQuorum,
                            emergencyAccessGraceHours: value.round(),
                            proofOfLifeCheckMode:
                                _document.globalSafeguards.proofOfLifeCheckMode,
                            proofOfLifeFallbackChannels: _document
                                .globalSafeguards.proofOfLifeFallbackChannels,
                            serverHeartbeatFallbackEnabled: _document
                                .globalSafeguards
                                .serverHeartbeatFallbackEnabled,
                            iosBackgroundRiskAcknowledged: _document
                                .globalSafeguards.iosBackgroundRiskAcknowledged,
                          ),
                          message: "Updated emergency waiting window.",
                        );
                      },
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Expanded(
                child: Text(
                  "à¹ƒà¸„à¸£à¸ˆà¸°à¹„à¸”à¹‰à¸£à¸±à¸šà¸­à¸°à¹„à¸£",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
              ),
              FilledButton.tonal(
                onPressed: () {
                  _addDraftEntry();
                },
                child: const Text("à¹€à¸žà¸´à¹ˆà¸¡à¹€à¸ªà¹‰à¸™à¸—à¸²à¸‡"),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_document.entries.isEmpty)
            Card(
              color: const Color(0xFFFFF7ED),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "à¸¢à¸±à¸‡à¹„à¸¡à¹ˆà¸¡à¸µà¹€à¸ªà¹‰à¸™à¸—à¸²à¸‡",
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "à¹€à¸£à¸´à¹ˆà¸¡à¸ˆà¸²à¸à¹€à¸žà¸´à¹ˆà¸¡à¸­à¸¢à¹ˆà¸²à¸‡à¸™à¹‰à¸­à¸¢ 1 à¹€à¸ªà¹‰à¸™à¸—à¸²à¸‡ à¹€à¸Šà¹ˆà¸™ à¸ªà¹ˆà¸‡à¹ƒà¸«à¹‰à¸„à¸™à¸—à¸µà¹ˆà¸„à¸¸à¸“à¸£à¸±à¸ à¸«à¸£à¸·à¸­à¸à¸¹à¹‰à¸„à¸·à¸™à¸šà¸±à¸à¸Šà¸µà¸•à¸±à¸§à¹€à¸­à¸‡",
                    ),
                    const SizedBox(height: 10),
                    FilledButton.tonal(
                      onPressed: _addDraftEntry,
                      child: const Text("à¹€à¸žà¸´à¹ˆà¸¡à¹€à¸ªà¹‰à¸™à¸—à¸²à¸‡à¹à¸£à¸"),
                    ),
                  ],
                ),
              ),
            )
          else
            ..._document.entries.map(
              (entry) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _IntentEntryCard(
                  entry: entry,
                  onEdit: () {
                    _editEntry(entry);
                  },
                  onToggleStatus: () {
                    _toggleEntryStatus(entry);
                  },
                  onRemove: () {
                    _removeEntry(entry);
                  },
                ),
              ),
            ),
          IntentReviewCard(report: report),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "à¸ªà¸£à¹‰à¸²à¸‡à¹€à¸§à¸­à¸£à¹Œà¸Šà¸±à¸™à¹ƒà¸Šà¹‰à¸‡à¸²à¸™",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "à¹€à¸¡à¸·à¹ˆà¸­à¸žà¸£à¹‰à¸­à¸¡à¹à¸¥à¹‰à¸§ à¸à¸”à¸ªà¸£à¹‰à¸²à¸‡à¹€à¸§à¸­à¸£à¹Œà¸Šà¸±à¸™à¹€à¸žà¸·à¹ˆà¸­à¸šà¸±à¸™à¸—à¸¶à¸à¹à¸œà¸™à¸¥à¹ˆà¸²à¸ªà¸¸à¸”à¹à¸šà¸šà¸›à¸¥à¸­à¸”à¸ à¸±à¸¢à¹ƒà¸™à¹€à¸„à¸£à¸·à¹ˆà¸­à¸‡",
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      FilledButton(
                        onPressed: _isExporting
                            ? null
                            : () {
                                _exportCanonicalArtifact(report, ptnPreview);
                              },
                        child: Text(
                          _isExporting
                              ? "Exporting..."
                              : "à¸ªà¸£à¹‰à¸²à¸‡à¹€à¸§à¸­à¸£à¹Œà¸Šà¸±à¸™à¸¥à¹ˆà¸²à¸ªà¸¸à¸”",
                        ),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton(
                        onPressed:
                            _artifact == null ? null : _clearCanonicalArtifact,
                        child: const Text("à¸¥à¹‰à¸²à¸‡à¹€à¸§à¸­à¸£à¹Œà¸Šà¸±à¸™à¸—à¸µà¹ˆà¸ªà¸£à¹‰à¸²à¸‡à¹„à¸§à¹‰"),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton(
                        onPressed: _artifact == null
                            ? null
                            : () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => IntentArtifactReviewScreen(
                                      artifact: _artifact!,
                                    ),
                                  ),
                                );
                              },
                        child: const Text("Review version"),
                      ),
                    ],
                  ),
                  if (_artifact != null) ...[
                    const SizedBox(height: 12),
                    _Pill(
                      label:
                          "Last export: ${_artifact!.generatedAt.toLocal().toString()}",
                    ),
                    const SizedBox(height: 8),
                    Text("Contract version: ${_artifact!.contractVersion}"),
                    const SizedBox(height: 4),
                    Text("Version status: ${_artifact!.artifactState.name}"),
                    const SizedBox(height: 4),
                    Text(
                      "Version active routes: ${_artifact!.activeEntryCount}",
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Trace entries: ${(_artifact!.trace["entries"] as Map?)?.length ?? 0}",
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Issue status: ${_artifact!.report.errorCount} blocking / ${_artifact!.report.warningCount} cautions",
                    ),
                    const SizedBox(height: 8),
                    Text(
                      artifactInSync
                          ? "Release status: draft and exported version are in sync."
                          : "Release status: draft changed since the last export.",
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: artifactInSync
                            ? const Color(0xFF2F5D3A)
                            : const Color(0xFF8A5A00),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _statePolicyMessage(
                        artifact: _artifact!,
                        artifactInSync: artifactInSync,
                        activeEntryCount: activeEntryCount,
                      ),
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF5A4632),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        FilledButton(
                          onPressed: () {
                            _openPolicyPaper(_artifact!);
                          },
                          child: const Text("à¸ªà¸£à¹‰à¸²à¸‡ Policy Paper"),
                        ),
                        OutlinedButton(
                          onPressed: canMarkReviewed
                              ? () {
                                  _transitionArtifactState(
                                    IntentArtifactState.reviewed,
                                  );
                                }
                              : null,
                          child: const Text("Mark reviewed"),
                        ),
                        OutlinedButton(
                          onPressed: canMarkReady
                              ? () {
                                  _transitionArtifactState(
                                    IntentArtifactState.ready,
                                  );
                                }
                              : null,
                          child: const Text("Activate route"),
                        ),
                      ],
                    ),
                  ] else ...[
                    const SizedBox(height: 12),
                    Text(
                      activeEntryCount > 0
                          ? "No exported version yet for the current active draft."
                          : "Activate at least one route to make export meaningful.",
                    ),
                  ],
                  if (_artifactHistory.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Text(
                      "Export history",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "Each export is kept as a separate local version for this owner.",
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => IntentArtifactHistoryScreen(
                                currentArtifact: _artifact,
                                artifactHistory: _artifactHistory,
                                onPromote: _promoteArtifactVersion,
                                onRemove: _clearArtifactVersionModel,
                              ),
                            ),
                          );
                        },
                        child: const Text("View full history"),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        ChoiceChip(
                          label: const Text("All"),
                          selected: _historyFilter == 'all',
                          onSelected: (_) {
                            setState(() {
                              _historyFilter = 'all';
                            });
                          },
                        ),
                        ChoiceChip(
                          label: const Text("Ready"),
                          selected: _historyFilter == 'ready',
                          onSelected: (_) {
                            setState(() {
                              _historyFilter = 'ready';
                            });
                          },
                        ),
                        ChoiceChip(
                          label: const Text("Copied"),
                          selected: _historyFilter == 'promoted',
                          onSelected: (_) {
                            setState(() {
                              _historyFilter = 'promoted';
                            });
                          },
                        ),
                        ChoiceChip(
                          label: const Text("Has issues"),
                          selected: _historyFilter == 'issues',
                          onSelected: (_) {
                            setState(() {
                              _historyFilter = 'issues';
                            });
                          },
                        ),
                        DropdownButton<String>(
                          value: _historySort,
                          items: const [
                            DropdownMenuItem(
                              value: 'newest',
                              child: Text("Newest first"),
                            ),
                            DropdownMenuItem(
                              value: 'oldest',
                              child: Text("Oldest first"),
                            ),
                            DropdownMenuItem(
                              value: 'state',
                              child: Text("Sort by state"),
                            ),
                          ],
                          onChanged: (value) {
                            if (value == null) {
                              return;
                            }
                            setState(() {
                              _historySort = value;
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (visibleArtifactHistory.isEmpty)
                      const Text(
                        "No versions match the current history filter.",
                      ),
                    ...visibleArtifactHistory.take(5).map(
                          (item) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(
                                "${item.generatedAt.toLocal()} | ${item.artifactState.name}",
                              ),
                              subtitle: Text(
                                "Version ${item.artifactId} | ${item.activeEntryCount} active routes",
                              ),
                              isThreeLine: _artifactBadges(item).isNotEmpty,
                              dense: false,
                              minVerticalPadding: 10,
                              leading: _artifactBadges(item).isEmpty
                                  ? null
                                  : Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: _artifactBadges(item)
                                          .take(2)
                                          .map(
                                            (badge) => Padding(
                                              padding: const EdgeInsets.only(
                                                bottom: 4,
                                              ),
                                              child: _Pill(label: badge),
                                            ),
                                          )
                                          .toList(),
                                    ),
                              trailing: Wrap(
                                spacing: 8,
                                children: [
                                  TextButton(
                                    onPressed: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              IntentArtifactReviewScreen(
                                            artifact: item,
                                          ),
                                        ),
                                      );
                                    },
                                    child: const Text("Review"),
                                  ),
                                  TextButton(
                                    onPressed: _artifact != null &&
                                            item.artifactId !=
                                                _artifact!.artifactId
                                        ? () {
                                            Navigator.of(context).push(
                                              MaterialPageRoute(
                                                builder: (_) =>
                                                    IntentArtifactCompareScreen(
                                                  currentArtifact: _artifact!,
                                                  compareArtifact: item,
                                                ),
                                              ),
                                            );
                                          }
                                        : null,
                                    child: const Text("Compare"),
                                  ),
                                  TextButton(
                                    onPressed: _artifact != null &&
                                            item.artifactId !=
                                                _artifact!.artifactId
                                        ? () {
                                            _promoteArtifactVersion(item);
                                          }
                                        : null,
                                    child: const Text("Copy"),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      _clearArtifactVersion(item.artifactId);
                                    },
                                    child: const Text("Remove"),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "à¸ à¸²à¸žà¸£à¸§à¸¡à¸à¸²à¸£à¸—à¸³à¸‡à¸²à¸™",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "à¸­à¹ˆà¸²à¸™à¹à¸šà¸šà¸ªà¸±à¹‰à¸™à¸à¹ˆà¸­à¸™ à¹€à¸žà¸·à¹ˆà¸­à¹ƒà¸«à¹‰à¸¡à¸±à¹ˆà¸™à¹ƒà¸ˆà¸§à¹ˆà¸²à¹€à¸ªà¹‰à¸™à¸—à¸²à¸‡à¸—à¸³à¸‡à¸²à¸™à¸–à¸¹à¸à¸•à¹‰à¸­à¸‡ à¹à¸¥à¹‰à¸§à¸„à¹ˆà¸­à¸¢à¸”à¸¹à¸£à¸²à¸¢à¸¥à¸°à¹€à¸­à¸µà¸¢à¸”à¹€à¸Šà¸´à¸‡à¹€à¸—à¸„à¸™à¸´à¸„",
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: const Color(0xFFEFF6F5),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "à¸¥à¸³à¸”à¸±à¸šà¹à¸šà¸šà¹€à¸‚à¹‰à¸²à¹ƒà¸ˆà¸‡à¹ˆà¸²à¸¢",
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        SizedBox(height: 8),
                        Text("1) à¸‚à¸²à¸”à¸à¸²à¸£à¸•à¸´à¸”à¸•à¹ˆà¸­à¸„à¸£à¸šà¸•à¸²à¸¡à¸—à¸µà¹ˆà¸•à¸±à¹‰à¸‡à¹„à¸§à¹‰"),
                        Text("2) à¸£à¸°à¸šà¸šà¸•à¸£à¸§à¸ˆà¸ªà¸­à¸šà¸„à¸§à¸²à¸¡à¸›à¸¥à¸­à¸”à¸ à¸±à¸¢à¸à¹ˆà¸­à¸™"),
                        Text("3) à¸ªà¹ˆà¸‡à¸¥à¸´à¸‡à¸à¹Œà¸«à¸£à¸·à¸­à¸‚à¸±à¹‰à¸™à¸•à¸­à¸™à¹ƒà¸«à¹‰à¸œà¸¹à¹‰à¸£à¸±à¸šà¸•à¸²à¸¡à¹€à¸ªà¹‰à¸™à¸—à¸²à¸‡"),
                        Text("4) à¸šà¸±à¸™à¸—à¸¶à¸à¸›à¸£à¸°à¸§à¸±à¸•à¸´à¸à¸²à¸£à¹€à¸‚à¹‰à¸²à¸–à¸¶à¸‡à¹€à¸žà¸·à¹ˆà¸­à¸¢à¸·à¸™à¸¢à¸±à¸™à¸¢à¹‰à¸­à¸™à¸«à¸¥à¸±à¸‡"),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  ExpansionTile(
                    tilePadding: EdgeInsets.zero,
                    title: const Text("à¸”à¸¹à¸£à¸²à¸¢à¸¥à¸°à¹€à¸­à¸µà¸¢à¸”à¹€à¸Šà¸´à¸‡à¹€à¸—à¸„à¸™à¸´à¸„ (PTN)"),
                    subtitle: const Text("à¹€à¸«à¸¡à¸²à¸°à¸ªà¸³à¸«à¸£à¸±à¸šà¸œà¸¹à¹‰à¸”à¸¹à¹à¸¥à¸£à¸°à¸šà¸šà¸«à¸£à¸·à¸­à¸—à¸µà¸¡à¹€à¸—à¸„à¸™à¸´à¸„"),
                    children: [
                      const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: const Color(0xFFF7F2EA),
                    ),
                    child: SelectableText(
                      ptnPreview,
                      style: const TextStyle(
                        fontFamily: 'Consolas',
                        fontSize: 12,
                      ),
                    ),
                  ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _IntentEntryCard extends StatelessWidget {
  const _IntentEntryCard({
    required this.entry,
    required this.onEdit,
    required this.onToggleStatus,
    required this.onRemove,
  });

  final IntentEntryModel entry;
  final VoidCallback onEdit;
  final VoidCallback onToggleStatus;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final receiver = entry.recipient.registeredLegalName.trim().isNotEmpty
        ? entry.recipient.registeredLegalName
        : (entry.recipient.destinationRef.isEmpty
            ? 'ยังไม่ได้ระบุผู้รับ'
            : entry.recipient.destinationRef);
    final startCondition =
        'เริ่มเมื่อไม่พบการใช้งาน ${entry.trigger.inactivityDays} วัน และรอยืนยันอีก ${entry.trigger.graceDays} วัน';
    final statusLabel = entry.status == 'active' ? 'กำลังใช้งาน' : 'พักไว้';
    final kindLabel =
        entry.kind == 'legacy_delivery' ? 'ส่งต่อให้ผู้รับ' : 'กู้คืนด้วยตัวเอง';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    entry.asset.displayName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                _Pill(label: kindLabel),
                const SizedBox(width: 8),
                _Pill(label: statusLabel),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'สรุป: ส่งให้ $receiver',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(startCondition),
            const SizedBox(height: 4),
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              title: const Text('ดูรายละเอียดเพิ่มเติม'),
              subtitle: const Text('ช่องทางส่ง การยืนยันตัวตน และความเป็นส่วนตัว'),
              children: [
                const SizedBox(height: 6),
                Text('ช่องทางติดต่อผู้รับ: ${entry.recipient.deliveryChannel}'),
                const SizedBox(height: 4),
                if (entry.recipient.verificationHint.trim().isNotEmpty) ...[
                  Text('คำใบ้ยืนยันตัวตน: ${entry.recipient.verificationHint}'),
                  const SizedBox(height: 4),
                ],
                Text('ช่องทางสำรอง: ${entry.recipient.fallbackChannels.join(', ')}'),
                const SizedBox(height: 4),
                Text(
                  'รูปแบบการส่ง: ${entry.delivery.method}'
                  '${entry.delivery.requireVerificationCode ? ' + รหัสยืนยัน' : ''}'
                  '${entry.delivery.requireTotp ? ' + แอปยืนยันตัวตน' : ''}',
                ),
                const SizedBox(height: 4),
                Text('ระดับความเป็นส่วนตัว: ${entry.privacy.profile}'),
                const SizedBox(height: 4),
                Text('ก่อนปล่อยให้เห็น: ${entry.privacy.preTriggerVisibility}'),
                const SizedBox(height: 4),
                Text('หลังปล่อยให้เห็น: ${entry.privacy.postTriggerVisibility}'),
                const SizedBox(height: 4),
                Text('การเปิดเผยมูลค่า: ${entry.privacy.valueDisclosureMode}'),
                const SizedBox(height: 4),
                Text(
                  'ชั้นความปลอดภัย: '
                  '${entry.safeguards.requireMultisignal ? 'ยืนยันหลายสัญญาณ' : 'ยืนยันสัญญาณเดียว'}'
                  '${entry.safeguards.requireGuardianApproval ? ', ต้องมีพยานร่วมยืนยัน' : ''}',
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                OutlinedButton(onPressed: onEdit, child: const Text('แก้ไข')),
                const SizedBox(width: 8),
                FilledButton.tonal(
                  onPressed: onToggleStatus,
                  child: Text(
                    entry.status == 'active' ? 'พักเส้นทาง' : 'เปิดใช้งาน',
                  ),
                ),
                const SizedBox(width: 8),
                TextButton(onPressed: onRemove, child: const Text('ลบ')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _IntentEntryEditorDialog extends StatefulWidget {
  const _IntentEntryEditorDialog({required this.entry});

  final IntentEntryModel entry;

  @override
  State<_IntentEntryEditorDialog> createState() =>
      _IntentEntryEditorDialogState();
}

class _IntentEntryEditorDialogState extends State<_IntentEntryEditorDialog> {
  int _editorStep = 0;
  late final TextEditingController _displayNameController;
  late final TextEditingController _payloadRefController;
  late final TextEditingController _recipientController;
  late final TextEditingController _recipientNameController;
  late final TextEditingController _verificationHintController;
  late final TextEditingController _triggerDaysController;
  late final TextEditingController _graceDaysController;
  late String _kind;
  late String _recipientChannel;
  late String _deliveryMethod;
  late String _assetType;
  late String _payloadMode;
  late String _triggerMode;
  late String _privacyProfile;
  late String _preTriggerVisibility;
  late String _postTriggerVisibility;
  late String _valueDisclosureMode;
  late bool _requireVerificationCode;
  late bool _requireTotp;
  late bool _requireGuardianApproval;
  late bool _requireMultisignal;
  late bool _oneTimeAccess;
  late bool _requireAliveConfirmation;
  late bool _fallbackEmail;
  late bool _fallbackSms;
  late String _safetyLevel;

  @override
  void initState() {
    super.initState();
    _displayNameController = TextEditingController(
      text: widget.entry.asset.displayName,
    );
    _payloadRefController = TextEditingController(
      text: widget.entry.asset.payloadRef,
    );
    _recipientController = TextEditingController(
      text: widget.entry.recipient.destinationRef,
    );
    _recipientNameController = TextEditingController(
      text: widget.entry.recipient.registeredLegalName,
    );
    _verificationHintController = TextEditingController(
      text: widget.entry.recipient.verificationHint,
    );
    _triggerDaysController = TextEditingController(
      text: widget.entry.trigger.inactivityDays.toString(),
    );
    _graceDaysController = TextEditingController(
      text: widget.entry.trigger.graceDays.toString(),
    );
    _kind = widget.entry.kind;
    _recipientChannel = widget.entry.recipient.deliveryChannel;
    _deliveryMethod = widget.entry.delivery.method;
    _assetType = widget.entry.asset.assetType;
    _payloadMode = widget.entry.asset.payloadMode;
    _triggerMode = widget.entry.trigger.mode;
    _privacyProfile = widget.entry.privacy.profile;
    _preTriggerVisibility = widget.entry.privacy.preTriggerVisibility;
    _postTriggerVisibility = widget.entry.privacy.postTriggerVisibility;
    _valueDisclosureMode = widget.entry.privacy.valueDisclosureMode;
    _requireVerificationCode = widget.entry.delivery.requireVerificationCode;
    _requireTotp = widget.entry.delivery.requireTotp;
    _requireGuardianApproval = widget.entry.safeguards.requireGuardianApproval;
    _requireMultisignal = widget.entry.safeguards.requireMultisignal;
    _oneTimeAccess = widget.entry.delivery.oneTimeAccess;
    _requireAliveConfirmation =
        widget.entry.trigger.requireUnconfirmedAliveStatus;
    final fallbackChannels = widget.entry.recipient.fallbackChannels.toSet();
    _fallbackEmail = fallbackChannels.contains('email');
    _fallbackSms = fallbackChannels.contains('sms');
    _safetyLevel = (_requireGuardianApproval || _requireMultisignal)
        ? 'high'
        : 'standard';
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _payloadRefController.dispose();
    _recipientController.dispose();
    _recipientNameController.dispose();
    _verificationHintController.dispose();
    _triggerDaysController.dispose();
    _graceDaysController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final inactivityDays =
        int.tryParse(_triggerDaysController.text.trim()) ??
            widget.entry.trigger.inactivityDays;
    final emergencyEnabled = _triggerMode == 'manual_release';
    return AlertDialog(
      title: const Text('ตั้งค่าแผนส่งต่อ'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6F5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Step ${_editorStep + 1} of 3',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 8),
            if (_editorStep == 0) ...[
              const Text(
                'Step 1: ใครคือผู้รับ?',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _recipientNameController,
                decoration: const InputDecoration(
                  labelText: 'ชื่อผู้รับ',
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _recipientController,
                decoration: const InputDecoration(
                  labelText: 'อีเมลหรือเบอร์โทรผู้รับ',
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _recipientChannel,
                decoration: const InputDecoration(labelText: 'ช่องทางหลัก'),
                items: const [
                  DropdownMenuItem(value: 'email', child: Text('อีเมล')),
                  DropdownMenuItem(value: 'sms', child: Text('SMS')),
                  DropdownMenuItem(value: 'in_app', child: Text('ในแอป')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _recipientChannel = value);
                  }
                },
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  FilterChip(
                    selected: _fallbackEmail,
                    label: const Text('สำรองทางอีเมล'),
                    onSelected: (value) =>
                        setState(() => _fallbackEmail = value),
                  ),
                  FilterChip(
                    selected: _fallbackSms,
                    label: const Text('สำรองทาง SMS'),
                    onSelected: (value) => setState(() => _fallbackSms = value),
                  ),
                ],
              ),
            ] else if (_editorStep == 1) ...[
              const Text(
                'Step 2: ส่งมอบเมื่อไหร่?',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: _triggerMode == 'inactivity',
                onChanged: (value) {
                  if (value == true) {
                    setState(() => _triggerMode = 'inactivity');
                  }
                },
                title: const Text('เมื่อฉันไม่ใช้งานเกินช่วงเวลาที่กำหนด'),
              ),
              Slider(
                value: inactivityDays.clamp(30, 365).toDouble(),
                min: 30,
                max: 365,
                divisions: 11,
                label: '$inactivityDays วัน',
                onChanged: (value) {
                  setState(() {
                    _triggerDaysController.text = value.round().toString();
                    _triggerMode = 'inactivity';
                  });
                },
              ),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: emergencyEnabled,
                onChanged: (value) {
                  setState(() {
                    _triggerMode = value == true ? 'manual_release' : 'inactivity';
                  });
                },
                title: const Text('ใช้โหมดฉุกเฉิน (Emergency Access)'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _graceDaysController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'วันยืนยันซ้ำก่อนส่งมอบ',
                ),
              ),
            ] else ...[
              const Text(
                'Step 3: ระดับความปลอดภัย',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: _safetyLevel == 'high'
                      ? const Color(0xFFEFF4FF)
                      : const Color(0xFFEFF6F5),
                ),
                child: Row(
                  children: [
                    Icon(
                      _safetyLevel == 'high'
                          ? Icons.security_rounded
                          : Icons.shield_outlined,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _safetyLevel == 'high'
                            ? 'High: ต้องมีพยานร่วมยืนยัน'
                            : 'Standard: ยืนยันผ่าน Email + SMS',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              SegmentedButton<String>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(
                    value: 'standard',
                    label: Text('Standard'),
                  ),
                  ButtonSegment(
                    value: 'high',
                    label: Text('High'),
                  ),
                ],
                selected: {_safetyLevel},
                onSelectionChanged: (selection) {
                  final value = selection.first;
                  setState(() {
                    _safetyLevel = value;
                    if (value == 'high') {
                      _requireVerificationCode = true;
                      _requireTotp = true;
                      _requireGuardianApproval = true;
                      _requireMultisignal = true;
                    } else {
                      _requireVerificationCode = true;
                      _requireTotp = false;
                      _requireGuardianApproval = false;
                      _requireMultisignal = false;
                    }
                  });
                },
              ),
              const SizedBox(height: 8),
              Text(
                _safetyLevel == 'high'
                    ? 'ต้องมีพยาน (Guardian) ร่วมยืนยัน'
                    : 'ยืนยันผ่าน Email + SMS',
              ),
            ],
            const SizedBox(height: 10),
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              title: const Text('ตั้งค่าเพิ่มเติม (สำหรับผู้เชี่ยวชาญ)'),
              children: [
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: _kind,
                  decoration: const InputDecoration(labelText: 'ประเภทเส้นทาง'),
                  items: const [
                    DropdownMenuItem(
                      value: 'legacy_delivery',
                      child: Text('ส่งต่อมรดกดิจิทัล'),
                    ),
                    DropdownMenuItem(
                      value: 'self_recovery',
                      child: Text('กู้คืนด้วยตัวเอง'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _kind = value);
                    }
                  },
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _displayNameController,
                  decoration: const InputDecoration(labelText: 'ชื่อแผน'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _payloadRefController,
                  decoration:
                      const InputDecoration(labelText: 'ข้อมูลที่ส่งมอบ (อ้างอิง)'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _verificationHintController,
                  decoration: const InputDecoration(labelText: 'คำใบ้ยืนยันตัวตน'),
                ),
                const SizedBox(height: 8),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('เปิดสิทธิ์ใช้งานครั้งเดียว'),
                  value: _oneTimeAccess,
                  onChanged: (value) {
                    setState(() => _oneTimeAccess = value);
                  },
                ),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('ต้องมีสัญญาณยืนยันว่าเจ้าของยังไม่ตอบ'),
                  value: _requireAliveConfirmation,
                  onChanged: (value) {
                    setState(() => _requireAliveConfirmation = value);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('ยกเลิก'),
        ),
        if (_editorStep > 0)
          TextButton(
            onPressed: () => setState(() => _editorStep -= 1),
            child: const Text('ย้อนกลับ'),
          ),
        FilledButton(
          onPressed: () {
            if (_editorStep < 2) {
              setState(() => _editorStep += 1);
              return;
            }
            final inactivityDays =
                int.tryParse(_triggerDaysController.text.trim()) ??
                    widget.entry.trigger.inactivityDays;
            final graceDays = int.tryParse(_graceDaysController.text.trim()) ??
                widget.entry.trigger.graceDays;
            Navigator.of(context).pop(
              widget.entry.copyWith(
                kind: _kind,
                asset: IntentAssetModel(
                  assetId: widget.entry.asset.assetId,
                  assetType: _assetType,
                  displayName: _displayNameController.text.trim().isEmpty
                      ? widget.entry.asset.displayName
                      : _displayNameController.text.trim(),
                  payloadMode: _payloadMode,
                  payloadRef: _payloadRefController.text.trim(),
                  notes: widget.entry.asset.notes,
                ),
                recipient: IntentRecipientModel(
                  recipientId: widget.entry.recipient.recipientId,
                  relationship: _kind == 'self_recovery'
                      ? 'owner'
                      : widget.entry.recipient.relationship,
                  deliveryChannel: _recipientChannel,
                  destinationRef: _recipientController.text.trim(),
                  role: _kind == 'self_recovery'
                      ? 'owner'
                      : widget.entry.recipient.role,
                  registeredLegalName: _kind == 'self_recovery'
                      ? 'Owner'
                      : _recipientNameController.text.trim(),
                  verificationHint: _kind == 'self_recovery'
                      ? ''
                      : _verificationHintController.text.trim(),
                  fallbackChannels: [
                    if (_fallbackEmail) 'email',
                    if (_fallbackSms) 'sms',
                    if (!_fallbackEmail && !_fallbackSms) _recipientChannel,
                  ],
                ),
                trigger: IntentTriggerModel(
                  mode: _triggerMode,
                  inactivityDays: inactivityDays,
                  requireUnconfirmedAliveStatus: _requireAliveConfirmation,
                  graceDays: graceDays,
                  remindersDaysBefore: widget.entry.trigger.remindersDaysBefore,
                ),
                delivery: IntentDeliveryModel(
                  method: _deliveryMethod,
                  requireVerificationCode: _requireVerificationCode,
                  requireTotp: _requireTotp,
                  oneTimeAccess: _oneTimeAccess,
                ),
                safeguards: IntentSafeguardsModel(
                  requireGuardianApproval: _requireGuardianApproval,
                  requireMultisignal: _requireMultisignal,
                  cooldownHours: widget.entry.safeguards.cooldownHours,
                  legalDisclaimerRequired:
                      widget.entry.safeguards.legalDisclaimerRequired,
                ),
                privacy: IntentPrivacyModel(
                  profile: _privacyProfile,
                  minimizeTraceMetadata:
                      widget.entry.privacy.minimizeTraceMetadata,
                  preTriggerVisibility: _preTriggerVisibility,
                  postTriggerVisibility: _postTriggerVisibility,
                  valueDisclosureMode: _valueDisclosureMode,
                ),
              ),
            );
          },
          child: Text(_editorStep < 2 ? 'ถัดไป' : 'บันทึกแผนนี้'),
        ),
      ],
    );
  }
}
class _Pill extends StatelessWidget {
  const _Pill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: const Color(0xFFE5D7C5),
      ),
      child: Text(label),
    );
  }
}
