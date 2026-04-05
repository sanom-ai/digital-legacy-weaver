import 'package:digital_legacy_weaver/features/beta/beta_feedback_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class BetaFeedbackScreen extends ConsumerStatefulWidget {
  const BetaFeedbackScreen({super.key});

  @override
  ConsumerState<BetaFeedbackScreen> createState() => _BetaFeedbackScreenState();
}

class _BetaFeedbackScreenState extends ConsumerState<BetaFeedbackScreen> {
  final _formKey = GlobalKey<FormState>();
  final _summaryController = TextEditingController();
  final _detailsController = TextEditingController();
  final _appVersionController = TextEditingController(text: "0.1.x");

  String _category = "ux";
  String _severity = "medium";
  bool _submitting = false;

  @override
  void dispose() {
    _summaryController.dispose();
    _detailsController.dispose();
    _appVersionController.dispose();
    super.dispose();
  }

  String? _required(String? value) {
    final text = (value ?? "").trim();
    if (text.isEmpty) return "Required";
    if (text.length < 8) return "Please add more detail";
    return null;
  }

  Future<void> _submit() async {
    if (_submitting) return;
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    try {
      await ref.read(betaFeedbackRepositoryProvider).submit(
            category: _category,
            severity: _severity,
            summary: _summaryController.text,
            details: _detailsController.text,
            appVersion: _appVersionController.text,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Feedback submitted. Thank you.")),
      );
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Submit failed: $error")),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Beta Feedback")),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text(
              "Help us improve stability and usability during beta.",
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _category,
              decoration: const InputDecoration(labelText: "Category"),
              items: const [
                DropdownMenuItem(value: "ux", child: Text("UX")),
                DropdownMenuItem(value: "bug", child: Text("Bug")),
                DropdownMenuItem(value: "security", child: Text("Security")),
                DropdownMenuItem(value: "reliability", child: Text("Reliability")),
                DropdownMenuItem(value: "other", child: Text("Other")),
              ],
              onChanged: (v) => setState(() => _category = v ?? "ux"),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _severity,
              decoration: const InputDecoration(labelText: "Severity"),
              items: const [
                DropdownMenuItem(value: "low", child: Text("Low")),
                DropdownMenuItem(value: "medium", child: Text("Medium")),
                DropdownMenuItem(value: "high", child: Text("High")),
                DropdownMenuItem(value: "critical", child: Text("Critical")),
              ],
              onChanged: (v) => setState(() => _severity = v ?? "medium"),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _summaryController,
              decoration: const InputDecoration(
                labelText: "Summary",
                hintText: "Short description of issue or feedback",
              ),
              validator: _required,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _detailsController,
              minLines: 4,
              maxLines: 8,
              decoration: const InputDecoration(
                labelText: "Details (optional)",
                hintText: "Steps to reproduce, expected behavior, actual behavior",
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _appVersionController,
              decoration: const InputDecoration(labelText: "App version"),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _submitting ? null : _submit,
              child: Text(_submitting ? "Submitting..." : "Submit feedback"),
            ),
          ],
        ),
      ),
    );
  }
}
