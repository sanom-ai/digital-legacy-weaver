import 'package:digital_legacy_weaver/core/providers/supabase_provider.dart';
import 'package:digital_legacy_weaver/features/settings/totp_factor_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final totpFactorRepositoryProvider = Provider<TotpFactorRepository>((ref) {
  return TotpFactorRepository(ref.watch(supabaseClientProvider));
});

class TotpFactorScreen extends ConsumerStatefulWidget {
  const TotpFactorScreen({super.key});

  @override
  ConsumerState<TotpFactorScreen> createState() => _TotpFactorScreenState();
}

class _TotpFactorScreenState extends ConsumerState<TotpFactorScreen> {
  final _codeController = TextEditingController();
  bool _busy = false;
  TotpFactorStatus? _status;
  TotpSetupBundle? _setupBundle;
  String? _message;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _reload() async {
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      final status = await ref.read(totpFactorRepositoryProvider).getStatus();
      if (!mounted) return;
      setState(() => _status = status);
    } catch (e) {
      if (!mounted) return;
      setState(() => _message = "Failed to load TOTP status: $e");
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _beginSetup() async {
    setState(() {
      _busy = true;
      _message = null;
      _setupBundle = null;
    });
    try {
      final bundle = await ref.read(totpFactorRepositoryProvider).beginSetup();
      if (!mounted) return;
      setState(() {
        _setupBundle = bundle;
        _message = "Scan OTP URI in authenticator app, then confirm with 6-digit code.";
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _message = "Begin setup failed: $e");
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _confirmSetup() async {
    final code = _codeController.text.trim();
    if (code.length < 6) {
      setState(() => _message = "Enter a valid 6-digit code.");
      return;
    }
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      final status = await ref.read(totpFactorRepositoryProvider).confirmSetup(
            totpCode: code,
            requireTotpUnlock: true,
          );
      if (!mounted) return;
      setState(() {
        _status = status;
        _setupBundle = null;
        _codeController.clear();
        _message = "TOTP enabled successfully.";
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _message = "Confirm setup failed: $e");
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _disable() async {
    setState(() {
      _busy = true;
      _message = null;
      _setupBundle = null;
    });
    try {
      final status = await ref.read(totpFactorRepositoryProvider).disable();
      if (!mounted) return;
      setState(() {
        _status = status;
        _message = "TOTP disabled.";
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _message = "Disable failed: $e");
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = _status;
    final enabled = status?.enabled ?? false;
    final configured = status?.configured ?? false;
    return Scaffold(
      appBar: AppBar(title: const Text("TOTP Factor")),
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
                    "Second Factor",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Text("Configured: ${configured ? "yes" : "no"}"),
                  Text("Enabled: ${enabled ? "yes" : "no"}"),
                  Text("Required at unlock: ${(status?.requireTotpUnlock ?? false) ? "yes" : "no"}"),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _busy ? null : _reload,
                          child: const Text("Refresh"),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: FilledButton(
                          onPressed: _busy ? null : _beginSetup,
                          child: const Text("Begin Setup"),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: (_busy || !enabled) ? null : _disable,
                      child: const Text("Disable Factor"),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_setupBundle != null) ...[
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Setup Bundle",
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    const Text("Secret (Base32)"),
                    SelectableText(_setupBundle!.secretBase32),
                    const SizedBox(height: 8),
                    const Text("OTP URI"),
                    SelectableText(_setupBundle!.otpauthUri),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _codeController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: "6-digit code"),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _busy ? null : _confirmSetup,
                        child: const Text("Confirm Setup"),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          if (_message != null) ...[
            const SizedBox(height: 12),
            Text(_message!),
          ],
        ],
      ),
    );
  }
}
