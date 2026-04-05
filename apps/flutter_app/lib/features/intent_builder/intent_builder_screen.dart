import 'package:digital_legacy_weaver/features/intent_builder/intent_builder_model.dart';
import 'package:digital_legacy_weaver/features/intent_builder/intent_compiler_report_model.dart';
import 'package:digital_legacy_weaver/features/intent_builder/intent_ptn_preview.dart';
import 'package:digital_legacy_weaver/features/intent_builder/intent_review_card.dart';
import 'package:digital_legacy_weaver/features/profile/profile_model.dart';
import 'package:digital_legacy_weaver/features/settings/safety_settings_model.dart';
import 'package:flutter/material.dart';

class IntentBuilderScreen extends StatefulWidget {
  const IntentBuilderScreen({
    super.key,
    required this.profile,
    required this.settings,
  });

  final ProfileModel profile;
  final SafetySettingsModel settings;

  @override
  State<IntentBuilderScreen> createState() => _IntentBuilderScreenState();
}

class _IntentBuilderScreenState extends State<IntentBuilderScreen> {
  late IntentDocumentModel _document;

  @override
  void initState() {
    super.initState();
    _document = _seedDocument();
  }

  IntentDocumentModel _seedDocument() {
    final entries = <IntentEntryModel>[
      IntentEntryModel(
        entryId: "legacy_delivery_primary",
        kind: "legacy_delivery",
        asset: const IntentAssetModel(
          assetId: "legacy_asset_primary",
          assetType: "vault_item",
          displayName: "Primary legacy bundle",
          payloadMode: "secure_link",
          payloadRef: "",
          notes: "Main beneficiary delivery bundle",
        ),
        recipient: IntentRecipientModel(
          recipientId: "beneficiary_primary",
          relationship: "beneficiary",
          deliveryChannel: "email",
          destinationRef: widget.profile.beneficiaryEmail ?? "",
          role: "beneficiary",
        ),
        trigger: IntentTriggerModel(
          mode: "inactivity",
          inactivityDays: widget.profile.legacyInactivityDays,
          requireUnconfirmedAliveStatus: true,
          graceDays: widget.settings.gracePeriodDays,
          remindersDaysBefore: widget.settings.reminderOffsetsDays,
        ),
        delivery: IntentDeliveryModel(
          method: "secure_link",
          requireVerificationCode: true,
          requireTotp: widget.settings.requireTotpUnlock,
          oneTimeAccess: true,
        ),
        safeguards: const IntentSafeguardsModel(
          requireGuardianApproval: false,
          requireMultisignal: true,
          cooldownHours: 24,
          legalDisclaimerRequired: true,
        ),
        privacy: IntentPrivacyModel(
          profile: widget.settings.tracePrivacyProfile,
          minimizeTraceMetadata: widget.settings.privateFirstMode,
        ),
        partnerPath: null,
        status: "draft",
      ),
      IntentEntryModel(
        entryId: "self_recovery_primary",
        kind: "self_recovery",
        asset: IntentAssetModel(
          assetId: "self_recovery_backup",
          assetType: "backup_email_route",
          displayName: "Backup recovery route",
          payloadMode: "self_recovery_route",
          payloadRef: widget.profile.backupEmail,
          notes: "Owner recovery route",
        ),
        recipient: IntentRecipientModel(
          recipientId: "owner_primary",
          relationship: "owner",
          deliveryChannel: "email",
          destinationRef: widget.profile.backupEmail,
          role: "owner",
        ),
        trigger: IntentTriggerModel(
          mode: "inactivity",
          inactivityDays: widget.profile.selfRecoveryInactivityDays,
          requireUnconfirmedAliveStatus: false,
          graceDays: widget.settings.gracePeriodDays,
          remindersDaysBefore: widget.settings.reminderOffsetsDays,
        ),
        delivery: IntentDeliveryModel(
          method: "self_recovery_route",
          requireVerificationCode: true,
          requireTotp: widget.settings.requireTotpUnlock,
          oneTimeAccess: true,
        ),
        safeguards: const IntentSafeguardsModel(
          requireGuardianApproval: false,
          requireMultisignal: false,
          cooldownHours: 24,
          legalDisclaimerRequired: true,
        ),
        privacy: IntentPrivacyModel(
          profile: widget.settings.tracePrivacyProfile,
          minimizeTraceMetadata: widget.settings.privateFirstMode,
        ),
        partnerPath: null,
        status: "draft",
      ),
    ];

    return IntentDocumentModel.initial(
      ownerRef: widget.profile.id,
      defaultPrivacyProfile: widget.settings.tracePrivacyProfile,
    ).copyWith(
      entries: entries,
      globalSafeguards: IntentGlobalSafeguardsModel(
        emergencyPauseEnabled: true,
        defaultGraceDays: widget.settings.gracePeriodDays,
        defaultRemindersDaysBefore: widget.settings.reminderOffsetsDays,
        requireMultisignalBeforeRelease: true,
        requireGuardianApprovalForLegacy: false,
      ),
    );
  }

  void _addDraftEntry() {
    final nextIndex = _document.entries.length + 1;
    final next = IntentEntryModel.legacyDeliveryDraft(
      entryId: "legacy_delivery_$nextIndex",
      recipientRef: "beneficiary_$nextIndex",
      destinationRef: widget.profile.beneficiaryEmail ?? "",
    ).copyWith(
      privacy: IntentPrivacyModel(
        profile: _document.defaultPrivacyProfile,
        minimizeTraceMetadata: widget.settings.privateFirstMode,
      ),
    );
    setState(() {
      _document = _document.copyWith(entries: [..._document.entries, next]);
    });
  }

  @override
  Widget build(BuildContext context) {
    final primaryLegacy = _document.entries.firstWhere(
      (entry) => entry.kind == "legacy_delivery",
      orElse: () => _document.entries.first,
    );
    final report = buildDraftIntentCompilerReport(
      beneficiaryEmail: primaryLegacy.recipient.destinationRef,
      legalAccepted: widget.settings.legalDisclaimerAccepted,
      privateFirstMode: widget.settings.privateFirstMode,
      privacyProfile: primaryLegacy.privacy.profile,
      legacyInactivityDays: primaryLegacy.trigger.inactivityDays,
      graceDays: primaryLegacy.trigger.graceDays,
    );
    final ptnPreview = buildDraftIntentPtnPreview(_document);

    return Scaffold(
      appBar: AppBar(title: const Text("Intent Builder")),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "User-defined legacy intent",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "This screen is the draft foundation for building intent in plain language before compiling it into PTN.",
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _Pill(label: "Default privacy: ${_document.defaultPrivacyProfile}"),
                      _Pill(label: "Entries: ${_document.entries.length}"),
                      _Pill(label: "Owner ref: ${_document.ownerRef}"),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Expanded(
                child: Text(
                  "Draft entries",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
              ),
              FilledButton.tonal(
                onPressed: _addDraftEntry,
                child: const Text("Add draft entry"),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ..._document.entries.map((entry) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _IntentEntryCard(entry: entry),
              )),
          IntentReviewCard(report: report),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Compiler bridge",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Draft canonical preview generated from the current intent document. This stays close to compiler semantics so users can see the PTN shape early.",
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: const Color(0xFFF7F2EA),
                    ),
                    child: SelectableText(
                      ptnPreview,
                      style: const TextStyle(fontFamily: 'Consolas', fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _IntentEntryCard extends StatelessWidget {
  const _IntentEntryCard({required this.entry});

  final IntentEntryModel entry;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    entry.asset.displayName,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                ),
                _Pill(label: entry.kind),
              ],
            ),
            const SizedBox(height: 8),
            Text("Recipient: ${entry.recipient.destinationRef.isEmpty ? "Not set" : entry.recipient.destinationRef}"),
            const SizedBox(height: 4),
            Text("Trigger: ${entry.trigger.inactivityDays} inactivity days + ${entry.trigger.graceDays} grace days"),
            const SizedBox(height: 4),
            Text("Delivery: ${entry.delivery.method}"),
            const SizedBox(height: 4),
            Text("Privacy: ${entry.privacy.profile}"),
            const SizedBox(height: 4),
            Text("Status: ${entry.status}"),
          ],
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: const Color(0xFFE5D7C5),
      ),
      child: Text(label),
    );
  }
}
