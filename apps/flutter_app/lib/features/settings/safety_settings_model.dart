class SafetySettingsModel {
  const SafetySettingsModel({
    required this.remindersEnabled,
    required this.reminderOffsetsDays,
    required this.gracePeriodDays,
    required this.proofOfLifeCheckMode,
    required this.proofOfLifeFallbackChannels,
    required this.serverHeartbeatFallbackEnabled,
    required this.iosBackgroundRiskAcknowledged,
    required this.legalDisclaimerAccepted,
    required this.emergencyPauseUntil,
    required this.requireTotpUnlock,
    this.guardianQuorumEnabled = false,
    this.guardianQuorumRequired = 2,
    this.guardianQuorumPoolSize = 3,
    this.emergencyAccessEnabled = false,
    this.emergencyAccessRequiresBeneficiaryRequest = true,
    this.emergencyAccessRequiresGuardianQuorum = true,
    this.emergencyAccessGraceHours = 48,
    required this.privateFirstMode,
    required this.tracePrivacyProfile,
  });

  final bool remindersEnabled;
  final List<int> reminderOffsetsDays;
  final int gracePeriodDays;
  final String proofOfLifeCheckMode;
  final List<String> proofOfLifeFallbackChannels;
  final bool serverHeartbeatFallbackEnabled;
  final bool iosBackgroundRiskAcknowledged;
  final bool legalDisclaimerAccepted;
  final DateTime? emergencyPauseUntil;
  final bool requireTotpUnlock;
  final bool guardianQuorumEnabled;
  final int guardianQuorumRequired;
  final int guardianQuorumPoolSize;
  final bool emergencyAccessEnabled;
  final bool emergencyAccessRequiresBeneficiaryRequest;
  final bool emergencyAccessRequiresGuardianQuorum;
  final int emergencyAccessGraceHours;
  final bool privateFirstMode;
  final String tracePrivacyProfile;

  factory SafetySettingsModel.fromMap(Map<String, dynamic> map) {
    return SafetySettingsModel(
      remindersEnabled: map["reminders_enabled"] as bool? ?? true,
      reminderOffsetsDays: (map["reminder_offsets_days"] as List<dynamic>? ?? [14, 7, 1]).map((e) => e as int).toList(),
      gracePeriodDays: map["grace_period_days"] as int? ?? 7,
      proofOfLifeCheckMode: map["proof_of_life_check_mode"] as String? ?? "biometric_tap",
      proofOfLifeFallbackChannels:
          (map["proof_of_life_fallback_channels"] as List<dynamic>? ?? ["email", "sms"])
              .map((e) => e as String)
              .toList(),
      serverHeartbeatFallbackEnabled: map["server_heartbeat_fallback_enabled"] as bool? ?? true,
      iosBackgroundRiskAcknowledged: map["ios_background_risk_acknowledged"] as bool? ?? false,
      legalDisclaimerAccepted: map["legal_disclaimer_accepted"] as bool? ?? false,
      emergencyPauseUntil: map["emergency_pause_until"] != null ? DateTime.parse(map["emergency_pause_until"] as String) : null,
      requireTotpUnlock: map["require_totp_unlock"] as bool? ?? false,
      guardianQuorumEnabled: map["guardian_quorum_enabled"] as bool? ?? false,
      guardianQuorumRequired: map["guardian_quorum_required"] as int? ?? 2,
      guardianQuorumPoolSize: map["guardian_quorum_pool_size"] as int? ?? 3,
      emergencyAccessEnabled: map["emergency_access_enabled"] as bool? ?? false,
      emergencyAccessRequiresBeneficiaryRequest:
          map["emergency_access_requires_beneficiary_request"] as bool? ?? true,
      emergencyAccessRequiresGuardianQuorum:
          map["emergency_access_requires_guardian_quorum"] as bool? ?? true,
      emergencyAccessGraceHours: map["emergency_access_grace_hours"] as int? ?? 48,
      privateFirstMode: map["private_first_mode"] as bool? ?? true,
      tracePrivacyProfile: map["trace_privacy_profile"] as String? ?? "minimal",
    );
  }
}
