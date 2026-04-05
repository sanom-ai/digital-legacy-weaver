import 'package:digital_legacy_weaver/features/intent_builder/intent_canonical_artifact_model.dart';
import 'package:flutter/material.dart';

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
      changes.add("Artifact state changed");
    }
    if (currentArtifact.activeEntryCount != compareArtifact.activeEntryCount) {
      changes.add("Active entry count changed");
    }
    if (currentArtifact.report.errorCount != compareArtifact.report.errorCount ||
        currentArtifact.report.warningCount != compareArtifact.report.warningCount) {
      changes.add("Compiler status changed");
    }
    final currentTraceCount = (currentArtifact.trace["entries"] as Map?)?.length ?? 0;
    final compareTraceCount = (compareArtifact.trace["entries"] as Map?)?.length ?? 0;
    if (currentTraceCount != compareTraceCount) {
      changes.add("Trace entry count changed");
    }
    if (currentArtifact.promotedFromArtifactId != compareArtifact.promotedFromArtifactId) {
      changes.add("Promotion lineage changed");
    }
    if (currentArtifact.ptn != compareArtifact.ptn) {
      changes.add("PTN body changed");
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
      if (added.isNotEmpty) ...added.map((line) => "Added: $line"),
      if (removed.isNotEmpty) ...removed.map((line) => "Removed: $line"),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final changedFields = _changedFields();
    final ptnLineSummary = _ptnLineSummary();
    return Scaffold(
      appBar: AppBar(
        title: const Text("Canonical Artifact Compare"),
      ),
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
                    "Comparison summary",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    "Changed fields",
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  if (changedFields.isEmpty)
                    const Text("No meaningful differences were detected between these artifact versions.")
                  else
                    ...changedFields.map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Text("• $item"),
                      ),
                    ),
                  const SizedBox(height: 12),
                  _ComparisonRow(
                    label: "Artifact IDs",
                    current: currentArtifact.artifactId,
                    compare: compareArtifact.artifactId,
                  ),
                  _ComparisonRow(
                    label: "States",
                    current: currentArtifact.artifactState.name,
                    compare: compareArtifact.artifactState.name,
                  ),
                  _ComparisonRow(
                    label: "Promotion lineage",
                    current: currentArtifact.promotedFromArtifactId ?? "direct export",
                    compare: compareArtifact.promotedFromArtifactId ?? "direct export",
                  ),
                  _ComparisonRow(
                    label: "Generated",
                    current: currentArtifact.generatedAt.toLocal().toString(),
                    compare: compareArtifact.generatedAt.toLocal().toString(),
                  ),
                  _ComparisonRow(
                    label: "Active entries",
                    current: "${currentArtifact.activeEntryCount}",
                    compare: "${compareArtifact.activeEntryCount}",
                  ),
                  _ComparisonRow(
                    label: "Compiler status",
                    current:
                        "${currentArtifact.report.errorCount} errors / ${currentArtifact.report.warningCount} warnings",
                    compare:
                        "${compareArtifact.report.errorCount} errors / ${compareArtifact.report.warningCount} warnings",
                  ),
                  _ComparisonRow(
                    label: "Trace entries",
                    current: "${(currentArtifact.trace["entries"] as Map?)?.length ?? 0}",
                    compare: "${(compareArtifact.trace["entries"] as Map?)?.length ?? 0}",
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
                    "Diff details",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  if (ptnLineSummary.isEmpty)
                    const Text("No PTN line-level summary differences were detected.")
                  else
                    ...ptnLineSummary.map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Text("• $item"),
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
                    "PTN comparison",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Review the latest export beside an earlier version to understand how user-defined intent changed over time.",
                  ),
                  const SizedBox(height: 12),
                  _ArtifactTextBlock(
                    title: "Current artifact PTN",
                    value: currentArtifact.ptn,
                  ),
                  const SizedBox(height: 12),
                  _ArtifactTextBlock(
                    title: "Compared artifact PTN",
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
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text("Current: $current"),
          Text("Compared: $compare"),
        ],
      ),
    );
  }
}

class _ArtifactTextBlock extends StatelessWidget {
  const _ArtifactTextBlock({
    required this.title,
    required this.value,
  });

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
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
