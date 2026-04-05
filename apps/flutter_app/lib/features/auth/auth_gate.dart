import 'package:digital_legacy_weaver/core/config/app_config.dart';
import 'package:digital_legacy_weaver/features/auth/config_landing_screen.dart';
import 'package:digital_legacy_weaver/features/auth/sign_in_screen.dart';
import 'package:digital_legacy_weaver/features/dashboard/dashboard_screen.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    if (!AppConfig.isConfigured) {
      return const ConfigLandingScreen();
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
