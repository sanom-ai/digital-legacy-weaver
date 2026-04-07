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
      return "$actionยังไม่สำเร็จ เพราะอินเทอร์เน็ตไม่เสถียร กรุณาลองใหม่อีกครั้ง";
    }
    if (lower.contains("no authenticated user") ||
        lower.contains("unauthorized") ||
        lower.contains("forbidden")) {
      return "เซสชันหมดอายุ กรุณาเข้าสู่ระบบใหม่ แล้วลอง$actionอีกครั้ง";
    }
    return "$actionยังไม่สำเร็จในขณะนี้ กรุณาลองใหม่อีกครั้ง";
  }

  String _friendlyLoadError(String scope, Object error) {
    final lower = error.toString().toLowerCase();
    if (lower.contains("socketexception") ||
        lower.contains("failed host lookup") ||
        lower.contains("network") ||
        lower.contains("timed out")) {
      return "ยังโหลด$scopeไม่ได้ เพราะตอนนี้ออฟไลน์หรือสัญญาณไม่เสถียร";
    }
    if (lower.contains("no authenticated user") ||
        lower.contains("unauthorized") ||
        lower.contains("forbidden")) {
      return "ยังโหลด$scopeไม่ได้ เพราะเซสชันไม่ถูกต้อง กรุณาเข้าสู่ระบบใหม่";
    }
    return "ยังโหลด$scopeไม่ได้ในขณะนี้ กรุณาลองใหม่อีกครั้ง";
  }

  Future<void> _handleAddPath(
    AsyncValue<List<PartnerConnectorModel>> connectorsAsync,
  ) async {
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
      _setMessage("บันทึกปลายทางสำเร็จ");
    } catch (error) {
      _setMessage(
        _friendlyActionError("บันทึกปลายทาง", error),
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() => _addingPath = false);
      }
    }
  }

  Future<void> _handleAddAssetRef(
    AsyncValue<List<PartnerConnectorModel>> connectorsAsync,
  ) async {
    if (_addingAssetRef) return;
    if (connectorsAsync.isLoading) {
      _setMessage(
        "กรุณารอให้ระบบโหลดปลายทางเสร็จก่อน แล้วค่อยเพิ่มรายการสินทรัพย์",
        isError: true,
      );
      return;
    }
    if (connectorsAsync.hasError) {
      _setMessage(
        "กรุณาแก้ปัญหาการโหลดปลายทางก่อน แล้วค่อยเพิ่มรายการสินทรัพย์",
        isError: true,
      );
      return;
    }
    final connectors = connectorsAsync.value ?? const <PartnerConnectorModel>[];
    if (connectors.isEmpty) {
      _setMessage(
        "กรุณาเพิ่มปลายทางอย่างน้อย 1 รายการก่อนเพิ่มสินทรัพย์",
        isError: true,
      );
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
      _setMessage("บันทึกรายการสินทรัพย์สำเร็จ");
    } catch (error) {
      _setMessage(
        _friendlyActionError("บันทึกรายการสินทรัพย์", error),
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() => _addingAssetRef = false);
      }
    }
  }

  String _statusLabel(String status) {
    switch (status.trim().toLowerCase()) {
      case "active":
        return "พร้อมใช้งาน";
      case "paused":
        return "พักไว้";
      case "draft":
        return "ยังไม่เปิดใช้";
      default:
        return status;
    }
  }

  String _assetTypeLabel(String type) {
    switch (type.trim().toLowerCase()) {
      case "wallet":
        return "กระเป๋าเงินดิจิทัล";
      case "cloud_storage":
        return "พื้นที่เก็บไฟล์";
      case "bank":
        return "บัญชีธนาคาร";
      case "exchange":
        return "แพลตฟอร์มซื้อขาย";
      case "email":
        return "อีเมล";
      case "social":
        return "โซเชียล";
      case "document":
        return "เอกสารสำคัญ";
      default:
        return type;
    }
  }

  String _secondFactorLabel(String factor) {
    switch (factor.trim().toLowerCase()) {
      case "verification_code":
        return "รหัสยืนยัน";
      case "totp":
        return "แอปยืนยันตัวตน";
      case "biometric":
        return "ชีวมิติ";
      case "guardian_approval":
        return "พยานร่วมอนุมัติ";
      default:
        return factor;
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final connectorsAsync = ref.watch(connectorsProvider);
    final assetsAsync = ref.watch(connectorAssetRefsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text("ปลายทางและรายการอ้างอิง")),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: scheme.primaryContainer.withValues(alpha: 0.28),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: scheme.outlineVariant.withValues(alpha: 0.45),
              ),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "เชื่อมไว้เฉพาะสิ่งที่จำเป็น",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                SizedBox(height: 8),
                Text(
                  "หน้าจอนี้เก็บเพียงปลายทางและข้อมูลอ้างอิงแบบเข้ารหัส เพื่อให้ระบบส่งเอกสารไปยังสถาบันหรือพาร์ทเนอร์ได้ตามแผน",
                ),
                SizedBox(height: 6),
                Text(
                  "แอปไม่เก็บยอดเงินจริง และไม่ใช้หน้านี้สำหรับสั่งโอนเงิน",
                ),
              ],
            ),
          ),
          if (_message != null) ...[
            const SizedBox(height: 12),
            _StatePanel(
              message: _message!,
              isError: _isMessageError,
            ),
          ],
          const SizedBox(height: 12),
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: scheme.outlineVariant.withValues(alpha: 0.45),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "ปลายทางที่เชื่อมไว้",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "จัดการรายชื่อสถาบันหรือบริการที่คุณต้องการให้ระบบประสานงานเอกสารเมื่อถึงเงื่อนไขที่กำหนด",
                  ),
                  const SizedBox(height: 10),
                  FilledButton.tonal(
                    onPressed:
                        _addingPath ? null : () => _handleAddPath(connectorsAsync),
                    child: Text(_addingPath ? "กำลังบันทึก..." : "เพิ่มปลายทาง"),
                  ),
                  const SizedBox(height: 10),
                  connectorsAsync.when(
                    data: (items) {
                      if (items.isEmpty) {
                        return const _StatePanel(
                          message:
                              "ยังไม่มีปลายทาง กรุณาเพิ่มอย่างน้อย 1 รายการก่อนผูกรายการสินทรัพย์",
                          highlighted: true,
                        );
                      }
                      return Column(
                        children: items
                            .map(
                              (connector) => ListTile(
                                contentPadding: EdgeInsets.zero,
                                title: Text(connector.name),
                                subtitle: Text(
                                  "สถานะ: ${_statusLabel(connector.status)}\n"
                                  "รองรับ: ${connector.supportedAssetTypes.map(_assetTypeLabel).join(", ")}\n"
                                  "ยืนยันตัวตน: ${connector.supportedSecondFactors.map(_secondFactorLabel).join(", ")}",
                                ),
                                isThreeLine: true,
                              ),
                            )
                            .toList(),
                      );
                    },
                    loading: () => const _StatePanel(
                      message: "กำลังโหลดรายการปลายทาง...",
                      showSpinner: true,
                    ),
                    error: (error, __) => _StatePanel(
                      message: _friendlyLoadError("รายการปลายทาง", error),
                      isError: true,
                      actionLabel: "ลองใหม่",
                      onAction: () => ref.invalidate(connectorsProvider),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: scheme.outlineVariant.withValues(alpha: 0.45),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "รายการอ้างอิงสินทรัพย์",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "ผูกสินทรัพย์เข้ากับปลายทางโดยเก็บแค่ข้อมูลอ้างอิงที่ปลอดภัย เพื่อให้ปลายทางตรวจสอบรายละเอียดจริงเอง",
                  ),
                  const SizedBox(height: 10),
                  FilledButton.tonal(
                    onPressed: _addingAssetRef
                        ? null
                        : () => _handleAddAssetRef(connectorsAsync),
                    child: Text(
                      _addingAssetRef ? "กำลังบันทึก..." : "เพิ่มรายการสินทรัพย์",
                    ),
                  ),
                  const SizedBox(height: 10),
                  assetsAsync.when(
                    data: (items) {
                      if (items.isEmpty) {
                        return const _StatePanel(
                          message:
                              "ยังไม่มีรายการสินทรัพย์ กรุณาเพิ่มอย่างน้อย 1 รายการเพื่อเตรียมการส่งต่อแบบเข้ารหัส",
                          highlighted: true,
                        );
                      }
                      final connectors = connectorsAsync.value ?? const <PartnerConnectorModel>[];
                      final connectorNames = <String, String>{
                        for (final item in connectors) item.id: item.name,
                      };
                      return Column(
                        children: items
                            .map(
                              (asset) => ListTile(
                                contentPadding: EdgeInsets.zero,
                                title: Text(asset.displayName),
                                subtitle: Text(
                                  "ปลายทาง: ${connectorNames[asset.connectorRefId] ?? "ปลายทางเดิม"}\n"
                                  "ประเภท: ${_assetTypeLabel(asset.assetType)}\n"
                                  "ข้อมูลอ้างอิง: ${asset.encryptedPayloadRef}",
                                ),
                                isThreeLine: true,
                              ),
                            )
                            .toList(),
                      );
                    },
                    loading: () => const _StatePanel(
                      message: "กำลังโหลดรายการสินทรัพย์...",
                      showSpinner: true,
                    ),
                    error: (error, __) => _StatePanel(
                      message: _friendlyLoadError("รายการสินทรัพย์", error),
                      isError: true,
                      actionLabel: "ลองใหม่",
                      onAction: () => ref.invalidate(connectorAssetRefsProvider),
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
    final scheme = Theme.of(context).colorScheme;
    final color = isError
        ? scheme.errorContainer.withValues(alpha: 0.35)
        : highlighted
            ? scheme.primaryContainer.withValues(alpha: 0.3)
            : scheme.surfaceContainerHighest.withValues(alpha: 0.5);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.5)),
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

  InputDecoration _dialogInputDecoration(String label) {
    final scheme = Theme.of(context).colorScheme;
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.3),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("เพิ่มปลายทาง"),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _connectorId,
              decoration: _dialogInputDecoration("รหัสปลายทาง"),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _name,
              decoration: _dialogInputDecoration("ชื่อปลายทาง"),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _assetTypes,
              decoration: _dialogInputDecoration("ประเภทสินทรัพย์ที่รองรับ (คั่นด้วย comma)"),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _secondFactors,
              decoration: _dialogInputDecoration("วิธียืนยันตัวตน (คั่นด้วย comma)"),
            ),
            CheckboxListTile(
              value: _supportsWebhooks,
              onChanged: (v) => setState(() => _supportsWebhooks = v ?? false),
              title: const Text("รองรับการรับสัญญาณจากปลายทาง"),
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text("ยกเลิก"),
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
          child: const Text("บันทึก"),
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

  InputDecoration _dialogInputDecoration(String label) {
    final scheme = Theme.of(context).colorScheme;
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.3),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  bool _containsMoneyLikeText(String input) {
    if (input.trim().isEmpty) return false;
    final hasCurrency = RegExp(
      r'\b(thb|baht|usd|eur|บาท)\s*[\d,]+(?:\.\d{1,2})?\b',
      caseSensitive: false,
    ).hasMatch(input);
    final hasLargeNumber = RegExp(
      r'(?<!\w)([\d]{1,3}(?:,[\d]{3})+|[\d]{5,})(?:\.\d{1,2})?(?!\w)',
    ).hasMatch(input);
    return hasCurrency || hasLargeNumber;
  }

  String _redactMoneyLikeText(String input) {
    var output = input;
    output = output.replaceAllMapped(
      RegExp(
        r'\b(thb|baht|usd|eur|บาท)\s*[\d,]+(?:\.\d{1,2})?\b',
        caseSensitive: false,
      ),
      (_) => 'ตรวจที่ปลายทาง',
    );
    output = output.replaceAllMapped(
      RegExp(r'(?<!\w)[\d]{1,3}(?:,[\d]{3})+(?:\.\d{1,2})?(?!\w)'),
      (_) => 'ตรวจที่ปลายทาง',
    );
    output = output.replaceAllMapped(
      RegExp(r'(?<!\w)[\d]{5,}(?:\.\d{1,2})?(?!\w)'),
      (_) => 'ตรวจที่ปลายทาง',
    );
    return output;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("เพิ่มรายการสินทรัพย์"),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              initialValue: _connectorRefId,
              items: widget.connectors
                  .map(
                    (connector) => DropdownMenuItem(
                      value: connector.id,
                      child: Text("${connector.name} (${connector.connectorId})"),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) setState(() => _connectorRefId = value);
              },
              decoration: _dialogInputDecoration("ปลายทางที่เชื่อมไว้"),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _assetId,
              decoration: _dialogInputDecoration("รหัสสินทรัพย์"),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _assetType,
              decoration: _dialogInputDecoration("ประเภทสินทรัพย์"),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _displayName,
              decoration: _dialogInputDecoration("ชื่อที่จะแสดง"),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _payloadRef,
              onChanged: (_) => setState(() {}),
              decoration: _dialogInputDecoration("ข้อมูลอ้างอิงแบบเข้ารหัส"),
            ),
            if (_containsMoneyLikeText(_payloadRef.text)) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: const Color(0xFFFFF4E8),
                  border: Border.all(color: const Color(0xFFF0C48A)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "พบข้อความที่คล้ายยอดเงิน",
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'เพื่อความปลอดภัย ควรเก็บเป็นข้อมูลอ้างอิง ไม่ใส่ยอดเงินจริงในช่องนี้',
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: () {
                        setState(() {
                          _payloadRef.text =
                              _redactMoneyLikeText(_payloadRef.text);
                        });
                      },
                      icon: const Icon(Icons.shield_outlined),
                      label: const Text('แทนอัตโนมัติเป็น "ตรวจที่ปลายทาง"'),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 8),
            TextField(
              controller: _integrityHash,
              decoration: _dialogInputDecoration("ค่าแฮชตรวจความถูกต้อง"),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text("ยกเลิก"),
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
          child: const Text("บันทึก"),
        ),
      ],
    );
  }
}
