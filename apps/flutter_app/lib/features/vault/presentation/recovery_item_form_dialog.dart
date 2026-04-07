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
  String _postTriggerVisibility = "route_only";
  String _valueDisclosureMode = "institution_verified_only";

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
    return AlertDialog(
      title: const Text("Add Recovery Item"),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<RecoveryKind>(
              initialValue: _kind,
              items: const [
                DropdownMenuItem(
                    value: RecoveryKind.legacy, child: Text("Legacy")),
                DropdownMenuItem(
                    value: RecoveryKind.selfRecovery,
                    child: Text("Self Recovery")),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() => _kind = value);
                }
              },
              decoration: const InputDecoration(labelText: "Mode"),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: "Title"),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _payloadController,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                labelText: "Encrypted payload",
                hintText: "Base64/Ciphertext",
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
                  borderRadius: BorderRadius.circular(10),
                  color: const Color(0xFFFFF4E8),
                  border: Border.all(color: const Color(0xFFF0C48A)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "พบข้อมูลที่คล้ายยอดเงิน",
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'เพื่อความปลอดภัย ฟิลด์นี้ควรเก็บเป็นข้อมูลอ้างอิง ไม่ใช่ยอดเงินจริง',
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
            const SizedBox(height: 10),
            TextField(
              controller: _notesController,
              onChanged: (_) => setState(() {}),
              decoration:
                  const InputDecoration(labelText: "Release notes (optional)"),
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
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              initialValue: _postTriggerVisibility,
              items: const [
                DropdownMenuItem(
                    value: "existence_only",
                    child: Text("Post-trigger: existence only")),
                DropdownMenuItem(
                    value: "route_only",
                    child: Text("Post-trigger: route only")),
                DropdownMenuItem(
                  value: "route_and_instructions",
                  child: Text("Post-trigger: route and instructions"),
                ),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() => _postTriggerVisibility = value);
                }
              },
              decoration:
                  const InputDecoration(labelText: "Visibility after trigger"),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              initialValue: _valueDisclosureMode,
              items: const [
                DropdownMenuItem(
                    value: "hidden", child: Text("Value disclosure: hidden")),
                DropdownMenuItem(
                  value: "institution_verified_only",
                  child: Text("Value disclosure: institution verified only"),
                ),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() => _valueDisclosureMode = value);
                }
              },
              decoration:
                  const InputDecoration(labelText: "Value disclosure mode"),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text("Cancel"),
        ),
        FilledButton(
          onPressed: _submit,
          child: const Text("Save"),
        ),
      ],
    );
  }
}
