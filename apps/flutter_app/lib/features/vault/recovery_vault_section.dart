import 'package:digital_legacy_weaver/core/widgets/app_feedback.dart';
import 'package:digital_legacy_weaver/core/widgets/app_state_panel.dart';
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

  void _setMessage(String message, {bool isError = false}) {
    if (!mounted) return;
    if (isError) {
      AppFeedback.showError(context, message);
      return;
    }
    AppFeedback.showSuccess(context, message);
  }

  String _friendlyActionError(String action, Object error) {
    final lower = error.toString().toLowerCase();
    if (lower.contains("socketexception") ||
        lower.contains("failed host lookup") ||
        lower.contains("network") ||
        lower.contains("timed out")) {
      return "ยัง$actionไม่สำเร็จ เพราะอินเทอร์เน็ตไม่เสถียร กรุณาลองใหม่อีกครั้ง";
    }
    if (lower.contains("no authenticated user") ||
        lower.contains("unauthorized") ||
        lower.contains("forbidden")) {
      return "เซสชันหมดอายุ กรุณาเข้าสู่ระบบใหม่แล้วลอง$actionอีกครั้ง";
    }
    return "ยัง$actionไม่สำเร็จในขณะนี้ กรุณาลองใหม่อีกครั้ง";
  }

  String _friendlyLoadError(Object error) {
    final lower = error.toString().toLowerCase();
    if (lower.contains("socketexception") ||
        lower.contains("failed host lookup") ||
        lower.contains("network") ||
        lower.contains("timed out")) {
      return "ไม่สามารถโหลดรายการคลังได้ เพราะออฟไลน์อยู่ กรุณาเชื่อมต่ออินเทอร์เน็ตแล้วลองใหม่";
    }
    if (lower.contains("no authenticated user") ||
        lower.contains("unauthorized") ||
        lower.contains("forbidden")) {
      return "ไม่สามารถโหลดรายการคลังได้ เพราะเซสชันไม่ถูกต้อง กรุณาเข้าสู่ระบบใหม่";
    }
    return "ยังเปิดรายการคลังไม่ได้ในขณะนี้ กรุณาลองใหม่อีกครั้ง";
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
      _setMessage("บันทึกรายการกู้คืนสำเร็จ");
    } catch (error) {
      _setMessage(_friendlyActionError("บันทึกรายการกู้คืน", error),
          isError: true);
    } finally {
      if (mounted) {
        setState(() => _adding = false);
      }
    }
  }

  Future<void> _handleDelete(String id) async {
    if (_deletingId != null) return;
    final confirmed = await AppFeedback.confirmAction(
      context: context,
      title: "ยืนยันการลบรายการ",
      message: "รายการนี้จะถูกลบออกจากคลังกู้คืนทันที ต้องการลบต่อใช่ไหม",
      confirmLabel: "ลบรายการ",
      destructive: true,
    );
    if (!confirmed) return;
    setState(() => _deletingId = id);
    try {
      await ref.read(vaultItemsProvider.notifier).deleteItem(id);
      _setMessage("ลบรายการกู้คืนสำเร็จ");
    } catch (error) {
      _setMessage(_friendlyActionError("ลบรายการกู้คืน", error), isError: true);
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
                  'คลังกู้คืน',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                FilledButton.tonal(
                  onPressed: _adding ? null : _handleAdd,
                  child: Text(_adding ? "กำลังบันทึก..." : "เพิ่มรายการ"),
                ),
              ],
            ),
            const SizedBox(height: 12),
            itemsAsync.when(
              data: (items) {
                if (items.isEmpty) {
                  return const _VaultStatePanel(
                    message:
                        "ยังไม่มีรายการกู้คืน กรุณาเพิ่มอย่างน้อย 1 รายการ เพื่อให้พร้อมใช้งานจริง",
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
                        "${item.releaseNotes ?? "รายการเข้ารหัส"}\nการมองเห็น: ${item.postTriggerVisibility} | การเปิดเผยมูลค่า: ${item.valueDisclosureMode}",
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(999),
                              color: const Color(0xFFE5D7C5),
                            ),
                            child: Text(item.kind.label),
                          ),
                          IconButton(
                            onPressed:
                                deleting ? null : () => _handleDelete(item.id),
                            icon: deleting
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
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
                message: "กำลังโหลดรายการคลังกู้คืน...",
                showSpinner: true,
              ),
              error: (error, __) => _VaultStatePanel(
                message: _friendlyLoadError(error),
                isError: true,
                actionLabel: "ลองใหม่",
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
    return AppStatePanel(
      message: message,
      tone: showSpinner
          ? AppStateTone.loading
          : isError
              ? (appStateLooksOfflineMessage(message)
                  ? AppStateTone.offline
                  : AppStateTone.error)
              : highlighted
                  ? AppStateTone.empty
                  : AppStateTone.success,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }
}
