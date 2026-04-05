import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:digital_legacy_weaver/features/intent_builder/intent_canonical_artifact_model.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class IntentCanonicalArtifactRepository {
  IntentCanonicalArtifactRepository({
    FlutterSecureStorage? secureStorage,
    AesGcm? cipher,
  }) : _secureStorage = secureStorage ?? const FlutterSecureStorage(),
       _cipher = cipher ?? AesGcm.with256bits();

  static const _artifactPrefix = 'intent_canonical_artifact::';
  static const _artifactKeyPrefix = 'intent_canonical_artifact_key::';
  static const _envelopeVersion = 1;

  final FlutterSecureStorage _secureStorage;
  final AesGcm _cipher;

  Future<IntentCanonicalArtifactModel?> loadArtifact({required String ownerRef}) async {
    final history = await loadArtifactHistory(ownerRef: ownerRef);
    if (history.isEmpty) {
      return null;
    }
    return history.first;
  }

  Future<List<IntentCanonicalArtifactModel>> loadArtifactHistory({required String ownerRef}) async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString(_storageKey(ownerRef));
    if (raw == null || raw.trim().isEmpty) {
      return const <IntentCanonicalArtifactModel>[];
    }

    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) {
      return const <IntentCanonicalArtifactModel>[];
    }
    if (!decoded.containsKey('ciphertext') || !decoded.containsKey('nonce')) {
      return const <IntentCanonicalArtifactModel>[];
    }

    final keyMaterial = await _secureStorage.read(key: _keyStorageKey(ownerRef));
    if (keyMaterial == null || keyMaterial.trim().isEmpty) {
      return const <IntentCanonicalArtifactModel>[];
    }

    final secretKey = SecretKey(base64Decode(keyMaterial));
    final secretBox = SecretBox(
      base64Decode(decoded['ciphertext'] as String),
      nonce: base64Decode(decoded['nonce'] as String),
      mac: Mac(base64Decode(decoded['mac'] as String)),
    );
    final clearBytes = await _cipher.decrypt(secretBox, secretKey: secretKey);
    final payload = jsonDecode(utf8.decode(clearBytes));
    if (payload is! Map<String, dynamic>) {
      return const <IntentCanonicalArtifactModel>[];
    }

    if (payload.containsKey('artifacts')) {
      final rawArtifacts = payload['artifacts'];
      if (rawArtifacts is! List) {
        return const <IntentCanonicalArtifactModel>[];
      }
      final artifacts = rawArtifacts
          .whereType<Map>()
          .map((item) => IntentCanonicalArtifactModel.fromMap(Map<String, dynamic>.from(item)))
          .toList();
      artifacts.sort((left, right) => right.generatedAt.compareTo(left.generatedAt));
      return artifacts;
    }

    return [IntentCanonicalArtifactModel.fromMap(payload)];
  }

  Future<void> saveArtifact(IntentCanonicalArtifactModel artifact) async {
    final preferences = await SharedPreferences.getInstance();
    final secretKey = await _loadOrCreateSecretKey(artifact.ownerRef);
    final existing = await loadArtifactHistory(ownerRef: artifact.ownerRef);
    final nextArtifacts = [
      artifact,
      for (final item in existing)
        if (item.artifactId != artifact.artifactId) item,
    ]..sort((left, right) => right.generatedAt.compareTo(left.generatedAt));
    final secretBox = await _cipher.encrypt(
      utf8.encode(
        jsonEncode({
          'format': 'intent_canonical_artifact_history',
          'artifacts': nextArtifacts.map((item) => item.toMap()).toList(),
        }),
      ),
      secretKey: secretKey,
    );
    await preferences.setString(
      _storageKey(artifact.ownerRef),
      jsonEncode({
        'format': 'encrypted_intent_canonical_artifact',
        'version': _envelopeVersion,
        'nonce': base64Encode(secretBox.nonce),
        'ciphertext': base64Encode(secretBox.cipherText),
        'mac': base64Encode(secretBox.mac.bytes),
      }),
    );
  }

  Future<void> clearArtifact({required String ownerRef}) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_storageKey(ownerRef));
    await _secureStorage.delete(key: _keyStorageKey(ownerRef));
  }

  Future<void> clearArtifactVersion({
    required String ownerRef,
    required String artifactId,
  }) async {
    final preferences = await SharedPreferences.getInstance();
    final existing = await loadArtifactHistory(ownerRef: ownerRef);
    final nextArtifacts = [
      for (final item in existing)
        if (item.artifactId != artifactId) item,
    ];
    if (nextArtifacts.isEmpty) {
      await clearArtifact(ownerRef: ownerRef);
      return;
    }

    final secretKey = await _loadOrCreateSecretKey(ownerRef);
    final secretBox = await _cipher.encrypt(
      utf8.encode(
        jsonEncode({
          'format': 'intent_canonical_artifact_history',
          'artifacts': nextArtifacts.map((item) => item.toMap()).toList(),
        }),
      ),
      secretKey: secretKey,
    );
    await preferences.setString(
      _storageKey(ownerRef),
      jsonEncode({
        'format': 'encrypted_intent_canonical_artifact',
        'version': _envelopeVersion,
        'nonce': base64Encode(secretBox.nonce),
        'ciphertext': base64Encode(secretBox.cipherText),
        'mac': base64Encode(secretBox.mac.bytes),
      }),
    );
  }

  Future<IntentCanonicalArtifactModel?> promoteArtifactVersion({
    required String ownerRef,
    required String artifactId,
  }) async {
    final existing = await loadArtifactHistory(ownerRef: ownerRef);
    IntentCanonicalArtifactModel? source;
    for (final item in existing) {
      if (item.artifactId == artifactId) {
        source = item;
        break;
      }
    }
    if (source == null) {
      return null;
    }

    final promotedAt = DateTime.now().toUtc();
    final promoted = source.copyWith(
      artifactId: 'artifact_${promotedAt.millisecondsSinceEpoch}',
      promotedFromArtifactId: source.artifactId,
      artifactState: IntentArtifactState.exported,
      generatedAt: promotedAt,
      sealedReleaseCandidate: source.sealedReleaseCandidate.copyWith(
        candidateId: 'release_candidate_${promotedAt.millisecondsSinceEpoch}',
        sealedAt: promotedAt,
      ),
    );
    await saveArtifact(promoted);
    return promoted;
  }

  String _storageKey(String ownerRef) => '$_artifactPrefix$ownerRef';

  String _keyStorageKey(String ownerRef) => '$_artifactKeyPrefix$ownerRef';

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
