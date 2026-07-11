import '../../domain/entities/homework.dart';

/// Wire format for a homework assignment as returned by the Child API.
class HomeworkModel {
  const HomeworkModel({
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
  final String status;
  final DateTime? completedAt;
  final DateTime createdAt;

  factory HomeworkModel.fromJson(Map<String, dynamic> json) {
    return HomeworkModel(
      homeworkId: json['homework_id'] as String,
      childId: json['child_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      subject: json['subject'] as String,
      dueDate: DateTime.parse(json['due_date'] as String),
      status: json['status'] as String? ?? 'pending',
      completedAt: json['completed_at'] == null
          ? null
          : DateTime.parse(json['completed_at'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'homework_id': homeworkId,
        'child_id': childId,
        'title': title,
        'description': description,
        'subject': subject,
        'due_date': dueDate.toIso8601String(),
        'status': status,
        'completed_at': completedAt?.toIso8601String(),
        'created_at': createdAt.toIso8601String(),
      };

  Homework toEntity() {
    return Homework(
      homeworkId: homeworkId,
      childId: childId,
      title: title,
      description: description,
      subject: subject,
      dueDate: dueDate,
      status: HomeworkStatus.values.firstWhere(
        (HomeworkStatus s) => s.name == status,
        orElse: () => HomeworkStatus.pending,
      ),
      completedAt: completedAt,
      createdAt: createdAt,
    );
  }
}
