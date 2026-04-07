import 'package:digital_legacy_weaver/features/beta/beta_feedback_screen.dart';
import 'package:digital_legacy_weaver/features/connectors/presentation/connectors_screen.dart';
import 'package:digital_legacy_weaver/features/intent_builder/intent_artifact_compare_screen.dart';
import 'package:digital_legacy_weaver/features/intent_builder/intent_artifact_history_screen.dart';
import 'package:digital_legacy_weaver/features/intent_builder/intent_artifact_review_screen.dart';
import 'package:digital_legacy_weaver/features/intent_builder/intent_canonical_artifact_model.dart';
import 'package:digital_legacy_weaver/features/intent_builder/intent_canonical_artifact_provider.dart';
import 'package:digital_legacy_weaver/features/intent_builder/intent_builder_screen.dart';
import 'package:digital_legacy_weaver/features/intent_builder/intent_runtime_readiness_model.dart';
import 'package:digital_legacy_weaver/features/intent_builder/intent_runtime_readiness_screen.dart';
import 'package:digital_legacy_weaver/features/onboarding/onboarding_setup_screen.dart';
import 'package:digital_legacy_weaver/features/profile/profile_model.dart';
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
              final inactiveDays =
                  DateTime.now().difference(profile.lastActiveAt).inDays;
              final daysLeft =
                  (profile.legacyInactivityDays - inactiveDays).clamp(0, 9999);
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
                    data: (settings) => _OwnerJourneyStatusCard(
                      beneficiaryIdentityReady:
                          profile.hasBeneficiaryIdentityKit,
                      proofOfLifeFallbackReady:
                          settings.serverHeartbeatFallbackEnabled,
                      legalConsentReady: settings.legalDisclaimerAccepted,
                    ),
                    loading: () => const _InlineStateCard(
                      message: "Loading owner journey status...",
                    ),
                    error: (_, __) => const _InlineStateCard(
                      message: "Could not load owner journey status right now.",
                      isError: true,
                    ),
                  ),
                  const SizedBox(height: 12),
                  safetyAsync.when(
                    data: (settings) {
                      final setupComplete =
                          (profile.beneficiaryEmail?.trim().isNotEmpty ??
                                  false) &&
                              profile.hasBeneficiaryIdentityKit &&
                              settings.serverHeartbeatFallbackEnabled &&
                              settings.iosBackgroundRiskAcknowledged &&
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
                            "Add beneficiary identity, fallback channels, consent, and private-first defaults. This product coordinates secure handoff and does not replace a legal will.",
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () async {
                            final changed =
                                await Navigator.of(context).push<bool>(
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
                    loading: () => const _InlineStateCard(
                      message: "Checking setup completion...",
                    ),
                    error: (_, __) => const _InlineStateCard(
                      message: "Could not verify setup completion right now.",
                      isError: true,
                    ),
                  ),
                ],
              );
            },
            loading: () => const _InlineStateCard(
              message: "Loading your profile and current policy state...",
              showSpinner: true,
            ),
            error: (_, __) => const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  "We could not load your profile right now. Please refresh and try again.",
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          profileAsync.when(
            data: (profile) => safetyAsync.when(
              data: (settings) {
                final artifactAsync = ref.watch(
                  intentCanonicalArtifactProvider(profile.id),
                );
                final artifactHistoryAsync = ref.watch(
                  intentCanonicalArtifactHistoryProvider(profile.id),
                );
                final readinessAsync = ref.watch(
                  intentRuntimeReadinessProvider(profile.id),
                );
                final setupComplete =
                    (profile.beneficiaryEmail?.trim().isNotEmpty ?? false) &&
                        profile.hasBeneficiaryIdentityKit &&
                        settings.serverHeartbeatFallbackEnabled &&
                        settings.iosBackgroundRiskAcknowledged &&
                        settings.legalDisclaimerAccepted;
                return Column(
                  children: [
                    readinessAsync.when(
                      data: (readiness) {
                        void openBuilder() {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => IntentBuilderScreen(
                                profile: profile,
                                settings: settings,
                              ),
                            ),
                          );
                        }

                        void openReadiness() {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => IntentRuntimeReadinessScreen(
                                readiness: readiness,
                              ),
                            ),
                          );
                        }

                        Future<void> openSetup() async {
                          final changed =
                              await Navigator.of(context).push<bool>(
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
                        }

                        void openReviewArtifact() {
                          if (readiness.currentArtifact == null) {
                            openBuilder();
                            return;
                          }
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => IntentArtifactReviewScreen(
                                artifact: readiness.currentArtifact!,
                              ),
                            ),
                          );
                        }

                        void openHistory() {
                          final artifact = readiness.currentArtifact;
                          final history = artifactHistoryAsync.valueOrNull;
                          if (artifact == null || history == null) {
                            openBuilder();
                            return;
                          }
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => IntentArtifactHistoryScreen(
                                currentArtifact: artifact,
                                artifactHistory: history,
                                onPromote: (selected) async {
                                  await ref
                                      .read(
                                        intentCanonicalArtifactRepositoryProvider,
                                      )
                                      .promoteArtifactVersion(
                                        ownerRef: profile.id,
                                        artifactId: selected.artifactId,
                                      );
                                  ref.invalidate(
                                    intentCanonicalArtifactProvider(profile.id),
                                  );
                                  ref.invalidate(
                                    intentCanonicalArtifactHistoryProvider(
                                      profile.id,
                                    ),
                                  );
                                  ref.invalidate(
                                    intentRuntimeReadinessProvider(profile.id),
                                  );
                                },
                                onRemove: (selected) async {
                                  await ref
                                      .read(
                                        intentCanonicalArtifactRepositoryProvider,
                                      )
                                      .clearArtifactVersion(
                                        ownerRef: profile.id,
                                        artifactId: selected.artifactId,
                                      );
                                  ref.invalidate(
                                    intentCanonicalArtifactProvider(profile.id),
                                  );
                                  ref.invalidate(
                                    intentCanonicalArtifactHistoryProvider(
                                      profile.id,
                                    ),
                                  );
                                  ref.invalidate(
                                    intentRuntimeReadinessProvider(profile.id),
                                  );
                                },
                              ),
                            ),
                          );
                        }

                        void openPrimaryAction() {
                          final actionKey = readiness.primaryActionKey;
                          if (actionKey == "review_exported_artifact") {
                            openReviewArtifact();
                            return;
                          }
                          if (actionKey == "refresh_exported_artifact" ||
                              actionKey == "reexport_latest_draft") {
                            openHistory();
                            return;
                          }
                          openBuilder();
                        }

                        return Column(
                          children: [
                            _LegacyLedgerDashboardCard(
                              profile: profile,
                              readiness: readiness,
                              onAddPlan: openBuilder,
                              onHeartbeatCheck: () async {
                                await ref
                                    .read(profileRepositoryProvider)
                                    .markAlive();
                                ref.invalidate(profileProvider);
                              },
                            ),
                            const SizedBox(height: 12),
                            _UserOutcomeCard(
                              setupComplete: setupComplete,
                              readiness: readiness,
                              onOpenSetup: () {
                                openSetup();
                              },
                              onOpenBuilder: openBuilder,
                              onOpenReceipt: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        const UnlockDeliveryScreen(),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 12),
                            _ControlRoomCard(
                              readiness: readiness,
                              setupComplete: setupComplete,
                              primaryActionLabel: readiness.primaryActionLabel,
                              onPrimaryAction: openPrimaryAction,
                              onOpenBuilder: openBuilder,
                              onOpenReadiness: openReadiness,
                              onOpenSetup: openSetup,
                              onOpenArtifactReview: openReviewArtifact,
                              onOpenArtifactHistory: openHistory,
                            ),
                          ],
                        );
                      },
                      loading: () => const _InlineStateCard(
                        message: "Loading control room status...",
                      ),
                      error: (_, __) => const _InlineStateCard(
                        message:
                            "Control room status is temporarily unavailable.",
                        isError: true,
                      ),
                    ),
                    readinessAsync.when(
                      data: (readiness) => Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: _ProductConcretenessCard(
                          profile: profile,
                          settings: settings,
                          readiness: readiness,
                          setupComplete: setupComplete,
                        ),
                      ),
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const _InlineStateCard(
                        message: "Could not load product status details.",
                        isError: true,
                      ),
                    ),
                    if (readinessAsync.hasValue) const SizedBox(height: 12),
                    _DashboardActionCard(
                      title: "Intent Builder",
                      subtitle:
                          "Shape recovery and handoff routes in plain language before export",
                      icon: Icons.route_outlined,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => IntentBuilderScreen(
                              profile: profile,
                              settings: settings,
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    readinessAsync.when(
                      data: (readiness) => _RuntimeReadinessCard(
                        readiness: readiness,
                        onOpenReadiness: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => IntentRuntimeReadinessScreen(
                                readiness: readiness,
                              ),
                            ),
                          );
                        },
                        onOpenBuilder: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => IntentBuilderScreen(
                                profile: profile,
                                settings: settings,
                              ),
                            ),
                          );
                        },
                      ),
                      loading: () => const _InlineStateCard(
                        message: "Loading runtime readiness summary...",
                      ),
                      error: (_, __) => const _InlineStateCard(
                        message: "Runtime readiness summary is unavailable.",
                        isError: true,
                      ),
                    ),
                    artifactAsync.when(
                      data: (artifact) => artifactHistoryAsync.when(
                        data: (history) => Card(
                          color:
                              artifact == null ? const Color(0xFFFFF7ED) : null,
                          child: Column(
                            children: [
                              ListTile(
                                leading: const Icon(Icons.verified_outlined),
                                title: const Text("Canonical artifact status"),
                                subtitle: Text(
                                  artifact == null
                                      ? "No exported handoff version yet."
                                      : "Current status: ${artifact.artifactState.name}. Version ${artifact.contractVersion} with ${artifact.activeEntryCount} active routes across ${history.length} saved versions.${artifact.promotedFromArtifactId != null ? " Latest version came from history promotion." : ""} Keep draft and exported version aligned before treating this as release-ready.",
                                ),
                                trailing: const Icon(Icons.chevron_right),
                                onTap: () {
                                  if (artifact == null) {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => IntentBuilderScreen(
                                          profile: profile,
                                          settings: settings,
                                        ),
                                      ),
                                    );
                                    return;
                                  }
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          IntentArtifactReviewScreen(
                                        artifact: artifact,
                                      ),
                                    ),
                                  );
                                },
                              ),
                              if (artifact != null && history.length > 1)
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    16,
                                    0,
                                    16,
                                    16,
                                  ),
                                  child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: OutlinedButton(
                                      onPressed: () {
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                IntentArtifactCompareScreen(
                                              currentArtifact: artifact,
                                              compareArtifact: history[1],
                                            ),
                                          ),
                                        );
                                      },
                                      child: const Text(
                                        "Compare latest with previous",
                                      ),
                                    ),
                                  ),
                                ),
                              if (artifact != null && history.length > 1)
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    16,
                                    0,
                                    16,
                                    16,
                                  ),
                                  child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      "Older versions can also be promoted again from Intent Builder without deleting history.",
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodySmall,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        loading: () => const _InlineStateCard(
                          message: "Loading artifact history...",
                        ),
                        error: (_, __) => const _InlineStateCard(
                          message: "Could not load artifact history.",
                          isError: true,
                        ),
                      ),
                      loading: () => const _InlineStateCard(
                        message: "Loading canonical artifact status...",
                      ),
                      error: (_, __) => const _InlineStateCard(
                        message: "Could not load canonical artifact status.",
                        isError: true,
                      ),
                    ),
                  ],
                );
              },
              loading: () =>
                  const _InlineStateCard(message: "Loading safety settings..."),
              error: (_, __) => const _InlineStateCard(
                message: "Could not load safety settings for this workspace.",
                isError: true,
              ),
            ),
            loading: () =>
                const _InlineStateCard(message: "Preparing workspace..."),
            error: (_, __) => const _InlineStateCard(
              message: "Workspace data is temporarily unavailable.",
              isError: true,
            ),
          ),
          const SizedBox(height: 16),
          const RecoveryVaultSection(),
          const SizedBox(height: 16),
          safetyAsync.when(
            data: (settings) => _PolicySelectorCard(settings: settings),
            loading: () =>
                const _InlineStateCard(message: "Loading privacy preset..."),
            error: (_, __) => const _InlineStateCard(
              message: "Could not load privacy preset.",
              isError: true,
            ),
          ),
          const SizedBox(height: 16),
          _DashboardActionCard(
            title: "Partner-ready Paths",
            subtitle:
                "Prepare destination references and optional handoff routes",
            icon: Icons.hub_outlined,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ConnectorsScreen()),
              );
            },
          ),
          const SizedBox(height: 16),
          _DashboardActionCard(
            title: "Risk Controls",
            subtitle:
                "Legal consent, reminders, grace period, private-first mode, emergency pause",
            icon: Icons.shield_outlined,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const SafetySettingsScreen(),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          _DashboardActionCard(
            title: "Beneficiary Receipt",
            subtitle:
                "Secure link, receipt code, and pre-registered identity flow",
            icon: Icons.mark_email_unread_outlined,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const UnlockDeliveryScreen(),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          _DashboardActionCard(
            title: "Beta Feedback",
            subtitle: "Report bug, reliability issue, or UX feedback",
            icon: Icons.rate_review_outlined,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const BetaFeedbackScreen()),
              );
            },
          ),
          const SizedBox(height: 16),
          const _DeliveryModeCard(),
        ],
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.daysLeft, required this.onAliveCheck});

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

class _OwnerJourneyStatusCard extends StatelessWidget {
  const _OwnerJourneyStatusCard({
    required this.beneficiaryIdentityReady,
    required this.proofOfLifeFallbackReady,
    required this.legalConsentReady,
  });

  final bool beneficiaryIdentityReady;
  final bool proofOfLifeFallbackReady;
  final bool legalConsentReady;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Owner journey status",
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            const Text(
              "This workspace is built for real user outcomes: secure self-recovery while alive, and secure beneficiary delivery only when policy conditions are met.",
            ),
            const SizedBox(height: 10),
            Text(
              beneficiaryIdentityReady
                  ? "1. Beneficiary identity kit: ready"
                  : "1. Beneficiary identity kit: still missing",
            ),
            Text(
              proofOfLifeFallbackReady
                  ? "2. Proof-of-life fallback: ready"
                  : "2. Proof-of-life fallback: still missing",
            ),
            Text(
              legalConsentReady
                  ? "3. Safety/legal consent: ready"
                  : "3. Safety/legal consent: still missing",
            ),
          ],
        ),
      ),
    );
  }
}

class _DeliveryModeCard extends StatelessWidget {
  const _DeliveryModeCard();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Delivery Modes',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 8),
            Text('1) Legacy delivery to beneficiary after long inactivity'),
            SizedBox(height: 4),
            Text(
              '2) Self-recovery delivery to backup email for password recovery',
            ),
            SizedBox(height: 10),
            Text(
              'Technical companion only: beneficiaries complete any required legal verification in the appropriate legal or service context.',
            ),
          ],
        ),
      ),
    );
  }
}

class _UserOutcomeCard extends StatelessWidget {
  const _UserOutcomeCard({
    required this.setupComplete,
    required this.readiness,
    required this.onOpenSetup,
    required this.onOpenBuilder,
    required this.onOpenReceipt,
  });

  final bool setupComplete;
  final IntentRuntimeReadinessModel readiness;
  final VoidCallback onOpenSetup;
  final VoidCallback onOpenBuilder;
  final VoidCallback onOpenReceipt;

  @override
  Widget build(BuildContext context) {
    final canDeliver = readiness.readyForRuntime && setupComplete;
    final scheme = Theme.of(context).colorScheme;
    return Card(
      color: scheme.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "User outcome focus",
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            const Text(
              "Use this app like a product, not a config panel: set up once, verify readiness, then keep your recovery and delivery path healthy.",
            ),
            const SizedBox(height: 10),
            Text(
              setupComplete
                  ? "1. Setup baseline is complete."
                  : "1. Setup baseline is incomplete.",
            ),
            Text(
              readiness.readyForRuntime
                  ? "2. Delivery policy is runtime-ready."
                  : "2. Delivery policy still needs action.",
            ),
            Text(
              canDeliver
                  ? "3. Beneficiary receipt path can be exercised safely."
                  : "3. Beneficiary receipt path should wait until setup and readiness are complete.",
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 8,
              children: [
                if (!setupComplete)
                  FilledButton(
                    onPressed: onOpenSetup,
                    child: const Text("Finish setup first"),
                  ),
                OutlinedButton(
                  onPressed: onOpenBuilder,
                  child: const Text("Open plan workspace"),
                ),
                OutlinedButton(
                  onPressed: onOpenReceipt,
                  child: const Text("Open beneficiary receipt"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductConcretenessCard extends StatelessWidget {
  const _ProductConcretenessCard({
    required this.profile,
    required this.settings,
    required this.readiness,
    required this.setupComplete,
  });

  final ProfileModel profile;
  final SafetySettingsModel settings;
  final IntentRuntimeReadinessModel readiness;
  final bool setupComplete;

  @override
  Widget build(BuildContext context) {
    final artifact = readiness.currentArtifact;
    final hasActiveRoute = (artifact?.activeEntryCount ?? 0) > 0;
    final secureLinkReceiptReady = settings.serverHeartbeatFallbackEnabled &&
        profile.hasBeneficiaryIdentityKit;
    final scheme = Theme.of(context).colorScheme;

    return Card(
      color: scheme.primaryContainer.withValues(alpha: 0.35),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Most Concrete Product Status",
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            const Text(
              "An owner can define a private digital legacy plan, keep it controlled while alive, and let the right recipient move through a secure, humane handoff when the time comes.",
            ),
            const SizedBox(height: 12),
            const Text(
              "Available now",
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            Text(
              setupComplete
                  ? "1. Owner setup baseline is complete."
                  : "1. Owner setup baseline is still incomplete.",
            ),
            Text(
              readiness.hasArtifact
                  ? "2. Canonical artifact export and history are active."
                  : "2. Canonical artifact export is not started yet.",
            ),
            Text(
              hasActiveRoute
                  ? "3. At least one active delivery route exists."
                  : "3. No active delivery route yet.",
            ),
            Text(
              secureLinkReceiptReady
                  ? "4. Beneficiary secure-link receipt flow is ready."
                  : "4. Beneficiary secure-link receipt flow still needs identity/fallback setup.",
            ),
            const SizedBox(height: 10),
            const Text(
              "Next milestone",
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            Text(
              readiness.readyForRuntime
                  ? "1. Run beta release pass (toolchain + smoke + controlled handoff drill)."
                  : "1. Drive current artifact to ready state without blockers.",
            ),
            const Text(
              "2. Harden proof-of-life cross-device recovery and keep false triggers low.",
            ),
            const Text(
              "3. Continue wrong-recipient protection and partner verification route polish.",
            ),
            const SizedBox(height: 12),
            const Text(
              "KPI snapshot",
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _MetricChip(
                  label: setupComplete
                      ? "Setup complete: Yes"
                      : "Setup complete: No",
                ),
                _MetricChip(label: "Readiness: ${readiness.readinessLabel}"),
                _MetricChip(
                  label: "Artifact versions: ${readiness.historyCount}",
                ),
                _MetricChip(
                  label: "Active routes: ${artifact?.activeEntryCount ?? 0}",
                ),
                _MetricChip(
                  label: secureLinkReceiptReady
                      ? "Receipt path: Ready"
                      : "Receipt path: Pending",
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LegacyLedgerDashboardCard extends StatelessWidget {
  const _LegacyLedgerDashboardCard({
    required this.profile,
    required this.readiness,
    required this.onAddPlan,
    required this.onHeartbeatCheck,
  });

  final ProfileModel profile;
  final IntentRuntimeReadinessModel readiness;
  final VoidCallback onAddPlan;
  final Future<void> Function() onHeartbeatCheck;

  String _relative(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 60) {
      return "${diff.inMinutes.clamp(1, 59)} นาทีที่แล้ว";
    }
    if (diff.inHours < 24) {
      return "${diff.inHours} ชม. ที่แล้ว";
    }
    return "${diff.inDays} วันที่แล้ว";
  }

  @override
  Widget build(BuildContext context) {
    final entries = readiness.currentArtifact?.sealedReleaseCandidate.entries ??
        const <SealedReleaseEntryModel>[];
    final heartbeatOk =
        DateTime.now().difference(profile.lastActiveAt).inDays <= 1;
    final statusText = heartbeatOk ? "ปลอดภัย" : "ต้องตรวจสอบ";
    final statusColor =
        heartbeatOk ? const Color(0xFFE9F6EF) : const Color(0xFFFFF7ED);

    return Card(
      margin: EdgeInsets.zero,
      color: const Color(0xFF18212D),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "สมุดบัญชีมรดก",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(999),
                          color: statusColor,
                        ),
                        child: Text(
                          "สถานะ: $statusText (อัปเดตล่าสุดเมื่อ ${_relative(profile.lastActiveAt)})",
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
                FilledButton.icon(
                  onPressed: onAddPlan,
                  icon: const Icon(Icons.add),
                  label: const Text("เพิ่มแผนมรดกใหม่"),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: const Color(0xFF243246),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "สัญญาณชีพดิจิทัล (Heartbeat)",
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: heartbeatOk ? 1 : 0.4,
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(999),
                    backgroundColor: Colors.white24,
                    color: heartbeatOk
                        ? const Color(0xFF6FD6B0)
                        : const Color(0xFFF5C07A),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          heartbeatOk
                              ? "ระบบยังตรวจพบการใช้งานปกติ"
                              : "ยังไม่พบการใช้งานล่าสุด กรุณาตรวจสอบ",
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ),
                      TextButton(
                        onPressed: onHeartbeatCheck,
                        child: const Text("เช็กตอนนี้"),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            if (entries.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.white,
                ),
                child: const Text(
                  "ยังไม่มีผู้รับมรดกในแผนนี้ เริ่มเพิ่มแผนแรกได้เลย",
                ),
              )
            else
              ...entries.take(3).toList().asMap().entries.map(
                (entry) {
                  final index = entry.key;
                  final item = entry.value;
                  final fallbackName =
                      profile.beneficiaryName?.trim().isNotEmpty == true
                          ? profile.beneficiaryName!.trim()
                          : "ผู้รับมรดก";
                  final displayName = item.kind == "self_recovery"
                      ? "เจ้าของบัญชี (คุณ)"
                      : (index == 0 ? fallbackName : "ผู้รับมรดก ${index + 1}");
                  final status = item.kind == "self_recovery"
                      ? "กู้คืนได้เมื่อยืนยันตัวตน"
                      : "รอการยืนยันตัวตน ${profile.legacyInactivityDays} วัน";
                  return Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: _LegacyRecipientCard(
                      displayName: displayName,
                      deliveryLabel: item.assetLabel,
                      statusLabel: status,
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _LegacyRecipientCard extends StatelessWidget {
  const _LegacyRecipientCard({
    required this.displayName,
    required this.deliveryLabel,
    required this.statusLabel,
  });

  final String displayName;
  final String deliveryLabel;
  final String statusLabel;

  @override
  Widget build(BuildContext context) {
    final initial = displayName.isEmpty ? "?" : displayName[0].toUpperCase();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: Colors.white,
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: const Color(0xFFEFF6F5),
            child: Text(initial),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text("ข้อมูลที่ส่งมอบ: $deliveryLabel"),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                color: const Color(0xFFEFF6F5),
              ),
              child: Text(
                statusLabel,
                textAlign: TextAlign.right,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ControlRoomCard extends StatelessWidget {
  const _ControlRoomCard({
    required this.readiness,
    required this.setupComplete,
    required this.primaryActionLabel,
    required this.onPrimaryAction,
    required this.onOpenBuilder,
    required this.onOpenReadiness,
    required this.onOpenSetup,
    required this.onOpenArtifactReview,
    required this.onOpenArtifactHistory,
  });

  final IntentRuntimeReadinessModel readiness;
  final bool setupComplete;
  final String primaryActionLabel;
  final VoidCallback onPrimaryAction;
  final VoidCallback onOpenBuilder;
  final VoidCallback onOpenReadiness;
  final VoidCallback onOpenSetup;
  final VoidCallback onOpenArtifactReview;
  final VoidCallback onOpenArtifactHistory;

  @override
  Widget build(BuildContext context) {
    final artifact = readiness.currentArtifact;
    final currentState = artifact?.artifactState.name ?? "draft";
    final modeLabel = setupComplete ? "Connected mode" : "Finish setup mode";
    final helperCards = _buildHelperCards();
    final scheme = Theme.of(context).colorScheme;

    return Card(
      color: scheme.surfaceContainerHighest.withValues(alpha: 0.55),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.dashboard_customize_outlined),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    "Control room",
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                _ReadinessBadge(label: readiness.readinessLabel),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              "Mode: $modeLabel | Current state: $currentState | Warnings: ${readiness.warningCount}",
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _MetricChip(label: "Artifacts ${readiness.historyCount}"),
                _MetricChip(label: "Ready ${readiness.readyArtifactCount}"),
                _MetricChip(
                  label: "Reviewed ${readiness.reviewedArtifactCount}",
                ),
                _MetricChip(
                  label: "Promoted ${readiness.promotedArtifactCount}",
                ),
                _MetricChip(
                  label:
                      readiness.draftInSync ? "Draft in sync" : "Draft changed",
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(readiness.summary),
            if (readiness.currentScenarioTitle != null) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: scheme.outlineVariant.withValues(alpha: 0.45),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Scenario focus: ${readiness.currentScenarioTitle}",
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    if (readiness.currentScenarioSummary != null) ...[
                      const SizedBox(height: 6),
                      Text(readiness.currentScenarioSummary!),
                    ],
                  ],
                ),
              ),
            ],
            const SizedBox(height: 8),
            Text(
              "Primary action: ${readiness.primaryActionLabel}",
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text("Next action: ${readiness.nextStep}"),
            if (readiness.actionPlan.isNotEmpty) ...[
              const SizedBox(height: 10),
              const Text(
                "Action plan",
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              ...readiness.actionPlan.map(
                (step) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text("- $step"),
                ),
              ),
            ],
            if (!setupComplete) ...[
              const SizedBox(height: 8),
              const Text(
                "Setup is not complete yet. Finish beneficiary identity and consent defaults before relying on this workspace.",
              ),
            ],
            if (helperCards.isNotEmpty) ...[
              const SizedBox(height: 14),
              const Text(
                "Guided next steps",
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 10),
              ...helperCards,
            ],
            const SizedBox(height: 14),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                FilledButton(
                  onPressed: onPrimaryAction,
                  child: Text(primaryActionLabel),
                ),
                OutlinedButton(
                  onPressed: onOpenReadiness,
                  child: const Text("Open readiness details"),
                ),
                if (!setupComplete)
                  OutlinedButton(
                    onPressed: onOpenSetup,
                    child: const Text("Complete beta setup"),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildHelperCards() {
    if (!readiness.hasArtifact) {
      return [
        _StateHelperCard(
          title: "Draft workspace only",
          body:
              "You have a working draft but no exported handoff version yet. Export the first version so review, history, and readiness can track a concrete release path.",
          cue:
              "Best next move: export the first handoff version from Intent Builder.",
          actionLabel: "Open builder",
          onTap: onOpenBuilder,
        ),
      ];
    }

    if (readiness.hasBlockingErrors) {
      return [
        _StateHelperCard(
          title: "Blocking compiler issues",
          body:
              "The latest artifact still carries compiler errors. Keep editing in Intent Builder until those errors are resolved before you treat this artifact as reviewable or ready.",
          cue: "Best next move: fix blocking issues and export again.",
          actionLabel: "Fix in builder",
          onTap: onOpenBuilder,
        ),
      ];
    }

    if ((readiness.currentArtifact?.activeEntryCount ?? 0) == 0) {
      return [
        _StateHelperCard(
          title: "No active entries yet",
          body:
              "The current artifact does not contain an active route. Activate at least one intent entry so the artifact reflects a real delivery or self-recovery path.",
          cue: "Best next move: activate an entry, then export again.",
          actionLabel: "Open builder",
          onTap: onOpenBuilder,
        ),
      ];
    }

    final artifact = readiness.currentArtifact!;
    if (artifact.artifactState == IntentArtifactState.exported) {
      return [
        _StateHelperCard(
          title: "Export completed",
          body:
              "The exported version is waiting for review. This is the best moment to inspect issues and safety posture before moving forward.",
          cue: "Best next move: review the exported artifact now.",
          actionLabel: "Open review",
          onTap: onOpenArtifactReview,
        ),
      ];
    }

    if (artifact.artifactState == IntentArtifactState.reviewed &&
        !readiness.draftInSync) {
      return [
        _StateHelperCard(
          title: "Reviewed but stale",
          body:
              "This version was reviewed, but the draft changed afterward. Treat that review as outdated until a fresh export captures the latest draft.",
          cue:
              "Best next move: re-export from the latest draft before marking anything ready.",
          actionLabel: "Open history",
          onTap: onOpenArtifactHistory,
        ),
      ];
    }

    if (artifact.artifactState == IntentArtifactState.reviewed) {
      return [
        _StateHelperCard(
          title: "Reviewed and in sync",
          body:
              "The reviewed version still matches your current draft. This is the cleanest moment to mark it ready for real use.",
          cue:
              "Best next move: mark the reviewed artifact ready while sync still holds.",
          actionLabel: "Open builder",
          onTap: onOpenBuilder,
        ),
      ];
    }

    if (artifact.artifactState == IntentArtifactState.ready &&
        !readiness.draftInSync) {
      return [
        _StateHelperCard(
          title: "Ready artifact drifted",
          body:
              "The latest ready version drifted because the draft changed later. Keep it as history only until you export a fresh ready candidate.",
          cue:
              "Best next move: re-export the latest draft to restore runtime confidence.",
          actionLabel: "Open history",
          onTap: onOpenArtifactHistory,
        ),
      ];
    }

    if (artifact.artifactState == IntentArtifactState.ready) {
      return [
        _StateHelperCard(
          title: "Runtime candidate is healthy",
          body:
              "The latest version is ready and in sync. From here the main job is to keep the workspace stable as intentional changes happen.",
          cue:
              "Best next move: use review and history tools only when you intentionally change the draft.",
          actionLabel: "Review artifact",
          onTap: onOpenArtifactReview,
        ),
      ];
    }

    return const [];
  }
}

class _RuntimeReadinessCard extends StatelessWidget {
  const _RuntimeReadinessCard({
    required this.readiness,
    required this.onOpenReadiness,
    required this.onOpenBuilder,
  });

  final IntentRuntimeReadinessModel readiness;
  final VoidCallback onOpenReadiness;
  final VoidCallback onOpenBuilder;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final statusColor = readiness.readyForRuntime
        ? scheme.tertiaryContainer.withValues(alpha: 0.45)
        : readiness.hasArtifact
            ? scheme.primaryContainer.withValues(alpha: 0.35)
            : scheme.surfaceContainerHighest.withValues(alpha: 0.5);

    return Card(
      color: statusColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.fact_check_outlined),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    "Runtime readiness",
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                _ReadinessBadge(label: readiness.readinessLabel),
              ],
            ),
            const SizedBox(height: 10),
            Text(readiness.summary),
            const SizedBox(height: 10),
            Text(
              "History: ${readiness.historyCount} versions | Ready: ${readiness.readyArtifactCount} | Reviewed: ${readiness.reviewedArtifactCount} | Promoted: ${readiness.promotedArtifactCount}",
            ),
            const SizedBox(height: 6),
            Text(
              readiness.draftInSync
                  ? "Draft sync: current draft still matches the latest exported artifact."
                  : "Draft sync: current draft changed since the latest export.",
            ),
            if (readiness.blockers.isNotEmpty) ...[
              const SizedBox(height: 10),
              const Text(
                "Runtime blockers",
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              ...readiness.blockers.map(
                (blocker) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text("- $blocker"),
                ),
              ),
            ],
            const SizedBox(height: 10),
            Text(readiness.nextStep),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                OutlinedButton(
                  onPressed: onOpenReadiness,
                  child: const Text("Readiness details"),
                ),
                OutlinedButton(
                  onPressed: onOpenBuilder,
                  child: const Text("Open Intent Builder"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InlineStateCard extends StatelessWidget {
  const _InlineStateCard({
    required this.message,
    this.isError = false,
    this.showSpinner = false,
  });

  final String message;
  final bool isError;
  final bool showSpinner;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      color: isError
          ? scheme.errorContainer.withValues(alpha: 0.35)
          : scheme.surfaceContainerHighest.withValues(alpha: 0.5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            if (showSpinner)
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              Icon(
                isError ? Icons.warning_amber_rounded : Icons.info_outline,
                size: 20,
              ),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
  }
}

class _ReadinessBadge extends StatelessWidget {
  const _ReadinessBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: scheme.primaryContainer.withValues(alpha: 0.7),
      ),
      child: Text(label),
    );
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: scheme.surfaceContainerHighest,
      ),
      child: Text(label),
    );
  }
}

class _StateHelperCard extends StatelessWidget {
  const _StateHelperCard({
    required this.title,
    required this.body,
    required this.cue,
    required this.actionLabel,
    required this.onTap,
  });

  final String title;
  final String body;
  final String cue;
  final String actionLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        border:
            Border.all(color: scheme.outlineVariant.withValues(alpha: 0.45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text(body),
          const SizedBox(height: 8),
          Text(cue, style: const TextStyle(fontWeight: FontWeight.w500)),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton(onPressed: onTap, child: Text(actionLabel)),
          ),
        ],
      ),
    );
  }
}

class _DashboardActionCard extends StatelessWidget {
  const _DashboardActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      color: scheme.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.45)),
      ),
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
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
          '${preset.summary}\nProduct boundary: this app coordinates secure handoff and does not replace legal will workflows.',
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
