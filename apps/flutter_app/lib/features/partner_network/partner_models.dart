class FeeTier {
  const FeeTier({
    required this.minInclusive,
    this.maxInclusive,
    required this.percent,
  });

  final double minInclusive;
  final double? maxInclusive;
  final double percent;

  factory FeeTier.fromMap(Map<String, dynamic> map) {
    return FeeTier(
      minInclusive: (map['min_inclusive'] as num?)?.toDouble() ?? 0,
      maxInclusive: (map['max_inclusive'] as num?)?.toDouble(),
      percent: (map['percent'] as num?)?.toDouble() ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'min_inclusive': minInclusive,
      'max_inclusive': maxInclusive,
      'percent': percent,
    };
  }

  String rangeLabel() {
    final min = _formatAmount(minInclusive);
    if (maxInclusive == null) {
      return ">$min";
    }
    final max = _formatAmount(maxInclusive!);
    return "$min - $max";
  }

  bool matches(double amount) {
    if (amount < minInclusive) return false;
    if (maxInclusive == null) return true;
    return amount <= maxInclusive!;
  }

  static String _formatAmount(double value) {
    final amount = value.round();
    final raw = amount.toString();
    final buffer = StringBuffer();
    for (var i = 0; i < raw.length; i++) {
      final idx = raw.length - i;
      buffer.write(raw[i]);
      if (idx > 1 && idx % 3 == 1) {
        buffer.write(",");
      }
    }
    return buffer.toString();
  }
}

class LegalPartnerProfile {
  const LegalPartnerProfile({
    required this.id,
    required this.officeName,
    required this.province,
    required this.specialties,
    required this.slaHours,
    required this.rating,
    required this.isVerified,
    required this.officeFeeTiers,
    required this.lawyerFeeTiers,
    required this.otherFeeNote,
    required this.platformFeePercent,
    this.feeFloor,
    this.feeCap,
  });

  final String id;
  final String officeName;
  final String province;
  final List<String> specialties;
  final int slaHours;
  final double rating;
  final bool isVerified;
  final List<FeeTier> officeFeeTiers;
  final List<FeeTier> lawyerFeeTiers;
  final String otherFeeNote;
  final double platformFeePercent;
  final double? feeFloor;
  final double? feeCap;

  factory LegalPartnerProfile.fromMap(Map<String, dynamic> map) {
    final officeFeeRaw = map['office_fee_tiers'] as List? ?? const [];
    final lawyerFeeRaw = map['lawyer_fee_tiers'] as List? ?? const [];
    return LegalPartnerProfile(
      id: map['id'] as String? ?? '',
      officeName: map['office_name'] as String? ?? '',
      province: map['province'] as String? ?? '',
      specialties: (map['specialties'] as List? ?? const [])
          .map((item) => item.toString())
          .toList(),
      slaHours: (map['sla_hours'] as num?)?.toInt() ?? 48,
      rating: (map['rating'] as num?)?.toDouble() ?? 0,
      isVerified: map['is_verified'] as bool? ?? false,
      officeFeeTiers: officeFeeRaw
          .whereType<Map>()
          .map((item) => FeeTier.fromMap(Map<String, dynamic>.from(item)))
          .toList(),
      lawyerFeeTiers: lawyerFeeRaw
          .whereType<Map>()
          .map((item) => FeeTier.fromMap(Map<String, dynamic>.from(item)))
          .toList(),
      otherFeeNote: map['other_fee_note'] as String? ?? '',
      platformFeePercent:
          (map['platform_fee_percent'] as num?)?.toDouble() ?? 0,
      feeFloor: (map['fee_floor'] as num?)?.toDouble(),
      feeCap: (map['fee_cap'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'office_name': officeName,
      'province': province,
      'specialties': specialties,
      'sla_hours': slaHours,
      'rating': rating,
      'is_verified': isVerified,
      'office_fee_tiers': officeFeeTiers.map((tier) => tier.toMap()).toList(),
      'lawyer_fee_tiers': lawyerFeeTiers.map((tier) => tier.toMap()).toList(),
      'other_fee_note': otherFeeNote,
      'platform_fee_percent': platformFeePercent,
      'fee_floor': feeFloor,
      'fee_cap': feeCap,
    };
  }

  FeeBreakdown estimate(double assetValue) {
    final officePercent = _percentFor(assetValue, officeFeeTiers);
    final lawyerPercent = _percentFor(assetValue, lawyerFeeTiers);
    final officeFee = assetValue * officePercent / 100;
    final lawyerFee = assetValue * lawyerPercent / 100;
    final platformFee = assetValue * platformFeePercent / 100;
    var total = officeFee + lawyerFee + platformFee;
    if (feeFloor != null && total < feeFloor!) {
      total = feeFloor!;
    }
    if (feeCap != null && total > feeCap!) {
      total = feeCap!;
    }
    return FeeBreakdown(
      officePercent: officePercent,
      lawyerPercent: lawyerPercent,
      platformPercent: platformFeePercent,
      officeFee: officeFee,
      lawyerFee: lawyerFee,
      platformFee: platformFee,
      totalFee: total,
    );
  }

  static double _percentFor(double amount, List<FeeTier> tiers) {
    for (final tier in tiers) {
      if (tier.matches(amount)) {
        return tier.percent;
      }
    }
    return tiers.isEmpty ? 0 : tiers.last.percent;
  }
}

class FeeBreakdown {
  const FeeBreakdown({
    required this.officePercent,
    required this.lawyerPercent,
    required this.platformPercent,
    required this.officeFee,
    required this.lawyerFee,
    required this.platformFee,
    required this.totalFee,
  });

  final double officePercent;
  final double lawyerPercent;
  final double platformPercent;
  final double officeFee;
  final double lawyerFee;
  final double platformFee;
  final double totalFee;
}

class EcosystemDestination {
  const EcosystemDestination({
    required this.id,
    required this.name,
    required this.category,
    required this.status,
    required this.note,
  });

  final String id;
  final String name;
  final String category;
  final String status;
  final String note;

  bool get isVerified => status.toLowerCase() == 'verified';

  factory EcosystemDestination.fromMap(Map<String, dynamic> map) {
    return EcosystemDestination(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      category: map['category'] as String? ?? 'Other',
      status: map['status'] as String? ?? 'unverified',
      note: map['note'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'status': status,
      'note': note,
    };
  }
}
