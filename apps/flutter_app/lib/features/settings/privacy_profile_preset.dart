class PrivacyProfilePreset {
  const PrivacyProfilePreset({
    required this.id,
    required this.title,
    required this.badgeLabel,
    required this.summary,
    required this.detail,
    required this.privateFirstMode,
    required this.tracePrivacyProfile,
    this.recommended = false,
  });

  final String id;
  final String title;
  final String badgeLabel;
  final String summary;
  final String detail;
  final bool privateFirstMode;
  final String tracePrivacyProfile;
  final bool recommended;
}

const privacyProfilePresets = <PrivacyProfilePreset>[
  PrivacyProfilePreset(
    id: 'confidential',
    title: 'Confidential',
    badgeLabel: 'Highest privacy',
    summary: 'Keeps trace data to an absolute minimum and stores only high-level outcomes.',
    detail: 'Best for users who want the smallest runtime metadata footprint and can accept thinner operational forensics.',
    privateFirstMode: true,
    tracePrivacyProfile: 'confidential',
  ),
  PrivacyProfilePreset(
    id: 'minimal',
    title: 'Minimal',
    badgeLabel: 'Recommended for beta',
    summary: 'Balanced default that stores only sanitized control-state needed for runtime review.',
    detail: 'Best for closed beta and general usage because it preserves enough signal for debugging without collecting excess detail.',
    privateFirstMode: true,
    tracePrivacyProfile: 'minimal',
    recommended: true,
  ),
  PrivacyProfilePreset(
    id: 'audit-heavy',
    title: 'Audit-heavy',
    badgeLabel: 'Best for audits',
    summary: 'Keeps sanitized evidence and owner references for deeper incident review.',
    detail: 'Best for teams that need richer post-incident analysis while still avoiding actual secret material.',
    privateFirstMode: true,
    tracePrivacyProfile: 'audit-heavy',
  ),
];

PrivacyProfilePreset presetById(String id) {
  return privacyProfilePresets.firstWhere(
    (preset) => preset.id == id,
    orElse: () => privacyProfilePresets[1],
  );
}
