import 'package:digital_legacy_weaver/features/onboarding/onboarding_setup_screen.dart';
import 'package:digital_legacy_weaver/features/dashboard/dashboard_screen.dart';
import 'package:digital_legacy_weaver/features/unlock/unlock_delivery_screen.dart';
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
        guardianQuorumEnabled: guardianQuorumEnabled,
        guardianQuorumRequired: guardianQuorumRequired,
        guardianQuorumPoolSize: guardianQuorumPoolSize,
        emergencyAccessEnabled: emergencyAccessEnabled,
        emergencyAccessRequiresBeneficiaryRequest:
            emergencyAccessRequiresBeneficiaryRequest,
        emergencyAccessRequiresGuardianQuorum:
            emergencyAccessRequiresGuardianQuorum,
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
      ),
    );
  }
}

void main() {
  testWidgets(
    'Safety settings screen exposes private-first controls and saves',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            safetySettingsProvider.overrideWith(
              () => _FakeSafetySettingsController(),
            ),
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

      await tester.ensureVisible(
        find.widgetWithText(FilledButton, 'บันทึกการตั้งค่าความปลอดภัย'),
      );
      await tester.tap(
        find.widgetWithText(FilledButton, 'บันทึกการตั้งค่าความปลอดภัย'),
      );
      await tester.pumpAndSettle();

      expect(
          find.text('บันทึกการตั้งค่าความปลอดภัยเรียบร้อยแล้ว'), findsOneWidget);
      expect(find.text('Best for audits'), findsOneWidget);
      expect(
        find.textContaining('sanitized evidence and owner references'),
        findsWidgets,
      );
    },
  );

  testWidgets(
    'Onboarding setup shows technical companion and privacy profile choices',
    (tester) async {
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

      final nextButtonFinder = find.widgetWithText(FilledButton, 'ถัดไป');
      await tester.ensureVisible(nextButtonFinder.first);
      await tester.tap(nextButtonFinder.first, warnIfMissed: false);
      await tester.pumpAndSettle();
      await tester.ensureVisible(nextButtonFinder.first);
      await tester.tap(nextButtonFinder.first, warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(find.text('ฉันเข้าใจขอบเขตทางกฎหมายของแอป'), findsOneWidget);
      expect(find.textContaining('เครื่องมือช่วยจัดการดิจิทัล'), findsOneWidget);
      expect(find.text('เปิดโหมดความเป็นส่วนตัวสูงสุดไว้'), findsOneWidget);
      expect(find.text('ระดับความเป็นส่วนตัว'), findsOneWidget);
      expect(
        find.textContaining('ไม่ได้แทนที่พินัยกรรม'),
        findsOneWidget,
      );
      expect(find.text('Highest privacy'), findsOneWidget);

      await tester.ensureVisible(find.text('Confidential').last);
      await tester.tap(find.text('Confidential').last, warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(find.text('Confidential'), findsWidgets);
      expect(find.text('Highest privacy'), findsOneWidget);
    },
  );

  test('privacy presets map to expected trace profiles', () {
    expect(presetById('confidential').tracePrivacyProfile, 'confidential');
    expect(presetById('minimal').recommended, isTrue);
    expect(presetById('audit-heavy').privateFirstMode, isTrue);
  });

  testWidgets('Dashboard policy card shows active privacy preset', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          safetySettingsProvider.overrideWith(
            () => _FakeSafetySettingsController(),
          ),
          profileProvider.overrideWith(
            (ref) async => ProfileModel(
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
            ),
          ),
        ],
        child: const MaterialApp(home: DashboardScreen()),
      ),
    );

    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.textContaining('ระดับความเป็นส่วนตัว: Minimal'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('ระดับความเป็นส่วนตัว: Minimal'), findsOneWidget);
    expect(find.textContaining('ขอบเขตผลิตภัณฑ์:'), findsWidgets);
  });

  testWidgets('Unlock flow shows anti-scam no-link guidance', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: UnlockDeliveryScreen()),
      ),
    );

    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.textContaining('ข้อควรรู้ก่อนทำต่อ'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('ข้อควรรู้ก่อนทำต่อ'), findsOneWidget);
    expect(find.textContaining('ไม่ขอรหัสผ่าน'), findsWidgets);
    expect(find.textContaining('อย่ากดลิงก์จากข้อความ'), findsOneWidget);
    expect(
      find.textContaining('เปิดแอป Digital Legacy Weaver เอง แล้วกรอกรหัส'),
      findsOneWidget,
    );
    expect(find.text('วางชุดข้อมูลรับมอบ (ไม่ต้องกดลิงก์)'), findsOneWidget);
  });
}


