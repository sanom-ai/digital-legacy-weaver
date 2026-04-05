import 'package:digital_legacy_weaver/features/onboarding/onboarding_setup_screen.dart';
import 'package:digital_legacy_weaver/features/dashboard/dashboard_screen.dart';
import 'package:digital_legacy_weaver/features/profile/profile_model.dart';
import 'package:digital_legacy_weaver/features/profile/profile_provider.dart';
import 'package:digital_legacy_weaver/features/settings/privacy_profile_preset.dart';
import 'package:digital_legacy_weaver/features/settings/safety_settings_model.dart';
import 'package:digital_legacy_weaver/features/settings/safety_settings_provider.dart';
import 'package:digital_legacy_weaver/features/settings/safety_settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeSafetySettingsController extends SafetySettingsController {
  static const seeded = SafetySettingsModel(
    remindersEnabled: true,
    reminderOffsetsDays: [14, 7, 1],
    gracePeriodDays: 7,
    proofOfLifeCheckMode: 'biometric_tap',
    proofOfLifeFallbackChannels: ['email', 'sms'],
    serverHeartbeatFallbackEnabled: true,
    iosBackgroundRiskAcknowledged: true,
    legalDisclaimerAccepted: true,
    emergencyPauseUntil: null,
    requireTotpUnlock: false,
    privateFirstMode: true,
    tracePrivacyProfile: 'minimal',
  );

  @override
  Future<SafetySettingsModel> build() async => seeded;

  @override
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
    required bool privateFirstMode,
    required String tracePrivacyProfile,
  }) async {
    state = AsyncData(
      SafetySettingsModel(
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
        privateFirstMode: privateFirstMode,
        tracePrivacyProfile: tracePrivacyProfile,
      ),
    );
  }
}

void main() {
  testWidgets('Safety settings screen exposes private-first controls and saves', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          safetySettingsProvider.overrideWith(() => _FakeSafetySettingsController()),
        ],
        child: const MaterialApp(home: SafetySettingsScreen()),
      ),
    );

    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Private-first Mode'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.text('Private-first Mode'), findsOneWidget);
    expect(find.text('Keep private-first mode enabled'), findsOneWidget);
    expect(find.text('Privacy preset'), findsOneWidget);
    expect(find.text('Recommended for beta'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Audit-heavy').last,
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Audit-heavy').last, warnIfMissed: false);
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.widgetWithText(FilledButton, 'Save Safety Settings'));
    await tester.tap(find.widgetWithText(FilledButton, 'Save Safety Settings'));
    await tester.pumpAndSettle();

    expect(find.text('Safety settings updated.'), findsOneWidget);
    expect(find.text('Best for audits'), findsOneWidget);
    expect(find.textContaining('sanitized evidence and owner references'), findsWidgets);
  });

  testWidgets('Onboarding setup shows technical companion and privacy profile choices', (tester) async {
    final initialProfile = ProfileModel(
      id: 'owner-1',
      backupEmail: 'owner@example.com',
      beneficiaryEmail: 'beneficiary@example.com',
      beneficiaryName: 'Beneficiary Example',
      beneficiaryPhone: '+66-800-000-111',
      beneficiaryVerificationHint: 'Family phrase',
      beneficiaryVerificationPhraseHash: 'seeded-hash',
      legacyInactivityDays: 180,
      selfRecoveryInactivityDays: 45,
      lastActiveAt: DateTime(2026, 1, 1),
    );

    const initialSettings = SafetySettingsModel(
      remindersEnabled: true,
      reminderOffsetsDays: [14, 7, 1],
      gracePeriodDays: 7,
      proofOfLifeCheckMode: 'biometric_tap',
      proofOfLifeFallbackChannels: ['email', 'sms'],
      serverHeartbeatFallbackEnabled: true,
      iosBackgroundRiskAcknowledged: true,
      legalDisclaimerAccepted: false,
      emergencyPauseUntil: null,
      requireTotpUnlock: false,
      privateFirstMode: true,
      tracePrivacyProfile: 'minimal',
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: OnboardingSetupScreen(
            initialProfile: initialProfile,
            initialSettings: initialSettings,
          ),
        ),
      ),
    );

    await tester.ensureVisible(find.widgetWithText(FilledButton, 'Continue').first);
    await tester.tap(find.widgetWithText(FilledButton, 'Continue').first, warnIfMissed: false);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.widgetWithText(FilledButton, 'Continue').first);
    await tester.tap(find.widgetWithText(FilledButton, 'Continue').first, warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(find.text('I understand legal companion mode'), findsOneWidget);
    expect(find.textContaining('technical companion'), findsOneWidget);
    expect(find.text('Keep private-first mode enabled'), findsOneWidget);
    expect(find.text('Privacy preset'), findsOneWidget);
    expect(find.textContaining('does not replace a legal will'), findsOneWidget);
    expect(find.text('Highest privacy'), findsOneWidget);

    await tester.ensureVisible(find.text('Confidential').last);
    await tester.tap(find.text('Confidential').last, warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(find.text('Confidential'), findsWidgets);
    expect(find.text('Highest privacy'), findsOneWidget);
  });

  test('privacy presets map to expected trace profiles', () {
    expect(presetById('confidential').tracePrivacyProfile, 'confidential');
    expect(presetById('minimal').recommended, isTrue);
    expect(presetById('audit-heavy').privateFirstMode, isTrue);
  });

  testWidgets('Dashboard policy card shows active privacy preset', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          safetySettingsProvider.overrideWith(() => _FakeSafetySettingsController()),
          profileProvider.overrideWith((ref) async => ProfileModel(
                id: 'owner-1',
                backupEmail: 'owner@example.com',
                beneficiaryEmail: 'beneficiary@example.com',
                beneficiaryName: 'Beneficiary Example',
                beneficiaryPhone: '+66-800-000-111',
                beneficiaryVerificationHint: 'Family phrase',
                beneficiaryVerificationPhraseHash: 'seeded-hash',
                legacyInactivityDays: 180,
                selfRecoveryInactivityDays: 45,
                lastActiveAt: DateTime(2026, 1, 1),
              )),
        ],
        child: const MaterialApp(home: DashboardScreen()),
      ),
    );

    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.textContaining('Privacy Preset: Minimal'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Privacy Preset: Minimal'), findsOneWidget);
    expect(find.textContaining('Technical companion only'), findsWidgets);
  });
}
