import 'package:equatable/equatable.dart';

import 'question.dart';

// ── Analytics result types ────────────────────────────────────────────────────

/// Full computed analytics for one child, derived from a single Supabase
/// query against `quiz_results` (joined with the topic hierarchy).
///
/// All screens in the Performance module are driven by this object.
/// Sub-views (subjects, chapters, topics, history) are pre-computed fields
/// so that UI drill-downs never trigger additional network calls.
class PerformanceData extends Equatable {
  const PerformanceData({
    required this.childId,
    required this.totalQuizzes,
    required this.averageScore,
    required this.highestScore,
    required this.lowestScore,
    required this.totalQuestionsAnswered,
    required this.totalCorrect,
    required this.totalWrong,
    required this.totalStudyTimeSeconds,
    required this.subjects,
    required this.topics,
    required this.history,
    required this.revisionSuggestions,
    required this.weeklyProgress,
    required this.monthlyProgress,
  });

  final String childId;

  // ── Overview stats ─────────────────────────────────────────────────────────
  final int totalQuizzes;
  final double averageScore;
  final double highestScore;
  final double lowestScore;
  final int totalQuestionsAnswered;
  final int totalCorrect;
  final int totalWrong;
  final int totalStudyTimeSeconds;

  // ── Sub-breakdowns ─────────────────────────────────────────────────────────
  final List<SubjectPerformance> subjects;
  final List<TopicPerformance> topics;
  final List<QuizHistoryItem> history;
  final List<RevisionSuggestion> revisionSuggestions;

  // ── Trend data ─────────────────────────────────────────────────────────────

  /// Last 7 calendar days average score (index 0 = oldest; 0.0 if no data).
  final List<double> weeklyProgress;

  /// Last 4 weeks average score (index 0 = oldest; 0.0 if no data).
  final List<double> monthlyProgress;

  // ── Convenience getters ────────────────────────────────────────────────────

  bool get isEmpty => totalQuizzes == 0;

  List<SubjectPerformance> get strongSubjects =>
      subjects.where((SubjectPerformance s) => s.averageScore >= 80).toList();

  List<SubjectPerformance> get weakSubjects =>
      subjects.where((SubjectPerformance s) => s.averageScore < 60).toList();

  /// Returns an empty placeholder (no quizzes taken yet).
  factory PerformanceData.empty(String childId) => PerformanceData(
        childId: childId,
        totalQuizzes: 0,
        averageScore: 0,
        highestScore: 0,
        lowestScore: 0,
        totalQuestionsAnswered: 0,
        totalCorrect: 0,
        totalWrong: 0,
        totalStudyTimeSeconds: 0,
        subjects: const <SubjectPerformance>[],
        topics: const <TopicPerformance>[],
        history: const <QuizHistoryItem>[],
        revisionSuggestions: const <RevisionSuggestion>[],
        weeklyProgress: List<double>.filled(7, 0),
        monthlyProgress: List<double>.filled(4, 0),
      );

  @override
  List<Object?> get props => <Object?>[
        childId,
        totalQuizzes,
        averageScore,
        highestScore,
        lowestScore,
        totalQuestionsAnswered,
        totalCorrect,
        totalWrong,
        totalStudyTimeSeconds,
        subjects,
        topics,
        history,
        revisionSuggestions,
        weeklyProgress,
        monthlyProgress,
      ];
}

// ── Per-subject breakdown ─────────────────────────────────────────────────────

class SubjectPerformance extends Equatable {
  const SubjectPerformance({
    required this.subjectId,
    required this.subjectName,
    required this.averageScore,
    required this.totalQuizzes,
    required this.chapters,
  });

  final String subjectId;
  final String subjectName;
  final double averageScore;
  final int totalQuizzes;
  final List<ChapterPerformance> chapters;

  /// Progress percentage = average score (0–100).
  double get progressPercent => averageScore;

  bool get isStrong => averageScore >= 80;
  bool get isWeak => averageScore < 60;

  @override
  List<Object?> get props =>
      <Object?>[subjectId, subjectName, averageScore, totalQuizzes, chapters];
}

// ── Per-chapter breakdown ─────────────────────────────────────────────────────

class ChapterPerformance extends Equatable {
  const ChapterPerformance({
    required this.chapterId,
    required this.chapterName,
    required this.subjectId,
    required this.subjectName,
    required this.averageScore,
    required this.totalQuizzes,
  });

  final String chapterId;
  final String chapterName;
  final String subjectId;
  final String subjectName;
  final double averageScore;
  final int totalQuizzes;

  bool get isStrong => averageScore >= 80;
  bool get isWeak => averageScore < 60;

  @override
  List<Object?> get props => <Object?>[
        chapterId,
        chapterName,
        subjectId,
        subjectName,
        averageScore,
        totalQuizzes,
      ];
}

// ── Per-topic breakdown ───────────────────────────────────────────────────────

class TopicPerformance extends Equatable {
  const TopicPerformance({
    required this.topicId,
    required this.topicName,
    required this.subjectId,
    required this.subjectName,
    required this.chapterId,
    required this.chapterName,
    required this.yearName,
    required this.averageScore,
    required this.attempts,
    required this.bestScore,
    this.lastAttempt,
  });

  final String topicId;
  final String topicName;
  final String subjectId;
  final String subjectName;
  final String chapterId;
  final String chapterName;
  final String yearName;
  final double averageScore;
  final int attempts;
  final double bestScore;
  final DateTime? lastAttempt;

  /// Recommendation text derived from [averageScore].
  String get recommendation {
    if (averageScore < 50) return 'Needs Immediate Revision';
    if (averageScore < 70) return 'Practice More';
    if (averageScore < 85) return 'Good Progress';
    return 'Excellent';
  }

  @override
  List<Object?> get props => <Object?>[
        topicId,
        topicName,
        subjectId,
        subjectName,
        chapterId,
        chapterName,
        yearName,
        averageScore,
        attempts,
        bestScore,
        lastAttempt,
      ];
}

// ── Quiz history entry ────────────────────────────────────────────────────────

class QuizHistoryItem extends Equatable {
  const QuizHistoryItem({
    required this.sessionId,
    required this.topicId,
    required this.topicName,
    required this.chapterName,
    required this.subjectName,
    required this.yearName,
    required this.score,
    required this.correctCount,
    required this.totalQuestions,
    required this.timeTakenSeconds,
    required this.completedAt,
  });

  final String sessionId;
  final String topicId;
  final String topicName;
  final String chapterName;
  final String subjectName;
  final String yearName;
  final double score;
  final int correctCount;
  final int totalQuestions;
  final int timeTakenSeconds;
  final DateTime completedAt;

  /// Formatted time taken as "Xm Ys".
  String get timeTakenFormatted {
    final int m = timeTakenSeconds ~/ 60;
    final int s = timeTakenSeconds % 60;
    if (m == 0) return '${s}s';
    return '${m}m ${s}s';
  }

  @override
  List<Object?> get props => <Object?>[
        sessionId,
        topicId,
        topicName,
        chapterName,
        subjectName,
        yearName,
        score,
        correctCount,
        totalQuestions,
        timeTakenSeconds,
        completedAt,
      ];
}

// ── Per-child overview (parent view) ─────────────────────────────────────────

class ChildPerformanceOverview extends Equatable {
  const ChildPerformanceOverview({
    required this.childId,
    required this.childName,
    required this.totalQuizzes,
    required this.averageScore,
    this.latestScore,
    this.strongestSubject,
    this.weakestSubject,
  });

  final String childId;
  final String childName;
  final int totalQuizzes;
  final double averageScore;
  final double? latestScore;
  final String? strongestSubject;
  final String? weakestSubject;

  @override
  List<Object?> get props => <Object?>[
        childId,
        childName,
        totalQuizzes,
        averageScore,
        latestScore,
        strongestSubject,
        weakestSubject,
      ];
}

// ── Revision suggestion ───────────────────────────────────────────────────────

class RevisionSuggestion extends Equatable {
  const RevisionSuggestion({
    required this.subjectName,
    required this.weakTopics,
  });

  final String subjectName;
  final List<String> weakTopics;

  @override
  List<Object?> get props => <Object?>[subjectName, weakTopics];
}

// ── Quiz answer review (session history) ─────────────────────────────────────

/// An answer entry loaded for history review.
///
/// Re-uses the [Question] entity so [QuizReviewScreen] can be re-used
/// without modification.
class QuizAnswerReview extends Equatable {
  const QuizAnswerReview({
    required this.question,
    required this.givenAnswer,
    required this.correctAnswer,
    required this.isCorrect,
  });

  final Question question;
  final String? givenAnswer;
  final String correctAnswer;
  final bool isCorrect;

  @override
  List<Object?> get props =>
      <Object?>[question, givenAnswer, correctAnswer, isCorrect];
}

// ── Active filter state ───────────────────────────────────────────────────────

class PerformanceFilter extends Equatable {
  const PerformanceFilter({
    this.subjectId,
    this.yearId,
    this.chapterId,
    this.topicId,
    this.dateFrom,
    this.dateTo,
  });

  final String? subjectId;
  final String? yearId;
  final String? chapterId;
  final String? topicId;
  final DateTime? dateFrom;
  final DateTime? dateTo;

  bool get hasAnyFilter =>
      subjectId != null ||
      yearId != null ||
      chapterId != null ||
      topicId != null ||
      dateFrom != null ||
      dateTo != null;

  PerformanceFilter copyWith({
    String? subjectId,
    String? yearId,
    String? chapterId,
    String? topicId,
    DateTime? dateFrom,
    DateTime? dateTo,
    bool clearSubjectId = false,
    bool clearYearId = false,
    bool clearChapterId = false,
    bool clearTopicId = false,
    bool clearDateRange = false,
  }) =>
      PerformanceFilter(
        subjectId:
            clearSubjectId ? null : subjectId ?? this.subjectId,
        yearId: clearYearId ? null : yearId ?? this.yearId,
        chapterId:
            clearChapterId ? null : chapterId ?? this.chapterId,
        topicId: clearTopicId ? null : topicId ?? this.topicId,
        dateFrom: clearDateRange ? null : dateFrom ?? this.dateFrom,
        dateTo: clearDateRange ? null : dateTo ?? this.dateTo,
      );

  @override
  List<Object?> get props =>
      <Object?>[subjectId, yearId, chapterId, topicId, dateFrom, dateTo];
}
