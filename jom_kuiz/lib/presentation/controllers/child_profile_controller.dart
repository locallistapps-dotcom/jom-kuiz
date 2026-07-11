import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/error/failure.dart';
import '../../core/utils/result.dart';
import '../../domain/entities/child_profile.dart';
import '../providers/child_providers.dart';

/// Manages the currently selected child's profile.
///
/// Reacts automatically when [currentChildIdProvider] changes. Mutation
/// methods return [Result]<T> and only update state on success — a failed
/// save never blanks the previously loaded profile.
final AsyncNotifierProvider<ChildProfileController, ChildProfile?>
    childProfileControllerProvider =
    AsyncNotifierProvider<ChildProfileController, ChildProfile?>(
        ChildProfileController.new);

class ChildProfileController extends AsyncNotifier<ChildProfile?> {
  @override
  Future<ChildProfile?> build() async {
    final String childId = ref.watch(currentChildIdProvider);
    if (childId.isEmpty) return null;
    final Result<ChildProfile> result =
        await ref.watch(childServiceProvider).getProfile(childId: childId);
    return result.when(
      success: (ChildProfile profile) => profile,
      failure: (Failure failure) => throw failure,
    );
  }

  Future<void> refresh() async {
    state = const AsyncValue<ChildProfile?>.loading();
    state = await AsyncValue.guard<ChildProfile?>(() async {
      final String childId = ref.read(currentChildIdProvider);
      if (childId.isEmpty) return null;
      final Result<ChildProfile> result =
          await ref.read(childServiceProvider).getProfile(childId: childId);
      return result.when(success: (p) => p, failure: (f) => throw f);
    });
  }

  Future<Result<ChildProfile>> updateProfile({
    required String fullName,
    String? dateOfBirth,
    String? gender,
    String? school,
    String? grade,
    String? bio,
  }) async {
    final String childId = ref.read(currentChildIdProvider);
    final Result<ChildProfile> result =
        await ref.read(childServiceProvider).updateProfile(
              childId: childId,
              fullName: fullName,
              dateOfBirth: dateOfBirth,
              gender: gender,
              school: school,
              grade: grade,
              bio: bio,
            );
    result.when(
      success: (ChildProfile profile) {
        state = AsyncValue<ChildProfile?>.data(profile);
      },
      failure: (_) {},
    );
    return result;
  }

  Future<Result<ChildProfile>> updateAvatar(
      {required String localFilePath}) async {
    final String childId = ref.read(currentChildIdProvider);
    final Result<ChildProfile> result = await ref
        .read(childServiceProvider)
        .updateAvatar(childId: childId, localFilePath: localFilePath);
    result.when(
      success: (ChildProfile profile) {
        state = AsyncValue<ChildProfile?>.data(profile);
      },
      failure: (_) {},
    );
    return result;
  }
}
