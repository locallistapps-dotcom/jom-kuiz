import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routing/app_routes.dart';
import '../../../domain/entities/child_profile.dart';
import '../../../domain/entities/homework.dart';
import '../../controllers/achievement_controller.dart';
import '../../controllers/child_profile_controller.dart';
import '../../controllers/homework_controller.dart';
import '../../controllers/session_controller.dart';
import '../../widgets/feedback/app_error_widget.dart';
import '../../widgets/feedback/loading_widget.dart';

/// Child Dashboard — the landing screen when a child is logged in.
/// Shows a welcome card, profile summary, parent link status, class
/// information, pending homework count, and quick navigation actions.
class ChildDashboardScreen extends ConsumerWidget {
  const ChildDashboardScreen({super.key});

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: const Text('Log Keluar'),
        content: const Text('Adakah anda pasti mahu log keluar?'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Log Keluar'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await ref.read(sessionControllerProvider.notifier).logout();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<ChildProfile?> profileState =
        ref.watch(childProfileControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Child Dashboard'),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.person_outline),
            tooltip: 'Profile',
            onPressed: () => context.push(AppRoutes.childProfile),
          ),
          IconButton(
            icon: const Icon(Icons.logout_outlined),
            tooltip: 'Log Keluar',
            onPressed: () => _confirmLogout(context, ref),
          ),
        ],
      ),
      body: profileState.when(
        loading: () =>
            const LoadingWidget(message: 'Loading child dashboard...'),
        error: (Object error, _) => AppErrorWidget(
          message: error.toString(),
          onRetry: () =>
              ref.read(childProfileControllerProvider.notifier).refresh(),
        ),
        data: (ChildProfile? profile) {
          if (profile == null) {
            return const AppErrorWidget(message: 'No child selected');
          }
          return RefreshIndicator(
            onRefresh: () async {
              await ref
                  .read(childProfileControllerProvider.notifier)
                  .refresh();
              await ref.read(homeworkControllerProvider.notifier).refresh();
              await ref
                  .read(achievementControllerProvider.notifier)
                  .refresh();
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: <Widget>[
                _WelcomeCard(profile: profile),
                const SizedBox(height: 12),
                _ProfileSummaryCard(profile: profile),
                const SizedBox(height: 12),
                _LinkedParentCard(profile: profile),
                const SizedBox(height: 12),
                _ClassInfoCard(profile: profile),
                const SizedBox(height: 12),
                const _HomeworkSummaryCard(),
                const SizedBox(height: 20),
                Text(
                  'Quick Actions',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                const _QuickActions(),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ── Sub-widgets ──────────────────────────────────────────────────────────────

class _WelcomeCard extends StatelessWidget {
  const _WelcomeCard({super.key, required this.profile});
  final ChildProfile profile;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          'Welcome, ${profile.fullName}! 👋',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
        ),
      ),
    );
  }
}

class _ProfileSummaryCard extends StatelessWidget {
  const _ProfileSummaryCard({super.key, required this.profile});
  final ChildProfile profile;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          radius: 24,
          backgroundImage: profile.profilePhoto != null
              ? NetworkImage(profile.profilePhoto!)
              : null,
          child:
              profile.profilePhoto == null ? const Icon(Icons.child_care) : null,
        ),
        title: Text(profile.fullName),
        subtitle: Text('@${profile.username}'),
        trailing: TextButton(
          onPressed: () => context.push(AppRoutes.childProfile),
          child: const Text('View'),
        ),
      ),
    );
  }
}

class _LinkedParentCard extends StatelessWidget {
  const _LinkedParentCard({super.key, required this.profile});
  final ChildProfile profile;

  @override
  Widget build(BuildContext context) {
    final LinkedParent? parent = profile.linkedParent;
    return Card(
      child: ListTile(
        leading: const Icon(Icons.family_restroom_outlined),
        title: const Text('Linked Parent'),
        subtitle: parent != null
            ? Text(parent.fullName)
            : const Text('No parent linked'),
        trailing: parent != null
            ? Chip(
                label: Text(parent.linkStatus.name),
                visualDensity: VisualDensity.compact,
              )
            : null,
        onTap: () => context.push(AppRoutes.childLinkedParent),
      ),
    );
  }
}

class _ClassInfoCard extends StatelessWidget {
  const _ClassInfoCard({super.key, required this.profile});
  final ChildProfile profile;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Education',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            _InfoRow(
              label: 'Level',
              value: profile.educationLevel.name == 'preschool'
                  ? 'Preschool'
                  : profile.educationLevel.name == 'primary'
                      ? 'Primary School'
                      : 'Secondary School',
            ),
            const SizedBox(height: 4),
            _InfoRow(
              label: 'Year / Grade',
              value: profile.yearGrade.isEmpty ? '—' : profile.yearGrade,
            ),
            if (profile.studentId.isNotEmpty) ...<Widget>[
              const SizedBox(height: 4),
              _InfoRow(label: 'Student ID', value: profile.studentId),
            ],
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({super.key, required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Text(
          '$label: ',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
        ),
        Text(value, style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }
}

class _HomeworkSummaryCard extends ConsumerWidget {
  const _HomeworkSummaryCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<Homework> pending =
        ref.watch(homeworkControllerProvider.notifier).pending;
    return Card(
      child: ListTile(
        leading: const Icon(Icons.assignment_outlined),
        title: const Text('Homework'),
        subtitle: Text(
          pending.isEmpty ? 'All caught up!' : '${pending.length} pending',
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => context.push(AppRoutes.childHomework),
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({super.key});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: <Widget>[
        ActionChip(
          avatar: const Icon(Icons.play_circle_outline, size: 18),
          label: const Text('Start Quiz'),
          onPressed: () => context.push(AppRoutes.studentStudySubjects),
        ),
        ActionChip(
          avatar: const Icon(Icons.assignment_outlined, size: 18),
          label: const Text('Homework'),
          onPressed: () => context.push(AppRoutes.childHomework),
        ),
        ActionChip(
          avatar: const Icon(Icons.quiz_outlined, size: 18),
          label: const Text('Quiz History'),
          onPressed: () => context.push(AppRoutes.childQuiz),
        ),
        ActionChip(
          avatar: const Icon(Icons.emoji_events_outlined, size: 18),
          label: const Text('Achievements'),
          onPressed: () => context.push(AppRoutes.childAchievements),
        ),
        ActionChip(
          avatar: const Icon(Icons.edit_outlined, size: 18),
          label: const Text('Edit Profile'),
          onPressed: () => context.push(AppRoutes.childEditProfile),
        ),
      ],
    );
  }
}
