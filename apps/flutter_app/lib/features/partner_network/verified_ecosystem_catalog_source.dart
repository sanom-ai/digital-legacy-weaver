import 'dart:convert';

import 'package:digital_legacy_weaver/features/partner_network/partner_models.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class VerifiedEcosystemCatalogResult {
  const VerifiedEcosystemCatalogResult({
    required this.destinations,
    required this.source,
  });

  final List<EcosystemDestination> destinations;
  final String source;
}

class VerifiedEcosystemCatalogSource {
  static const String _assetPath =
      'assets/config/verified_ecosystem_destinations.json';
  static const String _tableName = 'verified_ecosystem_destinations';

  Future<VerifiedEcosystemCatalogResult> loadVerifiedDestinations() async {
    try {
      final apiDestinations = await _loadFromApi();
      if (apiDestinations.isNotEmpty) {
        return VerifiedEcosystemCatalogResult(
          destinations: apiDestinations,
          source: 'admin_api',
        );
      }
    } catch (_) {
      // Fall through to local admin config when API is unavailable.
    }
    final configDestinations = await _loadFromAssetConfig();
    return VerifiedEcosystemCatalogResult(
      destinations: configDestinations,
      source: 'admin_config',
    );
  }

  Future<List<EcosystemDestination>> _loadFromApi() async {
    final client = Supabase.instance.client;
    final response = await client
        .from(_tableName)
        .select()
        .eq('status', 'verified')
        .order('name');
    final rows = (response as List)
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
    return rows
        .map(EcosystemDestination.fromMap)
        .where((destination) => destination.isVerified)
        .toList();
  }

  Future<List<EcosystemDestination>> _loadFromAssetConfig() async {
    final raw = await rootBundle.loadString(_assetPath);
    final decoded = jsonDecode(raw);
    if (decoded is! List) {
      return const [];
    }
    return decoded
        .whereType<Map>()
        .map((item) =>
            EcosystemDestination.fromMap(Map<String, dynamic>.from(item)))
        .where((destination) => destination.isVerified)
        .toList();
  }
}
