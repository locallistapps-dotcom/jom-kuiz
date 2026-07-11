import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/child_profile.dart';
import '../../../domain/entities/performance_entities.dart';
import '../../../domain/repositories/performance_repository.dart';
import '../../providers/child_providers.dart';
import '../../providers/performance_providers.dart';
import 'performance_dashboard_screen.dart';

/// Parent view: lists all linked children with their performance overview.
///
/// Tapping a child navigates to [PerformanceDashboardScreen] with that
/// child's ID, overriding [currentPerformanceChildIdProvider].
///
/// Data flow:
/// 1. Load linked children via [ChildRepository.getProfile] (uses
///    [currentChildIdProvider] to know which children exist).
/// 2. Load per-child summaries via [PerformanceRepository.getChildrenOverviews].
///
/// Because the child-listing API in [ChildRepository] only exposes
/// a single-child getter (by design), this screen uses the existing
/// [ChildProfile] list from the parent's dashboard state (injected as
/// [children]) rather than making N separate repository calls.
class ParentPerformanceScreen extends ConsumerWidget {
  const ParentPerformanceScreen({super.key, required this.children});

  /// Pre-loaded list of children linked to the current parent.
  final List<ChildProfile> children;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<String> childIds =
        children.map((ChildProfile c) => c.childId).toList();
    final AsyncValue<List<ChildPerformanceOverview>> async =
        ref.watch(_childrenOverviewProvider(childIds));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Children's Performance'),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () =>
                ref.invalidate(_childrenOverviewProvider(childIds)),
          ),
        ],
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (Object e, _) => _ErrorBody(
          message: e.toString().replaceFirst('Exception: ', ''),
          onRetry: () =>
              ref.invalidate(_childrenOverviewProvider(childIds)),
        ),
        data: (List<ChildPerformanceOverview> overviews) {
          if (overviews.isEmpty) {
            return _EmptyBody(
              message: 'No linked children found. '
                  'Ask your child to link their account.',
            );
          }

          // Merge child names from [ChildProfile] into overviews.
          final Map<String, String> nameMap = <String, String>{
            for (final ChildProfile c in children) c.childId: c.fullName
          };
          final List<ChildPerformanceOverview> named = overviews
              .map((ChildPerformanceOverview o) =>
                  ChildPerformanceOverview(
                    childId: o.childId,
                    childName: nameMap[o.childId] ?? o.childName,
                    totalQuizzes: o.totalQuizzes,
                    averageScore: o.averageScore,
                    latestScore: o.latestScore,
                    strongestSubject: o.strongestSubject,
                    weakestSubject: o.weakestSubject,
                  ))
              .toList();

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            itemCount: named.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (BuildContext ctx, int i) => _ChildCard(
              overview: named[i],
              onTap: () {
                ref
                    .read(currentPerformanceChildIdProvider.notifier)
                    .state = named[i].childId;
                Navigator.of(context).push(MaterialPageRoute<void>(
                  builder: (_) => PerformanceDashboardScreen(
                      childId: named[i].childId),
                ));
              },
            ),
          );
        },
      ),
    );
  }
}

// ── Local FutureProvider ──────────────────────────────────────────────────────

final AutoDisposeFutureProviderFamily<List<ChildPerformanceOverview>,
        List<String>> _childrenOverviewProvider =
    FutureProvider.autoDispose
        .family<List<ChildPerformanceOverview>, List<String>>(
  (AutoDisposeFutureProviderFamilyRef<List<ChildPerformanceOverview>, List<String>> ref,
      List<String> childIds) async {
    final PerformanceRepository repo =
        ref.watch(performanceRepositoryProvider);
    final result =
        await repo.getChildrenOverviews(childIds: childIds);
    return result.when(
      success: (List<ChildPerformanceOverview> data) => data,
      failure: (f) => throw Exception(f.message),
    );
  },
);

// ── Child card ────────────────────────────────────────────────────────────────

class _ChildCard extends StatelessWidget {
  const _ChildCard(
      {super.key, required this.overview, required this.onTap});
  final ChildPerformanceOverview overview;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;
    final bool hasData = overview.totalQuizzes > 0;

    final Color scoreColor = !hasData
        ? colors.outline
        : overview.averageScore >= 70
            ? Colors.green.shade700
            : overview.averageScore >= 50
                ? Colors.orange.shade700
                : colors.error;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.outlineVariant),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                CircleAvatar(
                  radius: 22,
                  backgroundColor: colors.primaryContainer,
                  child: Text(
                    overview.childName.isNotEmpty
                        ? overview.childName[0].toUpperCase()
                        : '?',
                    style: theme.textTheme.titleMedium?.copyWith(
                        color: colors.onPrimaryContainer,
                        fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        overview.childName,
                        style: theme.textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        hasData
                            ? '${overview.totalQuizzes} quiz${overview.totalQuizzes != 1 ? 'zes' : ''} completed'
                            : 'No quizzes yet',
                        style: theme.textTheme.bodySmall?.copyWith(
                            color:
                                colors.onSurface.withValues(alpha: 0.55)),
                      ),
                    ],
                  ),
                ),
                // Average score badge
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: hasData
                        ? scoreColor.withValues(alpha: 0.1)
                        : colors.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: hasData
                            ? scoreColor.withValues(alpha: 0.4)
                            : colors.outlineVariant),
                  ),
                  child: Text(
                    hasData
                        ? '${overview.averageScore.toStringAsFixed(1)} %'
                        : '—',
                    style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: hasData ? scoreColor : colors.outline),
                  ),
                ),
              ],
            ),
            if (hasData) ...<Widget>[
              const SizedBox(height: 12),
              Row(
                children: <Widget>[
                  if (overview.latestScore != null)
                    _InfoChip(
                      label: 'Latest',
                      value:
                          '${overview.latestScore!.toStringAsFixed(1)} %',
                      color: colors.primary,
                    ),
                  if (overview.strongestSubject != null) ...<Widget>[
                    const SizedBox(width: 8),
                    _InfoChip(
                      label: 'Best at',
                      value: overview.strongestSubject!,
                      color: Colors.green.shade700,
                    ),
                  ],
                  if (overview.weakestSubject != null) ...<Widget>[
                    const SizedBox(width: 8),
                    _InfoChip(
                      label: 'Needs work',
                      value: overview.weakestSubject!,
                      color: colors.error,
                    ),
                  ],
                ],
              ),
            ],
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                'View Dashboard →',
                style: theme.textTheme.labelSmall
                    ?.copyWith(color: colors.primary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip(
      {super.key,
      required this.label,
      required this.value,
      required this.color});
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.5),
                  fontSize: 9)),
          Text(value,
              style: Theme.of(context)
                  .textTheme
                  .labelSmall
                  ?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: color,
                      fontSize: 11),
              overflow: TextOverflow.ellipsis),
        ],
      );
}

// ── Empty / error bodies ──────────────────────────────────────────────────────

class _EmptyBody extends StatelessWidget {
  const _EmptyBody({super.key, required this.message});
  final String message;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(Icons.people_outline,
                  size: 64,
                  color: Theme.of(context)
                      .colorScheme
                      .outline
                      .withValues(alpha: 0.5)),
              const SizedBox(height: 16),
              Text(message,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.55))),
            ],
          ),
        ),
      );
}

class _ErrorBody extends StatelessWidget {
  const _ErrorBody(
      {super.key, required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(Icons.error_outline,
                  size: 56,
                  color: Theme.of(context).colorScheme.error),
              const SizedBox(height: 12),
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry')),
            ],
          ),
        ),
      );
}
