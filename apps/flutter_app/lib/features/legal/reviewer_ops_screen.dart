import 'package:digital_legacy_weaver/core/providers/supabase_provider.dart';
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
  List<ReviewerQueueItem> _queue = const [];

  @override
  void initState() {
    super.initState();
    _reload();
  }

  @override
  void dispose() {
    _reviewerRefController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _reload() async {
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      final queue = await ref.read(reviewerOpsRepositoryProvider).loadQueue(status: _status);
      if (!mounted) return;
      setState(() => _queue = queue);
    } catch (e) {
      if (!mounted) return;
      setState(() => _message = "Failed to load queue: $e");
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _review(String evidenceId, String decision) async {
    final reviewerRef = _reviewerRefController.text.trim();
    if (reviewerRef.isEmpty) {
      setState(() => _message = "Reviewer reference is required.");
      return;
    }
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      final result = await ref.read(reviewerOpsRepositoryProvider).applyDecision(
            evidenceId: evidenceId,
            reviewerRef: reviewerRef,
            decision: decision,
            notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
          );
      if (!mounted) return;
      setState(() {
        _message = "Updated ${result["evidence_id"]}: status=${result["review_status"]}, approvals=${result["approvals"]}";
      });
      await _reload();
    } catch (e) {
      if (!mounted) return;
      setState(() => _message = "Review action failed: $e");
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _openTimeline(String evidenceId) async {
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      final summary = await ref.read(reviewerOpsRepositoryProvider).loadSummary(evidenceId);
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
                  const Text("Decisions", style: TextStyle(fontWeight: FontWeight.w600)),
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
      setState(() => _message = "Failed to load timeline: $e");
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Reviewer Ops")),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Queue Controls", style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _reviewerRefController,
                    decoration: const InputDecoration(labelText: "Reviewer Ref"),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    initialValue: _status,
                    decoration: const InputDecoration(labelText: "Queue Status"),
                    items: const [
                      DropdownMenuItem(value: "submitted", child: Text("submitted")),
                      DropdownMenuItem(value: "under_review", child: Text("under_review")),
                      DropdownMenuItem(value: "verified", child: Text("verified")),
                      DropdownMenuItem(value: "rejected", child: Text("rejected")),
                    ],
                    onChanged: (v) => setState(() => _status = v ?? "under_review"),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _notesController,
                    decoration: const InputDecoration(labelText: "Notes (optional)"),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: _busy ? null : _reload,
                      child: const Text("Refresh Queue"),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_message != null) ...[
            const SizedBox(height: 10),
            Text(_message!),
          ],
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Queue (${_queue.length})", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  if (_busy) const LinearProgressIndicator(),
                  if (_queue.isEmpty && !_busy) const Text("No records in selected queue."),
                  ..._queue.map(
                    (item) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text("${item.documentType} - ${item.reviewStatus}"),
                      subtitle: Text(
                        "evidence: ${item.id}\nowner: ${item.ownerId}\nupdated: ${item.updatedAt.toIso8601String()}\napprovals: ${item.approvals}, rejections: ${item.rejections}, needs_info: ${item.needsInfoCount}",
                      ),
                      trailing: Wrap(
                        spacing: 6,
                        children: [
                          TextButton(
                            onPressed: _busy ? null : () => _openTimeline(item.id),
                            child: const Text("Timeline"),
                          ),
                          TextButton(
                            onPressed: _busy ? null : () => _review(item.id, "approved"),
                            child: const Text("Approve"),
                          ),
                          TextButton(
                            onPressed: _busy ? null : () => _review(item.id, "needs_info"),
                            child: const Text("Need Info"),
                          ),
                          TextButton(
                            onPressed: _busy ? null : () => _review(item.id, "rejected"),
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
