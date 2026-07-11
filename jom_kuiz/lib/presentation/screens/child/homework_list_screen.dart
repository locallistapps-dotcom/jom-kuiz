import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routing/app_routes.dart';
import '../../../domain/entities/homework.dart';
import '../../controllers/homework_controller.dart';
import '../../widgets/feedback/app_error_widget.dart';
import '../../widgets/feedback/empty_widget.dart';
import '../../widgets/feedback/loading_widget.dart';

/// Lists all homework assignments for the current child, grouped into
/// Pending / Overdue and Completed sections.
class HomeworkListScreen extends ConsumerWidget {
  const HomeworkListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<Homework>> state =
        ref.watch(homeworkControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Homework')),
      body: state.when(
        loading: () =>
            const LoadingWidget(message: 'Loading homework...'),
        error: (Object error, _) => AppErrorWidget(
          message: error.toString(),
          onRetry: () =>
              ref.read(homeworkControllerProvider.notifier).refresh(),
        ),
        data: (List<Homework> all) {
          if (all.isEmpty) {
            return const EmptyWidget(message: 'No homework assigned yet');
          }
          final HomeworkController controller =
              ref.read(homeworkControllerProvider.notifier);
          final List<Homework> pending = controller.pending;
          final List<Homework> completed = controller.completed;

          return RefreshIndicator(
            onRefresh: () =>
                ref.read(homeworkControllerProvider.notifier).refresh(),
            child: ListView(
              padding: const EdgeInsets.all(8),
              children: <Widget>[
                if (pending.isNotEmpty) ...<Widget>[
                  _SectionHeader(title: 'Pending (${pending.length})'),
                  ...pending
                      .map((Homework h) => _HomeworkTile(homework: h)),
                ],
                if (completed.isNotEmpty) ...<Widget>[
                  _SectionHeader(
                      title: 'Completed (${completed.length})'),
                  ...completed
                      .map((Homework h) => _HomeworkTile(homework: h)),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({super.key, required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 12, 8, 4),
      child: Text(title, style: Theme.of(context).textTheme.titleSmall),
    );
  }
}

class _HomeworkTile extends StatelessWidget {
  const _HomeworkTile({super.key, required this.homework});
  final Homework homework;

  Color _statusColor(BuildContext context) {
    switch (homework.status) {
      case HomeworkStatus.completed:
        return Colors.green;
      case HomeworkStatus.overdue:
        return Theme.of(context).colorScheme.error;
      case HomeworkStatus.pending:
        return Theme.of(context).colorScheme.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color statusColor = _statusColor(context);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: ListTile(
        leading: Icon(
          homework.isCompleted
              ? Icons.check_circle
              : Icons.radio_button_unchecked,
          color: statusColor,
        ),
        title: Text(homework.title),
        subtitle: Text(
          '${homework.subject} · Due ${_formatDate(homework.dueDate)}',
        ),
        trailing: Chip(
          label: Text(homework.status.name),
          visualDensity: VisualDensity.compact,
          backgroundColor: statusColor.withOpacity(0.12),
          labelStyle: TextStyle(color: statusColor, fontSize: 11),
        ),
        onTap: () => context.push(
          AppRoutes.childHomeworkDetail,
          extra: homework,
        ),
      ),
    );
  }

  String _formatDate(DateTime d) => '${d.day}/${d.month}/${d.year}';
}
