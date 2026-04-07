import 'package:digital_legacy_weaver/core/config/app_config.dart';
import 'package:digital_legacy_weaver/core/providers/supabase_provider.dart';
import 'package:digital_legacy_weaver/core/widgets/app_feedback.dart';
import 'package:digital_legacy_weaver/core/widgets/app_state_panel.dart';
import 'package:digital_legacy_weaver/features/legal/reviewer_ops_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final reviewerOpsRepositoryProvider = Provider<ReviewerOpsRepository>((ref) {
  return ReviewerOpsRepository(ref.watch(supabaseClientProvider));
});

class ReviewerOpsScreen extends ConsumerStatefulWidget {
  const ReviewerOpsScreen({super.key});

  @override
  ConsumerState<ReviewerOpsScreen> createState() => _ReviewerOpsScreenState();
}

class _ReviewerOpsScreenState extends ConsumerState<ReviewerOpsScreen> {
  final _reviewerRefController = TextEditingController(text: "reviewer-01");
  final _notesController = TextEditingController();
  String _status = "under_review";
  bool _busy = false;
  String? _message;
  bool _messageIsError = false;
  List<ReviewerQueueItem> _queue = const [];

  @override
  void initState() {
    super.initState();
    if (AppConfig.reviewerOpsEnabled) {
      _reload();
    }
  }

  @override
  void dispose() {
    _reviewerRefController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _reload() async {
    if (!AppConfig.reviewerOpsEnabled) return;
    setState(() {
      _busy = true;
    });
    try {
      final queue = await ref
          .read(reviewerOpsRepositoryProvider)
          .loadQueue(status: _status);
      if (!mounted) return;
      setState(() => _queue = queue);
    } catch (e) {
      if (!mounted) return;
      AppFeedback.showError(
          context, _friendlyError("load the review queue", e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _review(String evidenceId, String decision) async {
    final reviewerRef = _reviewerRefController.text.trim();
    if (reviewerRef.isEmpty) {
      setState(() {
        _message = "กรุณากรอกรหัสผู้ตรวจ";
        _messageIsError = true;
      });
      return;
    }
    final confirmed = await _confirmReviewDecision(decision);
    if (!confirmed) return;
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      final result =
          await ref.read(reviewerOpsRepositoryProvider).applyDecision(
                evidenceId: evidenceId,
                reviewerRef: reviewerRef,
                decision: decision,
                notes: _notesController.text.trim().isEmpty
                    ? null
                    : _notesController.text.trim(),
              );
      if (!mounted) return;
      setState(() {
        _message =
            "อัปเดตแล้ว ${result["evidence_id"]}: สถานะ=${result["review_status"]}, อนุมัติ=${result["approvals"]}";
        _messageIsError = false;
      });
      await _reload();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _message = _friendlyError("complete that review action", e);
        _messageIsError = true;
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<bool> _confirmReviewDecision(String decision) async {
    final normalized = decision.trim().toLowerCase();
    final isReject = normalized == "rejected";
    final isNeedsInfo = normalized == "needs_info";
    final title = isReject
        ? "ยืนยันการปฏิเสธคำขอ"
        : isNeedsInfo
            ? "ยืนยันว่าต้องขอข้อมูลเพิ่ม"
            : "ยืนยันการอนุมัติคำขอ";
    final message = isReject
        ? "ระบบจะอัปเดตสถานะเป็น Rejected ทันที ต้องการดำเนินการต่อใช่ไหม"
        : isNeedsInfo
            ? "ระบบจะอัปเดตสถานะเป็น Needs info เพื่อรอข้อมูลเพิ่ม ต้องการดำเนินการต่อใช่ไหม"
            : "ระบบจะอัปเดตสถานะเป็น Approved ต้องการดำเนินการต่อใช่ไหม";
    final confirmLabel = isReject
        ? "ยืนยันปฏิเสธ"
        : isNeedsInfo
            ? "ยืนยันขอข้อมูลเพิ่ม"
            : "ยืนยันอนุมัติ";
    return AppFeedback.confirmAction(
      context: context,
      title: title,
      message: message,
      confirmLabel: confirmLabel,
      destructive: isReject,
      icon: isReject ? Icons.block_rounded : Icons.verified_user_rounded,
    );
  }

  Future<void> _openTimeline(String evidenceId) async {
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      final summary =
          await ref.read(reviewerOpsRepositoryProvider).loadSummary(evidenceId);
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Review Timeline"),
          content: SizedBox(
            width: 520,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("evidence: ${summary.evidenceId}"),
                  Text("owner: ${summary.ownerId}"),
                  Text("document: ${summary.documentType}"),
                  Text("status: ${summary.reviewStatus}"),
                  const SizedBox(height: 12),
                  const Text(
                    "Decisions",
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  if (summary.reviews.isEmpty) const Text("No decisions yet."),
                  ...summary.reviews.map(
                    (entry) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        "${entry.reviewedAt.toIso8601String()} | ${entry.reviewerRef} | ${entry.decision}${entry.notes == null ? "" : " | ${entry.notes}"}",
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Close"),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _message = _friendlyError("load the review timeline", e);
        _messageIsError = true;
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _friendlyError(String action, Object error) {
    final lower = error.toString().toLowerCase();
    if (lower.contains("socketexception") ||
        lower.contains("failed host lookup") ||
        lower.contains("network") ||
        lower.contains("timed out")) {
      return "ยังไม่สามารถ$actionได้ เพราะอินเทอร์เน็ตไม่เสถียร กรุณาลองใหม่อีกครั้ง";
    }
    if (lower.contains("x-reviewer-key") ||
        lower.contains("forbidden") ||
        lower.contains("unauthorized")) {
      return "รีวิวคีย์ไม่ถูกต้องหรือยังไม่ได้ตั้งค่า กรุณาตรวจสอบ REVIEWER_API_KEY แล้วลองใหม่";
    }
    return "ยังไม่สามารถ$actionได้ในขณะนี้ กรุณาลองใหม่อีกครั้ง";
  }

  @override
  Widget build(BuildContext context) {
    if (!AppConfig.reviewerOpsEnabled) {
      return Scaffold(
        appBar: AppBar(title: const Text("งานตรวจสอบคำขอ")),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: const [
            Card(
              color: Color(0xFFFFF7ED),
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "ต้องตั้งค่าระบบผู้ตรวจสอบก่อน",
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                    ),
                    SizedBox(height: 8),
                    Text(
                      "หน้านี้ต้องใช้รีวิวคีย์ก่อนจึงจะใช้งานคิวตรวจสอบได้",
                    ),
                    SizedBox(height: 8),
                    SelectableText(
                        "flutter run --dart-define=REVIEWER_API_KEY=<reviewer_key>"),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("งานตรวจสอบคำขอ")),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "ตัวควบคุมคิว",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _reviewerRefController,
                    decoration: const InputDecoration(labelText: "รหัสผู้ตรวจ"),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    initialValue: _status,
                    decoration: const InputDecoration(
                      labelText: "สถานะคิว",
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: "submitted",
                        child: Text("Submitted"),
                      ),
                      DropdownMenuItem(
                        value: "under_review",
                        child: Text("Under review"),
                      ),
                      DropdownMenuItem(
                        value: "verified",
                        child: Text("Verified"),
                      ),
                      DropdownMenuItem(
                        value: "rejected",
                        child: Text("Rejected"),
                      ),
                    ],
                    onChanged: (v) =>
                        setState(() => _status = v ?? "under_review"),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _notesController,
                    decoration: const InputDecoration(
                      labelText: "Review notes (optional)",
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: _busy ? null : _reload,
                      child: const Text("Refresh queue"),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_message != null) ...[
            const SizedBox(height: 10),
            AppStatePanel(
              message: _message!,
              tone: _messageIsError
                  ? (appStateLooksOfflineMessage(_message!)
                      ? AppStateTone.offline
                      : AppStateTone.error)
                  : AppStateTone.success,
            ),
          ],
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Queue (${_queue.length})",
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (_busy) const LinearProgressIndicator(),
                  if (_queue.isEmpty && !_busy)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF7F1E8),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        "No records in the selected queue yet. Try another status or refresh.",
                      ),
                    ),
                  ..._queue.map(
                    (item) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        "${item.documentType} | ${item.reviewStatus}",
                      ),
                      subtitle: Text(
                        "evidence: ${item.id}\nowner: ${item.ownerId}\nupdated: ${item.updatedAt.toIso8601String()}\napprovals: ${item.approvals}, rejections: ${item.rejections}, needs_info: ${item.needsInfoCount}",
                      ),
                      trailing: Wrap(
                        spacing: 6,
                        children: [
                          TextButton(
                            onPressed:
                                _busy ? null : () => _openTimeline(item.id),
                            child: const Text("Timeline"),
                          ),
                          TextButton(
                            onPressed: _busy
                                ? null
                                : () => _review(item.id, "approved"),
                            child: const Text("Approve"),
                          ),
                          TextButton(
                            onPressed: _busy
                                ? null
                                : () => _review(item.id, "needs_info"),
                            child: const Text("Need Info"),
                          ),
                          TextButton(
                            onPressed: _busy
                                ? null
                                : () => _review(item.id, "rejected"),
                            child: const Text("Reject"),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
