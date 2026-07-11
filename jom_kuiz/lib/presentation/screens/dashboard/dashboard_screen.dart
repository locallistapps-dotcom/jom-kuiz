import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/extension_points/module_placeholders.dart';
import '../../../core/routing/app_routes.dart';
import '../../../domain/entities/parent_profile.dart';
import '../../controllers/parent_controller.dart';
import '../../controllers/session_controller.dart';
import '../../providers/child_providers.dart';
import '../../widgets/cards/placeholder_module_card.dart';
import '../../widgets/feedback/app_error_widget.dart';
import '../../widgets/feedback/loading_widget.dart';

/// Parent Dashboard — the landing screen after login.
///
/// Shows the parent's own profile summary plus a live "Children" card that
/// navigates into the Child module, and placeholder cards for every module
/// that has not shipped yet.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<ParentProfile?> profileState =
        ref.watch(parentControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings',
            onPressed: () => context.push(AppRoutes.settings),
          ),
          IconButton(
            icon: const Icon(Icons.logout_outlined),
            tooltip: 'Logout',
            onPressed: () =>
                ref.read(sessionControllerProvider.notifier).logout(),
          ),
        ],
      ),
      body: profileState.when(
        loading: () =>
            const LoadingWidget(message: 'Loading your dashboard...'),
        error: (Object error, _) => AppErrorWidget(
          message: error.toString(),
          onRetry: () =>
              ref.read(parentControllerProvider.notifier).refresh(),
        ),
        data: (ParentProfile? profile) {
          if (profile == null) {
            return const AppErrorWidget(message: 'Profile unavailable');
          }
          return RefreshIndicator(
            onRefresh: () =>
                ref.read(parentControllerProvider.notifier).refresh(),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: <Widget>[
                _WelcomeCard(profile: profile),
                const SizedBox(height: 12),
                _ProfileCard(profile: profile),
                const SizedBox(height: 20),
                Text('Overview',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                // Children card — wired to the Child module.
                const _ChildrenCard(),
                const SizedBox(height: 8),
                const PlaceholderModuleCard(
                    module: PlaceholderModule.subscription),
                const SizedBox(height: 8),
                const PlaceholderModuleCard(module: PlaceholderModule.wallet),
                const SizedBox(height: 8),
                const PlaceholderModuleCard(
                    module: PlaceholderModule.referral),
                const SizedBox(height: 8),
                const PlaceholderModuleCard(
                    module: PlaceholderModule.latestActivity),
                const SizedBox(height: 20),
                Text('Quick Actions',
                    style: Theme.of(context).textTheme.titleMedium),
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
  final ParentProfile profile;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          'Welcome back, ${profile.fullName}!',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
        ),
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({super.key, required this.profile});
  final ParentProfile profile;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          radius: 24,
          backgroundImage: profile.profilePhoto != null
              ? NetworkImage(profile.profilePhoto!)
              : null,
          child: profile.profilePhoto == null
              ? const Icon(Icons.person_outline)
              : null,
        ),
        title: Text(profile.fullName),
        subtitle: Text(profile.email),
        trailing: TextButton(
          onPressed: () => context.push(AppRoutes.editProfile),
          child: const Text('Edit'),
        ),
      ),
    );
  }
}

/// Tappable card that navigates into the Child module.
///
/// Sets [currentChildIdProvider] to a demo ID so child controllers load.
/// In a future "Children List" milestone this will navigate to a real picker.
class _ChildrenCard extends ConsumerWidget {
  const _ChildrenCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.child_care,
            size: 20,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        title: const Text('Children'),
        subtitle: const Text('Manage linked children'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          // Set a placeholder child ID; the Children List module (future
          // prompt) will replace this with a real selection flow.
          ref.read(currentChildIdProvider.notifier).state = 'demo-child-id';
          context.push(AppRoutes.childDashboard);
        },
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
          avatar: const Icon(Icons.edit_outlined, size: 18),
          label: const Text('Edit Profile'),
          onPressed: () => context.push(AppRoutes.editProfile),
        ),
        ActionChip(
          avatar: const Icon(Icons.lock_outline, size: 18),
          label: const Text('Security'),
          onPressed: () => context.push(AppRoutes.security),
        ),
        ActionChip(
          avatar: const Icon(Icons.settings_outlined, size: 18),
          label: const Text('Settings'),
          onPressed: () => context.push(AppRoutes.settings),
        ),
      ],
    );
  }
}
