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
  int _graceDays = 3;
  bool _pause7Days = false;
  bool _offset14 = true;
  bool _offset7 = true;
  bool _offset1 = true;
  bool _requireTotpUnlock = false;
  bool _privateFirstMode = true;
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
            _pause7Days = settings.emergencyPauseUntil != null && settings.emergencyPauseUntil!.isAfter(DateTime.now());
            final offsets = settings.reminderOffsetsDays.toSet();
            _offset14 = offsets.contains(14);
            _offset7 = offsets.contains(7);
            _offset1 = offsets.contains(1);
            _requireTotpUnlock = settings.requireTotpUnlock;
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
                      const Text("Final release grace period (days)"),
                      Slider(
                        value: _graceDays.toDouble(),
                        min: 1,
                        max: 14,
                        divisions: 13,
                        label: "$_graceDays",
                        onChanged: (v) => setState(() => _graceDays = v.round()),
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
                                  color: selected ? Theme.of(context).colorScheme.primary.withOpacity(0.06) : null,
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

                  await ref.read(safetySettingsProvider.notifier).save(
                        remindersEnabled: _remindersEnabled,
                        reminderOffsetsDays: offsets,
                        gracePeriodDays: _graceDays,
                        legalDisclaimerAccepted: _legalAccepted,
                        emergencyPauseUntil: _pause7Days ? DateTime.now().add(const Duration(days: 7)) : null,
                        requireTotpUnlock: _requireTotpUnlock,
                        privateFirstMode: _privateFirstMode,
                        tracePrivacyProfile: selectedPreset.tracePrivacyProfile,
                      );
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
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
