import 'dart:convert';

import 'package:digital_legacy_weaver/features/partner_network/partner_models.dart';
import 'package:flutter/services.dart';

class VerifiedPartnerCatalogSource {
  static const String _assetPath =
      'assets/config/verified_legal_partners.json';

  Future<List<LegalPartnerProfile>> loadVerifiedPartners() async {
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
