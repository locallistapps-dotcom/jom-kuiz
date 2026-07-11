import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/subject.dart';
import '../../../domain/entities/subject_access.dart';
import '../../controllers/subject_access_controller.dart';
import '../../controllers/subject_controller.dart';
import '../../widgets/feedback/app_error_widget.dart';
import '../../widgets/feedback/loading_widget.dart';

/// Shows all subjects the parent currently has access to.
///
/// Children automatically inherit access to every subject listed here.
class PurchasedSubjectsScreen extends ConsumerWidget {
  const PurchasedSubjectsScreen({super.key, required this.parentId});

  final String parentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accessState =
        ref.watch(subjectAccessControllerProvider(parentId));
    final subjectsState = ref.watch(subjectControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Purchased Subjects'),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.refresh_outlined),
            onPressed: () =>
                ref.read(subjectAccessControllerProvider(parentId).notifier).refresh(),
          ),
        ],
      ),
      body: accessState.when(
        loading: () => const LoadingWidget(message: 'Loading access...'),
        error: (err, _) => AppErrorWidget(
          message: err.toString(),
          onRetry: () => ref
              .read(subjectAccessControllerProvider(parentId).notifier)
              .refresh(),
        ),
        data: (List<SubjectAccess> accessList) {
          final List<SubjectAccess> valid =
              accessList.where((SubjectAccess a) => a.isValid).toList();

          if (valid.isEmpty) {
            return const _EmptyState(
              icon: Icons.lock_open_outlined,
              message:
                  'No purchased subjects yet.\nSubscribe to a package to unlock subjects.',
            );
          }

          // Build subject lookup from the existing subject list.
          final Map<String, Subject> subjectMap = <String, Subject>{};
          subjectsState.whenData((List<Subject> subjects) {
            for (final Subject s in subjects) {
              subjectMap[s.subjectId] = s;
            }
          });

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: valid.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (BuildContext context, int index) {
              final SubjectAccess access = valid[index];
              final Subject? subject = subjectMap[access.subjectId];

              return ListTile(
                leading: CircleAvatar(
                  backgroundColor:
                      Theme.of(context).colorScheme.primaryContainer,
                  child: Text(
                    subject?.icon ?? '📚',
                    style: const TextStyle(fontSize: 20),
                  ),
                ),
                title: Text(subject?.subjectName ?? access.subjectId),
                subtitle: Text(
                  'Source: ${access.source.name}  •  '
                  'Granted: ${_formatDate(access.grantedAt)}'
                  '${access.expiresAt != null ? '  •  Expires: ${_formatDate(access.expiresAt!)}' : ''}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                trailing: const Icon(Icons.lock_open_outlined,
                    color: Colors.green, size: 20),
              );
            },
          );
        },
      ),
    );
  }

  String _formatDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}

class _EmptyState extends StatelessWidget {
  const _EmptyState(
      {super.key, required this.icon, required this.message});
  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, size: 64, color: Theme.of(context).colorScheme.outline),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
