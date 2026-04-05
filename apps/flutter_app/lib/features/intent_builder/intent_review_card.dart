import 'package:digital_legacy_weaver/features/intent_builder/intent_compiler_report_model.dart';
import 'package:flutter/material.dart';

class IntentReviewCard extends StatelessWidget {
  const IntentReviewCard({
    super.key,
    required this.report,
  });

  final IntentCompilerReportModel report;

  Color _toneFor(BuildContext context, String severity) {
    if (severity == "error") {
      return Theme.of(context).colorScheme.errorContainer;
    }
    return const Color(0xFFFFF4E5);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Intent review",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              report.ok
                  ? "No blocking issues detected. Review the cautions below before saving."
                  : "Resolve blocking items before saving this intent.",
            ),
            const SizedBox(height: 12),
            if (report.issues.isEmpty)
              const Text("No review issues yet.")
            else
              Column(
                children: report.issues.map((issue) {
                  return Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _toneFor(context, issue.severity),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "${issue.severity.toUpperCase()} · ${issue.code}",
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 4),
                        Text(issue.message),
                      ],
                    ),
                  );
                }).toList(),
              ),
            const SizedBox(height: 4),
            Text(
              "Report summary: ${report.errorCount} error(s), ${report.warningCount} warning(s)",
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
