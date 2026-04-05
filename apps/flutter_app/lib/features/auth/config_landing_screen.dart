import 'package:digital_legacy_weaver/features/auth/demo_scenarios.dart';
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
    beneficiaryName: 'Demo Beneficiary',
    beneficiaryPhone: '+66-800-000-000',
    beneficiaryVerificationHint: 'Shared family phrase from setup',
    beneficiaryVerificationPhraseHash: 'demo-seeded-hash',
    legacyInactivityDays: 180,
    selfRecoveryInactivityDays: 45,
    lastActiveAt: DateTime.utc(2026, 1, 1),
  );

  static const SafetySettingsModel _demoSettings = SafetySettingsModel(
    remindersEnabled: true,
    reminderOffsetsDays: [14, 7, 1],
    gracePeriodDays: 7,
    proofOfLifeCheckMode: 'biometric_tap',
    proofOfLifeFallbackChannels: ['email', 'sms'],
    serverHeartbeatFallbackEnabled: true,
    iosBackgroundRiskAcknowledged: true,
    legalDisclaimerAccepted: true,
    emergencyPauseUntil: null,
    requireTotpUnlock: false,
    privateFirstMode: true,
    tracePrivacyProfile: 'minimal',
  );

  void _openScenario(BuildContext context, DemoScenario scenario) {
    final profile = scenario.buildProfile(_demoProfile);
    final document = scenario.buildDocument(
      profile: profile,
      settings: _demoSettings,
      ownerRefOverride: scenario.ownerRef,
    );

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => IntentBuilderScreen(
          profile: profile,
          settings: _demoSettings,
          initialDocument: document,
          storageOwnerRef: scenario.ownerRef,
          screenTitle: scenario.title,
          screenSubtitle: scenario.summary,
        ),
      ),
    );
  }

  void _showSetupReminder(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Use the displayed --dart-define values when you are ready to connect a real backend.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = unlockAttempt
        ? 'Backend setup required'
        : 'Finish backend setup or start a guided demo';
    final summary = unlockAttempt
        ? 'This bundle opened correctly, but unlock mode still needs Supabase runtime configuration before it can talk to a live backend.'
        : 'This build works without a live backend. You can explore the local UX, artifact flow, and readiness journey through guided demo scenarios.';

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 980),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF201812), Color(0xFF4A382B)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE9DDCC),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: const Text('Private-first demo entry'),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        title,
                        style: theme.textTheme.headlineMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        summary,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: Colors.white.withValues(alpha: 0.84),
                        ),
                      ),
                      const SizedBox(height: 18),
                      const Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          _LandingBadge(label: 'Intent -> PTN -> artifact'),
                          _LandingBadge(label: 'Local encrypted drafts'),
                          _LandingBadge(label: 'Technical companion only'),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 3,
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Start with a guided scenario',
                                style: theme.textTheme.titleLarge,
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Pick a concrete starting point. Each demo seeds the Intent Builder with a preset use case so you can move straight into artifact export and runtime readiness.',
                              ),
                              const SizedBox(height: 16),
                              ...demoScenarios.map(
                                (scenario) => Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: _ScenarioCard(
                                    scenario: scenario,
                                    onOpen: () => _openScenario(context, scenario),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 2,
                      child: Column(
                        children: [
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'What happens in demo mode',
                                    style: theme.textTheme.titleMedium,
                                  ),
                                  const SizedBox(height: 10),
                                  const _StepLine(
                                    index: '1',
                                    text: 'Open a preset intent scenario instead of starting from a blank screen.',
                                  ),
                                  const _StepLine(
                                    index: '2',
                                    text: 'Review entries, export a canonical PTN artifact, and inspect history locally.',
                                  ),
                                  const _StepLine(
                                    index: '3',
                                    text: 'Check readiness, compare versions, and see the control-room flow without a backend.',
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Backend setup',
                                    style: theme.textTheme.titleMedium,
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'When you are ready to connect a live Supabase project, run Flutter with these values:',
                                  ),
                                  const SizedBox(height: 10),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(14),
                                      color: const Color(0xFFF7F1E8),
                                    ),
                                    child: const SelectableText(
                                      'flutter run --dart-define=SUPABASE_URL=<url> --dart-define=SUPABASE_ANON_KEY=<anon_key>',
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  Wrap(
                                    spacing: 12,
                                    runSpacing: 12,
                                    children: [
                                      FilledButton(
                                        onPressed: () => _openScenario(context, demoScenarios.first),
                                        child: const Text('Open demo workspace'),
                                      ),
                                      OutlinedButton(
                                        onPressed: () => _showSetupReminder(context),
                                        child: const Text('Show setup reminder'),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Card(
                  color: Color(0xFFFFF7ED),
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'Technical companion only: demo mode is local UX only and does not replace a live backend, legal process, or destination-side verification.',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ScenarioCard extends StatelessWidget {
  const _ScenarioCard({
    required this.scenario,
    required this.onOpen,
  });

  final DemoScenario scenario;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5D7C5)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                scenario.title,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  color: const Color(0xFFF7F1E8),
                ),
                child: Text(scenario.badge),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(scenario.summary),
          const SizedBox(height: 14),
          FilledButton.tonal(
            onPressed: onOpen,
            child: Text(scenario.primaryActionLabel),
          ),
        ],
      ),
    );
  }
}

class _LandingBadge extends StatelessWidget {
  const _LandingBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(color: Colors.white),
      ),
    );
  }
}

class _StepLine extends StatelessWidget {
  const _StepLine({
    required this.index,
    required this.text,
  });

  final String index;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 26,
            height: 26,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: Color(0xFFE5D7C5),
              shape: BoxShape.circle,
            ),
            child: Text(index),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
