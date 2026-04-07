import 'package:digital_legacy_weaver/core/providers/supabase_provider.dart';
import 'package:digital_legacy_weaver/core/widgets/app_feedback.dart';
import 'package:digital_legacy_weaver/core/widgets/app_state_panel.dart';
import 'package:digital_legacy_weaver/features/settings/totp_factor_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final totpFactorRepositoryProvider = Provider<TotpFactorRepository>((ref) {
  return TotpFactorRepository(ref.watch(supabaseClientProvider));
});

class TotpFactorScreen extends ConsumerStatefulWidget {
  const TotpFactorScreen({super.key});

  @override
  ConsumerState<TotpFactorScreen> createState() => _TotpFactorScreenState();
}

class _TotpFactorScreenState extends ConsumerState<TotpFactorScreen> {
  final _codeController = TextEditingController();
  bool _busy = false;
  TotpFactorStatus? _status;
  TotpSetupBundle? _setupBundle;
  String? _message;
  bool _messageIsError = false;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _reload() async {
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      final status = await ref.read(totpFactorRepositoryProvider).getStatus();
      if (!mounted) return;
      setState(() => _status = status);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _message = "ยังโหลดสถานะการยืนยันตัวตนไม่สำเร็จ กรุณาลองใหม่อีกครั้ง";
        _messageIsError = true;
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _beginSetup() async {
    setState(() {
      _busy = true;
      _message = null;
      _setupBundle = null;
    });
    try {
      final bundle = await ref.read(totpFactorRepositoryProvider).beginSetup();
      if (!mounted) return;
      setState(() {
        _setupBundle = bundle;
        _message =
            "สแกนรหัสนี้ในแอปยืนยันตัวตนของคุณ แล้วกรอกรหัส 6 หลักเพื่อยืนยัน";
        _messageIsError = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _message = "เริ่มตั้งค่าการยืนยันตัวตนไม่สำเร็จ กรุณาลองใหม่อีกครั้ง";
        _messageIsError = true;
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _confirmSetup() async {
    final code = _codeController.text.trim();
    if (code.length < 6) {
      setState(() {
        _message = "กรุณากรอกรหัส 6 หลักให้ถูกต้อง";
        _messageIsError = true;
      });
      return;
    }
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      final status = await ref
          .read(totpFactorRepositoryProvider)
          .confirmSetup(totpCode: code, requireTotpUnlock: true);
      if (!mounted) return;
      setState(() {
        _status = status;
        _setupBundle = null;
        _codeController.clear();
        _message = "เปิดใช้งานการยืนยันตัวตนด้วยรหัสสำเร็จ";
        _messageIsError = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _message = "ยืนยันไม่สำเร็จ กรุณาตรวจสอบรหัส 6 หลักแล้วลองใหม่";
        _messageIsError = true;
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _disable() async {
    final confirmed = await AppFeedback.confirmAction(
      context: context,
      title: "ยืนยันการปิดการยืนยันตัวตน",
      message:
          "เมื่อปิดแล้ว การปลดล็อกจะไม่บังคับใช้รหัส TOTP ต้องการปิดใช่ไหม",
      confirmLabel: "ปิดการยืนยันตัวตน",
      destructive: true,
      icon: Icons.lock_open_rounded,
    );
    if (!confirmed) return;

    setState(() {
      _busy = true;
      _message = null;
      _setupBundle = null;
    });
    try {
      final status = await ref.read(totpFactorRepositoryProvider).disable();
      if (!mounted) return;
      setState(() {
        _status = status;
        _message = "ปิดการยืนยันตัวตนด้วยรหัสแล้ว";
        _messageIsError = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _message = "ปิดการยืนยันตัวตนไม่สำเร็จ กรุณาลองใหม่อีกครั้ง";
        _messageIsError = true;
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _messageBanner() {
    if (_message == null) {
      return const SizedBox.shrink();
    }
    return AppStatePanel(
      message: _message!,
      tone: _messageIsError
          ? (appStateLooksOfflineMessage(_message!)
              ? AppStateTone.offline
              : AppStateTone.error)
          : AppStateTone.success,
    );
  }

  @override
  Widget build(BuildContext context) {
    final status = _status;
    final enabled = status?.enabled ?? false;
    final configured = status?.configured ?? false;
    return Scaffold(
      appBar: AppBar(title: const Text("รหัสยืนยันตัวตน")),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "การยืนยันตัวตนชั้นที่สอง",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Text("ตั้งค่าแล้ว: ${configured ? "ใช่" : "ยังไม่ตั้งค่า"}"),
                  Text("สถานะ: ${enabled ? "เปิดใช้งาน" : "ปิดใช้งาน"}"),
                  Text(
                    "ต้องยืนยันก่อนปลดล็อก: ${(status?.requireTotpUnlock ?? false) ? "ใช่" : "ไม่บังคับ"}",
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _busy ? null : _reload,
                          child: const Text("รีเฟรช"),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: FilledButton(
                          onPressed: _busy ? null : _beginSetup,
                          child: const Text("เริ่มตั้งค่า"),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: (_busy || !enabled) ? null : _disable,
                      child: const Text("ปิดใช้งาน"),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_setupBundle != null) ...[
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "ข้อมูลสำหรับตั้งค่า",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text("คีย์ลับ (Base32)"),
                    SelectableText(_setupBundle!.secretBase32),
                    const SizedBox(height: 8),
                    const Text("ลิงก์ตั้งค่า"),
                    SelectableText(_setupBundle!.otpauthUri),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _codeController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: "รหัส 6 หลัก",
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _busy ? null : _confirmSetup,
                        child: const Text("ยืนยัน"),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          if (_message != null) ...[
            const SizedBox(height: 12),
            _messageBanner(),
          ],
        ],
      ),
    );
  }
}
