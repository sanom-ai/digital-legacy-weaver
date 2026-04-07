import 'package:digital_legacy_weaver/features/unlock/unlock_delivery_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Unlock screen renders core fields', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: UnlockDeliveryScreen()));
    expect(find.text('ขั้นตอนรับมอบสำหรับผู้รับผลประโยชน์'), findsOneWidget);
    expect(find.text('สิ่งที่ผู้รับควรเตรียม | What you need'), findsOneWidget);
    expect(find.text('ถ้าไม่ใช่ของคุณ | Not the intended recipient?'), findsOneWidget);
    expect(find.textContaining('ยืนยันข้อมูลรับมอบ'), findsOneWidget);
    expect(find.textContaining('ยืนยันตัวตนผู้รับ'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Access ID (รหัสอ้างอิง)'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Access Key (กุญแจรับมอบ)'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'รหัสยืนยัน | Verification code'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'ชื่อผู้รับที่ลงทะเบียนไว้'), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, 'ขอรหัสยืนยัน | Request code'), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, 'ไม่ใช่ของฉัน | This receipt is not mine'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'เปิดชุดรับมอบ | Open bundle'), findsOneWidget);
  });
}
