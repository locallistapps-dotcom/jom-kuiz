import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routing/app_routes.dart';
import '../../../data/models/account_management_models.dart';
import '../../../domain/entities/education_level.dart';
import '../../controllers/child_management_controller.dart';
import '../../controllers/children_list_controller.dart';
import '../../providers/child_providers.dart';
import '../../widgets/feedback/app_error_widget.dart';
import '../../widgets/feedback/loading_widget.dart';
import '../../widgets/inputs/password_field.dart';
import '../../widgets/buttons/primary_button.dart';

/// Full management screen for a single child — shown when the parent taps a
/// child card in the Children List.
///
/// Displays profile details, account status toggle, performance links, and a
/// password reset action.
class ChildManagementScreen extends ConsumerWidget {
  const ChildManagementScreen({super.key, required this.childId});

  final String childId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<ChildManagementModel> state =
        ref.watch(childManagementControllerProvider(childId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Child Management'),
        actions: <Widget>[
          state.whenOrNull(
            data: (ChildManagementModel _model) => IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Edit',
              onPressed: () async {
                await context.push(AppRoutes.editChild, extra: childId);
                if (context.mounted) {
                  ref
                      .read(childManagementControllerProvider(childId).notifier)
                      .refresh();
                }
              },
            ),
          ) ?? const SizedBox.shrink(),
        ],
      ),
      body: state.when(
        loading: () => const LoadingWidget(message: 'Loading child...'),
        error: (Object err, _) => AppErrorWidget(
          message: err.toString(),
          onRetry: () => ref
              .read(childManagementControllerProvider(childId).notifier)
              .refresh(),
        ),
        data: (ChildManagementModel model) => _ChildManagementBody(
          model: model,
          childId: childId,
        ),
      ),
    );
  }
}

// ── Body ──────────────────────────────────────────────────────────────────────

class _ChildManagementBody extends ConsumerWidget {
  const _ChildManagementBody({
    super.key,
    required this.model,
    required this.childId,
  });

  final ChildManagementModel model;
  final String childId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool isActive = model.accountStatus == ChildAccountStatus.active.name;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        // ── Avatar + name ─────────────────────────────────────────────────
        _ProfileHeader(model: model),
        const SizedBox(height: 20),

        // ── Profile card ──────────────────────────────────────────────────
        _InfoCard(
          title: 'Profile',
          children: <Widget>[
            _InfoRow(label: 'Student ID', value: model.studentId),
            _InfoRow(label: 'Username', value: '@${model.username}'),
            _InfoRow(
              label: 'Education',
              value: EducationLevelHelper.labelFor(
                  EducationLevelHelper.fromString(model.educationLevel)),
            ),
            _InfoRow(label: 'Year / Grade', value: model.yearGrade),
            _InfoRow(
              label: 'Created',
              value: _formatDate(model.createdAt),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // ── Account status ────────────────────────────────────────────────
        _StatusCard(
          isActive: isActive,
          childId: childId,
          model: model,
        ),
        const SizedBox(height: 16),

        // ── Performance links ─────────────────────────────────────────────
        _InfoCard(
          title: 'Performance',
          children: <Widget>[
            _NavTile(
              icon: Icons.bar_chart_outlined,
              label: 'Performance Dashboard',
              onTap: () {
                ref.read(currentChildIdProvider.notifier).state = childId;
                context.push(AppRoutes.performanceSummary);
              },
            ),
            _NavTile(
              icon: Icons.history_outlined,
              label: 'Quiz History',
              onTap: () {
                ref.read(currentChildIdProvider.notifier).state = childId;
                context.push(AppRoutes.performanceSummary);
              },
            ),
            _NavTile(
              icon: Icons.trending_down_outlined,
              label: 'Weak Topics',
              onTap: () {
                ref.read(currentChildIdProvider.notifier).state = childId;
                context.push(AppRoutes.performanceSummary);
              },
            ),
          ],
        ),
        const SizedBox(height: 16),

        // ── Password reset ────────────────────────────────────────────────
        _PasswordResetCard(childId: childId),
      ],
    );
  }

  String _formatDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({super.key, required this.model});
  final ChildManagementModel model;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        CircleAvatar(
          radius: 40,
          backgroundImage: model.profilePhoto != null
              ? NetworkImage(model.profilePhoto!)
              : null,
          child: model.profilePhoto == null
              ? const Icon(Icons.child_care, size: 36)
              : null,
        ),
        const SizedBox(height: 12),
        Text(model.fullName, style: Theme.of(context).textTheme.headlineSmall),
        Text(
          'Student ID: ${model.studentId}',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
        ),
      ],
    );
  }
}

class _StatusCard extends ConsumerWidget {
  const _StatusCard({
    super.key,
    required this.isActive,
    required this.childId,
    required this.model,
  });

  final bool isActive;
  final String childId;
  final ChildManagementModel model;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('Account Status',
                style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 12),
            Row(
              children: <Widget>[
                Icon(
                  isActive ? Icons.check_circle_outline : Icons.block_outlined,
                  color:
                      isActive ? Colors.green : Theme.of(context).colorScheme.error,
                ),
                const SizedBox(width: 8),
                Text(
                  isActive ? 'Active' : 'Disabled',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: isActive
                            ? Colors.green
                            : Theme.of(context).colorScheme.error,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => _confirmToggle(context, ref, isActive),
                  child: Text(isActive ? 'Disable' : 'Enable'),
                ),
              ],
            ),
            if (!isActive)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Disabled accounts cannot log in. Quiz history is preserved.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmToggle(
      BuildContext context, WidgetRef ref, bool currentlyActive) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: Text(currentlyActive ? 'Disable Account?' : 'Enable Account?'),
        content: Text(currentlyActive
            ? '${model.fullName} will not be able to log in until re-enabled.'
            : 'Re-enabling ${model.fullName}\'s account allows them to log in again.'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(currentlyActive ? 'Disable' : 'Enable'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    final newStatus =
        currentlyActive ? ChildAccountStatus.disabled : ChildAccountStatus.active;

    final result = await ref
        .read(childManagementControllerProvider(childId).notifier)
        .setStatus(newStatus);

    if (!context.mounted) return;
    result.when(
      success: (_) {
        ref.read(childrenListControllerProvider.notifier).refresh();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(newStatus == ChildAccountStatus.active
                ? 'Account enabled'
                : 'Account disabled'),
          ),
        );
      },
      failure: (f) => ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(f.toString()))),
    );
  }
}

class _PasswordResetCard extends ConsumerStatefulWidget {
  const _PasswordResetCard({super.key, required this.childId});
  final String childId;

  @override
  ConsumerState<_PasswordResetCard> createState() => _PasswordResetCardState();
}

class _PasswordResetCardState extends ConsumerState<_PasswordResetCard> {
  bool _expanded = false;
  final TextEditingController _pwdController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();
  bool _isResetting = false;

  @override
  void dispose() {
    _pwdController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _reset() async {
    if (_pwdController.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password must be at least 6 characters')),
      );
      return;
    }
    if (_pwdController.text != _confirmController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match')),
      );
      return;
    }

    setState(() => _isResetting = true);
    final result = await ref
        .read(childManagementControllerProvider(widget.childId).notifier)
        .resetPassword(_pwdController.text);
    if (!mounted) return;
    setState(() => _isResetting = false);

    result.when(
      success: (_) {
        setState(() => _expanded = false);
        _pwdController.clear();
        _confirmController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password reset successfully')),
        );
      },
      failure: (f) => ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(f.toString()))),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Text('Password', style: Theme.of(context).textTheme.titleSmall),
                const Spacer(),
                TextButton.icon(
                  icon: Icon(_expanded ? Icons.close : Icons.lock_reset_outlined,
                      size: 18),
                  label: Text(_expanded ? 'Cancel' : 'Reset'),
                  onPressed: () => setState(() {
                    _expanded = !_expanded;
                    if (!_expanded) {
                      _pwdController.clear();
                      _confirmController.clear();
                    }
                  }),
                ),
              ],
            ),
            if (_expanded) ...<Widget>[
              const SizedBox(height: 12),
              PasswordField(label: 'New Password', controller: _pwdController),
              const SizedBox(height: 12),
              PasswordField(
                  label: 'Confirm Password', controller: _confirmController),
              const SizedBox(height: 16),
              PrimaryButton(
                label: 'Set New Password',
                isLoading: _isResetting,
                onPressed: _reset,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({super.key, required this.title, required this.children});
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

class _InfoRow extends StatelessWidget {
  const _InfoRow({super.key, required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
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
            child: Text(value, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}

class _NavTile extends StatelessWidget {
  const _NavTile({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, size: 20),
      title: Text(label),
      trailing: const Icon(Icons.chevron_right, size: 18),
      onTap: onTap,
    );
  }
}
