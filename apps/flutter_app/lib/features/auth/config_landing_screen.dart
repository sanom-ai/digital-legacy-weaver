import 'package:digital_legacy_weaver/features/intent_builder/intent_builder_screen.dart';
import 'package:digital_legacy_weaver/features/profile/profile_model.dart';
import 'package:digital_legacy_weaver/features/settings/safety_settings_model.dart';
import 'package:flutter/material.dart';

class ConfigLandingScreen extends StatelessWidget {
  const ConfigLandingScreen({
    super.key,
    this.unlockAttempt = false,
  });

  final bool unlockAttempt;

  static final ProfileModel _demoProfile = ProfileModel(
    id: 'demo-owner',
    backupEmail: 'owner@example.com',
    beneficiaryEmail: 'beneficiary@example.com',
    legacyInactivityDays: 180,
    selfRecoveryInactivityDays: 45,
    lastActiveAt: DateTime.utc(2026, 1, 1),
  );

  static const SafetySettingsModel _demoSettings = SafetySettingsModel(
    remindersEnabled: true,
    reminderOffsetsDays: [14, 7, 1],
    gracePeriodDays: 3,
    legalDisclaimerAccepted: true,
    emergencyPauseUntil: null,
    requireTotpUnlock: false,
    privateFirstMode: true,
    tracePrivacyProfile: 'minimal',
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      unlockAttempt ? "Backend setup required" : "Finish backend setup or open demo mode",
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      unlockAttempt
                          ? "This release bundle opened correctly, but unlock mode still needs Supabase runtime configuration before it can talk to a live backend."
                          : "This build is working, but it does not include a live Supabase backend yet. You can still open a local demo workspace to explore the UX and artifact workflow.",
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      "Backend setup",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    const Text("Run Flutter with these values when wiring a real backend:"),
                    const SizedBox(height: 8),
                    const SelectableText(
                      "flutter run --dart-define=SUPABASE_URL=<url> --dart-define=SUPABASE_ANON_KEY=<anon_key>",
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      "What you can do right now",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    const Text("1. Open a local demo workspace and explore the intent builder, canonical artifacts, and runtime readiness flow."),
                    const SizedBox(height: 4),
                    const Text("2. Wire a real Supabase project later when you want sign-in, profile sync, and live unlock flows."),
                    const SizedBox(height: 20),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        FilledButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => IntentBuilderScreen(
                                  profile: _demoProfile,
                                  settings: _demoSettings,
                                ),
                              ),
                            );
                          },
                          child: const Text("Open demo workspace"),
                        ),
                        OutlinedButton(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Use the displayed --dart-define values when you are ready to connect a real backend."),
                              ),
                            );
                          },
                          child: const Text("Show setup reminder"),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      "Technical companion only: demo mode is local UX only and does not replace a live backend or legal process.",
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
