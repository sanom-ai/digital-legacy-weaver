import 'package:digital_legacy_weaver/features/intent_builder/intent_artifact_compare_screen.dart';
import 'package:digital_legacy_weaver/features/intent_builder/intent_artifact_review_screen.dart';
import 'package:digital_legacy_weaver/features/intent_builder/intent_canonical_artifact_model.dart';
import 'package:flutter/material.dart';

typedef ArtifactHistoryAction =
    Future<void> Function(IntentCanonicalArtifactModel artifact);

class IntentArtifactHistoryScreen extends StatefulWidget {
  const IntentArtifactHistoryScreen({
    super.key,
    required this.currentArtifact,
    required this.artifactHistory,
    required this.onPromote,
    required this.onRemove,
  });

  final IntentCanonicalArtifactModel? currentArtifact;
  final List<IntentCanonicalArtifactModel> artifactHistory;
  final ArtifactHistoryAction onPromote;
  final ArtifactHistoryAction onRemove;

  @override
  State<IntentArtifactHistoryScreen> createState() =>
      _IntentArtifactHistoryScreenState();
}

class _IntentArtifactHistoryScreenState
    extends State<IntentArtifactHistoryScreen> {
  String _historyFilter = 'all';
  String _historySort = 'newest';

  Future<bool> _confirmPromote(IntentCanonicalArtifactModel artifact) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("คัดลอกเป็นเวอร์ชันล่าสุด"),
        content: Text(
          "ต้องการสร้างเวอร์ชันส่งออกใหม่จาก ${artifact.artifactId} ใช่ไหม? ประวัติเดิมจะยังอยู่เหมือนเดิม",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text("ยกเลิก"),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text("คัดลอก"),
          ),
        ],
      ),
    );
    return confirmed == true;
  }

  Future<bool> _confirmRemove(IntentCanonicalArtifactModel artifact) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("ลบเวอร์ชัน"),
        content: Text(
          "ต้องการลบ ${artifact.artifactId} ออกจากประวัติเวอร์ชันในเครื่องนี้ใช่ไหม?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text("ยกเลิก"),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text("ลบ"),
          ),
        ],
      ),
    );
    return confirmed == true;
  }

  List<String> _artifactBadges(IntentCanonicalArtifactModel artifact) {
    final badges = <String>[];
    if (widget.currentArtifact != null &&
        artifact.artifactId == widget.currentArtifact!.artifactId) {
      badges.add("ล่าสุด");
    }
    if (artifact.promotedFromArtifactId != null &&
        artifact.promotedFromArtifactId!.isNotEmpty) {
      badges.add("คัดลอกมา");
    }
    if (artifact.artifactState == IntentArtifactState.ready) {
      badges.add("พร้อมใช้งาน");
    } else if (artifact.artifactState == IntentArtifactState.reviewed) {
      badges.add("รีวิวแล้ว");
    }
    if (artifact.report.errorCount > 0) {
      badges.add("มีประเด็น");
    }
    return badges;
  }

  List<IntentCanonicalArtifactModel> _visibleArtifactHistory() {
    final filtered = widget.artifactHistory.where((artifact) {
      switch (_historyFilter) {
        case 'ready':
          return artifact.artifactState == IntentArtifactState.ready;
        case 'promoted':
          return artifact.promotedFromArtifactId != null &&
              artifact.promotedFromArtifactId!.isNotEmpty;
        case 'issues':
          return artifact.report.errorCount > 0;
        default:
          return true;
      }
    }).toList();

    filtered.sort((left, right) {
      switch (_historySort) {
        case 'oldest':
          return left.generatedAt.compareTo(right.generatedAt);
        case 'state':
          return left.artifactState.name.compareTo(right.artifactState.name);
        default:
          return right.generatedAt.compareTo(left.generatedAt);
      }
    });
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final visibleArtifactHistory = _visibleArtifactHistory();
    return Scaffold(
      appBar: AppBar(title: const Text("ประวัติเวอร์ชันที่ส่งออก")),
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
                    "ประวัติเวอร์ชันทั้งหมด",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Text("เวอร์ชันที่เก็บไว้: ${widget.artifactHistory.length}"),
                  if (widget.currentArtifact != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      "เวอร์ชันล่าสุด: ${widget.currentArtifact!.artifactId} | ${_stateLabel(widget.currentArtifact!.artifactState)}",
                    ),
                  ],
                  const SizedBox(height: 8),
                  const Text(
                    "คุณสามารถรีวิว เทียบ และคัดลอกเวอร์ชันเดิมได้โดยไม่ทำให้ประวัติหาย",
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      ChoiceChip(
                        label: const Text("ทั้งหมด"),
                        selected: _historyFilter == 'all',
                        onSelected: (_) =>
                            setState(() => _historyFilter = 'all'),
                      ),
                      ChoiceChip(
                        label: const Text("พร้อมใช้งาน"),
                        selected: _historyFilter == 'ready',
                        onSelected: (_) =>
                            setState(() => _historyFilter = 'ready'),
                      ),
                      ChoiceChip(
                        label: const Text("คัดลอกมา"),
                        selected: _historyFilter == 'promoted',
                        onSelected: (_) =>
                            setState(() => _historyFilter = 'promoted'),
                      ),
                      ChoiceChip(
                        label: const Text("มีประเด็น"),
                        selected: _historyFilter == 'issues',
                        onSelected: (_) =>
                            setState(() => _historyFilter = 'issues'),
                      ),
                      DropdownButton<String>(
                        value: _historySort,
                        items: const [
                          DropdownMenuItem(
                            value: 'newest',
                            child: Text("ใหม่สุดก่อน"),
                          ),
                          DropdownMenuItem(
                            value: 'oldest',
                            child: Text("เก่าสุดก่อน"),
                          ),
                          DropdownMenuItem(
                            value: 'state',
                            child: Text("เรียงตามสถานะ"),
                          ),
                        ],
                        onChanged: (value) {
                          if (value == null) return;
                          setState(() => _historySort = value);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (visibleArtifactHistory.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text("ไม่พบเวอร์ชันที่ตรงกับตัวกรองตอนนี้"),
              ),
            ),
          ...visibleArtifactHistory.map(
            (artifact) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Card(
                child: ListTile(
                  title: Text(
                    "${artifact.generatedAt.toLocal()} | ${_stateLabel(artifact.artifactState)}",
                  ),
                  subtitle: Text(
                    "เวอร์ชัน ${artifact.artifactId} | แผนที่เปิดใช้งาน ${artifact.activeEntryCount}",
                  ),
                  isThreeLine: _artifactBadges(artifact).isNotEmpty,
                  leading: _artifactBadges(artifact).isEmpty
                      ? null
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: _artifactBadges(artifact)
                              .take(2)
                              .map(
                                (badge) => Padding(
                                  padding: const EdgeInsets.only(bottom: 4),
                                  child: _HistoryPill(label: badge),
                                ),
                              )
                              .toList(),
                        ),
                  trailing: Wrap(
                    spacing: 8,
                    children: [
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => IntentArtifactReviewScreen(
                                artifact: artifact,
                              ),
                            ),
                          );
                        },
                        child: const Text("รีวิว"),
                      ),
                      TextButton(
                        onPressed: widget.currentArtifact != null &&
                                artifact.artifactId !=
                                    widget.currentArtifact!.artifactId
                            ? () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => IntentArtifactCompareScreen(
                                      currentArtifact: widget.currentArtifact!,
                                      compareArtifact: artifact,
                                    ),
                                  ),
                                );
                              }
                            : null,
                        child: const Text("เทียบ"),
                      ),
                      TextButton(
                        onPressed: widget.currentArtifact != null &&
                                artifact.artifactId !=
                                    widget.currentArtifact!.artifactId
                            ? () async {
                                final messenger = ScaffoldMessenger.of(context);
                                final navigator = Navigator.of(context);
                                final confirmed = await _confirmPromote(artifact);
                                if (!confirmed) return;
                                await widget.onPromote(artifact);
                                if (!mounted) return;
                                messenger.showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      "คัดลอกเวอร์ชันประวัติเป็นเวอร์ชันส่งออกใหม่เรียบร้อยแล้ว",
                                    ),
                                  ),
                                );
                                navigator.pop();
                              }
                            : null,
                        child: const Text("คัดลอก"),
                      ),
                      TextButton(
                        onPressed: () async {
                          final messenger = ScaffoldMessenger.of(context);
                          final navigator = Navigator.of(context);
                          final confirmed = await _confirmRemove(artifact);
                          if (!confirmed) return;
                          await widget.onRemove(artifact);
                          if (!mounted) return;
                          messenger.showSnackBar(
                            const SnackBar(
                              content: Text(
                                "ลบเวอร์ชันออกจากประวัติในเครื่องแล้ว",
                              ),
                            ),
                          );
                          navigator.pop();
                        },
                        child: const Text("ลบ"),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _stateLabel(IntentArtifactState state) {
    switch (state) {
      case IntentArtifactState.draft:
        return 'แบบร่าง';
      case IntentArtifactState.exported:
        return 'ส่งออกแล้ว';
      case IntentArtifactState.reviewed:
        return 'รีวิวแล้ว';
      case IntentArtifactState.ready:
        return 'พร้อมใช้งาน';
    }
  }
}

class _HistoryPill extends StatelessWidget {
  const _HistoryPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: const Color(0xFFE5D7C5),
      ),
      child: Text(label),
    );
  }
}
