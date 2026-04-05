import 'package:digital_legacy_weaver/features/intent_builder/intent_builder_model.dart';

Map<String, dynamic> buildDraftIntentTrace(IntentDocumentModel document) {
  final activeEntries = document.entries.where((entry) => entry.status == 'active');
  return {
    "intent_id": document.intentId,
    "owner_ref": document.ownerRef,
    "entries": {
      for (final entry in activeEntries)
        entry.entryId: {
          "policy_block_id": "${_slug(entry.entryId)}_policy",
          "action": entry.kind == "legacy_delivery"
              ? "trigger_legacy_delivery"
              : "trigger_self_recovery_delivery",
          "privacy_profile": entry.privacy.profile,
        },
    },
  };
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
