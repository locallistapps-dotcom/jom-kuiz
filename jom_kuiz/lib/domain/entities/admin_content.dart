import 'package:equatable/equatable.dart';

/// The kind of content managed through the Admin CMS.
enum AdminContentType { announcement, banner, lesson, faq }

/// A single content item managed by an admin.
class AdminContent extends Equatable {
  const AdminContent({
    required this.contentId,
    required this.type,
    required this.title,
    required this.body,
    required this.createdAt,
    this.isPublished = false,
    this.publishedAt,
    this.imageUrl,
  });

  final String contentId;
  final AdminContentType type;
  final String title;
  final String body;
  final bool isPublished;
  final DateTime createdAt;
  final DateTime? publishedAt;
  final String? imageUrl;

  @override
  List<Object?> get props => <Object?>[
        contentId,
        type,
        title,
        body,
        isPublished,
        createdAt,
        publishedAt,
        imageUrl,
      ];
}
