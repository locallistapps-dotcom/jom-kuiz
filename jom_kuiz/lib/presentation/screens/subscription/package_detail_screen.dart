import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routing/app_routes.dart';
import '../../../domain/entities/parent_subscription.dart';
import '../../../domain/entities/subject.dart';
import '../../../domain/entities/subscription_package.dart';
import '../../controllers/parent_controller.dart';
import '../../controllers/parent_subscription_controller.dart';
import '../../controllers/subject_controller.dart';
import '../../widgets/feedback/loading_widget.dart';

/// Shows the full details of a [SubscriptionPackage].
///
/// The "Subscribe" button is disabled until the Payment module is implemented.
class PackageDetailScreen extends ConsumerWidget {
  const PackageDetailScreen({super.key, required this.package});

  final SubscriptionPackage package;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileState = ref.watch(parentControllerProvider);
    final subjectsState = ref.watch(subjectControllerProvider);

    final String parentId =
        profileState.valueOrNull?.parentId ?? '';
    final AsyncValue<ParentSubscription?> subState =
        ref.watch(parentSubscriptionControllerProvider(parentId));

    final bool isCurrent = subState.valueOrNull?.packageId == package.id &&
        (subState.valueOrNull?.isActive ?? false);

    // Build a quick lookup map once subjects load.
    final Map<String, String> subjectNames = <String, String>{};
    subjectsState.whenData((List<Subject> subjects) {
      for (final Subject s in subjects) {
        subjectNames[s.subjectId] = s.subjectName;
      }
    });

    return Scaffold(
      appBar: AppBar(title: Text(package.name)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          // ── Price + duration banner ──────────────────────────────────────
          Card(
            color: Theme.of(context).colorScheme.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: <Widget>[
                  Text(
                    package.priceDisplay,
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onPrimaryContainer,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  Text(
                    'for ${package.durationDays} days',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onPrimaryContainer,
                        ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ── Description ──────────────────────────────────────────────────
          if (package.description != null) ...<Widget>[
            Text('About', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            Text(
              package.description!,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
          ],

          // ── Benefits ─────────────────────────────────────────────────────
          Text('Package Benefits',
              style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          _BenefitRow(
            icon: Icons.child_care_outlined,
            label:
                'Up to ${package.maxChildren} child${package.maxChildren == 1 ? '' : 'ren'}',
          ),
          _BenefitRow(
            icon: Icons.calendar_today_outlined,
            label: '${package.durationDays}-day access',
          ),
          _BenefitRow(
            icon: Icons.menu_book_outlined,
            label:
                '${package.includedSubjectIds.length} subject${package.includedSubjectIds.length == 1 ? '' : 's'} included',
          ),
          const SizedBox(height: 16),

          // ── Included subjects ────────────────────────────────────────────
          Text('Included Subjects',
              style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          if (package.includedSubjectIds.isEmpty)
            Text(
              'No subjects assigned yet.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
            )
          else
            ...package.includedSubjectIds.map((String id) {
              final String name = subjectNames[id] ?? id;
              return ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.check_circle_outline,
                    color: Colors.green, size: 20),
                title: subjectsState.isLoading
                    ? const LoadingWidget(message: '')
                    : Text(name),
              );
            }),
          const SizedBox(height: 32),

          // ── Subscribe button ──────────────────────────────────────────────
          if (isCurrent)
            FilledButton.icon(
              onPressed: null,
              icon: const Icon(Icons.verified_outlined),
              label: const Text('Currently Subscribed'),
            )
          else
            FilledButton.icon(
              onPressed: package.priceCents > 0
                  ? () => context.push(
                        AppRoutes.paymentCheckout,
                        extra: package,
                      )
                  : null,
              icon: const Icon(Icons.payment_outlined),
              label: Text(package.priceCents > 0
                  ? 'Subscribe — ${package.priceDisplay}'
                  : 'Contact support to activate'),
            ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _BenefitRow extends StatelessWidget {
  const _BenefitRow({super.key, required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: <Widget>[
          Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}
