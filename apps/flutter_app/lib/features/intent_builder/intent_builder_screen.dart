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

  Future<void> _editEntry(IntentEntryModel entry) async {
    final updated = await showDialog<IntentEntryModel>(
      context: context,
      builder: (_) => _IntentEntryEditorDialog(entry: entry),
    );
    if (updated == null) return;
    setState(() {
      _document = _document.copyWith(
        entries: [
          for (final item in _document.entries) item.entryId == entry.entryId ? updated : item,
        ],
      );
    });
  }

  void _toggleEntryStatus(IntentEntryModel entry) {
    final nextStatus = entry.status == 'active' ? 'draft' : 'active';
    setState(() {
      _document = _document.copyWith(
        entries: [
          for (final item in _document.entries)
            item.entryId == entry.entryId ? item.copyWith(status: nextStatus) : item,
        ],
      );
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
                child: _IntentEntryCard(
                  entry: entry,
                  onEdit: () => _editEntry(entry),
                  onToggleStatus: () => _toggleEntryStatus(entry),
                ),
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
  const _IntentEntryCard({
    required this.entry,
    required this.onEdit,
    required this.onToggleStatus,
  });

  final IntentEntryModel entry;
  final VoidCallback onEdit;
  final VoidCallback onToggleStatus;

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
                const SizedBox(width: 8),
                _Pill(label: entry.status),
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
            const SizedBox(height: 12),
            Row(
              children: [
                OutlinedButton(
                  onPressed: onEdit,
                  child: const Text("Edit"),
                ),
                const SizedBox(width: 8),
                FilledButton.tonal(
                  onPressed: onToggleStatus,
                  child: Text(entry.status == 'active' ? "Move to draft" : "Activate"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _IntentEntryEditorDialog extends StatefulWidget {
  const _IntentEntryEditorDialog({required this.entry});

  final IntentEntryModel entry;

  @override
  State<_IntentEntryEditorDialog> createState() => _IntentEntryEditorDialogState();
}

class _IntentEntryEditorDialogState extends State<_IntentEntryEditorDialog> {
  late final TextEditingController _displayNameController;
  late final TextEditingController _recipientController;
  late final TextEditingController _triggerDaysController;
  late final TextEditingController _graceDaysController;
  late String _privacyProfile;

  @override
  void initState() {
    super.initState();
    _displayNameController = TextEditingController(text: widget.entry.asset.displayName);
    _recipientController = TextEditingController(text: widget.entry.recipient.destinationRef);
    _triggerDaysController = TextEditingController(text: widget.entry.trigger.inactivityDays.toString());
    _graceDaysController = TextEditingController(text: widget.entry.trigger.graceDays.toString());
    _privacyProfile = widget.entry.privacy.profile;
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _recipientController.dispose();
    _triggerDaysController.dispose();
    _graceDaysController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Edit intent entry"),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _displayNameController,
              decoration: const InputDecoration(labelText: "Asset label"),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _recipientController,
              decoration: const InputDecoration(labelText: "Recipient destination"),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _triggerDaysController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Inactivity days"),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _graceDaysController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Grace days"),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _privacyProfile,
              decoration: const InputDecoration(labelText: "Privacy profile"),
              items: const [
                DropdownMenuItem(value: "confidential", child: Text("Confidential")),
                DropdownMenuItem(value: "minimal", child: Text("Minimal")),
                DropdownMenuItem(value: "audit-heavy", child: Text("Audit-heavy")),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() => _privacyProfile = value);
                }
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text("Cancel"),
        ),
        FilledButton(
          onPressed: () {
            final inactivityDays = int.tryParse(_triggerDaysController.text.trim()) ?? widget.entry.trigger.inactivityDays;
            final graceDays = int.tryParse(_graceDaysController.text.trim()) ?? widget.entry.trigger.graceDays;
            Navigator.of(context).pop(
              widget.entry.copyWith(
                asset: IntentAssetModel(
                  assetId: widget.entry.asset.assetId,
                  assetType: widget.entry.asset.assetType,
                  displayName: _displayNameController.text.trim().isEmpty
                      ? widget.entry.asset.displayName
                      : _displayNameController.text.trim(),
                  payloadMode: widget.entry.asset.payloadMode,
                  payloadRef: widget.entry.asset.payloadRef,
                  notes: widget.entry.asset.notes,
                ),
                recipient: IntentRecipientModel(
                  recipientId: widget.entry.recipient.recipientId,
                  relationship: widget.entry.recipient.relationship,
                  deliveryChannel: widget.entry.recipient.deliveryChannel,
                  destinationRef: _recipientController.text.trim(),
                  role: widget.entry.recipient.role,
                ),
                trigger: IntentTriggerModel(
                  mode: widget.entry.trigger.mode,
                  inactivityDays: inactivityDays,
                  requireUnconfirmedAliveStatus: widget.entry.trigger.requireUnconfirmedAliveStatus,
                  graceDays: graceDays,
                  remindersDaysBefore: widget.entry.trigger.remindersDaysBefore,
                ),
                privacy: IntentPrivacyModel(
                  profile: _privacyProfile,
                  minimizeTraceMetadata: widget.entry.privacy.minimizeTraceMetadata,
                ),
              ),
            );
          },
          child: const Text("Apply"),
        ),
      ],
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
