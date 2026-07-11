import 'package:equatable/equatable.dart';

/// Sort options available in the Subject list screen.
enum SubjectSortOrder {
  /// Alphabetical A → Z by [Subject.subjectName].
  nameAsc,

  /// Newest first by [Subject.createdAt].
  createdAtDesc,
}

/// An academic subject managed through the Admin CMS (e.g. Mathematics, Science).
class Subject extends Equatable {
  const Subject({
    required this.subjectId,
    required this.subjectName,
    required this.displayOrder,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    this.description,
    this.icon,
  });

  /// Primary key — UUID supplied by Supabase.
  final String subjectId;

  /// Display name of the subject, must be unique.
  final String subjectName;

  /// Optional short description shown in list/detail views.
  final String? description;

  /// Optional icon identifier — emoji character or named icon key
  /// (e.g. `"📐"`, `"science"`). Rendered by the UI layer.
  final String? icon;

  /// Determines the display order when listing subjects. Lower = first.
  final int displayOrder;

  /// Whether this subject is currently visible to children and teachers.
  final bool isActive;

  final DateTime createdAt;
  final DateTime updatedAt;

  /// Returns a copy of this subject with the given fields replaced.
  Subject copyWith({
    String? subjectId,
    String? subjectName,
    String? description,
    String? icon,
    int? displayOrder,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Subject(
      subjectId: subjectId ?? this.subjectId,
      subjectName: subjectName ?? this.subjectName,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      displayOrder: displayOrder ?? this.displayOrder,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => <Object?>[
        subjectId,
        subjectName,
        description,
        icon,
        displayOrder,
        isActive,
        createdAt,
        updatedAt,
      ];
}
