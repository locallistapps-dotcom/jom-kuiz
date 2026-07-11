import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/result.dart';
import '../../domain/entities/admin_content.dart';
import '../../domain/repositories/admin_repository.dart';
import '../providers/admin_providers.dart';

/// Manages [AdminContent] list state for the Admin CMS.
///
/// Wraps [AdminRepository] publish / unpublish operations and keeps the
/// in-memory list in sync so the UI doesn't need to re-fetch after mutations.
class AdminContentController extends AsyncNotifier<List<AdminContent>> {
  AdminRepository get _repository =>
      ref.read(adminRepositoryProvider);

  @override
  Future<List<AdminContent>> build() async {
    final Result<List<AdminContent>> result =
        await _repository.getContent();
    return result.when(
      success: (List<AdminContent> list) => list,
      failure: (f) => throw f,
    );
  }

  /// Re-fetches the full content list from the server.
  Future<void> refresh() async {
    state = const AsyncValue<List<AdminContent>>.loading();
    state = await AsyncValue.guard(() => build());
  }

  /// Publishes [contentId] and updates the list in place.
  Future<Result<AdminContent>> publishContent({
    required String contentId,
  }) async {
    final Result<AdminContent> result =
        await _repository.publishContent(contentId: contentId);

    result.when(
      success: (AdminContent updated) {
        state = state.whenData(
          (List<AdminContent> list) => list
              .map((AdminContent c) =>
                  c.contentId == contentId ? updated : c)
              .toList(),
        );
      },
      failure: (_) {},
    );

    return result;
  }

  /// Unpublishes [contentId] and updates the list in place.
  Future<Result<AdminContent>> unpublishContent({
    required String contentId,
  }) async {
    final Result<AdminContent> result =
        await _repository.unpublishContent(contentId: contentId);

    result.when(
      success: (AdminContent updated) {
        state = state.whenData(
          (List<AdminContent> list) => list
              .map((AdminContent c) =>
                  c.contentId == contentId ? updated : c)
              .toList(),
        );
      },
      failure: (_) {},
    );

    return result;
  }
}

/// Global provider for [AdminContentController].
final AsyncNotifierProvider<AdminContentController, List<AdminContent>>
    adminContentControllerProvider =
    AsyncNotifierProvider<AdminContentController, List<AdminContent>>(
  AdminContentController.new,
);
