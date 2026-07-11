import '../../domain/entities/topic.dart';

/// Wire-format DTO for a Topic row returned by the Supabase REST API.
///
/// Supabase (PostgREST) returns snake_case JSON keys. Hand-written
/// [fromJson]/[toJson] — no codegen required.
class TopicModel {
  const TopicModel({
    required this.topicId,
    required this.chapterId,
    required this.topicName,
    required this.displayOrder,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    this.description,
  });

  final String topicId;
  final String chapterId;
  final String topicName;
  final String? description;
  final int displayOrder;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory TopicModel.fromJson(Map<String, dynamic> json) {
    return TopicModel(
      topicId: json['id'] as String,
      chapterId: json['chapter_id'] as String,
      topicName: json['topic_name'] as String,
      description: json['description'] as String?,
      displayOrder: (json['display_order'] as num?)?.toInt() ?? 0,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': topicId,
        'chapter_id': chapterId,
        'topic_name': topicName,
        'description': description,
        'display_order': displayOrder,
        'is_active': isActive,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  Topic toEntity() {
    return Topic(
      topicId: topicId,
      chapterId: chapterId,
      topicName: topicName,
      description: description,
      displayOrder: displayOrder,
      isActive: isActive,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

// ── Request bodies ────────────────────────────────────────────────────────────

/// Body sent to Supabase when creating a new topic (POST /topics).
class CreateTopicRequest {
  const CreateTopicRequest({
    required this.chapterId,
    required this.topicName,
    this.description,
    this.displayOrder = 0,
  });

  final String chapterId;
  final String topicName;
  final String? description;
  final int displayOrder;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'chapter_id': chapterId,
        'topic_name': topicName,
        if (description != null && description!.isNotEmpty)
          'description': description,
        'display_order': displayOrder,
        'is_active': true,
      };
}

/// Body sent to Supabase when updating a topic (PATCH /topics?id=eq.{id}).
class UpdateTopicRequest {
  const UpdateTopicRequest({
    required this.chapterId,
    required this.topicName,
    this.description,
    required this.displayOrder,
    required this.isActive,
  });

  final String chapterId;
  final String topicName;
  final String? description;
  final int displayOrder;
  final bool isActive;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'chapter_id': chapterId,
        'topic_name': topicName,
        'description':
            (description != null && description!.isNotEmpty) ? description : null,
        'display_order': displayOrder,
        'is_active': isActive,
      };
}

/// Body sent when toggling the active status only.
class ToggleTopicActiveRequest {
  const ToggleTopicActiveRequest({required this.isActive});

  final bool isActive;

  Map<String, dynamic> toJson() => <String, dynamic>{'is_active': isActive};
}
