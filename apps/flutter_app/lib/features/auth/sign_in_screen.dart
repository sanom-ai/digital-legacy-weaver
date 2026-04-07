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
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "ยินดีต้อนรับสู่ Digital Legacy Weaver",
                      style: TextStyle(fontSize: 30, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "เข้าสู่ระบบเพื่อจัดการการกู้คืนตัวเองและการส่งต่อให้ผู้รับในที่เดียว",
                    ),
                    const SizedBox(height: 10),
                    const Text("สิ่งที่แอปช่วยคุณได้ทันที"),
                    const SizedBox(height: 6),
                    const Text("1. เก็บข้อมูลการเข้าถึงสำคัญแบบ private-first"),
                    const Text("2. ลดความเสี่ยงสูญเสียการเข้าถึงขณะยังใช้งานอยู่"),
                    const Text("3. เตรียมการส่งต่ออย่างปลอดภัยให้ผู้รับที่ถูกต้อง"),
                    const SizedBox(height: 18),
                    TextField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: "อีเมล",
                        hintText: "you@example.com",
                      ),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _sending ? null : _sendMagicLink,
                        child: Text(_sending ? "กำลังส่ง..." : "ส่งลิงก์เข้าสู่ระบบแบบปลอดภัย"),
                      ),
                    ),
                    if (_message != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _messageIsError
                              ? const Color(0xFFFFF1F1)
                              : const Color(0xFFE9F6EF),
                          borderRadius: BorderRadius.circular(12),
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
    );
  }
}
