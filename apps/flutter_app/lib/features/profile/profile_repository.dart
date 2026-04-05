import 'package:digital_legacy_weaver/features/profile/profile_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileRepository {
  ProfileRepository(this._client);

  final SupabaseClient _client;

  Future<ProfileModel> getOrCreateProfile() async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw const AuthException("No authenticated user.");
    }
    if (user.email == null) {
      throw const AuthException("Authenticated account has no email.");
    }

    final existing = await _client.from("profiles").select().eq("id", user.id).maybeSingle();
    if (existing != null) {
      return ProfileModel.fromMap(existing);
    }

    final inserted = await _client
        .from("profiles")
        .insert({
          "id": user.id,
          "backup_email": user.email!,
          "beneficiary_email": null,
        })
        .select()
        .single();
    return ProfileModel.fromMap(inserted);
  }

  Future<void> markAlive() async {
    final user = _client.auth.currentUser;
    if (user == null) return;
    final nowIso = DateTime.now().toUtc().toIso8601String();
    await _client.from("profiles").update({"last_active_at": nowIso}).eq("id", user.id);
    await _client.from("owner_life_signals").insert({
      "owner_id": user.id,
      "signal_type": "alive_button",
      "occurred_at": nowIso,
      "details": {"source": "dashboard_alive_check"},
    });
  }

  Future<void> updateProfile({
    required String backupEmail,
    required String beneficiaryEmail,
    required int legacyInactivityDays,
    required int selfRecoveryInactivityDays,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) return;
    await _client.from("profiles").update({
      "backup_email": backupEmail.trim(),
      "beneficiary_email": beneficiaryEmail.trim(),
      "legacy_inactivity_days": legacyInactivityDays,
      "self_recovery_inactivity_days": selfRecoveryInactivityDays,
      "updated_at": DateTime.now().toUtc().toIso8601String(),
    }).eq("id", user.id);
  }
}
