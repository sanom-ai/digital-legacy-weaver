import 'package:digital_legacy_weaver/features/settings/safety_settings_provider.dart';
import 'package:digital_legacy_weaver/features/settings/privacy_profile_preset.dart';
import 'package:digital_legacy_weaver/features/settings/totp_factor_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SafetySettingsScreen extends ConsumerStatefulWidget {
  const SafetySettingsScreen({super.key});

  @override
  ConsumerState<SafetySettingsScreen> createState() =>
      _SafetySettingsScreenState();
}

class _SafetySettingsScreenState extends ConsumerState<SafetySettingsScreen> {
  bool _remindersEnabled = true;
  bool _legalAccepted = false;
  int _graceDays = 7;
  bool _pause7Days = false;
  bool _offset14 = true;
  bool _offset7 = true;
  bool _offset1 = true;
  bool _requireTotpUnlock = false;
  bool _guardianQuorumEnabled = false;
  int _guardianQuorumRequired = 2;
  int _guardianQuorumPoolSize = 3;
  bool _emergencyAccessEnabled = false;
  bool _emergencyAccessRequiresBeneficiaryRequest = true;
  bool _emergencyAccessRequiresGuardianQuorum = true;
  int _emergencyAccessGraceHours = 48;
  bool _deviceRebindInProgress = false;
  DateTime? _deviceRebindStartedAt;
  int _deviceRebindGraceHours = 72;
  bool _recoveryKeyEnabled = true;
  int _deliveryAccessTtlHours = 72;
  int _payloadRetentionDays = 30;
  int _auditLogRetentionDays = 30;
  bool _privateFirstMode = true;
  String _proofOfLifeCheckMode = "biometric_tap";
  bool _fallbackEmail = true;
  bool _fallbackSms = true;
  bool _serverHeartbeatFallbackEnabled = true;
  bool _iosBackgroundRiskAcknowledged = false;
  String _selectedPresetId = "minimal";
  bool _seeded = false;
  bool _saving = false;

  void _applyPreset(String presetId) {
    final preset = presetById(presetId);
    setState(() {
      _selectedPresetId = preset.id;
      _privateFirstMode = preset.privateFirstMode;
    });
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

  String? _productionGuardrailMessage() {
    final fallbackCount = <String>[
      if (_fallbackEmail) "email",
      if (_fallbackSms) "sms",
    ].length;

    if (!_legalAccepted) {
      return "Accept legal companion consent before saving safety settings.";
    }
    if (fallbackCount < 2) {
      return "Enable both email and SMS fallback channels before saving production safety settings.";
    }
    if (!_serverHeartbeatFallbackEnabled) {
      return "Enable server heartbeat fallback to reduce false triggers on mobile background limits.";
    }
    if (!_iosBackgroundRiskAcknowledged) {
      return "Acknowledge iOS/background limits before saving production safety settings.";
    }
    if (_guardianQuorumEnabled && _guardianQuorumRequired < 2) {
      return "Shared approval must require at least 2 approvers in production mode.";
    }
    if (_guardianQuorumEnabled &&
        _guardianQuorumRequired > _guardianQuorumPoolSize) {
      return "Required approvals cannot exceed approver group size.";
    }
    if (_emergencyAccessEnabled &&
        !_emergencyAccessRequiresBeneficiaryRequest) {
      return "Emergency access must require a beneficiary request in production mode.";
    }
    if (_emergencyAccessEnabled &&
        _emergencyAccessRequiresGuardianQuorum &&
        !_guardianQuorumEnabled) {
      return "Enable shared approval when emergency access requires guardian quorum.";
    }
    if (_deliveryAccessTtlHours > 120) {
      return "Delivery access TTL should not exceed 120 hours in production mode.";
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(safetySettingsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text("ตั้งค่าความปลอดภัย | Safety Settings")),
      body: settingsAsync.when(
        data: (settings) {
          if (!_seeded) {
            _remindersEnabled = settings.remindersEnabled;
            _legalAccepted = settings.legalDisclaimerAccepted;
            _graceDays = settings.gracePeriodDays;
            _proofOfLifeCheckMode = settings.proofOfLifeCheckMode;
            final fallbackChannels =
                settings.proofOfLifeFallbackChannels.toSet();
            _fallbackEmail = fallbackChannels.contains("email");
            _fallbackSms = fallbackChannels.contains("sms");
            _serverHeartbeatFallbackEnabled =
                settings.serverHeartbeatFallbackEnabled;
            _iosBackgroundRiskAcknowledged =
                settings.iosBackgroundRiskAcknowledged;
            _pause7Days = settings.emergencyPauseUntil != null &&
                settings.emergencyPauseUntil!.isAfter(DateTime.now());
            final offsets = settings.reminderOffsetsDays.toSet();
            _offset14 = offsets.contains(14);
            _offset7 = offsets.contains(7);
            _offset1 = offsets.contains(1);
            _requireTotpUnlock = settings.requireTotpUnlock;
            _guardianQuorumEnabled = settings.guardianQuorumEnabled;
            _guardianQuorumRequired = settings.guardianQuorumRequired;
            _guardianQuorumPoolSize = settings.guardianQuorumPoolSize;
            _emergencyAccessEnabled = settings.emergencyAccessEnabled;
            _emergencyAccessRequiresBeneficiaryRequest =
                settings.emergencyAccessRequiresBeneficiaryRequest;
            _emergencyAccessRequiresGuardianQuorum =
                settings.emergencyAccessRequiresGuardianQuorum;
            _emergencyAccessGraceHours = settings.emergencyAccessGraceHours;
            _deviceRebindInProgress = settings.deviceRebindInProgress;
            _deviceRebindStartedAt = settings.deviceRebindStartedAt;
            _deviceRebindGraceHours = settings.deviceRebindGraceHours;
            _recoveryKeyEnabled = settings.recoveryKeyEnabled;
            _deliveryAccessTtlHours = settings.deliveryAccessTtlHours;
            if (_deliveryAccessTtlHours < 24) {
              _deliveryAccessTtlHours = 24;
            }
            if (_deliveryAccessTtlHours > 120) {
              _deliveryAccessTtlHours = 120;
            }
            _payloadRetentionDays = settings.payloadRetentionDays;
            _auditLogRetentionDays = settings.auditLogRetentionDays;
            _privateFirstMode = settings.privateFirstMode;
            _selectedPresetId = settings.tracePrivacyProfile;
            _seeded = true;
          }
          final selectedPreset = presetById(_selectedPresetId);

          return ListView(
            physics: const BouncingScrollPhysics(),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "กฎหมายและความยินยอม | Legal & Consent",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "ผลิตภัณฑ์นี้ช่วยประสานการส่งต่อมรดกดิจิทัล และอาจไม่ทดแทนพินัยกรรมตามกฎหมายในเขตอำนาจของคุณ",
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        "Closed beta note: this app coordinates secure access handoff and does not act as a legal decision-maker.",
                      ),
                      const SizedBox(height: 12),
                      CheckboxListTile(
                        value: _legalAccepted,
                        onChanged: (v) =>
                            setState(() => _legalAccepted = v ?? false),
                        title: const Text(
                          "ฉันยอมรับข้อจำกัดทางกฎหมาย (I accept legal disclaimer and understand limitations.)",
                        ),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "เกราะป้องกันก่อนทริกเกอร์ | Trigger Safeguards",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SwitchListTile(
                        value: _remindersEnabled,
                        onChanged: (v) => setState(() => _remindersEnabled = v),
                        title: const Text("เปิดการเตือนก่อนทริกเกอร์ | Enable pre-trigger reminders"),
                        contentPadding: EdgeInsets.zero,
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 8,
                        children: [
                          FilterChip(
                            selected: _offset14,
                            label: const Text("14 days"),
                            onSelected: (v) => setState(() => _offset14 = v),
                          ),
                          FilterChip(
                            selected: _offset7,
                            label: const Text("7 days"),
                            onSelected: (v) => setState(() => _offset7 = v),
                          ),
                          FilterChip(
                            selected: _offset1,
                            label: const Text("1 day"),
                            onSelected: (v) => setState(() => _offset1 = v),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Text("การยืนยันว่ายังใช้งานอยู่ | Proof-of-life confirmation"),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        initialValue: _proofOfLifeCheckMode,
                        decoration: const InputDecoration(
                          labelText: "วิธีเช็กอิน | Check-in method",
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: "biometric_tap",
                            child: Text("Biometric tap"),
                          ),
                          DropdownMenuItem(
                            value: "single_tap",
                            child: Text("Single tap"),
                          ),
                          DropdownMenuItem(
                            value: "verification_code",
                            child: Text("Verification code"),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _proofOfLifeCheckMode = value);
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      const Text("ช่องทางสำรองสำหรับยืนยัน | Proof-of-life fallback channels"),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: [
                          FilterChip(
                            selected: _fallbackEmail,
                            label: const Text("Email"),
                            onSelected: (v) =>
                                setState(() => _fallbackEmail = v),
                          ),
                          FilterChip(
                            selected: _fallbackSms,
                            label: const Text("SMS"),
                            onSelected: (v) => setState(() => _fallbackSms = v),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Text("ช่วงหน่วงก่อนปล่อยจริง (วัน) | Final release grace period (days)"),
                      Slider(
                        value: _graceDays.toDouble(),
                        min: 7,
                        max: 21,
                        divisions: 14,
                        label: "$_graceDays",
                        onChanged: (v) =>
                            setState(() => _graceDays = v.round()),
                      ),
                      SwitchListTile(
                        value: _serverHeartbeatFallbackEnabled,
                        onChanged: (v) =>
                            setState(() => _serverHeartbeatFallbackEnabled = v),
                        title: const Text("เปิด server heartbeat สำรอง | Enable server heartbeat fallback"),
                        subtitle: const Text(
                          "Recommended for iOS and long background gaps where app-only proof-of-life can drift.",
                        ),
                        contentPadding: EdgeInsets.zero,
                      ),
                      CheckboxListTile(
                        value: _iosBackgroundRiskAcknowledged,
                        onChanged: (v) => setState(
                          () => _iosBackgroundRiskAcknowledged = v ?? false,
                        ),
                        title: const Text("รับทราบข้อจำกัด iOS/background | Acknowledge iOS/background limits"),
                        subtitle: const Text(
                          "Dead-man style timers on mobile may need fallback heartbeat to avoid false triggers.",
                        ),
                        contentPadding: EdgeInsets.zero,
                      ),
                      SwitchListTile(
                        value: _pause7Days,
                        onChanged: (v) => setState(() => _pause7Days = v),
                        title: const Text("พักการทำงานฉุกเฉิน 7 วัน | Emergency pause for 7 days"),
                        contentPadding: EdgeInsets.zero,
                      ),
                      SwitchListTile(
                        value: _requireTotpUnlock,
                        onChanged: (v) =>
                            setState(() => _requireTotpUnlock = v),
                        title: const Text("บังคับ TOTP ตอนปลดล็อก | Require TOTP at unlock"),
                        subtitle: const Text(
                          "Enable a stronger second-factor check before handoff details are shown.",
                        ),
                        contentPadding: EdgeInsets.zero,
                      ),
                      const SizedBox(height: 6),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const TotpFactorScreen(),
                              ),
                            );
                          },
                          child: const Text("จัดการ Authenticator Code"),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Divider(),
                      const SizedBox(height: 8),
                      const Text(
                        "การอนุมัติร่วม | Shared approval",
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        "ใช้การอนุมัติร่วมสำหรับการปล่อยที่อ่อนไหว เพื่อลดความเสี่ยงจากการตัดสินใจคนเดียว",
                      ),
                      SwitchListTile(
                        value: _guardianQuorumEnabled,
                        onChanged: (v) =>
                            setState(() => _guardianQuorumEnabled = v),
                        title: const Text("เปิดการอนุมัติร่วมก่อนปล่อย | Enable shared approval for release"),
                        subtitle: const Text(
                          "Recommended baseline: 2-of-3 approvers.",
                        ),
                        contentPadding: EdgeInsets.zero,
                      ),
                      if (_guardianQuorumEnabled) ...[
                        DropdownButtonFormField<int>(
                          initialValue: _guardianQuorumPoolSize,
                          decoration: const InputDecoration(
                            labelText: "จำนวนคนในกลุ่มอนุมัติ | Approver group size",
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 2,
                              child: Text("2 approvers"),
                            ),
                            DropdownMenuItem(
                              value: 3,
                              child: Text("3 approvers"),
                            ),
                            DropdownMenuItem(
                              value: 4,
                              child: Text("4 approvers"),
                            ),
                            DropdownMenuItem(
                              value: 5,
                              child: Text("5 approvers"),
                            ),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                _guardianQuorumPoolSize = value;
                                if (_guardianQuorumRequired > value) {
                                  _guardianQuorumRequired = value;
                                }
                              });
                            }
                          },
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<int>(
                          initialValue: _guardianQuorumRequired,
                          decoration: const InputDecoration(
                            labelText: "จำนวนที่ต้องอนุมัติ | Required approvals",
                          ),
                          items: List.generate(
                            _guardianQuorumPoolSize,
                            (index) => DropdownMenuItem(
                              value: index + 1,
                              child: Text("${index + 1} approvals"),
                            ),
                          ),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() => _guardianQuorumRequired = value);
                            }
                          },
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "เกณฑ์ปัจจุบัน: $_guardianQuorumRequired-of-$_guardianQuorumPoolSize",
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                      const SizedBox(height: 12),
                      const Text(
                        "การเข้าถึงฉุกเฉิน | Emergency access",
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        "Emergency access covers incapacity cases such as ICU or sudden device loss without waiting for a full dead-man cycle.",
                      ),
                      SwitchListTile(
                        value: _emergencyAccessEnabled,
                        onChanged: (v) =>
                            setState(() => _emergencyAccessEnabled = v),
                        title: const Text("เปิดการเข้าถึงฉุกเฉิน | Enable emergency access"),
                        subtitle: const Text(
                          "Keep this separate from standard inactivity-trigger release.",
                        ),
                        contentPadding: EdgeInsets.zero,
                      ),
                      if (_emergencyAccessEnabled) ...[
                        CheckboxListTile(
                          value: _emergencyAccessRequiresBeneficiaryRequest,
                          onChanged: (v) => setState(
                            () => _emergencyAccessRequiresBeneficiaryRequest =
                                v ?? true,
                          ),
                          title: const Text("ต้องมีคำขอจากผู้รับ | Require beneficiary request"),
                          subtitle: const Text(
                            "Emergency access should start with an explicit beneficiary request.",
                          ),
                          contentPadding: EdgeInsets.zero,
                        ),
                        CheckboxListTile(
                          value: _emergencyAccessRequiresGuardianQuorum,
                          onChanged: (v) => setState(
                            () => _emergencyAccessRequiresGuardianQuorum =
                                v ?? true,
                          ),
                          title: const Text("ต้องมีการอนุมัติร่วม | Require shared approval"),
                          subtitle: const Text(
                            "Recommended so one person cannot force emergency access alone.",
                          ),
                          contentPadding: EdgeInsets.zero,
                        ),
                        const SizedBox(height: 8),
                        const Text("ระยะเวลารอก่อนเข้าถึงฉุกเฉิน (ชม.) | Emergency waiting window (hours)"),
                        Slider(
                          value: _emergencyAccessGraceHours.toDouble(),
                          min: 24,
                          max: 168,
                          divisions: 6,
                          label: "$_emergencyAccessGraceHours",
                          onChanged: (v) => setState(
                            () => _emergencyAccessGraceHours = v.round(),
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      const Text(
                        "ย้ายอุปกรณ์และกู้คืน | Cross-device rebind & recovery",
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        "Start a temporary rebind window before device migration. Dispatch will avoid final release during this window to reduce false triggers.",
                      ),
                      SwitchListTile(
                        value: _deviceRebindInProgress,
                        onChanged: (v) {
                          setState(() {
                            _deviceRebindInProgress = v;
                            _deviceRebindStartedAt = v ? DateTime.now() : null;
                          });
                        },
                        title: const Text("กำลังย้ายอุปกรณ์ | Device rebind in progress"),
                        subtitle: const Text(
                          "Enable before changing phone, passkey, or biometric setup.",
                        ),
                        contentPadding: EdgeInsets.zero,
                      ),
                      if (_deviceRebindStartedAt != null)
                        Text(
                          "เริ่มย้ายอุปกรณ์: ${_deviceRebindStartedAt!.toLocal()}",
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      const SizedBox(height: 8),
                      const Text("ช่วงผ่อนผันการย้าย (ชม.) | Rebind grace window (hours)"),
                      Slider(
                        value: _deviceRebindGraceHours.toDouble(),
                        min: 24,
                        max: 168,
                        divisions: 6,
                        label: "$_deviceRebindGraceHours",
                        onChanged: (v) =>
                            setState(() => _deviceRebindGraceHours = v.round()),
                      ),
                      SwitchListTile(
                        value: _recoveryKeyEnabled,
                        onChanged: (v) =>
                            setState(() => _recoveryKeyEnabled = v),
                        title: const Text("เปิด recovery key สำรอง | Enable recovery key fallback"),
                        subtitle: const Text(
                          "Keep an offline recovery key path for proof-of-life disruptions.",
                        ),
                        contentPadding: EdgeInsets.zero,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        "นโยบายการเก็บข้อมูล | Retention policy",
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        "Set how long delivery links, secure references, and audit traces should remain retained.",
                      ),
                      const SizedBox(height: 8),
                      const Text("อายุลิงก์เข้าถึง (ชม.) | Delivery access link TTL (hours)"),
                      Slider(
                        value: _deliveryAccessTtlHours.toDouble(),
                        min: 24,
                        max: 120,
                        divisions: 4,
                        label: "$_deliveryAccessTtlHours",
                        onChanged: (v) =>
                            setState(() => _deliveryAccessTtlHours = v.round()),
                      ),
                      const SizedBox(height: 8),
                      const Text("เก็บ payload (วัน) | Payload retention (days)"),
                      Slider(
                        value: _payloadRetentionDays.toDouble(),
                        min: 7,
                        max: 180,
                        divisions: 173,
                        label: "$_payloadRetentionDays",
                        onChanged: (v) =>
                            setState(() => _payloadRetentionDays = v.round()),
                      ),
                      const SizedBox(height: 8),
                      const Text("เก็บ audit log (วัน) | Audit log retention (days)"),
                      Slider(
                        value: _auditLogRetentionDays.toDouble(),
                        min: 7,
                        max: 365,
                        divisions: 358,
                        label: "$_auditLogRetentionDays",
                        onChanged: (v) =>
                            setState(() => _auditLogRetentionDays = v.round()),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Private-first Mode",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "เลือก privacy preset ด้วยภาษาง่ายๆ แล้วระบบจะแปลงเป็นพฤติกรรม private-first ให้อัตโนมัติ",
                      ),
                      SwitchListTile(
                        value: _privateFirstMode,
                        onChanged: (v) => setState(() => _privateFirstMode = v),
                        title: const Text("Keep private-first mode enabled"),
                        subtitle: const Text(
                          "Prefer the stricter privacy posture between your settings and active policy.",
                        ),
                        contentPadding: EdgeInsets.zero,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "Privacy preset",
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      Column(
                        children: privacyProfilePresets.map((preset) {
                          final selected = preset.id == _selectedPresetId;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () => _applyPreset(preset.id),
                              child: Ink(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: selected
                                        ? Theme.of(context).colorScheme.primary
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
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(999),
                                              color: _badgeColor(preset),
                                            ),
                                            child: Text(
                                              preset.badgeLabel,
                                              style: const TextStyle(
                                                fontSize: 12,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Text(preset.summary),
                                      const SizedBox(height: 6),
                                      Text(
                                        preset.detail,
                                        style: Theme.of(
                                          context,
                                        ).textTheme.bodySmall,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 8),
                      Text(selectedPreset.summary),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: _saving
                    ? null
                    : () async {
                        final guardrailMessage = _productionGuardrailMessage();
                        if (guardrailMessage != null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(guardrailMessage)),
                          );
                          return;
                        }
                        setState(() => _saving = true);
                        final offsets = <int>[];
                        if (_offset14) offsets.add(14);
                        if (_offset7) offsets.add(7);
                        if (_offset1) offsets.add(1);
                        if (offsets.isEmpty) offsets.add(1);
                        final fallbackChannels = <String>[];
                        if (_fallbackEmail) fallbackChannels.add("email");
                        if (_fallbackSms) fallbackChannels.add("sms");
                        if (fallbackChannels.isEmpty) {
                          fallbackChannels.add("email");
                        }

                        final messenger = ScaffoldMessenger.of(context);
                        try {
                          await ref.read(safetySettingsProvider.notifier).save(
                                remindersEnabled: _remindersEnabled,
                                reminderOffsetsDays: offsets,
                                gracePeriodDays: _graceDays,
                                proofOfLifeCheckMode: _proofOfLifeCheckMode,
                                proofOfLifeFallbackChannels: fallbackChannels,
                                serverHeartbeatFallbackEnabled:
                                    _serverHeartbeatFallbackEnabled,
                                iosBackgroundRiskAcknowledged:
                                    _iosBackgroundRiskAcknowledged,
                                legalDisclaimerAccepted: _legalAccepted,
                                emergencyPauseUntil: _pause7Days
                                    ? DateTime.now().add(
                                        const Duration(days: 7),
                                      )
                                    : null,
                                requireTotpUnlock: _requireTotpUnlock,
                                guardianQuorumEnabled: _guardianQuorumEnabled,
                                guardianQuorumRequired: _guardianQuorumRequired,
                                guardianQuorumPoolSize: _guardianQuorumPoolSize,
                                emergencyAccessEnabled: _emergencyAccessEnabled,
                                emergencyAccessRequiresBeneficiaryRequest:
                                    _emergencyAccessRequiresBeneficiaryRequest,
                                emergencyAccessRequiresGuardianQuorum:
                                    _emergencyAccessRequiresGuardianQuorum,
                                emergencyAccessGraceHours:
                                    _emergencyAccessGraceHours,
                                deviceRebindInProgress: _deviceRebindInProgress,
                                deviceRebindStartedAt: _deviceRebindStartedAt,
                                deviceRebindGraceHours: _deviceRebindGraceHours,
                                recoveryKeyEnabled: _recoveryKeyEnabled,
                                deliveryAccessTtlHours: _deliveryAccessTtlHours,
                                payloadRetentionDays: _payloadRetentionDays,
                                auditLogRetentionDays: _auditLogRetentionDays,
                                privateFirstMode: _privateFirstMode,
                                tracePrivacyProfile:
                                    selectedPreset.tracePrivacyProfile,
                              );
                          if (!mounted) return;
                          messenger.showSnackBar(
                            const SnackBar(
                              content: Text(
                                "Safety settings updated successfully.",
                              ),
                            ),
                          );
                        } catch (_) {
                          if (!mounted) return;
                          messenger.showSnackBar(
                            const SnackBar(
                              content: Text(
                                "ยังบันทึกตั้งค่าไม่ได้ในตอนนี้ กรุณาลองใหม่ | We could not save safety settings right now. Please retry.",
                              ),
                            ),
                          );
                        } finally {
                          if (mounted) {
                            setState(() => _saving = false);
                          }
                        }
                      },
                child: Text(_saving ? "Saving..." : "Save Safety Settings"),
              ),
            ],
          );
        },
        loading: () => const Center(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 10),
                Text("กำลังโหลดตั้งค่าความปลอดภัย..."),
              ],
            ),
          ),
        ),
        error: (_, __) => Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "ยังโหลดตั้งค่าความปลอดภัยไม่ได้ในตอนนี้ กรุณาลองใหม่",
                ),
                const SizedBox(height: 10),
                OutlinedButton(
                  onPressed: () => ref.invalidate(safetySettingsProvider),
                  child: const Text("ลองใหม่ | Retry"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
