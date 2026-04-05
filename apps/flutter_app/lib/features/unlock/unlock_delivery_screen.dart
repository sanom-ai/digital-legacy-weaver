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
  final _accessIdController = TextEditingController();
  final _accessKeyController = TextEditingController();
  final _codeController = TextEditingController();
  final _totpController = TextEditingController();
  final _beneficiaryNameController = TextEditingController();
  final _verificationPhraseController = TextEditingController();

  bool _busy = false;
  bool _obscureAccessKey = true;
  String? _message;
  List<Map<String, dynamic>> _items = const [];

  bool get _hasAccessLink =>
      _accessIdController.text.trim().isNotEmpty &&
      _accessKeyController.text.trim().isNotEmpty;

  bool get _hasIdentityKit =>
      _beneficiaryNameController.text.trim().isNotEmpty &&
      _verificationPhraseController.text.trim().isNotEmpty;

  bool get _hasVerificationCode => _codeController.text.trim().isNotEmpty;

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
        _message = "Access link detected. Request the receipt code to continue.";
    }

    final params = Uri.base.queryParameters;
    final accessId = (params["access_id"] ?? "").trim();
    final accessKey = (params["access_key"] ?? "").trim();
    if (accessId.isNotEmpty && _accessIdController.text.isEmpty) {
      _accessIdController.text = accessId;
    }
    if (accessKey.isNotEmpty && _accessKeyController.text.isEmpty) {
      _accessKeyController.text = accessKey;
      _message = "Access link detected. Request the receipt code to continue.";
    }
  }

  @override
  void dispose() {
    _accessIdController.dispose();
    _accessKeyController.dispose();
    _codeController.dispose();
    _totpController.dispose();
    _beneficiaryNameController.dispose();
    _verificationPhraseController.dispose();
    super.dispose();
  }

  Future<void> _requestCode() async {
    setState(() {
      _busy = true;
      _message = null;
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
      setState(() => _message = (data?["message"] ?? "Receipt code requested.").toString());
    } catch (e) {
      setState(() => _message = "Receipt code request failed: $e");
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _unlock() async {
    setState(() {
      _busy = true;
      _message = null;
      _items = const [];
    });
    try {
      final response = await Supabase.instance.client.functions.invoke(
        "open-delivery-link",
        body: {
          "action": "unlock",
          "access_id": _accessIdController.text.trim(),
          "access_key": _accessKeyController.text.trim(),
          "verification_code": _codeController.text.trim(),
          "totp_code": _totpController.text.trim().isEmpty ? null : _totpController.text.trim(),
          "beneficiary_name": _beneficiaryNameController.text.trim().isEmpty
              ? null
              : _beneficiaryNameController.text.trim(),
          "verification_phrase": _verificationPhraseController.text.trim().isEmpty
              ? null
              : _verificationPhraseController.text.trim(),
        },
      );
      final data = response.data as Map<String, dynamic>?;
      final rawItems = (data?["items"] as List<dynamic>? ?? const []);
      setState(() {
        _message = "Delivery bundle opened successfully.";
        _items = rawItems.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      });
    } catch (e) {
      setState(() => _message = "Delivery receipt could not be opened: $e");
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
            Text("3. Contact the owner, guardian, operator, or designated partner so the route can be re-verified."),
            SizedBox(height: 4),
            Text("4. Treat this receipt as confidential until the rightful recipient is confirmed."),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("Close"),
          ),
        ],
      ),
    );
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
                complete ? Icons.check_circle_outline : Icons.radio_button_unchecked,
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
      case "legacy_delivery":
        return "Verify the current holdings, balances, or legal status directly with the relevant partner, institution, or law office.";
      case "archive_reference":
        return "Verify the referenced archive with the designated partner or records custodian before acting on it.";
      default:
        return "Verify the latest status directly with the relevant partner, institution, or professional advisor.";
    }
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
          Text(
            "Verification route: ${_verificationRoute(kind)}",
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Beneficiary Receipt")),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Beneficiary Receipt Flow",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Open the secure delivery bundle from a handoff link. The beneficiary does not need to install the app first, but does need the owner-prepared identity details.",
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildPill("Secure web-link default"),
                      _buildPill("App optional"),
                      _buildPill("Pre-registered identity"),
                    ],
                  ),
                  const SizedBox(height: 14),
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
                          "What the beneficiary needs",
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        SizedBox(height: 6),
                        Text("1. The secure handoff link from the owner or operator."),
                        SizedBox(height: 4),
                        Text("2. A one-time receipt code from the registered fallback channel."),
                        SizedBox(height: 4),
                        Text("3. The registered beneficiary name and private verification phrase."),
                      ],
                    ),
                  ),
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
                          "Not the intended recipient?",
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          "Do not try to guess missing details or keep retrying. Stop here and re-verify the recipient path with the owner, guardian, operator, or designated partner first.",
                        ),
                        const SizedBox(height: 10),
                        OutlinedButton(
                          onPressed: _showWrongRecipientDialog,
                          child: const Text("This receipt is not mine"),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildJourneyStep(
                    title: "1. Confirm the access link",
                    body:
                        "Paste the Access ID and Access Key from the owner handoff link before requesting a verification code.",
                    complete: _hasAccessLink,
                    cue: _hasAccessLink
                        ? "Access link detected. You can request a code now."
                        : "Best next move: add both Access ID and Access Key.",
                  ),
                  _buildJourneyStep(
                    title: "2. Confirm your beneficiary identity",
                    body:
                        "Enter the same registered beneficiary name and verification phrase that were prepared during owner setup.",
                    complete: _hasIdentityKit,
                    cue: _hasIdentityKit
                        ? "Identity kit looks complete."
                        : "Best next move: add the registered beneficiary name and verification phrase.",
                  ),
                  _buildJourneyStep(
                    title: "3. Verify and unlock",
                    body:
                        "Request the one-time code, then unlock. Add the TOTP code only if the bundle requires it.",
                    complete: _hasVerificationCode,
                    cue: _hasVerificationCode
                        ? "Verification code is ready for unlock."
                        : "Best next move: request the verification code after the access link is ready.",
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _accessIdController,
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                      labelText: "Access ID",
                      helperText: "Delivery link identifier from the owner handoff.",
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _accessKeyController,
                    onChanged: (_) => setState(() {}),
                    obscureText: _obscureAccessKey,
                    decoration: InputDecoration(
                      labelText: "Access Key",
                      helperText: "Keep this private. Treat it like a secure handoff token.",
                      suffixIcon: IconButton(
                        onPressed: () => setState(() => _obscureAccessKey = !_obscureAccessKey),
                        icon: Icon(_obscureAccessKey ? Icons.visibility : Icons.visibility_off),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _busy || !_hasAccessLink ? null : _requestCode,
                          child: const Text("Request Receipt Code"),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _codeController,
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                      labelText: "Verification Code",
                      helperText: "One-time code sent through the active fallback channel.",
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _beneficiaryNameController,
                    onChanged: (_) => setState(() {}),
                    autofillHints: const [AutofillHints.name],
                    decoration: const InputDecoration(
                      labelText: "Registered beneficiary name",
                      helperText: "Must match the owner-prepared beneficiary record.",
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _verificationPhraseController,
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                      labelText: "Verification phrase",
                      helperText: "Shared phrase from setup. It is checked before the bundle can open.",
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _totpController,
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                      labelText: "TOTP Code (if required)",
                      helperText: "Only enter this if the bundle asks for an extra authenticator step.",
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _busy || !_hasAccessLink || !_hasIdentityKit || !_hasVerificationCode
                          ? null
                          : _unlock,
                      child: Text(_busy ? "Working..." : "Open Delivery Bundle"),
                    ),
                  ),
                  if (_message != null) ...[
                    const SizedBox(height: 10),
                    Text(_message!),
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
                          "Need help?",
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        SizedBox(height: 6),
                        Text(
                          "Legacy handoff now expects a pre-registered beneficiary name and verification phrase from owner setup before the bundle can open.",
                        ),
                        SizedBox(height: 6),
                        Text(
                          "If the first code does not arrive, use the owner-prepared fallback path such as email plus SMS and wait for the grace-period handoff instructions instead of retrying blindly.",
                        ),
                        SizedBox(height: 6),
                        Text(
                          "If you already use the app, this same receipt can later be upgraded into an app-guided experience. The secure link remains the default path.",
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
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Delivery Bundle Receipt",
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
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
                            "Items",
                            _items.length.toString(),
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
                          Text("1. Review which delivery items were released before forwarding anything."),
                          SizedBox(height: 4),
                          Text("2. Keep the access link, receipt code, and verification phrase private."),
                          SizedBox(height: 4),
                          Text("3. Verify balances, legal status, or account details directly with the relevant partner, institution, or law office."),
                          SizedBox(height: 4),
                          Text("4. Complete any legal or service-specific verification outside this technical receipt flow."),
                          SizedBox(height: 4),
                          Text("5. If you think this receipt reached the wrong person, stop and re-verify the recipient path before sharing anything."),
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
