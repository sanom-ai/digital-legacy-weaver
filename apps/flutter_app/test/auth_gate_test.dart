import 'package:digital_legacy_weaver/features/auth/auth_gate.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('AuthGate shows missing config guidance without supabase defines', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: AuthGate()));
    expect(find.text('Supabase is not configured'), findsOneWidget);
    expect(find.textContaining('--dart-define=SUPABASE_URL='), findsOneWidget);
  });
}
