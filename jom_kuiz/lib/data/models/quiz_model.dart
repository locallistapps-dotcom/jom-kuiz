import '../../domain/entities/quiz.dart';

/// Wire format for a quiz as returned by the Child API.
class QuizModel {
  const QuizModel({
    required this.quizId,
    required this.title,
    required this.subject,
    required this.questionCount,
    required this.durationMinutes,
    required this.difficulty,
    required this.createdAt,
    this.description,
  });

  final String quizId;
  final String title;
  final String? description;
  final String subject;
  final int questionCount;
  final int durationMinutes;
  final String difficulty;
  final DateTime createdAt;

  factory QuizModel.fromJson(Map<String, dynamic> json) {
    return QuizModel(
      quizId: json['quiz_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      subject: json['subject'] as String,
      questionCount: json['question_count'] as int,
      durationMinutes: json['duration_minutes'] as int,
      difficulty: json['difficulty'] as String? ?? 'medium',
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'quiz_id': quizId,
        'title': title,
        'description': description,
        'subject': subject,
        'question_count': questionCount,
        'duration_minutes': durationMinutes,
        'difficulty': difficulty,
        'created_at': createdAt.toIso8601String(),
      };

  Quiz toEntity() {
    return Quiz(
      quizId: quizId,
      title: title,
      description: description,
      subject: subject,
      questionCount: questionCount,
      durationMinutes: durationMinutes,
      difficulty: QuizDifficulty.values.firstWhere(
        (QuizDifficulty d) => d.name == difficulty,
        orElse: () => QuizDifficulty.medium,
      ),
      createdAt: createdAt,
    );
  }
}

/// Wire format for a completed quiz result.
class QuizResultModel {
  const QuizResultModel({
    required this.resultId,
    required this.quizId,
    required this.quizTitle,
    required this.childId,
    required this.score,
    required this.totalQuestions,
    required this.completedAt,
    required this.timeTakenSeconds,
  });

  final String resultId;
  final String quizId;
  final String quizTitle;
  final String childId;
  final int score;
  final int totalQuestions;
  final DateTime completedAt;
  final int timeTakenSeconds;

  factory QuizResultModel.fromJson(Map<String, dynamic> json) {
    return QuizResultModel(
      resultId: json['result_id'] as String,
      quizId: json['quiz_id'] as String,
      quizTitle: json['quiz_title'] as String,
      childId: json['child_id'] as String,
      score: json['score'] as int,
      totalQuestions: json['total_questions'] as int,
      completedAt: DateTime.parse(json['completed_at'] as String),
      timeTakenSeconds: json['time_taken_seconds'] as int,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'result_id': resultId,
        'quiz_id': quizId,
        'quiz_title': quizTitle,
        'child_id': childId,
        'score': score,
        'total_questions': totalQuestions,
        'completed_at': completedAt.toIso8601String(),
        'time_taken_seconds': timeTakenSeconds,
      };

  QuizResult toEntity() {
    return QuizResult(
      resultId: resultId,
      quizId: quizId,
      quizTitle: quizTitle,
      childId: childId,
      score: score,
      totalQuestions: totalQuestions,
      completedAt: completedAt,
      timeTakenSeconds: timeTakenSeconds,
    );
  }
}
