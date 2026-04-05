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
          .map((item) => IntentCompilerIssueModel.fromMap(Map<String, dynamic>.from(item)))
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

  final activeEntries = document.entries.where((entry) => entry.status == "active").toList();
  if (activeEntries.isEmpty) {
    issues.add(
      _issue(
        severity: "warning",
        code: "inactive_entry_skipped",
        message: "No active entries yet. Activate at least one entry to emit canonical PTN.",
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

    if (entry.trigger.inactivityDays <= 0) {
      issues.add(
        _issue(
          severity: "error",
          code: "intent_validation_error",
          message: "${entry.entryId}: trigger.inactivity_days must be a positive integer",
          entryId: entry.entryId,
        ),
      );
    }

    if (entry.safeguards.legalDisclaimerRequired && !legalAccepted) {
      issues.add(
        _issue(
          severity: "error",
          code: "intent_validation_error",
          message: "${entry.entryId}: legal companion consent is required before activation",
          entryId: entry.entryId,
        ),
      );
    }

    if (entry.status != "active") {
      issues.add(
        _issue(
          severity: "warning",
          code: "inactive_entry_skipped",
          message: "${entry.entryId}: entry is not active and will not compile into PTN output",
          entryId: entry.entryId,
        ),
      );
      continue;
    }

    if (entry.asset.payloadRef.trim().isEmpty) {
      issues.add(
        _issue(
          severity: "warning",
          code: "missing_payload_ref",
          message: "${entry.entryId}: asset.payload_ref is empty; delivery may be incomplete",
          entryId: entry.entryId,
        ),
      );
    }

    if (entry.partnerPath == null) {
      issues.add(
        _issue(
          severity: "warning",
          code: "missing_partner_path",
          message: "${entry.entryId}: no partner_path defined; workflow will remain core-only",
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
          message: "${entry.entryId}: no multisignal safeguard configured for this active entry",
          entryId: entry.entryId,
        ),
      );
    }

    if (entry.privacy.profile == "audit-heavy" && entry.privacy.minimizeTraceMetadata) {
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

    if (entry.delivery.method == "notification_only" && entry.safeguards.requireGuardianApproval) {
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

  final errorCount = issues.where((issue) => issue["severity"] == "error").length;
  final warningCount = issues.where((issue) => issue["severity"] == "warning").length;
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
