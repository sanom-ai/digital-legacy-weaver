import 'package:digital_legacy_weaver/features/intent_builder/intent_draft_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final intentDraftRepositoryProvider = Provider<IntentDraftRepository>((ref) {
  return IntentDraftRepository();
});
