import 'package:digital_legacy_weaver/features/connectors/data/connector_models.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ConnectorsRepository {
  ConnectorsRepository(this._client);

  final SupabaseClient _client;

  Future<List<PartnerConnectorModel>> listConnectors() async {
    final user = _client.auth.currentUser;
    if (user == null) return [];
    final rows = await _client.from("partner_connectors").select().eq("owner_id", user.id).order("created_at");
    return rows.map((r) => PartnerConnectorModel.fromMap(r)).toList();
  }

  Future<List<LegacyAssetRefModel>> listAssetRefs() async {
    final user = _client.auth.currentUser;
    if (user == null) return [];
    final rows = await _client.from("legacy_asset_refs").select().eq("owner_id", user.id).order("created_at");
    return rows.map((r) => LegacyAssetRefModel.fromMap(r)).toList();
  }

  Future<void> addConnector({
    required String connectorId,
    required String name,
    required List<String> supportedAssetTypes,
    required bool supportsWebhooks,
    required List<String> supportedSecondFactors,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw const AuthException("No authenticated user.");
    }
    await _client.from("partner_connectors").upsert({
      "owner_id": user.id,
      "connector_id": connectorId,
      "name": name,
      "supported_asset_types": supportedAssetTypes,
      "supports_webhooks": supportsWebhooks,
      "supported_second_factors": supportedSecondFactors,
      "status": "active",
    });
  }

  Future<void> addAssetRef({
    required String connectorRefId,
    required String assetId,
    required String assetType,
    required String displayName,
    required String encryptedPayloadRef,
    String? integrityHash,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw const AuthException("No authenticated user.");
    }
    await _client.from("legacy_asset_refs").upsert({
      "owner_id": user.id,
      "connector_ref_id": connectorRefId,
      "asset_id": assetId,
      "asset_type": assetType,
      "display_name": displayName,
      "encrypted_payload_ref": encryptedPayloadRef,
      "integrity_hash": integrityHash,
    });
  }
}
