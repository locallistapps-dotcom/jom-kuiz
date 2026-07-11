import '../../domain/entities/subject.dart';

/// Wire-format DTO for a Subject row returned by the Supabase REST API.
///
/// Supabase (PostgREST) returns snake_case JSON keys. Hand-written
/// [fromJson]/[toJson] — no codegen required.
class SubjectModel {
  const SubjectModel({
    required this.subjectId,
    required this.subjectName,
    required this.displayOrder,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    this.description,
    this.icon,
  });

  final String subjectId;
  final String subjectName;
  final String? description;
  final String? icon;
  final int displayOrder;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory SubjectModel.fromJson(Map<String, dynamic> json) {
    return SubjectModel(
      subjectId: json['id'] as String,
      subjectName: json['subject_name'] as String,
      description: json['description'] as String?,
      icon: json['icon'] as String?,
      displayOrder: (json['display_order'] as num?)?.toInt() ?? 0,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': subjectId,
        'subject_name': subjectName,
        'description': description,
        'icon': icon,
        'display_order': displayOrder,
        'is_active': isActive,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  Subject toEntity() {
    return Subject(
      subjectId: subjectId,
      subjectName: subjectName,
      description: description,
      icon: icon,
      displayOrder: displayOrder,
      isActive: isActive,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

// ── Request bodies ────────────────────────────────────────────────────────────

/// Body sent to Supabase when creating a new subject (POST /subjects).
class CreateSubjectRequest {
  const CreateSubjectRequest({
    required this.subjectName,
    this.description,
    this.icon,
    this.displayOrder = 0,
  });

  final String subjectName;
  final String? description;
  final String? icon;
  final int displayOrder;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'subject_name': subjectName,
        if (description != null) 'description': description,
        if (icon != null) 'icon': icon,
        'display_order': displayOrder,
        'is_active': true, // defaults to active on creation
      };
}

/// Body sent to Supabase when updating an existing subject (PATCH /subjects?id=eq.{id}).
class UpdateSubjectRequest {
  const UpdateSubjectRequest({
    required this.subjectName,
    required this.displayOrder,
    required this.isActive,
    this.description,
    this.icon,
  });

  final String subjectName;
  final String? description;
  final String? icon;
  final int displayOrder;
  final bool isActive;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'subject_name': subjectName,
        'description': description,
        'icon': icon,
        'display_order': displayOrder,
        'is_active': isActive,
      };
}

/// Body sent when toggling the active status only.
class ToggleSubjectActiveRequest {
  const ToggleSubjectActiveRequest({required this.isActive});

  final bool isActive;

  Map<String, dynamic> toJson() => <String, dynamic>{'is_active': isActive};
}
