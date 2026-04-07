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
  String _proofOfLifeCheckMode = "half_life_soft_checkin";
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
    final scheme = Theme.of(context).colorScheme;
    switch (preset.id) {
      case "confidential":
        return scheme.primaryContainer.withValues(alpha: 0.75);
      case "audit-heavy":
        return scheme.tertiaryContainer.withValues(alpha: 0.75);
      default:
        return scheme.surfaceContainerHighest;
    }
  }

  RoundedRectangleBorder _sectionCardShape() {
    final scheme = Theme.of(context).colorScheme;
    return RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.45)),
    );
  }

  InputDecoration _settingsFieldDecoration(String label) {
    final theme = Theme.of(context);
    return InputDecoration(
      labelText: label,
    ).applyDefaults(theme.inputDecorationTheme).copyWith(
          fillColor: theme.colorScheme.surfaceContainerHighest.withValues(
            alpha: 0.3,
          ),
        );
  }

  String? _productionGuardrailMessage() {
    final fallbackCount = <String>[
      if (_fallbackEmail) "email",
      if (_fallbackSms) "sms",
    ].length;

    if (!_legalAccepted) {
      return "กรุณายอมรับขอบเขตกฎหมายก่อนบันทึกการตั้งค่าความปลอดภัย";
    }
    if (fallbackCount < 2) {
      return "กรุณาเปิดช่องทางสำรองทั้ง Email และ SMS ก่อนบันทึกค่าที่จะใช้จริง";
    }
    if (!_serverHeartbeatFallbackEnabled) {
      return "กรุณาเปิด server heartbeat สำรอง เพื่อลดการทริกเกอร์ผิดพลาดจากข้อจำกัดการทำงานเบื้องหลังของมือถือ";
    }
    if (!_iosBackgroundRiskAcknowledged) {
      return "กรุณารับทราบข้อจำกัด iOS/background ก่อนบันทึกค่าที่จะใช้จริง";
    }
    if (_guardianQuorumEnabled && _guardianQuorumRequired < 2) {
      return "โหมดใช้งานจริงต้องกำหนดการอนุมัติร่วมอย่างน้อย 2 คน";
    }
    if (_guardianQuorumEnabled &&
        _guardianQuorumRequired > _guardianQuorumPoolSize) {
      return "จำนวนผู้อนุมัติที่ต้องการ ห้ามมากกว่าจำนวนกลุ่มผู้อนุมัติ";
    }
    if (_emergencyAccessEnabled &&
        !_emergencyAccessRequiresBeneficiaryRequest) {
      return "โหมดใช้งานจริงควรให้การเข้าถึงฉุกเฉินเริ่มจากคำขอของผู้รับ";
    }
    if (_emergencyAccessEnabled &&
        _emergencyAccessRequiresGuardianQuorum &&
        !_guardianQuorumEnabled) {
      return "เมื่อการเข้าถึงฉุกเฉินต้องใช้องค์ประชุมผู้ดูแล กรุณาเปิดโหมดอนุมัติร่วม";
    }
    if (_deliveryAccessTtlHours > 120) {
      return "โหมดใช้งานจริงควรกำหนดอายุลิงก์รับมอบไม่เกิน 120 ชั่วโมง";
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
                shape: _sectionCardShape(),
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
                        "หมายเหตุช่วงปิดเบตา: แอปนี้ช่วยประสานการส่งต่อสิทธิ์เข้าถึงอย่างปลอดภัย และไม่ทำหน้าที่ตัดสินทางกฎหมาย",
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
                shape: _sectionCardShape(),
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
                        title: const Text(
                            "เปิดการเตือนก่อนทริกเกอร์ | Enable pre-trigger reminders"),
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
                      const Text(
                          "การยืนยันว่ายังใช้งานอยู่ | Proof-of-life confirmation"),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        initialValue: _proofOfLifeCheckMode,
                        decoration: _settingsFieldDecoration(
                          "วิธีเช็กอิน | Check-in method",
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: "half_life_soft_checkin",
                            child: Text("Half-life soft check-in (แนะนำ)"),
                          ),
                          DropdownMenuItem(
                            value: "biometric_tap",
                            child: Text("Biometric tap (เข้มงวด)"),
                          ),
                          DropdownMenuItem(
                            value: "single_tap",
                            child: Text("Single tap (เบา)"),
                          ),
                          DropdownMenuItem(
                            value: "verification_code",
                            child: Text("Verification code (เข้มงวดมาก)"),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _proofOfLifeCheckMode = value);
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      const Text(
                          "ช่องทางสำรองสำหรับยืนยัน | Proof-of-life fallback channels"),
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
                      const Text(
                          "ช่วงหน่วงก่อนปล่อยจริง (วัน) | Final release grace period (days)"),
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
                        title: const Text(
                            "เปิด server heartbeat สำรอง | Enable server heartbeat fallback"),
                        subtitle: const Text(
                          "แนะนำสำหรับ iOS และกรณีที่แอปไม่ได้เปิดนาน เพราะการเช็กจากแอปอย่างเดียวอาจคลาดเคลื่อนได้",
                        ),
                        contentPadding: EdgeInsets.zero,
                      ),
                      CheckboxListTile(
                        value: _iosBackgroundRiskAcknowledged,
                        onChanged: (v) => setState(
                          () => _iosBackgroundRiskAcknowledged = v ?? false,
                        ),
                        title: const Text(
                            "รับทราบข้อจำกัด iOS/background | Acknowledge iOS/background limits"),
                        subtitle: const Text(
                          "ตัวจับเวลาแบบ dead-man บนมือถืออาจต้องใช้ heartbeat สำรอง เพื่อลดการทริกเกอร์ผิดพลาด",
                        ),
                        contentPadding: EdgeInsets.zero,
                      ),
                      SwitchListTile(
                        value: _pause7Days,
                        onChanged: (v) => setState(() => _pause7Days = v),
                        title: const Text(
                            "Kill Switch: พักการส่งมอบอัตโนมัติ 7 วัน"),
                        contentPadding: EdgeInsets.zero,
                      ),
                      SwitchListTile(
                        value: _requireTotpUnlock,
                        onChanged: (v) =>
                            setState(() => _requireTotpUnlock = v),
                        title: const Text(
                            "บังคับ TOTP ตอนปลดล็อก | Require TOTP at unlock"),
                        subtitle: const Text(
                          "เพิ่มการยืนยันชั้นที่สองให้เข้มขึ้น ก่อนแสดงรายละเอียดการส่งมอบ",
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
                        title: const Text(
                            "เปิดการอนุมัติร่วมก่อนปล่อย | Enable shared approval for release"),
                        subtitle: const Text(
                          "ค่าแนะนำเริ่มต้น: อนุมัติ 2 จาก 3 คน",
                        ),
                        contentPadding: EdgeInsets.zero,
                      ),
                      if (_guardianQuorumEnabled) ...[
                        DropdownButtonFormField<int>(
                          initialValue: _guardianQuorumPoolSize,
                          decoration: _settingsFieldDecoration(
                            "จำนวนคนในกลุ่มอนุมัติ | Approver group size",
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
                          decoration: _settingsFieldDecoration(
                            "จำนวนที่ต้องอนุมัติ | Required approvals",
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
                        "การเข้าถึงฉุกเฉินรองรับกรณีเจ้าของไม่พร้อมใช้งาน เช่น ICU หรือทำอุปกรณ์หาย โดยไม่ต้องรอรอบ dead-man เต็ม",
                      ),
                      SwitchListTile(
                        value: _emergencyAccessEnabled,
                        onChanged: (v) =>
                            setState(() => _emergencyAccessEnabled = v),
                        title: const Text(
                            "เปิดการเข้าถึงฉุกเฉิน | Enable emergency access"),
                        subtitle: const Text(
                          "ควรแยกเส้นทางนี้ออกจากการส่งต่อแบบปกติที่อิงการขาดการติดต่อ",
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
                          title: const Text(
                              "ต้องมีคำขอจากผู้รับ | Require beneficiary request"),
                          subtitle: const Text(
                            "แนะนำให้การเข้าถึงฉุกเฉินเริ่มจากคำขอที่ชัดเจนของผู้รับ",
                          ),
                          contentPadding: EdgeInsets.zero,
                        ),
                        CheckboxListTile(
                          value: _emergencyAccessRequiresGuardianQuorum,
                          onChanged: (v) => setState(
                            () => _emergencyAccessRequiresGuardianQuorum =
                                v ?? true,
                          ),
                          title: const Text(
                              "ต้องมีการอนุมัติร่วม | Require shared approval"),
                          subtitle: const Text(
                            "แนะนำเพื่อไม่ให้คนเดียวสามารถบังคับเปิดการเข้าถึงฉุกเฉินได้",
                          ),
                          contentPadding: EdgeInsets.zero,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                            "ระยะเวลารอก่อนเข้าถึงฉุกเฉิน (ชม.) | Emergency waiting window (hours)"),
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
                        "เริ่มช่วงย้ายอุปกรณ์ชั่วคราวก่อนย้ายเครื่อง ระบบจะหลีกเลี่ยงการปล่อยจริงในช่วงนี้เพื่อลดทริกเกอร์ผิดพลาด",
                      ),
                      SwitchListTile(
                        value: _deviceRebindInProgress,
                        onChanged: (v) {
                          setState(() {
                            _deviceRebindInProgress = v;
                            _deviceRebindStartedAt = v ? DateTime.now() : null;
                          });
                        },
                        title: const Text(
                            "กำลังย้ายอุปกรณ์ | Device rebind in progress"),
                        subtitle: const Text(
                          "ให้เปิดก่อนเปลี่ยนมือถือ เปลี่ยน passkey หรือปรับค่าชีวมิติ",
                        ),
                        contentPadding: EdgeInsets.zero,
                      ),
                      if (_deviceRebindStartedAt != null)
                        Text(
                          "เริ่มย้ายอุปกรณ์: ${_deviceRebindStartedAt!.toLocal()}",
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      const SizedBox(height: 8),
                      const Text(
                          "ช่วงผ่อนผันการย้าย (ชม.) | Rebind grace window (hours)"),
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
                        title: const Text(
                            "เปิด recovery key สำรอง | Enable recovery key fallback"),
                        subtitle: const Text(
                          "เก็บเส้นทาง recovery key แบบออฟไลน์ไว้ เผื่อการยืนยันสัญญาณชีพสะดุด",
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
                        "กำหนดระยะเวลาเก็บลิงก์รับมอบ ข้อมูลอ้างอิงที่ปลอดภัย และบันทึกตรวจสอบ",
                      ),
                      const SizedBox(height: 8),
                      const Text(
                          "อายุลิงก์เข้าถึง (ชม.) | Delivery access link TTL (hours)"),
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
                      const Text(
                          "เก็บ payload (วัน) | Payload retention (days)"),
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
                      const Text(
                          "เก็บ audit log (วัน) | Audit log retention (days)"),
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
                shape: _sectionCardShape(),
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
                                "บันทึกการตั้งค่าความปลอดภัยเรียบร้อยแล้ว",
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
                child: Text(
                    _saving ? "กำลังบันทึก..." : "บันทึกการตั้งค่าความปลอดภัย"),
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
