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
        'demo_title': 'Owner self-recovery',
        'demo_summary': 'A recovery route that helps the owner regain access before escalating to legacy delivery.',
        'demo_next_step': 'Review the recovery route, then export a canonical artifact to validate the self-recovery handoff path.',
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
        'demo_title': 'Family beneficiary handoff',
        'demo_summary': 'A secure-link handoff route for an intended beneficiary after long inactivity.',
        'demo_next_step': 'Review the beneficiary route, then export and compare the artifact so the handoff flow becomes concrete.',
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
        'demo_title': 'Private-first archive',
        'demo_summary': 'A confidentiality-focused handoff path that keeps PTN and trace posture as tight as possible.',
        'demo_next_step': 'Inspect the privacy posture, export the artifact, and confirm how a confidentiality-heavy route changes readiness.',
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
    title: 'Family beneficiary handoff',
    summary: 'Start from a secure-link legacy handoff that shows the full artifact and readiness journey.',
    badge: 'Best first demo',
    primaryActionLabel: 'Start family handoff demo',
  ),
  DemoScenario(
    id: 'self_recovery',
    title: 'Owner self-recovery',
    summary: 'Open a lighter recovery route focused on helping the owner regain access first.',
    badge: 'Recovery path',
    primaryActionLabel: 'Start self-recovery demo',
  ),
  DemoScenario(
    id: 'private_archive',
    title: 'Private-first archive',
    summary: 'Explore a confidentiality-heavy notice flow with stronger privacy posture and handoff routing.',
    badge: 'Highest privacy',
    primaryActionLabel: 'Start private archive demo',
  ),
];
