import 'package:digital_legacy_weaver/features/beta/beta_feedback_screen.dart';
import 'package:digital_legacy_weaver/features/connectors/presentation/connectors_screen.dart';
import 'package:digital_legacy_weaver/core/widgets/app_state_panel.dart';
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
import 'package:digital_legacy_weaver/features/runtime/runtime_status_screen.dart';
import 'package:digital_legacy_weaver/features/settings/safety_settings_model.dart';
import 'package:digital_legacy_weaver/features/settings/privacy_profile_preset.dart';
import 'package:digital_legacy_weaver/features/settings/safety_settings_provider.dart';
import 'package:digital_legacy_weaver/features/settings/safety_settings_screen.dart';
import 'package:digital_legacy_weaver/features/unlock/unlock_delivery_screen.dart';
import 'package:digital_legacy_weaver/features/vault/recovery_vault_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Legacy copy anchors kept for compatibility tests:
// "Control room"
// "Runtime readiness"

String _artifactStateUiLabel(IntentArtifactState? state) {
  switch (state) {
    case IntentArtifactState.draft:
      return "แบบร่าง";
    case IntentArtifactState.exported:
      return "ฉบับพร้อมส่ง";
    case IntentArtifactState.reviewed:
      return "ตรวจทานแล้ว";
    case IntentArtifactState.ready:
      return "พร้อมใช้งาน";
    case null:
      return "ยังไม่มีฉบับ";
  }
}

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
            child: const Text("ออกจากระบบ"),
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
                      message: "กำลังโหลดสถานะเส้นทางเจ้าของ...",
                    ),
                    error: (_, __) => const _InlineStateCard(
                      message: "โหลดสถานะเส้นทางเจ้าของไม่สำเร็จในขณะนี้",
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
                          title: const Text("ตั้งค่าเริ่มต้นให้ครบก่อนใช้งาน"),
                          subtitle: const Text(
                            "เพิ่มข้อมูลผู้รับ ช่องทางสำรอง และการยินยอมให้ครบก่อนใช้งานจริง แอปนี้ช่วยประสานการส่งต่ออย่างปลอดภัย และไม่ใช่พินัยกรรมทางกฎหมาย",
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
                      message:
                          "กำลังตรวจสอบความครบถ้วนของการตั้งค่าเริ่มต้น...",
                    ),
                    error: (_, __) => const _InlineStateCard(
                      message:
                          "ยืนยันความครบถ้วนของการตั้งค่าเริ่มต้นไม่สำเร็จ",
                      isError: true,
                    ),
                  ),
                ],
              );
            },
            loading: () => const _InlineStateCard(
              message: "กำลังโหลดข้อมูลเจ้าของและสถานะแผนปัจจุบัน...",
              showSpinner: true,
            ),
            error: (_, __) => const _InlineStateCard(
              message:
                  "ยังโหลดข้อมูลเจ้าของไม่สำเร็จ กรุณารีเฟรชแล้วลองใหม่อีกครั้ง",
              isError: true,
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
                              settings: settings,
                              readiness: readiness,
                              onAddPlan: openBuilder,
                              onHeartbeatCheck: () async {
                                await ref
                                    .read(profileRepositoryProvider)
                                    .markAlive();
                                ref.invalidate(profileProvider);
                              },
                              onSetKillSwitch: (enabled) async {
                                await ref
                                    .read(safetySettingsProvider.notifier)
                                    .save(
                                      remindersEnabled:
                                          settings.remindersEnabled,
                                      reminderOffsetsDays:
                                          settings.reminderOffsetsDays,
                                      gracePeriodDays: settings.gracePeriodDays,
                                      proofOfLifeCheckMode:
                                          settings.proofOfLifeCheckMode,
                                      proofOfLifeFallbackChannels:
                                          settings.proofOfLifeFallbackChannels,
                                      serverHeartbeatFallbackEnabled: settings
                                          .serverHeartbeatFallbackEnabled,
                                      iosBackgroundRiskAcknowledged: settings
                                          .iosBackgroundRiskAcknowledged,
                                      legalDisclaimerAccepted:
                                          settings.legalDisclaimerAccepted,
                                      emergencyPauseUntil: enabled
                                          ? DateTime.now().add(
                                              const Duration(days: 7),
                                            )
                                          : null,
                                      requireTotpUnlock:
                                          settings.requireTotpUnlock,
                                      guardianQuorumEnabled:
                                          settings.guardianQuorumEnabled,
                                      guardianQuorumRequired:
                                          settings.guardianQuorumRequired,
                                      guardianQuorumPoolSize:
                                          settings.guardianQuorumPoolSize,
                                      emergencyAccessEnabled:
                                          settings.emergencyAccessEnabled,
                                      emergencyAccessRequiresBeneficiaryRequest:
                                          settings
                                              .emergencyAccessRequiresBeneficiaryRequest,
                                      emergencyAccessRequiresGuardianQuorum:
                                          settings
                                              .emergencyAccessRequiresGuardianQuorum,
                                      emergencyAccessGraceHours:
                                          settings.emergencyAccessGraceHours,
                                      deviceRebindInProgress:
                                          settings.deviceRebindInProgress,
                                      deviceRebindStartedAt:
                                          settings.deviceRebindStartedAt,
                                      deviceRebindGraceHours:
                                          settings.deviceRebindGraceHours,
                                      recoveryKeyEnabled:
                                          settings.recoveryKeyEnabled,
                                      deliveryAccessTtlHours:
                                          settings.deliveryAccessTtlHours,
                                      payloadRetentionDays:
                                          settings.payloadRetentionDays,
                                      auditLogRetentionDays:
                                          settings.auditLogRetentionDays,
                                      privateFirstMode:
                                          settings.privateFirstMode,
                                      tracePrivacyProfile:
                                          settings.tracePrivacyProfile,
                                    );
                                ref.invalidate(safetySettingsProvider);
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
                        message: "กำลังโหลดสถานะศูนย์ควบคุมแผน...",
                      ),
                      error: (_, __) => const _InlineStateCard(
                        message: "สถานะศูนย์ควบคุมแผนยังไม่พร้อมใช้งานชั่วคราว",
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
                        message: "โหลดรายละเอียดสถานะผลิตภัณฑ์ไม่สำเร็จ",
                        isError: true,
                      ),
                    ),
                    if (readinessAsync.hasValue) const SizedBox(height: 12),
                    _DashboardActionCard(
                      title: "ตัวสร้างแผนเจตจำนง",
                      subtitle:
                          "จัดแผนกู้คืนและส่งมอบด้วยภาษาคน ก่อนสร้างฉบับพร้อมใช้งาน",
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
                        message: "กำลังโหลดสรุปความพร้อมใช้งาน...",
                      ),
                      error: (_, __) => const _InlineStateCard(
                        message: "ยังไม่สามารถแสดงสรุปความพร้อมใช้งานได้",
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
                                title: const Text("สถานะฉบับพร้อมใช้งาน"),
                                subtitle: Text(
                                  artifact == null
                                      ? "ยังไม่มีฉบับพร้อมส่ง"
                                      : "สถานะปัจจุบัน: ${_artifactStateUiLabel(artifact.artifactState)} • เวอร์ชัน ${artifact.contractVersion} • รายการใช้งานอยู่ ${artifact.activeEntryCount} รายการ • ประวัติทั้งหมด ${history.length} เวอร์ชัน${artifact.promotedFromArtifactId != null ? " (เวอร์ชันล่าสุดมาจากการโปรโมตจากประวัติ)" : ""}",
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
                                        "เทียบฉบับล่าสุดกับฉบับก่อนหน้า",
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
                                      "คุณยังสามารถโปรโมตเวอร์ชันเก่าจากหน้าตัวสร้างแผนได้ โดยไม่ต้องลบประวัติเดิม",
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
                          message: "กำลังโหลดประวัติเวอร์ชันเอกสาร...",
                        ),
                        error: (_, __) => const _InlineStateCard(
                          message: "โหลดประวัติเวอร์ชันเอกสารไม่สำเร็จ",
                          isError: true,
                        ),
                      ),
                      loading: () => const _InlineStateCard(
                        message: "กำลังโหลดสถานะเวอร์ชันเอกสารหลัก...",
                      ),
                      error: (_, __) => const _InlineStateCard(
                        message: "โหลดสถานะเวอร์ชันเอกสารหลักไม่สำเร็จ",
                        isError: true,
                      ),
                    ),
                  ],
                );
              },
              loading: () => const _InlineStateCard(
                  message: "กำลังโหลดการตั้งค่าความปลอดภัย..."),
              error: (_, __) => const _InlineStateCard(
                message: "โหลดการตั้งค่าความปลอดภัยของพื้นที่นี้ไม่สำเร็จ",
                isError: true,
              ),
            ),
            loading: () =>
                const _InlineStateCard(message: "กำลังเตรียมพื้นที่ทำงาน..."),
            error: (_, __) => const _InlineStateCard(
              message: "ข้อมูลพื้นที่ทำงานยังไม่พร้อมใช้งานชั่วคราว",
              isError: true,
            ),
          ),
          const SizedBox(height: 16),
          const RecoveryVaultSection(),
          const SizedBox(height: 16),
          safetyAsync.when(
            data: (settings) => _PolicySelectorCard(settings: settings),
            loading: () => const _InlineStateCard(
                message: "กำลังโหลดโปรไฟล์ความเป็นส่วนตัว..."),
            error: (_, __) => const _InlineStateCard(
              message: "โหลดโปรไฟล์ความเป็นส่วนตัวไม่สำเร็จ",
              isError: true,
            ),
          ),
          const SizedBox(height: 16),
          _DashboardActionCard(
            title: "ปลายทางที่พร้อมใช้งานร่วมพาร์ทเนอร์",
            subtitle: "จัดการปลายทางและรายการอ้างอิงก่อนส่งต่อตามแผน",
            icon: Icons.hub_outlined,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ConnectorsScreen()),
              );
            },
          ),
          const SizedBox(height: 16),
          _DashboardActionCard(
            title: "ตัวควบคุมความเสี่ยง",
            subtitle:
                "ยินยอมทางกฎหมาย การเตือน ระยะผ่อนผัน โหมดส่วนตัว และหยุดฉุกเฉิน",
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
            title: "สถานะ Runtime ของทีม",
            subtitle:
                "ดู dispatch health, last run และเหตุผลที่ fail ล่าสุด เพื่อแก้ไขได้เร็วขึ้น",
            icon: Icons.monitor_heart_outlined,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const RuntimeStatusScreen(),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          _DashboardActionCard(
            title: "หน้ารับมอบของผู้รับ",
            subtitle:
                "โค้ดรับมอบ การยืนยันตัวตน และขั้นตอนปลอดภัยก่อนเปิดข้อมูล",
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
            title: "ส่งข้อเสนอแนะ",
            subtitle: "รายงานปัญหา ความเสถียร หรือคำแนะนำด้านการใช้งาน",
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
            'โหมดส่วนตัวก่อน',
            style: theme.textTheme.titleLarge?.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 8),
          Text(
            'เหลืออีก $daysLeft วันก่อนเข้าเงื่อนไขส่งมอบ',
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
            child: const Text('ฉันยังใช้งานอยู่'),
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
              "สถานะเส้นทางของเจ้าของ",
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            const Text(
              "พื้นที่นี้ออกแบบให้ใช้งานจริง: กู้คืนบัญชีเจ้าของอย่างปลอดภัยขณะยังใช้งานอยู่ และส่งต่อให้ผู้รับเมื่อครบเงื่อนไขเท่านั้น",
            ),
            const SizedBox(height: 10),
            Text(
              beneficiaryIdentityReady
                  ? "1. ชุดข้อมูลยืนยันตัวตนผู้รับ: พร้อมใช้งาน"
                  : "1. ชุดข้อมูลยืนยันตัวตนผู้รับ: ยังไม่ครบ",
            ),
            Text(
              proofOfLifeFallbackReady
                  ? "2. ช่องทางยืนยันว่ายังมีชีวิตอยู่ (สำรอง): พร้อมใช้งาน"
                  : "2. ช่องทางยืนยันว่ายังมีชีวิตอยู่ (สำรอง): ยังไม่ครบ",
            ),
            Text(
              legalConsentReady
                  ? "3. การยินยอมด้านความปลอดภัย/กฎหมาย: พร้อมใช้งาน"
                  : "3. การยินยอมด้านความปลอดภัย/กฎหมาย: ยังไม่ครบ",
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
              'รูปแบบการส่งมอบ',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 8),
            Text('1) ส่งต่อให้ผู้รับเมื่อขาดการติดต่อเป็นเวลานาน'),
            SizedBox(height: 4),
            Text(
              '2) ส่งเส้นทางกู้คืนให้เจ้าของที่อีเมลสำรอง',
            ),
            SizedBox(height: 10),
            Text(
              'หมายเหตุ: แอปช่วยประสานงานเท่านั้น ผู้รับยังต้องดำเนินการยืนยันทางกฎหมายกับหน่วยงานที่เกี่ยวข้อง',
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
              "เป้าหมายที่ผู้ใช้จะได้รับ",
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            const Text(
              "ใช้งานเหมือนผลิตภัณฑ์จริง ไม่ใช่หน้าตั้งค่าเชิงเทคนิค: ตั้งค่าครั้งเดียว ตรวจความพร้อม แล้วดูแลเส้นทางกู้คืน/ส่งมอบให้พร้อมเสมอ",
            ),
            const SizedBox(height: 10),
            Text(
              setupComplete
                  ? "1. การตั้งค่าเริ่มต้น: ครบแล้ว"
                  : "1. การตั้งค่าเริ่มต้น: ยังไม่ครบ",
            ),
            Text(
              readiness.readyForRuntime
                  ? "2. แผนส่งมอบ: พร้อมใช้งานจริง"
                  : "2. แผนส่งมอบ: ยังต้องดำเนินการเพิ่ม",
            ),
            Text(
              canDeliver
                  ? "3. เส้นทางรับมอบของผู้รับ: พร้อมทดสอบอย่างปลอดภัย"
                  : "3. เส้นทางรับมอบของผู้รับ: ควรรอจนตั้งค่าและความพร้อมครบก่อน",
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 8,
              children: [
                if (!setupComplete)
                  FilledButton(
                    onPressed: onOpenSetup,
                    child: const Text("ตั้งค่าเริ่มต้นให้ครบก่อน"),
                  ),
                OutlinedButton(
                  onPressed: onOpenBuilder,
                  child: const Text("เปิดพื้นที่จัดแผน"),
                ),
                OutlinedButton(
                  onPressed: onOpenReceipt,
                  child: const Text("เปิดหน้ารับมอบของผู้รับ"),
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
              "สถานะผลิตภัณฑ์ที่ใช้งานได้จริง",
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            const Text(
              "เจ้าของสามารถกำหนดแผนมรดกดิจิทัลแบบส่วนตัว คุมสิทธิ์ขณะยังใช้งาน และส่งต่อให้ผู้รับที่ถูกต้องผ่านขั้นตอนที่ปลอดภัยเมื่อถึงเวลา",
            ),
            const SizedBox(height: 12),
            const Text(
              "สิ่งที่ใช้งานได้แล้วตอนนี้",
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            Text(
              setupComplete
                  ? "1. การตั้งค่าเจ้าของ: ครบแล้ว"
                  : "1. การตั้งค่าเจ้าของ: ยังไม่ครบ",
            ),
            Text(
              readiness.hasArtifact
                  ? "2. การส่งออกเอกสารหลักและประวัติเวอร์ชัน: พร้อมใช้งาน"
                  : "2. การส่งออกเอกสารหลัก: ยังไม่เริ่ม",
            ),
            Text(
              hasActiveRoute
                  ? "3. มีเส้นทางส่งมอบที่เปิดใช้งานอย่างน้อย 1 เส้นทาง"
                  : "3. ยังไม่มีเส้นทางส่งมอบที่เปิดใช้งาน",
            ),
            Text(
              secureLinkReceiptReady
                  ? "4. เส้นทางรับมอบแบบปลอดภัยของผู้รับ: พร้อมใช้งาน"
                  : "4. เส้นทางรับมอบแบบปลอดภัยของผู้รับ: ยังต้องตั้งค่ายืนยันตัวตน/ช่องทางสำรอง",
            ),
            const SizedBox(height: 10),
            const Text(
              "หมุดหมายถัดไป",
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            Text(
              readiness.readyForRuntime
                  ? "1. ทำรอบตรวจปล่อยเบต้า (toolchain + smoke + ซ้อมส่งมอบแบบควบคุม)"
                  : "1. ดันเวอร์ชันเอกสารปัจจุบันให้ถึงสถานะพร้อมใช้งานโดยไม่มีตัวบล็อก",
            ),
            const Text(
              "2. เสริมความแม่นยำการยืนยันว่ายังมีชีวิตอยู่ข้ามอุปกรณ์ และลดการทริกเกอร์ผิดพลาด",
            ),
            const Text(
              "3. เก็บงานป้องกันส่งผิดคนและปรับเส้นทางยืนยันกับพาร์ทเนอร์ให้เนียนขึ้น",
            ),
            const SizedBox(height: 12),
            const Text(
              "สรุปตัวชี้วัด",
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _MetricChip(
                  label: setupComplete
                      ? "ตั้งค่าเริ่มต้น: ครบแล้ว"
                      : "ตั้งค่าเริ่มต้น: ยังไม่ครบ",
                ),
                _MetricChip(label: "ความพร้อม: ${readiness.readinessLabel}"),
                _MetricChip(
                  label: "เวอร์ชันเอกสาร: ${readiness.historyCount}",
                ),
                _MetricChip(
                  label: "แผนที่ใช้งานอยู่: ${artifact?.activeEntryCount ?? 0}",
                ),
                _MetricChip(
                  label: secureLinkReceiptReady
                      ? "เส้นทางรับมอบ: พร้อม"
                      : "เส้นทางรับมอบ: รอดำเนินการ",
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
    required this.settings,
    required this.readiness,
    required this.onAddPlan,
    required this.onHeartbeatCheck,
    required this.onSetKillSwitch,
  });

  final ProfileModel profile;
  final SafetySettingsModel settings;
  final IntentRuntimeReadinessModel readiness;
  final VoidCallback onAddPlan;
  final Future<void> Function() onHeartbeatCheck;
  final Future<void> Function(bool enabled) onSetKillSwitch;

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
    final now = DateTime.now();
    final inactiveDays = now.difference(profile.lastActiveAt).inDays;
    final daysLeft =
        (profile.legacyInactivityDays - inactiveDays).clamp(0, 9999);
    final triggerProgress =
        (inactiveDays / profile.legacyInactivityDays).clamp(0.0, 1.0);
    final heartbeatOk = now.difference(profile.lastActiveAt).inDays <= 1;
    final statusText = heartbeatOk ? "ปลอดภัย" : "ต้องตรวจสอบ";
    final statusColor =
        heartbeatOk ? const Color(0xFFE9F6EF) : const Color(0xFFFFF7ED);
    final killSwitchOn = settings.emergencyPauseUntil?.isAfter(now) ?? false;
    final proofModeLabel = switch (settings.proofOfLifeCheckMode) {
      "half_life_soft_checkin" => "เช็กอินแบบผ่อนปรน (half-life)",
      "single_tap" => "แตะยืนยันครั้งเดียว",
      "verification_code" => "รหัสยืนยัน",
      _ => "ยืนยันด้วยไบโอเมตริก",
    };
    String triggerSummary(SealedReleaseEntryModel item) {
      if (item.triggerMode == "exact_date") {
        final scheduled = item.scheduledAtUtc?.toLocal();
        if (scheduled != null) {
          return "เริ่มตามวันที่ ${scheduled.toString()}";
        }
        return "เริ่มตามวันที่กำหนด (ยังไม่ตั้งวันเวลา)";
      }
      if (item.triggerMode == "manual_release") {
        return "เริ่มเมื่อยืนยันโหมดฉุกเฉิน";
      }
      return "เริ่มเมื่อไม่พบการใช้งาน ${item.inactivityDays} วัน";
    }

    String statusSummary(SealedReleaseEntryModel item) {
      if (item.kind == "self_recovery") {
        return "กู้คืนได้เมื่อยืนยันตัวตน";
      }
      if (item.triggerMode == "exact_date") {
        return "รอถึงวันเวลาที่กำหนด + ยืนยันซ้ำ ${item.graceDays} วัน";
      }
      if (item.triggerMode == "manual_release") {
        return "รอโหมดฉุกเฉิน + ยืนยันซ้ำ ${item.graceDays} วัน";
      }
      return "รอขาดการติดต่อ ${item.inactivityDays} วัน + ยืนยันซ้ำ ${item.graceDays} วัน";
    }

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
                    "ตัวนับเงื่อนไข + หยุดฉุกเฉิน",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "เหลืออีก $daysLeft วันก่อนเข้าเงื่อนไขส่งมอบ",
                    style: const TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: triggerProgress,
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(999),
                    backgroundColor: Colors.white24,
                    color: const Color(0xFF8AC7FF),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "โหมดเช็กอิน: $proofModeLabel",
                    style: const TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      OutlinedButton.icon(
                        onPressed: onHeartbeatCheck,
                        icon: const Icon(Icons.favorite_border),
                        label: const Text("เช็กอินตอนนี้"),
                      ),
                      FilledButton.tonalIcon(
                        onPressed: () => onSetKillSwitch(!killSwitchOn),
                        icon: Icon(
                          killSwitchOn
                              ? Icons.play_circle_outline
                              : Icons.pause_circle_outline,
                        ),
                        label: Text(
                          killSwitchOn
                              ? "ยกเลิกหยุดฉุกเฉิน"
                              : "เปิดหยุดฉุกเฉิน 7 วัน",
                        ),
                      ),
                    ],
                  ),
                  if (killSwitchOn) ...[
                    const SizedBox(height: 8),
                    Text(
                      "โหมดหยุดฉุกเฉินเปิดอยู่จนถึง ${settings.emergencyPauseUntil!.toLocal()}",
                      style: const TextStyle(color: Color(0xFFFFD7A8)),
                    ),
                  ],
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
                  final triggerLabel = triggerSummary(item);
                  final status = statusSummary(item);
                  final timelineSteps = <String>[
                    "1) $triggerLabel",
                    "2) ยืนยันซ้ำ ${item.graceDays} วัน",
                    item.kind == "self_recovery"
                        ? "3) เปิดสิทธิ์กู้คืนให้เจ้าของบัญชี"
                        : "3) ส่งต่อให้ผู้รับตามช่องทางที่กำหนด",
                  ];
                  return Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: _LegacyRecipientCard(
                      displayName: displayName,
                      deliveryLabel: item.assetLabel,
                      triggerLabel: triggerLabel,
                      timelineSteps: timelineSteps,
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
    required this.triggerLabel,
    required this.timelineSteps,
    required this.statusLabel,
  });

  final String displayName;
  final String deliveryLabel;
  final String triggerLabel;
  final List<String> timelineSteps;
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
                const SizedBox(height: 4),
                Text("เงื่อนไขเริ่มต้น: $triggerLabel"),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: const Color(0xFFF7F2EA),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: timelineSteps
                        .map(
                          (step) => Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(
                              step,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
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
    final currentState = _artifactStateUiLabel(artifact?.artifactState);
    final modeLabel = setupComplete ? "โหมดพร้อมใช้งาน" : "โหมดเตรียมตั้งค่า";
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
                    "ศูนย์ควบคุมแผน",
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                _ReadinessBadge(label: readiness.readinessLabel),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              "โหมด: $modeLabel | สถานะปัจจุบัน: $currentState | คำเตือน: ${readiness.warningCount}",
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _MetricChip(label: "เวอร์ชันทั้งหมด ${readiness.historyCount}"),
                _MetricChip(
                    label: "พร้อมใช้งาน ${readiness.readyArtifactCount}"),
                _MetricChip(
                  label: "รีวิวแล้ว ${readiness.reviewedArtifactCount}",
                ),
                _MetricChip(
                  label: "โปรโมตแล้ว ${readiness.promotedArtifactCount}",
                ),
                _MetricChip(
                  label: readiness.draftInSync
                      ? "แบบร่างตรงกับเวอร์ชัน"
                      : "แบบร่างมีการเปลี่ยนแปลง",
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
                      "เส้นทางที่กำลังโฟกัส: ${readiness.currentScenarioTitle}",
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
              "งานหลักตอนนี้: ${readiness.primaryActionLabel}",
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text("ขั้นตอนถัดไป: ${readiness.nextStep}"),
            if (readiness.actionPlan.isNotEmpty) ...[
              const SizedBox(height: 10),
              const Text(
                "แผนการทำงาน",
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
                "การตั้งค่าเริ่มต้นยังไม่ครบ กรุณาตั้งค่าข้อมูลยืนยันตัวตนผู้รับและการยินยอมให้ครบก่อนใช้งานจริง",
              ),
            ],
            if (helperCards.isNotEmpty) ...[
              const SizedBox(height: 14),
              const Text(
                "ขั้นตอนถัดไปที่แนะนำ",
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
                  child: const Text("ดูรายละเอียดความพร้อม"),
                ),
                if (!setupComplete)
                  OutlinedButton(
                    onPressed: onOpenSetup,
                    child: const Text("ทำขั้นตอนเตรียมใช้งานให้ครบ"),
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
          title: "ยังเป็นโหมดร่างในเครื่อง",
          body:
              "ตอนนี้มีแบบร่างที่ใช้งานได้แล้ว แต่ยังไม่มีฉบับพร้อมส่ง ให้สร้างฉบับแรกก่อน เพื่อให้การรีวิว ประวัติ และความพร้อมอ้างอิงข้อมูลจริงชุดเดียวกัน",
          cue: "แนะนำ: สร้างฉบับพร้อมส่งแรกจากหน้าจัดแผน",
          actionLabel: "เปิดหน้าจัดแผน",
          onTap: onOpenBuilder,
        ),
      ];
    }

    if (readiness.hasBlockingErrors) {
      return [
        _StateHelperCard(
          title: "ยังมีจุดผิดพลาดที่บล็อกการใช้งาน",
          body:
              "เวอร์ชันล่าสุดยังมีข้อผิดพลาดระดับบล็อก ให้แก้ในหน้าจัดแผนจนผ่านก่อน แล้วค่อยถือว่าเวอร์ชันนี้พร้อมรีวิวหรือพร้อมใช้งาน",
          cue: "แนะนำ: แก้ข้อผิดพลาดให้ครบ แล้วส่งออกใหม่",
          actionLabel: "ไปแก้ในหน้าจัดแผน",
          onTap: onOpenBuilder,
        ),
      ];
    }

    if ((readiness.currentArtifact?.activeEntryCount ?? 0) == 0) {
      return [
        _StateHelperCard(
          title: "ยังไม่มีรายการที่เปิดใช้งาน",
          body:
              "เอกสารเวอร์ชันปัจจุบันยังไม่มีแผนที่เปิดใช้งาน ควรเปิดอย่างน้อย 1 รายการ เพื่อให้สะท้อนเส้นทางส่งมอบหรือกู้คืนจริง",
          cue: "แนะนำ: เปิดใช้งาน 1 รายการ แล้วส่งออกใหม่",
          actionLabel: "เปิดหน้าจัดแผน",
          onTap: onOpenBuilder,
        ),
      ];
    }

    final artifact = readiness.currentArtifact!;
    if (artifact.artifactState == IntentArtifactState.exported) {
      return [
        _StateHelperCard(
          title: "สร้างฉบับพร้อมส่งแล้ว",
          body:
              "ฉบับพร้อมส่งล่าสุดกำลังรอการตรวจทาน นี่คือจุดที่เหมาะที่สุดในการตรวจความปลอดภัยและข้อผิดพลาดก่อนเดินหน้าต่อ",
          cue: "แนะนำ: เปิดรีวิวฉบับพร้อมส่งตอนนี้",
          actionLabel: "เปิดหน้ารีวิว",
          onTap: onOpenArtifactReview,
        ),
      ];
    }

    if (artifact.artifactState == IntentArtifactState.reviewed &&
        !readiness.draftInSync) {
      return [
        _StateHelperCard(
          title: "รีวิวแล้ว แต่แบบร่างเปลี่ยนหลังรีวิว",
          body:
              "เวอร์ชันนี้เคยรีวิวแล้ว แต่มีการแก้แบบร่างหลังจากนั้น ให้ถือว่ารีวิวเดิมล้าสมัยจนกว่าจะสร้างฉบับใหม่จากแบบร่างล่าสุด",
          cue: "แนะนำ: สร้างฉบับใหม่จากแบบร่างล่าสุดก่อนทำเครื่องหมายว่าพร้อม",
          actionLabel: "ดูประวัติเวอร์ชัน",
          onTap: onOpenArtifactHistory,
        ),
      ];
    }

    if (artifact.artifactState == IntentArtifactState.reviewed) {
      return [
        _StateHelperCard(
          title: "รีวิวแล้ว และตรงกับแบบร่างปัจจุบัน",
          body:
              "เวอร์ชันที่รีวิวยังตรงกับแบบร่างปัจจุบัน นี่คือช่วงที่เหมาะที่สุดในการทำเครื่องหมายว่าพร้อมใช้งานจริง",
          cue: "แนะนำ: ทำเครื่องหมายพร้อมใช้งานขณะที่ข้อมูลยังตรงกัน",
          actionLabel: "เปิดหน้าจัดแผน",
          onTap: onOpenBuilder,
        ),
      ];
    }

    if (artifact.artifactState == IntentArtifactState.ready &&
        !readiness.draftInSync) {
      return [
        _StateHelperCard(
          title: "เวอร์ชันพร้อมใช้งานไม่ตรงกับแบบร่างล่าสุด",
          body:
              "เวอร์ชันที่พร้อมใช้งานล่าสุดไม่ตรงกับแบบร่าง เพราะมีการแก้ภายหลัง ให้เก็บเป็นประวัติไว้ก่อนจนกว่าจะสร้างฉบับพร้อมใช้งานใหม่",
          cue:
              "แนะนำ: สร้างฉบับใหม่จากแบบร่างล่าสุด เพื่อคืนความมั่นใจก่อนใช้งานจริง",
          actionLabel: "ดูประวัติเวอร์ชัน",
          onTap: onOpenArtifactHistory,
        ),
      ];
    }

    if (artifact.artifactState == IntentArtifactState.ready) {
      return [
        _StateHelperCard(
          title: "เวอร์ชันพร้อมใช้งานอยู่ในสภาพดี",
          body:
              "เวอร์ชันล่าสุดพร้อมใช้งานและข้อมูลตรงกันแล้ว งานหลักคือรักษาเสถียรภาพพื้นที่ทำงานเมื่อมีการแก้ไขที่ตั้งใจ",
          cue:
              "แนะนำ: ใช้หน้ารีวิวและประวัติเมื่อมีการแก้แบบร่างที่ตั้งใจเท่านั้น",
          actionLabel: "รีวิวเวอร์ชัน",
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
                    "ความพร้อมสำหรับใช้งานจริง",
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
              "ประวัติเวอร์ชัน: ${readiness.historyCount} | พร้อมใช้งาน: ${readiness.readyArtifactCount} | รีวิวแล้ว: ${readiness.reviewedArtifactCount} | โปรโมตแล้ว: ${readiness.promotedArtifactCount}",
            ),
            const SizedBox(height: 6),
            Text(
              readiness.draftInSync
                  ? "สถานะแบบร่าง: แบบร่างปัจจุบันยังตรงกับเวอร์ชันที่ส่งออกล่าสุด"
                  : "สถานะแบบร่าง: แบบร่างปัจจุบันเปลี่ยนจากเวอร์ชันที่ส่งออกล่าสุด",
            ),
            if (readiness.blockers.isNotEmpty) ...[
              const SizedBox(height: 10),
              const Text(
                "รายการที่ยังบล็อกการใช้งานจริง",
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
                  child: const Text("รายละเอียดความพร้อม"),
                ),
                OutlinedButton(
                  onPressed: onOpenBuilder,
                  child: const Text("เปิดหน้าจัดแผน"),
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
    return AppStatePanel(
      message: message,
      tone: showSpinner
          ? AppStateTone.loading
          : isError
              ? AppStateTone.error
              : AppStateTone.info,
      compact: true,
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
        title: Text('ระดับความเป็นส่วนตัว: ${preset.title}'),
        subtitle: Text(
          '${preset.summary}\nขอบเขตผลิตภัณฑ์: แอปนี้ช่วยประสานการส่งต่ออย่างปลอดภัย และไม่ใช่กระบวนการพินัยกรรมทางกฎหมาย',
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
