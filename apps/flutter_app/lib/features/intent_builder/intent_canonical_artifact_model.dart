import 'package:digital_legacy_weaver/features/intent_builder/intent_compiler_report_model.dart';

enum IntentArtifactState {
  draft,
  exported,
  reviewed,
  ready;

  static IntentArtifactState fromValue(String value) {
    return IntentArtifactState.values.firstWhere(
      (item) => item.name == value,
      orElse: () => IntentArtifactState.exported,
    );
  }
}

class IntentCanonicalArtifactModel {
  const IntentCanonicalArtifactModel({
    required this.artifactId,
    required this.promotedFromArtifactId,
    required this.contractVersion,
    required this.artifactState,
    required this.intentId,
    required this.ownerRef,
    required this.generatedAt,
    required this.sourceDraftSignature,
    required this.activeEntryCount,
    required this.ptn,
    required this.trace,
    required this.report,
  });

  final String artifactId;
  final String? promotedFromArtifactId;
  final String contractVersion;
  final IntentArtifactState artifactState;
  final String intentId;
  final String ownerRef;
  final DateTime generatedAt;
  final String sourceDraftSignature;
  final int activeEntryCount;
  final String ptn;
  final Map<String, dynamic> trace;
  final IntentCompilerReportModel report;

  factory IntentCanonicalArtifactModel.fromMap(Map<String, dynamic> map) {
    return IntentCanonicalArtifactModel(
      artifactId: map["artifact_id"] as String? ?? "artifact_latest",
      promotedFromArtifactId: map["promoted_from_artifact_id"] as String?,
      contractVersion: map["contract_version"] as String? ?? "intent-compiler-contract/v1",
      artifactState: IntentArtifactState.fromValue(
        map["artifact_state"] as String? ?? "exported",
      ),
      intentId: map["intent_id"] as String? ?? "intent_primary",
      ownerRef: map["owner_ref"] as String? ?? "",
      generatedAt: DateTime.parse(
        map["generated_at"] as String? ?? DateTime.fromMillisecondsSinceEpoch(0).toUtc().toIso8601String(),
      ),
      sourceDraftSignature: map["source_draft_signature"] as String? ?? "",
      activeEntryCount: map["active_entry_count"] as int? ?? 0,
      ptn: map["ptn"] as String? ?? "",
      trace: Map<String, dynamic>.from(map["trace"] as Map? ?? const <String, dynamic>{}),
      report: IntentCompilerReportModel.fromMap(
        Map<String, dynamic>.from(map["report"] as Map? ?? const <String, dynamic>{}),
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      "artifact_id": artifactId,
      "promoted_from_artifact_id": promotedFromArtifactId,
      "contract_version": contractVersion,
      "artifact_state": artifactState.name,
      "intent_id": intentId,
      "owner_ref": ownerRef,
      "generated_at": generatedAt.toUtc().toIso8601String(),
      "source_draft_signature": sourceDraftSignature,
      "active_entry_count": activeEntryCount,
      "ptn": ptn,
      "trace": trace,
      "report": report.toMap(),
    };
  }

  IntentCanonicalArtifactModel copyWith({
    String? artifactId,
    String? promotedFromArtifactId,
    String? contractVersion,
    IntentArtifactState? artifactState,
    String? intentId,
    String? ownerRef,
    DateTime? generatedAt,
    String? sourceDraftSignature,
    int? activeEntryCount,
    String? ptn,
    Map<String, dynamic>? trace,
    IntentCompilerReportModel? report,
  }) {
    return IntentCanonicalArtifactModel(
      artifactId: artifactId ?? this.artifactId,
      promotedFromArtifactId: promotedFromArtifactId ?? this.promotedFromArtifactId,
      contractVersion: contractVersion ?? this.contractVersion,
      artifactState: artifactState ?? this.artifactState,
      intentId: intentId ?? this.intentId,
      ownerRef: ownerRef ?? this.ownerRef,
      generatedAt: generatedAt ?? this.generatedAt,
      sourceDraftSignature: sourceDraftSignature ?? this.sourceDraftSignature,
      activeEntryCount: activeEntryCount ?? this.activeEntryCount,
      ptn: ptn ?? this.ptn,
      trace: trace ?? this.trace,
      report: report ?? this.report,
    );
  }
}
