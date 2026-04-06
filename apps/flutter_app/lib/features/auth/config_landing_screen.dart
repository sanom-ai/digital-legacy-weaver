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

  void _showBackendSetupSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Connect a live backend (optional)',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              const Text(
                'You can keep using local mode now. Connect a live backend only when your team is ready for account sync and cloud runtime services.',
              ),
              const SizedBox(height: 12),
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
              const SizedBox(height: 12),
              const Text(
                'After connecting, sign-in and cloud-backed flows will activate automatically.',
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = unlockAttempt
        ? 'Continue safely in local mode'
        : 'Start now with private-first local mode';
    final summary = unlockAttempt
        ? 'This receipt link opened, but secure bundle unlock needs a connected runtime. You can still explore the full product flow locally right now.'
        : 'No backend setup is required to start. Explore onboarding, intent shaping, and readiness journey first, then connect cloud services later if needed.';

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
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE9DDCC),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: const Text('Private-first product workspace'),
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
                          _LandingBadge(label: 'Intent to artifact journey'),
                          _LandingBadge(label: 'Local encrypted drafts'),
                          _LandingBadge(label: 'Start without backend setup'),
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
                                'Choose your first real user journey',
                                style: theme.textTheme.titleLarge,
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Pick a concrete path and continue immediately. Each journey starts with realistic defaults so you can move straight to outcomes, not technical setup.',
                              ),
                              const SizedBox(height: 16),
                              ...demoScenarios.map(
                                (scenario) => Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: _ScenarioCard(
                                    scenario: scenario,
                                    onOpen: () =>
                                        _openScenario(context, scenario),
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
                                    'What happens in local mode',
                                    style: theme.textTheme.titleMedium,
                                  ),
                                  const SizedBox(height: 10),
                                  const _StepLine(
                                    index: '1',
                                    text:
                                        'Start with a ready-to-use journey instead of a blank screen.',
                                  ),
                                  const _StepLine(
                                    index: '2',
                                    text:
                                        'Review safety choices, export artifacts, and inspect history on this device.',
                                  ),
                                  const _StepLine(
                                    index: '3',
                                    text:
                                        'Check readiness and compare versions without waiting for backend setup.',
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
                                  Text('Need cloud sync later?',
                                      style: theme.textTheme.titleMedium),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'Cloud runtime is optional for first use. Keep building in local mode, then connect backend only when your team is ready.',
                                  ),
                                  const SizedBox(height: 14),
                                  Wrap(
                                    spacing: 12,
                                    runSpacing: 12,
                                    children: [
                                      FilledButton(
                                        onPressed: () => _openScenario(
                                            context, demoScenarios.first),
                                        child:
                                            const Text('Start local workspace'),
                                      ),
                                      OutlinedButton(
                                        onPressed: () =>
                                            _showBackendSetupSheet(context),
                                        child: const Text(
                                            'Show cloud setup steps'),
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
                      'Product boundary: this app coordinates secure access handoff. It does not replace legal processes or destination-side identity verification.',
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
