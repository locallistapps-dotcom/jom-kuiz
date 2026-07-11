import '../../core/utils/result.dart';
import '../entities/admin_content.dart';

/// Abstract contract for Admin CMS operations.
///
/// Covers the full CRUD lifecycle for [AdminContent] items plus
/// publish / unpublish toggles.
abstract interface class AdminRepository {
  // ── Read ──────────────────────────────────────────────────────────────────

  /// Returns all content items, optionally filtered by [type].
  Future<Result<List<AdminContent>>> getContent({AdminContentType? type});

  /// Returns a single content item by [contentId].
  Future<Result<AdminContent>> getContentById({required String contentId});

  // ── Create / Update / Delete ──────────────────────────────────────────────

  /// Creates a new content item and returns the persisted entity.
  Future<Result<AdminContent>> createContent({
    required AdminContentType type,
    required String title,
    required String body,
    String? imageUrl,
  });

  /// Updates an existing content item. Only the provided fields are changed;
  /// publish status is managed by [publishContent] / [unpublishContent].
  Future<Result<AdminContent>> updateContent({
    required String contentId,
    required AdminContentType type,
    required String title,
    required String body,
    String? imageUrl,
  });

  /// Hard-deletes a content item.
  Future<Result<void>> deleteContent({required String contentId});

  // ── Publish toggles ───────────────────────────────────────────────────────

  /// Publishes a content item, setting [AdminContent.isPublished] to `true`.
  Future<Result<AdminContent>> publishContent({required String contentId});

  /// Unpublishes a content item, setting [AdminContent.isPublished] to `false`.
  Future<Result<AdminContent>> unpublishContent({required String contentId});
}
