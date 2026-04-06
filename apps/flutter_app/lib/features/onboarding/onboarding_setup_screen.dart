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
  ConsumerState<OnboardingSetupScreen> createState() => _OnboardingSetupScreenState();
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
    _backupEmailController = TextEditingController(text: widget.initialProfile.backupEmail);
    _beneficiaryEmailController = TextEditingController(text: widget.initialProfile.beneficiaryEmail ?? "");
    _beneficiaryNameController = TextEditingController(text: widget.initialProfile.beneficiaryName ?? "");
    _beneficiaryPhoneController = TextEditingController(text: widget.initialProfile.beneficiaryPhone ?? "");
    _beneficiaryVerificationHintController = TextEditingController(text: widget.initialProfile.beneficiaryVerificationHint ?? "");
    _beneficiaryVerificationPhraseController = TextEditingController();
    _legacyDaysController = TextEditingController(text: widget.initialProfile.legacyInactivityDays.toString());
    _selfRecoveryDaysController = TextEditingController(text: widget.initialProfile.selfRecoveryInactivityDays.toString());
    _graceDaysController = TextEditingController(text: widget.initialSettings.gracePeriodDays.toString());
    _remindersEnabled = widget.initialSettings.remindersEnabled;
    _legalAccepted = widget.initialSettings.legalDisclaimerAccepted;
    _privateFirstMode = widget.initialSettings.privateFirstMode;
    _proofOfLifeCheckMode = widget.initialSettings.proofOfLifeCheckMode;
    final fallbackChannels = widget.initialSettings.proofOfLifeFallbackChannels.toSet();
    _fallbackEmail = fallbackChannels.contains("email");
    _fallbackSms = fallbackChannels.contains("sms");
    _serverHeartbeatFallbackEnabled = widget.initialSettings.serverHeartbeatFallbackEnabled;
    _iosBackgroundRiskAcknowledged = widget.initialSettings.iosBackgroundRiskAcknowledged;
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
      return minLength <= 1 ? "Required" : "Must be at least $minLength characters";
    }
    return null;
  }

  String? _verificationPhraseValidator(String? value) {
    final text = (value ?? "").trim();
    if (widget.initialProfile.beneficiaryVerificationPhraseHash?.trim().isNotEmpty ?? false) {
      if (text.isEmpty) {
        return null;
      }
    }
    if (text.length < 8) {
      return "Must be at least 8 characters";
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
        const SnackBar(content: Text("Resolve blocking intent review items before saving.")),
      );
      return;
    }
    if (draftReport.warningCount > 0 && !_warningAcknowledged) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Acknowledge intent review warnings before saving.")),
      );
      return;
    }
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
            beneficiaryName: _beneficiaryNameController.text,
            beneficiaryPhone: _beneficiaryPhoneController.text,
            beneficiaryVerificationHint: _beneficiaryVerificationHintController.text,
            beneficiaryVerificationPhrase: _beneficiaryVerificationPhraseController.text,
            legacyInactivityDays: int.parse(_legacyDaysController.text),
            selfRecoveryInactivityDays: int.parse(_selfRecoveryDaysController.text),
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
            guardianQuorumRequired: widget.initialSettings.guardianQuorumRequired,
            guardianQuorumPoolSize: widget.initialSettings.guardianQuorumPoolSize,
            emergencyAccessEnabled: widget.initialSettings.emergencyAccessEnabled,
            emergencyAccessRequiresBeneficiaryRequest:
                widget.initialSettings.emergencyAccessRequiresBeneficiaryRequest,
            emergencyAccessRequiresGuardianQuorum:
                widget.initialSettings.emergencyAccessRequiresGuardianQuorum,
            emergencyAccessGraceHours: widget.initialSettings.emergencyAccessGraceHours,
            deviceRebindInProgress: widget.initialSettings.deviceRebindInProgress,
            deviceRebindStartedAt: widget.initialSettings.deviceRebindStartedAt,
            deviceRebindGraceHours: widget.initialSettings.deviceRebindGraceHours,
            recoveryKeyEnabled: widget.initialSettings.recoveryKeyEnabled,
            deliveryAccessTtlHours: widget.initialSettings.deliveryAccessTtlHours,
            payloadRetentionDays: widget.initialSettings.payloadRetentionDays,
            auditLogRetentionDays: widget.initialSettings.auditLogRetentionDays,
            privateFirstMode: _privateFirstMode,
            tracePrivacyProfile: presetById(_selectedPresetId).tracePrivacyProfile,
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
                  onPressed: _saving || (isFinalStep && !canFinalize) ? null : details.onStepContinue,
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
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _beneficiaryNameController,
                    decoration: const InputDecoration(labelText: "Beneficiary legal name"),
                    validator: (v) => _requiredText(v, minLength: 3),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _beneficiaryPhoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(labelText: "Beneficiary fallback phone (optional)"),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _beneficiaryVerificationHintController,
                    decoration: const InputDecoration(labelText: "Beneficiary verification hint"),
                    validator: (v) => _requiredText(v, minLength: 4),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _beneficiaryVerificationPhraseController,
                    decoration: const InputDecoration(labelText: "Beneficiary verification phrase"),
                    validator: _verificationPhraseValidator,
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
                    validator: (v) => _requiredIntInRange(v, 7, 30),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _proofOfLifeCheckMode,
                    decoration: const InputDecoration(labelText: "Proof-of-life confirmation"),
                    items: const [
                      DropdownMenuItem(value: 'biometric_tap', child: Text("Biometric tap")),
                      DropdownMenuItem(value: 'single_tap', child: Text("Single tap fallback")),
                      DropdownMenuItem(value: 'verification_code', child: Text("Verification code")),
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
                        onSelected: (value) => setState(() => _fallbackEmail = value),
                      ),
                      FilterChip(
                        selected: _fallbackSms,
                        label: const Text("SMS fallback"),
                        onSelected: (value) => setState(() => _fallbackSms = value),
                      ),
                    ],
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
                    title: const Text("Keep private-first mode enabled"),
                    subtitle: const Text("Prefer the stricter privacy posture between your app settings and active PTN policy."),
                  ),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    value: _serverHeartbeatFallbackEnabled,
                    onChanged: (v) => setState(() => _serverHeartbeatFallbackEnabled = v),
                    title: const Text("Enable server heartbeat fallback"),
                    subtitle: const Text("Recommended for iOS and long background gaps so false triggers stay less likely."),
                  ),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    value: _iosBackgroundRiskAcknowledged,
                    onChanged: (v) => setState(() => _iosBackgroundRiskAcknowledged = v ?? false),
                    title: const Text("I understand iOS/background delivery limits"),
                    subtitle: const Text("Mobile platforms may pause background execution, so fallback heartbeat is strongly recommended."),
                  ),
                  const SizedBox(height: 12),
                  const Text("Privacy preset", style: TextStyle(fontWeight: FontWeight.w600)),
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
                                color: selected ? Theme.of(context).colorScheme.primary : Theme.of(context).dividerColor,
                                width: selected ? 2 : 1,
                              ),
                              color: selected ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.06) : null,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          preset.title,
                                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(999),
                                          color: _badgeColor(preset),
                                        ),
                                        child: Text(preset.badgeLabel, style: const TextStyle(fontSize: 12)),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(preset.summary),
                                  const SizedBox(height: 6),
                                  Text(
                                    preset.detail,
                                    style: Theme.of(context).textTheme.bodySmall,
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
                      onChanged: (v) => setState(() => _warningAcknowledged = v ?? false),
                      title: const Text("I reviewed these warnings and want to continue"),
                      subtitle: const Text(
                        "Warnings are allowed, but they must be acknowledged before activation.",
                      ),
                    ),
                  ],
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
