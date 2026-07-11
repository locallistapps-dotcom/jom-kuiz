import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/error/failure.dart';
import '../../core/utils/result.dart';
import '../../domain/entities/parent_profile.dart';
import '../providers/parent_providers.dart';

/// Loads the current parent's profile and exposes profile/avatar/password/
/// settings/account-deletion mutations to the Parent screens.
///
/// Built manually (no `riverpod_generator`) so this compiles without a
/// `build_runner` codegen step.
///
/// Mutation methods return the raw [Result] rather than a bare `bool` so
/// screens can read the [Failure] directly, and deliberately only update
/// `state` on success -- a failed mutation (e.g. invalid phone number) must
/// not blank out the already-loaded profile or show a stray loading spinner.
final AsyncNotifierProvider<ParentController, ParentProfile?> parentControllerProvider =
    AsyncNotifierProvider<ParentController, ParentProfile?>(ParentController.new);

class ParentController extends AsyncNotifier<ParentProfile?> {
  @override
  Future<ParentProfile?> build() async {
    final Result<ParentProfile> result = await ref.watch(parentServiceProvider).getProfile();
    return result.when(
      success: (ParentProfile profile) => profile,
      failure: (Failure failure) => throw failure,
    );
  }

  Future<void> refresh() async {
    state = const AsyncValue<ParentProfile?>.loading();
    state = await AsyncValue.guard(() async {
      final Result<ParentProfile> result = await ref.read(parentServiceProvider).getProfile();
      return result.when(success: (p) => p, failure: (f) => throw f);
    });
  }

  Future<Result<ParentProfile>> updateProfile({
    required String fullName,
    String? phoneNumber,
    String? country,
    String? state,
    String? city,
    String? gender,
    DateTime? dateOfBirth,
    String? language,
    String? bio,
  }) async {
    final Result<ParentProfile> result = await ref.read(parentServiceProvider).updateProfile(
          fullName: fullName,
          phoneNumber: phoneNumber,
          country: country,
          state: state,
          city: city,
          gender: gender,
          dateOfBirth: dateOfBirth,
          language: language,
          bio: bio,
        );

    result.when(
      success: (ParentProfile profile) => this.state = AsyncValue<ParentProfile?>.data(profile),
      failure: (_) {}, // Keep the previously loaded profile; caller shows the error.
    );
    return result;
  }

  Future<Result<ParentProfile>> updateAvatar({required String localFilePath}) async {
    final Result<ParentProfile> result =
        await ref.read(parentServiceProvider).updateAvatar(localFilePath: localFilePath);

    result.when(
      success: (ParentProfile profile) => state = AsyncValue<ParentProfile?>.data(profile),
      failure: (_) {},
    );
    return result;
  }

  Future<Result<void>> updatePassword({
    required String currentPassword,
    required String newPassword,
  }) {
    return ref.read(parentServiceProvider).updatePassword(
          currentPassword: currentPassword,
          newPassword: newPassword,
        );
  }

  Future<Result<ParentProfile>> updateSettings({String? language, bool? notificationEnabled}) async {
    final Result<ParentProfile> result = await ref.read(parentServiceProvider).updateSettings(
          language: language,
          notificationEnabled: notificationEnabled,
        );

    result.when(
      success: (ParentProfile profile) => state = AsyncValue<ParentProfile?>.data(profile),
      failure: (_) {},
    );
    return result;
  }

  Future<Result<void>> deleteAccount() {
    return ref.read(parentServiceProvider).deleteAccount();
  }
}
