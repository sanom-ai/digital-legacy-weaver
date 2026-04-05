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
    required bool legalDisclaimerAccepted,
    required DateTime? emergencyPauseUntil,
    required bool requireTotpUnlock,
    required bool privateFirstMode,
    required String tracePrivacyProfile,
  }) async {
    final repo = ref.read(safetySettingsRepositoryProvider);
    await repo.update(
      remindersEnabled: remindersEnabled,
      reminderOffsetsDays: reminderOffsetsDays,
      gracePeriodDays: gracePeriodDays,
      legalDisclaimerAccepted: legalDisclaimerAccepted,
      emergencyPauseUntil: emergencyPauseUntil,
      requireTotpUnlock: requireTotpUnlock,
      privateFirstMode: privateFirstMode,
      tracePrivacyProfile: tracePrivacyProfile,
    );
    state = AsyncData(await repo.getOrCreate());
  }
}
