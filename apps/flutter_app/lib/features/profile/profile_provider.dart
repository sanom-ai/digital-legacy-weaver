import 'package:digital_legacy_weaver/core/providers/supabase_provider.dart';
import 'package:digital_legacy_weaver/features/profile/profile_model.dart';
import 'package:digital_legacy_weaver/features/profile/profile_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository(ref.watch(supabaseClientProvider));
});

final profileProvider = FutureProvider<ProfileModel>((ref) {
  return ref.watch(profileRepositoryProvider).getOrCreateProfile();
});
