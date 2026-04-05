import 'package:digital_legacy_weaver/core/config/app_config.dart';
import 'package:digital_legacy_weaver/features/auth/sign_in_screen.dart';
import 'package:digital_legacy_weaver/features/dashboard/dashboard_screen.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    if (!AppConfig.isConfigured) {
      return const _MissingConfigScreen();
    }

    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, _) {
        final session = Supabase.instance.client.auth.currentSession;
        if (session == null) {
          return const SignInScreen();
        }
        return const DashboardScreen();
      },
    );
  }
}

class _MissingConfigScreen extends StatelessWidget {
  const _MissingConfigScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: const Card(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Supabase is not configured",
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
                    ),
                    SizedBox(height: 10),
                    Text("Run Flutter with --dart-define values:"),
                    SizedBox(height: 8),
                    SelectableText(
                      "flutter run --dart-define=SUPABASE_URL=<url> --dart-define=SUPABASE_ANON_KEY=<anon_key>",
                    ),
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
