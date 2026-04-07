import 'package:digital_legacy_weaver/features/intent_builder/intent_builder_model.dart';
import 'package:digital_legacy_weaver/features/intent_builder/intent_compiler_report_model.dart';
import 'package:digital_legacy_weaver/features/intent_builder/intent_review_card.dart';
import 'package:digital_legacy_weaver/features/dashboard/dashboard_screen.dart';
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
    if (!required && text.isEmpty) {
      return null;
    }
    if (text.isEmpty) {
      return "กรุณากรอกข้อมูล";
    }
    if (!text.contains("@") || !text.contains(".")) {
      return "รูปแบบอีเมลไม่ถูกต้อง";
    }
    return null;
  }

  String? _requiredIntInRange(String? value, int min, int max) {
    final text = (value ?? "").trim();
    if (text.isEmpty) return "กรุณากรอกข้อมูล";
    final parsed = int.tryParse(text);
    if (parsed == null) return "ต้องเป็นตัวเลข";
    if (parsed < min || parsed > max) return "ต้องอยู่ระหว่าง $min ถึง $max";
    return null;
  }

  String? _requiredText(String? value, {int minLength = 1}) {
    final text = (value ?? "").trim();
    if (text.length < minLength) {
      return minLength <= 1
          ? "กรุณากรอกข้อมูล"
          : "ต้องมีอย่างน้อย $minLength ตัวอักษร";
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
      return "ต้องมีอย่างน้อย 8 ตัวอักษร";
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
      return "ยังตั้งค่าไม่สำเร็จ เพราะอินเทอร์เน็ตไม่เสถียร กรุณาตรวจสอบการเชื่อมต่อแล้วลองใหม่";
    }
    if (lower.contains("unauthorized") || lower.contains("forbidden")) {
      return "เซสชันอาจหมดอายุ กรุณาเข้าสู่ระบบใหม่แล้วลองตั้งค่าอีกครั้ง";
    }
    return "ยังตั้งค่าไม่สำเร็จในขณะนี้ ข้อมูลที่กรอกยังอยู่ครบ กรุณาลองใหม่อีกครั้ง";
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
      return "ระยะเวลากู้คืนตัวเองควรสั้นกว่าระยะเวลาส่งต่อ เพื่อป้องกันการส่งต่อผิดพลาด";
    }
    if (fallbackCount < 2) {
      return "ก่อนยืนยันขั้นสุดท้าย กรุณาเปิดช่องทางสำรองทั้งอีเมลและ SMS";
    }
    if (_fallbackSms && _beneficiaryPhoneController.text.trim().isEmpty) {
      return "กรุณาเพิ่มเบอร์โทรผู้รับก่อนเปิดช่องทางสำรองแบบ SMS";
    }
    if (!_serverHeartbeatFallbackEnabled) {
      return "กรุณาเปิดการเช็กสัญญาณชีพสำรองจากเซิร์ฟเวอร์ เพื่อลดการทริกเกอร์ผิดพลาด";
    }
    if (!_iosBackgroundRiskAcknowledged) {
      return "กรุณายืนยันว่ารับทราบข้อจำกัดการทำงานเบื้องหลังของมือถือก่อนยืนยันขั้นสุดท้าย";
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
    final theme = Theme.of(context);
    return InputDecoration(
      labelText: label,
      helperText: helper,
      prefixIcon: icon == null ? null : Icon(icon),
    ).applyDefaults(theme.inputDecorationTheme).copyWith(
          fillColor: theme.colorScheme.surfaceContainerHighest.withValues(
            alpha: 0.24,
          ),
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
        const SnackBar(content: Text("กรุณาแก้รายการที่ติดบล็อกก่อนบันทึก")),
      );
      return;
    }
    if (draftReport.warningCount > 0 && !_warningAcknowledged) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("กรุณายืนยันว่าได้ตรวจคำเตือนแล้วก่อนบันทึก")),
      );
      return;
    }
    if (!_legalAccepted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("กรุณายอมรับข้อตกลงก่อนดำเนินการต่อ")),
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
                "ตั้งค่าเสร็จแล้ว ระบบพร้อมใช้งานในโหมดความเป็นส่วนตัวสูงสุด")),
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

  Future<void> _skipToDashboard() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("ข้ามการตั้งค่าตอนนี้?"),
          content: const Text(
            "คุณสามารถเริ่มใช้งานต่อในหน้าแดชบอร์ดก่อน แล้วค่อยกลับมาตั้งค่าให้ครบทีหลังได้",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text("อยู่หน้านี้ต่อ"),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text("ไปหน้าแดชบอร์ด"),
            ),
          ],
        );
      },
    );
    if (!mounted || confirmed != true) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const DashboardScreen()),
      (route) => false,
    );
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
        _showStepError("กรุณากรอกข้อมูลผู้รับให้ครบก่อนกดถัดไป");
        return;
      }
      if (_stepIndex == 1 && !_stepTwoReady()) {
        _showStepError("กรุณาตั้งค่าเงื่อนไขเวลาให้ครบก่อนกดถัดไป");
        return;
      }
      if (_stepIndex < 2) {
        setState(() => _stepIndex += 1);
      } else {
        _save();
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("ตั้งค่าเริ่มต้น"),
        actions: [
          TextButton.icon(
            onPressed: _saving ? null : _skipToDashboard,
            icon: const Icon(Icons.dashboard_customize_outlined),
            label: const Text("ข้ามไปแดชบอร์ด"),
          ),
          const SizedBox(width: 8),
        ],
      ),
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
                    "ความคืบหน้า: ขั้นตอนที่ ${_stepIndex + 1} จาก 3",
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    "กรอกผู้รับ เงื่อนไขเวลา และการยืนยันให้ครบครั้งเดียว เพื่อให้การส่งต่อปลอดภัยและชัดเจน",
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
                        child: Text(
                            isFinalStep ? "ยืนยันและเริ่มใช้งาน" : "ถัดไป"),
                      ),
                      const SizedBox(width: 12),
                      TextButton(
                        onPressed: _saving ? null : details.onStepCancel,
                        child:
                            Text(_stepIndex == 0 ? "ไปหน้าหลัก" : "ย้อนกลับ"),
                      ),
                    ],
                  );
                },
                steps: [
                  Step(
                    isActive: _stepIndex >= 0,
                    title: const Text("ผู้รับ"),
                    content: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _stepIntro(
                          icon: Icons.group_outlined,
                          title: "ขั้นตอน 1 จาก 3: ผู้รับที่ไว้ใจได้",
                          detail:
                              "เพิ่มข้อมูลผู้รับหลัก เพื่อให้ระบบส่งต่อได้ถูกคนเมื่อถึงเวลา",
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: _backupEmailController,
                          decoration: _fieldDecoration(
                            label: "อีเมลสำรองของคุณ",
                            icon: Icons.alternate_email_outlined,
                          ),
                          validator: (v) => _requiredEmail(v),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _beneficiaryEmailController,
                          decoration: _fieldDecoration(
                            label: "อีเมลผู้รับ",
                            icon: Icons.mark_email_read_outlined,
                          ),
                          validator: (v) => _requiredEmail(v),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _beneficiaryNameController,
                          decoration: _fieldDecoration(
                            label: "ชื่อผู้รับ",
                            icon: Icons.badge_outlined,
                          ),
                          validator: (v) => _requiredText(v, minLength: 3),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _beneficiaryPhoneController,
                          keyboardType: TextInputType.phone,
                          decoration: _fieldDecoration(
                            label: "เบอร์โทรผู้รับ (ไม่บังคับ)",
                            icon: Icons.phone_outlined,
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _beneficiaryVerificationHintController,
                          decoration: _fieldDecoration(
                            label: "คำใบ้ยืนยันตัวตนของผู้รับ",
                            icon: Icons.help_outline,
                            helper: "ตัวอย่าง: คำถามความทรงจำในครอบครัว",
                          ),
                          validator: (v) => _requiredText(v, minLength: 4),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _beneficiaryVerificationPhraseController,
                          decoration: _fieldDecoration(
                            label: "คำตอบยืนยันตัวตน",
                            icon: Icons.password_outlined,
                          ),
                          validator: _verificationPhraseValidator,
                        ),
                      ],
                    ),
                  ),
                  Step(
                    isActive: _stepIndex >= 1,
                    title: const Text("เวลา"),
                    content: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _stepIntro(
                          icon: Icons.schedule_outlined,
                          title: "ขั้นตอน 2 จาก 3: เงื่อนไขเวลา",
                          detail: "กำหนดเวลาให้พอดี เพื่อกันการส่งต่อผิดพลาด",
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: _legacyDaysController,
                          keyboardType: TextInputType.number,
                          decoration: _fieldDecoration(
                            label: "ขาดการติดต่อกี่วันจึงเริ่มส่งต่อ",
                            icon: Icons.history_toggle_off,
                          ),
                          validator: (v) => _requiredIntInRange(v, 90, 3650),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _selfRecoveryDaysController,
                          keyboardType: TextInputType.number,
                          decoration: _fieldDecoration(
                            label: "ขาดการติดต่อกี่วันจึงเริ่มกู้คืนเอง",
                            icon: Icons.restore_outlined,
                          ),
                          validator: (v) => _requiredIntInRange(v, 30, 180),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _graceDaysController,
                          keyboardType: TextInputType.number,
                          decoration: _fieldDecoration(
                            label: "ช่วงรอก่อนปล่อยข้อมูล (วัน)",
                            icon: Icons.timer_outlined,
                          ),
                          validator: (v) => _requiredIntInRange(v, 7, 30),
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          initialValue: _proofOfLifeCheckMode,
                          decoration: _fieldDecoration(
                            label: "วิธียืนยันว่ายังใช้งานอยู่",
                            icon: Icons.fact_check_outlined,
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'half_life_soft_checkin',
                              child: Text("เช็กแบบนุ่มนวล (แนะนำ)"),
                            ),
                            DropdownMenuItem(
                                value: 'biometric_tap',
                                child: Text("แตะยืนยันด้วยชีวมิติ (เข้มงวด)")),
                            DropdownMenuItem(
                                value: 'single_tap',
                                child: Text("แตะครั้งเดียว (เบา)")),
                            DropdownMenuItem(
                                value: 'verification_code',
                                child: Text("รหัสยืนยัน (เข้มงวดมาก)")),
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
                              label: const Text("สำรองทางอีเมล"),
                              onSelected: (value) =>
                                  setState(() => _fallbackEmail = value),
                            ),
                            FilterChip(
                              selected: _fallbackSms,
                              label: const Text("สำรองทาง SMS"),
                              onSelected: (value) =>
                                  setState(() => _fallbackSms = value),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          "แนะนำ: เปิดทั้งอีเมลและ SMS เพื่อกันพลาด และใส่เบอร์โทรผู้รับเมื่อเปิด SMS",
                          style: TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  Step(
                    isActive: _stepIndex >= 2,
                    title: const Text("ยืนยัน"),
                    content: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _stepIntro(
                          icon: Icons.verified_user_outlined,
                          title: "ขั้นตอน 3 จาก 3: ความยินยอมและความปลอดภัย",
                          detail:
                              "ยืนยันค่าความปลอดภัยเริ่มต้น เพื่อให้แผนทำงานได้อย่างมั่นใจ",
                        ),
                        const SizedBox(height: 10),
                        SwitchListTile.adaptive(
                          contentPadding: EdgeInsets.zero,
                          value: _remindersEnabled,
                          onChanged: (v) =>
                              setState(() => _remindersEnabled = v),
                          title: const Text("เปิดการแจ้งเตือนล่วงหน้า"),
                          subtitle: const Text(
                              "ระบบจะเตือนก่อนถึงช่วงปล่อยข้อมูล เพื่อลดโอกาสส่งต่อผิดเวลา"),
                        ),
                        CheckboxListTile(
                          contentPadding: EdgeInsets.zero,
                          value: _legalAccepted,
                          onChanged: (v) =>
                              setState(() => _legalAccepted = v ?? false),
                          title: const Text("ฉันเข้าใจขอบเขตทางกฎหมายของแอป"),
                          subtitle: const Text(
                            "แอปนี้เป็นเครื่องมือช่วยจัดการดิจิทัล ไม่ได้แทนที่พินัยกรรมหรือคำแนะนำทางกฎหมาย",
                          ),
                        ),
                        SwitchListTile.adaptive(
                          contentPadding: EdgeInsets.zero,
                          value: _privateFirstMode,
                          onChanged: (v) =>
                              setState(() => _privateFirstMode = v),
                          title: const Text("เปิดโหมดความเป็นส่วนตัวสูงสุดไว้"),
                          subtitle: const Text(
                              "คงค่าความเป็นส่วนตัวที่เข้มกว่า ระหว่างการตั้งค่าแอปกับนโยบายที่ใช้งานจริง"),
                        ),
                        SwitchListTile.adaptive(
                          contentPadding: EdgeInsets.zero,
                          value: _serverHeartbeatFallbackEnabled,
                          onChanged: (v) => setState(
                              () => _serverHeartbeatFallbackEnabled = v),
                          title: const Text(
                              "เปิดการเช็กสัญญาณชีพสำรองจากเซิร์ฟเวอร์"),
                          subtitle: const Text(
                              "แนะนำสำหรับ iOS หรือช่วงที่แอปไม่ได้เปิดนาน เพื่อลดการทริกเกอร์ผิดพลาด"),
                        ),
                        CheckboxListTile(
                          contentPadding: EdgeInsets.zero,
                          value: _iosBackgroundRiskAcknowledged,
                          onChanged: (v) => setState(() =>
                              _iosBackgroundRiskAcknowledged = v ?? false),
                          title: const Text(
                              "ฉันเข้าใจข้อจำกัดการทำงานเบื้องหลังของมือถือ"),
                          subtitle: const Text(
                              "บางช่วงระบบมือถืออาจพักการทำงานเบื้องหลัง จึงควรเปิดการเช็กสำรองไว้"),
                        ),
                        const SizedBox(height: 12),
                        const Text("ระดับความเป็นส่วนตัว",
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
                                "ฉันตรวจคำเตือนแล้ว และต้องการดำเนินการต่อ"),
                            subtitle: const Text(
                              "ระบบอนุญาตให้มีคำเตือนได้ แต่ต้องยืนยันรับทราบก่อนเริ่มใช้งาน",
                            ),
                          ),
                        ],
                        const SizedBox(height: 8),
                        const Text(
                          "ผลิตภัณฑ์นี้ช่วยประสานการส่งต่อการเข้าถึงอย่างปลอดภัย และไม่ใช่เอกสารพินัยกรรมทางกฎหมาย",
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
