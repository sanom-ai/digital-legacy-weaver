import 'package:digital_legacy_weaver/features/unlock/unlock_delivery_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Unlock screen renders core fields', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: UnlockDeliveryScreen()));
    expect(find.text('Secure Access'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Access ID'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Access Key'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Verification Code'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Unlock'), findsOneWidget);
  });
}
