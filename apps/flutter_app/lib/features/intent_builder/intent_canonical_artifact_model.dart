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

class SealedReleaseEntryModel {
  const SealedReleaseEntryModel({
    required this.entryId,
    required this.kind,
    required this.assetLabel,
    required this.releaseChannel,
    required this.triggerMode,
    required this.inactivityDays,
    required this.graceDays,
    this.scheduledAtUtc,
    required this.payloadResidency,
    required this.preTriggerVisibility,
    required this.postTriggerVisibility,
    required this.valueDisclosureMode,
    required this.partnerVerificationRequired,
  });

  final String entryId;
  final String kind;
  final String assetLabel;
  final String releaseChannel;
  final String triggerMode;
  final int inactivityDays;
  final int graceDays;
  final DateTime? scheduledAtUtc;
  final String payloadResidency;
  final String preTriggerVisibility;
  final String postTriggerVisibility;
  final String valueDisclosureMode;
  final bool partnerVerificationRequired;

  factory SealedReleaseEntryModel.fromMap(Map<String, dynamic> map) {
    return SealedReleaseEntryModel(
      entryId: map["entry_id"] as String? ?? "entry_unknown",
      kind: map["kind"] as String? ?? "legacy_delivery",
      assetLabel: map["asset_label"] as String? ?? "Untitled asset",
      releaseChannel: map["release_channel"] as String? ?? "secure_link",
      triggerMode: map["trigger_mode"] as String? ?? "inactivity",
      inactivityDays: map["inactivity_days"] as int? ?? 90,
      graceDays: map["grace_days"] as int? ?? 7,
      scheduledAtUtc: map["scheduled_at_utc"] == null
          ? null
          : DateTime.tryParse(map["scheduled_at_utc"] as String)?.toUtc(),
      payloadResidency:
          map["payload_residency"] as String? ?? "device_local_only",
      preTriggerVisibility: map["pre_trigger_visibility"] as String? ?? "none",
      postTriggerVisibility:
          map["post_trigger_visibility"] as String? ?? "route_only",
      valueDisclosureMode: map["value_disclosure_mode"] as String? ??
          "institution_verified_only",
      partnerVerificationRequired:
          map["partner_verification_required"] as bool? ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      "entry_id": entryId,
      "kind": kind,
      "asset_label": assetLabel,
      "release_channel": releaseChannel,
      "trigger_mode": triggerMode,
      "inactivity_days": inactivityDays,
      "grace_days": graceDays,
      if (scheduledAtUtc != null)
        "scheduled_at_utc": scheduledAtUtc!.toUtc().toIso8601String(),
      "payload_residency": payloadResidency,
      "pre_trigger_visibility": preTriggerVisibility,
      "post_trigger_visibility": postTriggerVisibility,
      "value_disclosure_mode": valueDisclosureMode,
      "partner_verification_required": partnerVerificationRequired,
    };
  }

  SealedReleaseEntryModel copyWith({
    String? entryId,
    String? kind,
    String? assetLabel,
    String? releaseChannel,
    String? triggerMode,
    int? inactivityDays,
    int? graceDays,
    DateTime? scheduledAtUtc,
    String? payloadResidency,
    String? preTriggerVisibility,
    String? postTriggerVisibility,
    String? valueDisclosureMode,
    bool? partnerVerificationRequired,
  }) {
    return SealedReleaseEntryModel(
      entryId: entryId ?? this.entryId,
      kind: kind ?? this.kind,
      assetLabel: assetLabel ?? this.assetLabel,
      releaseChannel: releaseChannel ?? this.releaseChannel,
      triggerMode: triggerMode ?? this.triggerMode,
      inactivityDays: inactivityDays ?? this.inactivityDays,
      graceDays: graceDays ?? this.graceDays,
      scheduledAtUtc: scheduledAtUtc ?? this.scheduledAtUtc,
      payloadResidency: payloadResidency ?? this.payloadResidency,
      preTriggerVisibility: preTriggerVisibility ?? this.preTriggerVisibility,
      postTriggerVisibility:
          postTriggerVisibility ?? this.postTriggerVisibility,
      valueDisclosureMode: valueDisclosureMode ?? this.valueDisclosureMode,
      partnerVerificationRequired:
          partnerVerificationRequired ?? this.partnerVerificationRequired,
    );
  }
}

class SealedReleaseCandidateModel {
  const SealedReleaseCandidateModel({
    required this.candidateId,
    required this.sealedAt,
    required this.deviceSecretResidency,
    required this.releaseMode,
    required this.entries,
  });

  final String candidateId;
  final DateTime sealedAt;
  final String deviceSecretResidency;
  final String releaseMode;
  final List<SealedReleaseEntryModel> entries;

  factory SealedReleaseCandidateModel.fromMap(Map<String, dynamic> map) {
    return SealedReleaseCandidateModel(
      candidateId: map["candidate_id"] as String? ?? "release_candidate_latest",
      sealedAt: DateTime.parse(
        map["sealed_at"] as String? ??
            DateTime.fromMillisecondsSinceEpoch(0).toUtc().toIso8601String(),
      ),
      deviceSecretResidency:
          map["device_secret_residency"] as String? ?? "device_local_only",
      releaseMode: map["release_mode"] as String? ?? "hybrid_secure_link",
      entries: (map["entries"] as List<dynamic>? ?? const [])
          .whereType<Map>()
          .map((item) =>
              SealedReleaseEntryModel.fromMap(Map<String, dynamic>.from(item)))
          .toList(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      "candidate_id": candidateId,
      "sealed_at": sealedAt.toUtc().toIso8601String(),
      "device_secret_residency": deviceSecretResidency,
      "release_mode": releaseMode,
      "entries": entries.map((item) => item.toMap()).toList(),
    };
  }

  SealedReleaseCandidateModel copyWith({
    String? candidateId,
    DateTime? sealedAt,
    String? deviceSecretResidency,
    String? releaseMode,
    List<SealedReleaseEntryModel>? entries,
  }) {
    return SealedReleaseCandidateModel(
      candidateId: candidateId ?? this.candidateId,
      sealedAt: sealedAt ?? this.sealedAt,
      deviceSecretResidency:
          deviceSecretResidency ?? this.deviceSecretResidency,
      releaseMode: releaseMode ?? this.releaseMode,
      entries: entries ?? this.entries,
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
    required this.sealedReleaseCandidate,
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
  final SealedReleaseCandidateModel sealedReleaseCandidate;

  factory IntentCanonicalArtifactModel.fromMap(Map<String, dynamic> map) {
    return IntentCanonicalArtifactModel(
      artifactId: map["artifact_id"] as String? ?? "artifact_latest",
      promotedFromArtifactId: map["promoted_from_artifact_id"] as String?,
      contractVersion:
          map["contract_version"] as String? ?? "intent-compiler-contract/v1",
      artifactState: IntentArtifactState.fromValue(
        map["artifact_state"] as String? ?? "exported",
      ),
      intentId: map["intent_id"] as String? ?? "intent_primary",
      ownerRef: map["owner_ref"] as String? ?? "",
      generatedAt: DateTime.parse(
        map["generated_at"] as String? ??
            DateTime.fromMillisecondsSinceEpoch(0).toUtc().toIso8601String(),
      ),
      sourceDraftSignature: map["source_draft_signature"] as String? ?? "",
      activeEntryCount: map["active_entry_count"] as int? ?? 0,
      ptn: map["ptn"] as String? ?? "",
      trace: Map<String, dynamic>.from(
          map["trace"] as Map? ?? const <String, dynamic>{}),
      report: IntentCompilerReportModel.fromMap(
        Map<String, dynamic>.from(
            map["report"] as Map? ?? const <String, dynamic>{}),
      ),
      sealedReleaseCandidate: SealedReleaseCandidateModel.fromMap(
        Map<String, dynamic>.from(
          map["sealed_release_candidate"] as Map? ?? const <String, dynamic>{},
        ),
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
      "sealed_release_candidate": sealedReleaseCandidate.toMap(),
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
    SealedReleaseCandidateModel? sealedReleaseCandidate,
  }) {
    return IntentCanonicalArtifactModel(
      artifactId: artifactId ?? this.artifactId,
      promotedFromArtifactId:
          promotedFromArtifactId ?? this.promotedFromArtifactId,
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
      sealedReleaseCandidate:
          sealedReleaseCandidate ?? this.sealedReleaseCandidate,
    );
  }
}
