import 'package:digital_legacy_weaver/features/intent_builder/intent_builder_model.dart';

class IntentCompilerIssueModel {
  const IntentCompilerIssueModel({
    required this.severity,
    required this.code,
    required this.message,
    this.entryId,
  });

  final String severity;
  final String code;
  final String message;
  final String? entryId;

  factory IntentCompilerIssueModel.fromMap(Map<String, dynamic> map) {
    return IntentCompilerIssueModel(
      severity: map["severity"] as String? ?? "warning",
      code: map["code"] as String? ?? "intent_issue",
      message: map["message"] as String? ?? "",
      entryId: map["entry_id"] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      "severity": severity,
      "code": code,
      "message": message,
      "entry_id": entryId,
    };
  }
}

class IntentCompilerReportModel {
  const IntentCompilerReportModel({
    required this.ok,
    required this.errorCount,
    required this.warningCount,
    required this.issues,
  });

  final bool ok;
  final int errorCount;
  final int warningCount;
  final List<IntentCompilerIssueModel> issues;

  factory IntentCompilerReportModel.fromMap(Map<String, dynamic> map) {
    final rawIssues = map["issues"] as List<dynamic>? ?? const [];
    return IntentCompilerReportModel(
      ok: map["ok"] as bool? ?? false,
      errorCount: map["error_count"] as int? ?? 0,
      warningCount: map["warning_count"] as int? ?? 0,
      issues: rawIssues
          .whereType<Map>()
          .map((item) =>
              IntentCompilerIssueModel.fromMap(Map<String, dynamic>.from(item)))
          .toList(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      "ok": ok,
      "error_count": errorCount,
      "warning_count": warningCount,
      "issues": issues.map((issue) => issue.toMap()).toList(),
    };
  }
}

IntentCompilerReportModel buildDraftIntentCompilerReport({
  required IntentDocumentModel document,
  required bool legalAccepted,
  required bool privateFirstMode,
  String? proofOfLifeCheckMode,
  List<String>? proofOfLifeFallbackChannels,
  bool? serverHeartbeatFallbackEnabled,
  bool? iosBackgroundRiskAcknowledged,
}) {
  final issues = <Map<String, dynamic>>[];

  if (document.ownerRef.trim().isEmpty) {
    issues.add(
      _issue(
        severity: "error",
        code: "intent_validation_error",
        message: "missing owner_ref",
      ),
    );
  }

  if (document.entries.isEmpty) {
    issues.add(
      _issue(
        severity: "error",
        code: "intent_validation_error",
        message: "intent must include at least one entry",
      ),
    );
  }

  final activeEntries =
      document.entries.where((entry) => entry.status == "active").toList();
  if (activeEntries.isEmpty) {
    issues.add(
      _issue(
        severity: "warning",
        code: "inactive_entry_skipped",
        message:
            "No active entries yet. Activate at least one entry to emit canonical PTN.",
      ),
    );
  }

  for (final entry in document.entries) {
    if (entry.asset.displayName.trim().isEmpty) {
      issues.add(
        _issue(
          severity: "error",
          code: "intent_validation_error",
          message: "${entry.entryId}: missing asset.display_name",
          entryId: entry.entryId,
        ),
      );
    }

    if (entry.recipient.destinationRef.trim().isEmpty) {
      issues.add(
        _issue(
          severity: "error",
          code: "intent_validation_error",
          message: "${entry.entryId}: missing recipient.destination_ref",
          entryId: entry.entryId,
        ),
      );
    }

    final triggerMode = entry.trigger.mode.trim().toLowerCase();
    if (triggerMode == "inactivity") {
      if (entry.trigger.inactivityDays <= 0) {
        issues.add(
          _issue(
            severity: "error",
            code: "intent_validation_error",
            message:
                "${entry.entryId}: trigger.inactivity_days must be a positive integer",
            entryId: entry.entryId,
          ),
        );
      }
    } else if (triggerMode == "exact_date") {
      if (entry.trigger.scheduledAtUtc == null) {
        issues.add(
          _issue(
            severity: "error",
            code: "intent_validation_error",
            message:
                "${entry.entryId}: trigger.scheduled_at_utc is required for exact_date mode",
            entryId: entry.entryId,
          ),
        );
      } else if (!entry.trigger.scheduledAtUtc!
          .isAfter(DateTime.now().toUtc())) {
        issues.add(
          _issue(
            severity: "warning",
            code: "exact_date_in_past",
            message:
                "${entry.entryId}: exact date trigger is in the past; this route may dispatch immediately once evaluated.",
            entryId: entry.entryId,
          ),
        );
      }
    } else if (triggerMode != "manual_release") {
      issues.add(
        _issue(
          severity: "error",
          code: "intent_validation_error",
          message:
              "${entry.entryId}: unsupported trigger.mode '$triggerMode' (expected inactivity, exact_date, or manual_release)",
          entryId: entry.entryId,
        ),
      );
    }

    if (entry.safeguards.legalDisclaimerRequired && !legalAccepted) {
      issues.add(
        _issue(
          severity: "error",
          code: "intent_validation_error",
          message:
              "${entry.entryId}: legal companion consent is required before activation",
          entryId: entry.entryId,
        ),
      );
    }

    if (entry.status != "active") {
      issues.add(
        _issue(
          severity: "warning",
          code: "inactive_entry_skipped",
          message:
              "${entry.entryId}: entry is not active and will not compile into PTN output",
          entryId: entry.entryId,
        ),
      );
      continue;
    }

    if (entry.kind == "legacy_delivery" &&
        entry.recipient.registeredLegalName.trim().isEmpty) {
      issues.add(
        _issue(
          severity: "warning",
          code: "missing_beneficiary_identity",
          message:
              "${entry.entryId}: registered beneficiary identity is empty; configure a pre-registered recipient before delivery.",
          entryId: entry.entryId,
        ),
      );
    }

    if (entry.kind == "legacy_delivery" &&
        entry.recipient.verificationHint.trim().isEmpty) {
      issues.add(
        _issue(
          severity: "warning",
          code: "missing_beneficiary_verification_hint",
          message:
              "${entry.entryId}: beneficiary verification hint is empty; recipient authentication will be weaker at unlock time.",
          entryId: entry.entryId,
        ),
      );
    }

    if (entry.kind == "legacy_delivery" &&
        entry.recipient.fallbackChannels.toSet().length < 2) {
      issues.add(
        _issue(
          severity: "warning",
          code: "missing_multi_channel_fallback",
          message:
              "${entry.entryId}: beneficiary flow only has one fallback channel; add email plus SMS before treating proof-of-life as resilient.",
          entryId: entry.entryId,
        ),
      );
    }

    if (entry.privacy.preTriggerVisibility != "none") {
      issues.add(
        _issue(
          severity: "warning",
          code: "pretrigger_visibility_too_open",
          message:
              "${entry.entryId}: visibility before trigger should stay none to avoid disclosing legacy intent while the owner is alive.",
          entryId: entry.entryId,
        ),
      );
    }

    if (entry.privacy.valueDisclosureMode != "hidden" &&
        entry.privacy.valueDisclosureMode != "institution_verified_only") {
      issues.add(
        _issue(
          severity: "warning",
          code: "value_disclosure_too_open",
          message:
              "${entry.entryId}: value disclosure should stay hidden or institution-verified-only; do not expose value inside the technical receipt flow.",
          entryId: entry.entryId,
        ),
      );
    }

    if (entry.trigger.graceDays < 7) {
      issues.add(
        _issue(
          severity: "warning",
          code: "short_grace_period",
          message:
              "${entry.entryId}: grace_days is below 7; false triggers become harder to recover from.",
          entryId: entry.entryId,
        ),
      );
    }

    if (entry.asset.payloadRef.trim().isEmpty) {
      issues.add(
        _issue(
          severity: "warning",
          code: "missing_payload_ref",
          message:
              "${entry.entryId}: asset.payload_ref is empty; delivery may be incomplete",
          entryId: entry.entryId,
        ),
      );
    }

    if (entry.partnerPath == null) {
      issues.add(
        _issue(
          severity: "warning",
          code: "missing_partner_path",
          message:
              "${entry.entryId}: no partner_path defined; workflow will remain core-only",
          entryId: entry.entryId,
        ),
      );
    }

    if (!document.globalSafeguards.requireMultisignalBeforeRelease &&
        !entry.safeguards.requireMultisignal) {
      issues.add(
        _issue(
          severity: "warning",
          code: "missing_multisignal_safeguard",
          message:
              "${entry.entryId}: no multisignal safeguard configured for this active entry",
          entryId: entry.entryId,
        ),
      );
    }

    if (entry.privacy.profile == "audit-heavy" &&
        entry.privacy.minimizeTraceMetadata) {
      issues.add(
        _issue(
          severity: "warning",
          code: "privacy_trace_tension",
          message:
              "${entry.entryId}: audit-heavy profile with minimize_trace_metadata=true may reduce operational detail",
          entryId: entry.entryId,
        ),
      );
    }

    if (entry.delivery.method == "notification_only" &&
        entry.safeguards.requireGuardianApproval) {
      issues.add(
        _issue(
          severity: "warning",
          code: "intent_warning",
          message:
              "${entry.entryId}: notification_only with guardian approval may need clearer operator messaging",
          entryId: entry.entryId,
        ),
      );
    }

    if (!privateFirstMode) {
      issues.add(
        _issue(
          severity: "warning",
          code: "private_first_disabled",
          message:
              "${entry.entryId}: private-first mode is off; runtime will prefer the PTN posture instead of the stricter local posture.",
          entryId: entry.entryId,
        ),
      );
    }
  }

  final effectiveProofOfLifeMode =
      proofOfLifeCheckMode ?? document.globalSafeguards.proofOfLifeCheckMode;
  final effectiveFallbackChannels = proofOfLifeFallbackChannels ??
      document.globalSafeguards.proofOfLifeFallbackChannels;
  final effectiveHeartbeatFallback = serverHeartbeatFallbackEnabled ??
      document.globalSafeguards.serverHeartbeatFallbackEnabled;
  final effectiveIosRiskAck = iosBackgroundRiskAcknowledged ??
      document.globalSafeguards.iosBackgroundRiskAcknowledged;

  if (effectiveProofOfLifeMode != "biometric_tap" &&
      effectiveProofOfLifeMode != "single_tap") {
    issues.add(
      _issue(
        severity: "warning",
        code: "heavy_proof_of_life_check",
        message:
            "Proof-of-life confirmation is heavier than a single tap flow; false-negative risk may increase.",
      ),
    );
  }

  if (effectiveFallbackChannels.toSet().length < 2) {
    issues.add(
      _issue(
        severity: "warning",
        code: "single_channel_proof_of_life_fallback",
        message:
            "Proof-of-life fallback relies on fewer than two channels; add both email and SMS to reduce missed check-ins.",
      ),
    );
  }

  if (!effectiveHeartbeatFallback) {
    issues.add(
      _issue(
        severity: "warning",
        code: "server_heartbeat_fallback_disabled",
        message:
            "Server heartbeat fallback is disabled; mobile background limits can increase false-trigger risk.",
      ),
    );
  }

  if (!effectiveIosRiskAck) {
    issues.add(
      _issue(
        severity: "warning",
        code: "ios_background_risk_unacknowledged",
        message:
            "iOS/background execution risk is not acknowledged yet; review fallback posture before treating this workspace as reliable.",
      ),
    );
  }

  if (document.globalSafeguards.deviceRebindInProgress) {
    issues.add(
      _issue(
        severity: "warning",
        code: "device_rebind_window_active",
        message:
            "Device rebind window is active. Treat final release as temporarily paused until rebind is completed.",
      ),
    );
  }

  if (!document.globalSafeguards.recoveryKeyEnabled) {
    issues.add(
      _issue(
        severity: "warning",
        code: "recovery_key_fallback_disabled",
        message:
            "Recovery key fallback is disabled; cross-device proof-of-life recovery may be weaker during device loss or migration.",
      ),
    );
  }

  if (document.globalSafeguards.deliveryAccessTtlHours > 120) {
    issues.add(
      _issue(
        severity: "warning",
        code: "delivery_access_ttl_too_long",
        message:
            "Delivery access link TTL is longer than 120 hours. Shorter link lifetimes reduce replay and interception risk.",
      ),
    );
  }

  if (document.globalSafeguards.payloadRetentionDays >
      document.globalSafeguards.auditLogRetentionDays) {
    issues.add(
      _issue(
        severity: "warning",
        code: "payload_retention_exceeds_audit_retention",
        message:
            "Payload retention exceeds audit retention. Consider deleting sensitive payload artifacts earlier than audit metadata.",
      ),
    );
  }

  final safeguards = document.globalSafeguards;
  if (safeguards.guardianQuorumEnabled &&
      safeguards.guardianQuorumRequired > safeguards.guardianQuorumPoolSize) {
    issues.add(
      _issue(
        severity: "error",
        code: "guardian_quorum_invalid",
        message:
            "Guardian quorum requires more approvals than the configured guardian pool can provide.",
      ),
    );
  }

  if (safeguards.guardianQuorumEnabled &&
      safeguards.guardianQuorumRequired < 2) {
    issues.add(
      _issue(
        severity: "warning",
        code: "guardian_quorum_weak",
        message:
            "Guardian quorum is enabled with fewer than two approvals. Sensitive legacy routes should usually require at least 2 approvals.",
      ),
    );
  }

  if (safeguards.emergencyAccessEnabled &&
      safeguards.emergencyAccessRequiresGuardianQuorum &&
      !safeguards.guardianQuorumEnabled) {
    issues.add(
      _issue(
        severity: "warning",
        code: "emergency_access_without_guardian_quorum",
        message:
            "Emergency access is configured to depend on guardian quorum, but guardian quorum is not enabled globally.",
      ),
    );
  }

  if (safeguards.emergencyAccessEnabled &&
      !safeguards.emergencyAccessRequiresBeneficiaryRequest) {
    issues.add(
      _issue(
        severity: "warning",
        code: "emergency_access_without_beneficiary_request",
        message:
            "Emergency access does not require an explicit beneficiary request. This increases override risk for incapacity scenarios.",
      ),
    );
  }

  final errorCount =
      issues.where((issue) => issue["severity"] == "error").length;
  final warningCount =
      issues.where((issue) => issue["severity"] == "warning").length;
  return IntentCompilerReportModel.fromMap({
    "ok": errorCount == 0,
    "error_count": errorCount,
    "warning_count": warningCount,
    "issues": issues,
  });
}

Map<String, dynamic> _issue({
  required String severity,
  required String code,
  required String message,
  String? entryId,
}) {
  return {
    "severity": severity,
    "code": code,
    "message": message,
    "entry_id": entryId,
  };
}
