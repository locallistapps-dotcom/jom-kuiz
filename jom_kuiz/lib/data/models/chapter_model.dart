import '../../domain/entities/chapter.dart';

/// Wire-format DTO for a Chapter row returned by the Supabase REST API.
///
/// Supabase (PostgREST) returns snake_case JSON keys. Hand-written
/// [fromJson]/[toJson] — no codegen required.
class ChapterModel {
  const ChapterModel({
    required this.chapterId,
    required this.subjectId,
    required this.yearId,
    required this.chapterName,
    required this.displayOrder,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    this.description,
  });

  final String chapterId;
  final String subjectId;
  final String yearId;
  final String chapterName;
  final String? description;
  final int displayOrder;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory ChapterModel.fromJson(Map<String, dynamic> json) {
    return ChapterModel(
      chapterId: json['id'] as String,
      subjectId: json['subject_id'] as String,
      yearId: json['year_id'] as String,
      chapterName: json['chapter_name'] as String,
      description: json['description'] as String?,
      displayOrder: (json['display_order'] as num?)?.toInt() ?? 0,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': chapterId,
        'subject_id': subjectId,
        'year_id': yearId,
        'chapter_name': chapterName,
        'description': description,
        'display_order': displayOrder,
        'is_active': isActive,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  Chapter toEntity() {
    return Chapter(
      chapterId: chapterId,
      subjectId: subjectId,
      yearId: yearId,
      chapterName: chapterName,
      description: description,
      displayOrder: displayOrder,
      isActive: isActive,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

// ── Request bodies ────────────────────────────────────────────────────────────

/// Body sent to Supabase when creating a new chapter (POST /chapters).
class CreateChapterRequest {
  const CreateChapterRequest({
    required this.subjectId,
    required this.yearId,
    required this.chapterName,
    this.description,
    this.displayOrder = 0,
  });

  final String subjectId;
  final String yearId;
  final String chapterName;
  final String? description;
  final int displayOrder;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'subject_id': subjectId,
        'year_id': yearId,
        'chapter_name': chapterName,
        if (description != null && description!.isNotEmpty)
          'description': description,
        'display_order': displayOrder,
        'is_active': true,
      };
}

/// Body sent to Supabase when updating a chapter
/// (PATCH /chapters?id=eq.{id}).
class UpdateChapterRequest {
  const UpdateChapterRequest({
    required this.subjectId,
    required this.yearId,
    required this.chapterName,
    this.description,
    required this.displayOrder,
    required this.isActive,
  });

  final String subjectId;
  final String yearId;
  final String chapterName;
  final String? description;
  final int displayOrder;
  final bool isActive;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'subject_id': subjectId,
        'year_id': yearId,
        'chapter_name': chapterName,
        'description':
            (description != null && description!.isNotEmpty) ? description : null,
        'display_order': displayOrder,
        'is_active': isActive,
      };
}

/// Body sent when toggling the active status only.
class ToggleChapterActiveRequest {
  const ToggleChapterActiveRequest({required this.isActive});

  final bool isActive;

  Map<String, dynamic> toJson() => <String, dynamic>{'is_active': isActive};
}
