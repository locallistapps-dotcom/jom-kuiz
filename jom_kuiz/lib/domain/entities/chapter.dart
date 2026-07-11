import 'package:equatable/equatable.dart';

/// Sort options available in the Chapter list screen.
enum ChapterSortOrder {
  /// Ascending by [Chapter.displayOrder] (lowest number first).
  displayOrderAsc,

  /// Alphabetical A → Z by [Chapter.chapterName].
  nameAsc,

  /// Newest first by [Chapter.createdAt].
  createdAtDesc,
}

/// A chapter within a specific [Subject] and [Year] combination.
///
/// Relationships:
/// • Many chapters → one Subject  (via [subjectId])
/// • Many chapters → one Year     (via [yearId])
/// • Every Chapter belongs to exactly one Subject and one Year.
///
/// This entity is the canonical bridge between the Subject and Year modules.
/// Querying `ChapterRepository.getChapters(subjectId: x, yearId: y)` is the
/// standard way to enumerate chapters for a given curriculum slot.
class Chapter extends Equatable {
  const Chapter({
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

  /// Primary key — UUID supplied by Supabase.
  final String chapterId;

  /// Foreign key → subjects.id
  final String subjectId;

  /// Foreign key → years.id
  final String yearId;

  /// Human-readable chapter title, e.g. "Chapter 1: Numbers".
  /// Must be unique within the same (subjectId, yearId) pair.
  final String chapterName;

  /// Optional longer description shown on the chapter detail screen.
  final String? description;

  /// Display order within the same (subjectId, yearId) slot. Lower = first.
  final int displayOrder;

  /// Whether this chapter is visible to children and teachers.
  final bool isActive;

  final DateTime createdAt;
  final DateTime updatedAt;

  /// Returns a copy of this chapter with the given fields replaced.
  Chapter copyWith({
    String? chapterId,
    String? subjectId,
    String? yearId,
    String? chapterName,
    String? description,
    int? displayOrder,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Chapter(
      chapterId: chapterId ?? this.chapterId,
      subjectId: subjectId ?? this.subjectId,
      yearId: yearId ?? this.yearId,
      chapterName: chapterName ?? this.chapterName,
      description: description ?? this.description,
      displayOrder: displayOrder ?? this.displayOrder,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => <Object?>[
        chapterId,
        subjectId,
        yearId,
        chapterName,
        description,
        displayOrder,
        isActive,
        createdAt,
        updatedAt,
      ];
}
