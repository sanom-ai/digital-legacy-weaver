import 'package:digital_legacy_weaver/features/settings/safety_settings_provider.dart';
import 'package:digital_legacy_weaver/features/settings/privacy_profile_preset.dart';
import 'package:digital_legacy_weaver/features/settings/totp_factor_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SafetySettingsScreen extends ConsumerStatefulWidget {
  const SafetySettingsScreen({super.key});

  @override
  ConsumerState<SafetySettingsScreen> createState() => _SafetySettingsScreenState();
}

class _SafetySettingsScreenState extends ConsumerState<SafetySettingsScreen> {
  bool _remindersEnabled = true;
  bool _legalAccepted = false;
  int _graceDays = 7;
  bool _pause7Days = false;
  bool _offset14 = true;
  bool _offset7 = true;
  bool _offset1 = true;
  bool _requireTotpUnlock = false;
  bool _guardianQuorumEnabled = false;
  int _guardianQuorumRequired = 2;
  int _guardianQuorumPoolSize = 3;
  bool _emergencyAccessEnabled = false;
  bool _emergencyAccessRequiresBeneficiaryRequest = true;
  bool _emergencyAccessRequiresGuardianQuorum = true;
  int _emergencyAccessGraceHours = 48;
  bool _privateFirstMode = true;
  String _proofOfLifeCheckMode = "biometric_tap";
  bool _fallbackEmail = true;
  bool _fallbackSms = true;
  bool _serverHeartbeatFallbackEnabled = true;
  bool _iosBackgroundRiskAcknowledged = false;
  String _selectedPresetId = "minimal";
  bool _seeded = false;

  void _applyPreset(String presetId) {
    final preset = presetById(presetId);
    setState(() {
      _selectedPresetId = preset.id;
      _privateFirstMode = preset.privateFirstMode;
    });
  }

  Color _badgeColor(PrivacyProfilePreset preset) {
    switch (preset.id) {
      case "confidential":
        return const Color(0xFFD9E8FF);
      case "audit-heavy":
        return const Color(0xFFFFE4C7);
      default:
        return const Color(0xFFE5D7C5);
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(safetySettingsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text("Safety Settings")),
      body: settingsAsync.when(
        data: (settings) {
          if (!_seeded) {
            _remindersEnabled = settings.remindersEnabled;
            _legalAccepted = settings.legalDisclaimerAccepted;
            _graceDays = settings.gracePeriodDays;
            _proofOfLifeCheckMode = settings.proofOfLifeCheckMode;
            final fallbackChannels = settings.proofOfLifeFallbackChannels.toSet();
            _fallbackEmail = fallbackChannels.contains("email");
            _fallbackSms = fallbackChannels.contains("sms");
            _serverHeartbeatFallbackEnabled = settings.serverHeartbeatFallbackEnabled;
            _iosBackgroundRiskAcknowledged = settings.iosBackgroundRiskAcknowledged;
            _pause7Days = settings.emergencyPauseUntil != null && settings.emergencyPauseUntil!.isAfter(DateTime.now());
            final offsets = settings.reminderOffsetsDays.toSet();
            _offset14 = offsets.contains(14);
            _offset7 = offsets.contains(7);
            _offset1 = offsets.contains(1);
            _requireTotpUnlock = settings.requireTotpUnlock;
            _guardianQuorumEnabled = settings.guardianQuorumEnabled;
            _guardianQuorumRequired = settings.guardianQuorumRequired;
            _guardianQuorumPoolSize = settings.guardianQuorumPoolSize;
            _emergencyAccessEnabled = settings.emergencyAccessEnabled;
            _emergencyAccessRequiresBeneficiaryRequest =
                settings.emergencyAccessRequiresBeneficiaryRequest;
            _emergencyAccessRequiresGuardianQuorum =
                settings.emergencyAccessRequiresGuardianQuorum;
            _emergencyAccessGraceHours = settings.emergencyAccessGraceHours;
            _privateFirstMode = settings.privateFirstMode;
            _selectedPresetId = settings.tracePrivacyProfile;
            _seeded = true;
          }
          final selectedPreset = presetById(_selectedPresetId);

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Legal & Consent", style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      const Text("This tool supports digital legacy workflow but may not replace a legal will in your jurisdiction."),
                      const SizedBox(height: 6),
                      const Text("Closed-beta note: Digital Legacy Weaver is a technical companion. It helps coordinate secure delivery but does not act as a legal will or legal decision-maker."),
                      const SizedBox(height: 12),
                      CheckboxListTile(
                        value: _legalAccepted,
                        onChanged: (v) => setState(() => _legalAccepted = v ?? false),
                        title: const Text("I accept legal disclaimer and understand limitations."),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Trigger Safeguards", style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600)),
                      SwitchListTile(
                        value: _remindersEnabled,
                        onChanged: (v) => setState(() => _remindersEnabled = v),
                        title: const Text("Enable pre-trigger reminders"),
                        contentPadding: EdgeInsets.zero,
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 8,
                        children: [
                          FilterChip(
                            selected: _offset14,
                            label: const Text("14 days"),
                            onSelected: (v) => setState(() => _offset14 = v),
                          ),
                          FilterChip(
                            selected: _offset7,
                            label: const Text("7 days"),
                            onSelected: (v) => setState(() => _offset7 = v),
                          ),
                          FilterChip(
                            selected: _offset1,
                            label: const Text("1 day"),
                            onSelected: (v) => setState(() => _offset1 = v),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Text("Proof-of-life confirmation"),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        initialValue: _proofOfLifeCheckMode,
                        decoration: const InputDecoration(labelText: "Check-in method"),
                        items: const [
                          DropdownMenuItem(value: "biometric_tap", child: Text("Biometric tap")),
                          DropdownMenuItem(value: "single_tap", child: Text("Single tap fallback")),
                          DropdownMenuItem(value: "verification_code", child: Text("Verification code")),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _proofOfLifeCheckMode = value);
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      const Text("Proof-of-life fallback channels"),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: [
                          FilterChip(
                            selected: _fallbackEmail,
                            label: const Text("Email"),
                            onSelected: (v) => setState(() => _fallbackEmail = v),
                          ),
                          FilterChip(
                            selected: _fallbackSms,
                            label: const Text("SMS"),
                            onSelected: (v) => setState(() => _fallbackSms = v),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Text("Final release grace period (days)"),
                      Slider(
                        value: _graceDays.toDouble(),
                        min: 7,
                        max: 21,
                        divisions: 14,
                        label: "$_graceDays",
                        onChanged: (v) => setState(() => _graceDays = v.round()),
                      ),
                      SwitchListTile(
                        value: _serverHeartbeatFallbackEnabled,
                        onChanged: (v) => setState(() => _serverHeartbeatFallbackEnabled = v),
                        title: const Text("Enable server heartbeat fallback"),
                        subtitle: const Text("Recommended for iOS and long background gaps where app-only proof-of-life can drift."),
                        contentPadding: EdgeInsets.zero,
                      ),
                      CheckboxListTile(
                        value: _iosBackgroundRiskAcknowledged,
                        onChanged: (v) => setState(() => _iosBackgroundRiskAcknowledged = v ?? false),
                        title: const Text("Acknowledge iOS/background limits"),
                        subtitle: const Text("Dead-man style timers on mobile may need fallback heartbeat to avoid false triggers."),
                        contentPadding: EdgeInsets.zero,
                      ),
                      SwitchListTile(
                        value: _pause7Days,
                        onChanged: (v) => setState(() => _pause7Days = v),
                        title: const Text("Emergency pause for 7 days"),
                        contentPadding: EdgeInsets.zero,
                      ),
                      SwitchListTile(
                        value: _requireTotpUnlock,
                        onChanged: (v) => setState(() => _requireTotpUnlock = v),
                        title: const Text("Require TOTP at unlock"),
                        subtitle: const Text("Enable stronger second-factor check before release bundle is shown."),
                        contentPadding: EdgeInsets.zero,
                      ),
                      const SizedBox(height: 6),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const TotpFactorScreen()),
                            );
                          },
                          child: const Text("Manage TOTP Factor"),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Divider(),
                      const SizedBox(height: 8),
                      const Text("Guardian quorum", style: TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 6),
                      const Text(
                        "Use quorum for sensitive legacy release so no single guardian can approve or block alone.",
                      ),
                      SwitchListTile(
                        value: _guardianQuorumEnabled,
                        onChanged: (v) => setState(() => _guardianQuorumEnabled = v),
                        title: const Text("Enable guardian quorum for legacy release"),
                        subtitle: const Text("Recommended baseline: 2-of-3 guardians."),
                        contentPadding: EdgeInsets.zero,
                      ),
                      if (_guardianQuorumEnabled) ...[
                        DropdownButtonFormField<int>(
                          initialValue: _guardianQuorumPoolSize,
                          decoration: const InputDecoration(labelText: "Guardian pool size"),
                          items: const [
                            DropdownMenuItem(value: 2, child: Text("2 guardians")),
                            DropdownMenuItem(value: 3, child: Text("3 guardians")),
                            DropdownMenuItem(value: 4, child: Text("4 guardians")),
                            DropdownMenuItem(value: 5, child: Text("5 guardians")),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                _guardianQuorumPoolSize = value;
                                if (_guardianQuorumRequired > value) {
                                  _guardianQuorumRequired = value;
                                }
                              });
                            }
                          },
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<int>(
                          initialValue: _guardianQuorumRequired,
                          decoration: const InputDecoration(labelText: "Required guardian approvals"),
                          items: List.generate(
                            _guardianQuorumPoolSize,
                            (index) => DropdownMenuItem(
                              value: index + 1,
                              child: Text("${index + 1} approvals"),
                            ),
                          ),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() => _guardianQuorumRequired = value);
                            }
                          },
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Current quorum: $_guardianQuorumRequired-of-$_guardianQuorumPoolSize",
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                      const SizedBox(height: 12),
                      const Text("Emergency access override", style: TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 6),
                      const Text(
                        "Emergency access covers incapacity cases such as ICU or sudden device loss without waiting for a full dead-man cycle.",
                      ),
                      SwitchListTile(
                        value: _emergencyAccessEnabled,
                        onChanged: (v) => setState(() => _emergencyAccessEnabled = v),
                        title: const Text("Enable emergency access override"),
                        subtitle: const Text("Keep this separate from standard inactivity-trigger release."),
                        contentPadding: EdgeInsets.zero,
                      ),
                      if (_emergencyAccessEnabled) ...[
                        CheckboxListTile(
                          value: _emergencyAccessRequiresBeneficiaryRequest,
                          onChanged: (v) => setState(
                            () => _emergencyAccessRequiresBeneficiaryRequest = v ?? true,
                          ),
                          title: const Text("Require beneficiary request"),
                          subtitle: const Text("Emergency access should start with an explicit beneficiary request."),
                          contentPadding: EdgeInsets.zero,
                        ),
                        CheckboxListTile(
                          value: _emergencyAccessRequiresGuardianQuorum,
                          onChanged: (v) => setState(
                            () => _emergencyAccessRequiresGuardianQuorum = v ?? true,
                          ),
                          title: const Text("Require guardian quorum"),
                          subtitle: const Text("Recommended so one person cannot force emergency access alone."),
                          contentPadding: EdgeInsets.zero,
                        ),
                        const SizedBox(height: 8),
                        const Text("Emergency access grace window (hours)"),
                        Slider(
                          value: _emergencyAccessGraceHours.toDouble(),
                          min: 24,
                          max: 168,
                          divisions: 6,
                          label: "$_emergencyAccessGraceHours",
                          onChanged: (v) => setState(() => _emergencyAccessGraceHours = v.round()),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Private-first Mode", style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      const Text("Choose a privacy preset in plain language. The app will map it to private-first settings and trace behavior automatically."),
                      SwitchListTile(
                        value: _privateFirstMode,
                        onChanged: (v) => setState(() => _privateFirstMode = v),
                        title: const Text("Keep private-first mode enabled"),
                        subtitle: const Text("Prefer the stricter privacy posture between your settings and active PTN policy."),
                        contentPadding: EdgeInsets.zero,
                      ),
                      const SizedBox(height: 8),
                      const Text("Privacy preset", style: TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      Column(
                        children: privacyProfilePresets.map((preset) {
                          final selected = preset.id == _selectedPresetId;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () => _applyPreset(preset.id),
                              child: Ink(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: selected ? Theme.of(context).colorScheme.primary : Theme.of(context).dividerColor,
                                    width: selected ? 2 : 1,
                                  ),
                                  color: selected ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.06) : null,
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(14),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              preset.title,
                                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              borderRadius: BorderRadius.circular(999),
                                              color: _badgeColor(preset),
                                            ),
                                            child: Text(preset.badgeLabel, style: const TextStyle(fontSize: 12)),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Text(preset.summary),
                                      const SizedBox(height: 6),
                                      Text(
                                        preset.detail,
                                        style: Theme.of(context).textTheme.bodySmall,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 8),
                      Text(selectedPreset.summary),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () async {
                  final offsets = <int>[];
                  if (_offset14) offsets.add(14);
                  if (_offset7) offsets.add(7);
                  if (_offset1) offsets.add(1);
                  if (offsets.isEmpty) offsets.add(1);
                  final fallbackChannels = <String>[];
                  if (_fallbackEmail) fallbackChannels.add("email");
                  if (_fallbackSms) fallbackChannels.add("sms");
                  if (fallbackChannels.isEmpty) fallbackChannels.add("email");

                  final messenger = ScaffoldMessenger.of(context);
                  await ref.read(safetySettingsProvider.notifier).save(
                        remindersEnabled: _remindersEnabled,
                        reminderOffsetsDays: offsets,
                        gracePeriodDays: _graceDays,
                        proofOfLifeCheckMode: _proofOfLifeCheckMode,
                        proofOfLifeFallbackChannels: fallbackChannels,
                        serverHeartbeatFallbackEnabled: _serverHeartbeatFallbackEnabled,
                        iosBackgroundRiskAcknowledged: _iosBackgroundRiskAcknowledged,
                        legalDisclaimerAccepted: _legalAccepted,
                        emergencyPauseUntil: _pause7Days ? DateTime.now().add(const Duration(days: 7)) : null,
                        requireTotpUnlock: _requireTotpUnlock,
                        guardianQuorumEnabled: _guardianQuorumEnabled,
                        guardianQuorumRequired: _guardianQuorumRequired,
                        guardianQuorumPoolSize: _guardianQuorumPoolSize,
                        emergencyAccessEnabled: _emergencyAccessEnabled,
                        emergencyAccessRequiresBeneficiaryRequest:
                            _emergencyAccessRequiresBeneficiaryRequest,
                        emergencyAccessRequiresGuardianQuorum:
                            _emergencyAccessRequiresGuardianQuorum,
                        emergencyAccessGraceHours: _emergencyAccessGraceHours,
                        privateFirstMode: _privateFirstMode,
                        tracePrivacyProfile: selectedPreset.tracePrivacyProfile,
                      );
                  if (!mounted) return;
                  messenger.showSnackBar(
                    const SnackBar(content: Text("Safety settings updated.")),
                  );
                },
                child: const Text("Save Safety Settings"),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text("Failed to load settings: $error")),
      ),
    );
  }
}
