class FeeTier {
  const FeeTier({
    required this.minInclusive,
    this.maxInclusive,
    required this.percent,
  });

  final double minInclusive;
  final double? maxInclusive;
  final double percent;

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
}
