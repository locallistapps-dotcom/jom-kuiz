import 'dart:math' as math;

import '../models/performance_models.dart';
import '../../domain/entities/performance_entities.dart';
import '../../domain/entities/performance_summary.dart';

/// Computes all Performance Summary analytics from a flat list of raw result
/// rows fetched from Supabase.
///
/// No I/O is performed here — all computation is pure Dart.
/// This keeps the data layer thin and the analytics logic unit-testable.
class PerformanceAnalyticsService {
  const PerformanceAnalyticsService();

  /// Compute the full [PerformanceData] from [raw] quiz_results rows.
  ///
  /// If [filter] is supplied the history / topic / chapter / subject lists are
  /// trimmed to the matching subset, but the top-level summary stats always
  /// reflect the complete history.
  PerformanceData compute({
    required String childId,
    required List<PerformanceRawResultModel> raw,
    PerformanceFilter? filter,
  }) {
    if (raw.isEmpty) return PerformanceData.empty(childId);

    // ── Top-level summary ──────────────────────────────────────────────────
    final List<double> scores =
        raw.map((PerformanceRawResultModel r) => r.percentage).toList();
    final double avg =
        scores.reduce((double a, double b) => a + b) / scores.length;
    final double highest = scores.reduce(math.max);
    final double lowest = scores.reduce(math.min);
    final int totalQs = raw.fold(
        0, (int acc, PerformanceRawResultModel r) => acc + r.totalQuestions);
    final int correct = raw.fold(
        0, (int acc, PerformanceRawResultModel r) => acc + r.correctCount);
    final int wrong =
        raw.fold(0, (int acc, PerformanceRawResultModel r) => acc + r.wrongCount);
    final int totalTime = raw.fold(
        0, (int acc, PerformanceRawResultModel r) => acc + r.timeTakenSeconds);

    // ── Apply filter to sub-views ──────────────────────────────────────────
    final List<PerformanceRawResultModel> filtered =
        _applyFilter(raw, filter);

    // ── Subject breakdown ──────────────────────────────────────────────────
    final List<SubjectPerformance> subjects =
        _buildSubjectPerformance(filtered);

    // ── Topic breakdown ────────────────────────────────────────────────────
    final List<TopicPerformance> topics = _buildTopicPerformance(filtered);

    // ── History items (most recent first) ─────────────────────────────────
    final List<QuizHistoryItem> history = filtered
        .map((PerformanceRawResultModel r) => r.toHistoryItem())
        .toList();

    // ── Revision suggestions ───────────────────────────────────────────────
    final List<RevisionSuggestion> suggestions =
        _buildRevisionSuggestions(topics);

    // ── Weekly progress (last 7 calendar days) ─────────────────────────────
    final List<double> weekly = _weeklyProgress(raw);

    // ── Monthly progress (last 4 weeks) ───────────────────────────────────
    final List<double> monthly = _monthlyProgress(raw);

    return PerformanceData(
      childId: childId,
      totalQuizzes: raw.length,
      averageScore: avg,
      highestScore: highest,
      lowestScore: lowest,
      totalQuestionsAnswered: totalQs,
      totalCorrect: correct,
      totalWrong: wrong,
      totalStudyTimeSeconds: totalTime,
      subjects: subjects,
      topics: topics,
      history: history,
      revisionSuggestions: suggestions,
      weeklyProgress: weekly,
      monthlyProgress: monthly,
    );
  }

  /// Derive a lightweight [PerformanceSummary] from [raw] for backward compat.
  PerformanceSummary computeSummary({
    required String childId,
    required List<PerformanceRawResultModel> raw,
  }) {
    if (raw.isEmpty) {
      return PerformanceSummary(
        childId: childId,
        totalQuizzesTaken: 0,
        averageScorePercent: 0,
        totalPointsEarned: 0,
      );
    }
    final List<double> scores =
        raw.map((PerformanceRawResultModel r) => r.percentage).toList();
    final double avg =
        scores.reduce((double a, double b) => a + b) / scores.length;
    final int points = raw.fold(
        0, (int acc, PerformanceRawResultModel r) => acc + r.correctCount);

    final List<SubjectPerformance> subjects =
        _buildSubjectPerformance(raw);
    final List<String> strong = subjects
        .where((SubjectPerformance s) => s.averageScore >= 80)
        .map((SubjectPerformance s) => s.subjectName)
        .toList();
    final List<String> weak = subjects
        .where((SubjectPerformance s) => s.averageScore < 60)
        .map((SubjectPerformance s) => s.subjectName)
        .toList();

    return PerformanceSummary(
      childId: childId,
      totalQuizzesTaken: raw.length,
      averageScorePercent: avg,
      totalPointsEarned: points,
      strongSubjects: strong,
      weakSubjects: weak,
      weeklyProgress: _weeklyProgress(raw),
    );
  }

  // ── Private helpers ────────────────────────────────────────────────────────

  List<PerformanceRawResultModel> _applyFilter(
    List<PerformanceRawResultModel> raw,
    PerformanceFilter? filter,
  ) {
    if (filter == null || !filter.hasAnyFilter) return raw;

    return raw.where((PerformanceRawResultModel r) {
      if (filter.subjectId != null && r.subjectId != filter.subjectId) {
        return false;
      }
      if (filter.yearId != null && r.yearId != filter.yearId) {
        return false;
      }
      if (filter.chapterId != null && r.chapterId != filter.chapterId) {
        return false;
      }
      if (filter.topicId != null && r.topicId != filter.topicId) {
        return false;
      }
      if (filter.dateFrom != null &&
          r.completedAt.isBefore(filter.dateFrom!)) {
        return false;
      }
      if (filter.dateTo != null &&
          r.completedAt.isAfter(filter.dateTo!)) {
        return false;
      }
      return true;
    }).toList();
  }

  List<SubjectPerformance> _buildSubjectPerformance(
      List<PerformanceRawResultModel> raw) {
    final Map<String, List<PerformanceRawResultModel>> bySubject =
        <String, List<PerformanceRawResultModel>>{};
    for (final PerformanceRawResultModel r in raw) {
      bySubject.putIfAbsent(r.subjectId, () => <PerformanceRawResultModel>[]).add(r);
    }

    return bySubject.entries.map((MapEntry<String, List<PerformanceRawResultModel>> e) {
      final List<PerformanceRawResultModel> rows = e.value;
      final double avg = rows
              .map((PerformanceRawResultModel r) => r.percentage)
              .reduce((double a, double b) => a + b) /
          rows.length;

      final List<ChapterPerformance> chapters =
          _buildChapterPerformance(rows);

      return SubjectPerformance(
        subjectId: e.key,
        subjectName: rows.first.subjectName,
        averageScore: avg,
        totalQuizzes: rows.length,
        chapters: chapters,
      );
    }).toList()
      ..sort((SubjectPerformance a, SubjectPerformance b) =>
          b.averageScore.compareTo(a.averageScore));
  }

  List<ChapterPerformance> _buildChapterPerformance(
      List<PerformanceRawResultModel> raw) {
    final Map<String, List<PerformanceRawResultModel>> byChapter =
        <String, List<PerformanceRawResultModel>>{};
    for (final PerformanceRawResultModel r in raw) {
      byChapter.putIfAbsent(r.chapterId, () => <PerformanceRawResultModel>[]).add(r);
    }

    return byChapter.entries
        .map((MapEntry<String, List<PerformanceRawResultModel>> e) {
      final List<PerformanceRawResultModel> rows = e.value;
      final double avg = rows
              .map((PerformanceRawResultModel r) => r.percentage)
              .reduce((double a, double b) => a + b) /
          rows.length;
      return ChapterPerformance(
        chapterId: e.key,
        chapterName: rows.first.chapterName,
        subjectId: rows.first.subjectId,
        subjectName: rows.first.subjectName,
        averageScore: avg,
        totalQuizzes: rows.length,
      );
    }).toList()
          ..sort((ChapterPerformance a, ChapterPerformance b) =>
              a.chapterName.compareTo(b.chapterName));
  }

  List<TopicPerformance> _buildTopicPerformance(
      List<PerformanceRawResultModel> raw) {
    final Map<String, List<PerformanceRawResultModel>> byTopic =
        <String, List<PerformanceRawResultModel>>{};
    for (final PerformanceRawResultModel r in raw) {
      byTopic.putIfAbsent(r.topicId, () => <PerformanceRawResultModel>[]).add(r);
    }

    return byTopic.entries
        .map((MapEntry<String, List<PerformanceRawResultModel>> e) {
      final List<PerformanceRawResultModel> rows = e.value;
      final List<double> scores =
          rows.map((PerformanceRawResultModel r) => r.percentage).toList();
      final double avg =
          scores.reduce((double a, double b) => a + b) / scores.length;
      final double best = scores.reduce(math.max);
      rows.sort((PerformanceRawResultModel a, PerformanceRawResultModel b) =>
          b.completedAt.compareTo(a.completedAt));
      return TopicPerformance(
        topicId: e.key,
        topicName: rows.first.topicName,
        subjectId: rows.first.subjectId,
        subjectName: rows.first.subjectName,
        chapterId: rows.first.chapterId,
        chapterName: rows.first.chapterName,
        yearName: rows.first.yearName,
        averageScore: avg,
        attempts: rows.length,
        bestScore: best,
        lastAttempt: rows.first.completedAt,
      );
    }).toList()
          ..sort((TopicPerformance a, TopicPerformance b) =>
              a.topicName.compareTo(b.topicName));
  }

  List<RevisionSuggestion> _buildRevisionSuggestions(
      List<TopicPerformance> topics) {
    // Weak topics = average < 70%
    final List<TopicPerformance> weak =
        topics.where((TopicPerformance t) => t.averageScore < 70).toList();
    if (weak.isEmpty) return <RevisionSuggestion>[];

    final Map<String, List<String>> bySubject = <String, List<String>>{};
    for (final TopicPerformance t in weak) {
      bySubject
          .putIfAbsent(t.subjectName, () => <String>[])
          .add(t.topicName);
    }
    return bySubject.entries
        .map((MapEntry<String, List<String>> e) => RevisionSuggestion(
              subjectName: e.key,
              weakTopics: e.value,
            ))
        .toList()
      ..sort((RevisionSuggestion a, RevisionSuggestion b) =>
          a.subjectName.compareTo(b.subjectName));
  }

  List<double> _weeklyProgress(List<PerformanceRawResultModel> raw) {
    final DateTime now = DateTime.now().toUtc();
    final List<double> result = List<double>.filled(7, 0);
    for (int i = 0; i < 7; i++) {
      final DateTime day =
          DateTime(now.year, now.month, now.day - (6 - i)).toUtc();
      final DateTime nextDay = day.add(const Duration(days: 1));
      final List<PerformanceRawResultModel> dayRows = raw
          .where((PerformanceRawResultModel r) =>
              !r.completedAt.isBefore(day) && r.completedAt.isBefore(nextDay))
          .toList();
      if (dayRows.isNotEmpty) {
        result[i] = dayRows
                .map((PerformanceRawResultModel r) => r.percentage)
                .reduce((double a, double b) => a + b) /
            dayRows.length;
      }
    }
    return result;
  }

  List<double> _monthlyProgress(List<PerformanceRawResultModel> raw) {
    final DateTime now = DateTime.now().toUtc();
    final List<double> result = List<double>.filled(4, 0);
    for (int w = 0; w < 4; w++) {
      final DateTime weekStart = now.subtract(Duration(days: (3 - w) * 7 + 7));
      final DateTime weekEnd = now.subtract(Duration(days: (3 - w) * 7));
      final List<PerformanceRawResultModel> weekRows = raw
          .where((PerformanceRawResultModel r) =>
              r.completedAt.isAfter(weekStart) &&
              !r.completedAt.isAfter(weekEnd))
          .toList();
      if (weekRows.isNotEmpty) {
        result[w] = weekRows
                .map((PerformanceRawResultModel r) => r.percentage)
                .reduce((double a, double b) => a + b) /
            weekRows.length;
      }
    }
    return result;
  }
}
