import 'package:digital_legacy_weaver/features/beta/beta_feedback_screen.dart';
import 'package:digital_legacy_weaver/features/connectors/presentation/connectors_screen.dart';
import 'package:digital_legacy_weaver/features/onboarding/onboarding_setup_screen.dart';
import 'package:digital_legacy_weaver/features/profile/profile_provider.dart';
import 'package:digital_legacy_weaver/features/settings/safety_settings_model.dart';
import 'package:digital_legacy_weaver/features/settings/privacy_profile_preset.dart';
import 'package:digital_legacy_weaver/features/settings/safety_settings_provider.dart';
import 'package:digital_legacy_weaver/features/settings/safety_settings_screen.dart';
import 'package:digital_legacy_weaver/features/unlock/unlock_delivery_screen.dart';
import 'package:digital_legacy_weaver/features/vault/recovery_vault_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileProvider);
    final safetyAsync = ref.watch(safetySettingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Digital Legacy Weaver'),
        actions: [
          TextButton(
            onPressed: () => Supabase.instance.client.auth.signOut(),
            child: const Text("Sign out"),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          profileAsync.when(
            data: (profile) {
              final inactiveDays = DateTime.now().difference(profile.lastActiveAt).inDays;
              final daysLeft = (profile.legacyInactivityDays - inactiveDays).clamp(0, 9999);
              return Column(
                children: [
                  _HeroCard(
                    daysLeft: daysLeft,
                    onAliveCheck: () async {
                      await ref.read(profileRepositoryProvider).markAlive();
                      ref.invalidate(profileProvider);
                    },
                  ),
                  const SizedBox(height: 12),
                  safetyAsync.when(
                    data: (settings) {
                      final setupComplete =
                          (profile.beneficiaryEmail?.trim().isNotEmpty ?? false) &&
                          settings.legalDisclaimerAccepted;
                      if (setupComplete) {
                        return const SizedBox.shrink();
                      }
                      return Card(
                        color: const Color(0xFFFFF7ED),
                        child: ListTile(
                          leading: const Icon(Icons.auto_fix_high_rounded),
                          title: const Text("Complete setup for beta"),
                          subtitle: const Text(
                            "Add beneficiary + consent + private-first defaults. This product is a technical companion, not a legal will.",
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () async {
                            final changed = await Navigator.of(context).push<bool>(
                              MaterialPageRoute(
                                builder: (_) => OnboardingSetupScreen(
                                  initialProfile: profile,
                                  initialSettings: settings,
                                ),
                              ),
                            );
                            if (changed == true) {
                              ref.invalidate(profileProvider);
                              ref.invalidate(safetySettingsProvider);
                            }
                          },
                        ),
                      );
                    },
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                ],
              );
            },
            loading: () => const Card(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
            error: (error, _) => Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text("Profile load error: $error"),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const RecoveryVaultSection(),
          const SizedBox(height: 16),
          safetyAsync.when(
            data: (settings) => _PolicySelectorCard(settings: settings),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              title: const Text("Partner-ready Paths"),
              subtitle: const Text("Prepare destination references and optional handoff routes"),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ConnectorsScreen()),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              title: const Text("Risk Controls"),
              subtitle: const Text("Legal consent, reminders, grace period, private-first mode, emergency pause"),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SafetySettingsScreen()),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              title: const Text("Unlock Delivery"),
              subtitle: const Text("Access link + verification code flow"),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const UnlockDeliveryScreen()),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              title: const Text("Beta Feedback"),
              subtitle: const Text("Report bug, reliability issue, or UX feedback"),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const BetaFeedbackScreen()),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          const _DeliveryModeCard(),
        ],
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.daysLeft,
    required this.onAliveCheck,
  });

  final int daysLeft;
  final VoidCallback onAliveCheck;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [Color(0xFF1B1A17), Color(0xFF3E3023)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Private First',
            style: theme.textTheme.titleLarge?.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 8),
          Text(
            '$daysLeft days before legacy trigger',
            style: theme.textTheme.bodyLarge?.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: 20),
          FilledButton.tonal(
            onPressed: onAliveCheck,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFE5D7C5),
              foregroundColor: const Color(0xFF1B1A17),
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
            ),
            child: const Text('I am still alive'),
          ),
        ],
      ),
    );
  }
}

class _DeliveryModeCard extends StatelessWidget {
  const _DeliveryModeCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Delivery Modes',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 8),
            Text('1) Legacy delivery to beneficiary after long inactivity'),
            SizedBox(height: 4),
            Text('2) Self-recovery delivery to backup email for password recovery'),
            SizedBox(height: 10),
            Text('Technical companion only: beneficiaries complete any required legal verification in the appropriate legal or service context.'),
          ],
        ),
      ),
    );
  }
}

class _PolicySelectorCard extends StatelessWidget {
  const _PolicySelectorCard({required this.settings});

  final SafetySettingsModel settings;

  @override
  Widget build(BuildContext context) {
    final preset = presetById(settings.tracePrivacyProfile);
    return Card(
      child: ListTile(
        leading: const Icon(Icons.privacy_tip_outlined),
        title: Text('Privacy Preset: ${preset.title}'),
        subtitle: Text(
          '${preset.summary}\nTechnical companion only. Change this in Risk Controls.',
        ),
        isThreeLine: true,
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const SafetySettingsScreen()),
          );
        },
      ),
    );
  }
}
