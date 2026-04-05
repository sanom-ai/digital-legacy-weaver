import 'package:digital_legacy_weaver/core/providers/supabase_provider.dart';
import 'package:digital_legacy_weaver/features/connectors/data/connector_models.dart';
import 'package:digital_legacy_weaver/features/connectors/data/connectors_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final connectorsRepositoryProvider = Provider<ConnectorsRepository>((ref) {
  return ConnectorsRepository(ref.watch(supabaseClientProvider));
});

final connectorsProvider = AsyncNotifierProvider<ConnectorsController, List<PartnerConnectorModel>>(
  ConnectorsController.new,
);

final connectorAssetRefsProvider = AsyncNotifierProvider<ConnectorAssetRefsController, List<LegacyAssetRefModel>>(
  ConnectorAssetRefsController.new,
);

class ConnectorsController extends AsyncNotifier<List<PartnerConnectorModel>> {
  @override
  Future<List<PartnerConnectorModel>> build() async {
    return ref.read(connectorsRepositoryProvider).listConnectors();
  }

  Future<void> addConnector({
    required String connectorId,
    required String name,
    required List<String> supportedAssetTypes,
    required bool supportsWebhooks,
    required List<String> supportedSecondFactors,
  }) async {
    final repo = ref.read(connectorsRepositoryProvider);
    await repo.addConnector(
      connectorId: connectorId,
      name: name,
      supportedAssetTypes: supportedAssetTypes,
      supportsWebhooks: supportsWebhooks,
      supportedSecondFactors: supportedSecondFactors,
    );
    state = AsyncData(await repo.listConnectors());
    ref.invalidate(connectorAssetRefsProvider);
  }
}

class ConnectorAssetRefsController extends AsyncNotifier<List<LegacyAssetRefModel>> {
  @override
  Future<List<LegacyAssetRefModel>> build() async {
    return ref.read(connectorsRepositoryProvider).listAssetRefs();
  }

  Future<void> addAssetRef({
    required String connectorRefId,
    required String assetId,
    required String assetType,
    required String displayName,
    required String encryptedPayloadRef,
    String? integrityHash,
  }) async {
    final repo = ref.read(connectorsRepositoryProvider);
    await repo.addAssetRef(
      connectorRefId: connectorRefId,
      assetId: assetId,
      assetType: assetType,
      displayName: displayName,
      encryptedPayloadRef: encryptedPayloadRef,
      integrityHash: integrityHash,
    );
    state = AsyncData(await repo.listAssetRefs());
  }
}
