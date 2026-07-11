import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routing/app_routes.dart';
import '../../../domain/entities/child_profile.dart';
import '../../controllers/child_profile_controller.dart';
import '../../widgets/feedback/app_error_widget.dart';
import '../../widgets/feedback/loading_widget.dart';

/// Displays the child's full profile in read-only mode.
/// Navigate to [AppRoutes.childEditProfile] to make changes.
class ChildProfileScreen extends ConsumerWidget {
  const ChildProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<ChildProfile?> profileState =
        ref.watch(childProfileControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Child Profile'),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit',
            onPressed: () => context.push(AppRoutes.childEditProfile),
          ),
        ],
      ),
      body: profileState.when(
        loading: () => const LoadingWidget(message: 'Loading profile...'),
        error: (Object error, _) => AppErrorWidget(
          message: error.toString(),
          onRetry: () =>
              ref.read(childProfileControllerProvider.notifier).refresh(),
        ),
        data: (ChildProfile? profile) {
          if (profile == null) {
            return const AppErrorWidget(message: 'Profile unavailable');
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: <Widget>[
              Center(
                child: CircleAvatar(
                  radius: 44,
                  backgroundImage: profile.profilePhoto != null
                      ? NetworkImage(profile.profilePhoto!)
                      : null,
                  child: profile.profilePhoto == null
                      ? const Icon(Icons.child_care, size: 36)
                      : null,
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  profile.fullName,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
              Center(
                child: Text(
                  '@${profile.username}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                ),
              ),
              const SizedBox(height: 24),
              _ProfileSection(
                title: 'Personal',
                children: <Widget>[
                  _ProfileTile(
                    label: 'Gender',
                    value: profile.gender ?? 'Not set',
                  ),
                  _ProfileTile(
                    label: 'Birthday',
                    value: profile.dateOfBirth == null
                        ? 'Not set'
                        : _formatDate(profile.dateOfBirth!),
                  ),
                  _ProfileTile(label: 'Bio', value: profile.bio ?? '—'),
                ],
              ),
              const SizedBox(height: 16),
              _ProfileSection(
                title: 'Education',
                children: <Widget>[
                  _ProfileTile(
                    label: 'School',
                    value: profile.school ?? 'Not set',
                  ),
                  _ProfileTile(
                    label: 'Grade / Class',
                    value: profile.grade ?? 'Not set',
                  ),
                ],
              ),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Edit Profile'),
                onPressed: () => context.push(AppRoutes.childEditProfile),
              ),
            ],
          );
        },
      ),
    );
  }

  String _formatDate(DateTime date) =>
      '${date.year}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}

class _ProfileSection extends StatelessWidget {
  const _ProfileSection({super.key, required this.title, required this.children});
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(title, style: Theme.of(context).textTheme.titleSmall),
            const Divider(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _ProfileTile extends StatelessWidget {
  const _ProfileTile({super.key, required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
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
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}
