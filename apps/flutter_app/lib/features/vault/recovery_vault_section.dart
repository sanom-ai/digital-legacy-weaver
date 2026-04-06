import 'package:digital_legacy_weaver/features/vault/data/recovery_item_model.dart';
import 'package:digital_legacy_weaver/features/vault/data/vault_provider.dart';
import 'package:digital_legacy_weaver/features/vault/presentation/recovery_item_form_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class RecoveryVaultSection extends ConsumerWidget {
  const RecoveryVaultSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemsAsync = ref.watch(vaultItemsProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Recovery Vault',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                FilledButton.tonal(
                  onPressed: () async {
                    final draft = await showDialog<RecoveryItemDraft>(
                      context: context,
                      builder: (_) => const RecoveryItemFormDialog(),
                    );
                    if (draft == null) return;
                    await ref.read(vaultItemsProvider.notifier).addItem(
                          kind: draft.kind,
                          title: draft.title,
                          encryptedPayload: draft.encryptedPayload,
                          releaseNotes: draft.releaseNotes,
                          postTriggerVisibility: draft.postTriggerVisibility,
                          valueDisclosureMode: draft.valueDisclosureMode,
                        );
                  },
                  child: const Text("Add"),
                ),
              ],
            ),
            const SizedBox(height: 12),
            itemsAsync.when(
              data: (items) {
                if (items.isEmpty) {
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF7ED),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "No recovery items yet.",
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        SizedBox(height: 6),
                        Text(
                          "Add at least one encrypted recovery item so this workspace can support real self-recovery or beneficiary handoff.",
                        ),
                      ],
                    ),
                  );
                }
                return Column(
                  children: items.map((item) {
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(item.title),
                      subtitle: Text(
                        "${item.releaseNotes ?? "Encrypted vault item"}\nVisibility: ${item.postTriggerVisibility} | Value: ${item.valueDisclosureMode}",
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(999),
                              color: const Color(0xFFE5D7C5),
                            ),
                            child: Text(item.kind.label),
                          ),
                          IconButton(
                            onPressed: () => ref.read(vaultItemsProvider.notifier).deleteItem(item.id),
                            icon: const Icon(Icons.delete_outline),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                );
              },
              loading: () => const Padding(
                padding: EdgeInsets.all(8),
                child: Row(
                  children: [
                    SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: 8),
                    Expanded(child: Text("Loading recovery vault items...")),
                  ],
                ),
              ),
              error: (error, _) => Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF1F1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Vault load error",
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 6),
                    Text("$error"),
                    const SizedBox(height: 8),
                    OutlinedButton(
                      onPressed: () => ref.invalidate(vaultItemsProvider),
                      child: const Text("Retry"),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

