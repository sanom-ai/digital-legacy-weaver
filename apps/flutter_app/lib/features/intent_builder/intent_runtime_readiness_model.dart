import 'package:digital_legacy_weaver/features/intent_builder/intent_canonical_artifact_model.dart';
import 'package:digital_legacy_weaver/features/intent_builder/intent_builder_model.dart';
import 'package:digital_legacy_weaver/features/intent_builder/intent_document_signature.dart';

class IntentRuntimeReadinessModel {
  const IntentRuntimeReadinessModel({
    required this.currentArtifact,
    required this.currentDraft,
    required this.historyCount,
    required this.readyArtifactCount,
    required this.reviewedArtifactCount,
    required this.promotedArtifactCount,
    required this.draftInSync,
    required this.blockers,
  });

  final IntentCanonicalArtifactModel? currentArtifact;
  final IntentDocumentModel? currentDraft;
  final int historyCount;
  final int readyArtifactCount;
  final int reviewedArtifactCount;
  final int promotedArtifactCount;
  final bool draftInSync;
  final List<String> blockers;

  bool get hasArtifact => currentArtifact != null;

  bool get hasBlockingErrors => (currentArtifact?.report.errorCount ?? 0) > 0;

  int get warningCount => currentArtifact?.report.warningCount ?? 0;

  bool get readyForRuntime =>
      currentArtifact != null &&
      currentArtifact!.artifactState == IntentArtifactState.ready &&
      currentArtifact!.activeEntryCount > 0 &&
      !hasBlockingErrors &&
      draftInSync;

  String get readinessLabel {
    if (readyForRuntime) {
      return "Ready for runtime";
    }
    if (!hasArtifact) {
      return "Draft only";
    }
    return "Needs attention";
  }

  String get summary {
    if (!hasArtifact) {
      return "No canonical artifact exported yet. Create and export one from Intent Builder before runtime can rely on it.";
    }
    final artifact = currentArtifact!;
    if (readyForRuntime) {
      return "Latest artifact ${artifact.artifactId} is ready, in sync with the current draft, and can be treated as the current runtime candidate.";
    }
    return "Latest artifact ${artifact.artifactId} is ${artifact.artifactState.name} with ${artifact.activeEntryCount} active entries. Review blockers before treating it as runtime-ready.";
  }

  String get nextStep {
    if (!hasArtifact) {
      return "Next step: export a canonical PTN artifact from the current draft.";
    }
    if (hasBlockingErrors) {
      return "Next step: resolve compiler errors before moving this artifact forward.";
    }
    if ((currentArtifact?.activeEntryCount ?? 0) == 0) {
      return "Next step: activate at least one entry before using this artifact for runtime.";
    }
    if (currentArtifact!.artifactState == IntentArtifactState.exported) {
      return "Next step: review the exported artifact before marking it ready.";
    }
    if (currentArtifact!.artifactState == IntentArtifactState.reviewed && !draftInSync) {
      return "Next step: re-export because the current draft changed after review.";
    }
    if (currentArtifact!.artifactState == IntentArtifactState.reviewed) {
      return "Next step: mark the reviewed artifact ready while the draft is still in sync.";
    }
    if (currentArtifact!.artifactState == IntentArtifactState.ready && !draftInSync) {
      return "Next step: re-export to refresh the ready artifact from the latest draft.";
    }
    return "Next step: review the latest artifact state in Intent Builder.";
  }

  static IntentRuntimeReadinessModel fromArtifacts({
    required IntentCanonicalArtifactModel? currentArtifact,
    required IntentDocumentModel? currentDraft,
    required List<IntentCanonicalArtifactModel> artifactHistory,
  }) {
    final draftSignature =
        currentDraft == null ? null : buildIntentDocumentSignature(currentDraft);
    final draftInSync = currentArtifact == null ||
        draftSignature == null ||
        currentArtifact.sourceDraftSignature == draftSignature;

    final blockers = <String>[];
    if (currentArtifact == null) {
      blockers.add("No canonical artifact exported");
    } else {
      if (currentArtifact.report.errorCount > 0) {
        blockers.add("Compiler errors still present");
      }
      if (currentArtifact.activeEntryCount == 0) {
        blockers.add("No active entries exported");
      }
      if (currentArtifact.artifactState == IntentArtifactState.exported) {
        blockers.add("Artifact has not been reviewed");
      }
      if (currentArtifact.artifactState == IntentArtifactState.reviewed && !draftInSync) {
        blockers.add("Draft changed after review");
      }
      if (currentArtifact.artifactState == IntentArtifactState.ready && !draftInSync) {
        blockers.add("Ready artifact is no longer in sync");
      }
    }

    return IntentRuntimeReadinessModel(
      currentArtifact: currentArtifact,
      currentDraft: currentDraft,
      historyCount: artifactHistory.length,
      readyArtifactCount: artifactHistory
          .where((artifact) => artifact.artifactState == IntentArtifactState.ready)
          .length,
      reviewedArtifactCount: artifactHistory
          .where((artifact) => artifact.artifactState == IntentArtifactState.reviewed)
          .length,
      promotedArtifactCount: artifactHistory
          .where((artifact) =>
              artifact.promotedFromArtifactId != null &&
              artifact.promotedFromArtifactId!.isNotEmpty)
          .length,
      draftInSync: draftInSync,
      blockers: blockers,
    );
  }
}
