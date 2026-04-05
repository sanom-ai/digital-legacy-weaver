import 'package:digital_legacy_weaver/features/profile/profile_model.dart';
import 'package:digital_legacy_weaver/features/profile/profile_provider.dart';
import 'package:digital_legacy_weaver/features/settings/safety_settings_model.dart';
import 'package:digital_legacy_weaver/features/settings/safety_settings_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class OnboardingSetupScreen extends ConsumerStatefulWidget {
  const OnboardingSetupScreen({
    super.key,
    required this.initialProfile,
    required this.initialSettings,
  });

  final ProfileModel initialProfile;
  final SafetySettingsModel initialSettings;

  @override
  ConsumerState<OnboardingSetupScreen> createState() => _OnboardingSetupScreenState();
}

class _OnboardingSetupScreenState extends ConsumerState<OnboardingSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  int _stepIndex = 0;
  bool _saving = false;

  late final TextEditingController _backupEmailController;
  late final TextEditingController _beneficiaryEmailController;
  late final TextEditingController _legacyDaysController;
  late final TextEditingController _selfRecoveryDaysController;
  late final TextEditingController _graceDaysController;

  late bool _remindersEnabled;
  late bool _legalAccepted;
  late bool _privateFirstMode;
  late String _tracePrivacyProfile;

  @override
  void initState() {
    super.initState();
    _backupEmailController = TextEditingController(text: widget.initialProfile.backupEmail);
    _beneficiaryEmailController = TextEditingController(text: widget.initialProfile.beneficiaryEmail ?? "");
    _legacyDaysController = TextEditingController(text: widget.initialProfile.legacyInactivityDays.toString());
    _selfRecoveryDaysController = TextEditingController(text: widget.initialProfile.selfRecoveryInactivityDays.toString());
    _graceDaysController = TextEditingController(text: widget.initialSettings.gracePeriodDays.toString());
    _remindersEnabled = widget.initialSettings.remindersEnabled;
    _legalAccepted = widget.initialSettings.legalDisclaimerAccepted;
    _privateFirstMode = widget.initialSettings.privateFirstMode;
    _tracePrivacyProfile = widget.initialSettings.tracePrivacyProfile;
  }

  @override
  void dispose() {
    _backupEmailController.dispose();
    _beneficiaryEmailController.dispose();
    _legacyDaysController.dispose();
    _selfRecoveryDaysController.dispose();
    _graceDaysController.dispose();
    super.dispose();
  }

  String? _requiredEmail(String? value, {bool required = true}) {
    final text = (value ?? "").trim();
    if (!required && text.isEmpty) return null;
    if (text.isEmpty) return "Required";
    if (!text.contains("@") || !text.contains(".")) return "Invalid email";
    return null;
  }

  String? _requiredIntInRange(String? value, int min, int max) {
    final text = (value ?? "").trim();
    if (text.isEmpty) return "Required";
    final parsed = int.tryParse(text);
    if (parsed == null) return "Must be a number";
    if (parsed < min || parsed > max) return "Must be between $min and $max";
    return null;
  }

  Future<void> _save() async {
    if (_saving) return;
    if (!_formKey.currentState!.validate()) return;
    if (!_legalAccepted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please accept legal companion consent to continue.")),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      await ref.read(profileRepositoryProvider).updateProfile(
            backupEmail: _backupEmailController.text,
            beneficiaryEmail: _beneficiaryEmailController.text,
            legacyInactivityDays: int.parse(_legacyDaysController.text),
            selfRecoveryInactivityDays: int.parse(_selfRecoveryDaysController.text),
          );
      await ref.read(safetySettingsProvider.notifier).save(
            remindersEnabled: _remindersEnabled,
            reminderOffsetsDays: const [14, 7, 1],
            gracePeriodDays: int.parse(_graceDaysController.text),
            legalDisclaimerAccepted: _legalAccepted,
            emergencyPauseUntil: null,
            requireTotpUnlock: widget.initialSettings.requireTotpUnlock,
            privateFirstMode: _privateFirstMode,
            tracePrivacyProfile: _tracePrivacyProfile,
          );

      if (!mounted) return;
      ref.invalidate(profileProvider);
      ref.invalidate(safetySettingsProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Setup completed.")),
      );
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Save failed: $error")),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Complete Setup")),
      body: Form(
        key: _formKey,
        child: Stepper(
          currentStep: _stepIndex,
          onStepContinue: () {
            if (_stepIndex < 2) {
              setState(() => _stepIndex += 1);
            } else {
              _save();
            }
          },
          onStepCancel: () {
            if (_stepIndex == 0) {
              Navigator.of(context).maybePop();
            } else {
              setState(() => _stepIndex -= 1);
            }
          },
          controlsBuilder: (context, details) {
            final isFinalStep = _stepIndex == 2;
            return Row(
              children: [
                FilledButton(
                  onPressed: _saving ? null : details.onStepContinue,
                  child: Text(isFinalStep ? "Save setup" : "Continue"),
                ),
                const SizedBox(width: 12),
                TextButton(
                  onPressed: _saving ? null : details.onStepCancel,
                  child: Text(_stepIndex == 0 ? "Close" : "Back"),
                ),
              ],
            );
          },
          steps: [
            Step(
              isActive: _stepIndex >= 0,
              title: const Text("Contacts"),
              content: Column(
                children: [
                  TextFormField(
                    controller: _backupEmailController,
                    decoration: const InputDecoration(labelText: "Backup email"),
                    validator: (v) => _requiredEmail(v),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _beneficiaryEmailController,
                    decoration: const InputDecoration(labelText: "Beneficiary email"),
                    validator: (v) => _requiredEmail(v),
                  ),
                ],
              ),
            ),
            Step(
              isActive: _stepIndex >= 1,
              title: const Text("Triggers"),
              content: Column(
                children: [
                  TextFormField(
                    controller: _legacyDaysController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: "Legacy inactivity days"),
                    validator: (v) => _requiredIntInRange(v, 90, 3650),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _selfRecoveryDaysController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: "Self-recovery inactivity days"),
                    validator: (v) => _requiredIntInRange(v, 30, 180),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _graceDaysController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: "Final grace period (days)"),
                    validator: (v) => _requiredIntInRange(v, 1, 30),
                  ),
                ],
              ),
            ),
            Step(
              isActive: _stepIndex >= 2,
              title: const Text("Consent"),
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    value: _remindersEnabled,
                    onChanged: (v) => setState(() => _remindersEnabled = v),
                    title: const Text("Enable reminders"),
                    subtitle: const Text("Send pre-trigger reminders to reduce accidental release."),
                  ),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    value: _legalAccepted,
                    onChanged: (v) => setState(() => _legalAccepted = v ?? false),
                    title: const Text("I understand legal companion mode"),
                    subtitle: const Text(
                      "This app is a technical companion and does not replace legal will procedures or legal decision-making.",
                    ),
                  ),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    value: _privateFirstMode,
                    onChanged: (v) => setState(() => _privateFirstMode = v),
                    title: const Text("Enable private-first mode"),
                    subtitle: const Text("Prefer the stricter privacy posture between your app settings and active PTN policy."),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _tracePrivacyProfile,
                    decoration: const InputDecoration(
                      labelText: "Trace privacy profile",
                    ),
                    items: const [
                      DropdownMenuItem(value: "confidential", child: Text("Confidential")),
                      DropdownMenuItem(value: "minimal", child: Text("Minimal")),
                      DropdownMenuItem(value: "audit-heavy", child: Text("Audit-heavy")),
                    ],
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() => _tracePrivacyProfile = value);
                    },
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "For closed beta, keep messaging clear: this app helps coordinate secure delivery. It does not replace a legal will.",
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
