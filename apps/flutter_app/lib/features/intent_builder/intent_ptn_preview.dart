import 'package:digital_legacy_weaver/features/intent_builder/intent_builder_model.dart';

String buildDraftIntentPtnPreview(IntentDocumentModel document) {
  final lines = <String>[
    'language: PTN',
    'module: digital_legacy_weaver_intent_${_slug(document.intentId)}',
    'version: ${document.version}',
    'owner: ${_slug(document.ownerRef)}',
    'context: intent_compiled',
    'privacy_profile: ${document.defaultPrivacyProfile}',
    '',
    'role owner {',
    '  label: "Primary Account Owner"',
    '  level: 10',
    '}',
    '',
    'role beneficiary {',
    '  label: "Registered Beneficiary"',
    '  level: 2',
    '}',
    '',
    'role system_scheduler {',
    '  label: "Automated Trigger Scheduler"',
    '  level: 9',
    '}',
    '',
  ];

  final activeEntries = document.entries.where((entry) => entry.status == 'active').toList();
  if (activeEntries.isEmpty) {
    lines.add('# No active entries yet. Activate a draft entry to emit canonical PTN.');
    return '${lines.join('\n')}\n';
  }

  lines.add('constraint compiled_intent_safeguards {');
  for (final entry in activeEntries) {
    final action = entry.kind == 'legacy_delivery'
        ? 'trigger_legacy_delivery'
        : 'trigger_self_recovery_delivery';
    if (entry.delivery.requireVerificationCode) {
      lines.add(
        '  require verification_code[risk=high, mode=strict, evidence=entry:${_slug(entry.entryId)}:delivery, owner=delivery-core] for $action',
      );
    }
    if (entry.delivery.requireTotp) {
      lines.add(
        '  require totp_factor[risk=high, mode=strict, evidence=entry:${_slug(entry.entryId)}:delivery, owner=delivery-core] for $action',
      );
    }
    if (entry.safeguards.legalDisclaimerRequired) {
      lines.add(
        '  require consent_active[risk=high, mode=strict, evidence=entry:${_slug(entry.entryId)}:safeguards, owner=privacy-core] for $action',
      );
    }
  }
  lines.add('}');
  lines.add('');

  for (final entry in activeEntries) {
    final action = entry.kind == 'legacy_delivery'
        ? 'trigger_legacy_delivery'
        : 'trigger_self_recovery_delivery';
    final effect = entry.kind == 'legacy_delivery'
        ? 'send_legacy_secure_link'
        : 'send_self_recovery_route';
    lines.add('policy ${_slug(entry.entryId)}_policy {');
    lines.add('  when action == "$action"');
    lines.add('  and intent.entry_id == "${entry.entryId}"');
    lines.add('  and profile.inactive_days >= ${entry.trigger.inactivityDays}');
    if (entry.trigger.requireUnconfirmedAliveStatus) {
      lines.add('  and profile.last_alive_check_confirmed == false');
    }
    lines.add('  then $effect');
    lines.add('  and append_audit_log');
    lines.add('  and set_privacy_profile_${entry.privacy.profile.replaceAll('-', '_')}');
    lines.add('}');
    lines.add('');
  }

  return '${lines.join('\n')}\n';
}

String _slug(String value) {
  final buffer = StringBuffer();
  for (final rune in value.toLowerCase().runes) {
    final char = String.fromCharCode(rune);
    if (RegExp(r'[a-z0-9]').hasMatch(char)) {
      buffer.write(char);
    } else if (' -_:'.contains(char)) {
      buffer.write('_');
    }
  }
  final normalized = buffer.toString().replaceAll(RegExp(r'_+'), '_').replaceAll(RegExp(r'^_|_$'), '');
  return normalized.isEmpty ? 'unknown' : normalized;
}
