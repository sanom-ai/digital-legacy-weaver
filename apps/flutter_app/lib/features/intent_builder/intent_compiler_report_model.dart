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
}

IntentCompilerReportModel buildDraftIntentCompilerReport({
  required String beneficiaryEmail,
  required bool legalAccepted,
  required bool privateFirstMode,
  required String privacyProfile,
  required int legacyInactivityDays,
  required int graceDays,
}) {
  final issues = <IntentCompilerIssueModel>[];

  if (beneficiaryEmail.trim().isEmpty) {
    issues.add(
      const IntentCompilerIssueModel(
        severity: "error",
        code: "missing_beneficiary_destination",
        message: "Add a beneficiary destination before activating a legacy delivery intent.",
        entryId: "legacy_delivery_primary",
      ),
    );
  }

  if (!legalAccepted) {
    issues.add(
      const IntentCompilerIssueModel(
        severity: "error",
        code: "missing_legal_companion_consent",
        message: "Accept legal companion consent before activating a legacy delivery intent.",
        entryId: "legacy_delivery_primary",
      ),
    );
  }

  if (!privateFirstMode) {
    issues.add(
      const IntentCompilerIssueModel(
        severity: "warning",
        code: "private_first_disabled",
        message: "Private-first mode is off; runtime will prefer the PTN posture instead of the stricter local posture.",
        entryId: "legacy_delivery_primary",
      ),
    );
  }

  if (privacyProfile == "audit-heavy") {
    issues.add(
      const IntentCompilerIssueModel(
        severity: "warning",
        code: "audit_heavy_profile",
        message: "Audit-heavy keeps more operational context and is best when review detail matters more than minimal trace data.",
        entryId: "legacy_delivery_primary",
      ),
    );
  }

  if (legacyInactivityDays < 120) {
    issues.add(
      const IntentCompilerIssueModel(
        severity: "warning",
        code: "short_inactivity_window",
        message: "A shorter inactivity window can raise the risk of accidental release if the owner is temporarily offline.",
        entryId: "legacy_delivery_primary",
      ),
    );
  }

  if (graceDays <= 2) {
    issues.add(
      const IntentCompilerIssueModel(
        severity: "warning",
        code: "short_grace_window",
        message: "A very short grace window reduces the time available to stop an unintended release.",
        entryId: "legacy_delivery_primary",
      ),
    );
  }

  final errorCount = issues.where((issue) => issue.severity == "error").length;
  final warningCount = issues.where((issue) => issue.severity == "warning").length;

  return IntentCompilerReportModel(
    ok: errorCount == 0,
    errorCount: errorCount,
    warningCount: warningCount,
    issues: issues,
  );
}
