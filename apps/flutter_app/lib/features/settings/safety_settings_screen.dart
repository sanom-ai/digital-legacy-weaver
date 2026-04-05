import 'package:digital_legacy_weaver/features/settings/safety_settings_provider.dart';
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
  String _tracePrivacyProfile = "minimal";
  bool _seeded = false;

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
            _tracePrivacyProfile = settings.tracePrivacyProfile;
            _seeded = true;
          }

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
                      const Text("Keep runtime traces as small as possible and align logging posture with your chosen privacy profile."),
                      SwitchListTile(
                        value: _privateFirstMode,
                        onChanged: (v) => setState(() => _privateFirstMode = v),
                        title: const Text("Enable private-first mode"),
                        subtitle: const Text("Prefer the stricter privacy posture between your settings and active PTN policy."),
                        contentPadding: EdgeInsets.zero,
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        initialValue: _tracePrivacyProfile,
                        decoration: const InputDecoration(
                          labelText: "Trace privacy profile",
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: "confidential",
                            child: Text("Confidential"),
                          ),
                          DropdownMenuItem(
                            value: "minimal",
                            child: Text("Minimal"),
                          ),
                          DropdownMenuItem(
                            value: "audit-heavy",
                            child: Text("Audit-heavy"),
                          ),
                        ],
                        onChanged: (value) {
                          if (value == null) return;
                          setState(() => _tracePrivacyProfile = value);
                        },
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _tracePrivacyProfile == "confidential"
                            ? "Confidential keeps only high-level outcome markers and avoids detailed requirement traces."
                            : _tracePrivacyProfile == "minimal"
                                ? "Minimal keeps sanitized control-state only. This is the recommended default."
                                : "Audit-heavy keeps sanitized evidence and owner references for deeper review without storing secrets.",
                      ),
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
                        tracePrivacyProfile: _tracePrivacyProfile,
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
