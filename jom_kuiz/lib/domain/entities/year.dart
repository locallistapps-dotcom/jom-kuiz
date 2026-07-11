import 'package:equatable/equatable.dart';

/// Sort options available in the Year list screen.
enum YearSortOrder {
  /// Alphabetical A → Z by [Year.yearName].
  nameAsc,

  /// Ascending by [Year.displayOrder] (lowest number first).
  displayOrderAsc,

  /// Newest first by [Year.createdAt].
  createdAtDesc,
}

/// An academic year / grade level (e.g. Year 1, Year 2 … Year 6).
///
/// Years are linked to [Subject]s indirectly through [Chapter], which holds
/// both `subjectId` and `yearId`. When the Chapter module is implemented,
/// querying `ChapterRepository.getChapters(subjectId: x, yearId: y)` is the
/// canonical way to resolve Subject ↔ Year relationships.
class Year extends Equatable {
  const Year({
    required this.yearId,
    required this.yearName,
    required this.displayOrder,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Primary key — UUID supplied by Supabase.
  final String yearId;

  /// Display name of the year level, e.g. "Year 1".
  /// Must be unique within the system.
  final String yearName;

  /// Determines the display order when listing years. Lower = first.
  final int displayOrder;

  /// Whether this year level is currently available to users.
  final bool isActive;

  final DateTime createdAt;
  final DateTime updatedAt;

  /// Returns a copy of this year with the given fields replaced.
  Year copyWith({
    String? yearId,
    String? yearName,
    int? displayOrder,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Year(
      yearId: yearId ?? this.yearId,
      yearName: yearName ?? this.yearName,
      displayOrder: displayOrder ?? this.displayOrder,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => <Object?>[
        yearId,
        yearName,
        displayOrder,
        isActive,
        createdAt,
        updatedAt,
      ];
}
