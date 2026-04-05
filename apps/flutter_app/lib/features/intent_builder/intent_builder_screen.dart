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
  });

  final ProfileModel profile;
  final SafetySettingsModel settings;

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

  @override
  void initState() {
    super.initState();
    _document = _seedDocument();
    _restoreDraft();
    _restoreArtifact();
  }

  Future<void> _restoreArtifact() async {
    try {
      final repository = ref.read(intentCanonicalArtifactRepositoryProvider);
      final history = await repository.loadArtifactHistory(ownerRef: widget.profile.id);
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
      final stored = await repository.loadDraft(ownerRef: widget.profile.id);
      if (!mounted) {
        return;
      }
      setState(() {
        _document = stored ?? _seedDocument();
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
        _document = _seedDocument();
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
        ),
        partnerPath: null,
        status: "draft",
      ),
    ];

    return IntentDocumentModel.initial(
      ownerRef: widget.profile.id,
      defaultPrivacyProfile: widget.settings.tracePrivacyProfile,
    ).copyWith(
      entries: entries,
      globalSafeguards: IntentGlobalSafeguardsModel(
        emergencyPauseEnabled: true,
        defaultGraceDays: widget.settings.gracePeriodDays,
        defaultRemindersDaysBefore: widget.settings.reminderOffsetsDays,
        requireMultisignalBeforeRelease: true,
        requireGuardianApprovalForLegacy: false,
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

  Future<void> _resetDraft() async {
    final seed = _seedDocument();
    await ref.read(intentDraftRepositoryProvider).clearDraft(ownerRef: widget.profile.id);
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
    final artifact = IntentCanonicalArtifactModel(
      artifactId: "artifact_${DateTime.now().toUtc().millisecondsSinceEpoch}",
      promotedFromArtifactId: null,
      contractVersion: "intent-compiler-contract/v1",
      artifactState: IntentArtifactState.exported,
      intentId: _document.intentId,
      ownerRef: _document.ownerRef,
      generatedAt: DateTime.now().toUtc(),
      sourceDraftSignature: buildIntentDocumentSignature(_document),
      activeEntryCount: _document.entries.where((entry) => entry.status == "active").length,
      ptn: ptnPreview,
      trace: buildDraftIntentTrace(_document),
      report: report,
    );
    await ref.read(intentCanonicalArtifactRepositoryProvider).saveArtifact(artifact);
    ref.invalidate(intentCanonicalArtifactProvider(widget.profile.id));
    ref.invalidate(intentCanonicalArtifactHistoryProvider(widget.profile.id));
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

  Future<void> _clearCanonicalArtifact() async {
    await ref.read(intentCanonicalArtifactRepositoryProvider).clearArtifact(ownerRef: widget.profile.id);
    ref.invalidate(intentCanonicalArtifactProvider(widget.profile.id));
    ref.invalidate(intentCanonicalArtifactHistoryProvider(widget.profile.id));
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
        .clearArtifactVersion(ownerRef: widget.profile.id, artifactId: artifactId);
    ref.invalidate(intentCanonicalArtifactProvider(widget.profile.id));
    ref.invalidate(intentCanonicalArtifactHistoryProvider(widget.profile.id));
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
      ownerRef: widget.profile.id,
      artifactId: artifact.artifactId,
    );
    ref.invalidate(intentCanonicalArtifactProvider(widget.profile.id));
    ref.invalidate(intentCanonicalArtifactHistoryProvider(widget.profile.id));
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
    ref.invalidate(intentCanonicalArtifactProvider(widget.profile.id));
    ref.invalidate(intentCanonicalArtifactHistoryProvider(widget.profile.id));
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text("Intent Builder")),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final report = buildDraftIntentCompilerReport(
      document: _document,
      legalAccepted: widget.settings.legalDisclaimerAccepted,
      privateFirstMode: widget.settings.privateFirstMode,
    );
    final ptnPreview = buildDraftIntentPtnPreview(_document);
    final draftSignature = buildIntentDocumentSignature(_document);
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
        title: const Text("Intent Builder"),
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
                  const Text(
                    "This screen is the draft foundation for building intent in plain language before compiling it into PTN.",
                  ),
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
                    Text(
                      _saveMessage!,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF5A4632),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                  if (_loadError != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _loadError!,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.redAccent,
                        fontWeight: FontWeight.w500,
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
  late final TextEditingController _triggerDaysController;
  late final TextEditingController _graceDaysController;
  late String _kind;
  late String _recipientChannel;
  late String _deliveryMethod;
  late String _assetType;
  late String _payloadMode;
  late String _triggerMode;
  late String _privacyProfile;
  late bool _requireVerificationCode;
  late bool _requireTotp;
  late bool _requireGuardianApproval;
  late bool _requireMultisignal;
  late bool _oneTimeAccess;
  late bool _requireAliveConfirmation;

  @override
  void initState() {
    super.initState();
    _displayNameController = TextEditingController(text: widget.entry.asset.displayName);
    _payloadRefController = TextEditingController(text: widget.entry.asset.payloadRef);
    _recipientController = TextEditingController(text: widget.entry.recipient.destinationRef);
    _triggerDaysController = TextEditingController(text: widget.entry.trigger.inactivityDays.toString());
    _graceDaysController = TextEditingController(text: widget.entry.trigger.graceDays.toString());
    _kind = widget.entry.kind;
    _recipientChannel = widget.entry.recipient.deliveryChannel;
    _deliveryMethod = widget.entry.delivery.method;
    _assetType = widget.entry.asset.assetType;
    _payloadMode = widget.entry.asset.payloadMode;
    _triggerMode = widget.entry.trigger.mode;
    _privacyProfile = widget.entry.privacy.profile;
    _requireVerificationCode = widget.entry.delivery.requireVerificationCode;
    _requireTotp = widget.entry.delivery.requireTotp;
    _requireGuardianApproval = widget.entry.safeguards.requireGuardianApproval;
    _requireMultisignal = widget.entry.safeguards.requireMultisignal;
    _oneTimeAccess = widget.entry.delivery.oneTimeAccess;
    _requireAliveConfirmation = widget.entry.trigger.requireUnconfirmedAliveStatus;
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _payloadRefController.dispose();
    _recipientController.dispose();
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
