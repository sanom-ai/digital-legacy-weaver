import 'package:flutter/material.dart';
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
        _lockForCooldown(reason: "too many receipt code requests");
      }
      return;
    }
    _unlockFailures += 1;
    if (_unlockFailures >= _maxUnlockFailuresBeforeCooldown) {
      _lockForCooldown(reason: "too many unlock attempts");
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
      _message = "ตรวจพบข้อมูลรับมอบแล้ว | Handoff details detected. ขอรหัสยืนยันเพื่อทำต่อได้เลย";
    }

    final params = Uri.base.queryParameters;
    final accessId = (params["access_id"] ?? "").trim();
    final accessKey = (params["access_key"] ?? "").trim();
    if (accessId.isNotEmpty && _accessIdController.text.isEmpty) {
      _accessIdController.text = accessId;
    }
    if (accessKey.isNotEmpty && _accessKeyController.text.isEmpty) {
      _accessKeyController.text = accessKey;
      _message = "ตรวจพบข้อมูลรับมอบแล้ว | Handoff details detected. ขอรหัสยืนยันเพื่อทำต่อได้เลย";
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
    final pattern = RegExp('$key\\s*[:=]\\s*([^\\n\\r]+)', caseSensitive: false);
    final match = pattern.firstMatch(text);
    return match?.group(1)?.trim();
  }

  void _applyHandoffPacket() {
    final raw = _handoffCodeController.text.trim();
    if (raw.isEmpty) {
      setState(() {
        _messageIsError = true;
        _message = "วางชุดข้อมูลรับมอบก่อน | Paste the handoff packet first.";
      });
      return;
    }

    final accessId =
        _extractQueryValue(raw, "access_id") ?? _extractLineValue(raw, "access_id");
    final accessKey = _extractQueryValue(raw, "access_key") ??
        _extractLineValue(raw, "access_key");

    if ((accessId ?? "").isEmpty || (accessKey ?? "").isEmpty) {
      setState(() {
        _messageIsError = true;
        _message =
            "อ่าน Access ID + Access Key ไม่ได้ | Could not read Access ID + Access Key. ขอให้ญาติหรือพยานส่งข้อมูลทางการอีกครั้ง";
      });
      return;
    }

    setState(() {
      _accessIdController.text = accessId!;
      _accessKeyController.text = accessKey!;
      _messageIsError = false;
      _message =
          "ยืนยันชุดข้อมูลรับมอบแล้ว | Access ID และ Access Key ถูกกรอกให้อัตโนมัติ";
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
    });
    try {
      final response = await Supabase.instance.client.functions.invoke(
        "open-delivery-link",
        body: {
          "action": "request_code",
          "access_id": _accessIdController.text.trim(),
          "access_key": _accessKeyController.text.trim(),
        },
      );
      final data = response.data as Map<String, dynamic>?;
      setState(() {
        _message = (data?["message"] ?? "ส่งคำขอรหัสยืนยันแล้ว").toString();
        _messageIsError = false;
        _codeRequestAttempts = 0;
        _requestedCode = true;
      });
    } catch (e) {
      setState(() {
        _message = _friendlyActionError("requesting a receipt code", e);
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
      });
    } catch (e) {
      setState(() {
        _message = _friendlyActionError("opening the delivery bundle", e);
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
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Not the intended recipient?"),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "If this receipt was delivered to the wrong person, do not request codes or attempt to open the bundle.",
            ),
            SizedBox(height: 10),
            Text("1. Stop using the access link immediately."),
            SizedBox(height: 4),
            Text("2. Do not forward the link, code, or verification phrase."),
            SizedBox(height: 4),
            Text(
                "3. Contact the owner, guardian, operator, or designated partner so the route can be re-verified."),
            SizedBox(height: 4),
            Text(
                "4. Treat this receipt as confidential until the rightful recipient is confirmed."),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("Close"),
          ),
          FilledButton(
            onPressed: _busy || !_hasAccessLink
                ? null
                : () async {
                    Navigator.of(context).pop();
                    await _reportWrongRecipient();
                  },
            child: const Text("Report and pause receipt"),
          ),
        ],
      ),
    );
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
                "Receipt reported as wrong recipient. Access is paused pending re-verification.")
            .toString();
        _messageIsError = false;
        _codeController.clear();
        _totpController.clear();
        _beneficiaryNameController.clear();
        _verificationPhraseController.clear();
      });
    } catch (e) {
      setState(() {
        _message = _friendlyActionError("reporting wrong recipient", e);
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
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: complete ? const Color(0xFFE9F6EF) : const Color(0xFFF7F1E8),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: complete ? const Color(0xFF8BB89A) : const Color(0xFFE5D7C5),
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFEFE4D6),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(label),
    );
  }

  Widget _buildAntiScamChecklistCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE8C89A)),
      ),
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F7F7),
        borderRadius: BorderRadius.circular(14),
      ),
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
              labelText: "Handoff packet / message",
              helperText:
                  "รองรับรูปแบบ access_id=... และ access_key=... จากข้อความทางการ",
            ),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              onPressed: _busy ? null : _applyHandoffPacket,
              icon: const Icon(Icons.key_outlined),
              label: const Text("ใช้ชุดข้อมูลนี้"),
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
            "Security Notice | ข้อควรรู้ก่อนทำต่อ",
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          SizedBox(height: 6),
          Text("• แอปนี้ไม่ขอรหัสผ่าน ไม่ขอ PIN และไม่ขอให้โอนเงิน"),
          SizedBox(height: 4),
          Text("• อย่ากดลิงก์จากข้อความที่ไม่แน่ใจ แม้ชื่อจะคล้ายกัน"),
          SizedBox(height: 4),
          Text("• วิธีที่ถูกต้อง: เปิดแอป Digital Legacy Weaver เอง แล้วกรอกรหัสที่ได้รับ"),
          SizedBox(height: 4),
          Text("• หากยังไม่แน่ใจ ให้โทรยืนยันกับญาติ/พยานก่อนทุกครั้ง"),
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
    return "ทำรายการไม่สำเร็จในขณะนี้ กรุณาลองใหม่อีกครั้ง";
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

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFEFE4D6),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "สถานะปัจจุบัน | Current status",
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Text("ความคืบหน้า: $completedSteps/3 ขั้นตอน"),
          const SizedBox(height: 6),
          Text("สถานะ: $statusLabel"),
          const SizedBox(height: 6),
          Text(
            _lastAction == "none"
                ? "การทำงานล่าสุด: ยังไม่มีคำขอ"
                : "การทำงานล่าสุด: ${_lastAction.replaceAll("_", " ")}",
          ),
          if (_isTemporarilyLocked) ...[
            const SizedBox(height: 6),
            Text("เวลารอก่อนลองใหม่: ${_cooldownRemainingLabel()}"),
          ],
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: completedSteps / 3,
            minHeight: 8,
            borderRadius: BorderRadius.circular(999),
            backgroundColor: const Color(0xFFF7F1E8),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBanner() {
    if (_message == null) {
      return const SizedBox.shrink();
    }
    final color =
        _messageIsError ? const Color(0xFFFFF1F1) : const Color(0xFFE9F6EF);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_message!),
          if (_messageIsError && _networkIssue) ...[
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: _busy
                  ? null
                  : () async {
                      if (_lastAction == "request_code") {
                        await _requestCode();
                        return;
                      }
                      if (_lastAction == "unlock") {
                        await _unlock();
                      }
                    },
              child: const Text("ลองใหม่อีกครั้ง"),
            ),
          ],
        ],
      ),
    );
  }

  String _bundleSummary() {
    if (_items.isEmpty) {
      return "No delivery items have been opened yet.";
    }
    if (_items.length == 1) {
      return "1 delivery item is available in this receipt.";
    }
    return "${_items.length} delivery items are available in this receipt.";
  }

  String _kindLabel(String kind) {
    switch (kind.trim().toLowerCase()) {
      case "self_recovery":
        return "Self-recovery route";
      case "legacy":
      case "legacy_delivery":
        return "Legacy delivery route";
      case "archive_reference":
        return "Archive reference";
      default:
        return kind.isEmpty ? "Delivery item" : kind.replaceAll("_", " ");
    }
  }

  String _verificationRoute(String kind) {
    switch (kind.trim().toLowerCase()) {
      case "self_recovery":
        return "Verify the current recovery route directly with the designated provider or recovery service.";
      case "legacy":
      case "legacy_delivery":
        return "Verify the current holdings, balances, or legal status directly with the relevant partner, institution, or law office.";
      case "archive_reference":
        return "Verify the referenced archive with the designated partner or records custodian before acting on it.";
      default:
        return "Verify the latest status directly with the relevant partner, institution, or professional advisor.";
    }
  }

  String _visibilityLabel(String visibility) {
    switch (visibility) {
      case "existence_only":
        return "Existence only";
      case "route_and_instructions":
        return "Route and instructions";
      default:
        return "Route only";
    }
  }

  String _phaseLabel(String visibility) {
    switch (visibility) {
      case "existence_only":
        return "Phase 1: Existence confirmation";
      case "route_and_instructions":
        return "Phase 3: Route + instructions";
      default:
        return "Phase 2: Route verification";
    }
  }

  String _phaseActionCue(String visibility) {
    switch (visibility) {
      case "existence_only":
        return "Next: verify identity and wait for partner/operator confirmation.";
      case "route_and_instructions":
        return "Next: follow the instruction summary and verify with the destination partner.";
      default:
        return "Next: follow verification route with institution or legal partner.";
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
            title.isEmpty ? "Untitled delivery item" : title,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Text("Type: ${_kindLabel(kind)}"),
          const SizedBox(height: 6),
          Text("Post-trigger visibility: ${_visibilityLabel(visibility)}"),
          const SizedBox(height: 6),
          Text(
            _phaseLabel(visibility),
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Text(
            "Value disclosure: ${valueDisclosure == "hidden" ? "Hidden in receipt" : "Institution verified only"}",
          ),
          const SizedBox(height: 6),
          if (visibility == "existence_only")
            const Text(
              "This receipt confirms that a protected legacy route exists. Continue with recipient verification before route details are shown.",
            ),
          if (visibility == "route_only" ||
              visibility == "route_and_instructions")
            Text(
              "Verification route: ${item["verification_route"] ?? _verificationRoute(kind)}",
            ),
          if (visibility == "route_and_instructions" &&
              instructionSummary.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text("Instruction summary: $instructionSummary"),
          ],
          const SizedBox(height: 6),
          Text(_phaseActionCue(visibility)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("หน้ารับมอบผู้รับผลประโยชน์ | Beneficiary Receipt")),
      body: ListView(
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
                  _buildSecurityNoticeCard(),
                  const SizedBox(height: 12),
                  _buildAntiScamChecklistCard(),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF7F1E8),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "สิ่งที่ผู้รับควรเตรียม | What you need",
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        SizedBox(height: 6),
                        Text(
                            "1. ชุดข้อมูลรับมอบ (access_id / access_key) จากเจ้าของหรือผู้ดูแล"),
                        SizedBox(height: 4),
                        Text(
                            "2. รหัสยืนยันครั้งเดียวจากช่องทางที่ลงทะเบียนไว้"),
                        SizedBox(height: 4),
                        Text(
                            "3. ชื่อผู้รับที่ลงทะเบียนไว้ และวลียืนยันตัวตน"),
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
                      color: const Color(0xFFFFF7ED),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "ถ้าไม่ใช่ของคุณ | Not the intended recipient?",
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          "อย่าลองเดาหรือกดซ้ำหลายครั้ง ให้หยุดทันที แล้วตรวจสอบกับเจ้าของ/พยาน/ผู้ดูแลก่อนดำเนินการต่อ",
                        ),
                        const SizedBox(height: 10),
                        OutlinedButton(
                          onPressed: _showWrongRecipientDialog,
                          child: const Text("ไม่ใช่ของฉัน | This receipt is not mine"),
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
                        : "ขั้นตอนถัดไป: วาง handoff packet หรือกรอก Access ID/Access Key ให้ครบ",
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
                    decoration: const InputDecoration(
                      labelText: "Access ID (รหัสอ้างอิง)",
                      helperText:
                          "รหัสอ้างอิงจากข้อมูลรับมอบของเจ้าของ",
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _accessKeyController,
                    onChanged: (_) => setState(() {}),
                    obscureText: _obscureAccessKey,
                    decoration: InputDecoration(
                      labelText: "Access Key (กุญแจรับมอบ)",
                      helperText:
                          "เก็บเป็นความลับ ห้ามส่งต่อเหมือนโทเค็นปลอดภัย",
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
                          child: const Text("ขอรหัสยืนยัน | Request code"),
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
                        color: const Color(0xFFE9F6EF),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        "ส่งรหัสแล้ว ตรวจช่องทางที่ลงทะเบียนไว้ แล้วกลับมาปลดล็อกต่อได้เลย",
                      ),
                    ),
                  ],
                  const SizedBox(height: 10),
                  TextField(
                    controller: _codeController,
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                      labelText: "รหัสยืนยัน | Verification code",
                      helperText:
                          "รหัสครั้งเดียวจากช่องทางสำรองที่เปิดใช้งาน",
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _beneficiaryNameController,
                    onChanged: (_) => setState(() {}),
                    autofillHints: const [AutofillHints.name],
                    decoration: const InputDecoration(
                      labelText: "ชื่อผู้รับที่ลงทะเบียนไว้",
                      helperText:
                          "ต้องตรงกับข้อมูลที่เจ้าของตั้งไว้",
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _verificationPhraseController,
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                      labelText: "วลียืนยันตัวตน",
                      helperText:
                          "วลีที่แชร์กันไว้ตอนตั้งค่า ใช้ตรวจสอบก่อนเปิดข้อมูล",
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _totpController,
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                      labelText: "รหัส TOTP (ถ้าระบบร้องขอ)",
                      helperText:
                          "กรอกเฉพาะเมื่อระบบแจ้งว่าต้องมีขั้นยืนยันเพิ่ม",
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _canUnlock ? _unlock : null,
                      child:
                          Text(_busy ? "กำลังดำเนินการ..." : "เปิดชุดรับมอบ | Open bundle"),
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
                      color: const Color(0xFFEFE4D6),
                      borderRadius: BorderRadius.circular(14),
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
                      "Delivery Bundle Receipt",
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
                            "Receipt status",
                            "Opened",
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildReceiptMetric(
                            "Total items",
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
                            "Phase 1",
                            _countByVisibility("existence_only").toString(),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildReceiptMetric(
                            "Phase 2",
                            _countByVisibility("route_only").toString(),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildReceiptMetric(
                            "Phase 3",
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
                            "Safe next steps",
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          SizedBox(height: 6),
                          Text(
                              "1. Review which delivery items were released before forwarding anything."),
                          SizedBox(height: 4),
                          Text(
                              "2. Keep the access link, receipt code, and verification phrase private."),
                          SizedBox(height: 4),
                          Text(
                              "3. Verify balances, legal status, or account details directly with the relevant partner, institution, or law office."),
                          SizedBox(height: 4),
                          Text(
                              "4. Complete any legal or service-specific verification outside this technical receipt flow."),
                          SizedBox(height: 4),
                          Text(
                              "5. If you think this receipt reached the wrong person, stop and re-verify the recipient path before sharing anything."),
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
