import 'package:equatable/equatable.dart';

/// Sort options available in the Topic list screen.
enum TopicSortOrder {
  /// Ascending by [Topic.displayOrder] (lowest number first).
  displayOrderAsc,

  /// Alphabetical A → Z by [Topic.topicName].
  nameAsc,

  /// Newest first by [Topic.createdAt].
  createdAtDesc,
}

/// A topic within a specific [Chapter].
///
/// Hierarchy:  Topic → Chapter → (Subject, Year)
///
/// A topic inherits its Subject and Year through its parent Chapter.
/// To find all topics for a given Subject+Year slot:
///   1. Query ChapterRepository.getChapters(subjectId: x, yearId: y)
///   2. For each chapter, query TopicRepository.getTopics(chapterId: c.chapterId)
///
/// Or filter server-side using the optional [subjectId] / [yearId] params on
/// [TopicRepository.getTopics] — the datasource joins through the chapters
/// table via PostgREST embedding.
class Topic extends Equatable {
  const Topic({
    required this.topicId,
    required this.chapterId,
    required this.topicName,
    required this.displayOrder,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    this.description,
  });

  /// Primary key — UUID supplied by Supabase.
  final String topicId;

  /// Foreign key → chapters.id
  final String chapterId;

  /// Human-readable topic title, e.g. "Fractions".
  /// Must be unique within the same chapter.
  final String topicName;

  /// Optional description shown on the topic detail screen.
  final String? description;

  /// Display order within the chapter. Lower = first.
  final int displayOrder;

  /// Whether this topic is visible to children and teachers.
  final bool isActive;

  final DateTime createdAt;
  final DateTime updatedAt;

  /// Returns a copy of this topic with the given fields replaced.
  Topic copyWith({
    String? topicId,
    String? chapterId,
    String? topicName,
    String? description,
    int? displayOrder,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Topic(
      topicId: topicId ?? this.topicId,
      chapterId: chapterId ?? this.chapterId,
      topicName: topicName ?? this.topicName,
      description: description ?? this.description,
      displayOrder: displayOrder ?? this.displayOrder,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => <Object?>[
        topicId,
        chapterId,
        topicName,
        description,
        displayOrder,
        isActive,
        createdAt,
        updatedAt,
      ];
}
