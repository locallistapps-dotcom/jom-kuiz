import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routing/app_routes.dart';
import '../../../domain/entities/subject.dart';
import '../../../domain/entities/subject_access.dart';
import '../../controllers/subject_access_controller.dart';
import '../../controllers/subject_controller.dart';
import '../../widgets/feedback/app_error_widget.dart';
import '../../widgets/feedback/loading_widget.dart';

/// Shows all active subjects the parent does NOT yet have access to.
///
/// Each item shows a lock icon and a link to the subscription screen where
/// the parent can browse packages to unlock these subjects.
class LockedSubjectsScreen extends ConsumerWidget {
  const LockedSubjectsScreen({super.key, required this.parentId});

  final String parentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subjectsState = ref.watch(subjectControllerProvider);
    final accessState =
        ref.watch(subjectAccessControllerProvider(parentId));

    return Scaffold(
      appBar: AppBar(title: const Text('Locked Subjects')),
      body: subjectsState.when(
        loading: () => const LoadingWidget(message: 'Loading subjects...'),
        error: (err, _) => AppErrorWidget(message: err.toString()),
        data: (List<Subject> allSubjects) {
          // Filter to only active subjects.
          final List<Subject> active =
              allSubjects.where((Subject s) => s.isActive).toList();

          return accessState.when(
            loading: () => const LoadingWidget(message: 'Checking access...'),
            error: (err, _) => AppErrorWidget(message: err.toString()),
            data: (List<SubjectAccess> accessList) {
              // Determine which subjects are accessible.
              final Set<String> ownedIds = accessList
                  .where((SubjectAccess a) => a.isValid)
                  .map((SubjectAccess a) => a.subjectId)
                  .toSet();

              final List<Subject> locked = active
                  .where((Subject s) => !ownedIds.contains(s.subjectId))
                  .toList();

              if (locked.isEmpty) {
                return const _AllUnlockedState();
              }

              return Column(
                children: <Widget>[
                  // Upgrade banner.
                  Container(
                    width: double.infinity,
                    color: Theme.of(context).colorScheme.errorContainer,
                    padding: const EdgeInsets.symmetric(
                        vertical: 12, horizontal: 16),
                    child: Row(
                      children: <Widget>[
                        Icon(Icons.lock_outlined,
                            color: Theme.of(context)
                                .colorScheme
                                .onErrorContainer,
                            size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${locked.length} subject${locked.length == 1 ? '' : 's'} locked. '
                            'Subscribe to a package to gain access.',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onErrorContainer,
                                ),
                          ),
                        ),
                        TextButton(
                          onPressed: () =>
                              context.push(AppRoutes.subscription),
                          style: TextButton.styleFrom(
                            foregroundColor: Theme.of(context)
                                .colorScheme
                                .onErrorContainer,
                          ),
                          child: const Text('View Plans'),
                        ),
                      ],
                    ),
                  ),

                  // Locked subject list.
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: locked.length,
                      separatorBuilder: (_, __) =>
                          const Divider(height: 1),
                      itemBuilder: (BuildContext context, int index) {
                        final Subject s = locked[index];
                        return ListTile(
                          leading: ColorFiltered(
                            colorFilter: const ColorFilter.mode(
                              Colors.grey,
                              BlendMode.saturation,
                            ),
                            child: CircleAvatar(
                              backgroundColor: Theme.of(context)
                                  .colorScheme
                                  .surfaceContainerHighest,
                              child: Text(
                                s.icon ?? '📚',
                                style: const TextStyle(fontSize: 20),
                              ),
                            ),
                          ),
                          title: Text(
                            s.subjectName,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .outline,
                                ),
                          ),
                          trailing: const Icon(Icons.lock_outlined,
                              size: 20, color: Colors.grey),
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _AllUnlockedState extends StatelessWidget {
  const _AllUnlockedState({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(Icons.lock_open_outlined,
                size: 64,
                color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 16),
            Text(
              'All subjects are unlocked!',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'You have access to every available subject.',
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
