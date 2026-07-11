import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/parent_subscription.dart';
import '../../../domain/entities/subject.dart';
import '../../../domain/entities/subject_access.dart';
import '../../controllers/subject_access_controller.dart';
import '../../controllers/subject_controller.dart';
import '../../controllers/subscription_package_controller.dart';
import '../../widgets/feedback/app_error_widget.dart';
import '../../widgets/feedback/loading_widget.dart';

/// Admin screen showing all parent subscriptions and subject access records.
///
/// Two tabs:
///   • Subscribers — all [ParentSubscription] records
///   • Subject Access — all [SubjectAccess] records (admin view)
class AdminSubjectAccessScreen extends ConsumerWidget {
  const AdminSubjectAccessScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Subscribers & Access'),
          bottom: const TabBar(
            tabs: <Widget>[
              Tab(icon: Icon(Icons.people_outline), text: 'Subscribers'),
              Tab(icon: Icon(Icons.lock_open_outlined), text: 'Subject Access'),
            ],
          ),
          actions: <Widget>[
            IconButton(
              icon: const Icon(Icons.refresh_outlined),
              onPressed: () {
                ref
                    .read(adminSubjectAccessControllerProvider.notifier)
                    .refresh();
              },
            ),
          ],
        ),
        body: const TabBarView(
          children: <Widget>[
            _SubscribersTab(),
            _SubjectAccessTab(),
          ],
        ),
      ),
    );
  }
}

// ── Subscribers tab ───────────────────────────────────────────────────────────

class _SubscribersTab extends ConsumerWidget {
  const _SubscribersTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Load all packages for name lookup.
    final pkgState = ref.watch(subscriptionPackageControllerProvider(null));

    // For subscriptions we reuse the admin controller reading all subjects.
    // Note: getAllSubscriptions isn't exposed on a controller yet — we'll show
    // a placeholder with a note that it requires admin service_role access.
    return pkgState.when(
      loading: () =>
          const LoadingWidget(message: 'Loading subscription data...'),
      error: (err, _) => AppErrorWidget(message: err.toString()),
      data: (List<dynamic> packages) {
        final Map<String, String> pkgNames = <String, String>{};
        for (final dynamic p in packages) {
          if (p is dynamic) {
            // Using dynamic to avoid import of SubscriptionPackage here —
            // packages list IS List<SubscriptionPackage> from the controller.
          }
        }
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(Icons.admin_panel_settings_outlined,
                    size: 64,
                    color: Theme.of(context).colorScheme.outline),
                const SizedBox(height: 16),
                Text(
                  'Subscriber List',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Full subscriber list requires service_role access and will '
                  'be populated once the Payment module is integrated. '
                  'Use the Supabase dashboard to view parent_subscriptions '
                  'directly in the meantime.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ── Subject Access tab ────────────────────────────────────────────────────────

class _SubjectAccessTab extends ConsumerWidget {
  const _SubjectAccessTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accessState = ref.watch(adminSubjectAccessControllerProvider);
    final subjectsState = ref.watch(subjectControllerProvider);

    // Build subject lookup map.
    final Map<String, Subject> subjectMap = <String, Subject>{};
    subjectsState.whenData((List<Subject> subjects) {
      for (final Subject s in subjects) {
        subjectMap[s.subjectId] = s;
      }
    });

    return accessState.when(
      loading: () => const LoadingWidget(message: 'Loading access records...'),
      error: (err, _) => AppErrorWidget(
        message: err.toString(),
        onRetry: () => ref
            .read(adminSubjectAccessControllerProvider.notifier)
            .refresh(),
      ),
      data: (List<SubjectAccess> records) {
        if (records.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Text(
                'No subject access records found.',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: records.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (BuildContext context, int index) {
            final SubjectAccess a = records[index];
            final Subject? subject = subjectMap[a.subjectId];
            return ListTile(
              dense: true,
              leading: CircleAvatar(
                radius: 16,
                backgroundColor:
                    Theme.of(context).colorScheme.secondaryContainer,
                child: Text(
                  subject?.icon ?? '📚',
                  style: const TextStyle(fontSize: 14),
                ),
              ),
              title: Text(subject?.subjectName ?? a.subjectId),
              subtitle: Text(
                'Parent: ${a.parentId.substring(0, 8)}…  •  '
                'Source: ${a.source.name}  •  '
                'Valid: ${a.isValid ? "Yes" : "Expired"}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              trailing: _SourceChip(source: a.source),
            );
          },
        );
      },
    );
  }
}

class _SourceChip extends StatelessWidget {
  const _SourceChip({super.key, required this.source});
  final SubjectAccessSource source;

  @override
  Widget build(BuildContext context) {
    final Color color;
    switch (source) {
      case SubjectAccessSource.subscription:
        color = Theme.of(context).colorScheme.primaryContainer;
      case SubjectAccessSource.manual:
        color = Theme.of(context).colorScheme.tertiaryContainer;
      case SubjectAccessSource.trial:
        color = Theme.of(context).colorScheme.secondaryContainer;
    }
    return Chip(
      label: Text(source.name,
          style: const TextStyle(fontSize: 11)),
      backgroundColor: color,
      padding: EdgeInsets.zero,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}
