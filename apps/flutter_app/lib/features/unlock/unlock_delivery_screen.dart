import 'package:digital_legacy_weaver/core/config/app_config.dart';
import 'package:digital_legacy_weaver/core/widgets/app_feedback.dart';
import 'package:digital_legacy_weaver/core/widgets/app_state_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UnlockDeliveryScreen extends StatefulWidget {
  const UnlockDeliveryScreen({
    super.key,
    this.initialAccessId,
    this.initialAccessKey,
  });

  final String? initialAccessId;
  final String? initialAccessKey;

  @override
  State<UnlockDeliveryScreen> createState() => _UnlockDeliveryScreenState();
}

class _UnlockDeliveryScreenState extends State<UnlockDeliveryScreen> {
  static const int _maxCodeRequestsBeforeCooldown = 3;
  static const int _maxUnlockFailuresBeforeCooldown = 3;
  static const Duration _cooldownDuration = Duration(minutes: 10);

  final _accessIdController = TextEditingController();
  final _accessKeyController = TextEditingController();
  final _handoffCodeController = TextEditingController();
  final _codeController = TextEditingController();
  final _totpController = TextEditingController();
  final _beneficiaryNameController = TextEditingController();
  final _verificationPhraseController = TextEditingController();

  bool _busy = false;
  bool _obscureAccessKey = true;
  String? _message;
  bool _messageIsError = false;
  bool _networkIssue = false;
  bool _requestedCode = false;
  bool _unlockAttempted = false;
  String _lastAction = "none";
  List<Map<String, dynamic>> _items = const [];
  int _codeRequestAttempts = 0;
  int _unlockFailures = 0;
  DateTime? _lockedUntil;
  bool _receiptOpened = false;
  bool _antiScamChecklistAccepted = false;
  bool _guardianConfirmed = false;
  bool _closedBetaManualMode = AppConfig.closedBetaManualCodeEnabled;
  String? _manualVerificationCode;
  DateTime? _manualVerificationCodeExpiresAt;
  bool _openedFromExternalLink = false;

  bool get _hasAccessLink =>
      _accessIdController.text.trim().isNotEmpty &&
      _accessKeyController.text.trim().isNotEmpty;

  bool get _hasIdentityKit =>
      _beneficiaryNameController.text.trim().isNotEmpty &&
      _verificationPhraseController.text.trim().isNotEmpty;

  bool get _hasVerificationCode => _codeController.text.trim().isNotEmpty;

  bool get _isTemporarilyLocked =>
      _lockedUntil != null && DateTime.now().isBefore(_lockedUntil!);

  bool get _canRequestCode =>
      !_busy &&
      !_receiptOpened &&
      !_isTemporarilyLocked &&
      _hasAccessLink &&
      _antiScamChecklistAccepted &&
      _guardianConfirmed;

  bool get _manualModeEnabled =>
      AppConfig.closedBetaManualCodeEnabled && _closedBetaManualMode;

  bool get _canUnlock =>
      !_busy &&
      !_receiptOpened &&
      !_isTemporarilyLocked &&
      _hasAccessLink &&
      _hasIdentityKit &&
      _hasVerificationCode &&
      _antiScamChecklistAccepted &&
      _guardianConfirmed;

  String _cooldownRemainingLabel() {
    final until = _lockedUntil;
    if (until == null) {
      return "ไม่กี่นาที";
    }
    final remaining = until.difference(DateTime.now());
    if (remaining.inSeconds <= 0) {
      return "ไม่กี่นาที";
    }
    final minutes = remaining.inMinutes;
    if (minutes <= 1) {
      return "น้อยกว่า 1 นาที";
    }
    return "$minutes นาที";
  }

  void _maybeClearCooldown() {
    if (_lockedUntil != null && DateTime.now().isAfter(_lockedUntil!)) {
      _lockedUntil = null;
      _codeRequestAttempts = 0;
      _unlockFailures = 0;
    }
  }

  void _lockForCooldown({required String reason}) {
    _lockedUntil = DateTime.now().add(_cooldownDuration);
    _messageIsError = true;
    _message =
        "เพื่อความปลอดภัย ระบบล็อกชั่วคราว ${_cooldownDuration.inMinutes} นาที ($reason) กรุณาพักก่อนแล้วค่อยลองใหม่";
  }

  void _recordRiskyFailure(String action) {
    if (action == "request_code") {
      _codeRequestAttempts += 1;
      if (_codeRequestAttempts >= _maxCodeRequestsBeforeCooldown) {
        _lockForCooldown(reason: "ขอรหัสยืนยันถี่เกินไป");
      }
      return;
    }
    _unlockFailures += 1;
    if (_unlockFailures >= _maxUnlockFailuresBeforeCooldown) {
      _lockForCooldown(reason: "ลองปลดล็อกหลายครั้งเกินไป");
    }
  }

  @override
  void initState() {
    super.initState();
    final initAccessId = (widget.initialAccessId ?? "").trim();
    final initAccessKey = (widget.initialAccessKey ?? "").trim();
    if (initAccessId.isNotEmpty) {
      _accessIdController.text = initAccessId;
    }
    if (initAccessKey.isNotEmpty) {
      _accessKeyController.text = initAccessKey;
      _message = "ตรวจพบข้อมูลรับมอบแล้ว ขอรหัสยืนยันในแอปเพื่อทำต่อได้เลย";
    }

    final params = Uri.base.queryParameters;
    final linkHasCredentials = (params["access_id"] ?? "").trim().isNotEmpty ||
        (params["access_key"] ?? "").trim().isNotEmpty;
    if (linkHasCredentials) {
      _openedFromExternalLink = true;
      _messageIsError = true;
      _message =
          "เพื่อความปลอดภัย แอปจะไม่กรอก Access ID/Access Key อัตโนมัติจากลิงก์ กรุณาคัดลอกข้อมูลแล้วกรอกเองในหน้านี้เท่านั้น";
    }
  }

  @override
  void dispose() {
    _accessIdController.dispose();
    _accessKeyController.dispose();
    _handoffCodeController.dispose();
    _codeController.dispose();
    _totpController.dispose();
    _beneficiaryNameController.dispose();
    _verificationPhraseController.dispose();
    super.dispose();
  }

  String? _extractQueryValue(String text, String key) {
    final pattern = RegExp('$key=([^&\\s]+)', caseSensitive: false);
    final match = pattern.firstMatch(text);
    if (match == null) return null;
    return Uri.decodeComponent(match.group(1) ?? "").trim();
  }

  String? _extractLineValue(String text, String key) {
    final pattern =
        RegExp('$key\\s*[:=]\\s*([^\\n\\r]+)', caseSensitive: false);
    final match = pattern.firstMatch(text);
    return match?.group(1)?.trim();
  }

  void _applyHandoffPacket() {
    final raw = _handoffCodeController.text.trim();
    if (raw.isEmpty) {
      setState(() {
        _messageIsError = true;
        _message = "กรุณาวางชุดข้อมูลรับมอบก่อน";
      });
      return;
    }

    final accessId = _extractQueryValue(raw, "access_id") ??
        _extractLineValue(raw, "access_id");
    final accessKey = _extractQueryValue(raw, "access_key") ??
        _extractLineValue(raw, "access_key");

    if ((accessId ?? "").isEmpty || (accessKey ?? "").isEmpty) {
      setState(() {
        _messageIsError = true;
        _message =
            "ไม่พบ Access ID และ Access Key ในข้อความนี้ กรุณาให้ญาติหรือพยานส่งข้อมูลทางการอีกครั้ง";
      });
      return;
    }

    setState(() {
      _accessIdController.text = accessId!;
      _accessKeyController.text = accessKey!;
      _messageIsError = false;
      _message =
          "ยืนยันชุดข้อมูลรับมอบแล้ว ระบบกรอก Access ID และ Access Key ให้อัตโนมัติ";
    });
  }

  Future<void> _requestCode() async {
    _maybeClearCooldown();
    if (_isTemporarilyLocked) {
      setState(() {
        _messageIsError = true;
        _message =
            "ชุดรับมอบนี้ถูกล็อกชั่วคราว กรุณารอ ${_cooldownRemainingLabel()} ก่อนขอรหัสใหม่";
      });
      return;
    }
    if (_receiptOpened) {
      setState(() {
        _messageIsError = true;
        _message =
            "ชุดรับมอบนี้ถูกเปิดแล้ว หากต้องการเข้าถึงอีกครั้ง กรุณาขอรอบรับมอบใหม่จากเจ้าของหรือผู้ดูแล";
      });
      return;
    }
    setState(() {
      _busy = true;
      _message = null;
      _networkIssue = false;
      _lastAction = "request_code";
      _manualVerificationCode = null;
      _manualVerificationCodeExpiresAt = null;
    });
    try {
      final action =
          _manualModeEnabled ? "request_code_manual" : "request_code";
      final response = await Supabase.instance.client.functions.invoke(
        "open-delivery-link",
        body: {
          "action": action,
          "access_id": _accessIdController.text.trim(),
          "access_key": _accessKeyController.text.trim(),
        },
      );
      final data = response.data as Map<String, dynamic>?;
      final manualCode = (data?["manual_code"] ?? "").toString().trim();
      final expiresAtRaw = (data?["expires_at"] ?? "").toString().trim();
      setState(() {
        _message = (data?["message"] ??
                (_manualModeEnabled
                    ? "สร้างรหัสทดสอบแบบปิดแล้ว กรุณาใช้ในแอปนี้เท่านั้น"
                    : "ส่งคำขอรหัสยืนยันแล้ว"))
            .toString();
        _messageIsError = false;
        _codeRequestAttempts = 0;
        _requestedCode = true;
        _manualVerificationCode = manualCode.isEmpty ? null : manualCode;
        _manualVerificationCodeExpiresAt =
            expiresAtRaw.isEmpty ? null : DateTime.tryParse(expiresAtRaw);
      });
    } catch (e) {
      setState(() {
        _message = _friendlyActionError("request_code", e);
        _messageIsError = true;
        _networkIssue = _looksLikeNetworkError(e.toString());
        final lower = e.toString().toLowerCase();
        if (lower.contains("invalid") ||
            lower.contains("unauthorized") ||
            lower.contains("forbidden")) {
          _recordRiskyFailure("request_code");
        }
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _unlock() async {
    _maybeClearCooldown();
    if (_isTemporarilyLocked) {
      setState(() {
        _messageIsError = true;
        _message =
            "ชุดรับมอบนี้ถูกล็อกชั่วคราว กรุณารอ ${_cooldownRemainingLabel()} ก่อนลองใหม่";
      });
      return;
    }
    if (_receiptOpened) {
      setState(() {
        _messageIsError = true;
        _message =
            "ชุดรับมอบนี้เคยถูกเปิดแล้ว เพื่อความปลอดภัย กรุณาขอรอบรับมอบใหม่จากเจ้าของหรือผู้ดูแล";
      });
      return;
    }
    setState(() {
      _busy = true;
      _message = null;
      _items = const [];
      _networkIssue = false;
      _unlockAttempted = true;
      _lastAction = "unlock";
    });
    try {
      final response = await Supabase.instance.client.functions.invoke(
        "open-delivery-link",
        body: {
          "action": "unlock",
          "access_id": _accessIdController.text.trim(),
          "access_key": _accessKeyController.text.trim(),
          "verification_code": _codeController.text.trim(),
          "totp_code": _totpController.text.trim().isEmpty
              ? null
              : _totpController.text.trim(),
          "beneficiary_name": _beneficiaryNameController.text.trim().isEmpty
              ? null
              : _beneficiaryNameController.text.trim(),
          "verification_phrase":
              _verificationPhraseController.text.trim().isEmpty
                  ? null
                  : _verificationPhraseController.text.trim(),
        },
      );
      final data = response.data as Map<String, dynamic>?;
      final rawItems = (data?["items"] as List<dynamic>? ?? const []);
      setState(() {
        _message = "เปิดชุดรับมอบสำเร็จแล้ว";
        _messageIsError = false;
        _items =
            rawItems.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        _unlockFailures = 0;
        _codeRequestAttempts = 0;
        _receiptOpened = true;
        _manualVerificationCode = null;
        _manualVerificationCodeExpiresAt = null;
      });
    } catch (e) {
      setState(() {
        _message = _friendlyActionError("unlock", e);
        _messageIsError = true;
        _networkIssue = _looksLikeNetworkError(e.toString());
        final lower = e.toString().toLowerCase();
        if (lower.contains("invalid") ||
            lower.contains("unauthorized") ||
            lower.contains("forbidden")) {
          _recordRiskyFailure("unlock");
        }
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _showWrongRecipientDialog() async {
    if (_busy || !_hasAccessLink) {
      AppFeedback.showWarning(
        context,
        "กรุณากรอก Access ID และ Access Key ให้ครบก่อนแจ้งผู้รับไม่ตรง",
      );
      return;
    }

    final confirmed = await AppFeedback.confirmAction(
      context: context,
      title: "ยืนยันว่าไม่ใช่ผู้รับที่ถูกต้อง",
      message:
          "ระบบจะหยุดการเข้าถึงชุดรับมอบนี้ชั่วคราวเพื่อความปลอดภัย และให้รอยืนยันเส้นทางใหม่ ต้องการดำเนินการต่อใช่ไหม",
      confirmLabel: "ยืนยันและหยุดชุดรับมอบ",
      destructive: true,
      icon: Icons.gpp_bad_rounded,
    );
    if (!confirmed) return;

    await _reportWrongRecipient();
  }

  Future<void> _reportWrongRecipient() async {
    setState(() {
      _busy = true;
      _message = null;
      _items = const [];
      _networkIssue = false;
      _lastAction = "report_wrong_recipient";
    });
    try {
      final response = await Supabase.instance.client.functions.invoke(
        "open-delivery-link",
        body: {
          "action": "report_wrong_recipient",
          "access_id": _accessIdController.text.trim(),
          "access_key": _accessKeyController.text.trim(),
        },
      );
      final data = response.data as Map<String, dynamic>?;
      setState(() {
        _message = (data?["message"] ??
                "แจ้งว่าไม่ใช่ผู้รับเรียบร้อยแล้ว ระบบหยุดการเข้าถึงชั่วคราวเพื่อรอยืนยันใหม่")
            .toString();
        _messageIsError = false;
        _codeController.clear();
        _totpController.clear();
        _beneficiaryNameController.clear();
        _verificationPhraseController.clear();
        _manualVerificationCode = null;
        _manualVerificationCodeExpiresAt = null;
      });
    } catch (e) {
      setState(() {
        _message = _friendlyActionError("report_wrong_recipient", e);
        _messageIsError = true;
        _networkIssue = _looksLikeNetworkError(e.toString());
      });
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Widget _buildJourneyStep({
    required String title,
    required String body,
    required bool complete,
    String? cue,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: complete
            ? scheme.tertiaryContainer.withValues(alpha: 0.45)
            : scheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: complete
              ? scheme.tertiary.withValues(alpha: 0.8)
              : scheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                complete
                    ? Icons.check_circle_outline
                    : Icons.radio_button_unchecked,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(body),
          if (cue != null && cue.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              cue,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPill(String label) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Text(label),
    );
  }

  Widget _buildPanel({
    required Widget child,
    Color? color,
    Color? borderColor,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color ?? scheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: borderColor ?? scheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: child,
    );
  }

  InputDecoration _unlockInputDecoration({
    required String label,
    String? helper,
    Widget? suffixIcon,
  }) {
    final theme = Theme.of(context);
    return InputDecoration(
      labelText: label,
      helperText: helper,
      suffixIcon: suffixIcon,
    ).applyDefaults(theme.inputDecorationTheme).copyWith(
          fillColor: theme.colorScheme.surfaceContainerHighest.withValues(
            alpha: 0.3,
          ),
        );
  }

  Widget _buildAntiScamChecklistCard() {
    return _buildPanel(
      color: const Color(0xFFFFF7ED),
      borderColor: const Color(0xFFE8C89A),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.verified_user_outlined),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  "เช็กความปลอดภัยก่อนทำต่อ",
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            "ระบบจะไม่โทรหรือส่งข้อความเพื่อขอรหัสผ่าน วลียืนยัน หรือขอให้โอนเงิน",
          ),
          const SizedBox(height: 8),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            value: _antiScamChecklistAccepted,
            onChanged: (value) {
              setState(() {
                _antiScamChecklistAccepted = value ?? false;
              });
            },
            title: const Text(
              "ฉันเข้าใจว่า flow นี้ไม่มีการโอนเงิน และไม่มีการขอรหัสผ่านทางโทรศัพท์",
            ),
          ),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            value: _guardianConfirmed,
            onChanged: (value) {
              setState(() {
                _guardianConfirmed = value ?? false;
              });
            },
            title: const Text(
              "ฉันได้ยืนยันกับญาติหรือพยานแล้วว่าการรับมอบนี้ถูกต้อง",
            ),
          ),
          if (!_antiScamChecklistAccepted || !_guardianConfirmed)
            const Text(
              "ต้องติ๊กครบทั้ง 2 ข้อก่อน จึงจะขอรหัสและปลดล็อกได้",
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
        ],
      ),
    );
  }

  Widget _buildHandoffPacketCard() {
    return _buildPanel(
      color: const Color(0xFFF2F7F7),
      borderColor: const Color(0xFFCCE5E5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "ทางเลือกปลอดภัยแบบไม่ต้องกดลิงก์ (แนะนำ)",
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          const Text(
            "วางข้อความหรือชุดข้อมูลรับมอบจากครอบครัว แล้วแอปจะอ่าน Access ID / Access Key ให้อัตโนมัติ โดยไม่ต้องเปิดลิงก์ที่ไม่แน่ใจ",
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _handoffCodeController,
            minLines: 2,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: "วางชุดข้อมูลรับมอบ (ไม่ต้องกดลิงก์)",
              helperText:
                  "รองรับรูปแบบ access_id=... และ access_key=... จากข้อความทางการ",
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            "ไม่ต้องกดลิงก์จากข้อความ ให้เปิดแอปเอง แล้ววาง packet หรือกรอกรหัสในหน้านี้เท่านั้น",
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              onPressed: _busy ? null : _applyHandoffPacket,
              icon: const Icon(Icons.key_outlined),
              label: const Text("ใช้ข้อมูลชุดนี้"),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityNoticeCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF6F6),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFB7DCDD)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "ข้อควรรู้ก่อนทำต่อ",
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          SizedBox(height: 6),
          Text("• แอปนี้ไม่ขอรหัสผ่าน ไม่ขอ PIN และไม่ขอให้โอนเงิน"),
          SizedBox(height: 4),
          Text("• อย่ากดลิงก์จากข้อความที่ไม่แน่ใจ แม้ชื่อจะคล้ายกัน"),
          SizedBox(height: 4),
          Text(
              "• วิธีที่ถูกต้อง: เปิดแอป Digital Legacy Weaver เอง แล้วกรอกรหัสที่ได้รับ"),
          SizedBox(height: 4),
          Text("• หากยังไม่แน่ใจ ให้โทรยืนยันกับญาติ/พยานก่อนทุกครั้ง"),
        ],
      ),
    );
  }

  String _manualCodeExpiryLabel() {
    final expiresAt = _manualVerificationCodeExpiresAt;
    if (expiresAt == null) {
      return "ใช้ทันทีภายในแอปนี้ แล้วขอใหม่เมื่อหมดเวลา";
    }
    final local = expiresAt.toLocal();
    final minute = local.minute.toString().padLeft(2, "0");
    return "รหัสนี้หมดอายุเวลา ${local.hour}:$minute";
  }

  Future<void> _copyManualCode() async {
    final code = (_manualVerificationCode ?? "").trim();
    if (code.isEmpty) {
      return;
    }
    await Clipboard.setData(ClipboardData(text: code));
    if (!mounted) return;
    AppFeedback.showSuccess(
      context,
      "คัดลอกรหัสทดสอบแล้ว ใช้วางในช่องรหัสยืนยันของหน้านี้เท่านั้น",
    );
  }

  Widget _buildClosedBetaModeCard() {
    if (!AppConfig.closedBetaManualCodeEnabled) {
      return const SizedBox.shrink();
    }
    return _buildPanel(
      color: const Color(0xFFF0F8FF),
      borderColor: const Color(0xFFBFDDF7),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "โหมดทดสอบปิด (Closed beta)",
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          const Text(
            "ใช้โหมดนี้เมื่อต้องทดสอบกับผู้ใช้จริงแบบไม่พึ่งอีเมล production ระบบจะคืนรหัสแบบใช้ครั้งเดียวให้ในแอปนี้เท่านั้น",
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _closedBetaManualMode,
            onChanged: _busy
                ? null
                : (value) {
                    setState(() {
                      _closedBetaManualMode = value;
                      _manualVerificationCode = null;
                      _manualVerificationCodeExpiresAt = null;
                    });
                  },
            title: const Text("เปิดใช้ manual code path"),
            subtitle: const Text("ปิดไว้เมื่อทดสอบผ่านอีเมลปกติ"),
          ),
          if (_closedBetaManualMode) ...[
            const SizedBox(height: 6),
            const Text(
              "ข้อกำหนด: รหัสทดสอบต้องส่งต่อผ่านช่องทางที่นัดหมายล่วงหน้าเท่านั้น และห้ามแชร์ในที่สาธารณะ",
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildManualCodeResultCard() {
    final code = (_manualVerificationCode ?? "").trim();
    if (code.isEmpty) {
      return const SizedBox.shrink();
    }
    return _buildPanel(
      color: const Color(0xFFEAF9F3),
      borderColor: const Color(0xFFB8E2CF),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.key_rounded),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  "รหัสยืนยันสำหรับ Closed beta",
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SelectableText(
            code,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              letterSpacing: 4,
            ),
          ),
          const SizedBox(height: 6),
          Text(_manualCodeExpiryLabel()),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: _copyManualCode,
                icon: const Icon(Icons.copy_rounded),
                label: const Text("คัดลอกรหัส"),
              ),
              OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    _manualVerificationCode = null;
                    _manualVerificationCodeExpiresAt = null;
                  });
                },
                icon: const Icon(Icons.clear_rounded),
                label: const Text("ซ่อนรหัส"),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReceiverFirstMessageCard() {
    return _buildPanel(
      color: const Color(0xFFFFF8EF),
      borderColor: const Color(0xFFE6D0AA),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "ข้อความแรกที่ควรเห็น",
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          SizedBox(height: 6),
          Text(
            "คุณได้รับการแจ้งเตือนนี้ตามแผนที่เจ้าของตั้งไว้ล่วงหน้า",
          ),
          SizedBox(height: 4),
          Text(
            "ระบบจะไม่ขอข้อมูลลับ ไม่ขอรหัสผ่าน และไม่ขอให้โอนเงินในข้อความนี้",
          ),
          SizedBox(height: 4),
          Text(
            "วิธีที่ปลอดภัย: เปิดแอปเอง แล้วกรอกข้อมูลรับมอบที่ได้รับจากช่องทางที่ยืนยันไว้เท่านั้น",
          ),
          SizedBox(height: 4),
          Text(
            "ถ้ายังไม่แน่ใจ ให้ปรึกษาพยานหรือญาติก่อน ไม่ต้องรีบดำเนินการทันที",
          ),
        ],
      ),
    );
  }

  bool _looksLikeNetworkError(String text) {
    final lower = text.toLowerCase();
    return lower.contains("socketexception") ||
        lower.contains("failed host lookup") ||
        lower.contains("network") ||
        lower.contains("timed out");
  }

  String _friendlyActionError(String action, Object error) {
    final lower = error.toString().toLowerCase();
    final actionLabel = switch (action) {
      "request_code" => "การขอรหัสยืนยัน",
      "unlock" => "การเปิดชุดรับมอบ",
      "report_wrong_recipient" => "การแจ้งผู้รับไม่ตรง",
      _ => "การทำรายการนี้",
    };
    if (lower.contains("temporarily locked")) {
      return "ระบบล็อกชั่วคราวเพื่อความปลอดภัย หลังกรอกผิดหลายครั้ง กรุณารอสักครู่แล้วลองใหม่";
    }
    if (lower.contains("already active for this receipt")) {
      return "มีรหัสยืนยันที่ยังใช้งานอยู่แล้ว ใช้รหัสเดิมหรือรอหมดอายุก่อนขอใหม่";
    }
    if (lower.contains("already been used")) {
      return "ชุดรับมอบแบบครั้งเดียวนี้ถูกใช้ไปแล้ว กรุณาขอรอบรับมอบใหม่จากเจ้าของหรือผู้ดูแล";
    }
    if (_looksLikeNetworkError(error.toString())) {
      return "เครือข่ายไม่เสถียร จึงทำรายการไม่สำเร็จ กรุณาตรวจสอบอินเทอร์เน็ตแล้วลองใหม่";
    }
    if (lower.contains("invalid") ||
        lower.contains("unauthorized") ||
        lower.contains("forbidden")) {
      return "ทำรายการต่อไม่ได้ กรุณาตรวจสอบ Access ID, Access Key และข้อมูลผู้รับ แล้วลองใหม่";
    }
    return "$actionLabel ยังไม่สำเร็จในขณะนี้ กรุณาลองใหม่อีกครั้ง";
  }

  Widget _buildStatusCard() {
    final completedSteps = <bool>[
      _hasAccessLink,
      _hasIdentityKit,
      _hasVerificationCode,
    ].where((step) => step).length;
    final statusLabel = _busy
        ? "กำลังดำเนินการ"
        : _isTemporarilyLocked
            ? "ล็อกชั่วคราวเพื่อความปลอดภัย"
            : _items.isNotEmpty
                ? "เปิดชุดรับมอบแล้ว"
                : _networkIssue
                    ? "ออฟไลน์หรือสัญญาณไม่เสถียร"
                    : "กำลังเตรียมข้อมูล";

    return _buildPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "สถานะปัจจุบัน",
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Text("ความคืบหน้า: $completedSteps/3 ขั้นตอน"),
          const SizedBox(height: 6),
          Text("สถานะ: $statusLabel"),
          const SizedBox(height: 6),
          Text("การทำงานล่าสุด: ${_lastActionLabel()}"),
          if (_isTemporarilyLocked) ...[
            const SizedBox(height: 6),
            Text("เวลารอก่อนลองใหม่: ${_cooldownRemainingLabel()}"),
          ],
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: completedSteps / 3,
            minHeight: 8,
            borderRadius: BorderRadius.circular(999),
            backgroundColor: Theme.of(context)
                .colorScheme
                .surfaceContainerHighest
                .withValues(alpha: 0.65),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBanner() {
    if (_message == null) {
      return const SizedBox.shrink();
    }
    return AppStatePanel(
      message: _message!,
      tone: _messageIsError
          ? (_networkIssue ? AppStateTone.offline : AppStateTone.error)
          : AppStateTone.success,
      actionLabel: _messageIsError && _networkIssue ? "ลองใหม่อีกครั้ง" : null,
      onAction: _messageIsError && _networkIssue
          ? () async {
              if (_busy) return;
              if (_lastAction == "request_code") {
                await _requestCode();
                return;
              }
              if (_lastAction == "unlock") {
                await _unlock();
              }
            }
          : null,
    );
  }

  String _bundleSummary() {
    if (_items.isEmpty) {
      return "ยังไม่มีรายการที่เปิดรับมอบในรอบนี้";
    }
    if (_items.length == 1) {
      return "มี 1 รายการที่เปิดรับมอบแล้ว";
    }
    return "มี ${_items.length} รายการที่เปิดรับมอบแล้ว";
  }

  String _lastActionLabel() {
    return switch (_lastAction) {
      "none" => "ยังไม่มีคำขอ",
      "request_code" => "ขอรหัสยืนยัน",
      "unlock" => "เปิดชุดรับมอบ",
      "report_wrong_recipient" => "แจ้งผู้รับไม่ตรง",
      _ => "กำลังทำรายการ",
    };
  }

  String _kindLabel(String kind) {
    switch (kind.trim().toLowerCase()) {
      case "self_recovery":
        return "เส้นทางกู้คืนด้วยตัวเอง";
      case "legacy":
      case "legacy_delivery":
        return "เส้นทางส่งมอบมรดกดิจิทัล";
      case "archive_reference":
        return "รายการอ้างอิงเอกสาร";
      default:
        return kind.isEmpty ? "รายการรับมอบ" : kind.replaceAll("_", " ");
    }
  }

  String _verificationRoute(String kind) {
    switch (kind.trim().toLowerCase()) {
      case "self_recovery":
        return "ตรวจสอบเส้นทางกู้คืนกับผู้ให้บริการหรือหน่วยงานที่ระบุไว้โดยตรง";
      case "legacy":
      case "legacy_delivery":
        return "ตรวจสอบยอด ทรัพย์สิน หรือสถานะทางกฎหมายกับพาร์ทเนอร์/สถาบัน/สำนักงานกฎหมายโดยตรง";
      case "archive_reference":
        return "ตรวจสอบแหล่งอ้างอิงกับพาร์ทเนอร์หรือผู้ดูแลเอกสารที่ระบุไว้ก่อนดำเนินการ";
      default:
        return "ตรวจสอบสถานะล่าสุดกับพาร์ทเนอร์ สถาบัน หรือผู้เชี่ยวชาญที่เกี่ยวข้องโดยตรง";
    }
  }

  String _visibilityLabel(String visibility) {
    switch (visibility) {
      case "existence_only":
        return "ยืนยันการมีอยู่ของแผน";
      case "route_and_instructions":
        return "แสดงเส้นทางและคำแนะนำ";
      default:
        return "แสดงเส้นทาง";
    }
  }

  String _phaseLabel(String visibility) {
    switch (visibility) {
      case "existence_only":
        return "เฟส 1: ยืนยันการมีอยู่ของแผน";
      case "route_and_instructions":
        return "เฟส 3: เส้นทาง + คำแนะนำ";
      default:
        return "เฟส 2: ยืนยันเส้นทาง";
    }
  }

  String _phaseActionCue(String visibility) {
    switch (visibility) {
      case "existence_only":
        return "ถัดไป: ยืนยันตัวตน และรอพาร์ทเนอร์/ผู้ดูแลยืนยัน";
      case "route_and_instructions":
        return "ถัดไป: ทำตามคำแนะนำสรุป และยืนยันกับพาร์ทเนอร์ปลายทาง";
      default:
        return "ถัดไป: ทำตามเส้นทางยืนยันกับสถาบันหรือพาร์ทเนอร์กฎหมาย";
    }
  }

  int _countByVisibility(String visibility) {
    return _items
        .where((item) =>
            (item["visibility_policy"] ?? "route_only").toString() ==
            visibility)
        .length;
  }

  Widget _buildReceiptMetric(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F1E8),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(value),
        ],
      ),
    );
  }

  Widget _buildReceiptItem(Map<String, dynamic> item) {
    final title = (item["title"] ?? "").toString();
    final kind = (item["kind"] ?? "").toString();
    final visibility = (item["visibility_policy"] ?? "route_only").toString();
    final valueDisclosure =
        (item["value_disclosure_mode"] ?? "institution_verified_only")
            .toString();
    final instructionSummary =
        (item["instruction_summary"] ?? "").toString().trim();
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F1E8),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.isEmpty ? "รายการรับมอบ (ยังไม่ตั้งชื่อ)" : title,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Text("ประเภทรายการ: ${_kindLabel(kind)}"),
          const SizedBox(height: 6),
          Text("ระดับข้อมูลหลังเข้าเงื่อนไข: ${_visibilityLabel(visibility)}"),
          const SizedBox(height: 6),
          Text(
            _phaseLabel(visibility),
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Text(
            "ระดับการเปิดเผยมูลค่า: ${valueDisclosure == "hidden" ? "ซ่อนไว้ในใบรับมอบ" : "ตรวจที่สถาบันเท่านั้น"}",
          ),
          const SizedBox(height: 6),
          if (visibility == "existence_only")
            const Text(
              "ใบรับมอบนี้ยืนยันว่ามีเส้นทางที่ถูกปกป้องอยู่ กรุณายืนยันผู้รับให้ครบก่อนดูรายละเอียดเส้นทาง",
            ),
          if (visibility == "route_only" ||
              visibility == "route_and_instructions")
            Text(
              "เส้นทางการยืนยัน: ${item["verification_route"] ?? _verificationRoute(kind)}",
            ),
          if (visibility == "route_and_instructions" &&
              instructionSummary.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text("สรุปคำแนะนำ: $instructionSummary"),
          ],
          const SizedBox(height: 6),
          Text(_phaseActionCue(visibility)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text("หน้ารับมอบของผู้รับผลประโยชน์")),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
        children: [
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                  color: scheme.outlineVariant.withValues(alpha: 0.45)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "ขั้นตอนรับมอบสำหรับผู้รับผลประโยชน์",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "คุณไม่ต้องรีบและไม่ต้องกดลิงก์ทันที เปิดแอปเองแล้วใช้ข้อมูลที่เจ้าของเตรียมไว้ล่วงหน้าเพื่อยืนยันตัวตนอย่างปลอดภัย",
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildPill("เปิดแอปเองก่อน"),
                      _buildPill("ไม่ขอเงิน/ไม่ขอรหัสผ่าน"),
                      _buildPill("ยืนยันตัวตนที่ลงทะเบียนไว้"),
                      _buildPill("ล็อกชั่วคราวเมื่อเสี่ยง"),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _buildReceiverFirstMessageCard(),
                  const SizedBox(height: 12),
                  _buildSecurityNoticeCard(),
                  if (_openedFromExternalLink) ...[
                    const SizedBox(height: 12),
                    _buildPanel(
                      color: const Color(0xFFFFF3EE),
                      borderColor: const Color(0xFFF1BEAF),
                      child: const Text(
                        "ตรวจพบว่าหน้านี้ถูกเปิดจากลิงก์ภายนอก กรุณาอย่าดำเนินการจากลิงก์โดยตรง ให้กรอก Access ID และ Access Key ด้วยตัวเองในแอปเท่านั้น",
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  _buildAntiScamChecklistCard(),
                  const SizedBox(height: 12),
                  _buildClosedBetaModeCard(),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color:
                          scheme.surfaceContainerHighest.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: scheme.outlineVariant.withValues(alpha: 0.45),
                      ),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "สิ่งที่ผู้รับควรเตรียม",
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        SizedBox(height: 6),
                        Text(
                            "1. ชุดข้อมูลรับมอบ (access_id / access_key) จากเจ้าของหรือผู้ดูแล"),
                        SizedBox(height: 4),
                        Text(
                            "2. รหัสยืนยันครั้งเดียวจากช่องทางที่ลงทะเบียนไว้"),
                        SizedBox(height: 4),
                        Text("3. ชื่อผู้รับที่ลงทะเบียนไว้ และวลียืนยันตัวตน"),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildHandoffPacketCard(),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: scheme.primaryContainer.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: scheme.outlineVariant.withValues(alpha: 0.45),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "ถ้าไม่ใช่ของคุณ",
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          "อย่าลองเดาหรือกดซ้ำหลายครั้ง ให้หยุดทันที แล้วตรวจสอบกับเจ้าของ/พยาน/ผู้ดูแลก่อนดำเนินการต่อ",
                        ),
                        const SizedBox(height: 10),
                        OutlinedButton(
                          onPressed: _showWrongRecipientDialog,
                          child: const Text("ไม่ใช่ของฉัน"),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildJourneyStep(
                    title: "1) ยืนยันข้อมูลรับมอบ",
                    body:
                        "ใช้ชุดข้อมูลแบบไม่ต้องกดลิงก์ก่อน หรือวาง Access ID และ Access Key จากข้อความที่เจ้าของยืนยันแล้ว",
                    complete: _hasAccessLink,
                    cue: _hasAccessLink
                        ? "พบข้อมูลรับมอบแล้ว ขอรหัสยืนยันได้ทันที"
                        : "ขั้นตอนถัดไป: วางชุดข้อมูลรับมอบ หรือกรอก Access ID/Access Key ให้ครบ",
                  ),
                  _buildJourneyStep(
                    title: "2) ยืนยันตัวตนผู้รับ",
                    body:
                        "กรอกชื่อผู้รับและวลียืนยันตัวตนที่เจ้าของตั้งไว้ล่วงหน้าให้ตรงกัน",
                    complete: _hasIdentityKit,
                    cue: _hasIdentityKit
                        ? "ข้อมูลยืนยันตัวตนครบแล้ว"
                        : "ขั้นตอนถัดไป: กรอกชื่อผู้รับและวลียืนยันให้ครบ",
                  ),
                  _buildJourneyStep(
                    title: "3) ขอรหัสและปลดล็อก",
                    body:
                        "ขอรหัสครั้งเดียวก่อน แล้วค่อยปลดล็อก หากระบบถาม TOTP ค่อยกรอกเพิ่ม",
                    complete: _hasVerificationCode || _items.isNotEmpty,
                    cue: _hasVerificationCode
                        ? "พร้อมปลดล็อกแล้ว"
                        : "ขั้นตอนถัดไป: ขอรหัสยืนยันหลังจากข้อมูลรับมอบครบ",
                  ),
                  _buildJourneyStep(
                    title: "4) ตรวจผลการรับมอบ",
                    body:
                        "หลังปลดล็อก ให้ตรวจเฟสการเปิดเผยข้อมูล และทำตามเส้นทางยืนยันกับปลายทางก่อนตัดสินใจ",
                    complete: _items.isNotEmpty,
                    cue: _items.isNotEmpty
                        ? "เปิดชุดรับมอบแล้ว ตรวจรายละเอียดด้านล่างได้เลย"
                        : _unlockAttempted
                            ? "มีการลองปลดล็อกแล้ว ตรวจข้อความตอบกลับก่อนลองใหม่"
                            : "ขั้นตอนถัดไป: ปลดล็อกหลังยืนยันรหัส",
                  ),
                  const SizedBox(height: 2),
                  _buildStatusCard(),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _accessIdController,
                    onChanged: (_) => setState(() {}),
                    decoration: _unlockInputDecoration(
                      label: "Access ID (รหัสอ้างอิง)",
                      helper: "รหัสอ้างอิงจากข้อมูลรับมอบของเจ้าของ",
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _accessKeyController,
                    onChanged: (_) => setState(() {}),
                    obscureText: _obscureAccessKey,
                    decoration: _unlockInputDecoration(
                      label: "Access Key (กุญแจรับมอบ)",
                      helper:
                          "ใช้เฉพาะในแอปนี้เท่านั้น ห้ามส่งต่อ และอย่าพิมพ์ลงโซเชียล/แชตสาธารณะ",
                      suffixIcon: IconButton(
                        onPressed: () => setState(
                            () => _obscureAccessKey = !_obscureAccessKey),
                        icon: Icon(_obscureAccessKey
                            ? Icons.visibility
                            : Icons.visibility_off),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _canRequestCode ? _requestCode : null,
                          child: Text(
                            _manualModeEnabled
                                ? "สร้างรหัสทดสอบในแอป"
                                : "ขอรหัสยืนยันในแอป",
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (!_antiScamChecklistAccepted || !_guardianConfirmed) ...[
                    const SizedBox(height: 8),
                    const Text(
                      "กรุณาเช็กความปลอดภัยและยืนยันกับพยานให้ครบก่อนจึงจะทำขั้นตอนนี้ได้",
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                  if (_requestedCode) ...[
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: scheme.tertiaryContainer.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: scheme.outlineVariant.withValues(alpha: 0.45),
                        ),
                      ),
                      child: Text(
                        _manualModeEnabled
                            ? "สร้างรหัสทดสอบในแอปแล้ว ใช้ต่อในหน้าจอนี้ได้ทันที โดยไม่ต้องพึ่งอีเมล production"
                            : "ส่งรหัสแล้ว ตรวจช่องทางที่ลงทะเบียนไว้ แล้วกลับมาปลดล็อกต่อได้เลย",
                      ),
                    ),
                  ],
                  if (_manualModeEnabled &&
                      _manualVerificationCode != null) ...[
                    const SizedBox(height: 10),
                    _buildManualCodeResultCard(),
                  ],
                  const SizedBox(height: 10),
                  TextField(
                    controller: _codeController,
                    onChanged: (_) => setState(() {}),
                    decoration: _unlockInputDecoration(
                      label: "รหัสยืนยัน",
                      helper: "รหัสครั้งเดียวจากช่องทางสำรองที่เปิดใช้งาน",
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _beneficiaryNameController,
                    onChanged: (_) => setState(() {}),
                    autofillHints: const [AutofillHints.name],
                    decoration: _unlockInputDecoration(
                      label: "ชื่อผู้รับที่ลงทะเบียนไว้",
                      helper: "ต้องตรงกับข้อมูลที่เจ้าของตั้งไว้",
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _verificationPhraseController,
                    onChanged: (_) => setState(() {}),
                    decoration: _unlockInputDecoration(
                      label: "วลียืนยันตัวตน",
                      helper:
                          "วลีที่แชร์กันไว้ตอนตั้งค่า ใช้ตรวจสอบก่อนเปิดข้อมูล",
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _totpController,
                    onChanged: (_) => setState(() {}),
                    decoration: _unlockInputDecoration(
                      label: "รหัส TOTP (ถ้าระบบร้องขอ)",
                      helper: "กรอกเฉพาะเมื่อระบบแจ้งว่าต้องมีขั้นยืนยันเพิ่ม",
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _canUnlock ? _unlock : null,
                      child:
                          Text(_busy ? "กำลังดำเนินการ..." : "เปิดชุดรับมอบ"),
                    ),
                  ),
                  if (_message != null) ...[
                    const SizedBox(height: 10),
                    _buildMessageBanner(),
                  ],
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainerHighest
                          .withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: scheme.outlineVariant.withValues(alpha: 0.45),
                      ),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "ต้องการความช่วยเหลือ?",
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        SizedBox(height: 6),
                        Text(
                          "การรับมอบต้องใช้ชื่อผู้รับและวลียืนยันที่ลงทะเบียนไว้ล่วงหน้าก่อนจึงจะเปิดข้อมูลได้",
                        ),
                        SizedBox(height: 6),
                        Text(
                          "วิธีที่ปลอดภัยกว่า: เปิดแอปเองแล้ววางชุดข้อมูลรับมอบ หลีกเลี่ยงลิงก์ที่ไม่แน่ใจ",
                        ),
                        SizedBox(height: 6),
                        Text(
                          "ถ้ายังไม่ได้รหัส ให้ใช้ช่องทางสำรองที่เจ้าของตั้งไว้ (เช่น Email + SMS) และรอคำแนะนำ อย่ากดซ้ำแบบเดาสุ่ม",
                        ),
                        SizedBox(height: 6),
                        Text(
                          "ถ้าคุณใช้แอปอยู่แล้ว สามารถทำ flow แบบแนะนำในแอปต่อได้ทันที",
                        ),
                        SizedBox(height: 6),
                        Text(
                          "หากเน็ตไม่เสถียร ให้หยุดก่อนและลองใหม่เมื่อสัญญาณดีขึ้น การกดซ้ำตอนเน็ตไม่ดีอาจถูกล็อกชั่วคราว",
                        ),
                        SizedBox(height: 6),
                        Text(
                          "หากกรอกผิดหลายครั้ง ระบบจะล็อกชั่วคราวเพื่อปกป้องทั้งเจ้าของและผู้รับ",
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (_items.isNotEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "ใบรับมอบข้อมูล",
                      style:
                          TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Text(_bundleSummary()),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildReceiptMetric(
                            "สถานะใบรับมอบ",
                            "เปิดแล้ว",
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildReceiptMetric(
                            "จำนวนรายการ",
                            _items.length.toString(),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _buildReceiptMetric(
                            "เฟส 1",
                            _countByVisibility("existence_only").toString(),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildReceiptMetric(
                            "เฟส 2",
                            _countByVisibility("route_only").toString(),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildReceiptMetric(
                            "เฟส 3",
                            _countByVisibility("route_and_instructions")
                                .toString(),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFE4D6),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "ขั้นตอนถัดไปที่ปลอดภัย",
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          SizedBox(height: 6),
                          Text(
                              "1. ตรวจก่อนว่ามีรายการใดถูกเปิดให้รับมอบแล้ว ก่อนส่งต่อข้อมูลใด ๆ"),
                          SizedBox(height: 4),
                          Text(
                              "2. เก็บลิงก์เข้าถึง รหัสรับมอบ และวลียืนยันเป็นความลับ"),
                          SizedBox(height: 4),
                          Text(
                              "3. ตรวจสอบยอด สถานะทางกฎหมาย หรือข้อมูลบัญชี กับพาร์ทเนอร์/สถาบัน/สำนักงานกฎหมายโดยตรง"),
                          SizedBox(height: 4),
                          Text(
                              "4. ขั้นตอนกฎหมายหรือเงื่อนไขบริการเฉพาะ ให้ดำเนินการนอกหน้าเทคนิครับมอบนี้"),
                          SizedBox(height: 4),
                          Text(
                              "5. หากสงสัยว่าส่งผิดคน ให้หยุดทันที และยืนยันเส้นทางผู้รับใหม่ก่อนแชร์ข้อมูล"),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    ..._items.map(_buildReceiptItem),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
