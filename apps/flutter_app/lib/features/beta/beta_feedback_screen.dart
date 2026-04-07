import 'package:digital_legacy_weaver/features/beta/beta_feedback_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class BetaFeedbackScreen extends ConsumerStatefulWidget {
  const BetaFeedbackScreen({super.key});

  @override
  ConsumerState<BetaFeedbackScreen> createState() => _BetaFeedbackScreenState();
}

class _BetaFeedbackScreenState extends ConsumerState<BetaFeedbackScreen> {
  final _formKey = GlobalKey<FormState>();
  final _summaryController = TextEditingController();
  final _detailsController = TextEditingController();
  final _appVersionController = TextEditingController(text: '0.1.x');

  String _category = 'ux';
  String _severity = 'medium';
  bool _submitting = false;
  String? _message;
  bool _messageIsError = false;

  @override
  void dispose() {
    _summaryController.dispose();
    _detailsController.dispose();
    _appVersionController.dispose();
    super.dispose();
  }

  String? _required(String? value) {
    final text = (value ?? '').trim();
    if (text.isEmpty) return 'กรุณากรอกข้อมูล';
    if (text.length < 8) return 'กรุณาเพิ่มรายละเอียดอีกเล็กน้อย';
    return null;
  }

  Future<void> _submit() async {
    if (_submitting) return;
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _submitting = true;
      _message = null;
    });
    try {
      await ref.read(betaFeedbackRepositoryProvider).submit(
            category: _category,
            severity: _severity,
            summary: _summaryController.text,
            details: _detailsController.text,
            appVersion: _appVersionController.text,
          );
      if (!mounted) return;
      setState(() {
        _message =
            'ส่งความคิดเห็นเรียบร้อยแล้ว ขอบคุณมาก ข้อมูลนี้ช่วยให้เราปรับปรุงแอปได้ดีขึ้น';
        _messageIsError = false;
      });
      _summaryController.clear();
      _detailsController.clear();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _message = _friendlyError(error);
        _messageIsError = true;
      });
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  String _friendlyError(Object error) {
    final lower = error.toString().toLowerCase();
    if (lower.contains('socketexception') ||
        lower.contains('failed host lookup') ||
        lower.contains('network') ||
        lower.contains('timed out')) {
      return 'ยังส่งความคิดเห็นไม่ได้ เพราะอินเทอร์เน็ตไม่เสถียร กรุณาลองใหม่อีกครั้ง';
    }
    if (lower.contains('authenticated user') || lower.contains('unauthorized')) {
      return 'เซสชันหมดอายุ กรุณาเข้าสู่ระบบใหม่แล้วส่งอีกครั้ง';
    }
    return 'ยังส่งความคิดเห็นไม่ได้ในขณะนี้ กรุณาลองใหม่อีกครั้ง';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ความคิดเห็นช่วงทดสอบใช้')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text(
              'ช่วยเราปรับปรุงแอปให้ใช้งานง่ายและเสถียรมากขึ้น',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _category,
              decoration: const InputDecoration(labelText: 'หมวดหมู่'),
              items: const [
                DropdownMenuItem(value: 'ux', child: Text('ประสบการณ์ใช้งาน')),
                DropdownMenuItem(value: 'bug', child: Text('บั๊ก')),
                DropdownMenuItem(value: 'security', child: Text('ความปลอดภัย')),
                DropdownMenuItem(value: 'reliability', child: Text('ความเสถียร')),
                DropdownMenuItem(value: 'other', child: Text('อื่น ๆ')),
              ],
              onChanged: (v) => setState(() => _category = v ?? 'ux'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _severity,
              decoration: const InputDecoration(labelText: 'ระดับความสำคัญ'),
              items: const [
                DropdownMenuItem(value: 'low', child: Text('ต่ำ')),
                DropdownMenuItem(value: 'medium', child: Text('กลาง')),
                DropdownMenuItem(value: 'high', child: Text('สูง')),
                DropdownMenuItem(value: 'critical', child: Text('เร่งด่วนมาก')),
              ],
              onChanged: (v) => setState(() => _severity = v ?? 'medium'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _summaryController,
              decoration: const InputDecoration(
                labelText: 'สรุปสั้น ๆ',
                hintText: 'สรุปปัญหาหรือข้อเสนอแนะ',
              ),
              validator: _required,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _detailsController,
              minLines: 4,
              maxLines: 8,
              decoration: const InputDecoration(
                labelText: 'รายละเอียดเพิ่มเติม (ไม่บังคับ)',
                hintText: 'ขั้นตอนที่ทำ ผลที่คาดหวัง และสิ่งที่เกิดขึ้นจริง',
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _appVersionController,
              decoration: const InputDecoration(labelText: 'เวอร์ชันแอป'),
            ),
            const SizedBox(height: 20),
            if (_message != null) ...[
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
              const SizedBox(height: 12),
            ],
            FilledButton(
              onPressed: _submitting ? null : _submit,
              child: Text(_submitting ? 'กำลังส่ง...' : 'ส่งความคิดเห็น'),
            ),
          ],
        ),
      ),
    );
  }
}
