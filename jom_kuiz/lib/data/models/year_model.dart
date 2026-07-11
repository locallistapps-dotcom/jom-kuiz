import '../../domain/entities/year.dart';

/// Wire-format DTO for a Year row returned by the Supabase REST API.
///
/// Supabase (PostgREST) returns snake_case JSON keys. Hand-written
/// [fromJson]/[toJson] — no codegen required.
class YearModel {
  const YearModel({
    required this.yearId,
    required this.yearName,
    required this.displayOrder,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  final String yearId;
  final String yearName;
  final int displayOrder;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory YearModel.fromJson(Map<String, dynamic> json) {
    return YearModel(
      yearId: json['id'] as String,
      yearName: json['year_name'] as String,
      displayOrder: (json['display_order'] as num?)?.toInt() ?? 0,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': yearId,
        'year_name': yearName,
        'display_order': displayOrder,
        'is_active': isActive,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  Year toEntity() {
    return Year(
      yearId: yearId,
      yearName: yearName,
      displayOrder: displayOrder,
      isActive: isActive,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

// ── Request bodies ────────────────────────────────────────────────────────────

/// Body sent to Supabase when creating a new year (POST /years).
class CreateYearRequest {
  const CreateYearRequest({
    required this.yearName,
    this.displayOrder = 0,
  });

  final String yearName;
  final int displayOrder;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'year_name': yearName,
        'display_order': displayOrder,
        'is_active': true,
      };
}

/// Body sent to Supabase when updating a year (PATCH /years?id=eq.{id}).
class UpdateYearRequest {
  const UpdateYearRequest({
    required this.yearName,
    required this.displayOrder,
    required this.isActive,
  });

  final String yearName;
  final int displayOrder;
  final bool isActive;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'year_name': yearName,
        'display_order': displayOrder,
        'is_active': isActive,
      };
}

/// Body sent when toggling the active status only.
class ToggleYearActiveRequest {
  const ToggleYearActiveRequest({required this.isActive});

  final bool isActive;

  Map<String, dynamic> toJson() => <String, dynamic>{'is_active': isActive};
}
