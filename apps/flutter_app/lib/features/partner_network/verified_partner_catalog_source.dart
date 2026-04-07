import 'dart:convert';

import 'package:digital_legacy_weaver/features/partner_network/partner_models.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class VerifiedPartnerCatalogResult {
  const VerifiedPartnerCatalogResult({
    required this.partners,
    required this.source,
  });

  final List<LegalPartnerProfile> partners;
  final String source;
}

class VerifiedPartnerCatalogSource {
  static const String _assetPath =
      'assets/config/verified_legal_partners.json';
  static const String _tableName = 'verified_partner_catalog';

  Future<VerifiedPartnerCatalogResult> loadVerifiedPartners() async {
    try {
      final apiPartners = await _loadFromApi();
      if (apiPartners.isNotEmpty) {
        return VerifiedPartnerCatalogResult(
          partners: apiPartners,
          source: 'admin_api',
        );
      }
    } catch (_) {
      // Fall through to local admin config when API is unavailable.
    }
    final configPartners = await _loadFromAssetConfig();
    return VerifiedPartnerCatalogResult(
      partners: configPartners,
      source: 'admin_config',
    );
  }

  Future<List<LegalPartnerProfile>> _loadFromApi() async {
    final client = Supabase.instance.client;
    final response = await client
        .from(_tableName)
        .select()
        .eq('is_verified', true)
        .order('rating', ascending: false);
    final rows = (response as List)
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
    return rows
        .map(LegalPartnerProfile.fromMap)
        .where((partner) => partner.isVerified)
        .toList();
  }

  Future<List<LegalPartnerProfile>> _loadFromAssetConfig() async {
    final raw = await rootBundle.loadString(_assetPath);
    final decoded = jsonDecode(raw);
    if (decoded is! List) {
      return const [];
    }
    return decoded
        .whereType<Map>()
        .map((item) => LegalPartnerProfile.fromMap(Map<String, dynamic>.from(item)))
        .where((partner) => partner.isVerified)
        .toList();
  }
}
