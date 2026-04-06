enum RecoveryKind { legacy, selfRecovery }

extension RecoveryKindX on RecoveryKind {
  String get dbValue => this == RecoveryKind.legacy ? "legacy" : "self_recovery";
  String get label => this == RecoveryKind.legacy ? "LEGACY" : "SELF";

  static RecoveryKind fromDb(String value) {
    return value == "legacy" ? RecoveryKind.legacy : RecoveryKind.selfRecovery;
  }
}

class RecoveryItemModel {
  const RecoveryItemModel({
    required this.id,
    required this.kind,
    required this.title,
    required this.encryptedPayload,
    required this.releaseNotes,
    required this.postTriggerVisibility,
    required this.valueDisclosureMode,
    required this.isActive,
  });

  final String id;
  final RecoveryKind kind;
  final String title;
  final String encryptedPayload;
  final String? releaseNotes;
  final String postTriggerVisibility;
  final String valueDisclosureMode;
  final bool isActive;

  factory RecoveryItemModel.fromMap(Map<String, dynamic> map) {
    return RecoveryItemModel(
      id: map["id"] as String,
      kind: RecoveryKindX.fromDb(map["kind"] as String),
      title: map["title"] as String,
      encryptedPayload: map["encrypted_payload"] as String,
      releaseNotes: map["release_notes"] as String?,
      postTriggerVisibility: map["post_trigger_visibility"] as String? ?? "route_only",
      valueDisclosureMode: map["value_disclosure_mode"] as String? ?? "institution_verified_only",
      isActive: map["is_active"] as bool? ?? true,
    );
  }
}
