import 'package:digital_legacy_weaver/features/intent_builder/intent_builder_model.dart';
import 'package:digital_legacy_weaver/features/profile/profile_model.dart';
import 'package:digital_legacy_weaver/features/settings/safety_settings_model.dart';

class DemoScenario {
  const DemoScenario({
    required this.id,
    required this.title,
    required this.summary,
    required this.badge,
    required this.primaryActionLabel,
  });

  final String id;
  final String title;
  final String summary;
  final String badge;
  final String primaryActionLabel;

  String get ownerRef => 'demo_owner_$id';

  ProfileModel buildProfile(ProfileModel baseProfile) {
    return ProfileModel(
      id: ownerRef,
      backupEmail: baseProfile.backupEmail,
      beneficiaryEmail: baseProfile.beneficiaryEmail,
      beneficiaryName: baseProfile.beneficiaryName,
      beneficiaryPhone: baseProfile.beneficiaryPhone,
      beneficiaryVerificationHint: baseProfile.beneficiaryVerificationHint,
      beneficiaryVerificationPhraseHash: baseProfile.beneficiaryVerificationPhraseHash,
      legacyInactivityDays: baseProfile.legacyInactivityDays,
      selfRecoveryInactivityDays: baseProfile.selfRecoveryInactivityDays,
      lastActiveAt: baseProfile.lastActiveAt,
    );
  }

  IntentDocumentModel buildDocument({
    required ProfileModel profile,
    required SafetySettingsModel settings,
    String? ownerRefOverride,
  }) {
    switch (id) {
      case 'self_recovery':
        return _buildSelfRecovery(
          profile: profile,
          settings: settings,
          ownerRefOverride: ownerRefOverride,
        );
      case 'family_handoff':
        return _buildFamilyHandoff(
          profile: profile,
          settings: settings,
          ownerRefOverride: ownerRefOverride,
        );
      case 'private_archive':
        return _buildPrivateArchive(
          profile: profile,
          settings: settings,
          ownerRefOverride: ownerRefOverride,
        );
      default:
        return _buildFamilyHandoff(
          profile: profile,
          settings: settings,
          ownerRefOverride: ownerRefOverride,
        );
    }
  }

  IntentDocumentModel _buildSelfRecovery({
    required ProfileModel profile,
    required SafetySettingsModel settings,
    String? ownerRefOverride,
  }) {
    return IntentDocumentModel.initial(
      ownerRef: ownerRefOverride ?? profile.id,
      intentId: 'demo_self_recovery',
      defaultPrivacyProfile: 'minimal',
    ).copyWith(
      entries: [
        IntentEntryModel.selfRecoveryDraft(
          entryId: 'self_recovery_primary',
          ownerRef: 'owner_primary',
          destinationRef: profile.backupEmail,
        ).copyWith(
          status: 'active',
          asset: const IntentAssetModel(
            assetId: 'asset_self_recovery_primary',
            assetType: 'backup_email_route',
            displayName: 'Owner recovery route',
            payloadMode: 'self_recovery_route',
            payloadRef: 'owner@example.com',
            notes: 'Local-first recovery route for the owner',
          ),
          trigger: IntentTriggerModel(
            mode: 'inactivity',
            inactivityDays: profile.selfRecoveryInactivityDays,
            requireUnconfirmedAliveStatus: false,
            graceDays: settings.gracePeriodDays,
            remindersDaysBefore: settings.reminderOffsetsDays,
          ),
          delivery: IntentDeliveryModel(
            method: 'self_recovery_route',
            requireVerificationCode: true,
            requireTotp: settings.requireTotpUnlock,
            oneTimeAccess: true,
          ),
          privacy: const IntentPrivacyModel(
            profile: 'minimal',
            minimizeTraceMetadata: true,
            preTriggerVisibility: 'none',
            postTriggerVisibility: 'route_only',
            valueDisclosureMode: 'institution_verified_only',
          ),
        ),
      ],
      globalSafeguards: IntentGlobalSafeguardsModel(
        emergencyPauseEnabled: true,
        defaultGraceDays: settings.gracePeriodDays,
        defaultRemindersDaysBefore: settings.reminderOffsetsDays,
        requireMultisignalBeforeRelease: false,
        requireGuardianApprovalForLegacy: false,
        proofOfLifeCheckMode: settings.proofOfLifeCheckMode,
        proofOfLifeFallbackChannels: settings.proofOfLifeFallbackChannels,
        serverHeartbeatFallbackEnabled: settings.serverHeartbeatFallbackEnabled,
        iosBackgroundRiskAcknowledged: settings.iosBackgroundRiskAcknowledged,
      ),
      metadata: const {
        'source': 'demo_scenario',
        'demo_scenario': 'self_recovery',
        'demo_title': 'กู้คืนบัญชีของฉัน',
        'demo_summary': 'เดโมกู้คืนบัญชีที่ช่วยให้เจ้าของกลับมาเข้าถึงระบบได้ก่อนส่งต่อให้ผู้รับ',
        'demo_next_step': 'ตรวจเส้นทางกู้คืนให้ครบ แล้วสร้างเวอร์ชันเอกสารเพื่อยืนยันว่ากู้คืนได้จริง',
      },
    );
  }

  IntentDocumentModel _buildFamilyHandoff({
    required ProfileModel profile,
    required SafetySettingsModel settings,
    String? ownerRefOverride,
  }) {
    return IntentDocumentModel.initial(
      ownerRef: ownerRefOverride ?? profile.id,
      intentId: 'demo_family_handoff',
      defaultPrivacyProfile: 'minimal',
    ).copyWith(
      entries: [
        IntentEntryModel.legacyDeliveryDraft(
          entryId: 'family_handoff_primary',
          recipientRef: 'beneficiary_primary',
          destinationRef: profile.beneficiaryEmail ?? 'beneficiary@example.com',
        ).copyWith(
          status: 'active',
          recipient: IntentRecipientModel(
            recipientId: 'beneficiary_primary',
            relationship: 'beneficiary',
            deliveryChannel: 'email',
            destinationRef: profile.beneficiaryEmail ?? 'beneficiary@example.com',
            role: 'beneficiary',
            registeredLegalName: profile.beneficiaryName ?? 'Demo Beneficiary',
            verificationHint: profile.beneficiaryVerificationHint ?? 'Shared family phrase',
            fallbackChannels: settings.proofOfLifeFallbackChannels,
          ),
          asset: const IntentAssetModel(
            assetId: 'asset_family_handoff_primary',
            assetType: 'vault_item',
            displayName: 'Family continuity bundle',
            payloadMode: 'secure_link',
            payloadRef: 'legacy_bundle_primary',
            notes: 'Primary handoff route for family continuity',
          ),
          trigger: IntentTriggerModel(
            mode: 'inactivity',
            inactivityDays: profile.legacyInactivityDays,
            requireUnconfirmedAliveStatus: true,
            graceDays: settings.gracePeriodDays,
            remindersDaysBefore: settings.reminderOffsetsDays,
          ),
          delivery: IntentDeliveryModel(
            method: 'secure_link',
            requireVerificationCode: true,
            requireTotp: settings.requireTotpUnlock,
            oneTimeAccess: true,
          ),
          safeguards: const IntentSafeguardsModel(
            requireGuardianApproval: false,
            requireMultisignal: true,
            cooldownHours: 24,
            legalDisclaimerRequired: true,
          ),
          privacy: IntentPrivacyModel(
            profile: settings.tracePrivacyProfile,
            minimizeTraceMetadata: settings.privateFirstMode,
            preTriggerVisibility: 'none',
            postTriggerVisibility: 'route_only',
            valueDisclosureMode: 'institution_verified_only',
          ),
        ),
      ],
      globalSafeguards: IntentGlobalSafeguardsModel(
        emergencyPauseEnabled: true,
        defaultGraceDays: settings.gracePeriodDays,
        defaultRemindersDaysBefore: settings.reminderOffsetsDays,
        requireMultisignalBeforeRelease: true,
        requireGuardianApprovalForLegacy: false,
        proofOfLifeCheckMode: settings.proofOfLifeCheckMode,
        proofOfLifeFallbackChannels: settings.proofOfLifeFallbackChannels,
        serverHeartbeatFallbackEnabled: settings.serverHeartbeatFallbackEnabled,
        iosBackgroundRiskAcknowledged: settings.iosBackgroundRiskAcknowledged,
      ),
      metadata: const {
        'source': 'demo_scenario',
        'demo_scenario': 'family_handoff',
        'demo_title': 'เส้นทางมอบมรดกดิจิทัลให้คนที่คุณรัก',
        'demo_summary': 'เดโมส่งต่อแบบปลอดภัยให้ผู้รับที่กำหนดไว้ เมื่อครบเงื่อนไขขาดการติดต่อ',
        'demo_next_step': 'ตรวจเส้นทางผู้รับให้ครบ แล้วสร้างและเทียบเวอร์ชันเอกสารเพื่อเห็นภาพการส่งต่อจริง',
      },
    );
  }

  IntentDocumentModel _buildPrivateArchive({
    required ProfileModel profile,
    required SafetySettingsModel settings,
    String? ownerRefOverride,
  }) {
    return IntentDocumentModel.initial(
      ownerRef: ownerRefOverride ?? profile.id,
      intentId: 'demo_private_archive',
      defaultPrivacyProfile: 'confidential',
    ).copyWith(
      entries: [
        IntentEntryModel.legacyDeliveryDraft(
          entryId: 'private_archive_primary',
          recipientRef: 'beneficiary_archive',
          destinationRef: profile.beneficiaryEmail ?? 'beneficiary@example.com',
        ).copyWith(
          status: 'active',
          recipient: IntentRecipientModel(
            recipientId: 'beneficiary_archive',
            relationship: 'beneficiary',
            deliveryChannel: 'email',
            destinationRef: profile.beneficiaryEmail ?? 'beneficiary@example.com',
            role: 'beneficiary',
            registeredLegalName: profile.beneficiaryName ?? 'Demo Beneficiary',
            verificationHint: profile.beneficiaryVerificationHint ?? 'Archive phrase',
            fallbackChannels: settings.proofOfLifeFallbackChannels,
          ),
          asset: const IntentAssetModel(
            assetId: 'asset_private_archive',
            assetType: 'document_notice',
            displayName: 'Private archive notice',
            payloadMode: 'handoff_notice',
            payloadRef: 'private_archive_notice',
            notes: 'Confidential handoff notice with private-first posture',
          ),
          trigger: IntentTriggerModel(
            mode: 'inactivity',
            inactivityDays: 120,
            requireUnconfirmedAliveStatus: true,
            graceDays: settings.gracePeriodDays,
            remindersDaysBefore: const [21, 7, 1],
          ),
          delivery: const IntentDeliveryModel(
            method: 'handoff_notice',
            requireVerificationCode: true,
            requireTotp: false,
            oneTimeAccess: true,
          ),
          safeguards: const IntentSafeguardsModel(
            requireGuardianApproval: false,
            requireMultisignal: true,
            cooldownHours: 24,
            legalDisclaimerRequired: true,
          ),
          privacy: const IntentPrivacyModel(
            profile: 'confidential',
            minimizeTraceMetadata: true,
            preTriggerVisibility: 'none',
            postTriggerVisibility: 'route_only',
            valueDisclosureMode: 'institution_verified_only',
          ),
          partnerPath: const IntentPartnerPathModel(
            pathId: 'private_archive_handoff',
            pathType: 'handoff_route',
            handoffTemplate: 'private_archive_notice',
            requiredContext: ['beneficiary_notice', 'private_archive_reference'],
          ),
        ),
      ],
      globalSafeguards: IntentGlobalSafeguardsModel(
        emergencyPauseEnabled: true,
        defaultGraceDays: settings.gracePeriodDays,
        defaultRemindersDaysBefore: const [21, 7, 1],
        requireMultisignalBeforeRelease: true,
        requireGuardianApprovalForLegacy: false,
        proofOfLifeCheckMode: settings.proofOfLifeCheckMode,
        proofOfLifeFallbackChannels: settings.proofOfLifeFallbackChannels,
        serverHeartbeatFallbackEnabled: settings.serverHeartbeatFallbackEnabled,
        iosBackgroundRiskAcknowledged: settings.iosBackgroundRiskAcknowledged,
      ),
      metadata: const {
        'source': 'demo_scenario',
        'demo_scenario': 'private_archive',
        'demo_title': 'คลังส่วนตัวเข้มงวด',
        'demo_summary': 'เดโมที่เน้นความลับสูงสุด จำกัดการมองเห็นข้อมูลจนกว่าจะถึงเงื่อนไขจริง',
        'demo_next_step': 'ตรวจระดับความเป็นส่วนตัว สร้างเวอร์ชันเอกสาร แล้วดูผลต่อความพร้อมใช้งาน',
      },
    );
  }
}

DemoScenario? demoScenarioById(String? id) {
  if (id == null) {
    return null;
  }
  for (final scenario in demoScenarios) {
    if (scenario.id == id) {
      return scenario;
    }
  }
  return null;
}

const demoScenarios = <DemoScenario>[
  DemoScenario(
    id: 'family_handoff',
    title: 'เส้นทางมอบมรดกดิจิทัลให้คนที่คุณรัก',
    summary: 'เริ่มจากเดโมแนะนำที่เห็นภาพครบตั้งแต่ตั้งค่า จนถึงเส้นทางส่งมอบ',
    badge: 'แนะนำเริ่มจากอันนี้',
    primaryActionLabel: 'เริ่มเดโมนี้ก่อน',
  ),
  DemoScenario(
    id: 'self_recovery',
    title: 'กู้คืนบัญชีของฉัน',
    summary: 'เริ่มจากกู้คืนสิทธิ์เจ้าของก่อน ลดความเสี่ยงส่งผิดคน',
    badge: 'เส้นทางกู้คืน',
    primaryActionLabel: 'เริ่มเดโมกู้คืน',
  ),
  DemoScenario(
    id: 'private_archive',
    title: 'คลังส่วนตัวเข้มงวด',
    summary: 'เหมาะกับข้อมูลอ่อนไหวสูง เน้นความเป็นส่วนตัวและการเปิดเผยตามเงื่อนไขเท่านั้น',
    badge: 'ความเป็นส่วนตัวสูง',
    primaryActionLabel: 'เริ่มเดโมคลังส่วนตัว',
  ),
];
