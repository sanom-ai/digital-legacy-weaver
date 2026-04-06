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
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
  ConsumerState<IntentBuilderScreen> createState() => _IntentBuilderScreenState();
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
      final history = await repository.loadArtifactHistory(ownerRef: _storageOwnerRef);
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
        _saveMessage = stored != null ? "Restored encrypted local draft from this device." : null;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _document = widget.initialDocument ?? _seedDocument();
        _isLoading = false;
        _loadError = "Could not restore local draft: $error";
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
        proofOfLifeFallbackChannels: widget.settings.proofOfLifeFallbackChannels,
        serverHeartbeatFallbackEnabled: widget.settings.serverHeartbeatFallbackEnabled,
        iosBackgroundRiskAcknowledged: widget.settings.iosBackgroundRiskAcknowledged,
      ),
    );
  }

  Future<void> _persistDocument(IntentDocumentModel next, {required String message}) async {
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
    await ref.read(intentDraftRepositoryProvider).clearDraft(ownerRef: _storageOwnerRef);
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
              subtitle: const Text("Send a secure path to a beneficiary after long inactivity"),
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
          for (final item in _document.entries) item.entryId == entry.entryId ? updated : item,
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
      message: "${scenario.title} preset applied and saved locally with device encryption.",
    );
    await _restoreArtifact();
  }

  Future<void> _toggleEntryStatus(IntentEntryModel entry) async {
    final nextStatus = entry.status == 'active' ? 'draft' : 'active';
    await _persistDocument(
      _document.copyWith(
        entries: [
          for (final item in _document.entries)
            item.entryId == entry.entryId ? item.copyWith(status: nextStatus) : item,
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
          "Remove '${entry.asset.displayName}' from this local intent draft? This does not publish or revoke any PTN policy.",
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

  Future<void> _exportCanonicalArtifact(IntentCompilerReportModel report, String ptnPreview) async {
    if (!report.ok) {
      setState(() {
        _saveMessage = "Resolve blocking intent review items before exporting a canonical PTN artifact.";
      });
      return;
    }

    final activeEntries = _document.entries.where((entry) => entry.status == "active");
    if (activeEntries.isEmpty) {
      setState(() {
        _saveMessage = "Activate at least one entry before exporting a canonical PTN artifact.";
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
      activeEntryCount: _document.entries.where((entry) => entry.status == "active").length,
      ptn: ptnPreview,
      trace: buildDraftIntentTrace(_document),
      report: report,
      sealedReleaseCandidate: _buildSealedReleaseCandidate(generatedAt),
    );
    await ref.read(intentCanonicalArtifactRepositoryProvider).saveArtifact(artifact);
    ref.invalidate(intentCanonicalArtifactProvider(_storageOwnerRef));
    ref.invalidate(intentCanonicalArtifactHistoryProvider(_storageOwnerRef));
    if (!mounted) {
      return;
    }
    setState(() {
      _artifactHistory = [artifact, ..._artifactHistory];
      _artifact = artifact;
      _isExporting = false;
      _saveMessage = "Canonical PTN artifact exported and sealed locally on this device.";
    });
  }

  SealedReleaseCandidateModel _buildSealedReleaseCandidate(DateTime generatedAt) {
    final activeEntries = _document.entries.where((entry) => entry.status == "active");
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
    await ref.read(intentCanonicalArtifactRepositoryProvider).clearArtifact(ownerRef: _storageOwnerRef);
    ref.invalidate(intentCanonicalArtifactProvider(_storageOwnerRef));
    ref.invalidate(intentCanonicalArtifactHistoryProvider(_storageOwnerRef));
    if (!mounted) {
      return;
    }
    setState(() {
      _artifact = null;
      _artifactHistory = const [];
      _saveMessage = "Cleared locally sealed canonical PTN artifact.";
    });
  }

  Future<void> _clearArtifactVersion(String artifactId) async {
    await ref
        .read(intentCanonicalArtifactRepositoryProvider)
        .clearArtifactVersion(ownerRef: _storageOwnerRef, artifactId: artifactId);
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
      _saveMessage = "Removed one canonical artifact version from local history.";
    });
  }

  Future<void> _clearArtifactVersionModel(IntentCanonicalArtifactModel artifact) async {
    await _clearArtifactVersion(artifact.artifactId);
  }

  Future<void> _promoteArtifactVersion(IntentCanonicalArtifactModel artifact) async {
    final promoted = await ref.read(intentCanonicalArtifactRepositoryProvider).promoteArtifactVersion(
      ownerRef: _storageOwnerRef,
      artifactId: artifact.artifactId,
    );
    ref.invalidate(intentCanonicalArtifactProvider(_storageOwnerRef));
    ref.invalidate(intentCanonicalArtifactHistoryProvider(_storageOwnerRef));
    if (promoted == null || !mounted) {
      return;
    }
    final nextHistory = [
      promoted,
      for (final item in _artifactHistory)
        item,
    ]..sort((left, right) => right.generatedAt.compareTo(left.generatedAt));
    setState(() {
      _artifactHistory = nextHistory;
      _artifact = promoted;
      _saveMessage =
          "Promoted one historical artifact into a new exported version so it can be reviewed again without losing history.";
    });
  }

  Future<void> _transitionArtifactState(IntentArtifactState nextState) async {
    final artifact = _artifact;
    if (artifact == null) {
      return;
    }
    final updated = artifact.copyWith(artifactState: nextState);
    await ref.read(intentCanonicalArtifactRepositoryProvider).saveArtifact(updated);
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
      _saveMessage = "Canonical artifact state updated to ${nextState.name}.";
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
      return "State policy: activate at least one entry before advancing artifact readiness.";
    }
    if (artifact.report.errorCount > 0) {
      return "State policy: resolve blocking compiler errors before marking this artifact reviewed or ready.";
    }
    if (artifact.artifactState == IntentArtifactState.exported) {
      return "State policy: exported artifacts can be marked reviewed when compiler errors are clear and active entries remain present.";
    }
    if (artifact.artifactState == IntentArtifactState.reviewed && !artifactInSync) {
      return "State policy: reviewed artifacts can only be marked ready while the current draft still matches the exported artifact.";
    }
    if (artifact.artifactState == IntentArtifactState.reviewed && artifactInSync) {
      return "State policy: this reviewed artifact is eligible to move to ready because the draft is still in sync.";
    }
    if (artifact.artifactState == IntentArtifactState.ready) {
      return "State policy: ready artifacts stay trustworthy only while the draft remains in sync with the exported version.";
    }
    return "State policy: export a canonical artifact first, then review it before marking it ready.";
  }

  List<String> _artifactBadges(IntentCanonicalArtifactModel artifact) {
    final badges = <String>[];
    if (_artifact != null && artifact.artifactId == _artifact!.artifactId) {
      badges.add("Latest");
    }
    if (artifact.promotedFromArtifactId != null && artifact.promotedFromArtifactId!.isNotEmpty) {
      badges.add("Promoted");
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
    final background = isError ? const Color(0xFFFFF1F1) : const Color(0xFFE9F6EF);
    final icon = isError ? Icons.warning_amber_rounded : Icons.check_circle_outline;
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
            TextButton(
              onPressed: onRetry,
              child: const Text("Retry"),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenTitle = widget.screenTitle ?? "Intent Builder";
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
                  "Loading your local encrypted draft and recent artifact history...",
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
      serverHeartbeatFallbackEnabled: widget.settings.serverHeartbeatFallbackEnabled,
      iosBackgroundRiskAcknowledged: widget.settings.iosBackgroundRiskAcknowledged,
    );
    final ptnPreview = buildDraftIntentPtnPreview(_document);
    final draftSignature = buildIntentDocumentSignature(_document);
    final screenSubtitle = widget.screenSubtitle ??
        "This screen is the draft foundation for building intent in plain language before compiling it into PTN.";
    final demoScenarioTitle = _document.metadata["demo_title"] as String?;
    final demoScenarioSummary = _document.metadata["demo_summary"] as String?;
    final demoScenarioNextStep = _document.metadata["demo_next_step"] as String?;
    final artifactInSync = _artifact != null && _artifact!.sourceDraftSignature == draftSignature;
    final activeEntryCount = _document.entries.where((entry) => entry.status == "active").length;
    final canMarkReviewed = _artifact != null
        ? _canMarkReviewed(artifact: _artifact!, activeEntryCount: activeEntryCount)
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
            child: const Text("Reset local draft"),
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
                    "User-defined legacy intent",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Text(screenSubtitle),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF7F1E8),
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
                        Text("1. Keep at least one active entry for a real route."),
                        SizedBox(height: 4),
                        Text("2. Export canonical PTN and review warnings immediately."),
                        SizedBox(height: 4),
                        Text("3. Keep draft and exported artifact in sync before release drills."),
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
                            "Demo scenario: $demoScenarioTitle",
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
                            ? "Encrypted draft stored on this device"
                            : "Seeded from setup",
                      ),
                      _Pill(label: "Default privacy: ${_document.defaultPrivacyProfile}"),
                      _Pill(label: "Entries: ${_document.entries.length}"),
                      _Pill(label: "Owner ref: ${_document.ownerRef}"),
                      _Pill(label: "Artifact versions: ${_artifactHistory.length}"),
                    ],
                  ),
                  if (_saveMessage != null) ...[
                    const SizedBox(height: 12),
                    _buildStatusBanner(
                      message: _saveMessage!,
                      isError: false,
                    ),
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
                    "Scenario preset",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Use a preset to make the current workspace concrete faster. Presets seed entries, safeguards, and privacy posture without making you start from a blank document.",
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
                            "Preset active: ${_activeScenario!.title}",
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 6),
                          Text(_activeScenario!.summary),
                          if (demoScenarioNextStep != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              "Preset next step: $demoScenarioNextStep",
                              style: const TextStyle(fontWeight: FontWeight.w600),
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
                    "Encrypted local draft persistence",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "Intent drafts are encrypted and cached on this device so users can continue shaping intent in plain language before activation. This draft cache is local-first and not treated as a published PTN policy yet.",
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
                    "Guardian quorum & emergency access",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Use guardian quorum for sensitive legacy release and keep emergency access as a separate incapacity flow rather than a shortcut around dead-man timing.",
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    title: const Text("Enable guardian quorum"),
                    subtitle: const Text("Recommended baseline: 2-of-3 for important legacy delivery."),
                    value: _document.globalSafeguards.guardianQuorumEnabled,
                    onChanged: (value) {
                      final poolSize = _document.globalSafeguards.guardianQuorumPoolSize;
                      _updateGlobalSafeguards(
                        IntentGlobalSafeguardsModel(
                          emergencyPauseEnabled: _document.globalSafeguards.emergencyPauseEnabled,
                          defaultGraceDays: _document.globalSafeguards.defaultGraceDays,
                          defaultRemindersDaysBefore:
                              _document.globalSafeguards.defaultRemindersDaysBefore,
                          requireMultisignalBeforeRelease:
                              _document.globalSafeguards.requireMultisignalBeforeRelease,
                          requireGuardianApprovalForLegacy: value,
                          guardianQuorumEnabled: value,
                          guardianQuorumRequired: value
                              ? _document.globalSafeguards.guardianQuorumRequired.clamp(1, poolSize)
                              : _document.globalSafeguards.guardianQuorumRequired,
                          guardianQuorumPoolSize: poolSize,
                          emergencyAccessEnabled:
                              _document.globalSafeguards.emergencyAccessEnabled,
                          emergencyAccessRequiresBeneficiaryRequest: _document
                              .globalSafeguards.emergencyAccessRequiresBeneficiaryRequest,
                          emergencyAccessRequiresGuardianQuorum: _document
                              .globalSafeguards.emergencyAccessRequiresGuardianQuorum,
                          emergencyAccessGraceHours:
                              _document.globalSafeguards.emergencyAccessGraceHours,
                          proofOfLifeCheckMode: _document.globalSafeguards.proofOfLifeCheckMode,
                          proofOfLifeFallbackChannels:
                              _document.globalSafeguards.proofOfLifeFallbackChannels,
                          serverHeartbeatFallbackEnabled: _document
                              .globalSafeguards.serverHeartbeatFallbackEnabled,
                          iosBackgroundRiskAcknowledged:
                              _document.globalSafeguards.iosBackgroundRiskAcknowledged,
                        ),
                        message: "Updated guardian quorum posture.",
                      );
                    },
                  ),
                  if (_document.globalSafeguards.guardianQuorumEnabled) ...[
                    const SizedBox(height: 8),
                    Text(
                      "Current quorum: ${_document.globalSafeguards.guardianQuorumRequired}-of-${_document.globalSafeguards.guardianQuorumPoolSize}",
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<int>(
                      initialValue: _document.globalSafeguards.guardianQuorumPoolSize,
                      decoration: const InputDecoration(labelText: "Guardian pool size"),
                      items: const [
                        DropdownMenuItem(value: 2, child: Text("2 guardians")),
                        DropdownMenuItem(value: 3, child: Text("3 guardians")),
                        DropdownMenuItem(value: 4, child: Text("4 guardians")),
                        DropdownMenuItem(value: 5, child: Text("5 guardians")),
                      ],
                      onChanged: (value) {
                        if (value == null) {
                          return;
                        }
                        _updateGlobalSafeguards(
                          IntentGlobalSafeguardsModel(
                            emergencyPauseEnabled: _document.globalSafeguards.emergencyPauseEnabled,
                            defaultGraceDays: _document.globalSafeguards.defaultGraceDays,
                            defaultRemindersDaysBefore:
                                _document.globalSafeguards.defaultRemindersDaysBefore,
                            requireMultisignalBeforeRelease:
                                _document.globalSafeguards.requireMultisignalBeforeRelease,
                            requireGuardianApprovalForLegacy:
                                _document.globalSafeguards.requireGuardianApprovalForLegacy,
                            guardianQuorumEnabled: _document.globalSafeguards.guardianQuorumEnabled,
                            guardianQuorumRequired:
                                _document.globalSafeguards.guardianQuorumRequired.clamp(1, value),
                            guardianQuorumPoolSize: value,
                            emergencyAccessEnabled:
                                _document.globalSafeguards.emergencyAccessEnabled,
                            emergencyAccessRequiresBeneficiaryRequest: _document
                                .globalSafeguards.emergencyAccessRequiresBeneficiaryRequest,
                            emergencyAccessRequiresGuardianQuorum: _document
                                .globalSafeguards.emergencyAccessRequiresGuardianQuorum,
                            emergencyAccessGraceHours:
                                _document.globalSafeguards.emergencyAccessGraceHours,
                            proofOfLifeCheckMode:
                                _document.globalSafeguards.proofOfLifeCheckMode,
                            proofOfLifeFallbackChannels:
                                _document.globalSafeguards.proofOfLifeFallbackChannels,
                            serverHeartbeatFallbackEnabled: _document
                                .globalSafeguards.serverHeartbeatFallbackEnabled,
                            iosBackgroundRiskAcknowledged:
                                _document.globalSafeguards.iosBackgroundRiskAcknowledged,
                          ),
                          message: "Updated guardian pool size.",
                        );
                      },
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<int>(
                      initialValue: _document.globalSafeguards.guardianQuorumRequired,
                      decoration: const InputDecoration(labelText: "Required guardian approvals"),
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
                            emergencyPauseEnabled: _document.globalSafeguards.emergencyPauseEnabled,
                            defaultGraceDays: _document.globalSafeguards.defaultGraceDays,
                            defaultRemindersDaysBefore:
                                _document.globalSafeguards.defaultRemindersDaysBefore,
                            requireMultisignalBeforeRelease:
                                _document.globalSafeguards.requireMultisignalBeforeRelease,
                            requireGuardianApprovalForLegacy:
                                _document.globalSafeguards.requireGuardianApprovalForLegacy,
                            guardianQuorumEnabled: _document.globalSafeguards.guardianQuorumEnabled,
                            guardianQuorumRequired: value,
                            guardianQuorumPoolSize:
                                _document.globalSafeguards.guardianQuorumPoolSize,
                            emergencyAccessEnabled:
                                _document.globalSafeguards.emergencyAccessEnabled,
                            emergencyAccessRequiresBeneficiaryRequest: _document
                                .globalSafeguards.emergencyAccessRequiresBeneficiaryRequest,
                            emergencyAccessRequiresGuardianQuorum: _document
                                .globalSafeguards.emergencyAccessRequiresGuardianQuorum,
                            emergencyAccessGraceHours:
                                _document.globalSafeguards.emergencyAccessGraceHours,
                            proofOfLifeCheckMode:
                                _document.globalSafeguards.proofOfLifeCheckMode,
                            proofOfLifeFallbackChannels:
                                _document.globalSafeguards.proofOfLifeFallbackChannels,
                            serverHeartbeatFallbackEnabled: _document
                                .globalSafeguards.serverHeartbeatFallbackEnabled,
                            iosBackgroundRiskAcknowledged:
                                _document.globalSafeguards.iosBackgroundRiskAcknowledged,
                          ),
                          message: "Updated guardian quorum requirement.",
                        );
                      },
                    ),
                  ],
                  const SizedBox(height: 12),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    title: const Text("Enable emergency access override"),
                    subtitle: const Text("For incapacity cases such as ICU, separate from standard inactivity release."),
                    value: _document.globalSafeguards.emergencyAccessEnabled,
                    onChanged: (value) {
                      _updateGlobalSafeguards(
                        IntentGlobalSafeguardsModel(
                          emergencyPauseEnabled: _document.globalSafeguards.emergencyPauseEnabled,
                          defaultGraceDays: _document.globalSafeguards.defaultGraceDays,
                          defaultRemindersDaysBefore:
                              _document.globalSafeguards.defaultRemindersDaysBefore,
                          requireMultisignalBeforeRelease:
                              _document.globalSafeguards.requireMultisignalBeforeRelease,
                          requireGuardianApprovalForLegacy:
                              _document.globalSafeguards.requireGuardianApprovalForLegacy,
                          guardianQuorumEnabled: _document.globalSafeguards.guardianQuorumEnabled,
                          guardianQuorumRequired:
                              _document.globalSafeguards.guardianQuorumRequired,
                          guardianQuorumPoolSize:
                              _document.globalSafeguards.guardianQuorumPoolSize,
                          emergencyAccessEnabled: value,
                          emergencyAccessRequiresBeneficiaryRequest:
                              _document.globalSafeguards.emergencyAccessRequiresBeneficiaryRequest,
                          emergencyAccessRequiresGuardianQuorum:
                              _document.globalSafeguards.emergencyAccessRequiresGuardianQuorum,
                          emergencyAccessGraceHours:
                              _document.globalSafeguards.emergencyAccessGraceHours,
                          proofOfLifeCheckMode: _document.globalSafeguards.proofOfLifeCheckMode,
                          proofOfLifeFallbackChannels:
                              _document.globalSafeguards.proofOfLifeFallbackChannels,
                          serverHeartbeatFallbackEnabled:
                              _document.globalSafeguards.serverHeartbeatFallbackEnabled,
                          iosBackgroundRiskAcknowledged:
                              _document.globalSafeguards.iosBackgroundRiskAcknowledged,
                        ),
                        message: "Updated emergency access posture.",
                      );
                    },
                  ),
                  if (_document.globalSafeguards.emergencyAccessEnabled) ...[
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text("Require beneficiary request"),
                      subtitle: const Text("Emergency access should begin with an explicit beneficiary request."),
                      value: _document.globalSafeguards.emergencyAccessRequiresBeneficiaryRequest,
                      onChanged: (value) {
                        _updateGlobalSafeguards(
                          IntentGlobalSafeguardsModel(
                            emergencyPauseEnabled: _document.globalSafeguards.emergencyPauseEnabled,
                            defaultGraceDays: _document.globalSafeguards.defaultGraceDays,
                            defaultRemindersDaysBefore:
                                _document.globalSafeguards.defaultRemindersDaysBefore,
                            requireMultisignalBeforeRelease:
                                _document.globalSafeguards.requireMultisignalBeforeRelease,
                            requireGuardianApprovalForLegacy:
                                _document.globalSafeguards.requireGuardianApprovalForLegacy,
                            guardianQuorumEnabled: _document.globalSafeguards.guardianQuorumEnabled,
                            guardianQuorumRequired:
                                _document.globalSafeguards.guardianQuorumRequired,
                            guardianQuorumPoolSize:
                                _document.globalSafeguards.guardianQuorumPoolSize,
                            emergencyAccessEnabled:
                                _document.globalSafeguards.emergencyAccessEnabled,
                            emergencyAccessRequiresBeneficiaryRequest: value ?? true,
                            emergencyAccessRequiresGuardianQuorum:
                                _document.globalSafeguards.emergencyAccessRequiresGuardianQuorum,
                            emergencyAccessGraceHours:
                                _document.globalSafeguards.emergencyAccessGraceHours,
                            proofOfLifeCheckMode:
                                _document.globalSafeguards.proofOfLifeCheckMode,
                            proofOfLifeFallbackChannels:
                                _document.globalSafeguards.proofOfLifeFallbackChannels,
                            serverHeartbeatFallbackEnabled:
                                _document.globalSafeguards.serverHeartbeatFallbackEnabled,
                            iosBackgroundRiskAcknowledged:
                                _document.globalSafeguards.iosBackgroundRiskAcknowledged,
                          ),
                          message: "Updated beneficiary request requirement.",
                        );
                      },
                    ),
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text("Require guardian quorum"),
                      subtitle: const Text("Recommended so emergency access stays multi-party and auditable."),
                      value: _document.globalSafeguards.emergencyAccessRequiresGuardianQuorum,
                      onChanged: (value) {
                        _updateGlobalSafeguards(
                          IntentGlobalSafeguardsModel(
                            emergencyPauseEnabled: _document.globalSafeguards.emergencyPauseEnabled,
                            defaultGraceDays: _document.globalSafeguards.defaultGraceDays,
                            defaultRemindersDaysBefore:
                                _document.globalSafeguards.defaultRemindersDaysBefore,
                            requireMultisignalBeforeRelease:
                                _document.globalSafeguards.requireMultisignalBeforeRelease,
                            requireGuardianApprovalForLegacy:
                                _document.globalSafeguards.requireGuardianApprovalForLegacy,
                            guardianQuorumEnabled: _document.globalSafeguards.guardianQuorumEnabled,
                            guardianQuorumRequired:
                                _document.globalSafeguards.guardianQuorumRequired,
                            guardianQuorumPoolSize:
                                _document.globalSafeguards.guardianQuorumPoolSize,
                            emergencyAccessEnabled:
                                _document.globalSafeguards.emergencyAccessEnabled,
                            emergencyAccessRequiresBeneficiaryRequest: _document
                                .globalSafeguards.emergencyAccessRequiresBeneficiaryRequest,
                            emergencyAccessRequiresGuardianQuorum: value ?? true,
                            emergencyAccessGraceHours:
                                _document.globalSafeguards.emergencyAccessGraceHours,
                            proofOfLifeCheckMode:
                                _document.globalSafeguards.proofOfLifeCheckMode,
                            proofOfLifeFallbackChannels:
                                _document.globalSafeguards.proofOfLifeFallbackChannels,
                            serverHeartbeatFallbackEnabled:
                                _document.globalSafeguards.serverHeartbeatFallbackEnabled,
                            iosBackgroundRiskAcknowledged:
                                _document.globalSafeguards.iosBackgroundRiskAcknowledged,
                          ),
                          message: "Updated emergency guardian requirement.",
                        );
                      },
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Emergency access grace window: ${_document.globalSafeguards.emergencyAccessGraceHours} hours",
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Slider(
                      value: _document.globalSafeguards.emergencyAccessGraceHours.toDouble(),
                      min: 24,
                      max: 168,
                      divisions: 6,
                      label: "${_document.globalSafeguards.emergencyAccessGraceHours}",
                      onChanged: (value) {
                        _updateGlobalSafeguards(
                          IntentGlobalSafeguardsModel(
                            emergencyPauseEnabled: _document.globalSafeguards.emergencyPauseEnabled,
                            defaultGraceDays: _document.globalSafeguards.defaultGraceDays,
                            defaultRemindersDaysBefore:
                                _document.globalSafeguards.defaultRemindersDaysBefore,
                            requireMultisignalBeforeRelease:
                                _document.globalSafeguards.requireMultisignalBeforeRelease,
                            requireGuardianApprovalForLegacy:
                                _document.globalSafeguards.requireGuardianApprovalForLegacy,
                            guardianQuorumEnabled: _document.globalSafeguards.guardianQuorumEnabled,
                            guardianQuorumRequired:
                                _document.globalSafeguards.guardianQuorumRequired,
                            guardianQuorumPoolSize:
                                _document.globalSafeguards.guardianQuorumPoolSize,
                            emergencyAccessEnabled:
                                _document.globalSafeguards.emergencyAccessEnabled,
                            emergencyAccessRequiresBeneficiaryRequest: _document
                                .globalSafeguards.emergencyAccessRequiresBeneficiaryRequest,
                            emergencyAccessRequiresGuardianQuorum: _document
                                .globalSafeguards.emergencyAccessRequiresGuardianQuorum,
                            emergencyAccessGraceHours: value.round(),
                            proofOfLifeCheckMode:
                                _document.globalSafeguards.proofOfLifeCheckMode,
                            proofOfLifeFallbackChannels:
                                _document.globalSafeguards.proofOfLifeFallbackChannels,
                            serverHeartbeatFallbackEnabled:
                                _document.globalSafeguards.serverHeartbeatFallbackEnabled,
                            iosBackgroundRiskAcknowledged:
                                _document.globalSafeguards.iosBackgroundRiskAcknowledged,
                          ),
                          message: "Updated emergency access grace window.",
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
                  "Draft entries",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
              ),
              FilledButton.tonal(
                onPressed: () {
                  _addDraftEntry();
                },
                child: const Text("Add intent entry"),
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
                      "No draft entries yet",
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "Add at least one intent entry so this workspace can protect self-recovery or beneficiary delivery in a real scenario.",
                    ),
                    const SizedBox(height: 10),
                    FilledButton.tonal(
                      onPressed: _addDraftEntry,
                      child: const Text("Add first entry"),
                    ),
                  ],
                ),
              ),
            )
          else
            ..._document.entries.map((entry) => Padding(
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
                )),
          IntentReviewCard(report: report),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Canonical export",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Export the current active intent set into a locally sealed PTN artifact with compiler report and trace metadata. This is the activation bridge from working draft to canonical policy output.",
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
                        child: Text(_isExporting ? "Exporting..." : "Export canonical PTN"),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton(
                        onPressed: _artifact == null ? null : _clearCanonicalArtifact,
                        child: const Text("Clear exported artifact"),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton(
                        onPressed: _artifact == null
                            ? null
                            : () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => IntentArtifactReviewScreen(artifact: _artifact!),
                                  ),
                                );
                              },
                        child: const Text("Review artifact"),
                      ),
                    ],
                  ),
                  if (_artifact != null) ...[
                    const SizedBox(height: 12),
                    _Pill(label: "Last export: ${_artifact!.generatedAt.toLocal().toString()}"),
                    const SizedBox(height: 8),
                    Text("Contract: ${_artifact!.contractVersion}"),
                    const SizedBox(height: 4),
                    Text("Artifact state: ${_artifact!.artifactState.name}"),
                    const SizedBox(height: 4),
                    Text("Artifact active entries: ${_artifact!.activeEntryCount}"),
                    const SizedBox(height: 4),
                    Text("Trace entries: ${(_artifact!.trace["entries"] as Map?)?.length ?? 0}"),
                    const SizedBox(height: 4),
                    Text(
                      "Compiler status: ${_artifact!.report.errorCount} errors / ${_artifact!.report.warningCount} warnings",
                    ),
                    const SizedBox(height: 8),
                      Text(
                        artifactInSync
                            ? "Activation status: draft and exported artifact are in sync."
                            : "Activation status: draft changed since the last canonical export.",
                        style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: artifactInSync ? const Color(0xFF2F5D3A) : const Color(0xFF8A5A00),
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
                          OutlinedButton(
                            onPressed: canMarkReviewed
                                ? () {
                                  _transitionArtifactState(IntentArtifactState.reviewed);
                                }
                                : null,
                            child: const Text("Mark reviewed"),
                          ),
                          OutlinedButton(
                            onPressed: canMarkReady
                                ? () {
                                  _transitionArtifactState(IntentArtifactState.ready);
                                }
                                : null,
                          child: const Text("Mark ready"),
                        ),
                      ],
                    ),
                  ] else ...[
                    const SizedBox(height: 12),
                    Text(
                      activeEntryCount > 0
                          ? "No canonical artifact exported yet for the current active draft."
                          : "Activate at least one entry to make canonical export meaningful.",
                    ),
                  ],
                  if (_artifactHistory.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Text(
                      "Export history",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "Each export is kept as a separate local canonical artifact version for this owner.",
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
                          label: const Text("Promoted"),
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
                            DropdownMenuItem(value: 'newest', child: Text("Newest first")),
                            DropdownMenuItem(value: 'oldest', child: Text("Oldest first")),
                            DropdownMenuItem(value: 'state', child: Text("Sort by state")),
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
                        "No artifact versions match the current history filter.",
                      ),
                    ...visibleArtifactHistory.take(5).map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                            title: Text(
                              "${item.generatedAt.toLocal()} · ${item.artifactState.name}",
                            ),
                            subtitle: Text(
                              "Artifact ${item.artifactId} · ${item.activeEntryCount} active entries",
                            ),
                            isThreeLine: _artifactBadges(item).isNotEmpty,
                            dense: false,
                            minVerticalPadding: 10,
                            leading: _artifactBadges(item).isEmpty
                                ? null
                                : Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: _artifactBadges(item)
                                        .take(2)
                                        .map((badge) => Padding(
                                              padding: const EdgeInsets.only(bottom: 4),
                                              child: _Pill(label: badge),
                                            ))
                                        .toList(),
                                  ),
                            trailing: Wrap(
                              spacing: 8,
                            children: [
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => IntentArtifactReviewScreen(artifact: item),
                                    ),
                                  );
                                },
                                child: const Text("Review"),
                              ),
                              TextButton(
                                onPressed: _artifact != null && item.artifactId != _artifact!.artifactId
                                    ? () {
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (_) => IntentArtifactCompareScreen(
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
                                onPressed: _artifact != null && item.artifactId != _artifact!.artifactId
                                    ? () {
                                        _promoteArtifactVersion(item);
                                      }
                                    : null,
                                child: const Text("Promote"),
                              ),
                              TextButton(
                                onPressed: () {
                                  _clearArtifactVersion(item.artifactId);
                                },
                                child: const Text("Remove version"),
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
                    "Compiler bridge",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Draft canonical preview generated from the current intent document. This stays close to compiler semantics so users can see the PTN shape early.",
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: const Color(0xFFF7F2EA),
                    ),
                    child: SelectableText(
                      ptnPreview,
                      style: const TextStyle(fontFamily: 'Consolas', fontSize: 12),
                    ),
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
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                ),
                _Pill(label: entry.kind),
                const SizedBox(width: 8),
                _Pill(label: entry.status),
              ],
            ),
            const SizedBox(height: 8),
            Text("Recipient: ${entry.recipient.destinationRef.isEmpty ? "Not set" : entry.recipient.destinationRef}"),
            const SizedBox(height: 4),
            Text("Recipient channel: ${entry.recipient.deliveryChannel}"),
            const SizedBox(height: 4),
            if (entry.recipient.registeredLegalName.trim().isNotEmpty) ...[
              Text("Registered beneficiary: ${entry.recipient.registeredLegalName}"),
              const SizedBox(height: 4),
            ],
            if (entry.recipient.verificationHint.trim().isNotEmpty) ...[
              Text("Verification hint: ${entry.recipient.verificationHint}"),
              const SizedBox(height: 4),
            ],
            Text("Fallback channels: ${entry.recipient.fallbackChannels.join(", ")}"),
            const SizedBox(height: 4),
            Text("Trigger: ${entry.trigger.mode} / ${entry.trigger.inactivityDays} inactivity days + ${entry.trigger.graceDays} grace days"),
            const SizedBox(height: 4),
            Text(
              "Delivery: ${entry.delivery.method}"
              "${entry.delivery.requireVerificationCode ? " + verification code" : ""}"
              "${entry.delivery.requireTotp ? " + TOTP" : ""}",
            ),
            const SizedBox(height: 4),
            Text("Privacy: ${entry.privacy.profile}"),
            const SizedBox(height: 4),
            Text("Visibility before trigger: ${entry.privacy.preTriggerVisibility}"),
            const SizedBox(height: 4),
            Text("Visibility after trigger: ${entry.privacy.postTriggerVisibility}"),
            const SizedBox(height: 4),
            Text("Value disclosure: ${entry.privacy.valueDisclosureMode}"),
            const SizedBox(height: 4),
            Text(
              "Safeguards: "
              "${entry.safeguards.requireMultisignal ? "multisignal" : "single-signal"}"
              "${entry.safeguards.requireGuardianApproval ? ", guardian approval" : ""}",
            ),
            const SizedBox(height: 4),
            Text("Status: ${entry.status}"),
            const SizedBox(height: 12),
            Row(
              children: [
                OutlinedButton(
                  onPressed: onEdit,
                  child: const Text("Edit"),
                ),
                const SizedBox(width: 8),
                FilledButton.tonal(
                  onPressed: onToggleStatus,
                  child: Text(entry.status == 'active' ? "Move to draft" : "Activate"),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: onRemove,
                  child: const Text("Remove"),
                ),
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
  State<_IntentEntryEditorDialog> createState() => _IntentEntryEditorDialogState();
}

class _IntentEntryEditorDialogState extends State<_IntentEntryEditorDialog> {
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

  @override
  void initState() {
    super.initState();
    _displayNameController = TextEditingController(text: widget.entry.asset.displayName);
    _payloadRefController = TextEditingController(text: widget.entry.asset.payloadRef);
    _recipientController = TextEditingController(text: widget.entry.recipient.destinationRef);
    _recipientNameController = TextEditingController(text: widget.entry.recipient.registeredLegalName);
    _verificationHintController = TextEditingController(text: widget.entry.recipient.verificationHint);
    _triggerDaysController = TextEditingController(text: widget.entry.trigger.inactivityDays.toString());
    _graceDaysController = TextEditingController(text: widget.entry.trigger.graceDays.toString());
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
    _requireAliveConfirmation = widget.entry.trigger.requireUnconfirmedAliveStatus;
    final fallbackChannels = widget.entry.recipient.fallbackChannels.toSet();
    _fallbackEmail = fallbackChannels.contains("email");
    _fallbackSms = fallbackChannels.contains("sms");
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
    return AlertDialog(
      title: const Text("Edit intent entry"),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Use plain-language fields first. Advanced controls can stay conservative unless you have a specific release need.",
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _kind,
              decoration: const InputDecoration(labelText: "Intent kind"),
              items: const [
                DropdownMenuItem(value: "legacy_delivery", child: Text("Legacy delivery")),
                DropdownMenuItem(value: "self_recovery", child: Text("Self-recovery")),
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
              decoration: const InputDecoration(labelText: "Asset label"),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _assetType,
              decoration: const InputDecoration(labelText: "Asset type"),
              items: const [
                DropdownMenuItem(value: "vault_item", child: Text("Vault item")),
                DropdownMenuItem(value: "backup_email_route", child: Text("Backup email route")),
                DropdownMenuItem(value: "document_notice", child: Text("Document notice")),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() => _assetType = value);
                }
              },
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _payloadMode,
              decoration: const InputDecoration(labelText: "Payload mode"),
              items: const [
                DropdownMenuItem(value: "secure_link", child: Text("Secure link")),
                DropdownMenuItem(value: "self_recovery_route", child: Text("Self-recovery route")),
                DropdownMenuItem(value: "handoff_notice", child: Text("Handoff notice")),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() => _payloadMode = value);
                }
              },
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _payloadRefController,
              decoration: const InputDecoration(labelText: "Payload reference"),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _recipientController,
              decoration: const InputDecoration(labelText: "Recipient destination"),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _recipientNameController,
              decoration: const InputDecoration(labelText: "Registered beneficiary name"),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _verificationHintController,
              decoration: const InputDecoration(labelText: "Verification hint"),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _recipientChannel,
              decoration: const InputDecoration(labelText: "Recipient channel"),
              items: const [
                DropdownMenuItem(value: "email", child: Text("Email")),
                DropdownMenuItem(value: "sms", child: Text("SMS")),
                DropdownMenuItem(value: "in_app", child: Text("In-app")),
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
                  label: const Text("Email fallback"),
                  onSelected: (value) => setState(() => _fallbackEmail = value),
                ),
                FilterChip(
                  selected: _fallbackSms,
                  label: const Text("SMS fallback"),
                  onSelected: (value) => setState(() => _fallbackSms = value),
                ),
              ],
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _triggerMode,
              decoration: const InputDecoration(labelText: "Trigger mode"),
              items: const [
                DropdownMenuItem(value: "inactivity", child: Text("Inactivity")),
                DropdownMenuItem(value: "manual_release", child: Text("Manual release")),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() => _triggerMode = value);
                }
              },
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _triggerDaysController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Inactivity days"),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _graceDaysController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Grace days"),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _deliveryMethod,
              decoration: const InputDecoration(labelText: "Delivery method"),
              items: const [
                DropdownMenuItem(value: "secure_link", child: Text("Secure link")),
                DropdownMenuItem(value: "self_recovery_route", child: Text("Self-recovery route")),
                DropdownMenuItem(value: "handoff_notice", child: Text("Handoff notice")),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() => _deliveryMethod = value);
                }
              },
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _privacyProfile,
              decoration: const InputDecoration(labelText: "Privacy profile"),
              items: const [
                DropdownMenuItem(value: "confidential", child: Text("Confidential")),
                DropdownMenuItem(value: "minimal", child: Text("Minimal")),
                DropdownMenuItem(value: "audit-heavy", child: Text("Audit-heavy")),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() => _privacyProfile = value);
                }
              },
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _preTriggerVisibility,
              decoration: const InputDecoration(labelText: "Visibility before trigger"),
              items: const [
                DropdownMenuItem(value: "none", child: Text("None")),
                DropdownMenuItem(value: "notice_only", child: Text("Notice only")),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() => _preTriggerVisibility = value);
                }
              },
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _postTriggerVisibility,
              decoration: const InputDecoration(labelText: "Visibility after trigger"),
              items: const [
                DropdownMenuItem(value: "existence_only", child: Text("Existence only")),
                DropdownMenuItem(value: "route_only", child: Text("Route only")),
                DropdownMenuItem(value: "route_and_instructions", child: Text("Route and instructions")),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() => _postTriggerVisibility = value);
                }
              },
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _valueDisclosureMode,
              decoration: const InputDecoration(labelText: "Value disclosure"),
              items: const [
                DropdownMenuItem(value: "hidden", child: Text("Hidden")),
                DropdownMenuItem(value: "institution_verified_only", child: Text("Institution verified only")),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() => _valueDisclosureMode = value);
                }
              },
            ),
            const SizedBox(height: 8),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: const Text("Require verification code"),
              value: _requireVerificationCode,
              onChanged: (value) {
                setState(() => _requireVerificationCode = value);
              },
            ),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: const Text("Require TOTP"),
              value: _requireTotp,
              onChanged: (value) {
                setState(() => _requireTotp = value);
              },
            ),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: const Text("One-time access"),
              value: _oneTimeAccess,
              onChanged: (value) {
                setState(() => _oneTimeAccess = value);
              },
            ),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: const Text("Require multisignal"),
              value: _requireMultisignal,
              onChanged: (value) {
                setState(() => _requireMultisignal = value);
              },
            ),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: const Text("Require guardian approval"),
              value: _requireGuardianApproval,
              onChanged: (value) {
                setState(() => _requireGuardianApproval = value);
              },
            ),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: const Text("Require unconfirmed alive status"),
              value: _requireAliveConfirmation,
              onChanged: (value) {
                setState(() => _requireAliveConfirmation = value);
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text("Cancel"),
        ),
        FilledButton(
          onPressed: () {
            final inactivityDays = int.tryParse(_triggerDaysController.text.trim()) ?? widget.entry.trigger.inactivityDays;
            final graceDays = int.tryParse(_graceDaysController.text.trim()) ?? widget.entry.trigger.graceDays;
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
                  relationship: _kind == "self_recovery" ? "owner" : widget.entry.recipient.relationship,
                  deliveryChannel: _recipientChannel,
                  destinationRef: _recipientController.text.trim(),
                  role: _kind == "self_recovery" ? "owner" : widget.entry.recipient.role,
                  registeredLegalName: _kind == "self_recovery"
                      ? "Owner"
                      : _recipientNameController.text.trim(),
                  verificationHint: _kind == "self_recovery"
                      ? ""
                      : _verificationHintController.text.trim(),
                  fallbackChannels: [
                    if (_fallbackEmail) "email",
                    if (_fallbackSms) "sms",
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
                  legalDisclaimerRequired: widget.entry.safeguards.legalDisclaimerRequired,
                ),
                privacy: IntentPrivacyModel(
                  profile: _privacyProfile,
                  minimizeTraceMetadata: widget.entry.privacy.minimizeTraceMetadata,
                  preTriggerVisibility: _preTriggerVisibility,
                  postTriggerVisibility: _postTriggerVisibility,
                  valueDisclosureMode: _valueDisclosureMode,
                ),
              ),
            );
          },
          child: const Text("Apply"),
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
