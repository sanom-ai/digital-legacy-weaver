import 'package:digital_legacy_weaver/features/settings/safety_settings_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SafetySettingsRepository {
  SafetySettingsRepository(this._client);

  final SupabaseClient _client;

  Future<SafetySettingsModel> getOrCreate() async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw const AuthException("No authenticated user.");
    }
    final existing = await _client.from("user_safety_settings").select().eq("owner_id", user.id).maybeSingle();
    if (existing != null) {
      return SafetySettingsModel.fromMap(existing);
    }
    final inserted = await _client
        .from("user_safety_settings")
        .insert({
          "owner_id": user.id,
          "reminders_enabled": true,
          "reminder_offsets_days": [14, 7, 1],
          "grace_period_days": 7,
          "proof_of_life_check_mode": "biometric_tap",
          "proof_of_life_fallback_channels": ["email", "sms"],
          "server_heartbeat_fallback_enabled": true,
          "ios_background_risk_acknowledged": false,
          "legal_disclaimer_accepted": false,
          "require_totp_unlock": false,
          "private_first_mode": true,
          "trace_privacy_profile": "minimal",
        })
        .select()
        .single();
    return SafetySettingsModel.fromMap(inserted);
  }

  Future<void> update({
    required bool remindersEnabled,
    required List<int> reminderOffsetsDays,
    required int gracePeriodDays,
    required String proofOfLifeCheckMode,
    required List<String> proofOfLifeFallbackChannels,
    required bool serverHeartbeatFallbackEnabled,
    required bool iosBackgroundRiskAcknowledged,
    required bool legalDisclaimerAccepted,
    required DateTime? emergencyPauseUntil,
    required bool requireTotpUnlock,
    required bool privateFirstMode,
    required String tracePrivacyProfile,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) return;
    await _client.from("user_safety_settings").update({
      "reminders_enabled": remindersEnabled,
      "reminder_offsets_days": reminderOffsetsDays,
      "grace_period_days": gracePeriodDays,
      "proof_of_life_check_mode": proofOfLifeCheckMode,
      "proof_of_life_fallback_channels": proofOfLifeFallbackChannels,
      "server_heartbeat_fallback_enabled": serverHeartbeatFallbackEnabled,
      "ios_background_risk_acknowledged": iosBackgroundRiskAcknowledged,
      "legal_disclaimer_accepted": legalDisclaimerAccepted,
      "legal_disclaimer_accepted_at": legalDisclaimerAccepted ? DateTime.now().toUtc().toIso8601String() : null,
      "emergency_pause_until": emergencyPauseUntil?.toUtc().toIso8601String(),
      "require_totp_unlock": requireTotpUnlock,
      "private_first_mode": privateFirstMode,
      "trace_privacy_profile": tracePrivacyProfile,
    }).eq("owner_id", user.id);
  }
}
