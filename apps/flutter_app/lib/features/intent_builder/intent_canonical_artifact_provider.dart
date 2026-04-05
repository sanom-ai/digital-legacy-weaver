import 'package:digital_legacy_weaver/features/intent_builder/intent_canonical_artifact_repository.dart';
import 'package:digital_legacy_weaver/features/intent_builder/intent_canonical_artifact_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final intentCanonicalArtifactRepositoryProvider = Provider<IntentCanonicalArtifactRepository>((ref) {
  return IntentCanonicalArtifactRepository();
});

final intentCanonicalArtifactProvider = FutureProvider.family<IntentCanonicalArtifactModel?, String>((ref, ownerRef) {
  return ref.read(intentCanonicalArtifactRepositoryProvider).loadArtifact(ownerRef: ownerRef);
});

final intentCanonicalArtifactHistoryProvider = FutureProvider.family<List<IntentCanonicalArtifactModel>, String>((ref, ownerRef) {
  return ref.read(intentCanonicalArtifactRepositoryProvider).loadArtifactHistory(ownerRef: ownerRef);
});
