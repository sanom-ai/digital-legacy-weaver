import 'package:digital_legacy_weaver/features/vault/data/recovery_item_model.dart';
import 'package:flutter/material.dart';

class RecoveryItemDraft {
  const RecoveryItemDraft({
    required this.kind,
    required this.title,
    required this.encryptedPayload,
    required this.releaseNotes,
  });

  final RecoveryKind kind;
  final String title;
  final String encryptedPayload;
  final String? releaseNotes;
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
      ),
    );
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
                DropdownMenuItem(value: RecoveryKind.legacy, child: Text("Legacy")),
                DropdownMenuItem(value: RecoveryKind.selfRecovery, child: Text("Self Recovery")),
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
              decoration: const InputDecoration(
                labelText: "Encrypted payload",
                hintText: "Base64/Ciphertext",
              ),
              minLines: 2,
              maxLines: 4,
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(labelText: "Release notes (optional)"),
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
