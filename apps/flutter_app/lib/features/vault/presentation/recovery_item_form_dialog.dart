import 'package:digital_legacy_weaver/features/vault/data/recovery_item_model.dart';
import 'package:flutter/material.dart';

class RecoveryItemDraft {
  const RecoveryItemDraft({
    required this.kind,
    required this.title,
    required this.encryptedPayload,
    required this.releaseNotes,
    required this.postTriggerVisibility,
    required this.valueDisclosureMode,
  });

  final RecoveryKind kind;
  final String title;
  final String encryptedPayload;
  final String? releaseNotes;
  final String postTriggerVisibility;
  final String valueDisclosureMode;
}

class RecoveryItemFormDialog extends StatefulWidget {
  const RecoveryItemFormDialog({super.key});

  @override
  State<RecoveryItemFormDialog> createState() => _RecoveryItemFormDialogState();
}

class _RecoveryItemFormDialogState extends State<RecoveryItemFormDialog> {
  final _titleController = TextEditingController();
  final _payloadController = TextEditingController();
  final _notesController = TextEditingController();
  RecoveryKind _kind = RecoveryKind.legacy;
  String _postTriggerVisibility = 'route_only';
  String _valueDisclosureMode = 'institution_verified_only';

  @override
  void dispose() {
    _titleController.dispose();
    _payloadController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _submit() {
    final title = _titleController.text.trim();
    final payload = _payloadController.text.trim();
    final notes = _notesController.text.trim();
    if (title.isEmpty || payload.isEmpty) return;
    Navigator.of(context).pop(
      RecoveryItemDraft(
        kind: _kind,
        title: title,
        encryptedPayload: payload,
        releaseNotes: notes.isEmpty ? null : notes,
        postTriggerVisibility: _postTriggerVisibility,
        valueDisclosureMode: _valueDisclosureMode,
      ),
    );
  }

  bool _containsMoneyLikeText(String input) {
    if (input.trim().isEmpty) return false;
    final hasCurrency = RegExp(
      r'\b(thb|baht|usd|eur|บาท)\s*[\d,]+(?:\.\d{1,2})?\b',
      caseSensitive: false,
    ).hasMatch(input);
    final hasLargeNumber = RegExp(
      r'(?<!\w)([\d]{1,3}(?:,[\d]{3})+|[\d]{5,})(?:\.\d{1,2})?(?!\w)',
    ).hasMatch(input);
    return hasCurrency || hasLargeNumber;
  }

  String _redactMoneyLikeText(String input) {
    var output = input;
    output = output.replaceAllMapped(
      RegExp(
        r'\b(thb|baht|usd|eur|บาท)\s*[\d,]+(?:\.\d{1,2})?\b',
        caseSensitive: false,
      ),
      (_) => 'ตรวจที่ปลายทาง',
    );
    output = output.replaceAllMapped(
      RegExp(r'(?<!\w)[\d]{1,3}(?:,[\d]{3})+(?:\.\d{1,2})?(?!\w)'),
      (_) => 'ตรวจที่ปลายทาง',
    );
    output = output.replaceAllMapped(
      RegExp(r'(?<!\w)[\d]{5,}(?:\.\d{1,2})?(?!\w)'),
      (_) => 'ตรวจที่ปลายทาง',
    );
    return output;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AlertDialog(
      title: const Text('เพิ่มรายการสินทรัพย์'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                gradient: const LinearGradient(
                  colors: [Color(0xFFF8F1E7), Color(0xFFFFFCF8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(color: const Color(0xFFE5D5BE)),
              ),
              child: const Text(
                'เก็บเฉพาะข้อมูลอ้างอิงที่จำเป็น เช่น ชื่อรายการ จุดตรวจสอบ และวิธีปล่อยข้อมูล โดยไม่ใส่มูลค่าจริงลงในฟอร์มนี้',
              ),
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<RecoveryKind>(
              initialValue: _kind,
              items: const [
                DropdownMenuItem(
                  value: RecoveryKind.legacy,
                  child: Text('ส่งต่อมรดกดิจิทัล'),
                ),
                DropdownMenuItem(
                  value: RecoveryKind.selfRecovery,
                  child: Text('กู้คืนด้วยตัวเอง'),
                ),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() => _kind = value);
                }
              },
              decoration: const InputDecoration(labelText: 'ประเภทเส้นทาง'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'ชื่อรายการ',
                hintText: 'เช่น บัญชีธนาคารหลัก หรือ โฟลเดอร์รูปครอบครัว',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _payloadController,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                labelText: 'ข้อมูลเข้ารหัสอ้างอิง',
                hintText:
                    'เช่น รหัสอ้างอิงเอกสาร หรือข้อความว่าให้ตรวจที่ปลายทาง',
              ),
              minLines: 2,
              maxLines: 4,
            ),
            if (_containsMoneyLikeText(_payloadController.text)) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: const Color(0xFFFFF4E8),
                  border: Border.all(color: const Color(0xFFF0C48A)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'พบข้อความที่คล้ายยอดเงิน',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'เพื่อความปลอดภัย ควรเก็บเป็นข้อมูลอ้างอิง ไม่ใส่ยอดเงินจริงในช่องนี้',
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: () {
                        setState(() {
                          _payloadController.text =
                              _redactMoneyLikeText(_payloadController.text);
                        });
                      },
                      icon: const Icon(Icons.shield_outlined),
                      label: const Text('แทนอัตโนมัติเป็น "ตรวจที่ปลายทาง"'),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),
            TextField(
              controller: _notesController,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                labelText: 'หมายเหตุการส่งมอบ (ไม่บังคับ)',
                hintText: 'เช่น ใครควรเริ่มติดต่อก่อน หรือควรตรวจเอกสารชุดไหน',
              ),
            ),
            if (_containsMoneyLikeText(_notesController.text)) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton.icon(
                  onPressed: () {
                    setState(() {
                      _notesController.text =
                          _redactMoneyLikeText(_notesController.text);
                    });
                  },
                  icon: const Icon(Icons.auto_fix_high_rounded),
                  label: const Text('แทนยอดในหมายเหตุเป็น "ตรวจที่ปลายทาง"'),
                ),
              ),
            ],
            const SizedBox(height: 12),
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              childrenPadding: EdgeInsets.zero,
              iconColor: scheme.primary,
              collapsedIconColor: scheme.onSurfaceVariant,
              title: const Text('รายละเอียดการส่งมอบ'),
              subtitle: const Text(
                'เปิดเมื่อต้องการกำหนดระดับการมองเห็นและการเปิดเผยมูลค่า',
              ),
              children: [
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: _postTriggerVisibility,
                  items: const [
                    DropdownMenuItem(
                      value: 'existence_only',
                      child: Text('หลังเข้าเงื่อนไข: ยืนยันการมีอยู่เท่านั้น'),
                    ),
                    DropdownMenuItem(
                      value: 'route_only',
                      child: Text('หลังเข้าเงื่อนไข: แสดงเส้นทางเท่านั้น'),
                    ),
                    DropdownMenuItem(
                      value: 'route_and_instructions',
                      child: Text('หลังเข้าเงื่อนไข: เส้นทางและคำแนะนำ'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _postTriggerVisibility = value);
                    }
                  },
                  decoration: const InputDecoration(
                    labelText: 'ระดับการมองเห็นหลังเข้าเงื่อนไข',
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _valueDisclosureMode,
                  items: const [
                    DropdownMenuItem(
                      value: 'hidden',
                      child: Text('การเปิดเผยมูลค่า: ซ่อนไว้'),
                    ),
                    DropdownMenuItem(
                      value: 'institution_verified_only',
                      child: Text('การเปิดเผยมูลค่า: ให้สถาบันยืนยันเท่านั้น'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _valueDisclosureMode = value);
                    }
                  },
                  decoration: const InputDecoration(
                    labelText: 'โหมดการเปิดเผยมูลค่า',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('ยกเลิก'),
        ),
        FilledButton(
          onPressed: _submit,
          child: const Text('บันทึก'),
        ),
      ],
    );
  }
}
