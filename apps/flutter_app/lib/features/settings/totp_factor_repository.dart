import 'package:supabase_flutter/supabase_flutter.dart';

class TotpFactorStatus {
  const TotpFactorStatus({
    required this.configured,
    required this.enabled,
    required this.requireTotpUnlock,
  });

  final bool configured;
  final bool enabled;
  final bool requireTotpUnlock;

  factory TotpFactorStatus.fromMap(Map<String, dynamic> map) {
    return TotpFactorStatus(
      configured: map["configured"] as bool? ?? false,
      enabled: map["enabled"] as bool? ?? false,
      requireTotpUnlock: map["require_totp_unlock"] as bool? ?? false,
    );
  }
}

class TotpSetupBundle {
  const TotpSetupBundle({
    required this.secretBase32,
    required this.otpauthUri,
  });

  final String secretBase32;
  final String otpauthUri;

  factory TotpSetupBundle.fromMap(Map<String, dynamic> map) {
    return TotpSetupBundle(
      secretBase32: (map["secret_base32"] ?? "").toString(),
      otpauthUri: (map["otpauth_uri"] ?? "").toString(),
    );
  }
}

class TotpFactorRepository {
  TotpFactorRepository(this._client);

  final SupabaseClient _client;

  Future<TotpFactorStatus> getStatus() async {
    final response = await _client.functions.invoke(
      "manage-totp-factor",
      body: {"action": "status"},
    );
    final data = Map<String, dynamic>.from(response.data as Map);
    return TotpFactorStatus.fromMap(data);
  }

  Future<TotpSetupBundle> beginSetup() async {
    final response = await _client.functions.invoke(
      "manage-totp-factor",
      body: {"action": "begin_setup"},
    );
    final data = Map<String, dynamic>.from(response.data as Map);
    return TotpSetupBundle.fromMap(data);
  }

  Future<TotpFactorStatus> confirmSetup({
    required String totpCode,
    required bool requireTotpUnlock,
  }) async {
    final response = await _client.functions.invoke(
      "manage-totp-factor",
      body: {
        "action": "confirm_setup",
        "totp_code": totpCode,
        "require_totp_unlock": requireTotpUnlock,
      },
    );
    final data = Map<String, dynamic>.from(response.data as Map);
    return TotpFactorStatus.fromMap(data);
  }

  Future<TotpFactorStatus> disable() async {
    final response = await _client.functions.invoke(
      "manage-totp-factor",
      body: {"action": "disable"},
    );
    final data = Map<String, dynamic>.from(response.data as Map);
    return TotpFactorStatus.fromMap(data);
  }
}
