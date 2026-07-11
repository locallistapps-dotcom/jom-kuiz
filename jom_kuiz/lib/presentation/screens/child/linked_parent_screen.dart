import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/child_profile.dart';
import '../../controllers/child_profile_controller.dart';
import '../../widgets/feedback/app_error_widget.dart';
import '../../widgets/feedback/loading_widget.dart';

/// Shows the parent linked to the current child, including name, email,
/// relationship, and link status.
class LinkedParentScreen extends ConsumerWidget {
  const LinkedParentScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<ChildProfile?> profileState =
        ref.watch(childProfileControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Linked Parent')),
      body: profileState.when(
        loading: () => const LoadingWidget(message: 'Loading...'),
        error: (Object error, _) => AppErrorWidget(
          message: error.toString(),
          onRetry: () =>
              ref.read(childProfileControllerProvider.notifier).refresh(),
        ),
        data: (ChildProfile? profile) {
          final LinkedParent? parent = profile?.linkedParent;
          if (parent == null) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Icon(Icons.link_off, size: 48),
                    SizedBox(height: 12),
                    Text('No parent is linked to this account.'),
                  ],
                ),
              ),
            );
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: <Widget>[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          const CircleAvatar(
                            child: Icon(Icons.person_outline),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  parent.fullName,
                                  style:
                                      Theme.of(context).textTheme.titleMedium,
                                ),
                                Text(
                                  parent.email,
                                  style:
                                      Theme.of(context).textTheme.bodySmall?.copyWith(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .outline,
                                          ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 24),
                      _DetailRow(
                        label: 'Relationship',
                        value: parent.relationship ?? 'Guardian',
                      ),
                      const SizedBox(height: 8),
                      _DetailRow(
                        label: 'Link Status',
                        value: parent.linkStatus.name,
                      ),
                    ],
                  ),
                ),
              ),
              if (parent.linkStatus != LinkStatus.linked)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Card(
                    color:
                        Theme.of(context).colorScheme.errorContainer,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        'Link status: ${parent.linkStatus.name}. '
                        'Contact your parent to complete the linking process.',
                        style: TextStyle(
                          color: Theme.of(context)
                              .colorScheme
                              .onErrorContainer,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
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
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }
}
