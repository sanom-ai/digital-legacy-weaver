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
    required this.isActive,
  });

  final String id;
  final RecoveryKind kind;
  final String title;
  final String encryptedPayload;
  final String? releaseNotes;
  final bool isActive;

  factory RecoveryItemModel.fromMap(Map<String, dynamic> map) {
    return RecoveryItemModel(
      id: map["id"] as String,
      kind: RecoveryKindX.fromDb(map["kind"] as String),
      title: map["title"] as String,
      encryptedPayload: map["encrypted_payload"] as String,
      releaseNotes: map["release_notes"] as String?,
      isActive: map["is_active"] as bool? ?? true,
    );
  }
}
