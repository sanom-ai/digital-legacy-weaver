import 'dart:convert';

import 'package:digital_legacy_weaver/features/intent_builder/intent_canonical_artifact_model.dart';
import 'package:flutter/material.dart';

class IntentArtifactReviewScreen extends StatelessWidget {
  const IntentArtifactReviewScreen({super.key, required this.artifact});

  final IntentCanonicalArtifactModel artifact;

  @override
  Widget build(BuildContext context) {
    final traceJson = const JsonEncoder.withIndent(
      '  ',
    ).convert(artifact.trace);
    return Scaffold(
      appBar: AppBar(title: const Text("Exported Version Review")),
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
                    "Version summary",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Text("Intent: ${artifact.intentId}"),
                  const SizedBox(height: 4),
                  Text("Version ID: ${artifact.artifactId}"),
                  if (artifact.promotedFromArtifactId != null &&
                      artifact.promotedFromArtifactId!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      "Copied from version: ${artifact.promotedFromArtifactId}",
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text("Owner: ${artifact.ownerRef}"),
                  const SizedBox(height: 4),
                  Text("Contract version: ${artifact.contractVersion}"),
                  const SizedBox(height: 4),
                  Text("Status: ${artifact.artifactState.name}"),
                  const SizedBox(height: 4),
                  Text("Generated: ${artifact.generatedAt.toLocal()}"),
                  const SizedBox(height: 4),
                  Text("Active routes: ${artifact.activeEntryCount}"),
                  const SizedBox(height: 4),
                  Text(
                    "Release mode: ${artifact.sealedReleaseCandidate.releaseMode}",
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Secret residency: ${artifact.sealedReleaseCandidate.deviceSecretResidency}",
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Sealed release routes: ${artifact.sealedReleaseCandidate.entries.length}",
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Issue status: ${artifact.report.errorCount} blocking / ${artifact.report.warningCount} cautions",
                  ),
                  if (artifact.report.errorCount > 0) ...[
                    const SizedBox(height: 4),
                    const Text("Badge: Has blocking issues"),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    artifact.artifactState == IntentArtifactState.ready
                        ? "Status rule: this version reached ready after export and review."
                        : "Status rule: exported versions should be reviewed before being treated as ready.",
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    "Historical versions can be copied into a fresh export when you want to resume from an earlier checkpoint.",
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
                    "Trigger summary (human view)",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Use this section to confirm when each route starts. No technical syntax is needed.",
                  ),
                  const SizedBox(height: 10),
                  ...artifact.sealedReleaseCandidate.entries.map(
                    (entry) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: const Color(0xFFEFF6F5),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              entry.assetLabel,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 6),
                            Text(_triggerSummaryText(entry)),
                          ],
                        ),
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
                    "Sealed release package",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Package ID: ${artifact.sealedReleaseCandidate.candidateId}",
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Sealed at: ${artifact.sealedReleaseCandidate.sealedAt.toLocal()}",
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    "This package shows release posture only. Secret payloads remain on-device, and value visibility stays hidden or institution-verified.",
                  ),
                  const SizedBox(height: 10),
                  ...artifact.sealedReleaseCandidate.entries.map(
                    (entry) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: const Color(0xFFF7F2EA),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              entry.assetLabel,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text("Route kind: ${entry.kind}"),
                            const SizedBox(height: 4),
                            Text("Release channel: ${entry.releaseChannel}"),
                            const SizedBox(height: 4),
                            Text(
                              "Before trigger visibility: ${entry.preTriggerVisibility}",
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "After trigger visibility: ${entry.postTriggerVisibility}",
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "Value disclosure: ${entry.valueDisclosureMode}",
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "Partner verification required: ${entry.partnerVerificationRequired ? "yes" : "no"}",
                            ),
                          ],
                        ),
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
                    "Issue report",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  if (artifact.report.issues.isEmpty)
                    const Text(
                      "No issues were captured in this exported version.",
                    )
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
                      style: const TextStyle(
                        fontFamily: 'Consolas',
                        fontSize: 12,
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
                    "Policy Text",
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
                      style: const TextStyle(
                        fontFamily: 'Consolas',
                        fontSize: 12,
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

  String _triggerSummaryText(SealedReleaseEntryModel entry) {
    if (entry.triggerMode == "manual_release") {
      return "Starts only when emergency release is approved, then waits ${entry.graceDays} day(s) before final release.";
    }
    if (entry.triggerMode == "exact_date") {
      final scheduled = entry.scheduledAtUtc;
      if (scheduled == null) {
        return "Starts on an exact date/time, but no schedule is recorded yet. Review this route before production use.";
      }
      return "Starts at ${_formatDateTime(scheduled.toLocal())}, then waits ${entry.graceDays} day(s) before final release.";
    }
    return "Starts after ${entry.inactivityDays} day(s) of inactivity, then waits ${entry.graceDays} day(s) before final release.";
  }

  String _formatDateTime(DateTime value) {
    final month = value.month.toString().padLeft(2, "0");
    final day = value.day.toString().padLeft(2, "0");
    final hour = value.hour.toString().padLeft(2, "0");
    final minute = value.minute.toString().padLeft(2, "0");
    return "${value.year}-$month-$day $hour:$minute";
  }
}
