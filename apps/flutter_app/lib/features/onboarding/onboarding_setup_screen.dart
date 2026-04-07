import 'package:digital_legacy_weaver/features/intent_builder/intent_builder_model.dart';
import 'package:digital_legacy_weaver/features/intent_builder/intent_compiler_report_model.dart';
import 'package:digital_legacy_weaver/features/intent_builder/intent_review_card.dart';
import 'package:digital_legacy_weaver/features/profile/profile_model.dart';
import 'package:digital_legacy_weaver/features/profile/profile_provider.dart';
import 'package:digital_legacy_weaver/features/settings/privacy_profile_preset.dart';
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
  ConsumerState<OnboardingSetupScreen> createState() =>
      _OnboardingSetupScreenState();
}

class _OnboardingSetupScreenState extends ConsumerState<OnboardingSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  int _stepIndex = 0;
  bool _saving = false;

  late final TextEditingController _backupEmailController;
  late final TextEditingController _beneficiaryEmailController;
  late final TextEditingController _beneficiaryNameController;
  late final TextEditingController _beneficiaryPhoneController;
  late final TextEditingController _beneficiaryVerificationHintController;
  late final TextEditingController _beneficiaryVerificationPhraseController;
  late final TextEditingController _legacyDaysController;
  late final TextEditingController _selfRecoveryDaysController;
  late final TextEditingController _graceDaysController;

  late bool _remindersEnabled;
  late bool _legalAccepted;
  late bool _privateFirstMode;
  late String _proofOfLifeCheckMode;
  late bool _fallbackEmail;
  late bool _fallbackSms;
  late bool _serverHeartbeatFallbackEnabled;
  bool _iosBackgroundRiskAcknowledged = false;
  late String _selectedPresetId;
  bool _warningAcknowledged = false;

  @override
  void initState() {
    super.initState();
    _backupEmailController =
        TextEditingController(text: widget.initialProfile.backupEmail);
    _beneficiaryEmailController = TextEditingController(
        text: widget.initialProfile.beneficiaryEmail ?? "");
    _beneficiaryNameController = TextEditingController(
        text: widget.initialProfile.beneficiaryName ?? "");
    _beneficiaryPhoneController = TextEditingController(
        text: widget.initialProfile.beneficiaryPhone ?? "");
    _beneficiaryVerificationHintController = TextEditingController(
        text: widget.initialProfile.beneficiaryVerificationHint ?? "");
    _beneficiaryVerificationPhraseController = TextEditingController();
    _legacyDaysController = TextEditingController(
        text: widget.initialProfile.legacyInactivityDays.toString());
    _selfRecoveryDaysController = TextEditingController(
        text: widget.initialProfile.selfRecoveryInactivityDays.toString());
    _graceDaysController = TextEditingController(
        text: widget.initialSettings.gracePeriodDays.toString());
    _remindersEnabled = widget.initialSettings.remindersEnabled;
    _legalAccepted = widget.initialSettings.legalDisclaimerAccepted;
    _privateFirstMode = widget.initialSettings.privateFirstMode;
    _proofOfLifeCheckMode = widget.initialSettings.proofOfLifeCheckMode;
    final fallbackChannels =
        widget.initialSettings.proofOfLifeFallbackChannels.toSet();
    _fallbackEmail = fallbackChannels.contains("email");
    _fallbackSms = fallbackChannels.contains("sms");
    _serverHeartbeatFallbackEnabled =
        widget.initialSettings.serverHeartbeatFallbackEnabled;
    _iosBackgroundRiskAcknowledged =
        widget.initialSettings.iosBackgroundRiskAcknowledged;
    _selectedPresetId = widget.initialSettings.tracePrivacyProfile;
  }

  @override
  void dispose() {
    _backupEmailController.dispose();
    _beneficiaryEmailController.dispose();
    _beneficiaryNameController.dispose();
    _beneficiaryPhoneController.dispose();
    _beneficiaryVerificationHintController.dispose();
    _beneficiaryVerificationPhraseController.dispose();
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

  String? _requiredText(String? value, {int minLength = 1}) {
    final text = (value ?? "").trim();
    if (text.length < minLength) {
      return minLength <= 1
          ? "Required"
          : "Must be at least $minLength characters";
    }
    return null;
  }

  String? _verificationPhraseValidator(String? value) {
    final text = (value ?? "").trim();
    if (widget.initialProfile.beneficiaryVerificationPhraseHash
            ?.trim()
            .isNotEmpty ??
        false) {
      if (text.isEmpty) {
        return null;
      }
    }
    if (text.length < 8) {
      return "Must be at least 8 characters";
    }
    return null;
  }

  bool _stepOneReady() {
    return _requiredEmail(_backupEmailController.text) == null &&
        _requiredEmail(_beneficiaryEmailController.text) == null &&
        _requiredText(_beneficiaryNameController.text, minLength: 3) == null &&
        _requiredText(_beneficiaryVerificationHintController.text,
                minLength: 4) ==
            null &&
        _verificationPhraseValidator(
                _beneficiaryVerificationPhraseController.text) ==
            null;
  }

  bool _stepTwoReady() {
    return _requiredIntInRange(_legacyDaysController.text, 90, 3650) == null &&
        _requiredIntInRange(_selfRecoveryDaysController.text, 30, 180) ==
            null &&
        _requiredIntInRange(_graceDaysController.text, 7, 30) == null;
  }

  void _showStepError(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  String _friendlySaveError(Object error) {
    final lower = error.toString().toLowerCase();
    if (lower.contains("socketexception") ||
        lower.contains("failed host lookup") ||
        lower.contains("network") ||
        lower.contains("timed out")) {
      return "We could not finish setup because your connection looks unstable. Please check internet and try again.";
    }
    if (lower.contains("unauthorized") || lower.contains("forbidden")) {
      return "Your session may have expired. Please sign in again, then retry setup.";
    }
    return "We could not finish setup right now. Your inputs are still here, so please try again in a moment.";
  }

  String? _productionGuardrailMessage() {
    final legacyDays = int.tryParse(_legacyDaysController.text) ?? 0;
    final selfRecoveryDays =
        int.tryParse(_selfRecoveryDaysController.text) ?? 0;
    final fallbackCount = <String>[
      if (_fallbackEmail) "email",
      if (_fallbackSms) "sms",
    ].length;

    if (selfRecoveryDays >= legacyDays) {
      return "Self-recovery timing should be earlier than legacy release timing to avoid accidental handoff.";
    }
    if (fallbackCount < 2) {
      return "Enable both email and SMS fallback channels before final setup so proof-of-life remains resilient.";
    }
    if (_fallbackSms && _beneficiaryPhoneController.text.trim().isEmpty) {
      return "Add beneficiary fallback phone before enabling SMS fallback.";
    }
    if (!_serverHeartbeatFallbackEnabled) {
      return "Enable server heartbeat fallback before final setup to reduce mobile background false triggers.";
    }
    if (!_iosBackgroundRiskAcknowledged) {
      return "Acknowledge iOS/background execution limits before final setup.";
    }
    return null;
  }

  Color _badgeColor(PrivacyProfilePreset preset) {
    switch (preset.id) {
      case "confidential":
        return const Color(0xFFD9E8FF);
      case "audit-heavy":
        return const Color(0xFFFFE4C7);
      default:
        return const Color(0xFFE5D7C5);
    }
  }

  Widget _stepIntro({
    required IconData icon,
    required String title,
    required String detail,
  }) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.6)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: scheme.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(detail, style: theme.textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _fieldDecoration({
    required String label,
    IconData? icon,
    String? helper,
  }) {
    return InputDecoration(
      labelText: label,
      helperText: helper,
      prefixIcon: icon == null ? null : Icon(icon),
      filled: true,
      fillColor:
          Theme.of(context).colorScheme.surfaceContainerHighest.withValues(
                alpha: 0.24,
              ),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
    );
  }

  IntentDocumentModel _buildDraftIntentDocument(PrivacyProfilePreset preset) {
    final legacyDays = int.tryParse(_legacyDaysController.text) ?? 0;
    final graceDays = int.tryParse(_graceDaysController.text) ?? 0;
    final reminders = _remindersEnabled ? const [14, 7, 1] : const <int>[];

    final legacyEntry = IntentEntryModel.legacyDeliveryDraft(
      entryId: 'onboarding_legacy_delivery',
      recipientRef: 'beneficiary_primary',
      destinationRef: _beneficiaryEmailController.text.trim(),
    ).copyWith(
      recipient: IntentRecipientModel(
        recipientId: 'beneficiary_primary',
        relationship: 'beneficiary',
        deliveryChannel: 'email',
        destinationRef: _beneficiaryEmailController.text.trim(),
        role: 'beneficiary',
        registeredLegalName: _beneficiaryNameController.text.trim(),
        verificationHint: _beneficiaryVerificationHintController.text.trim(),
        fallbackChannels: [
          if (_fallbackEmail) 'email',
          if (_fallbackSms) 'sms',
        ],
      ),
      trigger: IntentTriggerModel(
        mode: 'inactivity',
        inactivityDays: legacyDays,
        requireUnconfirmedAliveStatus: true,
        graceDays: graceDays,
        remindersDaysBefore: reminders,
      ),
      privacy: IntentPrivacyModel(
        profile: preset.tracePrivacyProfile,
        minimizeTraceMetadata: _privateFirstMode,
        preTriggerVisibility: 'none',
        postTriggerVisibility: 'route_only',
        valueDisclosureMode: 'institution_verified_only',
      ),
      status: 'active',
    );

    return IntentDocumentModel.initial(
      ownerRef: widget.initialProfile.id,
      defaultPrivacyProfile: preset.tracePrivacyProfile,
    ).copyWith(
      entries: [legacyEntry],
      globalSafeguards: IntentGlobalSafeguardsModel(
        emergencyPauseEnabled: true,
        defaultGraceDays: graceDays,
        defaultRemindersDaysBefore: reminders,
        requireMultisignalBeforeRelease: true,
        requireGuardianApprovalForLegacy: false,
        proofOfLifeCheckMode: _proofOfLifeCheckMode,
        proofOfLifeFallbackChannels: [
          if (_fallbackEmail) 'email',
          if (_fallbackSms) 'sms',
        ],
        serverHeartbeatFallbackEnabled: _serverHeartbeatFallbackEnabled,
        iosBackgroundRiskAcknowledged: _iosBackgroundRiskAcknowledged,
      ),
    );
  }

  Future<void> _save() async {
    if (_saving) return;
    if (!_formKey.currentState!.validate()) return;
    final guardrailMessage = _productionGuardrailMessage();
    if (guardrailMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(guardrailMessage)),
      );
      return;
    }
    final selectedPreset = presetById(_selectedPresetId);
    final draftDocument = _buildDraftIntentDocument(selectedPreset);
    final draftReport = buildDraftIntentCompilerReport(
      document: draftDocument,
      legalAccepted: _legalAccepted,
      privateFirstMode: _privateFirstMode,
      proofOfLifeCheckMode: _proofOfLifeCheckMode,
      proofOfLifeFallbackChannels: [
        if (_fallbackEmail) 'email',
        if (_fallbackSms) 'sms',
      ],
      serverHeartbeatFallbackEnabled: _serverHeartbeatFallbackEnabled,
      iosBackgroundRiskAcknowledged: _iosBackgroundRiskAcknowledged,
    );
    if (draftReport.errorCount > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text("Resolve blocking intent review items before saving.")),
      );
      return;
    }
    if (draftReport.warningCount > 0 && !_warningAcknowledged) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Acknowledge intent review warnings before saving.")),
      );
      return;
    }
    if (!_legalAccepted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text("Please accept legal companion consent to continue.")),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      await ref.read(profileRepositoryProvider).updateProfile(
            backupEmail: _backupEmailController.text,
            beneficiaryEmail: _beneficiaryEmailController.text,
            beneficiaryName: _beneficiaryNameController.text,
            beneficiaryPhone: _beneficiaryPhoneController.text,
            beneficiaryVerificationHint:
                _beneficiaryVerificationHintController.text,
            beneficiaryVerificationPhrase:
                _beneficiaryVerificationPhraseController.text,
            legacyInactivityDays: int.parse(_legacyDaysController.text),
            selfRecoveryInactivityDays:
                int.parse(_selfRecoveryDaysController.text),
          );
      final fallbackChannels = <String>[
        if (_fallbackEmail) 'email',
        if (_fallbackSms) 'sms',
      ];
      if (fallbackChannels.isEmpty) {
        fallbackChannels.add('email');
      }
      await ref.read(safetySettingsProvider.notifier).save(
            remindersEnabled: _remindersEnabled,
            reminderOffsetsDays: const [14, 7, 1],
            gracePeriodDays: int.parse(_graceDaysController.text),
            proofOfLifeCheckMode: _proofOfLifeCheckMode,
            proofOfLifeFallbackChannels: fallbackChannels,
            serverHeartbeatFallbackEnabled: _serverHeartbeatFallbackEnabled,
            iosBackgroundRiskAcknowledged: _iosBackgroundRiskAcknowledged,
            legalDisclaimerAccepted: _legalAccepted,
            emergencyPauseUntil: null,
            requireTotpUnlock: widget.initialSettings.requireTotpUnlock,
            guardianQuorumEnabled: widget.initialSettings.guardianQuorumEnabled,
            guardianQuorumRequired:
                widget.initialSettings.guardianQuorumRequired,
            guardianQuorumPoolSize:
                widget.initialSettings.guardianQuorumPoolSize,
            emergencyAccessEnabled:
                widget.initialSettings.emergencyAccessEnabled,
            emergencyAccessRequiresBeneficiaryRequest: widget
                .initialSettings.emergencyAccessRequiresBeneficiaryRequest,
            emergencyAccessRequiresGuardianQuorum:
                widget.initialSettings.emergencyAccessRequiresGuardianQuorum,
            emergencyAccessGraceHours:
                widget.initialSettings.emergencyAccessGraceHours,
            deviceRebindInProgress:
                widget.initialSettings.deviceRebindInProgress,
            deviceRebindStartedAt: widget.initialSettings.deviceRebindStartedAt,
            deviceRebindGraceHours:
                widget.initialSettings.deviceRebindGraceHours,
            recoveryKeyEnabled: widget.initialSettings.recoveryKeyEnabled,
            deliveryAccessTtlHours:
                widget.initialSettings.deliveryAccessTtlHours.clamp(24, 120),
            payloadRetentionDays: widget.initialSettings.payloadRetentionDays,
            auditLogRetentionDays: widget.initialSettings.auditLogRetentionDays,
            privateFirstMode: _privateFirstMode,
            tracePrivacyProfile:
                presetById(_selectedPresetId).tracePrivacyProfile,
          );

      if (!mounted) return;
      ref.invalidate(profileProvider);
      ref.invalidate(safetySettingsProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                "Setup complete. Your private-first defaults are now active.")),
      );
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_friendlySaveError(error))),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedPreset = presetById(_selectedPresetId);
    final draftDocument = _buildDraftIntentDocument(selectedPreset);
    final draftReport = buildDraftIntentCompilerReport(
      document: draftDocument,
      legalAccepted: _legalAccepted,
      privateFirstMode: _privateFirstMode,
      proofOfLifeCheckMode: _proofOfLifeCheckMode,
      proofOfLifeFallbackChannels: [
        if (_fallbackEmail) 'email',
        if (_fallbackSms) 'sms',
      ],
      serverHeartbeatFallbackEnabled: _serverHeartbeatFallbackEnabled,
      iosBackgroundRiskAcknowledged: _iosBackgroundRiskAcknowledged,
    );
    final canFinalize = draftReport.errorCount == 0 &&
        (draftReport.warningCount == 0 || _warningAcknowledged);
    final setupProgress = ((_stepIndex + 1) / 3).clamp(0.0, 1.0);
    void onStepContinue() {
      if (_stepIndex == 0 && !_stepOneReady()) {
        _showStepError("Please complete contact details before continuing.");
        return;
      }
      if (_stepIndex == 1 && !_stepTwoReady()) {
        _showStepError("Please complete trigger settings before continuing.");
        return;
      }
      if (_stepIndex < 2) {
        setState(() => _stepIndex += 1);
      } else {
        _save();
      }
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Finish Setup")),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .surfaceContainerHighest
                    .withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: Theme.of(context)
                      .colorScheme
                      .outlineVariant
                      .withValues(alpha: 0.5),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Setup progress: step ${_stepIndex + 1} of 3",
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    "Complete contacts, trigger rules, and consent in one pass so beneficiary handoff is safe and predictable.",
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: setupProgress,
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(999),
                    backgroundColor: Colors.white,
                  ),
                ],
              ),
            ),
            Expanded(
              child: Stepper(
                currentStep: _stepIndex,
                onStepContinue: onStepContinue,
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
                        onPressed: _saving || (isFinalStep && !canFinalize)
                            ? null
                            : details.onStepContinue,
                        child:
                            Text(isFinalStep ? "Finalize setup" : "Continue"),
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
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _stepIntro(
                          icon: Icons.group_outlined,
                          title: "Step 1 of 3: trusted contacts",
                          detail:
                              "Add trusted contact details for secure handoff and recovery.",
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: _backupEmailController,
                          decoration: _fieldDecoration(
                            label: "Backup email",
                            icon: Icons.alternate_email_outlined,
                          ),
                          validator: (v) => _requiredEmail(v),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _beneficiaryEmailController,
                          decoration: _fieldDecoration(
                            label: "Beneficiary email",
                            icon: Icons.mark_email_read_outlined,
                          ),
                          validator: (v) => _requiredEmail(v),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _beneficiaryNameController,
                          decoration: _fieldDecoration(
                            label: "Beneficiary legal name",
                            icon: Icons.badge_outlined,
                          ),
                          validator: (v) => _requiredText(v, minLength: 3),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _beneficiaryPhoneController,
                          keyboardType: TextInputType.phone,
                          decoration: _fieldDecoration(
                            label: "Beneficiary fallback phone (optional)",
                            icon: Icons.phone_outlined,
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _beneficiaryVerificationHintController,
                          decoration: _fieldDecoration(
                            label: "Beneficiary verification hint",
                            icon: Icons.help_outline,
                            helper: "Example: our family memory question",
                          ),
                          validator: (v) => _requiredText(v, minLength: 4),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _beneficiaryVerificationPhraseController,
                          decoration: _fieldDecoration(
                            label: "Beneficiary verification phrase",
                            icon: Icons.password_outlined,
                          ),
                          validator: _verificationPhraseValidator,
                        ),
                      ],
                    ),
                  ),
                  Step(
                    isActive: _stepIndex >= 1,
                    title: const Text("Triggers"),
                    content: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _stepIntro(
                          icon: Icons.schedule_outlined,
                          title: "Step 2 of 3: release timing",
                          detail:
                              "Set timing so recovery stays safe and accidental release is less likely.",
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: _legacyDaysController,
                          keyboardType: TextInputType.number,
                          decoration: _fieldDecoration(
                            label: "Legacy inactivity days",
                            icon: Icons.history_toggle_off,
                          ),
                          validator: (v) => _requiredIntInRange(v, 90, 3650),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _selfRecoveryDaysController,
                          keyboardType: TextInputType.number,
                          decoration: _fieldDecoration(
                            label: "Self-recovery inactivity days",
                            icon: Icons.restore_outlined,
                          ),
                          validator: (v) => _requiredIntInRange(v, 30, 180),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _graceDaysController,
                          keyboardType: TextInputType.number,
                          decoration: _fieldDecoration(
                            label: "Final grace period (days)",
                            icon: Icons.timer_outlined,
                          ),
                          validator: (v) => _requiredIntInRange(v, 7, 30),
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          initialValue: _proofOfLifeCheckMode,
                          decoration: _fieldDecoration(
                            label: "Proof-of-life confirmation",
                            icon: Icons.fact_check_outlined,
                          ),
                          items: const [
                            DropdownMenuItem(
                                value: 'biometric_tap',
                                child: Text("Biometric tap")),
                            DropdownMenuItem(
                                value: 'single_tap',
                                child: Text("Single tap fallback")),
                            DropdownMenuItem(
                                value: 'verification_code',
                                child: Text("Verification code")),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              setState(() => _proofOfLifeCheckMode = value);
                            }
                          },
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          children: [
                            FilterChip(
                              selected: _fallbackEmail,
                              label: const Text("Email fallback"),
                              onSelected: (value) =>
                                  setState(() => _fallbackEmail = value),
                            ),
                            FilterChip(
                              selected: _fallbackSms,
                              label: const Text("SMS fallback"),
                              onSelected: (value) =>
                                  setState(() => _fallbackSms = value),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          "Production baseline: keep both fallback channels on, and add beneficiary phone when SMS fallback is enabled.",
                          style: TextStyle(fontSize: 12),
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
                        _stepIntro(
                          icon: Icons.verified_user_outlined,
                          title: "Step 3 of 3: consent and safety",
                          detail:
                              "Confirm safety defaults so your workspace stays private-first and false-trigger resistant.",
                        ),
                        const SizedBox(height: 10),
                        SwitchListTile.adaptive(
                          contentPadding: EdgeInsets.zero,
                          value: _remindersEnabled,
                          onChanged: (v) =>
                              setState(() => _remindersEnabled = v),
                          title: const Text("Enable reminders"),
                          subtitle: const Text(
                              "Send reminders before trigger windows to reduce accidental release."),
                        ),
                        CheckboxListTile(
                          contentPadding: EdgeInsets.zero,
                          value: _legalAccepted,
                          onChanged: (v) =>
                              setState(() => _legalAccepted = v ?? false),
                          title:
                              const Text("I understand legal companion mode"),
                          subtitle: const Text(
                            "This app is a technical companion and does not replace legal will procedures or legal decision-making.",
                          ),
                        ),
                        SwitchListTile.adaptive(
                          contentPadding: EdgeInsets.zero,
                          value: _privateFirstMode,
                          onChanged: (v) =>
                              setState(() => _privateFirstMode = v),
                          title: const Text("Keep private-first mode enabled"),
                          subtitle: const Text(
                              "Keep the stricter privacy posture between app settings and active policy."),
                        ),
                        SwitchListTile.adaptive(
                          contentPadding: EdgeInsets.zero,
                          value: _serverHeartbeatFallbackEnabled,
                          onChanged: (v) => setState(
                              () => _serverHeartbeatFallbackEnabled = v),
                          title: const Text("Enable server heartbeat fallback"),
                          subtitle: const Text(
                              "Recommended for iOS and long background gaps so false triggers stay less likely."),
                        ),
                        CheckboxListTile(
                          contentPadding: EdgeInsets.zero,
                          value: _iosBackgroundRiskAcknowledged,
                          onChanged: (v) => setState(() =>
                              _iosBackgroundRiskAcknowledged = v ?? false),
                          title: const Text(
                              "I understand iOS/background delivery limits"),
                          subtitle: const Text(
                              "Mobile platforms may pause background execution, so fallback heartbeat is strongly recommended."),
                        ),
                        const SizedBox(height: 12),
                        const Text("Privacy preset",
                            style: TextStyle(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        Column(
                          children: privacyProfilePresets.map((preset) {
                            final selected = preset.id == _selectedPresetId;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(16),
                                onTap: () => setState(() {
                                  _selectedPresetId = preset.id;
                                  _privateFirstMode = preset.privateFirstMode;
                                }),
                                child: Ink(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: selected
                                          ? Theme.of(context)
                                              .colorScheme
                                              .primary
                                          : Theme.of(context).dividerColor,
                                      width: selected ? 2 : 1,
                                    ),
                                    color: selected
                                        ? Theme.of(context)
                                            .colorScheme
                                            .primary
                                            .withValues(alpha: 0.06)
                                        : null,
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(14),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                preset.title,
                                                style: const TextStyle(
                                                    fontSize: 16,
                                                    fontWeight:
                                                        FontWeight.w600),
                                              ),
                                            ),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 4),
                                              decoration: BoxDecoration(
                                                borderRadius:
                                                    BorderRadius.circular(999),
                                                color: _badgeColor(preset),
                                              ),
                                              child: Text(preset.badgeLabel,
                                                  style: const TextStyle(
                                                      fontSize: 12)),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        Text(preset.summary),
                                        const SizedBox(height: 6),
                                        Text(
                                          preset.detail,
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        Text(selectedPreset.summary),
                        const SizedBox(height: 12),
                        IntentReviewCard(report: draftReport),
                        if (draftReport.warningCount > 0) ...[
                          const SizedBox(height: 8),
                          CheckboxListTile(
                            contentPadding: EdgeInsets.zero,
                            value: _warningAcknowledged,
                            onChanged: (v) => setState(
                                () => _warningAcknowledged = v ?? false),
                            title: const Text(
                                "I reviewed these warnings and want to continue"),
                            subtitle: const Text(
                              "Warnings are allowed, but they must be acknowledged before activation.",
                            ),
                          ),
                        ],
                        const SizedBox(height: 8),
                        const Text(
                          "This product helps coordinate secure access handoff. It does not replace a legal will.",
                        ),
                      ],
                    ),
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
