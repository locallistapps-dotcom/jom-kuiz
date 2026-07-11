import 'package:equatable/equatable.dart';

import 'quiz.dart';

/// A badge that a child can earn by completing milestones.
class Badge extends Equatable {
  const Badge({
    required this.badgeId,
    required this.name,
    required this.description,
    required this.isEarned,
    this.iconUrl,
    this.earnedAt,
  });

  final String badgeId;
  final String name;
  final String description;
  final bool isEarned;
  final String? iconUrl;
  final DateTime? earnedAt;

  @override
  List<Object?> get props => <Object?>[
        badgeId,
        name,
        description,
        isEarned,
        iconUrl,
        earnedAt,
      ];
}

/// Aggregated achievement summary for a child.
class Achievement extends Equatable {
  const Achievement({
    required this.childId,
    required this.totalPoints,
    required this.ranking,
    required this.stars,
    required this.badges,
    required this.recentResults,
  });

  final String childId;
  final int totalPoints;

  /// Global ranking position (1 = top).
  final int ranking;

  /// Star count earned from quiz performance.
  final int stars;
  final List<Badge> badges;
  final List<QuizResult> recentResults;

  int get earnedBadgeCount => badges.where((Badge b) => b.isEarned).length;

  @override
  List<Object?> get props => <Object?>[
        childId,
        totalPoints,
        ranking,
        stars,
        badges,
        recentResults,
      ];
}
