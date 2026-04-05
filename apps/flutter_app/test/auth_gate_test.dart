import 'package:digital_legacy_weaver/features/auth/auth_gate.dart';
import 'package:digital_legacy_weaver/features/settings/safety_settings_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('AuthGate shows missing config guidance without supabase defines', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: AuthGate()));
    expect(find.text('Finish backend setup or open demo mode'), findsOneWidget);
    expect(find.text('Open demo workspace'), findsOneWidget);
    expect(find.text('Show setup reminder'), findsOneWidget);
    expect(find.textContaining('--dart-define=SUPABASE_URL='), findsOneWidget);
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
