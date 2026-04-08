import 'package:digital_legacy_weaver/core/widgets/app_state_panel.dart';
import 'package:digital_legacy_weaver/features/runtime/runtime_status_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class RuntimeStatusScreen extends ConsumerStatefulWidget {
  const RuntimeStatusScreen({super.key});

  @override
  ConsumerState<RuntimeStatusScreen> createState() =>
      _RuntimeStatusScreenState();
}

class _RuntimeStatusScreenState extends ConsumerState<RuntimeStatusScreen> {
  bool _loading = true;
  String? _error;
  RuntimeStatusSnapshot? _snapshot;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final snapshot =
          await ref.read(runtimeStatusRepositoryProvider).load(windowHours: 24);
      if (!mounted) return;
      setState(() {
        _snapshot = snapshot;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = _friendlyError(error);
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _friendlyError(Object error) {
    final lower = error.toString().toLowerCase();
    if (lower.contains("socketexception") ||
        lower.contains("failed host lookup") ||
        lower.contains("network") ||
        lower.contains("timed out")) {
      return "ยังโหลดสถานะ runtime ไม่ได้ เพราะอินเทอร์เน็ตไม่เสถียร";
    }
    if (lower.contains("reviewer_api_key") ||
        lower.contains("reviewer authorization failed") ||
        lower.contains("unauthorized")) {
      return "ต้องตั้ง REVIEWER_API_KEY ก่อนเปิดหน้า runtime status";
    }
    return "ยังโหลดสถานะ runtime ไม่ได้ในขณะนี้ กรุณาลองใหม่อีกครั้ง";
  }

  String _healthLabel(String health) {
    switch (health.trim().toLowerCase()) {
      case "healthy":
        return "ปกติ";
      case "degraded":
        return "มีความเสี่ยง";
      default:
        return "ต้องตรวจสอบ";
    }
  }

  Color _healthColor(BuildContext context, String health) {
    final scheme = Theme.of(context).colorScheme;
    switch (health.trim().toLowerCase()) {
      case "healthy":
        return scheme.tertiary;
      case "degraded":
        return const Color(0xFFC47D22);
      default:
        return scheme.error;
    }
  }

  String _formatDateTime(DateTime? value) {
    if (value == null) return "ยังไม่มีข้อมูล";
    final local = value.toLocal();
    final minute = local.minute.toString().padLeft(2, "0");
    final second = local.second.toString().padLeft(2, "0");
    return "${local.year}-${local.month.toString().padLeft(2, "0")}-${local.day.toString().padLeft(2, "0")} ${local.hour.toString().padLeft(2, "0")}:$minute:$second";
  }

  @override
  Widget build(BuildContext context) {
    final snapshot = _snapshot;
    return Scaffold(
      appBar: AppBar(
        title: const Text("สถานะ Runtime"),
        actions: [
          IconButton(
            onPressed: _loading ? null : _reload,
            icon: const Icon(Icons.refresh_rounded),
            tooltip: "รีเฟรช",
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          if (_loading)
            const AppStatePanel(
              tone: AppStateTone.loading,
              message: "กำลังโหลดสถานะ dispatch runtime...",
            ),
          if (!_loading && _error != null)
            AppStatePanel(
              tone: appStateLooksOfflineMessage(_error!)
                  ? AppStateTone.offline
                  : AppStateTone.error,
              message: _error!,
              actionLabel: "ลองใหม่",
              onAction: _reload,
            ),
          if (!_loading && _error == null && snapshot != null) ...[
            _OverviewCard(
              healthLabel: _healthLabel(snapshot.dispatchHealth),
              healthColor: _healthColor(context, snapshot.dispatchHealth),
              heartbeatStatus: snapshot.heartbeatStatus,
              lastRunAt: _formatDateTime(snapshot.lastRunAt),
              failReason: snapshot.failReason,
            ),
            const SizedBox(height: 12),
            _StatsCard(snapshot: snapshot),
            const SizedBox(height: 12),
            _RecentEventsCard(
              events: snapshot.recentEvents,
              formatDateTime: _formatDateTime,
            ),
          ],
        ],
      ),
    );
  }
}

class _OverviewCard extends StatelessWidget {
  const _OverviewCard({
    required this.healthLabel,
    required this.healthColor,
    required this.heartbeatStatus,
    required this.lastRunAt,
    required this.failReason,
  });

  final String healthLabel;
  final Color healthColor;
  final String heartbeatStatus;
  final String lastRunAt;
  final String failReason;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.monitor_heart_outlined, color: healthColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "Dispatch health: $healthLabel",
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    color: healthColor.withValues(alpha: 0.18),
                  ),
                  child: Text(heartbeatStatus),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text("Last run: $lastRunAt"),
            const SizedBox(height: 6),
            Text(
              "Fail reason: ${failReason.trim().isEmpty ? "none" : failReason}",
              style: TextStyle(color: scheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatsCard extends StatelessWidget {
  const _StatsCard({required this.snapshot});

  final RuntimeStatusSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final byStatus = snapshot.byStatus;
    final byStage = snapshot.byStage;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "สถิติย้อนหลัง ${snapshot.windowHours} ชั่วโมง",
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _MetricChip(
                  label: "เหตุการณ์รวม",
                  value: snapshot.totalEvents.toString(),
                ),
                _MetricChip(
                  label: "sent",
                  value: (byStatus["sent"] ?? 0).toString(),
                ),
                _MetricChip(
                  label: "skipped",
                  value: (byStatus["skipped"] ?? 0).toString(),
                ),
                _MetricChip(
                  label: "error",
                  value: (byStatus["error"] ?? 0).toString(),
                ),
                _MetricChip(
                  label: "final_release",
                  value: (byStage["final_release"] ?? 0).toString(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: scheme.surfaceContainerHighest,
      ),
      child: Text("$label: $value"),
    );
  }
}

class _RecentEventsCard extends StatelessWidget {
  const _RecentEventsCard({
    required this.events,
    required this.formatDateTime,
  });

  final List<RuntimeStatusEvent> events;
  final String Function(DateTime?) formatDateTime;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "เหตุการณ์ล่าสุด",
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            if (events.isEmpty)
              const AppStatePanel(
                tone: AppStateTone.empty,
                message: "ยังไม่พบเหตุการณ์ในช่วงเวลาที่เลือก",
              )
            else
              ...events.map(
                (event) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.history_rounded),
                  title: Text(
                    "${event.mode} • ${event.stage} • ${event.status}",
                  ),
                  subtitle: Text(
                    "${formatDateTime(event.createdAt)}\n${event.reason.trim().isEmpty ? "no reason" : event.reason}",
                  ),
                  isThreeLine: true,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
