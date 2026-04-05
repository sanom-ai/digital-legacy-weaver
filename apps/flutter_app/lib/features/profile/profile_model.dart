class ProfileModel {
  const ProfileModel({
    required this.id,
    required this.backupEmail,
    required this.beneficiaryEmail,
    required this.beneficiaryName,
    required this.beneficiaryPhone,
    required this.beneficiaryVerificationHint,
    required this.beneficiaryVerificationPhraseHash,
    required this.legacyInactivityDays,
    required this.selfRecoveryInactivityDays,
    required this.lastActiveAt,
  });

  final String id;
  final String backupEmail;
  final String? beneficiaryEmail;
  final String? beneficiaryName;
  final String? beneficiaryPhone;
  final String? beneficiaryVerificationHint;
  final String? beneficiaryVerificationPhraseHash;
  final int legacyInactivityDays;
  final int selfRecoveryInactivityDays;
  final DateTime lastActiveAt;

  bool get hasBeneficiaryIdentityKit =>
      (beneficiaryName?.trim().isNotEmpty ?? false) &&
      (beneficiaryVerificationHint?.trim().isNotEmpty ?? false) &&
      (beneficiaryVerificationPhraseHash?.trim().isNotEmpty ?? false);

  factory ProfileModel.fromMap(Map<String, dynamic> map) {
    return ProfileModel(
      id: map["id"] as String,
      backupEmail: map["backup_email"] as String,
      beneficiaryEmail: map["beneficiary_email"] as String?,
      beneficiaryName: map["beneficiary_name"] as String?,
      beneficiaryPhone: map["beneficiary_phone"] as String?,
      beneficiaryVerificationHint: map["beneficiary_verification_hint"] as String?,
      beneficiaryVerificationPhraseHash: map["beneficiary_verification_phrase_hash"] as String?,
      legacyInactivityDays: map["legacy_inactivity_days"] as int,
      selfRecoveryInactivityDays: map["self_recovery_inactivity_days"] as int,
      lastActiveAt: DateTime.parse(map["last_active_at"] as String),
    );
  }
}
