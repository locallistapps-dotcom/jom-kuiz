import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../domain/entities/homework.dart';

/// Displays the full details of a single homework assignment.
///
/// The [Homework] entity is passed via GoRouter's `extra` parameter so no
/// additional network fetch is needed for this read-only detail view.
class HomeworkDetailScreen extends StatelessWidget {
  const HomeworkDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final Homework? homework =
        GoRouterState.of(context).extra as Homework?;

    if (homework == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Homework Detail')),
        body: const Center(child: Text('Homework not found')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Homework Detail')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          _StatusBanner(status: homework.status),
          const SizedBox(height: 16),
          Text(
            homework.title,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          _MetaChip(label: homework.subject, icon: Icons.book_outlined),
          const SizedBox(height: 16),
          if (homework.description != null &&
              homework.description!.isNotEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text('Description',
                        style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: 8),
                    Text(
                      homework.description!,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text('Details',
                      style: Theme.of(context).textTheme.titleSmall),
                  const Divider(height: 16),
                  _DetailRow(label: 'Subject', value: homework.subject),
                  const SizedBox(height: 8),
                  _DetailRow(
                    label: 'Due Date',
                    value: _formatDate(homework.dueDate),
                  ),
                  const SizedBox(height: 8),
                  _DetailRow(
                    label: 'Status',
                    value: homework.status.name,
                  ),
                  if (homework.completedAt != null) ...<Widget>[
                    const SizedBox(height: 8),
                    _DetailRow(
                      label: 'Completed',
                      value: _formatDate(homework.completedAt!),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/'
      '${d.month.toString().padLeft(2, '0')}/${d.year}';
}

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({super.key, required this.status});
  final HomeworkStatus status;

  Color _bg(BuildContext context) {
    switch (status) {
      case HomeworkStatus.completed:
        return Colors.green.shade50;
      case HomeworkStatus.overdue:
        return Theme.of(context).colorScheme.errorContainer;
      case HomeworkStatus.pending:
        return Theme.of(context).colorScheme.primaryContainer;
    }
  }

  Color _fg(BuildContext context) {
    switch (status) {
      case HomeworkStatus.completed:
        return Colors.green.shade800;
      case HomeworkStatus.overdue:
        return Theme.of(context).colorScheme.onErrorContainer;
      case HomeworkStatus.pending:
        return Theme.of(context).colorScheme.onPrimaryContainer;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: _bg(context),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status.name.toUpperCase(),
        style: TextStyle(
          color: _fg(context),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({super.key, required this.label, required this.icon});
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon, size: 16),
      label: Text(label),
      visualDensity: VisualDensity.compact,
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({super.key, required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SizedBox(
          width: 90,
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }
}
