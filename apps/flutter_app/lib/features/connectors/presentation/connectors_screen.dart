import 'package:digital_legacy_weaver/features/connectors/data/connector_models.dart';
import 'package:digital_legacy_weaver/features/connectors/data/connectors_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ConnectorsScreen extends ConsumerStatefulWidget {
  const ConnectorsScreen({super.key});

  @override
  ConsumerState<ConnectorsScreen> createState() => _ConnectorsScreenState();
}

class _ConnectorsScreenState extends ConsumerState<ConnectorsScreen> {
  bool _addingPath = false;
  bool _addingAssetRef = false;
  bool _isMessageError = false;
  String? _message;

  void _setMessage(String message, {bool isError = false}) {
    if (!mounted) return;
    setState(() {
      _message = message;
      _isMessageError = isError;
    });
  }

  String _friendlyActionError(String action, Object error) {
    final lower = error.toString().toLowerCase();
    if (lower.contains("socketexception") ||
        lower.contains("failed host lookup") ||
        lower.contains("network") ||
        lower.contains("timed out")) {
      return "Could not finish $action because the connection looks unstable. Please try again once you are back online.";
    }
    if (lower.contains("no authenticated user") ||
        lower.contains("unauthorized") ||
        lower.contains("forbidden")) {
      return "Your session may have expired. Please sign in again, then retry $action.";
    }
    return "We could not finish $action right now. Please retry in a moment.";
  }

  String _friendlyLoadError(String scope, Object error) {
    final lower = error.toString().toLowerCase();
    if (lower.contains("socketexception") ||
        lower.contains("failed host lookup") ||
        lower.contains("network") ||
        lower.contains("timed out")) {
      return "Cannot load $scope while you are offline. Please reconnect and retry.";
    }
    if (lower.contains("no authenticated user") ||
        lower.contains("unauthorized") ||
        lower.contains("forbidden")) {
      return "Cannot load $scope because your sign-in session is not valid. Please sign in again.";
    }
    return "We could not load $scope right now. Please retry.";
  }

  Future<void> _handleAddPath(AsyncValue<List<PartnerConnectorModel>> connectorsAsync) async {
    if (_addingPath) return;
    final draft = await showDialog<_ConnectorDraft>(
      context: context,
      builder: (_) => const _ConnectorFormDialog(),
    );
    if (draft == null) return;

    setState(() => _addingPath = true);
    try {
      await ref.read(connectorsProvider.notifier).addConnector(
            connectorId: draft.connectorId,
            name: draft.name,
            supportedAssetTypes: draft.assetTypes,
            supportsWebhooks: draft.supportsWebhooks,
            supportedSecondFactors: draft.secondFactors,
          );
      _setMessage("Destination path saved.");
    } catch (error) {
      _setMessage(_friendlyActionError("saving this path", error), isError: true);
    } finally {
      if (mounted) {
        setState(() => _addingPath = false);
      }
    }
  }

  Future<void> _handleAddAssetRef(AsyncValue<List<PartnerConnectorModel>> connectorsAsync) async {
    if (_addingAssetRef) return;
    if (connectorsAsync.isLoading) {
      _setMessage(
        "Please wait for destination paths to finish loading before adding an asset reference.",
        isError: true,
      );
      return;
    }
    if (connectorsAsync.hasError) {
      _setMessage(
        "Please fix destination path loading first, then add asset references.",
        isError: true,
      );
      return;
    }
    final connectors = connectorsAsync.value ?? const <PartnerConnectorModel>[];
    if (connectors.isEmpty) {
      _setMessage("Add at least one destination path before adding asset references.", isError: true);
      return;
    }

    final draft = await showDialog<_AssetRefDraft>(
      context: context,
      builder: (_) => _AssetRefFormDialog(connectors: connectors),
    );
    if (draft == null) return;

    setState(() => _addingAssetRef = true);
    try {
      await ref.read(connectorAssetRefsProvider.notifier).addAssetRef(
            connectorRefId: draft.connectorRefId,
            assetId: draft.assetId,
            assetType: draft.assetType,
            displayName: draft.displayName,
            encryptedPayloadRef: draft.encryptedPayloadRef,
            integrityHash: draft.integrityHash,
          );
      _setMessage("Asset reference saved.");
    } catch (error) {
      _setMessage(
        _friendlyActionError("saving this asset reference", error),
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() => _addingAssetRef = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final connectorsAsync = ref.watch(connectorsProvider);
    final assetsAsync = ref.watch(connectorAssetRefsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text("Partner-ready Paths")),
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
                    "Destination Paths",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Track the services, routes, and handoff references that may be used when a protected workflow is activated.",
                  ),
                  if (_message != null) ...[
                    const SizedBox(height: 10),
                    _StatePanel(
                      message: _message!,
                      isError: _isMessageError,
                    ),
                  ],
                  const SizedBox(height: 10),
                  FilledButton.tonal(
                    onPressed: _addingPath ? null : () => _handleAddPath(connectorsAsync),
                    child: Text(_addingPath ? "Saving path..." : "Add Path"),
                  ),
                  const SizedBox(height: 10),
                  connectorsAsync.when(
                    data: (items) {
                      if (items.isEmpty) {
                        return const _StatePanel(
                          message:
                              "No destination paths yet. Add at least one path before mapping legacy asset references.",
                          highlighted: true,
                        );
                      }
                      return Column(
                        children: items
                            .map(
                              (c) => ListTile(
                                contentPadding: EdgeInsets.zero,
                                title: Text(c.name),
                                subtitle: Text(
                                  "${c.connectorId} | ${c.status}\nassets: ${c.supportedAssetTypes.join(", ")}",
                                ),
                              ),
                            )
                            .toList(),
                      );
                    },
                    loading: () => const _StatePanel(
                      message: "Loading destination paths...",
                      showSpinner: true,
                    ),
                    error: (error, __) => _StatePanel(
                      message: _friendlyLoadError("destination paths", error),
                      isError: true,
                      actionLabel: "Retry",
                      onAction: () => ref.invalidate(connectorsProvider),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Legacy Asset References",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Map private asset references to a destination path without exposing the underlying payload.",
                  ),
                  const SizedBox(height: 10),
                  FilledButton.tonal(
                    onPressed:
                        _addingAssetRef ? null : () => _handleAddAssetRef(connectorsAsync),
                    child: Text(_addingAssetRef ? "Saving asset ref..." : "Add Asset Ref"),
                  ),
                  const SizedBox(height: 10),
                  assetsAsync.when(
                    data: (items) {
                      if (items.isEmpty) {
                        return const _StatePanel(
                          message:
                              "No asset references yet. Add references so each destination path has a concrete, encrypted handoff target.",
                          highlighted: true,
                        );
                      }
                      return Column(
                        children: items
                            .map(
                              (a) => ListTile(
                                contentPadding: EdgeInsets.zero,
                                title: Text(a.displayName),
                                subtitle: Text(
                                  "${a.assetType} | asset_id=${a.assetId}\nref=${a.encryptedPayloadRef}",
                                ),
                              ),
                            )
                            .toList(),
                      );
                    },
                    loading: () => const _StatePanel(
                      message: "Loading asset references...",
                      showSpinner: true,
                    ),
                    error: (error, __) => _StatePanel(
                      message: _friendlyLoadError("asset references", error),
                      isError: true,
                      actionLabel: "Retry",
                      onAction: () =>
                          ref.invalidate(connectorAssetRefsProvider),
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

class _StatePanel extends StatelessWidget {
  const _StatePanel({
    required this.message,
    this.isError = false,
    this.highlighted = false,
    this.showSpinner = false,
    this.actionLabel,
    this.onAction,
  });

  final String message;
  final bool isError;
  final bool highlighted;
  final bool showSpinner;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final color = isError
        ? const Color(0xFFFFF1F1)
        : highlighted
            ? const Color(0xFFFFF7ED)
            : const Color(0xFFF7F1E8);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (showSpinner)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                Icon(
                  isError ? Icons.warning_amber_rounded : Icons.info_outline,
                  size: 20,
                ),
              const SizedBox(width: 8),
              Expanded(child: Text(message)),
            ],
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 8),
            OutlinedButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ],
      ),
    );
  }
}

class _ConnectorDraft {
  const _ConnectorDraft({
    required this.connectorId,
    required this.name,
    required this.assetTypes,
    required this.supportsWebhooks,
    required this.secondFactors,
  });

  final String connectorId;
  final String name;
  final List<String> assetTypes;
  final bool supportsWebhooks;
  final List<String> secondFactors;
}

class _ConnectorFormDialog extends StatefulWidget {
  const _ConnectorFormDialog();

  @override
  State<_ConnectorFormDialog> createState() => _ConnectorFormDialogState();
}

class _ConnectorFormDialogState extends State<_ConnectorFormDialog> {
  final _connectorId = TextEditingController();
  final _name = TextEditingController();
  final _assetTypes = TextEditingController(text: "wallet, cloud_storage");
  final _secondFactors = TextEditingController(text: "verification_code");
  bool _supportsWebhooks = false;

  @override
  void dispose() {
    _connectorId.dispose();
    _name.dispose();
    _assetTypes.dispose();
    _secondFactors.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Add Path"),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _connectorId,
              decoration: const InputDecoration(labelText: "Path ID"),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _name,
              decoration: const InputDecoration(labelText: "Name"),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _assetTypes,
              decoration: const InputDecoration(labelText: "Asset Types (csv)"),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _secondFactors,
              decoration: const InputDecoration(
                labelText: "Second Factors (csv)",
              ),
            ),
            CheckboxListTile(
              value: _supportsWebhooks,
              onChanged: (v) => setState(() => _supportsWebhooks = v ?? false),
              title: const Text("Supports webhooks"),
              contentPadding: EdgeInsets.zero,
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
            final connectorId = _connectorId.text.trim();
            final name = _name.text.trim();
            if (connectorId.isEmpty || name.isEmpty) return;
            Navigator.of(context).pop(
              _ConnectorDraft(
                connectorId: connectorId,
                name: name,
                assetTypes: _assetTypes.text
                    .split(",")
                    .map((e) => e.trim())
                    .where((e) => e.isNotEmpty)
                    .toList(),
                supportsWebhooks: _supportsWebhooks,
                secondFactors: _secondFactors.text
                    .split(",")
                    .map((e) => e.trim())
                    .where((e) => e.isNotEmpty)
                    .toList(),
              ),
            );
          },
          child: const Text("Save"),
        ),
      ],
    );
  }
}

class _AssetRefDraft {
  const _AssetRefDraft({
    required this.connectorRefId,
    required this.assetId,
    required this.assetType,
    required this.displayName,
    required this.encryptedPayloadRef,
    required this.integrityHash,
  });

  final String connectorRefId;
  final String assetId;
  final String assetType;
  final String displayName;
  final String encryptedPayloadRef;
  final String? integrityHash;
}

class _AssetRefFormDialog extends StatefulWidget {
  const _AssetRefFormDialog({required this.connectors});

  final List<PartnerConnectorModel> connectors;

  @override
  State<_AssetRefFormDialog> createState() => _AssetRefFormDialogState();
}

class _AssetRefFormDialogState extends State<_AssetRefFormDialog> {
  late String _connectorRefId;
  final _assetId = TextEditingController();
  final _assetType = TextEditingController(text: "wallet");
  final _displayName = TextEditingController();
  final _payloadRef = TextEditingController();
  final _integrityHash = TextEditingController();

  @override
  void initState() {
    super.initState();
    _connectorRefId = widget.connectors.first.id;
  }

  @override
  void dispose() {
    _assetId.dispose();
    _assetType.dispose();
    _displayName.dispose();
    _payloadRef.dispose();
    _integrityHash.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Add Asset Ref"),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              initialValue: _connectorRefId,
              items: widget.connectors
                  .map(
                    (c) => DropdownMenuItem(
                      value: c.id,
                      child: Text("${c.name} (${c.connectorId})"),
                    ),
                  )
                  .toList(),
              onChanged: (v) {
                if (v != null) setState(() => _connectorRefId = v);
              },
              decoration: const InputDecoration(labelText: "Destination Path"),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _assetId,
              decoration: const InputDecoration(labelText: "Asset ID"),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _assetType,
              decoration: const InputDecoration(labelText: "Asset Type"),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _displayName,
              decoration: const InputDecoration(labelText: "Display Name"),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _payloadRef,
              decoration: const InputDecoration(
                labelText: "Encrypted Payload Ref",
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _integrityHash,
              decoration: const InputDecoration(labelText: "Integrity Hash"),
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
            final assetId = _assetId.text.trim();
            final displayName = _displayName.text.trim();
            final payloadRef = _payloadRef.text.trim();
            if (assetId.isEmpty || displayName.isEmpty || payloadRef.isEmpty) {
              return;
            }
            Navigator.of(context).pop(
              _AssetRefDraft(
                connectorRefId: _connectorRefId,
                assetId: assetId,
                assetType: _assetType.text.trim().isEmpty
                    ? "unknown"
                    : _assetType.text.trim(),
                displayName: displayName,
                encryptedPayloadRef: payloadRef,
                integrityHash: _integrityHash.text.trim().isEmpty
                    ? null
                    : _integrityHash.text.trim(),
              ),
            );
          },
          child: const Text("Save"),
        ),
      ],
    );
  }
}
