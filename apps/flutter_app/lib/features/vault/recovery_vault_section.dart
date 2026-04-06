import 'package:digital_legacy_weaver/features/vault/data/recovery_item_model.dart';
import 'package:digital_legacy_weaver/features/vault/data/vault_provider.dart';
import 'package:digital_legacy_weaver/features/vault/presentation/recovery_item_form_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class RecoveryVaultSection extends ConsumerStatefulWidget {
  const RecoveryVaultSection({super.key});

  @override
  ConsumerState<RecoveryVaultSection> createState() =>
      _RecoveryVaultSectionState();
}

class _RecoveryVaultSectionState extends ConsumerState<RecoveryVaultSection> {
  bool _adding = false;
  String? _deletingId;
  bool _isMessageError = false;
  String? _message;

  void _setMessage(String message, {bool isError = false}) {
    if (!mounted) return;
    setState(() {
      _message = message;
      _isMessageError = isError;
    });
  }

  String _friendlyActionError(String action, Object error) {
    final lower = error.toString().toLowerCase();
    if (lower.contains("socketexception") ||
        lower.contains("failed host lookup") ||
        lower.contains("network") ||
        lower.contains("timed out")) {
      return "Could not finish $action because the connection looks unstable. Please retry when your internet is stable.";
    }
    if (lower.contains("no authenticated user") ||
        lower.contains("unauthorized") ||
        lower.contains("forbidden")) {
      return "Your session may have expired. Please sign in again, then retry $action.";
    }
    return "We could not finish $action right now. Please retry in a moment.";
  }

  String _friendlyLoadError(Object error) {
    final lower = error.toString().toLowerCase();
    if (lower.contains("socketexception") ||
        lower.contains("failed host lookup") ||
        lower.contains("network") ||
        lower.contains("timed out")) {
      return "We cannot load vault items while offline. Please reconnect and retry.";
    }
    if (lower.contains("no authenticated user") ||
        lower.contains("unauthorized") ||
        lower.contains("forbidden")) {
      return "We cannot load vault items because your sign-in session is not valid. Please sign in again.";
    }
    return "We could not open your vault items right now. Please retry.";
  }

  Future<void> _handleAdd() async {
    if (_adding) return;
    final draft = await showDialog<RecoveryItemDraft>(
      context: context,
      builder: (_) => const RecoveryItemFormDialog(),
    );
    if (draft == null) return;

    setState(() => _adding = true);
    try {
      await ref.read(vaultItemsProvider.notifier).addItem(
            kind: draft.kind,
            title: draft.title,
            encryptedPayload: draft.encryptedPayload,
            releaseNotes: draft.releaseNotes,
            postTriggerVisibility: draft.postTriggerVisibility,
            valueDisclosureMode: draft.valueDisclosureMode,
          );
      _setMessage("Recovery item saved.");
    } catch (error) {
      _setMessage(_friendlyActionError("saving this recovery item", error), isError: true);
    } finally {
      if (mounted) {
        setState(() => _adding = false);
      }
    }
  }

  Future<void> _handleDelete(String id) async {
    if (_deletingId != null) return;
    setState(() => _deletingId = id);
    try {
      await ref.read(vaultItemsProvider.notifier).deleteItem(id);
      _setMessage("Recovery item removed.");
    } catch (error) {
      _setMessage(_friendlyActionError("removing this recovery item", error), isError: true);
    } finally {
      if (mounted) {
        setState(() => _deletingId = null);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
                  onPressed: _adding ? null : _handleAdd,
                  child: Text(_adding ? "Saving..." : "Add"),
                ),
              ],
            ),
            if (_message != null) ...[
              const SizedBox(height: 10),
              _VaultStatePanel(
                message: _message!,
                isError: _isMessageError,
              ),
            ],
            const SizedBox(height: 12),
            itemsAsync.when(
              data: (items) {
                if (items.isEmpty) {
                  return const _VaultStatePanel(
                    message:
                        "No recovery items yet. Add at least one encrypted recovery item so this workspace can support real self-recovery or beneficiary handoff.",
                    highlighted: true,
                  );
                }
                return Column(
                  children: items.map((item) {
                    final deleting = _deletingId == item.id;
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
                            onPressed: deleting ? null : () => _handleDelete(item.id),
                            icon: deleting
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Icon(Icons.delete_outline),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                );
              },
              loading: () => const _VaultStatePanel(
                message: "Loading recovery vault items...",
                showSpinner: true,
              ),
              error: (error, __) => _VaultStatePanel(
                message: _friendlyLoadError(error),
                isError: true,
                actionLabel: "Retry",
                onAction: () => ref.invalidate(vaultItemsProvider),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VaultStatePanel extends StatelessWidget {
  const _VaultStatePanel({
    required this.message,
    this.isError = false,
    this.highlighted = false,
    this.showSpinner = false,
    this.actionLabel,
    this.onAction,
  });

  final String message;
  final bool isError;
  final bool highlighted;
  final bool showSpinner;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final color = isError
        ? const Color(0xFFFFF1F1)
        : highlighted
            ? const Color(0xFFFFF7ED)
            : const Color(0xFFF7F1E8);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (showSpinner)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                Icon(
                  isError ? Icons.warning_amber_rounded : Icons.info_outline,
                  size: 20,
                ),
              const SizedBox(width: 8),
              Expanded(child: Text(message)),
            ],
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 8),
            OutlinedButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ],
      ),
    );
  }
}
