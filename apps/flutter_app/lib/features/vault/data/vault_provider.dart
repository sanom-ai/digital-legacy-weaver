import 'package:digital_legacy_weaver/core/providers/supabase_provider.dart';
import 'package:digital_legacy_weaver/features/vault/data/recovery_item_model.dart';
import 'package:digital_legacy_weaver/features/vault/data/vault_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final vaultRepositoryProvider = Provider<VaultRepository>((ref) {
  return VaultRepository(ref.watch(supabaseClientProvider));
});

final vaultItemsProvider = AsyncNotifierProvider<VaultItemsController, List<RecoveryItemModel>>(
  VaultItemsController.new,
);

class VaultItemsController extends AsyncNotifier<List<RecoveryItemModel>> {
  @override
  Future<List<RecoveryItemModel>> build() async {
    return ref.watch(vaultRepositoryProvider).listItems();
  }

  Future<void> addItem({
    required RecoveryKind kind,
    required String title,
    required String encryptedPayload,
    String? releaseNotes,
    required String postTriggerVisibility,
    required String valueDisclosureMode,
  }) async {
    final repo = ref.read(vaultRepositoryProvider);
    await repo.addItem(
      kind: kind,
      title: title,
      encryptedPayload: encryptedPayload,
      releaseNotes: releaseNotes,
      postTriggerVisibility: postTriggerVisibility,
      valueDisclosureMode: valueDisclosureMode,
    );
    state = AsyncData(await repo.listItems());
  }

  Future<void> deleteItem(String id) async {
    final repo = ref.read(vaultRepositoryProvider);
    await repo.deleteItem(id);
    state = AsyncData(await repo.listItems());
  }
}
