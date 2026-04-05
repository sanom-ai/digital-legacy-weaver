import 'dart:convert';

import 'package:digital_legacy_weaver/features/intent_builder/intent_canonical_artifact_model.dart';
import 'package:flutter/material.dart';

class IntentArtifactReviewScreen extends StatelessWidget {
  const IntentArtifactReviewScreen({
    super.key,
    required this.artifact,
  });

  final IntentCanonicalArtifactModel artifact;

  @override
  Widget build(BuildContext context) {
    final traceJson = const JsonEncoder.withIndent('  ').convert(artifact.trace);
    return Scaffold(
      appBar: AppBar(
        title: const Text("Canonical Artifact Review"),
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
                    "Artifact summary",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Text("Intent: ${artifact.intentId}"),
                  const SizedBox(height: 4),
                  Text("Artifact: ${artifact.artifactId}"),
                  if (artifact.promotedFromArtifactId != null &&
                      artifact.promotedFromArtifactId!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text("Promoted from: ${artifact.promotedFromArtifactId}"),
                  ],
                  const SizedBox(height: 4),
                  Text("Owner: ${artifact.ownerRef}"),
                  const SizedBox(height: 4),
                  Text("Contract: ${artifact.contractVersion}"),
                  const SizedBox(height: 4),
                  Text("State: ${artifact.artifactState.name}"),
                  const SizedBox(height: 4),
                  Text("Generated: ${artifact.generatedAt.toLocal()}"),
                  const SizedBox(height: 4),
                  Text("Active entries: ${artifact.activeEntryCount}"),
                  const SizedBox(height: 4),
                  Text(
                    "Compiler status: ${artifact.report.errorCount} errors / ${artifact.report.warningCount} warnings",
                  ),
                  if (artifact.report.errorCount > 0) ...[
                    const SizedBox(height: 4),
                    const Text("Badge: Has issues"),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    artifact.artifactState == IntentArtifactState.ready
                        ? "State policy: this artifact reached ready after export and review."
                        : "State policy: exported artifacts should be reviewed before they are treated as ready.",
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    "Historical artifacts may be promoted into a fresh exported version when the owner wants to resume from an earlier canonical snapshot.",
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
                    "Compiler report",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  if (artifact.report.issues.isEmpty)
                    const Text("No compiler issues were captured in this artifact.")
                  else
                    ...artifact.report.issues.map(
                      (issue) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          "[${issue.severity}] ${issue.code}: ${issue.message}",
                        ),
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
                    "Trace",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
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
                      traceJson,
                      style: const TextStyle(fontFamily: 'Consolas', fontSize: 12),
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
                    "PTN",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
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
                      artifact.ptn,
                      style: const TextStyle(fontFamily: 'Consolas', fontSize: 12),
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
