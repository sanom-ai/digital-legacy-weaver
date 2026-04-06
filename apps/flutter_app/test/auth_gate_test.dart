import 'package:digital_legacy_weaver/features/auth/auth_gate.dart';
import 'package:digital_legacy_weaver/features/settings/safety_settings_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('AuthGate shows missing config guidance without supabase defines',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(home: AuthGate()));
    expect(
        find.text('Start now with private-first local mode'), findsOneWidget);
    expect(find.text('Choose your first real user journey'), findsOneWidget);
    expect(find.text('Family beneficiary handoff'), findsOneWidget);
    expect(find.text('Owner self-recovery'), findsOneWidget);
    expect(find.text('Private-first archive'), findsOneWidget);
    expect(find.text('Start local workspace'), findsOneWidget);
    expect(find.text('Show cloud setup steps'), findsOneWidget);
    expect(find.textContaining('No backend setup is required to start'),
        findsOneWidget);
  });

  test('SafetySettingsModel reads private-first defaults', () {
    final model = SafetySettingsModel.fromMap(const {
      'private_first_mode': true,
      'trace_privacy_profile': 'confidential',
    });
    expect(model.privateFirstMode, isTrue);
    expect(model.tracePrivacyProfile, 'confidential');
  });
}
