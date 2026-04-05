import 'package:digital_legacy_weaver/features/vault/data/recovery_item_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class VaultRepository {
  VaultRepository(this._client);

  final SupabaseClient _client;

  Future<List<RecoveryItemModel>> listItems() async {
    final user = _client.auth.currentUser;
    if (user == null) return [];
    final rows = await _client
        .from("recovery_items")
        .select()
        .eq("owner_id", user.id)
        .eq("is_active", true)
        .order("created_at", ascending: false);
    return rows.map((row) => RecoveryItemModel.fromMap(row)).toList();
  }

  Future<void> addItem({
    required RecoveryKind kind,
    required String title,
    required String encryptedPayload,
    String? releaseNotes,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw const AuthException("No authenticated user.");
    }
    await _client.from("recovery_items").insert({
      "owner_id": user.id,
      "kind": kind.dbValue,
      "title": title,
      "encrypted_payload": encryptedPayload,
      "release_notes": releaseNotes,
      "is_active": true,
    });
  }

  Future<void> deleteItem(String id) async {
    await _client.from("recovery_items").update({"is_active": false}).eq("id", id);
  }
}
