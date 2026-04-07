class IntentDocumentModel {
  const IntentDocumentModel({
    required this.intentId,
    required this.version,
    required this.ownerRef,
    required this.defaultPrivacyProfile,
    required this.entries,
    required this.globalSafeguards,
    required this.metadata,
  });

  final String intentId;
  final String version;
  final String ownerRef;
  final String defaultPrivacyProfile;
  final List<IntentEntryModel> entries;
  final IntentGlobalSafeguardsModel globalSafeguards;
  final Map<String, dynamic> metadata;

  factory IntentDocumentModel.initial({
    required String ownerRef,
    String intentId = "intent_primary",
    String version = "0.1.0",
    String defaultPrivacyProfile = "minimal",
  }) {
    return IntentDocumentModel(
      intentId: intentId,
      version: version,
      ownerRef: ownerRef,
      defaultPrivacyProfile: defaultPrivacyProfile,
      entries: const [],
      globalSafeguards: const IntentGlobalSafeguardsModel(),
      metadata: const {"source": "intent_builder"},
    );
  }

  IntentDocumentModel copyWith({
    String? intentId,
    String? version,
    String? ownerRef,
    String? defaultPrivacyProfile,
    List<IntentEntryModel>? entries,
    IntentGlobalSafeguardsModel? globalSafeguards,
    Map<String, dynamic>? metadata,
  }) {
    return IntentDocumentModel(
      intentId: intentId ?? this.intentId,
      version: version ?? this.version,
      ownerRef: ownerRef ?? this.ownerRef,
      defaultPrivacyProfile:
          defaultPrivacyProfile ?? this.defaultPrivacyProfile,
      entries: entries ?? this.entries,
      globalSafeguards: globalSafeguards ?? this.globalSafeguards,
      metadata: metadata ?? this.metadata,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      "intent_id": intentId,
      "version": version,
      "owner_ref": ownerRef,
      "default_privacy_profile": defaultPrivacyProfile,
      "entries": entries.map((entry) => entry.toMap()).toList(),
      "global_safeguards": globalSafeguards.toMap(),
      "metadata": metadata,
    };
  }

  factory IntentDocumentModel.fromMap(Map<String, dynamic> map) {
    return IntentDocumentModel(
      intentId: map["intent_id"] as String? ?? "intent_primary",
      version: map["version"] as String? ?? "0.1.0",
      ownerRef: map["owner_ref"] as String? ?? "",
      defaultPrivacyProfile:
          map["default_privacy_profile"] as String? ?? "minimal",
      entries: (map["entries"] as List<dynamic>? ?? const [])
          .whereType<Map>()
          .map((entry) =>
              IntentEntryModel.fromMap(Map<String, dynamic>.from(entry)))
          .toList(),
      globalSafeguards: IntentGlobalSafeguardsModel.fromMap(
        Map<String, dynamic>.from(
          map["global_safeguards"] as Map? ?? const <String, dynamic>{},
        ),
      ),
      metadata: Map<String, dynamic>.from(
          map["metadata"] as Map? ?? const <String, dynamic>{}),
    );
  }
}

class IntentEntryModel {
  const IntentEntryModel({
    required this.entryId,
    required this.kind,
    required this.asset,
    required this.recipient,
    required this.trigger,
    required this.delivery,
    required this.safeguards,
    required this.privacy,
    required this.partnerPath,
    required this.status,
  });

  final String entryId;
  final String kind;
  final IntentAssetModel asset;
  final IntentRecipientModel recipient;
  final IntentTriggerModel trigger;
  final IntentDeliveryModel delivery;
  final IntentSafeguardsModel safeguards;
  final IntentPrivacyModel privacy;
  final IntentPartnerPathModel? partnerPath;
  final String status;

  factory IntentEntryModel.legacyDeliveryDraft({
    required String entryId,
    required String recipientRef,
    required String destinationRef,
  }) {
    return IntentEntryModel(
      entryId: entryId,
      kind: "legacy_delivery",
      asset: const IntentAssetModel(
        assetId: "asset_draft",
        assetType: "unknown",
        displayName: "Untitled asset",
        payloadMode: "secure_link",
        payloadRef: "",
        notes: null,
      ),
      recipient: IntentRecipientModel(
        recipientId: recipientRef,
        relationship: "beneficiary",
        deliveryChannel: "email",
        destinationRef: destinationRef,
        role: "beneficiary",
        registeredLegalName: "",
        verificationHint: "",
        fallbackChannels: const ["email", "sms"],
      ),
      trigger: const IntentTriggerModel(
        mode: "inactivity",
        inactivityDays: 90,
        requireUnconfirmedAliveStatus: true,
        graceDays: 7,
        remindersDaysBefore: [14, 7, 1],
      ),
      delivery: const IntentDeliveryModel(
        method: "secure_link",
        requireVerificationCode: true,
        requireTotp: false,
        oneTimeAccess: true,
      ),
      safeguards: const IntentSafeguardsModel(
        requireGuardianApproval: false,
        requireMultisignal: true,
        cooldownHours: 24,
        legalDisclaimerRequired: true,
      ),
      privacy: const IntentPrivacyModel(
        profile: "minimal",
        minimizeTraceMetadata: true,
        preTriggerVisibility: "none",
        postTriggerVisibility: "route_only",
        valueDisclosureMode: "institution_verified_only",
      ),
      partnerPath: null,
      status: "draft",
    );
  }

  factory IntentEntryModel.selfRecoveryDraft({
    required String entryId,
    required String ownerRef,
    required String destinationRef,
  }) {
    return IntentEntryModel(
      entryId: entryId,
      kind: "self_recovery",
      asset: const IntentAssetModel(
        assetId: "asset_self_recovery",
        assetType: "backup_email_route",
        displayName: "Recovery route",
        payloadMode: "self_recovery_route",
        payloadRef: "",
        notes: "Owner self-recovery path",
      ),
      recipient: IntentRecipientModel(
        recipientId: ownerRef,
        relationship: "owner",
        deliveryChannel: "email",
        destinationRef: destinationRef,
        role: "owner",
        registeredLegalName: "Owner",
        verificationHint: "",
        fallbackChannels: const ["email"],
      ),
      trigger: const IntentTriggerModel(
        mode: "inactivity",
        inactivityDays: 45,
        requireUnconfirmedAliveStatus: false,
        graceDays: 3,
        remindersDaysBefore: [14, 7, 1],
      ),
      delivery: const IntentDeliveryModel(
        method: "self_recovery_route",
        requireVerificationCode: true,
        requireTotp: false,
        oneTimeAccess: true,
      ),
      safeguards: const IntentSafeguardsModel(
        requireGuardianApproval: false,
        requireMultisignal: false,
        cooldownHours: 24,
        legalDisclaimerRequired: true,
      ),
      privacy: const IntentPrivacyModel(
        profile: "minimal",
        minimizeTraceMetadata: true,
        preTriggerVisibility: "none",
        postTriggerVisibility: "route_only",
        valueDisclosureMode: "institution_verified_only",
      ),
      partnerPath: null,
      status: "draft",
    );
  }

  IntentEntryModel copyWith({
    String? entryId,
    String? kind,
    IntentAssetModel? asset,
    IntentRecipientModel? recipient,
    IntentTriggerModel? trigger,
    IntentDeliveryModel? delivery,
    IntentSafeguardsModel? safeguards,
    IntentPrivacyModel? privacy,
    IntentPartnerPathModel? partnerPath,
    String? status,
  }) {
    return IntentEntryModel(
      entryId: entryId ?? this.entryId,
      kind: kind ?? this.kind,
      asset: asset ?? this.asset,
      recipient: recipient ?? this.recipient,
      trigger: trigger ?? this.trigger,
      delivery: delivery ?? this.delivery,
      safeguards: safeguards ?? this.safeguards,
      privacy: privacy ?? this.privacy,
      partnerPath: partnerPath ?? this.partnerPath,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      "entry_id": entryId,
      "kind": kind,
      "asset": asset.toMap(),
      "recipient": recipient.toMap(),
      "trigger": trigger.toMap(),
      "delivery": delivery.toMap(),
      "safeguards": safeguards.toMap(),
      "privacy": privacy.toMap(),
      "partner_path": partnerPath?.toMap(),
      "status": status,
    };
  }

  factory IntentEntryModel.fromMap(Map<String, dynamic> map) {
    return IntentEntryModel(
      entryId: map["entry_id"] as String? ?? "entry_unknown",
      kind: map["kind"] as String? ?? "legacy_delivery",
      asset: IntentAssetModel.fromMap(
        Map<String, dynamic>.from(
            map["asset"] as Map? ?? const <String, dynamic>{}),
      ),
      recipient: IntentRecipientModel.fromMap(
        Map<String, dynamic>.from(
            map["recipient"] as Map? ?? const <String, dynamic>{}),
      ),
      trigger: IntentTriggerModel.fromMap(
        Map<String, dynamic>.from(
            map["trigger"] as Map? ?? const <String, dynamic>{}),
      ),
      delivery: IntentDeliveryModel.fromMap(
        Map<String, dynamic>.from(
            map["delivery"] as Map? ?? const <String, dynamic>{}),
      ),
      safeguards: IntentSafeguardsModel.fromMap(
        Map<String, dynamic>.from(
            map["safeguards"] as Map? ?? const <String, dynamic>{}),
      ),
      privacy: IntentPrivacyModel.fromMap(
        Map<String, dynamic>.from(
            map["privacy"] as Map? ?? const <String, dynamic>{}),
      ),
      partnerPath: map["partner_path"] == null
          ? null
          : IntentPartnerPathModel.fromMap(
              Map<String, dynamic>.from(map["partner_path"] as Map),
            ),
      status: map["status"] as String? ?? "draft",
    );
  }
}

class IntentAssetModel {
  const IntentAssetModel({
    required this.assetId,
    required this.assetType,
    required this.displayName,
    required this.payloadMode,
    required this.payloadRef,
    required this.notes,
  });

  final String assetId;
  final String assetType;
  final String displayName;
  final String payloadMode;
  final String payloadRef;
  final String? notes;

  Map<String, dynamic> toMap() {
    return {
      "asset_id": assetId,
      "asset_type": assetType,
      "display_name": displayName,
      "payload_mode": payloadMode,
      "payload_ref": payloadRef,
      "notes": notes,
    };
  }

  factory IntentAssetModel.fromMap(Map<String, dynamic> map) {
    return IntentAssetModel(
      assetId: map["asset_id"] as String? ?? "asset_unknown",
      assetType: map["asset_type"] as String? ?? "unknown",
      displayName: map["display_name"] as String? ?? "Untitled asset",
      payloadMode: map["payload_mode"] as String? ?? "secure_link",
      payloadRef: map["payload_ref"] as String? ?? "",
      notes: map["notes"] as String?,
    );
  }
}

class IntentRecipientModel {
  const IntentRecipientModel({
    required this.recipientId,
    required this.relationship,
    required this.deliveryChannel,
    required this.destinationRef,
    required this.role,
    required this.registeredLegalName,
    required this.verificationHint,
    required this.fallbackChannels,
  });

  final String recipientId;
  final String relationship;
  final String deliveryChannel;
  final String destinationRef;
  final String role;
  final String registeredLegalName;
  final String verificationHint;
  final List<String> fallbackChannels;

  Map<String, dynamic> toMap() {
    return {
      "recipient_id": recipientId,
      "relationship": relationship,
      "delivery_channel": deliveryChannel,
      "destination_ref": destinationRef,
      "role": role,
      "registered_legal_name": registeredLegalName,
      "verification_hint": verificationHint,
      "fallback_channels": fallbackChannels,
    };
  }

  factory IntentRecipientModel.fromMap(Map<String, dynamic> map) {
    return IntentRecipientModel(
      recipientId: map["recipient_id"] as String? ?? "recipient_unknown",
      relationship: map["relationship"] as String? ?? "beneficiary",
      deliveryChannel: map["delivery_channel"] as String? ?? "email",
      destinationRef: map["destination_ref"] as String? ?? "",
      role: map["role"] as String? ?? "beneficiary",
      registeredLegalName: map["registered_legal_name"] as String? ?? "",
      verificationHint: map["verification_hint"] as String? ?? "",
      fallbackChannels:
          (map["fallback_channels"] as List<dynamic>? ?? const ["email"])
              .whereType<String>()
              .toList(),
    );
  }
}

class IntentTriggerModel {
  const IntentTriggerModel({
    required this.mode,
    required this.inactivityDays,
    required this.requireUnconfirmedAliveStatus,
    required this.graceDays,
    required this.remindersDaysBefore,
    this.scheduledAtUtc,
  });

  final String mode;
  final int inactivityDays;
  final bool requireUnconfirmedAliveStatus;
  final int graceDays;
  final List<int> remindersDaysBefore;
  final DateTime? scheduledAtUtc;

  Map<String, dynamic> toMap() {
    return {
      "mode": mode,
      "inactivity_days": inactivityDays,
      "require_unconfirmed_alive_status": requireUnconfirmedAliveStatus,
      "grace_days": graceDays,
      "reminders_days_before": remindersDaysBefore,
      if (scheduledAtUtc != null)
        "scheduled_at_utc": scheduledAtUtc!.toUtc().toIso8601String(),
    };
  }

  factory IntentTriggerModel.fromMap(Map<String, dynamic> map) {
    DateTime? scheduledAt;
    final rawScheduledAt = map["scheduled_at_utc"];
    if (rawScheduledAt is String && rawScheduledAt.trim().isNotEmpty) {
      scheduledAt = DateTime.tryParse(rawScheduledAt)?.toUtc();
    }
    return IntentTriggerModel(
      mode: map["mode"] as String? ?? "inactivity",
      inactivityDays: map["inactivity_days"] as int? ?? 90,
      requireUnconfirmedAliveStatus:
          map["require_unconfirmed_alive_status"] as bool? ?? true,
      graceDays: map["grace_days"] as int? ?? 7,
      remindersDaysBefore:
          (map["reminders_days_before"] as List<dynamic>? ?? const [14, 7, 1])
              .whereType<int>()
              .toList(),
      scheduledAtUtc: scheduledAt,
    );
  }
}

class IntentDeliveryModel {
  const IntentDeliveryModel({
    required this.method,
    required this.requireVerificationCode,
    required this.requireTotp,
    required this.oneTimeAccess,
  });

  final String method;
  final bool requireVerificationCode;
  final bool requireTotp;
  final bool oneTimeAccess;

  Map<String, dynamic> toMap() {
    return {
      "method": method,
      "require_verification_code": requireVerificationCode,
      "require_totp": requireTotp,
      "one_time_access": oneTimeAccess,
    };
  }

  factory IntentDeliveryModel.fromMap(Map<String, dynamic> map) {
    return IntentDeliveryModel(
      method: map["method"] as String? ?? "secure_link",
      requireVerificationCode:
          map["require_verification_code"] as bool? ?? true,
      requireTotp: map["require_totp"] as bool? ?? false,
      oneTimeAccess: map["one_time_access"] as bool? ?? true,
    );
  }
}

class IntentSafeguardsModel {
  const IntentSafeguardsModel({
    required this.requireGuardianApproval,
    required this.requireMultisignal,
    required this.cooldownHours,
    required this.legalDisclaimerRequired,
  });

  final bool requireGuardianApproval;
  final bool requireMultisignal;
  final int cooldownHours;
  final bool legalDisclaimerRequired;

  Map<String, dynamic> toMap() {
    return {
      "require_guardian_approval": requireGuardianApproval,
      "require_multisignal": requireMultisignal,
      "cooldown_hours": cooldownHours,
      "legal_disclaimer_required": legalDisclaimerRequired,
    };
  }

  factory IntentSafeguardsModel.fromMap(Map<String, dynamic> map) {
    return IntentSafeguardsModel(
      requireGuardianApproval:
          map["require_guardian_approval"] as bool? ?? false,
      requireMultisignal: map["require_multisignal"] as bool? ?? true,
      cooldownHours: map["cooldown_hours"] as int? ?? 24,
      legalDisclaimerRequired:
          map["legal_disclaimer_required"] as bool? ?? true,
    );
  }
}

class IntentPrivacyModel {
  const IntentPrivacyModel({
    required this.profile,
    required this.minimizeTraceMetadata,
    required this.preTriggerVisibility,
    required this.postTriggerVisibility,
    required this.valueDisclosureMode,
  });

  final String profile;
  final bool minimizeTraceMetadata;
  final String preTriggerVisibility;
  final String postTriggerVisibility;
  final String valueDisclosureMode;

  Map<String, dynamic> toMap() {
    return {
      "profile": profile,
      "minimize_trace_metadata": minimizeTraceMetadata,
      "pre_trigger_visibility": preTriggerVisibility,
      "post_trigger_visibility": postTriggerVisibility,
      "value_disclosure_mode": valueDisclosureMode,
    };
  }

  factory IntentPrivacyModel.fromMap(Map<String, dynamic> map) {
    return IntentPrivacyModel(
      profile: map["profile"] as String? ?? "minimal",
      minimizeTraceMetadata: map["minimize_trace_metadata"] as bool? ?? true,
      preTriggerVisibility: map["pre_trigger_visibility"] as String? ?? "none",
      postTriggerVisibility:
          map["post_trigger_visibility"] as String? ?? "route_only",
      valueDisclosureMode: map["value_disclosure_mode"] as String? ??
          "institution_verified_only",
    );
  }
}

class IntentPartnerPathModel {
  const IntentPartnerPathModel({
    required this.pathId,
    required this.pathType,
    required this.handoffTemplate,
    required this.requiredContext,
  });

  final String pathId;
  final String pathType;
  final String handoffTemplate;
  final List<String> requiredContext;

  Map<String, dynamic> toMap() {
    return {
      "path_id": pathId,
      "path_type": pathType,
      "handoff_template": handoffTemplate,
      "required_context": requiredContext,
    };
  }

  factory IntentPartnerPathModel.fromMap(Map<String, dynamic> map) {
    return IntentPartnerPathModel(
      pathId: map["path_id"] as String? ?? "path_unknown",
      pathType: map["path_type"] as String? ?? "handoff_route",
      handoffTemplate: map["handoff_template"] as String? ?? "",
      requiredContext: (map["required_context"] as List<dynamic>? ?? const [])
          .whereType<String>()
          .toList(),
    );
  }
}

class IntentGlobalSafeguardsModel {
  const IntentGlobalSafeguardsModel({
    this.emergencyPauseEnabled = true,
    this.defaultGraceDays = 7,
    this.defaultRemindersDaysBefore = const [14, 7, 1],
    this.requireMultisignalBeforeRelease = true,
    this.requireGuardianApprovalForLegacy = false,
    this.guardianQuorumEnabled = false,
    this.guardianQuorumRequired = 2,
    this.guardianQuorumPoolSize = 3,
    this.emergencyAccessEnabled = false,
    this.emergencyAccessRequiresBeneficiaryRequest = true,
    this.emergencyAccessRequiresGuardianQuorum = true,
    this.emergencyAccessGraceHours = 48,
    this.deviceRebindInProgress = false,
    this.deviceRebindGraceHours = 72,
    this.recoveryKeyEnabled = true,
    this.deliveryAccessTtlHours = 72,
    this.payloadRetentionDays = 30,
    this.auditLogRetentionDays = 30,
    this.proofOfLifeCheckMode = "half_life_soft_checkin",
    this.proofOfLifeFallbackChannels = const ["email", "sms"],
    this.serverHeartbeatFallbackEnabled = true,
    this.iosBackgroundRiskAcknowledged = false,
  });

  final bool emergencyPauseEnabled;
  final int defaultGraceDays;
  final List<int> defaultRemindersDaysBefore;
  final bool requireMultisignalBeforeRelease;
  final bool requireGuardianApprovalForLegacy;
  final bool guardianQuorumEnabled;
  final int guardianQuorumRequired;
  final int guardianQuorumPoolSize;
  final bool emergencyAccessEnabled;
  final bool emergencyAccessRequiresBeneficiaryRequest;
  final bool emergencyAccessRequiresGuardianQuorum;
  final int emergencyAccessGraceHours;
  final bool deviceRebindInProgress;
  final int deviceRebindGraceHours;
  final bool recoveryKeyEnabled;
  final int deliveryAccessTtlHours;
  final int payloadRetentionDays;
  final int auditLogRetentionDays;
  final String proofOfLifeCheckMode;
  final List<String> proofOfLifeFallbackChannels;
  final bool serverHeartbeatFallbackEnabled;
  final bool iosBackgroundRiskAcknowledged;

  Map<String, dynamic> toMap() {
    return {
      "emergency_pause_enabled": emergencyPauseEnabled,
      "default_grace_days": defaultGraceDays,
      "default_reminders_days_before": defaultRemindersDaysBefore,
      "require_multisignal_before_release": requireMultisignalBeforeRelease,
      "require_guardian_approval_for_legacy": requireGuardianApprovalForLegacy,
      "guardian_quorum_enabled": guardianQuorumEnabled,
      "guardian_quorum_required": guardianQuorumRequired,
      "guardian_quorum_pool_size": guardianQuorumPoolSize,
      "emergency_access_enabled": emergencyAccessEnabled,
      "emergency_access_requires_beneficiary_request":
          emergencyAccessRequiresBeneficiaryRequest,
      "emergency_access_requires_guardian_quorum":
          emergencyAccessRequiresGuardianQuorum,
      "emergency_access_grace_hours": emergencyAccessGraceHours,
      "device_rebind_in_progress": deviceRebindInProgress,
      "device_rebind_grace_hours": deviceRebindGraceHours,
      "recovery_key_enabled": recoveryKeyEnabled,
      "delivery_access_ttl_hours": deliveryAccessTtlHours,
      "payload_retention_days": payloadRetentionDays,
      "audit_log_retention_days": auditLogRetentionDays,
      "proof_of_life_check_mode": proofOfLifeCheckMode,
      "proof_of_life_fallback_channels": proofOfLifeFallbackChannels,
      "server_heartbeat_fallback_enabled": serverHeartbeatFallbackEnabled,
      "ios_background_risk_acknowledged": iosBackgroundRiskAcknowledged,
    };
  }

  factory IntentGlobalSafeguardsModel.fromMap(Map<String, dynamic> map) {
    return IntentGlobalSafeguardsModel(
      emergencyPauseEnabled: map["emergency_pause_enabled"] as bool? ?? true,
      defaultGraceDays: map["default_grace_days"] as int? ?? 7,
      defaultRemindersDaysBefore:
          (map["default_reminders_days_before"] as List<dynamic>? ??
                  const [14, 7, 1])
              .whereType<int>()
              .toList(),
      requireMultisignalBeforeRelease:
          map["require_multisignal_before_release"] as bool? ?? true,
      requireGuardianApprovalForLegacy:
          map["require_guardian_approval_for_legacy"] as bool? ?? false,
      guardianQuorumEnabled: map["guardian_quorum_enabled"] as bool? ?? false,
      guardianQuorumRequired: map["guardian_quorum_required"] as int? ?? 2,
      guardianQuorumPoolSize: map["guardian_quorum_pool_size"] as int? ?? 3,
      emergencyAccessEnabled: map["emergency_access_enabled"] as bool? ?? false,
      emergencyAccessRequiresBeneficiaryRequest:
          map["emergency_access_requires_beneficiary_request"] as bool? ?? true,
      emergencyAccessRequiresGuardianQuorum:
          map["emergency_access_requires_guardian_quorum"] as bool? ?? true,
      emergencyAccessGraceHours:
          map["emergency_access_grace_hours"] as int? ?? 48,
      deviceRebindInProgress:
          map["device_rebind_in_progress"] as bool? ?? false,
      deviceRebindGraceHours: map["device_rebind_grace_hours"] as int? ?? 72,
      recoveryKeyEnabled: map["recovery_key_enabled"] as bool? ?? true,
      deliveryAccessTtlHours: map["delivery_access_ttl_hours"] as int? ?? 72,
      payloadRetentionDays: map["payload_retention_days"] as int? ?? 30,
      auditLogRetentionDays: map["audit_log_retention_days"] as int? ?? 30,
      proofOfLifeCheckMode: map["proof_of_life_check_mode"] as String? ??
          "half_life_soft_checkin",
      proofOfLifeFallbackChannels:
          (map["proof_of_life_fallback_channels"] as List<dynamic>? ??
                  const ["email", "sms"])
              .whereType<String>()
              .toList(),
      serverHeartbeatFallbackEnabled:
          map["server_heartbeat_fallback_enabled"] as bool? ?? true,
      iosBackgroundRiskAcknowledged:
          map["ios_background_risk_acknowledged"] as bool? ?? false,
    );
  }
}
