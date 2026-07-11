import 'package:equatable/equatable.dart';

/// Aggregated performance metrics for a child across all quizzes.
class PerformanceSummary extends Equatable {
  const PerformanceSummary({
    required this.childId,
    required this.totalQuizzesTaken,
    required this.averageScorePercent,
    required this.totalPointsEarned,
    this.strongSubjects = const <String>[],
    this.weakSubjects = const <String>[],
    this.weeklyProgress = const <double>[],
  });

  final String childId;
  final int totalQuizzesTaken;

  /// Average score expressed as a value from 0.0 to 100.0.
  final double averageScorePercent;
  final int totalPointsEarned;

  /// Subject names where the child scores ≥ 80 %.
  final List<String> strongSubjects;

  /// Subject names where the child scores < 60 %.
  final List<String> weakSubjects;

  /// Last-7-days average scores (index 0 = oldest), for a trend sparkline.
  final List<double> weeklyProgress;

  @override
  List<Object?> get props => <Object?>[
        childId,
        totalQuizzesTaken,
        averageScorePercent,
        totalPointsEarned,
        strongSubjects,
        weakSubjects,
        weeklyProgress,
      ];
}
