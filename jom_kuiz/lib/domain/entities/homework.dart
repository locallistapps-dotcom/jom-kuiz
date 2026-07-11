import 'package:equatable/equatable.dart';

/// Completion state of a homework assignment.
enum HomeworkStatus { pending, completed, overdue }

/// A single homework assignment assigned to a child.
class Homework extends Equatable {
  const Homework({
    required this.homeworkId,
    required this.childId,
    required this.title,
    required this.subject,
    required this.dueDate,
    required this.status,
    required this.createdAt,
    this.description,
    this.completedAt,
  });

  final String homeworkId;
  final String childId;
  final String title;
  final String? description;
  final String subject;
  final DateTime dueDate;
  final HomeworkStatus status;
  final DateTime? completedAt;
  final DateTime createdAt;

  bool get isCompleted => status == HomeworkStatus.completed;
  bool get isOverdue => status == HomeworkStatus.overdue;
  bool get isPending => status == HomeworkStatus.pending;

  @override
  List<Object?> get props => <Object?>[
        homeworkId,
        childId,
        title,
        description,
        subject,
        dueDate,
        status,
        completedAt,
        createdAt,
      ];
}
