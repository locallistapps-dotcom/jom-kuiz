import 'package:equatable/equatable.dart';

/// A chapter within a subject for a specific year level.
class Chapter extends Equatable {
  const Chapter({
    required this.chapterId,
    required this.subjectId,
    required this.yearId,
    required this.name,
    required this.order,
    this.description,
  });

  final String chapterId;
  final String subjectId;
  final String yearId;
  final String name;

  /// Display order within the subject-year combination.
  final int order;
  final String? description;

  @override
  List<Object?> get props => <Object?>[
        chapterId,
        subjectId,
        yearId,
        name,
        order,
        description,
      ];
}
