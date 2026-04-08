import 'package:digital_legacy_weaver/core/config/app_config.dart';
import 'package:digital_legacy_weaver/core/providers/supabase_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final runtimeStatusRepositoryProvider =
    Provider<RuntimeStatusRepository>((ref) {
  return RuntimeStatusRepository(ref.watch(supabaseClientProvider));
});

class RuntimeStatusSnapshot {
  const RuntimeStatusSnapshot({
    required this.dispatchHealth,
    required this.heartbeatStatus,
    required this.lastRunAt,
    required this.failReason,
    required this.windowHours,
    required this.totalEvents,
    required this.byStatus,
    required this.byStage,
    required this.recentEvents,
  });

  final String dispatchHealth;
  final String heartbeatStatus;
  final DateTime? lastRunAt;
  final String failReason;
  final int windowHours;
  final int totalEvents;
  final Map<String, int> byStatus;
  final Map<String, int> byStage;
  final List<RuntimeStatusEvent> recentEvents;

  factory RuntimeStatusSnapshot.fromMap(Map<String, dynamic> map) {
    final stats = Map<String, dynamic>.from(map["stats"] as Map? ?? const {});
    final byStatusRaw =
        Map<String, dynamic>.from(stats["by_status"] as Map? ?? const {});
    final byStageRaw =
        Map<String, dynamic>.from(stats["by_stage"] as Map? ?? const {});
    final recentRaw = (map["recent_events"] as List<dynamic>? ?? const []);
    return RuntimeStatusSnapshot(
      dispatchHealth: (map["dispatch_health"] ?? "down").toString(),
      heartbeatStatus: (map["heartbeat_status"] ?? "unknown").toString(),
      lastRunAt: DateTime.tryParse((map["last_run_at"] ?? "").toString()),
      failReason: (map["fail_reason"] ?? "No runtime heartbeat yet").toString(),
      windowHours: (stats["window_hours"] as num?)?.toInt() ?? 24,
      totalEvents: (stats["total_events"] as num?)?.toInt() ?? 0,
      byStatus: {
        for (final entry in byStatusRaw.entries)
          entry.key: (entry.value as num?)?.toInt() ?? 0,
      },
      byStage: {
        for (final entry in byStageRaw.entries)
          entry.key: (entry.value as num?)?.toInt() ?? 0,
      },
      recentEvents: recentRaw
          .map((row) =>
              RuntimeStatusEvent.fromMap(Map<String, dynamic>.from(row as Map)))
          .toList(),
    );
  }
}

class RuntimeStatusEvent {
  const RuntimeStatusEvent({
    required this.mode,
    required this.stage,
    required this.status,
    required this.reason,
    required this.createdAt,
  });

  final String mode;
  final String stage;
  final String status;
  final String reason;
  final DateTime? createdAt;

  factory RuntimeStatusEvent.fromMap(Map<String, dynamic> map) {
    return RuntimeStatusEvent(
      mode: (map["mode"] ?? "").toString(),
      stage: (map["stage"] ?? "").toString(),
      status: (map["status"] ?? "").toString(),
      reason: (map["reason"] ?? "").toString(),
      createdAt: DateTime.tryParse((map["created_at"] ?? "").toString()),
    );
  }
}

class RuntimeStatusRepository {
  RuntimeStatusRepository(this._client);

  final SupabaseClient _client;

  Future<RuntimeStatusSnapshot> load({int windowHours = 24}) async {
    if (!AppConfig.reviewerOpsEnabled) {
      throw const AuthException(
        "REVIEWER_API_KEY is required to open runtime status.",
      );
    }
    final response = await _client.functions.invoke(
      "runtime-status",
      body: {
        "window_hours": windowHours,
      },
      headers: {
        "x-reviewer-key": AppConfig.reviewerApiKey,
      },
    );

    final data = Map<String, dynamic>.from(response.data as Map);
    if (data["ok"] != true) {
      throw AuthException(
          (data["error"] ?? "runtime-status failed").toString());
    }
    return RuntimeStatusSnapshot.fromMap(data);
  }
}
