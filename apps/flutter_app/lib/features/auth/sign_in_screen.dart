import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _emailController = TextEditingController();
  bool _sending = false;
  String? _message;
  bool _messageIsError = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendMagicLink() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() {
        _message = "Please enter your email.";
        _messageIsError = true;
      });
      return;
    }
    if (!email.contains("@") || !email.contains(".")) {
      setState(() {
        _message = "Please enter a valid email.";
        _messageIsError = true;
      });
      return;
    }
    setState(() {
      _sending = true;
      _message = null;
    });

    try {
      await Supabase.instance.client.auth.signInWithOtp(
        email: email,
        emailRedirectTo: null,
      );
      setState(() {
        _message =
            "Secure sign-in link sent. Check your inbox (and spam) then return to continue.";
        _messageIsError = false;
      });
    } on AuthException catch (e) {
      setState(() {
        _message = _friendlyAuthError(e.message);
        _messageIsError = true;
      });
    } finally {
      if (mounted) {
        setState(() => _sending = false);
      }
    }
  }

  String _friendlyAuthError(String raw) {
    final lower = raw.toLowerCase();
    if (lower.contains("network") ||
        lower.contains("timed out") ||
        lower.contains("failed host lookup")) {
      return "Network looks unstable. Please check your connection and try again.";
    }
    return raw;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Welcome to Digital Legacy Weaver",
                      style: TextStyle(fontSize: 30, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "Sign in to manage self-recovery and beneficiary handoff in one place.",
                    ),
                    const SizedBox(height: 10),
                    const Text("What this app helps you do right now"),
                    const SizedBox(height: 6),
                    const Text("1. Keep critical access information private-first"),
                    const Text("2. Prevent accidental loss of access while alive"),
                    const Text("3. Prepare secure delivery for the right beneficiary"),
                    const SizedBox(height: 18),
                    TextField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: "Email address",
                        hintText: "you@example.com",
                      ),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _sending ? null : _sendMagicLink,
                        child: Text(_sending ? "Sending..." : "Send secure sign-in link"),
                      ),
                    ),
                    if (_message != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _messageIsError
                              ? const Color(0xFFFFF1F1)
                              : const Color(0xFFE9F6EF),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(_message!),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
