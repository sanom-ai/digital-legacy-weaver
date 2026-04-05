import 'package:digital_legacy_weaver/features/intent_builder/intent_canonical_artifact_repository.dart';
import 'package:digital_legacy_weaver/features/intent_builder/intent_canonical_artifact_model.dart';
import 'package:digital_legacy_weaver/features/intent_builder/intent_draft_provider.dart';
import 'package:digital_legacy_weaver/features/intent_builder/intent_runtime_readiness_model.dart';
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

final intentRuntimeReadinessProvider = FutureProvider.family<IntentRuntimeReadinessModel, String>((ref, ownerRef) async {
  final artifactRepository = ref.read(intentCanonicalArtifactRepositoryProvider);
  final draftRepository = ref.read(intentDraftRepositoryProvider);

  final currentArtifact = await artifactRepository.loadArtifact(ownerRef: ownerRef);
  final artifactHistory = await artifactRepository.loadArtifactHistory(ownerRef: ownerRef);
  final currentDraft = await draftRepository.loadDraft(ownerRef: ownerRef);

  return IntentRuntimeReadinessModel.fromArtifacts(
    currentArtifact: currentArtifact,
    currentDraft: currentDraft,
    artifactHistory: artifactHistory,
  );
});
