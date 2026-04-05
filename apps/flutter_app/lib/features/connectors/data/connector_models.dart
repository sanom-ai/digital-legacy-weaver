class PartnerConnectorModel {
  const PartnerConnectorModel({
    required this.id,
    required this.connectorId,
    required this.name,
    required this.supportedAssetTypes,
    required this.supportsWebhooks,
    required this.supportedSecondFactors,
    required this.status,
  });

  final String id;
  final String connectorId;
  final String name;
  final List<String> supportedAssetTypes;
  final bool supportsWebhooks;
  final List<String> supportedSecondFactors;
  final String status;

  factory PartnerConnectorModel.fromMap(Map<String, dynamic> map) {
    return PartnerConnectorModel(
      id: map["id"] as String,
      connectorId: map["connector_id"] as String,
      name: map["name"] as String,
      supportedAssetTypes: (map["supported_asset_types"] as List<dynamic>? ?? const []).map((e) => e.toString()).toList(),
      supportsWebhooks: map["supports_webhooks"] as bool? ?? false,
      supportedSecondFactors:
          (map["supported_second_factors"] as List<dynamic>? ?? const []).map((e) => e.toString()).toList(),
      status: map["status"] as String? ?? "active",
    );
  }
}

class LegacyAssetRefModel {
  const LegacyAssetRefModel({
    required this.id,
    required this.connectorRefId,
    required this.assetId,
    required this.assetType,
    required this.displayName,
    required this.encryptedPayloadRef,
    required this.integrityHash,
  });

  final String id;
  final String connectorRefId;
  final String assetId;
  final String assetType;
  final String displayName;
  final String encryptedPayloadRef;
  final String? integrityHash;

  factory LegacyAssetRefModel.fromMap(Map<String, dynamic> map) {
    return LegacyAssetRefModel(
      id: map["id"] as String,
      connectorRefId: map["connector_ref_id"] as String,
      assetId: map["asset_id"] as String,
      assetType: map["asset_type"] as String,
      displayName: map["display_name"] as String,
      encryptedPayloadRef: map["encrypted_payload_ref"] as String,
      integrityHash: map["integrity_hash"] as String?,
    );
  }
}
