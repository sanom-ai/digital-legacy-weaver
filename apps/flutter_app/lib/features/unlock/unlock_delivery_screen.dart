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

  bool _busy = false;
  bool _obscureAccessKey = true;
  String? _message;
  List<Map<String, dynamic>> _items = const [];

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
      _message = "Access link detected. Request verification code to continue.";
    }

    final params = Uri.base.queryParameters;
    final accessId = (params["access_id"] ?? "").trim();
    final accessKey = (params["access_key"] ?? "").trim();
    if (accessId.isNotEmpty && _accessIdController.text.isEmpty) {
      _accessIdController.text = accessId;
    }
    if (accessKey.isNotEmpty && _accessKeyController.text.isEmpty) {
      _accessKeyController.text = accessKey;
      _message = "Access link detected. Request verification code to continue.";
    }
  }

  @override
  void dispose() {
    _accessIdController.dispose();
    _accessKeyController.dispose();
    _codeController.dispose();
    _totpController.dispose();
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
      setState(() => _message = (data?["message"] ?? "Verification code requested.").toString());
    } catch (e) {
      setState(() => _message = "Request code failed: $e");
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
        },
      );
      final data = response.data as Map<String, dynamic>?;
      final rawItems = (data?["items"] as List<dynamic>? ?? const []);
      setState(() {
        _message = "Unlock successful.";
        _items = rawItems.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      });
    } catch (e) {
      setState(() => _message = "Unlock failed: $e");
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Unlock Delivery")),
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
                    "Secure Access",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  const Text("Use access link values and verification code to unlock encrypted delivery bundle."),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _accessIdController,
                    decoration: const InputDecoration(labelText: "Access ID"),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _accessKeyController,
                    obscureText: _obscureAccessKey,
                    decoration: InputDecoration(
                      labelText: "Access Key",
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
                          onPressed: _busy ? null : _requestCode,
                          child: const Text("Request Code"),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _codeController,
                    decoration: const InputDecoration(labelText: "Verification Code"),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _totpController,
                    decoration: const InputDecoration(labelText: "TOTP Code (if required)"),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _busy ? null : _unlock,
                      child: Text(_busy ? "Working..." : "Unlock"),
                    ),
                  ),
                  if (_message != null) ...[
                    const SizedBox(height: 10),
                    Text(_message!),
                  ],
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
                      "Encrypted Bundle",
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    ..._items.map((item) {
                      final title = (item["title"] ?? "").toString();
                      final kind = (item["kind"] ?? "").toString();
                      final payload = (item["encrypted_payload"] ?? "").toString();
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(title.isEmpty ? "Untitled" : title),
                        subtitle: Text("kind: $kind\npayload: $payload"),
                      );
                    }),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
