import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _emailController = TextEditingController();
  bool _sending = false;
  String? _message;
  bool _messageIsError = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendMagicLink() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() {
        _message = "กรุณากรอกอีเมล";
        _messageIsError = true;
      });
      return;
    }
    if (!email.contains("@") || !email.contains(".")) {
      setState(() {
        _message = "กรุณากรอกอีเมลให้ถูกต้อง";
        _messageIsError = true;
      });
      return;
    }
    setState(() {
      _sending = true;
      _message = null;
    });

    try {
      await Supabase.instance.client.auth.signInWithOtp(
        email: email,
        emailRedirectTo: null,
      );
      setState(() {
        _message =
            "ส่งลิงก์เข้าสู่ระบบแบบปลอดภัยแล้ว กรุณาตรวจกล่องจดหมาย (รวมถึงสแปม) แล้วกลับมาทำต่อ";
        _messageIsError = false;
      });
    } on AuthException catch (e) {
      setState(() {
        _message = _friendlyAuthError(e.message);
        _messageIsError = true;
      });
    } finally {
      if (mounted) {
        setState(() => _sending = false);
      }
    }
  }

  String _friendlyAuthError(String raw) {
    final lower = raw.toLowerCase();
    if (lower.contains("network") ||
        lower.contains("timed out") ||
        lower.contains("failed host lookup")) {
      return "เครือข่ายไม่เสถียร กรุณาตรวจสอบอินเทอร์เน็ตแล้วลองใหม่";
    }
    return raw;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFAF6F0), Color(0xFFF4EEE5), Color(0xFFF9F5EE)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(999),
                          color: const Color(0xFFE7F0EE),
                          border: Border.all(color: const Color(0xFFD5E7E3)),
                        ),
                        child: Text(
                          "พื้นที่ทำงานส่วนตัวและปลอดภัย",
                          style:
                              Theme.of(context).textTheme.labelLarge?.copyWith(
                                    color: const Color(0xFF17444D),
                                  ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "ยินดีต้อนรับสู่ Digital Legacy Weaver",
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(
                              fontWeight: FontWeight.w700,
                              height: 1.05,
                            ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        "เข้าสู่ระบบเพื่อจัดการการกู้คืนตัวเองและการส่งต่อให้ผู้รับในที่เดียว",
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: scheme.onSurface.withValues(alpha: 0.8),
                              height: 1.4,
                            ),
                      ),
                      const SizedBox(height: 18),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          color: Colors.white.withValues(alpha: 0.72),
                          border: Border.all(color: const Color(0xFFE5D6C2)),
                        ),
                        child: const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "สิ่งที่แอปช่วยคุณได้ทันที",
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                            SizedBox(height: 8),
                            Text(
                                "1. เก็บข้อมูลการเข้าถึงสำคัญแบบ private-first"),
                            SizedBox(height: 4),
                            Text(
                                "2. ลดความเสี่ยงสูญเสียการเข้าถึงขณะยังใช้งานอยู่"),
                            SizedBox(height: 4),
                            Text(
                                "3. เตรียมการส่งต่ออย่างปลอดภัยให้ผู้รับที่ถูกต้อง"),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        controller: _emailController,
                        decoration: const InputDecoration(
                          labelText: "อีเมล",
                          hintText: "you@example.com",
                        ),
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: _sending ? null : _sendMagicLink,
                          child: Text(
                            _sending
                                ? "กำลังส่ง..."
                                : "ส่งลิงก์เข้าสู่ระบบแบบปลอดภัย",
                          ),
                        ),
                      ),
                      if (_message != null) ...[
                        const SizedBox(height: 14),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: _messageIsError
                                ? const Color(0xFFFFF6F4)
                                : const Color(0xFFF2F8F4),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: _messageIsError
                                  ? const Color(0xFFF0CEC8)
                                  : const Color(0xFFD5E6D9),
                            ),
                          ),
                          child: Text(_message!),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
