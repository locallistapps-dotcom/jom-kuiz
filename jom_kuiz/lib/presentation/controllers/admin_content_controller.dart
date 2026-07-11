import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/result.dart';
import '../../domain/entities/admin_content.dart';
import '../../domain/repositories/admin_repository.dart';
import '../providers/admin_providers.dart';

/// Manages [AdminContent] list state for the Admin CMS.
///
/// Wraps [AdminRepository] for full CRUD + publish/unpublish operations
/// and keeps the in-memory list in sync so the UI doesn't re-fetch after
/// each mutation.
class AdminContentController extends AsyncNotifier<List<AdminContent>> {
  AdminRepository get _repository => ref.read(adminRepositoryProvider);

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

  // ── Create ────────────────────────────────────────────────────────────────

  /// Creates a new content item and prepends it to the list on success.
  Future<Result<AdminContent>> createContent({
    required AdminContentType type,
    required String title,
    required String body,
    String? imageUrl,
  }) async {
    final Result<AdminContent> result = await _repository.createContent(
      type: type,
      title: title,
      body: body,
      imageUrl: imageUrl,
    );

    result.when(
      success: (AdminContent created) {
        state = state.whenData(
          (List<AdminContent> list) => <AdminContent>[created, ...list],
        );
      },
      failure: (_) {},
    );

    return result;
  }

  // ── Update ────────────────────────────────────────────────────────────────

  /// Updates a content item and replaces it in the list on success.
  Future<Result<AdminContent>> updateContent({
    required String contentId,
    required AdminContentType type,
    required String title,
    required String body,
    String? imageUrl,
  }) async {
    final Result<AdminContent> result = await _repository.updateContent(
      contentId: contentId,
      type: type,
      title: title,
      body: body,
      imageUrl: imageUrl,
    );

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

  // ── Delete ────────────────────────────────────────────────────────────────

  /// Hard-deletes a content item and removes it from the list.
  Future<Result<void>> deleteContent({required String contentId}) async {
    final Result<void> result =
        await _repository.deleteContent(contentId: contentId);

    result.when(
      success: (_) {
        state = state.whenData(
          (List<AdminContent> list) => list
              .where((AdminContent c) => c.contentId != contentId)
              .toList(),
        );
      },
      failure: (_) {},
    );

    return result;
  }

  // ── Publish toggles ───────────────────────────────────────────────────────

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
