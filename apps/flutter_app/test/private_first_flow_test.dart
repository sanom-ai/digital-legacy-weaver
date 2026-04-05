import 'package:digital_legacy_weaver/features/onboarding/onboarding_setup_screen.dart';
import 'package:digital_legacy_weaver/features/profile/profile_model.dart';
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
    gracePeriodDays: 3,
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
          safetySettingsProvider.overrideWith(_FakeSafetySettingsController.new),
        ],
        child: const MaterialApp(home: SafetySettingsScreen()),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Private-first Mode'), findsOneWidget);
    expect(find.text('Enable private-first mode'), findsOneWidget);
    expect(find.text('Trace privacy profile'), findsOneWidget);

    await tester.tap(find.text('Minimal'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Audit-heavy').last);
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, 'Save Safety Settings'));
    await tester.pumpAndSettle();

    expect(find.text('Safety settings updated.'), findsOneWidget);
    expect(find.textContaining('evidence and owner references'), findsOneWidget);
  });

  testWidgets('Onboarding setup shows technical companion and privacy profile choices', (tester) async {
    const initialProfile = ProfileModel(
      id: 'owner-1',
      backupEmail: 'owner@example.com',
      beneficiaryEmail: 'beneficiary@example.com',
      legacyInactivityDays: 180,
      selfRecoveryInactivityDays: 45,
      lastActiveAt: DateTime(2026, 1, 1),
    );

    const initialSettings = SafetySettingsModel(
      remindersEnabled: true,
      reminderOffsetsDays: [14, 7, 1],
      gracePeriodDays: 3,
      legalDisclaimerAccepted: false,
      emergencyPauseUntil: null,
      requireTotpUnlock: false,
      privateFirstMode: true,
      tracePrivacyProfile: 'minimal',
    );

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: OnboardingSetupScreen(
            initialProfile: initialProfile,
            initialSettings: initialSettings,
          ),
        ),
      ),
    );

    await tester.tap(find.widgetWithText(FilledButton, 'Continue'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Continue'));
    await tester.pumpAndSettle();

    expect(find.text('I understand legal companion mode'), findsOneWidget);
    expect(find.textContaining('technical companion'), findsOneWidget);
    expect(find.text('Enable private-first mode'), findsOneWidget);
    expect(find.text('Trace privacy profile'), findsOneWidget);
    expect(find.textContaining('does not replace a legal will'), findsOneWidget);

    await tester.tap(find.text('Minimal'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Confidential').last);
    await tester.pumpAndSettle();

    expect(find.text('Confidential'), findsWidgets);
  });
}
