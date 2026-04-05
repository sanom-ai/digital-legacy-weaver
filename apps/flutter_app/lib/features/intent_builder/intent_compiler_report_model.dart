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
  required String beneficiaryEmail,
  required bool legalAccepted,
  required bool privateFirstMode,
  required String privacyProfile,
  required int legacyInactivityDays,
  required int graceDays,
}) {
  final issues = <Map<String, dynamic>>[];

  if (beneficiaryEmail.trim().isEmpty) {
    issues.add(
      _issue(
        severity: "error",
        code: "missing_beneficiary_destination",
        message: "Add a beneficiary destination before activating a legacy delivery intent.",
        entryId: "legacy_delivery_primary",
      ),
    );
  }

  if (!legalAccepted) {
    issues.add(
      _issue(
        severity: "error",
        code: "missing_legal_companion_consent",
        message: "Accept legal companion consent before activating a legacy delivery intent.",
        entryId: "legacy_delivery_primary",
      ),
    );
  }

  if (!privateFirstMode) {
    issues.add(
      _issue(
        severity: "warning",
        code: "private_first_disabled",
        message: "Private-first mode is off; runtime will prefer the PTN posture instead of the stricter local posture.",
        entryId: "legacy_delivery_primary",
      ),
    );
  }

  if (privacyProfile == "audit-heavy") {
    issues.add(
      _issue(
        severity: "warning",
        code: "audit_heavy_profile",
        message: "Audit-heavy keeps more operational context and is best when review detail matters more than minimal trace data.",
        entryId: "legacy_delivery_primary",
      ),
    );
  }

  if (legacyInactivityDays < 120) {
    issues.add(
      _issue(
        severity: "warning",
        code: "short_inactivity_window",
        message: "A shorter inactivity window can raise the risk of accidental release if the owner is temporarily offline.",
        entryId: "legacy_delivery_primary",
      ),
    );
  }

  if (graceDays <= 2) {
    issues.add(
      _issue(
        severity: "warning",
        code: "short_grace_window",
        message: "A very short grace window reduces the time available to stop an unintended release.",
        entryId: "legacy_delivery_primary",
      ),
    );
  }

  return IntentCompilerReportModel.fromMap({
    "ok": !issues.any((issue) => issue["severity"] == "error"),
    "error_count": issues.where((issue) => issue["severity"] == "error").length,
    "warning_count": issues.where((issue) => issue["severity"] == "warning").length,
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
