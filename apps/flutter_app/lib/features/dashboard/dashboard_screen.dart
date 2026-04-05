import 'package:digital_legacy_weaver/features/beta/beta_feedback_screen.dart';
import 'package:digital_legacy_weaver/features/connectors/presentation/connectors_screen.dart';
import 'package:digital_legacy_weaver/features/intent_builder/intent_artifact_compare_screen.dart';
import 'package:digital_legacy_weaver/features/intent_builder/intent_artifact_review_screen.dart';
import 'package:digital_legacy_weaver/features/intent_builder/intent_canonical_artifact_model.dart';
import 'package:digital_legacy_weaver/features/intent_builder/intent_canonical_artifact_provider.dart';
import 'package:digital_legacy_weaver/features/intent_builder/intent_builder_screen.dart';
import 'package:digital_legacy_weaver/features/intent_builder/intent_runtime_readiness_model.dart';
import 'package:digital_legacy_weaver/features/intent_builder/intent_runtime_readiness_screen.dart';
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
          profileAsync.when(
            data: (profile) => safetyAsync.when(
              data: (settings) {
                final artifactAsync = ref.watch(intentCanonicalArtifactProvider(profile.id));
                final artifactHistoryAsync = ref.watch(intentCanonicalArtifactHistoryProvider(profile.id));
                final readinessAsync = ref.watch(intentRuntimeReadinessProvider(profile.id));
                final setupComplete =
                    (profile.beneficiaryEmail?.trim().isNotEmpty ?? false) &&
                    settings.legalDisclaimerAccepted;
                return Column(
                  children: [
                    readinessAsync.when(
                      data: (readiness) => _ControlRoomCard(
                        readiness: readiness,
                        setupComplete: setupComplete,
                        primaryActionLabel: readiness.primaryActionLabel,
                        onPrimaryAction: () {
                          final actionKey = readiness.primaryActionKey;
                          if (actionKey == "review_exported_artifact" &&
                              readiness.currentArtifact != null) {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => IntentArtifactReviewScreen(
                                  artifact: readiness.currentArtifact!,
                                ),
                              ),
                            );
                            return;
                          }

                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => IntentBuilderScreen(
                                profile: profile,
                                settings: settings,
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
                        onOpenReadiness: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => IntentRuntimeReadinessScreen(
                                readiness: readiness,
                              ),
                            ),
                          );
                        },
                        onOpenSetup: () async {
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
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
                    if (readinessAsync.hasValue) const SizedBox(height: 12),
                    Card(
                      child: ListTile(
                        title: const Text("Intent Builder"),
                        subtitle: const Text("Draft user-defined legacy intent before compiling it into PTN"),
                        trailing: const Icon(Icons.chevron_right),
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
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
                    artifactAsync.when(
                      data: (artifact) => artifactHistoryAsync.when(
                        data: (history) => Card(
                          color: artifact == null ? const Color(0xFFFFF7ED) : null,
                          child: Column(
                            children: [
                              ListTile(
                                leading: const Icon(Icons.verified_outlined),
                                title: const Text("Canonical artifact status"),
                                subtitle: Text(
                                  artifact == null
                                      ? "No local canonical PTN artifact exported yet."
                                      : "State ${artifact.artifactState.name}. Contract ${artifact.contractVersion} with ${artifact.activeEntryCount} active entries across ${history.length} artifact versions.${artifact.promotedFromArtifactId != null ? " Latest artifact was promoted from history." : ""} Reviewed artifacts must stay in sync before they can be treated as ready.",
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
                                      builder: (_) => IntentArtifactReviewScreen(artifact: artifact),
                                    ),
                                  );
                                },
                              ),
                              if (artifact != null && history.length > 1)
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                                  child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: OutlinedButton(
                                      onPressed: () {
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (_) => IntentArtifactCompareScreen(
                                              currentArtifact: artifact,
                                              compareArtifact: history[1],
                                            ),
                                          ),
                                        );
                                      },
                                      child: const Text("Compare latest with previous"),
                                    ),
                                  ),
                                ),
                              if (artifact != null && history.length > 1)
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                                  child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      "Older versions can also be promoted again from Intent Builder without deleting history.",
                                      style: Theme.of(context).textTheme.bodySmall,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        loading: () => const SizedBox.shrink(),
                        error: (_, __) => const SizedBox.shrink(),
                      ),
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
                  ],
                );
              },
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
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
            Text('2) Self-recovery delivery to backup email for password recovery'),
            SizedBox(height: 10),
            Text('Technical companion only: beneficiaries complete any required legal verification in the appropriate legal or service context.'),
          ],
        ),
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
  });

  final IntentRuntimeReadinessModel readiness;
  final bool setupComplete;
  final String primaryActionLabel;
  final VoidCallback onPrimaryAction;
  final VoidCallback onOpenBuilder;
  final VoidCallback onOpenReadiness;
  final VoidCallback onOpenSetup;

  @override
  Widget build(BuildContext context) {
    final artifact = readiness.currentArtifact;
    final currentState = artifact?.artifactState.name ?? "draft";
    final modeLabel = setupComplete ? "Live backend mode" : "Setup still incomplete";
    final helperCards = _buildHelperCards();

    return Card(
      color: const Color(0xFFF7F1E8),
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
                _MetricChip(label: "Reviewed ${readiness.reviewedArtifactCount}"),
                _MetricChip(label: "Promoted ${readiness.promotedArtifactCount}"),
                _MetricChip(
                  label: readiness.draftInSync ? "Draft in sync" : "Draft changed",
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
                  color: const Color(0xFFEFE4D6),
                  borderRadius: BorderRadius.circular(14),
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
                "Setup is still incomplete. Finish beneficiary and consent defaults before treating this workspace as operational.",
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
      return const [
        _StateHelperCard(
          title: "Draft workspace only",
          body:
              "You have a working draft but no canonical artifact yet. Export the first PTN artifact so review, history, and readiness can start tracking a concrete runtime candidate.",
          cue: "Best next move: export the first canonical artifact from Intent Builder.",
        ),
      ];
    }

    if (readiness.hasBlockingErrors) {
      return const [
        _StateHelperCard(
          title: "Blocking compiler issues",
          body:
              "The latest artifact still carries compiler errors. Keep editing in Intent Builder until those errors are resolved before you treat this artifact as reviewable or ready.",
          cue: "Best next move: fix blocking issues and export again.",
        ),
      ];
    }

    if ((readiness.currentArtifact?.activeEntryCount ?? 0) == 0) {
      return const [
        _StateHelperCard(
          title: "No active entries yet",
          body:
              "The current artifact does not contain an active route. Activate at least one intent entry so the artifact reflects a real delivery or self-recovery path.",
          cue: "Best next move: activate an entry, then export again.",
        ),
      ];
    }

    final artifact = readiness.currentArtifact!;
    if (artifact.artifactState == IntentArtifactState.exported) {
      return const [
        _StateHelperCard(
          title: "Export completed",
          body:
              "The artifact exists and is now waiting for review. This is the right moment to inspect the PTN, compiler report, and trace before advancing the state.",
          cue: "Best next move: review the exported artifact now.",
        ),
      ];
    }

    if (artifact.artifactState == IntentArtifactState.reviewed && !readiness.draftInSync) {
      return const [
        _StateHelperCard(
          title: "Reviewed but stale",
          body:
              "The artifact was reviewed, but the draft changed afterward. Treat the review as outdated until a fresh export captures the current draft again.",
          cue: "Best next move: re-export from the latest draft before marking anything ready.",
        ),
      ];
    }

    if (artifact.artifactState == IntentArtifactState.reviewed) {
      return const [
        _StateHelperCard(
          title: "Reviewed and in sync",
          body:
              "The artifact has been reviewed and still matches the current draft. This is the cleanest moment to mark it ready for runtime use.",
          cue: "Best next move: mark the reviewed artifact ready while sync still holds.",
        ),
      ];
    }

    if (artifact.artifactState == IntentArtifactState.ready && !readiness.draftInSync) {
      return const [
        _StateHelperCard(
          title: "Ready artifact drifted",
          body:
              "The latest artifact was ready, but the draft changed later. Keep the ready state as historical context only until you export a fresh runtime candidate.",
          cue: "Best next move: re-export the latest draft to restore runtime confidence.",
        ),
      ];
    }

    if (artifact.artifactState == IntentArtifactState.ready) {
      return const [
        _StateHelperCard(
          title: "Runtime candidate is healthy",
          body:
              "The latest artifact is ready, in sync, and suitable to treat as the current runtime candidate. From here the main job is to keep the workspace stable as changes happen.",
          cue: "Best next move: use review and history tools only when you intentionally change the draft.",
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
    final statusColor = readiness.readyForRuntime
        ? const Color(0xFFE9F6EF)
        : readiness.hasArtifact
            ? const Color(0xFFFFF7ED)
            : const Color(0xFFF7F1E8);

    return Card(
      color: statusColor,
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

class _ReadinessBadge extends StatelessWidget {
  const _ReadinessBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: const Color(0xFFE5D7C5),
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: const Color(0xFFE9DDCC),
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
  });

  final String title;
  final String body;
  final String cue;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFEFE4D6),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Text(body),
          const SizedBox(height: 8),
          Text(
            cue,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ],
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

