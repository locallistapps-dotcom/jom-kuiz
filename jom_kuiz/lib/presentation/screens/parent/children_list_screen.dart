import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routing/app_routes.dart';
import '../../../data/models/account_management_models.dart';
import '../../../domain/entities/education_level.dart';
import '../../controllers/children_list_controller.dart';
import '../../providers/child_providers.dart';
import '../../widgets/feedback/app_error_widget.dart';
import '../../widgets/feedback/loading_widget.dart';

/// Parent's Children List — shows all linked children with performance cards.
///
/// Tap a child card to open the child management screen.
/// The FAB opens the Add Child flow.
class ChildrenListScreen extends ConsumerWidget {
  const ChildrenListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<ChildCardData>> listState =
        ref.watch(childrenListControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Children'),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () =>
                ref.read(childrenListControllerProvider.notifier).refresh(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'add_child_fab',
        onPressed: () async {
          await context.push(AppRoutes.addChild);
          if (context.mounted) {
            ref.read(childrenListControllerProvider.notifier).refresh();
          }
        },
        icon: const Icon(Icons.person_add_outlined),
        label: const Text('Add Child'),
      ),
      body: listState.when(
        loading: () => const LoadingWidget(message: 'Loading children...'),
        error: (Object err, _) => AppErrorWidget(
          message: err.toString(),
          onRetry: () =>
              ref.read(childrenListControllerProvider.notifier).refresh(),
        ),
        data: (List<ChildCardData> children) {
          if (children.isEmpty) {
            return const _EmptyState();
          }
          return RefreshIndicator(
            onRefresh: () =>
                ref.read(childrenListControllerProvider.notifier).refresh(),
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              itemCount: children.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (BuildContext context, int i) =>
                  _ChildCard(card: children[i]),
            ),
          );
        },
      ),
    );
  }
}

// ── Child Card ────────────────────────────────────────────────────────────────

class _ChildCard extends ConsumerWidget {
  const _ChildCard({super.key, required this.card});
  final ChildCardData card;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool isDisabled = card.accountStatus == ChildAccountStatus.disabled;
    final Color statusColor =
        isDisabled ? Theme.of(context).colorScheme.error : Colors.green;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () async {
          await context.push(AppRoutes.childManagement, extra: card.childId);
          if (context.mounted) {
            ref.read(childrenListControllerProvider.notifier).refresh();
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // ── Header row ─────────────────────────────────────────────────
              Row(
                children: <Widget>[
                  CircleAvatar(
                    radius: 22,
                    backgroundImage: card.profilePhoto != null
                        ? NetworkImage(card.profilePhoto!)
                        : null,
                    child: card.profilePhoto == null
                        ? const Icon(Icons.child_care)
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          card.fullName,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(
                          '@${card.username}  •  ID: ${card.studentId}',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color:
                                        Theme.of(context).colorScheme.outline,
                                  ),
                        ),
                      ],
                    ),
                  ),
                  // Status chip
                  Chip(
                    label: Text(
                      isDisabled ? 'Disabled' : 'Active',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: Colors.white,
                          ),
                    ),
                    backgroundColor: statusColor,
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // ── Education row ───────────────────────────────────────────────
              Text(
                '${EducationLevelHelper.labelFor(card.educationLevel)}  •  ${card.yearGrade}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                    ),
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),
              // ── Performance row ─────────────────────────────────────────────
              _PerfRow(card: card),
            ],
          ),
        ),
      ),
    );
  }
}

class _PerfRow extends StatelessWidget {
  const _PerfRow({super.key, required this.card});
  final ChildCardData card;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        _StatCell(
          label: 'Quizzes',
          value: '${card.totalQuizzes}',
        ),
        _StatCell(
          label: 'Avg Score',
          value: card.totalQuizzes == 0
              ? '—'
              : '${card.averageScore.toStringAsFixed(1)}%',
        ),
        _StatCell(
          label: 'Latest',
          value: card.latestScore < 0
              ? '—'
              : '${card.latestScore.toStringAsFixed(1)}%',
        ),
      ],
    );
  }
}

class _StatCell extends StatelessWidget {
  const _StatCell({super.key, required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: <Widget>[
          Text(
            value,
            style: Theme.of(context).textTheme.titleSmall,
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
          ),
        ],
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Icon(
            Icons.child_care_outlined,
            size: 72,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            'No children added yet',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the + button to add your first child.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
          ),
        ],
      ),
    );
  }
}
