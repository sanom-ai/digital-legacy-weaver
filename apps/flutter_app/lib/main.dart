import 'package:digital_legacy_weaver/core/config/app_config.dart';
import 'package:digital_legacy_weaver/core/theme/app_theme.dart';
import 'package:digital_legacy_weaver/features/auth/auth_gate.dart';
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
        return const _MissingConfigScreen();
      }
      return UnlockDeliveryScreen(
        initialAccessId: Uri.base.queryParameters["access_id"],
        initialAccessKey: Uri.base.queryParameters["access_key"],
      );
    }
    return const AuthGate();
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
