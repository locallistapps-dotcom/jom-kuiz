import '../../core/utils/result.dart';
import '../entities/admin_content.dart';

/// Abstract contract for Admin CMS operations.
abstract interface class AdminRepository {
  /// Returns all content items, optionally filtered by [type].
  Future<Result<List<AdminContent>>> getContent({AdminContentType? type});

  /// Returns a single content item by [contentId].
  Future<Result<AdminContent>> getContentById({required String contentId});

  /// Publishes a content item, setting [AdminContent.isPublished] to true.
  Future<Result<AdminContent>> publishContent({required String contentId});

  /// Unpublishes a content item.
  Future<Result<AdminContent>> unpublishContent({required String contentId});
}
