import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/teacher_dashboard.dart';
import '../../controllers/teacher_dashboard_controller.dart';
import '../../widgets/feedback/app_error_widget.dart';
import '../../widgets/feedback/empty_widget.dart';
import '../../widgets/feedback/loading_widget.dart';

/// Teacher Dashboard — the landing screen for a logged-in teacher.
///
/// Displays welcome card, profile summary, school information, assigned
/// classes with student counts, today's schedule, recent activities, and
/// quick-action chips for modules that ship in later prompts.
class TeacherDashboardScreen extends ConsumerWidget {
  const TeacherDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<TeacherDashboard?> state =
        ref.watch(teacherDashboardControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Teacher Dashboard'),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.refresh_outlined),
            tooltip: 'Refresh',
            onPressed: () =>
                ref.read(teacherDashboardControllerProvider.notifier).refresh(),
          ),
        ],
      ),
      body: state.when(
        loading: () =>
            const LoadingWidget(message: 'Loading your dashboard...'),
        error: (Object error, _) => AppErrorWidget(
          message: error.toString(),
          onRetry: () =>
              ref.read(teacherDashboardControllerProvider.notifier).refresh(),
        ),
        data: (TeacherDashboard? dashboard) {
          if (dashboard == null) {
            return const EmptyWidget(
              message: 'No teacher data found. Please log in again.',
              icon: Icons.school_outlined,
            );
          }
          return RefreshIndicator(
            onRefresh: () =>
                ref.read(teacherDashboardControllerProvider.notifier).refresh(),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: <Widget>[
                _WelcomeCard(profile: dashboard.profile),
                const SizedBox(height: 12),
                _ProfileSummaryCard(profile: dashboard.profile),
                const SizedBox(height: 12),
                _SchoolInfoCard(school: dashboard.school),
                const SizedBox(height: 12),
                _AssignedClassesCard(
                  classes: dashboard.assignedClasses,
                  totalStudents: dashboard.totalStudents,
                ),
                const SizedBox(height: 12),
                _TodayScheduleCard(schedule: dashboard.todaySchedule),
                const SizedBox(height: 12),
                _RecentActivitiesCard(activities: dashboard.recentActivities),
                const SizedBox(height: 20),
                Text(
                  'Quick Actions',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                const _QuickActions(),
                const SizedBox(height: 8),
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
  final TeacherProfile profile;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: <Widget>[
            Icon(
              Icons.waving_hand_outlined,
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Welcome, ${profile.fullName}!',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color:
                          Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileSummaryCard extends StatelessWidget {
  const _ProfileSummaryCard({super.key, required this.profile});
  final TeacherProfile profile;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: <Widget>[
            CircleAvatar(
              radius: 28,
              backgroundImage: profile.profilePhoto != null
                  ? NetworkImage(profile.profilePhoto!)
                  : null,
              child: profile.profilePhoto == null
                  ? const Icon(Icons.person_outline, size: 28)
                  : null,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    profile.fullName,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(
                    profile.email,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: <Widget>[
                      Chip(
                        label: Text(profile.subject),
                        visualDensity: VisualDensity.compact,
                        avatar: const Icon(Icons.book_outlined, size: 14),
                      ),
                      if (profile.employeeId != null) ...<Widget>[
                        const SizedBox(width: 6),
                        Text(
                          profile.employeeId!,
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(
                                color:
                                    Theme.of(context).colorScheme.outline,
                              ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SchoolInfoCard extends StatelessWidget {
  const _SchoolInfoCard({super.key, required this.school});
  final SchoolInfo school;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(
                  Icons.school_outlined,
                  size: 18,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 6),
                Text(
                  'School Information',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ],
            ),
            const Divider(height: 16),
            _InfoRow(label: 'School', value: school.schoolName),
            if (school.schoolType != null) ...<Widget>[
              const SizedBox(height: 4),
              _InfoRow(label: 'Type', value: school.schoolType!),
            ],
            if (school.academicYear != null) ...<Widget>[
              const SizedBox(height: 4),
              _InfoRow(label: 'Academic Year', value: school.academicYear!),
            ],
            if (school.schoolAddress != null) ...<Widget>[
              const SizedBox(height: 4),
              _InfoRow(label: 'Address', value: school.schoolAddress!),
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SizedBox(
          width: 110,
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
          ),
        ),
        Expanded(
          child: Text(value, style: Theme.of(context).textTheme.bodyMedium),
        ),
      ],
    );
  }
}

class _AssignedClassesCard extends StatelessWidget {
  const _AssignedClassesCard({
    super.key,
    required this.classes,
    required this.totalStudents,
  });
  final List<TeacherClass> classes;
  final int totalStudents;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Icon(
                      Icons.class_outlined,
                      size: 18,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Assigned Classes',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ],
                ),
                _CountBadge(
                  count: totalStudents,
                  label: 'students',
                  icon: Icons.people_outline,
                ),
              ],
            ),
            const Divider(height: 16),
            if (classes.isEmpty)
              const EmptyWidget(
                message: 'No classes assigned yet',
                icon: Icons.class_outlined,
              )
            else
              ...classes.map((TeacherClass c) => _ClassTile(teacherClass: c)),
          ],
        ),
      ),
    );
  }
}

class _CountBadge extends StatelessWidget {
  const _CountBadge({
    super.key,
    required this.count,
    required this.label,
    required this.icon,
  });
  final int count;
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(icon, size: 16, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 4),
        Text(
          '$count $label',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );
  }
}

class _ClassTile extends StatelessWidget {
  const _ClassTile({super.key, required this.teacherClass});
  final TeacherClass teacherClass;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: <Widget>[
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.secondaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.people_outline,
              size: 18,
              color: Theme.of(context).colorScheme.secondary,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  teacherClass.name,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                ),
                Text(
                  '${teacherClass.subject}'
                  '${teacherClass.gradeLevel != null ? ' · ${teacherClass.gradeLevel}' : ''}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                ),
              ],
            ),
          ),
          Text(
            '${teacherClass.studentCount}',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                ),
          ),
          const SizedBox(width: 4),
          Text(
            'students',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
          ),
        ],
      ),
    );
  }
}

class _TodayScheduleCard extends StatelessWidget {
  const _TodayScheduleCard({super.key, required this.schedule});
  final List<ScheduleItem> schedule;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(
                  Icons.schedule_outlined,
                  size: 18,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 6),
                Text(
                  "Today's Schedule",
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ],
            ),
            const Divider(height: 16),
            if (schedule.isEmpty)
              const EmptyWidget(
                message: 'No classes scheduled for today',
                icon: Icons.event_available_outlined,
              )
            else
              ...schedule.map(
                (ScheduleItem item) => _ScheduleRow(item: item),
              ),
          ],
        ),
      ),
    );
  }
}

class _ScheduleRow extends StatelessWidget {
  const _ScheduleRow({super.key, required this.item});
  final ScheduleItem item;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: <Widget>[
          SizedBox(
            width: 46,
            child: Text(
              item.time,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          Container(
            width: 2,
            height: 36,
            color: Theme.of(context).colorScheme.outlineVariant,
            margin: const EdgeInsets.symmetric(horizontal: 8),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  item.subject,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                ),
                Text(
                  '${item.className}'
                  '${item.room != null ? ' · ${item.room}' : ''}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentActivitiesCard extends StatelessWidget {
  const _RecentActivitiesCard({super.key, required this.activities});
  final List<RecentActivity> activities;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(
                  Icons.history_outlined,
                  size: 18,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 6),
                Text(
                  'Recent Activities',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ],
            ),
            const Divider(height: 16),
            if (activities.isEmpty)
              const EmptyWidget(
                message: 'No recent activities',
                icon: Icons.history_outlined,
              )
            else
              ...activities
                  .take(5)
                  .map((RecentActivity a) => _ActivityRow(activity: a)),
          ],
        ),
      ),
    );
  }
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({super.key, required this.activity});
  final RecentActivity activity;

  static IconData _iconFor(ActivityType type) {
    switch (type) {
      case ActivityType.homework:
        return Icons.assignment_outlined;
      case ActivityType.quiz:
        return Icons.quiz_outlined;
      case ActivityType.announcement:
        return Icons.campaign_outlined;
      case ActivityType.attendance:
        return Icons.how_to_reg_outlined;
      case ActivityType.other:
        return Icons.info_outline;
    }
  }

  static Color _colorFor(ActivityType type, BuildContext context) {
    switch (type) {
      case ActivityType.homework:
        return Theme.of(context).colorScheme.primary;
      case ActivityType.quiz:
        return Colors.orange;
      case ActivityType.announcement:
        return Colors.purple;
      case ActivityType.attendance:
        return Colors.green;
      case ActivityType.other:
        return Theme.of(context).colorScheme.outline;
    }
  }

  /// Returns a human-readable relative time string.
  String _relativeTime(DateTime ts) {
    final Duration diff = DateTime.now().difference(ts);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    final Color color = _colorFor(activity.type, context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(_iconFor(activity.type), size: 16, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  activity.description,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                Text(
                  _relativeTime(activity.timestamp),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({super.key});

  void _showComingSoon(BuildContext context, String module) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$module — coming in the next prompt'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: <Widget>[
        ActionChip(
          avatar: const Icon(Icons.class_outlined, size: 18),
          label: const Text('My Classes'),
          onPressed: () => _showComingSoon(context, 'My Classes'),
        ),
        ActionChip(
          avatar: const Icon(Icons.how_to_reg_outlined, size: 18),
          label: const Text('Attendance'),
          onPressed: () => _showComingSoon(context, 'Attendance'),
        ),
        ActionChip(
          avatar: const Icon(Icons.assignment_outlined, size: 18),
          label: const Text('Homework'),
          onPressed: () => _showComingSoon(context, 'Homework'),
        ),
        ActionChip(
          avatar: const Icon(Icons.quiz_outlined, size: 18),
          label: const Text('Quiz'),
          onPressed: () => _showComingSoon(context, 'Quiz'),
        ),
        ActionChip(
          avatar: const Icon(Icons.campaign_outlined, size: 18),
          label: const Text('Announcements'),
          onPressed: () => _showComingSoon(context, 'Announcements'),
        ),
      ],
    );
  }
}
