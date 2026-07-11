import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routing/app_routes.dart';
import '../../../domain/entities/parent_subscription.dart';
import '../../../domain/entities/subscription_package.dart';
import '../../controllers/parent_controller.dart';
import '../../controllers/parent_subscription_controller.dart';
import '../../controllers/subscription_package_controller.dart';
import '../../widgets/feedback/app_error_widget.dart';
import '../../widgets/feedback/loading_widget.dart';

/// Parent Subscription screen.
///
/// Shows the current subscription status, available packages for browsing,
/// and links to purchased / locked subjects. Payment is not yet implemented —
/// "Subscribe" buttons show a "Coming soon" state.
class SubscriptionScreen extends ConsumerWidget {
  const SubscriptionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileState = ref.watch(parentControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Subscription')),
      body: profileState.when(
        loading: () => const LoadingWidget(message: 'Loading...'),
        error: (err, _) => AppErrorWidget(message: err.toString()),
        data: (profile) {
          if (profile == null) {
            return const AppErrorWidget(message: 'Profile unavailable');
          }
          return _SubscriptionBody(parentId: profile.parentId);
        },
      ),
    );
  }
}

class _SubscriptionBody extends ConsumerWidget {
  const _SubscriptionBody({super.key, required this.parentId});
  final String parentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subState = ref.watch(parentSubscriptionControllerProvider(parentId));
    final pkgState = ref.watch(subscriptionPackageControllerProvider(true));

    return RefreshIndicator(
      onRefresh: () async {
        ref
            .read(parentSubscriptionControllerProvider(parentId).notifier)
            .refresh();
        ref
            .read(subscriptionPackageControllerProvider(true).notifier)
            .refresh();
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          // ── Current subscription ─────────────────────────────────────────
          _CurrentSubscriptionCard(
            subState: subState,
            parentId: parentId,
          ),
          const SizedBox(height: 16),

          // ── Quick links ──────────────────────────────────────────────────
          Row(
            children: <Widget>[
              Expanded(
                child: _QuickLinkCard(
                  icon: Icons.lock_open_outlined,
                  label: 'Purchased Subjects',
                  color: Theme.of(context).colorScheme.primaryContainer,
                  onTap: () =>
                      context.push(AppRoutes.purchasedSubjects, extra: parentId),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _QuickLinkCard(
                  icon: Icons.lock_outlined,
                  label: 'Locked Subjects',
                  color: Theme.of(context).colorScheme.errorContainer,
                  onTap: () =>
                      context.push(AppRoutes.lockedSubjects, extra: parentId),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // ── Available packages ───────────────────────────────────────────
          Text('Available Packages',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          pkgState.when(
            loading: () =>
                const LoadingWidget(message: 'Loading packages...'),
            error: (err, _) => AppErrorWidget(message: err.toString()),
            data: (List<SubscriptionPackage> packages) {
              if (packages.isEmpty) {
                return const _EmptyPackages();
              }
              return Column(
                children: packages
                    .map((SubscriptionPackage pkg) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _PackageCard(
                            package: pkg,
                            currentSubscription: subState.valueOrNull,
                          ),
                        ))
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _CurrentSubscriptionCard extends StatelessWidget {
  const _CurrentSubscriptionCard({
    super.key,
    required this.subState,
    required this.parentId,
  });

  final AsyncValue<ParentSubscription?> subState;
  final String parentId;

  @override
  Widget build(BuildContext context) {
    return subState.when(
      loading: () => const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (err, _) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text('Error: $err'),
        ),
      ),
      data: (ParentSubscription? sub) {
        final bool active = sub != null && sub.isActive;
        final ColorScheme cs = Theme.of(context).colorScheme;

        return Card(
          color: active ? cs.primaryContainer : cs.surfaceContainerHighest,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Icon(
                      active
                          ? Icons.verified_outlined
                          : Icons.info_outline_rounded,
                      color: active ? cs.onPrimaryContainer : cs.outline,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      active ? 'Active Subscription' : 'No Active Subscription',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: active
                                ? cs.onPrimaryContainer
                                : cs.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
                if (active && sub != null) ...<Widget>[
                  const SizedBox(height: 12),
                  _SubInfoRow(
                    label: 'Expires',
                    value: _formatDate(sub.expiryDate),
                  ),
                  _SubInfoRow(
                    label: 'Days remaining',
                    value: '${sub.daysRemaining} days',
                  ),
                  _SubInfoRow(
                    label: 'Status',
                    value: sub.status.displayLabel,
                  ),
                ] else ...<Widget>[
                  const SizedBox(height: 8),
                  Text(
                    'Browse the packages below and subscribe to unlock subjects '
                    'for all your children.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}

class _SubInfoRow extends StatelessWidget {
  const _SubInfoRow({super.key, required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: <Widget>[
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickLinkCard extends StatelessWidget {
  const _QuickLinkCard({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: color,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          child: Column(
            children: <Widget>[
              Icon(icon, size: 28),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PackageCard extends StatelessWidget {
  const _PackageCard({
    super.key,
    required this.package,
    required this.currentSubscription,
  });
  final SubscriptionPackage package;
  final ParentSubscription? currentSubscription;

  @override
  Widget build(BuildContext context) {
    final bool isCurrent =
        currentSubscription?.packageId == package.id &&
            currentSubscription!.isActive;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () =>
            context.push(AppRoutes.packageDetail, extra: package),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      package.name,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ),
                  if (isCurrent)
                    Chip(
                      label: const Text('Current'),
                      backgroundColor:
                          Theme.of(context).colorScheme.primaryContainer,
                      labelStyle: TextStyle(
                        fontSize: 11,
                        color: Theme.of(context)
                            .colorScheme
                            .onPrimaryContainer,
                      ),
                    )
                  else
                    Text(
                      package.priceDisplay,
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                          ),
                    ),
                ],
              ),
              if (package.description != null) ...<Widget>[
                const SizedBox(height: 4),
                Text(
                  package.description!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: <Widget>[
                  _InfoChip(
                    icon: Icons.calendar_today_outlined,
                    label: '${package.durationDays} days',
                  ),
                  _InfoChip(
                    icon: Icons.child_care_outlined,
                    label: 'Up to ${package.maxChildren} children',
                  ),
                  _InfoChip(
                    icon: Icons.menu_book_outlined,
                    label:
                        '${package.includedSubjectIds.length} subject(s)',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({super.key, required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(icon,
            size: 14, color: Theme.of(context).colorScheme.outline),
        const SizedBox(width: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
        ),
      ],
    );
  }
}

class _EmptyPackages extends StatelessWidget {
  const _EmptyPackages({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: <Widget>[
            Icon(Icons.inventory_2_outlined,
                size: 48,
                color: Theme.of(context).colorScheme.outline),
            const SizedBox(height: 12),
            Text(
              'No packages available yet.',
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
