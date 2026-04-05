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
      defaultPrivacyProfile: defaultPrivacyProfile ?? this.defaultPrivacyProfile,
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
}

class IntentRecipientModel {
  const IntentRecipientModel({
    required this.recipientId,
    required this.relationship,
    required this.deliveryChannel,
    required this.destinationRef,
    required this.role,
  });

  final String recipientId;
  final String relationship;
  final String deliveryChannel;
  final String destinationRef;
  final String role;

  Map<String, dynamic> toMap() {
    return {
      "recipient_id": recipientId,
      "relationship": relationship,
      "delivery_channel": deliveryChannel,
      "destination_ref": destinationRef,
      "role": role,
    };
  }
}

class IntentTriggerModel {
  const IntentTriggerModel({
    required this.mode,
    required this.inactivityDays,
    required this.requireUnconfirmedAliveStatus,
    required this.graceDays,
    required this.remindersDaysBefore,
  });

  final String mode;
  final int inactivityDays;
  final bool requireUnconfirmedAliveStatus;
  final int graceDays;
  final List<int> remindersDaysBefore;

  Map<String, dynamic> toMap() {
    return {
      "mode": mode,
      "inactivity_days": inactivityDays,
      "require_unconfirmed_alive_status": requireUnconfirmedAliveStatus,
      "grace_days": graceDays,
      "reminders_days_before": remindersDaysBefore,
    };
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
}

class IntentPrivacyModel {
  const IntentPrivacyModel({
    required this.profile,
    required this.minimizeTraceMetadata,
  });

  final String profile;
  final bool minimizeTraceMetadata;

  Map<String, dynamic> toMap() {
    return {
      "profile": profile,
      "minimize_trace_metadata": minimizeTraceMetadata,
    };
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
}

class IntentGlobalSafeguardsModel {
  const IntentGlobalSafeguardsModel({
    this.emergencyPauseEnabled = true,
    this.defaultGraceDays = 3,
    this.defaultRemindersDaysBefore = const [14, 7, 1],
    this.requireMultisignalBeforeRelease = true,
    this.requireGuardianApprovalForLegacy = false,
  });

  final bool emergencyPauseEnabled;
  final int defaultGraceDays;
  final List<int> defaultRemindersDaysBefore;
  final bool requireMultisignalBeforeRelease;
  final bool requireGuardianApprovalForLegacy;

  Map<String, dynamic> toMap() {
    return {
      "emergency_pause_enabled": emergencyPauseEnabled,
      "default_grace_days": defaultGraceDays,
      "default_reminders_days_before": defaultRemindersDaysBefore,
      "require_multisignal_before_release": requireMultisignalBeforeRelease,
      "require_guardian_approval_for_legacy": requireGuardianApprovalForLegacy,
    };
  }
}
