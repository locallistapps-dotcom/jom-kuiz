// Flutter's material.dart exports a Badge widget (notification dot); hide it
// so our domain entity [Badge] from achievement.dart is unambiguous.
import 'package:flutter/material.dart' hide Badge;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/achievement.dart';
import '../../../domain/entities/quiz.dart';
import '../../controllers/achievement_controller.dart';
import '../../widgets/feedback/app_error_widget.dart';
import '../../widgets/feedback/empty_widget.dart';
import '../../widgets/feedback/loading_widget.dart';

/// Displays the child's total points, ranking, stars, earned badges, and
/// recent quiz result history.
class AchievementScreen extends ConsumerWidget {
  const AchievementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<Achievement?> state =
        ref.watch(achievementControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Achievements')),
      body: state.when(
        loading: () =>
            const LoadingWidget(message: 'Loading achievements...'),
        error: (Object error, _) => AppErrorWidget(
          message: error.toString(),
          onRetry: () =>
              ref.read(achievementControllerProvider.notifier).refresh(),
        ),
        data: (Achievement? achievement) {
          if (achievement == null) {
            return const EmptyWidget(
                message: 'No achievement data available');
          }
          return RefreshIndicator(
            onRefresh: () =>
                ref.read(achievementControllerProvider.notifier).refresh(),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: <Widget>[
                _SummaryRow(achievement: achievement),
                const SizedBox(height: 16),
                _BadgeSection(badges: achievement.badges),
                const SizedBox(height: 16),
                _RecentResultsSection(results: achievement.recentResults),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({super.key, required this.achievement});
  final Achievement achievement;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: _StatCard(
            icon: Icons.star,
            iconColor: Colors.amber,
            label: 'Stars',
            value: '${achievement.stars}',
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatCard(
            icon: Icons.bolt,
            iconColor: Theme.of(context).colorScheme.primary,
            label: 'Points',
            value: '${achievement.totalPoints}',
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatCard(
            icon: Icons.leaderboard_outlined,
            iconColor: Colors.orange,
            label: 'Rank',
            value: '#${achievement.ranking}',
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        child: Column(
          children: <Widget>[
            Icon(icon, color: iconColor, size: 28),
            const SizedBox(height: 4),
            Text(value, style: Theme.of(context).textTheme.titleLarge),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BadgeSection extends StatelessWidget {
  const _BadgeSection({super.key, required this.badges});
  final List<Badge> badges;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text('Badges', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        if (badges.isEmpty)
          const EmptyWidget(message: 'No badges yet — keep going!')
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 0.85,
            ),
            itemCount: badges.length,
            itemBuilder: (_, int index) =>
                _BadgeTile(badge: badges[index]),
          ),
      ],
    );
  }
}

class _BadgeTile extends StatelessWidget {
  const _BadgeTile({super.key, required this.badge});
  final Badge badge;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: badge.isEarned
          ? Theme.of(context).colorScheme.primaryContainer
          : Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(
              Icons.military_tech,
              size: 32,
              color: badge.isEarned
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 4),
            Text(
              badge.name,
              style: Theme.of(context).textTheme.labelSmall,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (!badge.isEarned)
              Text(
                'Locked',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                    ),
              ),
          ],
        ),
      ),
    );
  }
}

class _RecentResultsSection extends StatelessWidget {
  const _RecentResultsSection({super.key, required this.results});
  final List<QuizResult> results;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text('Score History',
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        if (results.isEmpty)
          const EmptyWidget(message: 'No quiz attempts yet')
        else
          ...results.map((QuizResult r) => _ResultTile(result: r)),
      ],
    );
  }
}

class _ResultTile extends StatelessWidget {
  const _ResultTile({super.key, required this.result});
  final QuizResult result;

  @override
  Widget build(BuildContext context) {
    final double pct = result.percentage;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Expanded(
                  child: Text(
                    result.quizTitle,
                    style: Theme.of(context).textTheme.titleSmall,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  '${result.score}/${result.totalQuestions}',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: result.isPassed
                            ? Colors.green
                            : Theme.of(context).colorScheme.error,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            LinearProgressIndicator(
              value: pct,
              backgroundColor:
                  Theme.of(context).colorScheme.surfaceContainerHighest,
              color: result.isPassed
                  ? Colors.green
                  : Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 4),
            Text(
              '${(pct * 100).toStringAsFixed(0)}% · '
              '${result.isPassed ? 'Passed' : 'Failed'}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
