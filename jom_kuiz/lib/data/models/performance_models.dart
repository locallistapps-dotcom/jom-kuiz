import '../../domain/entities/performance_entities.dart';
import '../../domain/entities/question.dart';

// ── Raw result row (quiz_results joined with topic hierarchy) ─────────────────

/// Maps a single row from:
///
/// ```
/// GET /quiz_results
///   ?select=*,topics!inner(topic_id,topic_name,chapter_id,
///             chapters!inner(chapter_id,chapter_name,year_id,
///               years!inner(year_id,year_name,subject_id,
///                 subjects!inner(subject_id,subject_name))))
///   &child_id=eq.{childId}
///   &order=completed_at.desc
/// ```
class PerformanceRawResultModel {
  const PerformanceRawResultModel({
    required this.sessionId,
    required this.topicId,
    required this.topicName,
    required this.chapterId,
    required this.chapterName,
    required this.yearId,
    required this.yearName,
    required this.subjectId,
    required this.subjectName,
    required this.childId,
    required this.percentage,
    required this.correctCount,
    required this.wrongCount,
    required this.skippedCount,
    required this.totalQuestions,
    required this.timeTakenSeconds,
    required this.completedAt,
  });

  final String sessionId;
  final String topicId;
  final String topicName;
  final String chapterId;
  final String chapterName;
  final String yearId;
  final String yearName;
  final String subjectId;
  final String subjectName;
  final String childId;
  final double percentage;
  final int correctCount;
  final int wrongCount;
  final int skippedCount;
  final int totalQuestions;
  final int timeTakenSeconds;
  final DateTime completedAt;

  factory PerformanceRawResultModel.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> topic =
        json['topics'] as Map<String, dynamic>? ?? <String, dynamic>{};
    final Map<String, dynamic> chapter =
        topic['chapters'] as Map<String, dynamic>? ?? <String, dynamic>{};
    final Map<String, dynamic> year =
        chapter['years'] as Map<String, dynamic>? ?? <String, dynamic>{};
    final Map<String, dynamic> subject =
        year['subjects'] as Map<String, dynamic>? ?? <String, dynamic>{};

    return PerformanceRawResultModel(
      sessionId: json['session_id'] as String? ?? '',
      topicId: json['topic_id'] as String? ?? '',
      topicName: topic['topic_name'] as String? ?? 'Unknown Topic',
      chapterId:
          chapter['chapter_id'] as String? ?? topic['chapter_id'] as String? ?? '',
      chapterName: chapter['chapter_name'] as String? ?? 'Unknown Chapter',
      yearId: year['year_id'] as String? ?? chapter['year_id'] as String? ?? '',
      yearName: year['year_name'] as String? ?? 'Unknown Year',
      subjectId: subject['subject_id'] as String? ?? year['subject_id'] as String? ?? '',
      subjectName: subject['subject_name'] as String? ?? 'Unknown Subject',
      childId: json['child_id'] as String? ?? '',
      percentage: (json['percentage'] as num?)?.toDouble() ?? 0.0,
      correctCount: json['correct_count'] as int? ?? 0,
      wrongCount: json['wrong_count'] as int? ?? 0,
      skippedCount: json['skipped_count'] as int? ?? 0,
      totalQuestions: json['total_questions'] as int? ?? 0,
      timeTakenSeconds: json['time_taken_seconds'] as int? ?? 0,
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'] as String)
          : DateTime.now(),
    );
  }

  QuizHistoryItem toHistoryItem() => QuizHistoryItem(
        sessionId: sessionId,
        topicId: topicId,
        topicName: topicName,
        chapterName: chapterName,
        subjectName: subjectName,
        yearName: yearName,
        score: percentage,
        correctCount: correctCount,
        totalQuestions: totalQuestions,
        timeTakenSeconds: timeTakenSeconds,
        completedAt: completedAt,
      );
}

// ── Quiz answer row (quiz_answers joined with questions) ──────────────────────

/// Maps a row from:
///
/// ```
/// GET /quiz_answers
///   ?select=*,questions!inner(*)
///   &session_id=eq.{sessionId}
/// ```
class QuizAnswerReviewModel {
  const QuizAnswerReviewModel({
    required this.givenAnswer,
    required this.correctAnswer,
    required this.isCorrect,
    required this.question,
  });

  final String? givenAnswer;
  final String correctAnswer;
  final bool isCorrect;
  final Question question;

  factory QuizAnswerReviewModel.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> qJson =
        json['questions'] as Map<String, dynamic>? ?? <String, dynamic>{};

    return QuizAnswerReviewModel(
      givenAnswer: json['given_answer'] as String?,
      correctAnswer: json['correct_answer'] as String? ?? '',
      isCorrect: json['is_correct'] as bool? ?? false,
      question: _questionFromJson(qJson),
    );
  }

  QuizAnswerReview toDomain() => QuizAnswerReview(
        question: question,
        givenAnswer: givenAnswer,
        correctAnswer: correctAnswer,
        isCorrect: isCorrect,
      );

  static Question _questionFromJson(Map<String, dynamic> j) {
    final QuestionType type = _parseType(j['question_type'] as String? ?? 'mcq');
    final QuestionDifficulty diff =
        _parseDifficulty(j['difficulty'] as String? ?? 'medium');
    return Question(
      questionId: j['question_id'] as String? ?? '',
      topicId: j['topic_id'] as String? ?? '',
      questionText: j['question_text'] as String? ?? '',
      questionType: type,
      difficulty: diff,
      optionA: j['option_a'] as String?,
      optionB: j['option_b'] as String?,
      optionC: j['option_c'] as String?,
      optionD: j['option_d'] as String?,
      correctAnswer: j['correct_answer'] as String? ?? '',
      explanation: j['explanation'] as String?,
      explanationImageUrl: j['explanation_image_url'] as String?,
      isActive: j['is_active'] as bool? ?? true,
      createdAt: j['created_at'] != null
          ? DateTime.parse(j['created_at'] as String)
          : DateTime.now(),
      updatedAt: j['updated_at'] != null
          ? DateTime.parse(j['updated_at'] as String)
          : DateTime.now(),
    );
  }

  static QuestionType _parseType(String raw) {
    switch (raw) {
      case 'true_false':
        return QuestionType.trueFalse;
      case 'fill_in_the_blank':
        return QuestionType.fillInTheBlank;
      default:
        return QuestionType.mcq;
    }
  }

  static QuestionDifficulty _parseDifficulty(String raw) {
    switch (raw) {
      case 'easy':
        return QuestionDifficulty.easy;
      case 'hard':
        return QuestionDifficulty.hard;
      default:
        return QuestionDifficulty.medium;
    }
  }
}

// ── Child summary row (aggregate across quiz_results) ─────────────────────────

/// Minimal aggregate per child for the Parent View list.
///
/// This is computed client-side from multiple [PerformanceRawResultModel]
/// rows filtered by child_id.
class ChildSummaryRawModel {
  const ChildSummaryRawModel({
    required this.childId,
    required this.results,
  });

  final String childId;
  final List<PerformanceRawResultModel> results;

  ChildPerformanceOverview toOverview(String childName) {
    if (results.isEmpty) {
      return ChildPerformanceOverview(
        childId: childId,
        childName: childName,
        totalQuizzes: 0,
        averageScore: 0,
      );
    }

    final List<double> scores =
        results.map((PerformanceRawResultModel r) => r.percentage).toList();
    final double avg = scores.reduce((double a, double b) => a + b) / scores.length;
    final double latest = results.first.percentage; // already desc-ordered

    // Subject aggregates
    final Map<String, List<double>> bySubject = <String, List<double>>{};
    for (final PerformanceRawResultModel r in results) {
      bySubject
          .putIfAbsent(r.subjectName, () => <double>[])
          .add(r.percentage);
    }
    final Map<String, double> subjectAvg = bySubject.map(
      (String k, List<double> v) => MapEntry<String, double>(
          k, v.reduce((double a, double b) => a + b) / v.length),
    );
    final String? strongest = subjectAvg.isNotEmpty
        ? subjectAvg.entries
            .reduce(
                (MapEntry<String, double> a, MapEntry<String, double> b) =>
                    a.value >= b.value ? a : b)
            .key
        : null;
    final String? weakest = subjectAvg.isNotEmpty
        ? subjectAvg.entries
            .reduce(
                (MapEntry<String, double> a, MapEntry<String, double> b) =>
                    a.value <= b.value ? a : b)
            .key
        : null;

    return ChildPerformanceOverview(
      childId: childId,
      childName: childName,
      totalQuizzes: results.length,
      averageScore: avg,
      latestScore: latest,
      strongestSubject: strongest,
      weakestSubject: weakest,
    );
  }
}
