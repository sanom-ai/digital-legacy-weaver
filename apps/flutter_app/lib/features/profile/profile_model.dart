class ProfileModel {
  const ProfileModel({
    required this.id,
    required this.backupEmail,
    required this.beneficiaryEmail,
    required this.legacyInactivityDays,
    required this.selfRecoveryInactivityDays,
    required this.lastActiveAt,
  });

  final String id;
  final String backupEmail;
  final String? beneficiaryEmail;
  final int legacyInactivityDays;
  final int selfRecoveryInactivityDays;
  final DateTime lastActiveAt;

  factory ProfileModel.fromMap(Map<String, dynamic> map) {
    return ProfileModel(
      id: map["id"] as String,
      backupEmail: map["backup_email"] as String,
      beneficiaryEmail: map["beneficiary_email"] as String?,
      legacyInactivityDays: map["legacy_inactivity_days"] as int,
      selfRecoveryInactivityDays: map["self_recovery_inactivity_days"] as int,
      lastActiveAt: DateTime.parse(map["last_active_at"] as String),
    );
  }
}
