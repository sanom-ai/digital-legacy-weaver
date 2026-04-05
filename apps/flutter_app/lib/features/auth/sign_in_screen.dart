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

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendMagicLink() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() => _message = "Please enter your email.");
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
      setState(() => _message = "Magic link sent. Please check your inbox.");
    } on AuthException catch (e) {
      setState(() => _message = e.message);
    } finally {
      if (mounted) {
        setState(() => _sending = false);
      }
    }
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
                      "Welcome Back",
                      style: TextStyle(fontSize: 30, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    const Text("Private-first access to your recovery vault."),
                    const SizedBox(height: 18),
                    TextField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: "Email",
                        hintText: "you@example.com",
                      ),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _sending ? null : _sendMagicLink,
                        child: Text(_sending ? "Sending..." : "Send Magic Link"),
                      ),
                    ),
                    if (_message != null) ...[
                      const SizedBox(height: 12),
                      Text(_message!),
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
