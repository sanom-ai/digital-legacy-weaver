import 'package:digital_legacy_weaver/features/intent_builder/intent_runtime_readiness_model.dart';
import 'package:flutter/material.dart';

class IntentRuntimeReadinessScreen extends StatelessWidget {
  const IntentRuntimeReadinessScreen({super.key, required this.readiness});

  final IntentRuntimeReadinessModel readiness;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Release Readiness")),
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
                    "What this means for users",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Readiness is the checkpoint between a draft plan and a safe, real handoff path. Treat this screen as your go/no-go decision before relying on delivery.",
                  ),
                  const SizedBox(height: 12),
                  Text(
                    readiness.readinessLabel,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(readiness.summary),
                  const SizedBox(height: 12),
                  Text(readiness.nextStep),
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
                    "Readiness criteria",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  _CriterionRow(
                    label: "An exported handoff version exists",
                    satisfied: readiness.hasArtifact,
                  ),
                  _CriterionRow(
                    label: "Exported version is marked ready",
                    satisfied:
                        readiness.currentArtifact?.artifactState.name ==
                        'ready',
                  ),
                  _CriterionRow(
                    label: "At least one active route exists",
                    satisfied:
                        (readiness.currentArtifact?.activeEntryCount ?? 0) > 0,
                  ),
                  _CriterionRow(
                    label: "No blocking issues",
                    satisfied: !readiness.hasBlockingErrors,
                  ),
                  _CriterionRow(
                    label: "Draft is still in sync",
                    satisfied: readiness.draftInSync,
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
                    "Readiness metrics",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Text("History versions: ${readiness.historyCount}"),
                  Text("Ready artifacts: ${readiness.readyArtifactCount}"),
                  Text(
                    "Reviewed artifacts: ${readiness.reviewedArtifactCount}",
                  ),
                  Text(
                    "Promoted artifacts: ${readiness.promotedArtifactCount}",
                  ),
                  Text("Compiler warnings: ${readiness.warningCount}"),
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
                    "Current blockers",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  if (readiness.blockers.isEmpty)
                    const Text(
                      "No blockers. The current version is eligible for real release use.",
                    )
                  else
                    ...readiness.blockers.map(
                      (blocker) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text("- $blocker"),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Three-layer map",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "1. User Layer: owners use guided flows for setup, review, and readiness checks.",
                  ),
                  SizedBox(height: 4),
                  Text(
                    "2. Policy Core Layer: safety controls and validation logic stay consistent here.",
                  ),
                  SizedBox(height: 4),
                  Text(
                    "3. Delivery Layer: release paths share only what policy allows for each recipient route.",
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

class _CriterionRow extends StatelessWidget {
  const _CriterionRow({required this.label, required this.satisfied});

  final String label;
  final bool satisfied;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            satisfied
                ? Icons.check_circle_outline
                : Icons.radio_button_unchecked,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(label)),
        ],
      ),
    );
  }
}
