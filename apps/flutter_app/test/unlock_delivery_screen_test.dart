import 'package:digital_legacy_weaver/features/unlock/unlock_delivery_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Unlock screen renders core fields', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: UnlockDeliveryScreen()));
    expect(find.text('Beneficiary Receipt Flow'), findsOneWidget);
    expect(find.text('What the beneficiary needs'), findsOneWidget);
    expect(find.text('Not the intended recipient?'), findsOneWidget);
    expect(find.textContaining('Confirm the access link'), findsOneWidget);
    expect(find.textContaining('Confirm your beneficiary identity'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Access ID'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Access Key'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Verification Code'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Registered beneficiary name'), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, 'Request Receipt Code'), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, 'This receipt is not mine'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Open Delivery Bundle'), findsOneWidget);
  });
}
