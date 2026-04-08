import 'package:digital_legacy_weaver/core/config/app_config.dart';
import 'package:digital_legacy_weaver/core/theme/app_theme.dart';
import 'package:digital_legacy_weaver/features/auth/auth_gate.dart';
import 'package:digital_legacy_weaver/features/auth/config_landing_screen.dart';
import 'package:digital_legacy_weaver/features/unlock/unlock_delivery_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (AppConfig.isConfigured) {
    await Supabase.initialize(
      url: AppConfig.supabaseUrl,
      anonKey: AppConfig.supabaseAnonKey,
    );
  }
  runApp(const ProviderScope(child: DigitalLegacyWeaverApp()));
}

class DigitalLegacyWeaverApp extends StatelessWidget {
  const DigitalLegacyWeaverApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Digital Legacy Weaver',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: const _AppEntry(),
    );
  }
}

class _AppEntry extends StatefulWidget {
  const _AppEntry();

  @override
  State<_AppEntry> createState() => _AppEntryState();
}

class _AppEntryState extends State<_AppEntry> {
  @override
  Widget build(BuildContext context) {
    final path = Uri.base.path.toLowerCase();
    if (path == "/unlock" || path.endsWith("/unlock")) {
      if (!AppConfig.isConfigured) {
        return const ConfigLandingScreen(unlockAttempt: true);
      }
      return const UnlockDeliveryScreen();
    }
    return const AuthGate();
  }
}
