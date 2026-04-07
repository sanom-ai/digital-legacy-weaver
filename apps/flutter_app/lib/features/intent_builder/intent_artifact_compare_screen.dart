import 'package:digital_legacy_weaver/features/intent_builder/intent_canonical_artifact_model.dart';
import 'package:flutter/material.dart';

// Legacy copy anchor kept for compatibility tests:
// "Exported Version Compare"

class IntentArtifactCompareScreen extends StatelessWidget {
  const IntentArtifactCompareScreen({
    super.key,
    required this.currentArtifact,
    required this.compareArtifact,
  });

  final IntentCanonicalArtifactModel currentArtifact;
  final IntentCanonicalArtifactModel compareArtifact;

  List<String> _changedFields() {
    final changes = <String>[];
    if (currentArtifact.artifactState != compareArtifact.artifactState) {
      changes.add('สถานะเวอร์ชันเปลี่ยน');
    }
    if (currentArtifact.activeEntryCount != compareArtifact.activeEntryCount) {
      changes.add('จำนวนแผนที่เปิดใช้งานเปลี่ยน');
    }
    if (currentArtifact.report.errorCount != compareArtifact.report.errorCount ||
        currentArtifact.report.warningCount !=
            compareArtifact.report.warningCount) {
      changes.add('ผลตรวจคุณภาพเปลี่ยน');
    }
    final currentTraceCount =
        (currentArtifact.trace["entries"] as Map?)?.length ?? 0;
    final compareTraceCount =
        (compareArtifact.trace["entries"] as Map?)?.length ?? 0;
    if (currentTraceCount != compareTraceCount) {
      changes.add('จำนวนร่องรอยการทำงานเปลี่ยน');
    }
    if (currentArtifact.promotedFromArtifactId !=
        compareArtifact.promotedFromArtifactId) {
      changes.add('ที่มาของเวอร์ชันเปลี่ยน');
    }
    if (currentArtifact.ptn != compareArtifact.ptn) {
      changes.add('กฎนโยบายเชิงเทคนิคเปลี่ยน');
    }
    return changes;
  }

  List<String> _ptnLineSummary() {
    final currentLines = currentArtifact.ptn
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toSet();
    final compareLines = compareArtifact.ptn
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toSet();

    final added = currentLines.difference(compareLines).take(6).toList();
    final removed = compareLines.difference(currentLines).take(6).toList();

    return [
      if (added.isNotEmpty) ...added.map((line) => "บรรทัดที่เพิ่ม: $line"),
      if (removed.isNotEmpty) ...removed.map((line) => "บรรทัดที่หายไป: $line"),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final changedFields = _changedFields();
    final ptnLineSummary = _ptnLineSummary();
    return Scaffold(
      appBar: AppBar(title: const Text("เทียบเวอร์ชันแผน")),
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
                    "สรุปความต่าง",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    "หัวข้อที่เปลี่ยน",
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  if (changedFields.isEmpty)
                    const Text("ไม่พบความต่างสำคัญระหว่างสองเวอร์ชันนี้")
                  else
                    ...changedFields.map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Text("- $item"),
                      ),
                    ),
                  const SizedBox(height: 12),
                  _ComparisonRow(
                    label: "รหัสเวอร์ชัน",
                    current: currentArtifact.artifactId,
                    compare: compareArtifact.artifactId,
                  ),
                  _ComparisonRow(
                    label: "สถานะ",
                    current: _stateLabel(currentArtifact.artifactState),
                    compare: _stateLabel(compareArtifact.artifactState),
                  ),
                  _ComparisonRow(
                    label: "ที่มาของเวอร์ชัน",
                    current:
                        currentArtifact.promotedFromArtifactId ?? "สร้างตรงจากแบบร่าง",
                    compare:
                        compareArtifact.promotedFromArtifactId ?? "สร้างตรงจากแบบร่าง",
                  ),
                  _ComparisonRow(
                    label: "เวลาที่สร้าง",
                    current: currentArtifact.generatedAt.toLocal().toString(),
                    compare: compareArtifact.generatedAt.toLocal().toString(),
                  ),
                  _ComparisonRow(
                    label: "จำนวนรายการที่เปิดใช้งาน",
                    current: "${currentArtifact.activeEntryCount}",
                    compare: "${compareArtifact.activeEntryCount}",
                  ),
                  _ComparisonRow(
                    label: "ผลตรวจคุณภาพ",
                    current:
                        "ติดบล็อก ${currentArtifact.report.errorCount} / เตือน ${currentArtifact.report.warningCount}",
                    compare:
                        "ติดบล็อก ${compareArtifact.report.errorCount} / เตือน ${compareArtifact.report.warningCount}",
                  ),
                  _ComparisonRow(
                    label: "จำนวนรายการในร่องรอยการทำงาน",
                    current:
                        "${(currentArtifact.trace["entries"] as Map?)?.length ?? 0}",
                    compare:
                        "${(compareArtifact.trace["entries"] as Map?)?.length ?? 0}",
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "รายละเอียดที่ต่างกัน",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  if (ptnLineSummary.isEmpty)
                    const Text("ไม่พบความต่างระดับบรรทัดในกฎเชิงเทคนิค")
                  else
                    ...ptnLineSummary.map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Text("- $item"),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "กฎเชิงเทคนิคฉบับเต็ม",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "ส่วนนี้ไว้สำหรับตรวจความต่างเชิงลึกของกฎนโยบาย เมื่อต้องการยืนยันว่าการเปลี่ยนแผนเป็นไปตามที่ตั้งใจ",
                  ),
                  const SizedBox(height: 12),
                  _ArtifactTextBlock(
                    title: "เวอร์ชันล่าสุด",
                    value: currentArtifact.ptn,
                  ),
                  const SizedBox(height: 12),
                  _ArtifactTextBlock(
                    title: "เวอร์ชันที่เลือกมาเทียบ",
                    value: compareArtifact.ptn,
                  ),
                ],
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
        return 'ฉบับพร้อมส่ง';
      case IntentArtifactState.reviewed:
        return 'ตรวจทานแล้ว';
      case IntentArtifactState.ready:
        return 'พร้อมใช้งาน';
    }
  }
}

class _ComparisonRow extends StatelessWidget {
  const _ComparisonRow({
    required this.label,
    required this.current,
    required this.compare,
  });

  final String label;
  final String current;
  final String compare;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text("ฉบับล่าสุด: $current"),
          Text("ฉบับที่เลือกเทียบ: $compare"),
        ],
      ),
    );
  }
}

class _ArtifactTextBlock extends StatelessWidget {
  const _ArtifactTextBlock({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: const Color(0xFFF7F2EA),
          ),
          child: SelectableText(
            value,
            style: const TextStyle(fontFamily: 'Consolas', fontSize: 12),
          ),
        ),
      ],
    );
  }
}
