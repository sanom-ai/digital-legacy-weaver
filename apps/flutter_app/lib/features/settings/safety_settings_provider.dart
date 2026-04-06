import 'package:digital_legacy_weaver/core/providers/supabase_provider.dart';
import 'package:digital_legacy_weaver/features/settings/safety_settings_model.dart';
import 'package:digital_legacy_weaver/features/settings/safety_settings_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final safetySettingsRepositoryProvider = Provider<SafetySettingsRepository>((ref) {
  return SafetySettingsRepository(ref.watch(supabaseClientProvider));
});

final safetySettingsProvider = AsyncNotifierProvider<SafetySettingsController, SafetySettingsModel>(
  SafetySettingsController.new,
);

class SafetySettingsController extends AsyncNotifier<SafetySettingsModel> {
  @override
  Future<SafetySettingsModel> build() async {
    return ref.read(safetySettingsRepositoryProvider).getOrCreate();
  }

  Future<void> save({
    required bool remindersEnabled,
    required List<int> reminderOffsetsDays,
    required int gracePeriodDays,
    required String proofOfLifeCheckMode,
    required List<String> proofOfLifeFallbackChannels,
    required bool serverHeartbeatFallbackEnabled,
    required bool iosBackgroundRiskAcknowledged,
    required bool legalDisclaimerAccepted,
    required DateTime? emergencyPauseUntil,
    required bool requireTotpUnlock,
    required bool guardianQuorumEnabled,
    required int guardianQuorumRequired,
    required int guardianQuorumPoolSize,
    required bool emergencyAccessEnabled,
    required bool emergencyAccessRequiresBeneficiaryRequest,
    required bool emergencyAccessRequiresGuardianQuorum,
    required int emergencyAccessGraceHours,
    required bool deviceRebindInProgress,
    required DateTime? deviceRebindStartedAt,
    required int deviceRebindGraceHours,
    required bool recoveryKeyEnabled,
    required int deliveryAccessTtlHours,
    required int payloadRetentionDays,
    required int auditLogRetentionDays,
    required bool privateFirstMode,
    required String tracePrivacyProfile,
  }) async {
    final repo = ref.read(safetySettingsRepositoryProvider);
    await repo.update(
      remindersEnabled: remindersEnabled,
      reminderOffsetsDays: reminderOffsetsDays,
      gracePeriodDays: gracePeriodDays,
      proofOfLifeCheckMode: proofOfLifeCheckMode,
      proofOfLifeFallbackChannels: proofOfLifeFallbackChannels,
      serverHeartbeatFallbackEnabled: serverHeartbeatFallbackEnabled,
      iosBackgroundRiskAcknowledged: iosBackgroundRiskAcknowledged,
      legalDisclaimerAccepted: legalDisclaimerAccepted,
      emergencyPauseUntil: emergencyPauseUntil,
      requireTotpUnlock: requireTotpUnlock,
      guardianQuorumEnabled: guardianQuorumEnabled,
      guardianQuorumRequired: guardianQuorumRequired,
      guardianQuorumPoolSize: guardianQuorumPoolSize,
      emergencyAccessEnabled: emergencyAccessEnabled,
      emergencyAccessRequiresBeneficiaryRequest: emergencyAccessRequiresBeneficiaryRequest,
      emergencyAccessRequiresGuardianQuorum: emergencyAccessRequiresGuardianQuorum,
      emergencyAccessGraceHours: emergencyAccessGraceHours,
      deviceRebindInProgress: deviceRebindInProgress,
      deviceRebindStartedAt: deviceRebindStartedAt,
      deviceRebindGraceHours: deviceRebindGraceHours,
      recoveryKeyEnabled: recoveryKeyEnabled,
      deliveryAccessTtlHours: deliveryAccessTtlHours,
      payloadRetentionDays: payloadRetentionDays,
      auditLogRetentionDays: auditLogRetentionDays,
      privateFirstMode: privateFirstMode,
      tracePrivacyProfile: tracePrivacyProfile,
    );
    state = AsyncData(await repo.getOrCreate());
  }
}
