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
    final existing = await _client
        .from("user_safety_settings")
        .select()
        .eq("owner_id", user.id)
        .maybeSingle();
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
          "proof_of_life_check_mode": "half_life_soft_checkin",
          "proof_of_life_fallback_channels": ["email", "sms"],
          "server_heartbeat_fallback_enabled": true,
          "ios_background_risk_acknowledged": false,
          "legal_disclaimer_accepted": false,
          "require_totp_unlock": false,
          "guardian_quorum_enabled": false,
          "guardian_quorum_required": 2,
          "guardian_quorum_pool_size": 3,
          "emergency_access_enabled": false,
          "emergency_access_requires_beneficiary_request": true,
          "emergency_access_requires_guardian_quorum": true,
          "emergency_access_grace_hours": 48,
          "device_rebind_in_progress": false,
          "device_rebind_started_at": null,
          "device_rebind_grace_hours": 72,
          "recovery_key_enabled": true,
          "delivery_access_ttl_hours": 72,
          "payload_retention_days": 30,
          "audit_log_retention_days": 30,
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
    required bool guardianQuorumEnabled,
    required int guardianQuorumRequired,
    required int guardianQuorumPoolSize,
    required bool emergencyAccessEnabled,
    required bool emergencyAccessRequiresBeneficiaryRequest,
    required bool emergencyAccessRequiresGuardianQuorum,
    required int emergencyAccessGraceHours,
    required bool deviceRebindInProgress,
    required DateTime? deviceRebindStartedAt,
    required int deviceRebindGraceHours,
    required bool recoveryKeyEnabled,
    required int deliveryAccessTtlHours,
    required int payloadRetentionDays,
    required int auditLogRetentionDays,
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
      "legal_disclaimer_accepted_at": legalDisclaimerAccepted
          ? DateTime.now().toUtc().toIso8601String()
          : null,
      "emergency_pause_until": emergencyPauseUntil?.toUtc().toIso8601String(),
      "require_totp_unlock": requireTotpUnlock,
      "guardian_quorum_enabled": guardianQuorumEnabled,
      "guardian_quorum_required": guardianQuorumRequired,
      "guardian_quorum_pool_size": guardianQuorumPoolSize,
      "emergency_access_enabled": emergencyAccessEnabled,
      "emergency_access_requires_beneficiary_request":
          emergencyAccessRequiresBeneficiaryRequest,
      "emergency_access_requires_guardian_quorum":
          emergencyAccessRequiresGuardianQuorum,
      "emergency_access_grace_hours": emergencyAccessGraceHours,
      "device_rebind_in_progress": deviceRebindInProgress,
      "device_rebind_started_at":
          deviceRebindStartedAt?.toUtc().toIso8601String(),
      "device_rebind_grace_hours": deviceRebindGraceHours,
      "recovery_key_enabled": recoveryKeyEnabled,
      "delivery_access_ttl_hours": deliveryAccessTtlHours,
      "payload_retention_days": payloadRetentionDays,
      "audit_log_retention_days": auditLogRetentionDays,
      "private_first_mode": privateFirstMode,
      "trace_privacy_profile": tracePrivacyProfile,
    }).eq("owner_id", user.id);
  }
}
