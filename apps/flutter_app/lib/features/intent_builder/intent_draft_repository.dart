import 'dart:convert';

import 'package:digital_legacy_weaver/features/intent_builder/intent_builder_model.dart';
import 'package:cryptography/cryptography.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class IntentDraftRepository {
  IntentDraftRepository({
    FlutterSecureStorage? secureStorage,
    AesGcm? cipher,
  }) : _secureStorage = secureStorage ?? const FlutterSecureStorage(),
       _cipher = cipher ?? AesGcm.with256bits();

  static const _storagePrefix = 'intent_draft::';
  static const _keyPrefix = 'intent_draft_key::';
  static const _envelopeVersion = 1;

  final FlutterSecureStorage _secureStorage;
  final AesGcm _cipher;

  Future<IntentDocumentModel?> loadDraft({required String ownerRef}) async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString(_storageKey(ownerRef));
    if (raw == null || raw.trim().isEmpty) {
      return null;
    }
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) {
      return null;
    }

    if (decoded.containsKey('ciphertext') && decoded.containsKey('nonce')) {
      return _loadEncryptedDraft(ownerRef: ownerRef, envelope: decoded);
    }

    if (decoded.containsKey('intent_id')) {
      final legacy = IntentDocumentModel.fromMap(decoded);
      await saveDraft(legacy);
      return legacy;
    }

    return null;
  }

  Future<void> saveDraft(IntentDocumentModel document) async {
    final preferences = await SharedPreferences.getInstance();
    final payload = document.copyWith(
      metadata: {
        ...document.metadata,
        'storage_mode': 'local_device_draft_encrypted',
        'saved_at': DateTime.now().toUtc().toIso8601String(),
      },
    );
    final secretKey = await _loadOrCreateSecretKey(document.ownerRef);
    final secretBox = await _cipher.encrypt(
      utf8.encode(jsonEncode(payload.toMap())),
      secretKey: secretKey,
    );
    await preferences.setString(
      _storageKey(document.ownerRef),
      jsonEncode({
        'format': 'encrypted_intent_draft',
        'version': _envelopeVersion,
        'nonce': base64Encode(secretBox.nonce),
        'ciphertext': base64Encode(secretBox.cipherText),
        'mac': base64Encode(secretBox.mac.bytes),
      }),
    );
  }

  Future<void> clearDraft({required String ownerRef}) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_storageKey(ownerRef));
    await _secureStorage.delete(key: _keyStorageKey(ownerRef));
  }

  String _storageKey(String ownerRef) => '$_storagePrefix$ownerRef';

  String _keyStorageKey(String ownerRef) => '$_keyPrefix$ownerRef';

  Future<IntentDocumentModel?> _loadEncryptedDraft({
    required String ownerRef,
    required Map<String, dynamic> envelope,
  }) async {
    final keyMaterial = await _secureStorage.read(key: _keyStorageKey(ownerRef));
    if (keyMaterial == null || keyMaterial.trim().isEmpty) {
      return null;
    }

    final secretKey = SecretKey(base64Decode(keyMaterial));
    final secretBox = SecretBox(
      base64Decode(envelope['ciphertext'] as String),
      nonce: base64Decode(envelope['nonce'] as String),
      mac: Mac(base64Decode(envelope['mac'] as String)),
    );
    final clearBytes = await _cipher.decrypt(secretBox, secretKey: secretKey);
    final decoded = jsonDecode(utf8.decode(clearBytes));
    if (decoded is! Map<String, dynamic>) {
      return null;
    }
    return IntentDocumentModel.fromMap(decoded);
  }

  Future<SecretKey> _loadOrCreateSecretKey(String ownerRef) async {
    final existing = await _secureStorage.read(key: _keyStorageKey(ownerRef));
    if (existing != null && existing.trim().isNotEmpty) {
      return SecretKey(base64Decode(existing));
    }

    final secretKey = await _cipher.newSecretKey();
    final keyBytes = await secretKey.extractBytes();
    await _secureStorage.write(
      key: _keyStorageKey(ownerRef),
      value: base64Encode(keyBytes),
    );
    return secretKey;
  }
}
