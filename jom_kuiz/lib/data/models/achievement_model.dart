import '../../domain/entities/achievement.dart';
import 'quiz_model.dart';

/// Wire format for a badge.
class BadgeModel {
  const BadgeModel({
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

  factory BadgeModel.fromJson(Map<String, dynamic> json) {
    return BadgeModel(
      badgeId: json['badge_id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      isEarned: json['is_earned'] as bool? ?? false,
      iconUrl: json['icon_url'] as String?,
      earnedAt: json['earned_at'] == null
          ? null
          : DateTime.parse(json['earned_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'badge_id': badgeId,
        'name': name,
        'description': description,
        'is_earned': isEarned,
        'icon_url': iconUrl,
        'earned_at': earnedAt?.toIso8601String(),
      };

  Badge toEntity() {
    return Badge(
      badgeId: badgeId,
      name: name,
      description: description,
      isEarned: isEarned,
      iconUrl: iconUrl,
      earnedAt: earnedAt,
    );
  }
}

/// Wire format for the aggregated achievement summary.
class AchievementModel {
  const AchievementModel({
    required this.childId,
    required this.totalPoints,
    required this.ranking,
    required this.stars,
    required this.badges,
    required this.recentResults,
  });

  final String childId;
  final int totalPoints;
  final int ranking;
  final int stars;
  final List<BadgeModel> badges;
  final List<QuizResultModel> recentResults;

  factory AchievementModel.fromJson(Map<String, dynamic> json) {
    final List<dynamic> badgesRaw =
        json['badges'] as List<dynamic>? ?? <dynamic>[];
    final List<dynamic> resultsRaw =
        json['recent_results'] as List<dynamic>? ?? <dynamic>[];
    return AchievementModel(
      childId: json['child_id'] as String,
      totalPoints: json['total_points'] as int? ?? 0,
      ranking: json['ranking'] as int? ?? 0,
      stars: json['stars'] as int? ?? 0,
      badges: badgesRaw
          .map((dynamic e) =>
              BadgeModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      recentResults: resultsRaw
          .map((dynamic e) =>
              QuizResultModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'child_id': childId,
        'total_points': totalPoints,
        'ranking': ranking,
        'stars': stars,
        'badges': badges.map((BadgeModel b) => b.toJson()).toList(),
        'recent_results':
            recentResults.map((QuizResultModel r) => r.toJson()).toList(),
      };

  Achievement toEntity() {
    return Achievement(
      childId: childId,
      totalPoints: totalPoints,
      ranking: ranking,
      stars: stars,
      badges: badges.map((BadgeModel b) => b.toEntity()).toList(),
      recentResults:
          recentResults.map((QuizResultModel r) => r.toEntity()).toList(),
    );
  }
}
