import 'package:digital_legacy_weaver/features/auth/auth_gate.dart';
import 'package:digital_legacy_weaver/features/settings/safety_settings_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('AuthGate shows missing config guidance without supabase defines',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(home: AuthGate()));
    expect(find.text('Start now in private local mode'), findsOneWidget);
    expect(find.text('Choose your first journey'), findsOneWidget);
    expect(find.text('Digital Legacy Handoff'), findsWidgets);
    expect(find.text('Owner Self-Recovery'), findsOneWidget);
    expect(find.text('Private-first Archive'), findsOneWidget);
    expect(find.text('Start in private mode'), findsOneWidget);
    expect(find.text('Cloud setup later'), findsOneWidget);
    expect(find.textContaining('No cloud setup needed'), findsOneWidget);
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
