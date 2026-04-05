class SafetySettingsModel {
  const SafetySettingsModel({
    required this.remindersEnabled,
    required this.reminderOffsetsDays,
    required this.gracePeriodDays,
    required this.legalDisclaimerAccepted,
    required this.emergencyPauseUntil,
    required this.requireTotpUnlock,
    required this.privateFirstMode,
    required this.tracePrivacyProfile,
  });

  final bool remindersEnabled;
  final List<int> reminderOffsetsDays;
  final int gracePeriodDays;
  final bool legalDisclaimerAccepted;
  final DateTime? emergencyPauseUntil;
  final bool requireTotpUnlock;
  final bool privateFirstMode;
  final String tracePrivacyProfile;

  factory SafetySettingsModel.fromMap(Map<String, dynamic> map) {
    return SafetySettingsModel(
      remindersEnabled: map["reminders_enabled"] as bool? ?? true,
      reminderOffsetsDays: (map["reminder_offsets_days"] as List<dynamic>? ?? [14, 7, 1]).map((e) => e as int).toList(),
      gracePeriodDays: map["grace_period_days"] as int? ?? 3,
      legalDisclaimerAccepted: map["legal_disclaimer_accepted"] as bool? ?? false,
      emergencyPauseUntil: map["emergency_pause_until"] != null ? DateTime.parse(map["emergency_pause_until"] as String) : null,
      requireTotpUnlock: map["require_totp_unlock"] as bool? ?? false,
      privateFirstMode: map["private_first_mode"] as bool? ?? true,
      tracePrivacyProfile: map["trace_privacy_profile"] as String? ?? "minimal",
    );
  }
}
