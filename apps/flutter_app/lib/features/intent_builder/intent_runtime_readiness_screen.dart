import 'package:digital_legacy_weaver/features/intent_builder/intent_runtime_readiness_model.dart';
import 'package:flutter/material.dart';

class IntentRuntimeReadinessScreen extends StatelessWidget {
  const IntentRuntimeReadinessScreen({
    super.key,
    required this.readiness,
  });

  final IntentRuntimeReadinessModel readiness;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Runtime Readiness")),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                    "Runtime criteria",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  _CriterionRow(
                    label: "Canonical artifact exported",
                    satisfied: readiness.hasArtifact,
                  ),
                  _CriterionRow(
                    label: "Artifact state is ready",
                    satisfied: readiness.currentArtifact?.artifactState.name == 'ready',
                  ),
                  _CriterionRow(
                    label: "Active entries available",
                    satisfied: (readiness.currentArtifact?.activeEntryCount ?? 0) > 0,
                  ),
                  _CriterionRow(
                    label: "No compiler errors",
                    satisfied: !readiness.hasBlockingErrors,
                  ),
                  _CriterionRow(
                    label: "Draft still in sync",
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
                  Text("Reviewed artifacts: ${readiness.reviewedArtifactCount}"),
                  Text("Promoted artifacts: ${readiness.promotedArtifactCount}"),
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
                    const Text("No blockers. The current artifact is eligible for runtime use.")
                  else
                    ...readiness.blockers.map(
                      (blocker) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text("• $blocker"),
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
                  Text("1. User Layer: owners interact with UX, drafts, review, and readiness summaries."),
                  SizedBox(height: 4),
                  Text("2. PTN Core Layer: policy, controls, compiler semantics, and runtime readiness logic stay canonical here."),
                  SizedBox(height: 4),
                  Text("3. Output Layer: release paths deliver only what PTN authorizes for the configured recipient or route."),
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
  const _CriterionRow({
    required this.label,
    required this.satisfied,
  });

  final String label;
  final bool satisfied;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            satisfied ? Icons.check_circle_outline : Icons.radio_button_unchecked,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(label)),
        ],
      ),
    );
  }
}
