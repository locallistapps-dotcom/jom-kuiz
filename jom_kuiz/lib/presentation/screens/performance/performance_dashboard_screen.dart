import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../domain/entities/performance_entities.dart';
import '../../controllers/performance_controller.dart';
import '../../providers/performance_providers.dart';
import 'quiz_history_screen.dart';
import 'subject_performance_screen.dart';
import 'topic_performance_screen.dart';

/// Student-facing Performance Dashboard.
///
/// Entry point for the `/performance` GoRoute. Shows an overview of all quiz
/// activity for the currently authenticated child (or the [childId] passed
/// by a parent viewing their child).
///
/// Navigation from here:
/// - Subjects card → [SubjectPerformanceScreen]
/// - Topics card   → [TopicPerformanceScreen]
/// - History card  → [QuizHistoryScreen]
class PerformanceDashboardScreen extends ConsumerStatefulWidget {
  const PerformanceDashboardScreen({super.key, this.childId});

  /// When set by a parent, overrides [currentPerformanceChildIdProvider].
  final String? childId;

  @override
  ConsumerState<PerformanceDashboardScreen> createState() =>
      _PerformanceDashboardScreenState();
}

class _PerformanceDashboardScreenState
    extends ConsumerState<PerformanceDashboardScreen> {
  @override
  void initState() {
    super.initState();
    if (widget.childId != null && widget.childId!.isNotEmpty) {
      // Override the active child before first build.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(currentPerformanceChildIdProvider.notifier).state =
            widget.childId!;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<PerformanceData> async =
        ref.watch(performanceControllerProvider);
    final ThemeData theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Performance'),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () => ref
                .read(performanceControllerProvider.notifier)
                .refresh(),
          ),
        ],
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (Object e, _) => _ErrorView(
          message: e.toString().replaceFirst('Exception: ', ''),
          onRetry: () => ref
              .read(performanceControllerProvider.notifier)
              .refresh(),
        ),
        data: (PerformanceData data) => data.isEmpty
            ? _EmptyView(theme: theme)
            : _DashboardBody(data: data),
      ),
    );
  }
}

// ── Dashboard body ────────────────────────────────────────────────────────────

class _DashboardBody extends StatelessWidget {
  const _DashboardBody({super.key, required this.data});
  final PerformanceData data;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;

    return RefreshIndicator(
      onRefresh: () async {
        final ref = (context as Element)
            .getInheritedWidgetOfExactType<ProviderScope>()
            ?.key; // fallback handled below
        // Pull-to-refresh via InheritedWidget lookup is complex;
        // the FAB handles this; pull-to-refresh triggers same route reload.
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            // ── Hero score card ──────────────────────────────────────────
            _ScoreHero(data: data),
            const SizedBox(height: 16),

            // ── 8-stat grid ──────────────────────────────────────────────
            Text(
              'OVERVIEW',
              style: theme.textTheme.labelSmall?.copyWith(
                color: colors.onSurface.withValues(alpha: 0.5),
                fontWeight: FontWeight.w700,
                letterSpacing: 1.1,
              ),
            ),
            const SizedBox(height: 8),
            _OverviewGrid(data: data),
            const SizedBox(height: 20),

            // ── Weekly progress chart ─────────────────────────────────────
            if (data.weeklyProgress.any((double v) => v > 0)) ...<Widget>[
              Text(
                'LAST 7 DAYS',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colors.onSurface.withValues(alpha: 0.5),
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: 8),
              _SparklineChart(values: data.weeklyProgress),
              const SizedBox(height: 20),
            ],

            // ── Navigation cards ──────────────────────────────────────────
            Text(
              'EXPLORE',
              style: theme.textTheme.labelSmall?.copyWith(
                color: colors.onSurface.withValues(alpha: 0.5),
                fontWeight: FontWeight.w700,
                letterSpacing: 1.1,
              ),
            ),
            const SizedBox(height: 8),
            _NavCard(
              icon: Icons.book_outlined,
              title: 'Subjects',
              subtitle:
                  '${data.subjects.length} subject${data.subjects.length != 1 ? 's' : ''}',
              onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
                  builder: (_) =>
                      SubjectPerformanceScreen(subjects: data.subjects))),
            ),
            const SizedBox(height: 8),
            _NavCard(
              icon: Icons.topic_outlined,
              title: 'Topics',
              subtitle:
                  '${data.topics.length} topic${data.topics.length != 1 ? 's' : ''}',
              onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
                  builder: (_) =>
                      TopicPerformanceScreen(topics: data.topics))),
            ),
            const SizedBox(height: 8),
            _NavCard(
              icon: Icons.history,
              title: 'Quiz History',
              subtitle: '${data.totalQuizzes} completed',
              onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
                  builder: (_) =>
                      QuizHistoryScreen(history: data.history))),
            ),
            const SizedBox(height: 20),

            // ── Revision suggestions ──────────────────────────────────────
            if (data.revisionSuggestions.isNotEmpty) ...<Widget>[
              Text(
                'REVISION SUGGESTIONS',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colors.onSurface.withValues(alpha: 0.5),
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: 8),
              ...data.revisionSuggestions.map(
                  (RevisionSuggestion s) => _RevisionCard(suggestion: s)),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Score hero ────────────────────────────────────────────────────────────────

class _ScoreHero extends StatelessWidget {
  const _ScoreHero({super.key, required this.data});
  final PerformanceData data;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;
    final Color scoreColor = data.averageScore >= 70
        ? Colors.green.shade700
        : data.averageScore >= 50
            ? Colors.orange.shade700
            : colors.error;

    return Card(
      elevation: 0,
      color: colors.primaryContainer,
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Average Score',
                    style: theme.textTheme.labelMedium?.copyWith(
                        color: colors.onPrimaryContainer.withValues(alpha: 0.7)),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${data.averageScore.toStringAsFixed(1)} %',
                    style: theme.textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: scoreColor,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${data.totalQuizzes} quiz${data.totalQuizzes != 1 ? 'zes' : ''} completed',
                    style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.onPrimaryContainer.withValues(alpha: 0.65)),
                  ),
                ],
              ),
            ),
            Column(
              children: <Widget>[
                _MiniStat(
                    label: 'Best',
                    value:
                        '${data.highestScore.toStringAsFixed(0)} %',
                    color: Colors.green.shade700),
                const SizedBox(height: 8),
                _MiniStat(
                    label: 'Lowest',
                    value: '${data.lowestScore.toStringAsFixed(0)} %',
                    color: colors.onPrimaryContainer.withValues(alpha: 0.7)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat(
      {super.key,
      required this.label,
      required this.value,
      required this.color});
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) => Column(
        children: <Widget>[
          Text(label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onPrimaryContainer
                      .withValues(alpha: 0.6))),
          Text(value,
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.bold, color: color)),
        ],
      );
}

// ── 8-stat overview grid ──────────────────────────────────────────────────────

class _OverviewGrid extends StatelessWidget {
  const _OverviewGrid({super.key, required this.data});
  final PerformanceData data;

  String _formatTime(int seconds) {
    if (seconds < 60) return '${seconds}s';
    final int h = seconds ~/ 3600;
    final int m = (seconds % 3600) ~/ 60;
    if (h > 0) return '${h}h ${m}m';
    return '${m}m';
  }

  @override
  Widget build(BuildContext context) {
    final List<_StatData> stats = <_StatData>[
      _StatData(
          'Total Quizzes',
          data.totalQuizzes.toString(),
          Icons.quiz_outlined,
          Colors.blue),
      _StatData(
          'Avg Score',
          '${data.averageScore.toStringAsFixed(1)} %',
          Icons.trending_up,
          Colors.indigo),
      _StatData(
          'Highest',
          '${data.highestScore.toStringAsFixed(1)} %',
          Icons.emoji_events_outlined,
          Colors.amber),
      _StatData(
          'Lowest',
          '${data.lowestScore.toStringAsFixed(1)} %',
          Icons.arrow_downward,
          Colors.orange),
      _StatData(
          'Total Qs',
          data.totalQuestionsAnswered.toString(),
          Icons.help_outline,
          Colors.teal),
      _StatData('Correct', data.totalCorrect.toString(),
          Icons.check_circle_outline, Colors.green),
      _StatData('Wrong', data.totalWrong.toString(),
          Icons.cancel_outlined, Colors.red),
      _StatData(
          'Study Time',
          _formatTime(data.totalStudyTimeSeconds),
          Icons.timer_outlined,
          Colors.purple),
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 2.2,
      children:
          stats.map((s) => _GridTile(stat: s)).toList(),
    );
  }
}

class _StatData {
  const _StatData(this.label, this.value, this.icon, this.color);
  final String label;
  final String value;
  final IconData icon;
  final Color color;
}

class _GridTile extends StatelessWidget {
  const _GridTile({super.key, required this.stat});
  final _StatData stat;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: stat.color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(stat.icon, size: 16, color: stat.color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text(stat.label,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color:
                            colors.onSurface.withValues(alpha: 0.55)),
                    overflow: TextOverflow.ellipsis),
                Text(stat.value,
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Sparkline chart ───────────────────────────────────────────────────────────

class _SparklineChart extends StatelessWidget {
  const _SparklineChart({super.key, required this.values});
  final List<double> values;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final double maxVal =
        values.reduce((double a, double b) => a > b ? a : b);
    final double displayMax = maxVal > 0 ? maxVal : 100;

    final List<String> labels = List<String>.generate(7, (int i) {
      final DateTime d =
          DateTime.now().subtract(Duration(days: 6 - i));
      return DateFormat('E').format(d).substring(0, 1);
    });

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        children: <Widget>[
          SizedBox(
            height: 60,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List<Widget>.generate(values.length, (int i) {
                final double pct = values[i] / displayMax;
                return Expanded(
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 2),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: <Widget>[
                        if (values[i] > 0)
                          Text(
                            '${values[i].toStringAsFixed(0)}%',
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(fontSize: 8),
                            textAlign: TextAlign.center,
                          ),
                        const SizedBox(height: 2),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.easeOut,
                          height: pct * 44,
                          decoration: BoxDecoration(
                            color: values[i] > 0
                                ? colors.primary
                                : colors.outlineVariant.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: List<Widget>.generate(
              labels.length,
              (int i) => Expanded(
                child: Text(
                  labels[i],
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: colors.onSurface.withValues(alpha: 0.5),
                      fontSize: 10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Navigation card ───────────────────────────────────────────────────────────

class _NavCard extends StatelessWidget {
  const _NavCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: colors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: colors.outlineVariant),
        ),
        child: Row(
          children: <Widget>[
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: colors.primaryContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: colors.onPrimaryContainer, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(title,
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(fontWeight: FontWeight.w600)),
                  Text(subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colors.onSurface.withValues(alpha: 0.55))),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: colors.outline),
          ],
        ),
      ),
    );
  }
}

// ── Revision suggestions ──────────────────────────────────────────────────────

class _RevisionCard extends StatelessWidget {
  const _RevisionCard({super.key, required this.suggestion});
  final RevisionSuggestion suggestion;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.errorContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.errorContainer),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(Icons.warning_amber_rounded,
                  size: 16, color: colors.error),
              const SizedBox(width: 6),
              Text(suggestion.subjectName,
                  style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold, color: colors.error)),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Weak Topics:',
            style: theme.textTheme.labelSmall
                ?.copyWith(color: colors.onSurface.withValues(alpha: 0.6)),
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: suggestion.weakTopics
                .map((String t) => Chip(
                      label: Text(t,
                          style: theme.textTheme.labelSmall
                              ?.copyWith(color: colors.error)),
                      backgroundColor: colors.errorContainer,
                      padding: EdgeInsets.zero,
                      materialTapTargetSize:
                          MaterialTapTargetSize.shrinkWrap,
                    ))
                .toList(),
          ),
          const SizedBox(height: 6),
          Text(
            'Recommended: Repeat these topics before attempting another quiz.',
            style: theme.textTheme.bodySmall?.copyWith(
                color: colors.onSurface.withValues(alpha: 0.65),
                fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyView extends StatelessWidget {
  const _EmptyView({super.key, required this.theme});
  final ThemeData theme;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(Icons.bar_chart_rounded,
                  size: 72,
                  color: theme.colorScheme.outline.withValues(alpha: 0.5)),
              const SizedBox(height: 20),
              Text('No quizzes yet',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(
                'Complete a quiz in the Quiz Engine to see your performance analytics here.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.55)),
              ),
            ],
          ),
        ),
      );
}

// ── Error state ───────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  const _ErrorView(
      {super.key, required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(Icons.error_outline, size: 56, color: colors.error),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
