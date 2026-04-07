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
import 'package:digital_legacy_weaver/features/partner_network/partner_models.dart';
import 'package:digital_legacy_weaver/features/partner_network/verified_ecosystem_catalog_source.dart';
import 'package:digital_legacy_weaver/features/partner_network/verified_partner_catalog_source.dart';
import 'package:digital_legacy_weaver/features/profile/profile_model.dart';
import 'package:digital_legacy_weaver/features/settings/safety_settings_model.dart';
import 'package:digital_legacy_weaver/core/widgets/app_state_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';

// Legacy copy anchors kept for compatibility tests:
// "Add route"
// "Edit route details"
// "Export current version"
// "Policy preview"
// "Version history:"

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

String _destinationCategoryUiLabel(String category) {
  switch (category.trim().toLowerCase()) {
    case 'bank':
      return 'ธนาคาร';
    case 'exchange':
      return 'แพลตฟอร์มซื้อขาย';
    case 'gold':
      return 'ผู้ให้บริการทองคำ';
    case 'legal':
      return 'กฎหมาย';
    default:
      return category;
  }
}

String _destinationStatusUiLabel(String status) {
  switch (status.trim().toLowerCase()) {
    case 'verified':
      return 'ยืนยันแล้ว';
    case 'active':
      return 'พร้อมใช้งาน';
    case 'pending':
      return 'รอตรวจสอบ';
    default:
      return status;
  }
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
  String? _selectedPartnerId;
  bool _partnerTermsAccepted = false;
  bool _partnerCatalogLoading = true;
  String _partnerCatalogSourceLabel = 'admin_config';
  bool _ecosystemCatalogLoading = true;
  String _ecosystemCatalogSourceLabel = 'admin_config';
  bool _showAdvanced = false;
  final Set<String> _selectedDestinationIds = <String>{};
  final TextEditingController _assetValueController =
      TextEditingController(text: '1000000');
  final List<LegalPartnerProfile> _partnerCatalog = [];
  final List<EcosystemDestination> _ecosystemCatalog = [];

  String get _storageOwnerRef => widget.storageOwnerRef ?? widget.profile.id;
  DemoScenario? get _activeScenario =>
      demoScenarioById(_document.metadata["demo_scenario"] as String?);
  String _scenarioTitleHuman(DemoScenario scenario) {
    switch (scenario.id) {
      case 'family_handoff':
        return 'เส้นทางมอบมรดกดิจิทัลให้คนที่คุณรัก';
      case 'self_recovery':
        return 'กู้คืนบัญชีของฉัน';
      case 'private_archive':
        return 'คลังส่วนตัวเข้มงวด';
      default:
        return scenario.title;
    }
  }

  String _scenarioSummaryHuman(DemoScenario scenario) {
    switch (scenario.id) {
      case 'family_handoff':
        return 'เดโมแนะนำที่เห็นภาพครบตั้งแต่เริ่มตั้งค่าไปจนถึงการส่งต่อ';
      case 'self_recovery':
        return 'เริ่มจากป้องกันและกู้คืนบัญชีเจ้าของก่อน ลดความเสี่ยงส่งผิดคน';
      case 'private_archive':
        return 'เหมาะกับข้อมูลอ่อนไหวสูง เน้นความเป็นส่วนตัวมากที่สุด';
      default:
        return scenario.summary;
    }
  }

  LegalPartnerProfile? get _selectedPartner {
    if (_selectedPartnerId == null) return null;
    for (final partner in _partnerCatalog) {
      if (partner.id == _selectedPartnerId) {
        return partner;
      }
    }
    return null;
  }

  List<LegalPartnerProfile> get _verifiedLegalPartners =>
      _partnerCatalog.where((partner) => partner.isVerified).toList();
  List<EcosystemDestination> get _verifiedDestinations =>
      _ecosystemCatalog.where((destination) => destination.isVerified).toList();

  @override
  void initState() {
    super.initState();
    _document = widget.initialDocument ?? _seedDocument();
    _loadVerifiedPartnersFromAdminSource();
    _loadVerifiedEcosystemFromAdminSource();
    _restoreDraft();
    _restoreArtifact();
  }

  @override
  void dispose() {
    _assetValueController.dispose();
    super.dispose();
  }

  void _completeSetupFlow() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("ตั้งค่าเสร็จแล้ว แผนส่งมอบของคุณพร้อมใช้งาน"),
      ),
    );
    Navigator.of(context).maybePop();
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
        _saveMessage =
            stored != null ? "กู้คืนร่างเข้ารหัสจากเครื่องนี้แล้ว" : null;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _document = widget.initialDocument ?? _seedDocument();
        _isLoading = false;
        _loadError = "ยังกู้คืนร่างในเครื่องไม่ได้ตอนนี้ กรุณาลองใหม่อีกครั้ง";
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
          displayName: "ชุดส่งมอบหลัก",
          payloadMode: "secure_link",
          payloadRef: "",
          notes: "ชุดส่งมอบหลักสำหรับผู้รับ",
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
          displayName: "เส้นทางกู้คืนสำรอง",
          payloadMode: "self_recovery_route",
          payloadRef: widget.profile.backupEmail,
          notes: "เส้นทางกู้คืนของเจ้าของบัญชี",
        ),
        recipient: IntentRecipientModel(
          recipientId: "owner_primary",
          relationship: "owner",
          deliveryChannel: "email",
          destinationRef: widget.profile.backupEmail,
          role: "owner",
          registeredLegalName: "เจ้าของบัญชี",
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
      _saveMessage = "รีเซ็ตร่างเข้ารหัสในเครื่องเป็นฉบับใหม่แล้ว";
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
              title: const Text("ส่งต่อให้ผู้รับ"),
              subtitle: const Text(
                "ส่งต่อข้อมูลแบบปลอดภัยให้ผู้รับ เมื่อถึงเงื่อนไขที่ตั้งไว้",
              ),
              onTap: () => Navigator.of(context).pop("legacy_delivery"),
            ),
            ListTile(
              leading: const Icon(Icons.shield_outlined),
              title: const Text("กู้คืนด้วยตัวเอง"),
              subtitle: const Text("เตรียมเส้นทางกู้คืนสำหรับเจ้าของบัญชี"),
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
          ? "เพิ่มร่างกู้คืนด้วยตัวเองและบันทึกในเครื่องแบบเข้ารหัสแล้ว"
          : "เพิ่มร่างส่งต่อให้ผู้รับและบันทึกในเครื่องแบบเข้ารหัสแล้ว",
    );
  }

  Future<void> _editEntry(IntentEntryModel entry) async {
    final updated = await showDialog<IntentEntryModel>(
      context: context,
      builder: (_) => _IntentEntryEditorDialog(
        entry: entry,
        verifiedLegalPartners: _verifiedLegalPartners
            .map((partner) => partner.officeName)
            .toList(),
      ),
    );
    if (updated == null) return;
    await _persistDocument(
      _document.copyWith(
        entries: [
          for (final item in _document.entries)
            item.entryId == entry.entryId ? updated : item,
        ],
      ),
      message: "บันทึกการแก้ไขแบบร่างไว้ในเครื่องแบบเข้ารหัสแล้ว",
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
          "ใช้ตัวอย่าง ${_scenarioTitleHuman(scenario)} แล้ว และบันทึกในเครื่องแบบเข้ารหัสเรียบร้อย",
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
          ? "เปิดใช้งานรายการแล้ว และบันทึกในเครื่องแบบเข้ารหัสเรียบร้อย"
          : "ย้ายรายการกลับเป็นฉบับร่างแล้ว และบันทึกในเครื่องแบบเข้ารหัสเรียบร้อย",
    );
  }

  Future<void> _removeEntry(IntentEntryModel entry) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("ลบรายการฉบับร่าง"),
        content: Text(
          "ต้องการลบ '${entry.asset.displayName}' ออกจากฉบับร่างในเครื่องใช่ไหม? การลบนี้กระทบเฉพาะเครื่องนี้ และยังไม่ส่งมอบข้อมูล",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text("ยกเลิก"),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text("ลบ"),
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
      message: "ลบรายการฉบับร่างจากเครื่องนี้แล้ว",
    );
  }

  Future<void> _exportCanonicalArtifact(
    IntentCompilerReportModel report,
    String ptnPreview,
  ) async {
    if (!report.ok) {
      setState(() {
        _saveMessage = "กรุณาแก้รายการที่ยังบล็อกก่อนสร้างฉบับพร้อมส่ง";
      });
      return;
    }

    final activeEntries = _document.entries.where(
      (entry) => entry.status == "active",
    );
    if (activeEntries.isEmpty) {
      setState(() {
        _saveMessage = "ต้องเปิดใช้งานอย่างน้อย 1 เส้นทางก่อนสร้างฉบับพร้อมส่ง";
      });
      return;
    }

    setState(() {
      _isExporting = true;
    });
    final generatedAt = DateTime.now().toUtc();
    final exportDocument = _redactedDocumentForExport(_document);
    final artifact = IntentCanonicalArtifactModel(
      artifactId: "artifact_${generatedAt.millisecondsSinceEpoch}",
      promotedFromArtifactId: null,
      contractVersion: "intent-compiler-contract/v1",
      artifactState: IntentArtifactState.exported,
      intentId: exportDocument.intentId,
      ownerRef: exportDocument.ownerRef,
      generatedAt: generatedAt,
      sourceDraftSignature: buildIntentDocumentSignature(exportDocument),
      activeEntryCount: exportDocument.entries
          .where((entry) => entry.status == "active")
          .length,
      ptn: _redactMoneyLikeText(ptnPreview),
      trace: buildDraftIntentTrace(exportDocument),
      report: report,
      sealedReleaseCandidate: _buildSealedReleaseCandidate(
        generatedAt,
        exportDocument,
      ),
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
      _saveMessage = "สร้างและผนึกฉบับพร้อมส่งในเครื่องนี้แล้ว";
    });
  }

  SealedReleaseCandidateModel _buildSealedReleaseCandidate(
    DateTime generatedAt,
    IntentDocumentModel sourceDocument,
  ) {
    final activeEntries = sourceDocument.entries.where(
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
            triggerMode: entry.trigger.mode,
            inactivityDays: entry.trigger.inactivityDays,
            graceDays: entry.trigger.graceDays,
            scheduledAtUtc: entry.trigger.scheduledAtUtc,
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
      _saveMessage = "ลบฉบับพร้อมส่งที่ผนึกไว้ ออกจากเครื่องนี้แล้ว";
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
      _saveMessage = "ลบฉบับพร้อมส่งออกจากประวัติในเครื่องแล้ว 1 รายการ";
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
          "คัดลอกเวอร์ชันเก่ามาสร้างฉบับพร้อมส่งใหม่แล้ว เพื่อทบทวนซ้ำโดยไม่เสียประวัติเดิม";
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
      _saveMessage =
          "อัปเดตสถานะฉบับพร้อมส่งเป็น ${_artifactStateLabel(nextState)} แล้ว";
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
      return "เงื่อนไขสถานะ: ต้องเปิดใช้งานอย่างน้อย 1 รายการก่อนตั้งเป็นพร้อมใช้งาน";
    }
    if (artifact.report.errorCount > 0) {
      return "เงื่อนไขสถานะ: ต้องแก้ปัญหาแบบบล็อกก่อน จึงจะตรวจทานหรือพร้อมใช้งานได้";
    }
    if (artifact.artifactState == IntentArtifactState.exported) {
      return "เงื่อนไขสถานะ: หลังสร้างฉบับพร้อมส่งแล้ว ให้ตรวจทานได้เมื่อไม่มีปัญหาแบบบล็อกและยังมีรายการที่เปิดใช้งาน";
    }
    if (artifact.artifactState == IntentArtifactState.reviewed &&
        !artifactInSync) {
      return "เงื่อนไขสถานะ: ฉบับที่ตรวจทานแล้วจะพร้อมใช้งานได้ เมื่อร่างล่าสุดยังตรงกับฉบับนี้";
    }
    if (artifact.artifactState == IntentArtifactState.reviewed &&
        artifactInSync) {
      return "เงื่อนไขสถานะ: ฉบับนี้พร้อมเลื่อนไปสถานะพร้อมใช้งาน เพราะร่างล่าสุดยังตรงกัน";
    }
    if (artifact.artifactState == IntentArtifactState.ready) {
      return "เงื่อนไขสถานะ: สถานะพร้อมใช้งานจะเชื่อถือได้ ตราบใดที่ร่างล่าสุดยังตรงกับฉบับนี้";
    }
    return "เงื่อนไขสถานะ: ให้สร้างฉบับพร้อมส่งก่อน จากนั้นตรวจทาน แล้วค่อยตั้งเป็นพร้อมใช้งาน";
  }

  String _artifactStateLabel(IntentArtifactState state) {
    switch (state) {
      case IntentArtifactState.draft:
        return "แบบร่าง";
      case IntentArtifactState.exported:
        return "ฉบับพร้อมส่ง";
      case IntentArtifactState.reviewed:
        return "ตรวจทานแล้ว";
      case IntentArtifactState.ready:
        return "พร้อมใช้งาน";
    }
  }

  String _buildPolicyPaper(IntentCanonicalArtifactModel artifact) {
    final sealedEntries = artifact.sealedReleaseCandidate.entries;
    final primary = sealedEntries.isNotEmpty ? sealedEntries.first : null;
    final beneficiaryName =
        widget.profile.beneficiaryName?.trim().isNotEmpty == true
            ? widget.profile.beneficiaryName!.trim()
            : "ผู้รับหลัก";
    final beneficiaryEmail =
        widget.profile.beneficiaryEmail?.trim().isNotEmpty == true
            ? widget.profile.beneficiaryEmail!.trim()
            : "beneficiary@example.com";
    final inactivity = widget.profile.legacyInactivityDays;
    final grace = _document.globalSafeguards.defaultGraceDays;
    final verifyLevel =
        primary?.partnerVerificationRequired == true ? "high" : "standard";
    final partner = _selectedPartner;
    final selectedDestinations = _verifiedDestinations
        .where(
            (destination) => _selectedDestinationIds.contains(destination.id))
        .map((destination) => destination.name)
        .toList();
    final partnerLine = partner == null
        ? "ยังไม่ได้เลือก"
        : "${partner.officeName} (${partner.province})";
    final destinationLine = selectedDestinations.isEmpty
        ? "ยังไม่ได้เลือก"
        : selectedDestinations.join(", ");

    return '''
เอกสารสรุปนโยบายมรดกดิจิทัล (ฉบับสุดท้าย)

ส่วนที่ 1: สรุปเจตจำนง
- ชื่อแผน: แผนส่งมอบมรดกดิจิทัลให้ครอบครัว
- เจ้าของแผน: ${widget.profile.id}
- ผู้รับ: $beneficiaryName ($beneficiaryEmail)
- ระดับความเป็นส่วนตัว: ${widget.settings.tracePrivacyProfile}
- รหัสเอกสาร: ${artifact.artifactId}
- เวลาสร้างเอกสาร: ${artifact.generatedAt.toLocal()}

ส่วนที่ 2: เงื่อนไขการส่งมอบ
- เริ่มตรวจการส่งมอบเมื่อขาดการติดต่อครบ $inactivity วัน
- รอช่วงยืนยันความปลอดภัยเพิ่มเติมอีก $grace วันก่อนปล่อยข้อมูล
- ระดับการยืนยันตัวตน: $verifyLevel
- เวลาหน่วงก่อนเปิดข้อมูลจริง: 24 ชั่วโมง

ส่วนที่ 3: สิทธิ์และการเข้าถึง
- สิทธิ์ผู้รับ: เข้าถึงแพ็กข้อมูลแบบอ่านอย่างเดียว
- บทบาทระบบ: ตรวจเงื่อนไขและส่งมอบผ่านช่องทางที่อนุมัติไว้
- ช่องทางส่งมอบหลัก: ${primary?.releaseChannel ?? "secure_link"}

ส่วนที่ 4: พาร์ทเนอร์และปลายทาง
- สำนักงานกฎหมาย: $partnerLine
- ปลายทางสถาบัน: $destinationLine
- สถานะการยอมรับค่าธรรมเนียมพาร์ทเนอร์: ${_partnerTermsAccepted ? "ยอมรับแล้ว" : "ยังไม่ยอมรับ"}

หมายเหตุ
- สรุปนี้อ้างอิงจากฉบับพร้อมส่งล่าสุด
- แอปไม่เก็บยอดเงินจริง และไม่ถือครองเงินผู้ใช้
- ยอดเงินจริงต้องตรวจสอบกับปลายทางโดยตรง (ธนาคาร/Exchange/พาร์ทเนอร์กฎหมาย)
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
        title: const Text("เอกสารสรุปนโยบาย"),
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
                  "QR สำหรับตรวจสอบเอกสาร",
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Center(
                  child: QrImageView(
                    data: verifyUrl,
                    size: 140,
                    eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square),
                    dataModuleStyle: const QrDataModuleStyle(
                      dataModuleShape: QrDataModuleShape.square,
                    ),
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
            child: const Text("ปิด"),
          ),
          FilledButton.tonal(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: paper));
              messenger.showSnackBar(
                const SnackBar(content: Text("คัดลอกเอกสารสรุปนโยบายแล้ว")),
              );
            },
            child: const Text("คัดลอกเอกสาร"),
          ),
        ],
      ),
    );
  }

  List<String> _artifactBadges(IntentCanonicalArtifactModel artifact) {
    final badges = <String>[];
    if (_artifact != null && artifact.artifactId == _artifact!.artifactId) {
      badges.add("ล่าสุด");
    }
    if (artifact.promotedFromArtifactId != null &&
        artifact.promotedFromArtifactId!.isNotEmpty) {
      badges.add("คัดลอกมา");
    }
    if (artifact.artifactState == IntentArtifactState.ready) {
      badges.add("พร้อมใช้งาน");
    } else if (artifact.artifactState == IntentArtifactState.reviewed) {
      badges.add("ตรวจทานแล้ว");
    }
    if (artifact.report.errorCount > 0) {
      badges.add("มีปัญหา");
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
    return AppStatePanel(
      message: message,
      tone: isError ? AppStateTone.error : AppStateTone.success,
      actionLabel: isError && onRetry != null ? "ลองใหม่" : null,
      onAction: isError ? onRetry : null,
      compact: true,
    );
  }

  double _assetValueOrFallback() {
    final raw = _assetValueController.text.replaceAll(',', '').trim();
    final parsed = double.tryParse(raw);
    if (parsed == null || parsed <= 0) {
      return 1000000;
    }
    return parsed;
  }

  String _money(double amount) {
    final rounded = amount.round();
    final raw = rounded.toString();
    final parts = <String>[];
    for (var i = raw.length; i > 0; i -= 3) {
      final start = i - 3 < 0 ? 0 : i - 3;
      parts.insert(0, raw.substring(start, i));
    }
    return parts.join(',');
  }

  String _redactMoneyLikeText(String input) {
    if (input.trim().isEmpty) {
      return input;
    }
    var output = input;
    output = output.replaceAllMapped(
      RegExp(
        r'\\b(thb|baht|usd|eur|บาท)\\s*[\\d,]+(?:\\.\\d{1,2})?\\b',
        caseSensitive: false,
      ),
      (_) => '[institution-verified amount]',
    );
    output = output.replaceAllMapped(
      RegExp(r'(?<!\w)[\d]{1,3}(?:,[\d]{3})+(?:\.\d{1,2})?(?!\w)'),
      (_) => '[institution-verified amount]',
    );
    output = output.replaceAllMapped(
      RegExp(
        r'(?<!\\w)[\\d]{5,}(?:\\.\\d{1,2})?\\s*(thb|baht|บาท)?(?!\\w)',
        caseSensitive: false,
      ),
      (_) => '[institution-verified amount]',
    );
    return output;
  }

  IntentDocumentModel _redactedDocumentForExport(IntentDocumentModel source) {
    return source.copyWith(
      entries: [
        for (final entry in source.entries)
          entry.copyWith(
            asset: IntentAssetModel(
              assetId: entry.asset.assetId,
              assetType: entry.asset.assetType,
              displayName: entry.asset.displayName,
              payloadMode: entry.asset.payloadMode,
              payloadRef: _redactMoneyLikeText(entry.asset.payloadRef),
              notes: entry.asset.notes == null
                  ? null
                  : _redactMoneyLikeText(entry.asset.notes!),
            ),
          ),
      ],
    );
  }

  Future<void> _loadVerifiedPartnersFromAdminSource() async {
    try {
      final source = VerifiedPartnerCatalogSource();
      final result = await source.loadVerifiedPartners();
      if (!mounted) {
        return;
      }
      setState(() {
        _partnerCatalog
          ..clear()
          ..addAll(result.partners);
        _partnerCatalogSourceLabel = result.source;
        _partnerCatalogLoading = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _partnerCatalog.clear();
        _partnerCatalogSourceLabel = 'unavailable';
        _partnerCatalogLoading = false;
      });
    }
  }

  Future<void> _loadVerifiedEcosystemFromAdminSource() async {
    try {
      final source = VerifiedEcosystemCatalogSource();
      final result = await source.loadVerifiedDestinations();
      if (!mounted) {
        return;
      }
      setState(() {
        _ecosystemCatalog
          ..clear()
          ..addAll(result.destinations);
        _ecosystemCatalogSourceLabel = result.source;
        _ecosystemCatalogLoading = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _ecosystemCatalog.clear();
        _ecosystemCatalogSourceLabel = 'unavailable';
        _ecosystemCatalogLoading = false;
      });
    }
  }

  String _partnerCatalogSourceText() {
    switch (_partnerCatalogSourceLabel) {
      case 'admin_api':
        return 'แหล่งข้อมูล: ระบบกลางที่ยืนยันแล้ว';
      case 'admin_config':
        return 'แหล่งข้อมูล: รายการสำรองในแอป';
      case 'unavailable':
        return 'ตอนนี้ยังดึงรายชื่อจากระบบกลางไม่ได้';
      default:
        return 'แหล่งข้อมูล: $_partnerCatalogSourceLabel';
    }
  }

  String _ecosystemCatalogSourceText() {
    switch (_ecosystemCatalogSourceLabel) {
      case 'admin_api':
        return 'แหล่งข้อมูล: ระบบกลางที่ยืนยันแล้ว';
      case 'admin_config':
        return 'แหล่งข้อมูล: รายการสำรองในแอป';
      case 'unavailable':
        return 'ตอนนี้ยังดึงรายชื่อจากระบบกลางไม่ได้';
      default:
        return 'แหล่งข้อมูล: $_ecosystemCatalogSourceLabel';
    }
  }

  Widget _buildPartnerNetworkCard() {
    final scheme = Theme.of(context).colorScheme;
    final assetValue = _assetValueOrFallback();
    final selected = _selectedPartner;
    final estimate = selected?.estimate(assetValue);
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.45)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    "เครือข่ายสำนักงานกฎหมาย",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                ),
                IconButton(
                  tooltip: 'รีเฟรชรายชื่อพาร์ทเนอร์',
                  onPressed: _partnerCatalogLoading
                      ? null
                      : () {
                          setState(() => _partnerCatalogLoading = true);
                          _loadVerifiedPartnersFromAdminSource();
                        },
                  icon: const Icon(Icons.refresh_rounded),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              "เลือกสำนักงานกฎหมายที่ผ่านการตรวจสอบแล้ว พร้อมตารางค่าธรรมเนียมที่โปร่งใสก่อนส่งมอบงานจริง",
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                color: scheme.surfaceContainerHighest,
                border: Border.all(
                  color: scheme.outlineVariant.withValues(alpha: 0.55),
                ),
              ),
              child: Text(
                _partnerCatalogSourceText(),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _assetValueController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: "มูลค่าประมาณการ (THB)",
                prefixText: "THB ",
                filled: true,
                fillColor:
                    scheme.surfaceContainerHighest.withValues(alpha: 0.35),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            if (_partnerCatalogLoading) ...[
              const LinearProgressIndicator(minHeight: 4),
              const SizedBox(height: 8),
              const Text(
                "กำลังอัปเดตรายชื่อพาร์ทเนอร์ที่ผ่านการตรวจสอบ...",
              ),
              const SizedBox(height: 12),
            ],
            const Text(
              "แสดงเฉพาะพาร์ทเนอร์ที่ผ่านการยืนยันแล้วเท่านั้น",
            ),
            const SizedBox(height: 12),
            if (_verifiedLegalPartners.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: scheme.surfaceContainerLowest,
                  border: Border.all(
                    color: scheme.outlineVariant.withValues(alpha: 0.5),
                  ),
                ),
                child: const Text(
                  "ยังไม่มีสำนักงานกฎหมายที่ผ่านการยืนยันจากระบบกลาง เมื่อรายชื่อได้รับอนุมัติแล้วจะแสดงที่นี่อัตโนมัติ",
                ),
              ),
            ..._verifiedLegalPartners.map((partner) {
              final isSelected = _selectedPartnerId == partner.id;
              final fee = partner.estimate(assetValue);
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    color: isSelected
                        ? scheme.tertiaryContainer.withValues(alpha: 0.45)
                        : scheme.surfaceContainerLowest,
                    border: Border.all(
                      color:
                          isSelected ? scheme.tertiary : scheme.outlineVariant,
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              partner.officeName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          if (partner.isVerified)
                            const _Pill(label: "ยืนยันแล้ว"),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "${partner.province} • SLA ${partner.slaHours} ชม. • คะแนนรีวิว ${partner.rating.toStringAsFixed(1)}",
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "ค่าธรรมเนียมรวมโดยประมาณ: THB ${_money(fee.totalFee)} (สำนักงาน ${fee.officePercent.toStringAsFixed(2)}% + ทนาย ${fee.lawyerPercent.toStringAsFixed(2)}% + แพลตฟอร์ม ${fee.platformPercent.toStringAsFixed(2)}%)",
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: partner.officeFeeTiers
                            .map(
                              (tier) => _Pill(
                                label:
                                    "สำนักงาน ${tier.rangeLabel()} = ${tier.percent.toStringAsFixed(2)}%",
                              ),
                            )
                            .toList(),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "หมายเหตุ: ${partner.otherFeeNote}",
                        style: const TextStyle(fontSize: 12),
                      ),
                      const SizedBox(height: 8),
                      FilledButton.tonal(
                        onPressed: () {
                          setState(() {
                            _selectedPartnerId = partner.id;
                            _partnerTermsAccepted = false;
                          });
                        },
                        child: Text(
                          isSelected ? "เลือกแล้ว" : "เลือกสำนักงานนี้",
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
            if (selected != null && estimate != null) ...[
              const SizedBox(height: 8),
              CheckboxListTile(
                value: _partnerTermsAccepted,
                contentPadding: EdgeInsets.zero,
                onChanged: (value) {
                  setState(() => _partnerTermsAccepted = value ?? false);
                },
                title: Text(
                  "ยอมรับเงื่อนไขค่าธรรมเนียมของ ${selected.officeName} (ประมาณ THB ${_money(estimate.totalFee)}) ก่อนส่งมอบงาน",
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEcosystemCard() {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.45)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "ปลายทางสถาบันที่พร้อมรับเอกสาร",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            const Text(
              "เลือกสถาบันปลายทางที่จะรับเอกสารสรุปและคำขอ โดยแอปจะไม่ทำการโอนหรือสั่งธุรกรรมอัตโนมัติ",
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                color: scheme.surfaceContainerHighest,
                border: Border.all(
                  color: scheme.outlineVariant.withValues(alpha: 0.55),
                ),
              ),
              child: Text(
                _ecosystemCatalogSourceText(),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (_ecosystemCatalogLoading) ...[
              const LinearProgressIndicator(minHeight: 4),
              const SizedBox(height: 8),
              const Text(
                "กำลังอัปเดตรายชื่อปลายทางที่ผ่านการตรวจสอบ...",
              ),
              const SizedBox(height: 12),
            ],
            Row(
              children: [
                const Expanded(
                  child: Text("แสดงเฉพาะปลายทางที่ผ่านการยืนยันแล้ว"),
                ),
                IconButton(
                  tooltip: 'อัปเดตรายชื่อปลายทาง',
                  onPressed: _ecosystemCatalogLoading
                      ? null
                      : () {
                          setState(() => _ecosystemCatalogLoading = true);
                          _loadVerifiedEcosystemFromAdminSource();
                        },
                  icon: const Icon(Icons.refresh_rounded),
                ),
              ],
            ),
            if (_verifiedDestinations.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: scheme.surfaceContainerLowest,
                  border: Border.all(
                    color: scheme.outlineVariant.withValues(alpha: 0.5),
                  ),
                ),
                child: const Text(
                  "ยังไม่มีปลายทางสถาบันที่ผ่านการยืนยัน เมื่อระบบกลางอัปเดตรายชื่อแล้วจะแสดงที่นี่อัตโนมัติ",
                ),
              ),
            ..._verifiedDestinations.map((destination) {
              final enabled = _selectedDestinationIds.contains(destination.id);
              return SwitchListTile.adaptive(
                value: enabled,
                contentPadding: EdgeInsets.zero,
                onChanged: (value) {
                  setState(() {
                    if (value) {
                      _selectedDestinationIds.add(destination.id);
                    } else {
                      _selectedDestinationIds.remove(destination.id);
                    }
                  });
                },
                title: Text(destination.name),
                subtitle: Text(
                  "${_destinationCategoryUiLabel(destination.category)} • ${_destinationStatusUiLabel(destination.status)} • ${destination.note}",
                ),
              );
            }),
            if (_selectedDestinationIds.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                "จำนวนปลายทางที่เลือก: ${_selectedDestinationIds.length}",
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final screenTitle = widget.screenTitle ?? "แผนส่งมอบของคุณ";
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text(screenTitle)),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: AppStatePanel(
              title: "กำลังเตรียมแผนของคุณ",
              message:
                  "กำลังโหลดร่างเข้ารหัสในเครื่องและประวัติเวอร์ชันล่าสุด...",
              tone: AppStateTone.loading,
              layout: AppStateLayout.centered,
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
        "ขั้นที่ 2 จาก 3: ตั้งค่าแผนด้วยภาษาง่ายๆ แล้วกดยืนยัน";
    final demoScenarioTitle = _activeScenario != null
        ? _scenarioTitleHuman(_activeScenario!)
        : _document.metadata["demo_title"] as String?;
    final demoScenarioSummary = _activeScenario != null
        ? _scenarioSummaryHuman(_activeScenario!)
        : _document.metadata["demo_summary"] as String?;
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
    final partnerTermsGateSatisfied =
        _selectedPartnerId == null || _partnerTermsAccepted;
    final canCreateVersion = !_isExporting && partnerTermsGateSatisfied;
    final isCompact = MediaQuery.of(context).size.width < 760;
    final pagePadding = EdgeInsets.symmetric(
      horizontal: isCompact ? 14 : 20,
      vertical: isCompact ? 14 : 20,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(screenTitle),
        actions: [
          Row(
            children: [
              const Text("โหมดขั้นสูง"),
              Switch.adaptive(
                value: _showAdvanced,
                onChanged: (value) {
                  setState(() {
                    _showAdvanced = value;
                  });
                },
              ),
            ],
          ),
          TextButton(
            onPressed: _hasLocalDraft ? _resetDraft : null,
            child: const Text("เริ่มใหม่"),
          ),
        ],
      ),
      body: ListView(
        padding: pagePadding,
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        physics: const BouncingScrollPhysics(),
        children: [
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: scheme.outlineVariant.withValues(alpha: 0.45),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "ขั้นที่ 2 จาก 3: จัดแผนให้พร้อม",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Text(screenSubtitle),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: scheme.tertiaryContainer.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: scheme.outlineVariant.withValues(alpha: 0.5),
                      ),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "ทำตามนี้ได้เลย",
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        SizedBox(height: 6),
                        Text(
                            "1. มีรายการส่งต่อที่เปิดใช้งานอย่างน้อย 1 รายการ"),
                        SizedBox(height: 4),
                        Text("2. สร้างฉบับพร้อมส่ง แล้วดูคำเตือน"),
                        SizedBox(height: 4),
                        Text(
                            "3. กดพร้อมใช้งาน เมื่อร่างล่าสุดตรงกับฉบับพร้อมส่ง"),
                      ],
                    ),
                  ),
                  if (demoScenarioTitle != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: scheme.surfaceContainerHighest.withValues(
                          alpha: 0.5,
                        ),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: scheme.outlineVariant.withValues(alpha: 0.45),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "จากหน้าเริ่มต้น: $demoScenarioTitle",
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
                  FilledButton.icon(
                    onPressed: canMarkReady ? _completeSetupFlow : null,
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text("เสร็จสิ้นการตั้งค่า"),
                  ),
                  if (!canMarkReady) ...[
                    const SizedBox(height: 8),
                    Text(
                      "ต้องมีรายการที่เปิดใช้งานอย่างน้อย 1 รายการ สร้างฉบับพร้อมส่ง และตรวจทานก่อน",
                      style: TextStyle(
                        color: scheme.onSurfaceVariant,
                        fontSize: 12,
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
                            ? "บันทึกร่างในเครื่อง: เปิดอยู่"
                            : "ใช้ค่าตั้งต้นเริ่มต้น",
                      ),
                      _Pill(
                        label:
                            "ระดับความเป็นส่วนตัว: ${_document.defaultPrivacyProfile}",
                      ),
                      _Pill(
                          label: "รายการทั้งหมด: ${_document.entries.length}"),
                      _Pill(label: "เปิดใช้งาน: $activeEntryCount"),
                      _Pill(
                        label: "ฉบับที่บันทึก: ${_artifactHistory.length}",
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
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: scheme.outlineVariant.withValues(alpha: 0.45),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "เริ่มเร็วด้วยตัวอย่าง",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "เลือกตัวอย่าง 1 แบบเพื่อเติมข้อมูลอัตโนมัติ แล้วค่อยแก้ให้ตรงกับเคสจริงของคุณ",
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final scenario in demoScenarios)
                        ChoiceChip(
                          label: Text(_scenarioTitleHuman(scenario)),
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
                        color: scheme.surfaceContainerHighest.withValues(
                          alpha: 0.5,
                        ),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: scheme.outlineVariant.withValues(alpha: 0.45),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "ตัวอย่างที่เลือก: ${_scenarioTitleHuman(_activeScenario!)}",
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 6),
                          Text(_scenarioSummaryHuman(_activeScenario!)),
                          if (demoScenarioNextStep != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              "ขั้นถัดไป: $demoScenarioNextStep",
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
          _buildPartnerNetworkCard(),
          const SizedBox(height: 12),
          _buildEcosystemCard(),
          const SizedBox(height: 12),
          Card(
            color: scheme.primaryContainer.withValues(alpha: 0.28),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: scheme.outlineVariant.withValues(alpha: 0.45),
              ),
            ),
            child: const Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "ร่างส่วนตัวในเครื่อง",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "แผนของคุณถูกเข้ารหัสในเครื่องนี้ และจะยังไม่เผยแพร่จนกว่าจะสร้างฉบับพร้อมส่งและยืนยันความพร้อม",
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: scheme.outlineVariant.withValues(alpha: 0.45),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "การยืนยันร่วมกันและโหมดฉุกเฉิน",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "ใช้การยืนยันร่วมกันกับการส่งมอบที่สำคัญ และแยกโหมดฉุกเฉินไว้สำหรับกรณีเจ้าของไม่สามารถตอบสนองได้",
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    title: const Text("เปิดใช้การยืนยันร่วมกัน"),
                    subtitle: const Text(
                      "แนะนำให้ใช้ 2 จาก 3 คน สำหรับการส่งมอบที่สำคัญ",
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
                        message: "อัปเดตการตั้งค่าการยืนยันร่วมกันแล้ว",
                      );
                    },
                  ),
                  if (_document.globalSafeguards.guardianQuorumEnabled) ...[
                    const SizedBox(height: 8),
                    Text(
                      "เกณฑ์ยืนยันปัจจุบัน: ${_document.globalSafeguards.guardianQuorumRequired} จาก ${_document.globalSafeguards.guardianQuorumPoolSize} คน",
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<int>(
                      initialValue:
                          _document.globalSafeguards.guardianQuorumPoolSize,
                      decoration: const InputDecoration(
                        labelText: "จำนวนผู้ยืนยันทั้งหมด",
                      ),
                      items: const [
                        DropdownMenuItem(value: 2, child: Text("2 คน")),
                        DropdownMenuItem(value: 3, child: Text("3 คน")),
                        DropdownMenuItem(value: 4, child: Text("4 คน")),
                        DropdownMenuItem(value: 5, child: Text("5 คน")),
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
                          message: "อัปเดตจำนวนผู้ยืนยันทั้งหมดแล้ว",
                        );
                      },
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<int>(
                      initialValue:
                          _document.globalSafeguards.guardianQuorumRequired,
                      decoration: const InputDecoration(
                        labelText: "จำนวนผู้ยืนยันที่ต้องครบ",
                      ),
                      items: List.generate(
                        _document.globalSafeguards.guardianQuorumPoolSize,
                        (index) => DropdownMenuItem(
                          value: index + 1,
                          child: Text("${index + 1} คน"),
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
                          message: "อัปเดตจำนวนผู้ยืนยันที่ต้องครบแล้ว",
                        );
                      },
                    ),
                  ],
                  const SizedBox(height: 12),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    title: const Text("เปิดใช้โหมดฉุกเฉิน"),
                    subtitle: const Text(
                      "ใช้เมื่อเจ้าของไม่สามารถตอบสนองได้เท่านั้น (เช่น ICU) แยกจากการส่งมอบตามการขาดการติดต่อ",
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
                        message: "อัปเดตการตั้งค่าโหมดฉุกเฉินแล้ว",
                      );
                    },
                  ),
                  if (_document.globalSafeguards.emergencyAccessEnabled) ...[
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text("ต้องมีคำขอจากผู้รับก่อน"),
                      subtitle: const Text(
                        "โหมดฉุกเฉินจะเริ่มเมื่อผู้รับยื่นคำขออย่างชัดเจน",
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
                          message: "อัปเดตเงื่อนไขคำขอจากผู้รับแล้ว",
                        );
                      },
                    ),
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text("ต้องผ่านการยืนยันร่วมกัน"),
                      subtitle: const Text(
                        "แนะนำให้เปิดไว้ เพื่อให้โหมดฉุกเฉินโปร่งใสและตรวจสอบย้อนหลังได้",
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
                              "อัปเดตเงื่อนไขการยืนยันร่วมกันในโหมดฉุกเฉินแล้ว",
                        );
                      },
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "ระยะเวลารอก่อนปลดโหมดฉุกเฉิน: ${_document.globalSafeguards.emergencyAccessGraceHours} ชั่วโมง",
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
                          message: "อัปเดตระยะเวลารอโหมดฉุกเฉินแล้ว",
                        );
                      },
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (isCompact)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "รายการส่งต่อที่คุณดูแล",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                FilledButton.tonal(
                  onPressed: () {
                    _addDraftEntry();
                  },
                  child: const Text("เพิ่มรายการส่งต่อ"),
                ),
              ],
            )
          else
            Row(
              children: [
                const Expanded(
                  child: Text(
                    "รายการส่งต่อที่คุณดูแล",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                ),
                FilledButton.tonal(
                  onPressed: () {
                    _addDraftEntry();
                  },
                  child: const Text("เพิ่มรายการส่งต่อ"),
                ),
              ],
            ),
          const SizedBox(height: 12),
          if (_document.entries.isEmpty)
            Card(
              color: const Color(0xFFF9F4EC),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.playlist_add_check_circle_outlined,
                      color: Color(0xFF866141),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "ยังไม่มีรายการส่งต่อ",
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "เริ่มด้วยอย่างน้อย 1 รายการ เช่น ส่งต่อให้ครอบครัว หรือกู้คืนด้วยตัวเอง",
                    ),
                    const SizedBox(height: 10),
                    FilledButton.tonal(
                      onPressed: _addDraftEntry,
                      child: const Text("เพิ่มรายการแรก"),
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
          if (_showAdvanced) ...[
            IntentReviewCard(report: report),
            const SizedBox(height: 12),
          ],
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "ยืนยันแผนฉบับพร้อมใช้งาน",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "สร้างฉบับพร้อมส่งของแผน ตรวจทาน แล้วตั้งเป็นพร้อมใช้งาน",
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      FilledButton.icon(
                        onPressed: canCreateVersion
                            ? () {
                                _exportCanonicalArtifact(report, ptnPreview);
                              }
                            : null,
                        icon: const Icon(Icons.publish_rounded),
                        label: Text(
                          _isExporting ? "กำลังสร้าง..." : "สร้างฉบับพร้อมส่ง",
                        ),
                      ),
                      if (!partnerTermsGateSatisfied)
                        const Padding(
                          padding: EdgeInsets.only(top: 6),
                          child: Text(
                            "โปรดยอมรับเงื่อนไขค่าธรรมเนียมพาร์ทเนอร์ก่อนสร้างฉบับพร้อมส่ง",
                            style: TextStyle(
                              color: Color(0xFF8A5A00),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      OutlinedButton(
                        onPressed:
                            _artifact == null ? null : _clearCanonicalArtifact,
                        child: const Text("ล้างฉบับนี้"),
                      ),
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
                        child: const Text("ตรวจทานฉบับนี้"),
                      ),
                    ],
                  ),
                  if (_artifact != null) ...[
                    const SizedBox(height: 12),
                    _Pill(
                      label:
                          "สร้างล่าสุด: ${_artifact!.generatedAt.toLocal().toString()}",
                    ),
                    if (_showAdvanced) ...[
                      const SizedBox(height: 8),
                      Text("สัญญาเวอร์ชัน: ${_artifact!.contractVersion}"),
                      const SizedBox(height: 4),
                      Text(
                        "สถานะฉบับพร้อมส่ง: ${_artifactStateLabel(_artifact!.artifactState)}",
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "รายการที่เปิดใช้งานในฉบับนี้: ${_artifact!.activeEntryCount}",
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "ร่องรอยการทำงาน: ${(_artifact!.trace["entries"] as Map?)?.length ?? 0}",
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "สถานะปัญหา: บล็อก ${_artifact!.report.errorCount} / คำเตือน ${_artifact!.report.warningCount}",
                      ),
                    ] else ...[
                      const SizedBox(height: 8),
                      Text(
                        "ปัญหา: บล็อก ${_artifact!.report.errorCount} / คำเตือน ${_artifact!.report.warningCount}",
                      ),
                    ],
                    const SizedBox(height: 8),
                    Text(
                      artifactInSync
                          ? "สถานะ: ร่างล่าสุดตรงกับฉบับพร้อมส่ง"
                          : "สถานะ: มีการแก้ร่างหลังสร้างฉบับพร้อมส่งล่าสุด",
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
                          child: const Text("ดูเอกสารสรุปนโยบาย"),
                        ),
                        OutlinedButton(
                          onPressed: canMarkReviewed
                              ? () {
                                  _transitionArtifactState(
                                    IntentArtifactState.reviewed,
                                  );
                                }
                              : null,
                          child: const Text("ทำเครื่องหมายว่าตรวจแล้ว"),
                        ),
                        OutlinedButton(
                          onPressed: canMarkReady
                              ? () {
                                  _transitionArtifactState(
                                    IntentArtifactState.ready,
                                  );
                                }
                              : null,
                          child: const Text("ตั้งเป็นพร้อมใช้งาน"),
                        ),
                      ],
                    ),
                  ] else ...[
                    const SizedBox(height: 12),
                    Text(
                      activeEntryCount > 0
                          ? "ยังไม่มีฉบับพร้อมส่งสำหรับร่างที่กำลังใช้งาน"
                          : "โปรดเปิดใช้งานอย่างน้อย 1 รายการก่อนสร้างฉบับพร้อมส่ง",
                    ),
                  ],
                  if (_artifactHistory.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    if (_showAdvanced) ...[
                      const Text(
                        "ประวัติฉบับพร้อมส่ง",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "ทุกการสร้างฉบับพร้อมส่งจะถูกเก็บแยกเป็นประวัติในเครื่อง",
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
                          child: const Text("ดูประวัติทั้งหมด"),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ] else ...[
                      Text(
                        "ฉบับที่บันทึกไว้: ${_artifactHistory.length} (เปิดโหมดขั้นสูงเพื่อจัดการประวัติทั้งหมด)",
                      ),
                      const SizedBox(height: 12),
                    ],
                    if (_showAdvanced)
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          ChoiceChip(
                            label: const Text("ทั้งหมด"),
                            selected: _historyFilter == 'all',
                            onSelected: (_) {
                              setState(() {
                                _historyFilter = 'all';
                              });
                            },
                          ),
                          ChoiceChip(
                            label: const Text("พร้อมใช้งาน"),
                            selected: _historyFilter == 'ready',
                            onSelected: (_) {
                              setState(() {
                                _historyFilter = 'ready';
                              });
                            },
                          ),
                          ChoiceChip(
                            label: const Text("คัดลอกมา"),
                            selected: _historyFilter == 'promoted',
                            onSelected: (_) {
                              setState(() {
                                _historyFilter = 'promoted';
                              });
                            },
                          ),
                          ChoiceChip(
                            label: const Text("มีปัญหา"),
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
                                child: Text("ใหม่สุดก่อน"),
                              ),
                              DropdownMenuItem(
                                value: 'oldest',
                                child: Text("เก่าสุดก่อน"),
                              ),
                              DropdownMenuItem(
                                value: 'state',
                                child: Text("เรียงตามสถานะ"),
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
                    if (_showAdvanced && visibleArtifactHistory.isEmpty)
                      const Text(
                        "ไม่มีรายการที่ตรงกับตัวกรองประวัติ",
                      ),
                    ...visibleArtifactHistory.take(_showAdvanced ? 5 : 1).map(
                          (item) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(
                                "${item.generatedAt.toLocal()} | ${_artifactStateLabel(item.artifactState)}",
                              ),
                              subtitle: Text(
                                "รหัส ${item.artifactId} | รายการที่เปิดใช้งาน ${item.activeEntryCount}",
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
                                    child: const Text("ตรวจทาน"),
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
                                    child: const Text("เปรียบเทียบ"),
                                  ),
                                  TextButton(
                                    onPressed: _artifact != null &&
                                            item.artifactId !=
                                                _artifact!.artifactId
                                        ? () {
                                            _promoteArtifactVersion(item);
                                          }
                                        : null,
                                    child: const Text("คัดลอก"),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      _clearArtifactVersion(item.artifactId);
                                    },
                                    child: const Text("ลบ"),
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
                    "แผนนี้ทำงานอย่างไร",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "อ่านสรุปแบบเข้าใจง่ายก่อน รายละเอียดเชิงเทคนิคจะแสดงเมื่อเปิดโหมดขั้นสูงเท่านั้น",
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
                          "ลำดับการทำงานแบบย่อ",
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        SizedBox(height: 8),
                        Text(
                            "1) ถึงเงื่อนไขวันเวลา หรือขาดการติดต่อที่ตั้งไว้"),
                        Text("2) ระบบตรวจความปลอดภัยก่อนทุกครั้ง"),
                        Text("3) ผู้รับเห็นขั้นตอนที่ชัดเจนและทำตามได้ทันที"),
                        Text("4) ทุกเหตุการณ์ถูกบันทึกไว้เพื่อตรวจสอบย้อนหลัง"),
                      ],
                    ),
                  ),
                  if (_showAdvanced) ...[
                    const SizedBox(height: 10),
                    ExpansionTile(
                      tilePadding: EdgeInsets.zero,
                      title: const Text("รายละเอียดเชิงเทคนิค (PTN)"),
                      subtitle: const Text(
                        "สำหรับผู้ดูแลระบบและผู้ตรวจสอบ",
                      ),
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
    final startCondition = switch (entry.trigger.mode) {
      'exact_date' when entry.trigger.scheduledAtUtc != null =>
        'เริ่มตามวันเวลาที่ตั้งไว้ ${entry.trigger.scheduledAtUtc!.toLocal()} และรอยืนยันซ้ำอีก ${entry.trigger.graceDays} วัน',
      'exact_date' =>
        'เริ่มตามวันเวลาที่กำหนด (ยังไม่ได้เลือกวันเวลา) และรอยืนยันซ้ำอีก ${entry.trigger.graceDays} วัน',
      'manual_release' =>
        'เริ่มจากโหมดฉุกเฉินแบบปลดล็อกด้วยมือ และรอยืนยันซ้ำอีก ${entry.trigger.graceDays} วัน',
      _ =>
        'เริ่มเมื่อไม่พบการใช้งาน ${entry.trigger.inactivityDays} วัน และรอยืนยันซ้ำอีก ${entry.trigger.graceDays} วัน',
    };
    final statusLabel = entry.status == 'active' ? 'เปิดใช้งาน' : 'พักไว้';
    final kindLabel = entry.kind == 'legacy_delivery'
        ? 'ส่งต่อให้ผู้รับ'
        : 'กู้คืนด้วยตัวเอง';

    final scheme = Theme.of(context).colorScheme;
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.45)),
      ),
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
                const SizedBox(width: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _Pill(label: kindLabel),
                    _Pill(label: statusLabel),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'สรุป: ส่งต่อให้ $receiver',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(startCondition),
            const SizedBox(height: 4),
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              title: const Text('ดูรายละเอียดเพิ่มเติม'),
              subtitle: const Text(
                'ช่องทางส่ง การยืนยันตัวตน และการตั้งค่าความเป็นส่วนตัว',
              ),
              children: [
                const SizedBox(height: 6),
                Text(
                  'ช่องทางหลักของผู้รับ: ${entry.recipient.deliveryChannel}',
                ),
                const SizedBox(height: 4),
                if (entry.recipient.verificationHint.trim().isNotEmpty) ...[
                  Text(
                    'คำใบ้ยืนยันตัวตน: ${entry.recipient.verificationHint}',
                  ),
                  const SizedBox(height: 4),
                ],
                Text(
                  'ช่องทางสำรอง: ${entry.recipient.fallbackChannels.join(', ')}',
                ),
                const SizedBox(height: 4),
                Text(
                  'รูปแบบการส่ง: ${entry.delivery.method}'
                  '${entry.delivery.requireVerificationCode ? ' + รหัสยืนยัน' : ''}'
                  '${entry.delivery.requireTotp ? ' + แอปยืนยันตัวตน' : ''}',
                ),
                const SizedBox(height: 4),
                Text('ระดับความเป็นส่วนตัว: ${entry.privacy.profile}'),
                const SizedBox(height: 4),
                Text(
                  'ก่อนถึงเงื่อนไขให้เห็น: ${entry.privacy.preTriggerVisibility}',
                ),
                const SizedBox(height: 4),
                Text(
                  'หลังถึงเงื่อนไขให้เห็น: ${entry.privacy.postTriggerVisibility}',
                ),
                const SizedBox(height: 4),
                Text('การเปิดเผยมูลค่า: ${entry.privacy.valueDisclosureMode}'),
                const SizedBox(height: 4),
                Text(
                  'ระดับความปลอดภัย: '
                  '${entry.safeguards.requireMultisignal ? 'ต้องยืนยันหลายสัญญาณ' : 'ยืนยันสัญญาณเดียว'}'
                  '${entry.safeguards.requireGuardianApproval ? ', ต้องมีพยานร่วมยืนยัน' : ''}',
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton(onPressed: onEdit, child: const Text('แก้ไข')),
                FilledButton.tonal(
                  onPressed: onToggleStatus,
                  child: Text(
                    entry.status == 'active' ? 'พักรายการ' : 'เปิดใช้งาน',
                  ),
                ),
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
  const _IntentEntryEditorDialog({
    required this.entry,
    required this.verifiedLegalPartners,
  });

  final IntentEntryModel entry;
  final List<String> verifiedLegalPartners;

  @override
  State<_IntentEntryEditorDialog> createState() =>
      _IntentEntryEditorDialogState();
}

class _IntentEntryEditorDialogState extends State<_IntentEntryEditorDialog> {
  int _editorStep = 0;
  late final TextEditingController _displayNameController;
  late final TextEditingController _payloadRefController;
  late final TextEditingController _bankAssetsController;
  late final TextEditingController _emailAssetsController;
  late final TextEditingController _socialAssetsController;
  late final TextEditingController _fileAssetsController;
  late final TextEditingController _personalSecretsNoteController;
  late final TextEditingController _importantDocsNoteController;
  late final TextEditingController _digitalAccountsNoteController;
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
  DateTime? _exactDateUtc;
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
  final Set<String> _selectedPersonalSecrets = <String>{};
  final Set<String> _selectedImportantDocs = <String>{};
  final Set<String> _selectedDigitalAccounts = <String>{};
  final Set<String> _selectedEcosystemConnectors = <String>{};
  bool _connectLegalPartner = false;
  String? _selectedLegalPartner;
  bool _expandPersonalSecrets = true;
  bool _expandImportantDocs = false;
  bool _expandDigitalAccounts = false;

  static const List<String> _personalSecretItems = [
    'รหัสกู้คืน',
    'ชุดคำกู้กระเป๋าเงินคริปโต',
    'ไฟล์ส่งออกจากตัวจัดการรหัสผ่าน',
    'กุญแจส่วนตัว',
    'PIN / รหัสผ่านวลี',
  ];
  static const List<String> _importantDocumentItems = [
    'พินัยกรรม (อ้างอิง)',
    'ประกันชีวิต',
    'สัญญา / โฉนด',
    'รหัสบัญชีธนาคาร',
    'ข้อมูลติดต่อฉุกเฉิน',
  ];
  static const List<String> _digitalAccountItems = [
    'บัญชีอีเมล / โซเชียล',
    'สิทธิ์เข้าถึงคลาวด์',
    'บริการสมาชิกที่ผูกไว้',
    'โดเมน / โฮสติ้ง',
    'บัญชีแพลตฟอร์มคริปโต',
  ];
  static const List<String> _ecosystemTargets = [
    'Bank connector',
    'Exchange connector',
    'Gold broker connector',
  ];

  String _ecosystemTargetLabel(String target) {
    switch (target) {
      case 'Bank connector':
        return 'ธนาคาร';
      case 'Exchange connector':
        return 'แพลตฟอร์มซื้อขาย';
      case 'Gold broker connector':
        return 'ผู้ให้บริการทองคำ';
      default:
        return target;
    }
  }

  String _selectedEcosystemSummary() {
    return _selectedEcosystemConnectors.map(_ecosystemTargetLabel).join(', ');
  }

  @override
  void initState() {
    super.initState();
    _displayNameController = TextEditingController(
      text: widget.entry.asset.displayName,
    );
    _payloadRefController = TextEditingController(
      text: widget.entry.asset.payloadRef,
    );
    _bankAssetsController = TextEditingController();
    _emailAssetsController = TextEditingController();
    _socialAssetsController = TextEditingController();
    _fileAssetsController = TextEditingController();
    _personalSecretsNoteController = TextEditingController();
    _importantDocsNoteController = TextEditingController();
    _digitalAccountsNoteController = TextEditingController();
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
    _exactDateUtc = widget.entry.trigger.scheduledAtUtc;
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
    _safetyLevel =
        (_requireGuardianApproval || _requireMultisignal) ? 'high' : 'standard';
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _payloadRefController.dispose();
    _bankAssetsController.dispose();
    _emailAssetsController.dispose();
    _socialAssetsController.dispose();
    _fileAssetsController.dispose();
    _personalSecretsNoteController.dispose();
    _importantDocsNoteController.dispose();
    _digitalAccountsNoteController.dispose();
    _recipientController.dispose();
    _recipientNameController.dispose();
    _verificationHintController.dispose();
    _triggerDaysController.dispose();
    _graceDaysController.dispose();
    super.dispose();
  }

  List<String> _structuredAssetLines() {
    final lines = <String>[];
    if (_selectedPersonalSecrets.isNotEmpty) {
      lines.add('ความลับส่วนตัว: ${_selectedPersonalSecrets.join(', ')}');
    }
    if (_selectedImportantDocs.isNotEmpty) {
      lines.add('เอกสารสำคัญ: ${_selectedImportantDocs.join(', ')}');
    }
    if (_selectedDigitalAccounts.isNotEmpty) {
      lines.add('บัญชีดิจิทัล: ${_selectedDigitalAccounts.join(', ')}');
    }
    if (_bankAssetsController.text.trim().isNotEmpty) {
      lines.add('บัญชีการเงิน: ${_bankAssetsController.text.trim()}');
    }
    if (_emailAssetsController.text.trim().isNotEmpty) {
      lines.add('บัญชีอีเมล: ${_emailAssetsController.text.trim()}');
    }
    if (_socialAssetsController.text.trim().isNotEmpty) {
      lines.add('บัญชีโซเชียล: ${_socialAssetsController.text.trim()}');
    }
    if (_fileAssetsController.text.trim().isNotEmpty) {
      lines.add('ไฟล์สำคัญ: ${_fileAssetsController.text.trim()}');
    }
    if (_personalSecretsNoteController.text.trim().isNotEmpty) {
      lines.add(
          'หมายเหตุความลับส่วนตัว: ${_personalSecretsNoteController.text.trim()}');
    }
    if (_importantDocsNoteController.text.trim().isNotEmpty) {
      lines.add(
          'หมายเหตุเอกสารสำคัญ: ${_importantDocsNoteController.text.trim()}');
    }
    if (_digitalAccountsNoteController.text.trim().isNotEmpty) {
      lines.add(
          'หมายเหตุบัญชีดิจิทัล: ${_digitalAccountsNoteController.text.trim()}');
    }
    if (_selectedEcosystemConnectors.isNotEmpty) {
      lines.add('ประสานปลายทางสถาบัน: ${_selectedEcosystemSummary()}');
    }
    if (_connectLegalPartner && _selectedLegalPartner != null) {
      lines.add('ประสานงานสำนักงานกฎหมาย: $_selectedLegalPartner');
    }
    return lines;
  }

  void _applyStructuredAssetsTemplate() {
    final lines = _structuredAssetLines();
    if (lines.isEmpty) {
      return;
    }
    if (_payloadRefController.text.trim().isEmpty) {
      _payloadRefController.text = lines.join('\n');
    }
    if (_displayNameController.text.trim().isEmpty) {
      _displayNameController.text =
          'ชุดสินทรัพย์ดิจิทัล (${lines.length} หมวด)';
    }
  }

  String _redactMoneyLikeText(String input) {
    if (input.trim().isEmpty) {
      return input;
    }
    var output = input;
    output = output.replaceAllMapped(
      RegExp(
        r'\\b(thb|baht|usd|eur|บาท)\\s*[\\d,]+(?:\\.\\d{1,2})?\\b',
        caseSensitive: false,
      ),
      (_) => '[institution-verified amount]',
    );
    output = output.replaceAllMapped(
      RegExp(r'(?<!\w)[\d]{1,3}(?:,[\d]{3})+(?:\.\d{1,2})?(?!\w)'),
      (_) => '[institution-verified amount]',
    );
    output = output.replaceAllMapped(
      RegExp(
        r'(?<!\\w)[\\d]{5,}(?:\\.\\d{1,2})?\\s*(thb|baht|บาท)?(?!\\w)',
        caseSensitive: false,
      ),
      (_) => '[institution-verified amount]',
    );
    return output;
  }

  bool _containsMoneyLikeText(String input) {
    if (input.trim().isEmpty) {
      return false;
    }
    final hasCurrency = RegExp(
      r'\\b(thb|baht|usd|eur|บาท)\\s*[\\d,]+(?:\\.\\d{1,2})?\\b',
      caseSensitive: false,
    ).hasMatch(input);
    final hasLargeNumber = RegExp(
      r'(?<!\w)([\d]{1,3}(?:,[\d]{3})+|[\d]{5,})(?:\.\d{1,2})?(?!\w)',
    ).hasMatch(input);
    return hasCurrency || hasLargeNumber;
  }

  String _exactDateLabel() {
    final value = _exactDateUtc;
    if (value == null) {
      return 'ยังไม่ได้เลือกวันเวลา';
    }
    final local = value.toLocal();
    final hh = local.hour.toString().padLeft(2, '0');
    final mm = local.minute.toString().padLeft(2, '0');
    return '${local.year}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')} $hh:$mm';
  }

  Future<void> _pickExactDateTime() async {
    final now = DateTime.now();
    final current = (_exactDateUtc ?? now.toUtc()).toLocal();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: current.isBefore(now) ? now : current,
      firstDate: now,
      lastDate: DateTime(now.year + 10),
    );
    if (pickedDate == null || !mounted) {
      return;
    }
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(current),
    );
    if (pickedTime == null) {
      return;
    }
    final local = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );
    setState(() {
      _exactDateUtc = local.toUtc();
      _triggerMode = 'exact_date';
    });
  }

  Widget _buildChecklistSection({
    required String title,
    required bool expanded,
    required ValueChanged<bool> onExpanded,
    required List<String> items,
    required Set<String> selected,
    required TextEditingController noteController,
    required String noteLabel,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8F4ED),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE8DDCF)),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        initiallyExpanded: expanded,
        onExpansionChanged: onExpanded,
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          "เลือกแล้ว ${selected.length} รายการ",
        ),
        childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: items
                .map(
                  (item) => FilterChip(
                    selected: selected.contains(item),
                    label: Text(item),
                    onSelected: (value) {
                      setState(() {
                        if (value) {
                          selected.add(item);
                        } else {
                          selected.remove(item);
                        }
                      });
                    },
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: noteController,
            maxLines: 2,
            decoration: InputDecoration(
              labelText: noteLabel,
            ),
          ),
        ],
      ),
    );
  }

  String? _stepValidationMessage() {
    final recipientRef = _recipientController.text.trim();
    final recipientName = _recipientNameController.text.trim();
    final graceDays = int.tryParse(_graceDaysController.text.trim()) ?? 0;
    final inactivityDays =
        int.tryParse(_triggerDaysController.text.trim()) ?? 0;

    if (_editorStep == 0) {
      if (_kind != 'self_recovery' && recipientName.isEmpty) {
        return 'กรุณาระบุชื่อผู้รับก่อนกดถัดไป';
      }
      if (recipientRef.isEmpty) {
        return 'กรุณาระบุช่องทางติดต่อผู้รับก่อนกดถัดไป';
      }
      if (_payloadRefController.text.trim().isEmpty &&
          _structuredAssetLines().isEmpty) {
        return 'กรุณาระบุรายการสินทรัพย์หรือข้อมูลอ้างอิงอย่างน้อย 1 รายการ';
      }
      return null;
    }

    if (_editorStep == 1) {
      if (_triggerMode == 'exact_date' && _exactDateUtc == null) {
        return 'คุณเลือกวันกำหนดแล้ว กรุณาเลือกวันและเวลาก่อนกดถัดไป';
      }
      if (_triggerMode == 'inactivity' && inactivityDays < 30) {
        return 'ช่วงไม่พบการใช้งานควรไม่น้อยกว่า 30 วัน';
      }
      if (graceDays < 1 || graceDays > 30) {
        return 'ช่วงยืนยันซ้ำควรอยู่ระหว่าง 1-30 วัน';
      }
      return null;
    }

    if (_editorStep == 2) {
      if (_triggerMode == 'exact_date' && _exactDateUtc == null) {
        return 'ยังไม่สามารถบันทึกได้ เพราะยังไม่ได้ตั้งวันเวลาสำหรับวันกำหนด';
      }
      if (graceDays < 1 || graceDays > 30) {
        return 'ยังไม่สามารถบันทึกได้ กรุณาตรวจช่วงยืนยันซ้ำ (1-30 วัน)';
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final inactivityDays = int.tryParse(_triggerDaysController.text.trim()) ??
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
                'ขั้นที่ ${_editorStep + 1} จาก 3',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 8),
            if (_editorStep == 0) ...[
              const Text(
                'ขั้นที่ 1: ใครคือผู้รับ?',
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
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF4EFE8),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'รายการสินทรัพย์ดิจิทัล (กรอกแบบตรงๆ)',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'ช่วยให้ผู้รับเข้าใจง่ายว่าแผนนี้ครอบคลุมอะไรบ้าง',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              _buildChecklistSection(
                title: 'ความลับส่วนตัว',
                expanded: _expandPersonalSecrets,
                onExpanded: (value) =>
                    setState(() => _expandPersonalSecrets = value),
                items: _personalSecretItems,
                selected: _selectedPersonalSecrets,
                noteController: _personalSecretsNoteController,
                noteLabel: 'หมายเหตุความลับส่วนตัว (เพิ่มเติม)',
              ),
              const SizedBox(height: 10),
              _buildChecklistSection(
                title: 'เอกสารสำคัญ',
                expanded: _expandImportantDocs,
                onExpanded: (value) =>
                    setState(() => _expandImportantDocs = value),
                items: _importantDocumentItems,
                selected: _selectedImportantDocs,
                noteController: _importantDocsNoteController,
                noteLabel: 'หมายเหตุเอกสารสำคัญ (เพิ่มเติม)',
              ),
              const SizedBox(height: 10),
              _buildChecklistSection(
                title: 'บัญชีดิจิทัล',
                expanded: _expandDigitalAccounts,
                onExpanded: (value) =>
                    setState(() => _expandDigitalAccounts = value),
                items: _digitalAccountItems,
                selected: _selectedDigitalAccounts,
                noteController: _digitalAccountsNoteController,
                noteLabel: 'หมายเหตุบัญชีดิจิทัล (เพิ่มเติม)',
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _bankAssetsController,
                decoration: const InputDecoration(
                  labelText: 'บัญชีการเงิน (ธนาคาร / คริปโต / ทองคำ)',
                  hintText: 'เช่น KBank, Bitkub, ร้านทอง A',
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _emailAssetsController,
                decoration: const InputDecoration(
                  labelText: 'บัญชีอีเมล',
                  hintText: 'เช่น Gmail, Outlook',
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _socialAssetsController,
                decoration: const InputDecoration(
                  labelText: 'บัญชีโซเชียล',
                  hintText: 'เช่น LINE, Facebook, X',
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _fileAssetsController,
                decoration: const InputDecoration(
                  labelText: 'ไฟล์สำคัญ',
                  hintText: 'เช่น รูปครอบครัว, เอกสารประกัน',
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF6F6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'ประสานปลายทางเพิ่มเติม',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'เลือกให้ระบบส่งเอกสารไปยังสถาบันที่เกี่ยวข้องและสำนักงานกฎหมายได้เมื่อถึงเวลา',
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _ecosystemTargets
                          .map(
                            (target) => FilterChip(
                              selected:
                                  _selectedEcosystemConnectors.contains(target),
                              label: Text(_ecosystemTargetLabel(target)),
                              onSelected: (value) {
                                setState(() {
                                  if (value) {
                                    _selectedEcosystemConnectors.add(target);
                                  } else {
                                    _selectedEcosystemConnectors.remove(target);
                                  }
                                });
                              },
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: 8),
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      value: _connectLegalPartner,
                      onChanged: widget.verifiedLegalPartners.isEmpty
                          ? null
                          : (value) {
                              setState(() {
                                _connectLegalPartner = value;
                                if (!value) {
                                  _selectedLegalPartner = null;
                                }
                              });
                            },
                      title:
                          const Text('เชื่อมต่อสำนักงานกฎหมายให้ช่วยประสานงาน'),
                    ),
                    if (widget.verifiedLegalPartners.isEmpty)
                      const Padding(
                        padding: EdgeInsets.only(bottom: 8),
                        child: Text(
                          'ตอนนี้ยังไม่มีสำนักงานกฎหมายที่พร้อมใช้งาน จึงยังเปิดการประสานงานส่วนนี้ไม่ได้',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    if (_connectLegalPartner)
                      if (widget.verifiedLegalPartners.isEmpty)
                        const Padding(
                          padding: EdgeInsets.only(bottom: 8),
                          child: Text(
                            'ยังไม่มีสำนักงานกฎหมายที่ผ่านการยืนยันจากระบบกลาง',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        )
                      else
                        DropdownButtonFormField<String>(
                          initialValue: _selectedLegalPartner,
                          decoration: const InputDecoration(
                            labelText: 'เลือกสำนักงานกฎหมายพาร์ทเนอร์',
                          ),
                          items: widget.verifiedLegalPartners
                              .map(
                                (partner) => DropdownMenuItem(
                                  value: partner,
                                  child: Text(partner),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            setState(() => _selectedLegalPartner = value);
                          },
                        ),
                    const SizedBox(height: 6),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: const Color(0xFFF7F1E8),
                      ),
                      child: Text(
                        "สรุปที่จะส่ง: ผู้รับหลัก 1 คน"
                        "${_selectedEcosystemConnectors.isNotEmpty ? " + ปลายทางสถาบัน ${_selectedEcosystemConnectors.length} แห่ง" : ""}"
                        "${_connectLegalPartner && _selectedLegalPartner != null ? " + สำนักงานกฎหมาย 1 แห่ง" : ""}",
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton.icon(
                  onPressed: () {
                    setState(() {
                      _applyStructuredAssetsTemplate();
                    });
                  },
                  icon: const Icon(Icons.auto_fix_high_rounded),
                  label: const Text('เติมชื่อแผน/ข้อมูลอ้างอิงอัตโนมัติ'),
                ),
              ),
            ] else if (_editorStep == 1) ...[
              const Text(
                'ขั้นที่ 2: ส่งมอบเมื่อไหร่?',
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
              if (_triggerMode == 'inactivity')
                Slider(
                  value: inactivityDays.clamp(30, 365).toDouble(),
                  min: 30,
                  max: 365,
                  divisions: 11,
                  label: '$inactivityDays วัน',
                  onChanged: (value) {
                    setState(() {
                      _triggerDaysController.text = value.round().toString();
                    });
                  },
                ),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: _triggerMode == 'exact_date',
                onChanged: (value) {
                  if (value == true) {
                    setState(() => _triggerMode = 'exact_date');
                  }
                },
                title: const Text('กำหนดวันและเวลาแบบตายตัว (วันกำหนด)'),
              ),
              if (_triggerMode == 'exact_date') ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'วันเวลาที่ตั้งไว้: ${_exactDateLabel()}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: _pickExactDateTime,
                      icon: const Icon(Icons.calendar_month_outlined),
                      label: const Text('เลือกวันเวลา'),
                    ),
                  ],
                ),
              ],
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: emergencyEnabled,
                onChanged: (value) {
                  setState(() {
                    _triggerMode =
                        value == true ? 'manual_release' : 'inactivity';
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
                'ขั้นที่ 3: ระดับความปลอดภัย',
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
                            ? 'เข้มงวด: ต้องมีพยานร่วมยืนยัน'
                            : 'มาตรฐาน: ยืนยันผ่าน Email + SMS',
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
                    label: Text('มาตรฐาน'),
                  ),
                  ButtonSegment(
                    value: 'high',
                    label: Text('เข้มงวด'),
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
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    labelText: 'ข้อมูลที่ส่งมอบ (อ้างอิง)',
                    helperText:
                        'ไม่ต้องใส่ยอดเงินจริง ระบบยืนยันยอดกับปลายทางเท่านั้น',
                  ),
                ),
                if (_containsMoneyLikeText(_payloadRefController.text)) ...[
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: const Color(0xFFFFF4E8),
                      border: Border.all(color: const Color(0xFFF0C48A)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'พบข้อมูลที่คล้ายยอดเงิน',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'เพื่อความปลอดภัย ระบบนี้ไม่เก็บยอดจริง แนะนำให้แทนคำเป็น "ตรวจที่ปลายทาง"',
                        ),
                        const SizedBox(height: 8),
                        OutlinedButton.icon(
                          onPressed: () {
                            setState(() {
                              _payloadRefController.text = _redactMoneyLikeText(
                                      _payloadRefController.text)
                                  .replaceAll(
                                '[institution-verified amount]',
                                'ตรวจที่ปลายทาง',
                              );
                            });
                          },
                          icon: const Icon(Icons.shield_outlined),
                          label: const Text(
                            'แทนคำอัตโนมัติเป็น "ตรวจที่ปลายทาง"',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                TextField(
                  controller: _verificationHintController,
                  decoration:
                      const InputDecoration(labelText: 'คำใบ้ยืนยันตัวตน'),
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
            final validation = _stepValidationMessage();
            if (validation != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(validation)),
              );
              return;
            }
            if (_editorStep < 2) {
              setState(() => _editorStep += 1);
              return;
            }
            _applyStructuredAssetsTemplate();
            final sanitizedPayloadRef =
                _redactMoneyLikeText(_payloadRefController.text.trim());
            final sanitizedAssetNotes = widget.entry.asset.notes == null
                ? null
                : _redactMoneyLikeText(widget.entry.asset.notes!);
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
                  payloadRef: sanitizedPayloadRef,
                  notes: sanitizedAssetNotes,
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
                      ? 'เจ้าของบัญชี'
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
                  scheduledAtUtc:
                      _triggerMode == 'exact_date' ? _exactDateUtc : null,
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
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: scheme.surfaceContainerHighest,
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.6)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: scheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}
