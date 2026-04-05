import 'package:digital_legacy_weaver/core/providers/supabase_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final betaFeedbackRepositoryProvider = Provider<BetaFeedbackRepository>((ref) {
  return BetaFeedbackRepository(ref.watch(supabaseClientProvider));
});

class BetaFeedbackRepository {
  BetaFeedbackRepository(this._client);

  final SupabaseClient _client;

  Future<void> submit({
    required String category,
    required String severity,
    required String summary,
    required String details,
    required String appVersion,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw const AuthException("No authenticated user.");
    }

    await _client.from("beta_feedback_reports").insert({
      "owner_id": user.id,
      "category": category,
      "severity": severity,
      "summary": summary.trim(),
      "details": details.trim().isEmpty ? null : details.trim(),
      "app_version": appVersion.trim().isEmpty ? null : appVersion.trim(),
    });
  }
}
