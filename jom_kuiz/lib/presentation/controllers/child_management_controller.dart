import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/result.dart';
import '../../data/models/account_management_models.dart';
import '../../domain/entities/education_level.dart';
import '../providers/account_management_providers.dart';

/// Manages the state of a single child's management view, and exposes CRUD
/// mutations for the parent screens.
///
/// Keyed by `childId` so multiple instances can coexist in the widget tree
/// (e.g. when navigating from a list into a detail screen).
final AutoDisposeAsyncNotifierProviderFamily<ChildManagementController,
        ChildManagementModel, String> childManagementControllerProvider =
    AsyncNotifierProvider.autoDispose
        .family<ChildManagementController, ChildManagementModel, String>(
            ChildManagementController.new);

class ChildManagementController
    extends AutoDisposeFamilyAsyncNotifier<ChildManagementModel, String> {
  @override
  Future<ChildManagementModel> build(String arg) async {
    // `arg` is the childId.
    final Result<ChildManagementModel> result =
        await ref.read(accountManagementServiceProvider).getChild(arg);
    return result.when(
      success: (ChildManagementModel m) => m,
      failure: (f) => throw f,
    );
  }

  Future<void> refresh() async {
    state = const AsyncValue<ChildManagementModel>.loading();
    state = await AsyncValue.guard(() async {
      final Result<ChildManagementModel> result =
          await ref.read(accountManagementServiceProvider).getChild(arg);
      return result.when(success: (m) => m, failure: (f) => throw f);
    });
  }

  /// Updates child profile fields. Returns the [Result] so the screen can
  /// display a success or error message.
  Future<Result<ChildManagementModel>> updateChild({
    required String fullName,
    required String username,
    String? password,
    required EducationLevel educationLevel,
    required String yearGrade,
  }) async {
    final ChildManagementModel? current = state.valueOrNull;
    final Result<ChildManagementModel> result = await ref
        .read(accountManagementServiceProvider)
        .updateChild(
          childId: arg,
          currentUsername: current?.username ?? '',
          fullName: fullName,
          username: username,
          password: password,
          educationLevel: educationLevel,
          yearGrade: yearGrade,
        );
    result.when(
      success: (ChildManagementModel m) {
        state = AsyncValue<ChildManagementModel>.data(m);
      },
      failure: (_) {},
    );
    return result;
  }

  /// Enables or disables the child account.
  Future<Result<ChildManagementModel>> setStatus(
      ChildAccountStatus status) async {
    final Result<ChildManagementModel> result = await ref
        .read(accountManagementServiceProvider)
        .setChildStatus(childId: arg, status: status);
    result.when(
      success: (ChildManagementModel m) {
        state = AsyncValue<ChildManagementModel>.data(m);
      },
      failure: (_) {},
    );
    return result;
  }

  /// Resets the child's password. Returns the [Result] for screen feedback.
  Future<Result<void>> resetPassword(String newPassword) =>
      ref.read(accountManagementServiceProvider).resetChildPassword(
            childId: arg,
            newPassword: newPassword,
          );

  /// Permanently deletes this child account. The parent must confirm before
  /// calling this; no undo is possible after success.
  Future<Result<void>> deleteChild() =>
      ref.read(accountManagementServiceProvider).deleteChild(childId: arg);
}
