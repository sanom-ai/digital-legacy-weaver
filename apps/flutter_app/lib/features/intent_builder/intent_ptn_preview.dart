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
    'authority owner {',
    '  allow: upsert_recovery_item, delete_recovery_item, ack_alive_check',
    '  allow: trigger_self_recovery_delivery',
    '  require mfa for trigger_self_recovery_delivery',
    '}',
    '',
    'authority beneficiary {',
    '  allow: read_legacy_delivery',
    '  deny: upsert_recovery_item, delete_recovery_item',
    '}',
    '',
    'authority system_scheduler {',
    '  allow: trigger_self_recovery_delivery, trigger_legacy_delivery',
  ];

  if (document.globalSafeguards.requireMultisignalBeforeRelease) {
    lines.add(
      _requireLine(
        'multisignal_recent',
        'trigger_legacy_delivery',
        'high',
        'advisory',
        'global_multisignal_guard',
        'safety-core',
      ),
    );
  }
  if (document.globalSafeguards.requireGuardianApprovalForLegacy) {
    lines.add(
      _requireLine(
        'guardian_approval',
        'trigger_legacy_delivery',
        'high',
        'strict',
        'global_guardian_requirement',
        'safety-core',
      ),
    );
  }
  if (document.globalSafeguards.guardianQuorumEnabled) {
    lines.add(
      '# guardian quorum ${document.globalSafeguards.guardianQuorumRequired}-of-${document.globalSafeguards.guardianQuorumPoolSize}',
    );
  }
  if (document.globalSafeguards.emergencyAccessEnabled) {
    lines.add(
      '# emergency access override ${document.globalSafeguards.emergencyAccessGraceHours}h'
      '${document.globalSafeguards.emergencyAccessRequiresBeneficiaryRequest ? ", beneficiary_request" : ""}'
      '${document.globalSafeguards.emergencyAccessRequiresGuardianQuorum ? ", guardian_quorum" : ""}',
    );
  }
  if (document.globalSafeguards.deviceRebindInProgress) {
    lines.add(
      '# device rebind window active ${document.globalSafeguards.deviceRebindGraceHours}h',
    );
  }
  if (document.globalSafeguards.recoveryKeyEnabled) {
    lines.add('# recovery key fallback enabled');
  }
  lines.add(
    '# retention delivery_ttl:${document.globalSafeguards.deliveryAccessTtlHours}h'
    ' payload:${document.globalSafeguards.payloadRetentionDays}d'
    ' audit:${document.globalSafeguards.auditLogRetentionDays}d',
  );
  if (document.globalSafeguards.serverHeartbeatFallbackEnabled) {
    lines.add(
      _requireLine(
        'server_heartbeat_fallback',
        'trigger_legacy_delivery',
        'medium',
        'advisory',
        'global_server_heartbeat_fallback',
        'runtime-core',
      ),
    );
  }
  lines.add('}');
  lines.add('');

  final activeEntries =
      document.entries.where((entry) => entry.status == 'active').toList();
  if (activeEntries.isEmpty) {
    lines.add(
        '# No active entries yet. Activate a draft entry to emit canonical PTN.');
    return '${lines.join('\n')}\n';
  }

  final constraintLines = <String>[];
  for (final entry in activeEntries) {
    final action = entry.kind == 'legacy_delivery'
        ? 'trigger_legacy_delivery'
        : 'trigger_self_recovery_delivery';

    if (entry.delivery.requireVerificationCode) {
      constraintLines.add(
        _requireLine(
          'verification_code',
          action,
          'high',
          'strict',
          'entry:${_slug(entry.entryId)}:delivery',
          'delivery-core',
        ),
      );
    }
    if (entry.delivery.requireTotp) {
      constraintLines.add(
        _requireLine(
          'totp_factor',
          action,
          'high',
          'strict',
          'entry:${_slug(entry.entryId)}:delivery',
          'delivery-core',
        ),
      );
    }
    if (entry.safeguards.legalDisclaimerRequired) {
      constraintLines.add(
        _requireLine(
          'consent_active',
          action,
          'high',
          'strict',
          'entry:${_slug(entry.entryId)}:safeguards',
          'privacy-core',
        ),
      );
    }
    if (entry.safeguards.requireMultisignal &&
        !document.globalSafeguards.requireMultisignalBeforeRelease) {
      constraintLines.add(
        _requireLine(
          'multisignal_recent',
          action,
          'high',
          'advisory',
          'entry:${_slug(entry.entryId)}:safeguards',
          'safety-core',
        ),
      );
    }
    if (entry.safeguards.requireGuardianApproval) {
      constraintLines.add(
        _requireLine(
          'guardian_approval',
          action,
          'high',
          'strict',
          'entry:${_slug(entry.entryId)}:safeguards',
          'safety-core',
        ),
      );
    }
    if (entry.safeguards.cooldownHours > 0) {
      constraintLines.add(
        _requireLine(
          'cooldown_${entry.safeguards.cooldownHours}h',
          action,
          'medium',
          'strict',
          'entry:${_slug(entry.entryId)}:safeguards',
          'safety-core',
        ),
      );
    }
    if (entry.kind == 'legacy_delivery') {
      constraintLines.add(
        _requireLine(
          'beneficiary_identity_match',
          action,
          'high',
          'strict',
          'entry:${_slug(entry.entryId)}:beneficiary_identity',
          'delivery-core',
        ),
      );
      if (entry.recipient.fallbackChannels.toSet().length >= 2) {
        constraintLines.add(
          _requireLine(
            'fallback_channels_ready',
            action,
            'medium',
            'advisory',
            'entry:${_slug(entry.entryId)}:recipient_fallbacks',
            'delivery-core',
          ),
        );
      }
      if (entry.privacy.preTriggerVisibility == 'none') {
        constraintLines.add(
          _requireLine(
            'pretrigger_visibility_dark',
            action,
            'high',
            'strict',
            'entry:${_slug(entry.entryId)}:visibility',
            'privacy-core',
          ),
        );
      }
      if (entry.privacy.valueDisclosureMode == 'institution_verified_only') {
        constraintLines.add(
          _requireLine(
            'institution_verified_value_only',
            action,
            'high',
            'strict',
            'entry:${_slug(entry.entryId)}:visibility',
            'privacy-core',
          ),
        );
      }
    }
  }

  if (constraintLines.isNotEmpty) {
    lines.add('constraint compiled_intent_safeguards {');
    for (final line in _dedupe(constraintLines)) {
      lines.add(line);
    }
    lines.add('}');
    lines.add('');
  }

  for (final entry in activeEntries) {
    final action = entry.kind == 'legacy_delivery'
        ? 'trigger_legacy_delivery'
        : 'trigger_self_recovery_delivery';
    var event = entry.kind == 'legacy_delivery'
        ? 'send_legacy_secure_link'
        : 'send_self_recovery_secure_link';
    if (entry.delivery.method == 'notification_only') {
      event = 'send_notification_only';
    } else if (entry.delivery.method == 'self_recovery_route') {
      event = 'send_self_recovery_route';
    }

    lines.add('policy ${_slug(entry.entryId)}_policy {');
    lines.add('  when action == "$action"');
    lines.add('  and intent.entry_id == "${_quote(entry.entryId)}"');
    if (entry.trigger.mode == 'exact_date') {
      final scheduledAt =
          entry.trigger.scheduledAtUtc?.toUtc().toIso8601String();
      if (scheduledAt != null) {
        lines.add('  and runtime.now_utc >= "$scheduledAt"');
      } else {
        lines.add('  and runtime.now_utc >= "<missing_exact_date>"');
      }
    } else if (entry.trigger.mode == 'manual_release') {
      lines.add('  and runtime.manual_release_approved == true');
    } else {
      lines.add(
          '  and profile.inactive_days >= ${entry.trigger.inactivityDays}');
    }
    if (entry.trigger.requireUnconfirmedAliveStatus) {
      lines.add('  and profile.last_alive_check_confirmed == false');
    }
    lines.add('  then $event');
    lines.add('  and append_audit_log');
    lines.add(
        '  and set_privacy_profile_${entry.privacy.profile.replaceAll('-', '_')}');
    lines.add('  and route_to_${_slug(entry.recipient.recipientId)}');
    lines.add('  and label_asset_${_slug(entry.asset.assetId)}');
    lines.add('}');
    lines.add('');
  }

  return '${lines.join('\n')}\n';
}

String _requireLine(
  String name,
  String action,
  String risk,
  String mode,
  String evidence,
  String owner,
) {
  return '  require $name[risk=$risk, mode=$mode, evidence=$evidence, owner=$owner] for $action';
}

List<String> _dedupe(List<String> input) {
  final seen = <String>{};
  final output = <String>[];
  for (final line in input) {
    if (seen.add(line)) {
      output.add(line);
    }
  }
  return output;
}

String _quote(String value) {
  return value.replaceAll('"', r'\"');
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
  final normalized = buffer
      .toString()
      .replaceAll(RegExp(r'_+'), '_')
      .replaceAll(RegExp(r'^_|_$'), '');
  return normalized.isEmpty ? 'unknown' : normalized;
}
