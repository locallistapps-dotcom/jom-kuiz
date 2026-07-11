import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/di/providers.dart';
import '../../../domain/entities/parent_subscription.dart';
import '../../../domain/entities/subject.dart';
import '../../../domain/entities/subject_access.dart';
import '../../../domain/entities/subscription_package.dart';
import '../../controllers/subject_controller.dart';
import '../../controllers/subscription_package_controller.dart';

// ── Lightweight data classes (admin-only) ─────────────────────────────────────

class _Parent {
  const _Parent({required this.id, required this.fullName, required this.email});
  final String id;
  final String fullName;
  final String email;
}

class _AdminSubData {
  const _AdminSubData({this.subscription, required this.access});
  final ParentSubscription? subscription;
  final List<SubjectAccess> access;
}

// ── Providers ─────────────────────────────────────────────────────────────────

/// The email search string typed by the admin.
final _searchQueryProvider = StateProvider<String>((ref) => '');

/// The parent the admin has selected to manage.
final _selectedParentProvider = StateProvider<_Parent?>((ref) => null);

/// A refresh counter so we can force-reload the parent's sub data.
final _subDataRefreshProvider = StateProvider<int>((ref) => 0);

/// Search results: parents matching the query email substring.
final _parentSearchResultsProvider =
    FutureProvider.autoDispose<List<_Parent>>((ref) async {
  final String query = ref.watch(_searchQueryProvider).trim();
  if (query.length < 3) return <_Parent>[];
  final Dio dio = ref.watch(dioProvider);
  final Response<dynamic> res = await dio.get<dynamic>(
    '/parents',
    queryParameters: <String, dynamic>{
      'select': 'id,full_name,email',
      'email': 'ilike.*${query.toLowerCase()}*',
      'order': 'email.asc',
      'limit': '20',
    },
  );
  final List<dynamic> list = res.data as List<dynamic>;
  return list.map((dynamic e) {
    final Map<String, dynamic> m = e as Map<String, dynamic>;
    return _Parent(
      id: m['id'] as String,
      fullName: m['full_name'] as String,
      email: m['email'] as String,
    );
  }).toList();
});

/// The selected parent's current subscription + subject access.
final _adminSubDataProvider =
    FutureProvider.autoDispose.family<_AdminSubData, String>((ref, parentId) async {
  // Watch refresh counter so callers can invalidate.
  ref.watch(_subDataRefreshProvider);
  final Dio dio = ref.watch(dioProvider);

  final List<Response<dynamic>> responses = await Future.wait(<Future<Response<dynamic>>>[
    dio.get<dynamic>(
      '/parent_subscriptions',
      queryParameters: <String, dynamic>{
        'parent_id': 'eq.$parentId',
        'order': 'created_at.desc',
        'limit': '1',
      },
    ),
    dio.get<dynamic>(
      '/parent_subject_access',
      queryParameters: <String, dynamic>{
        'parent_id': 'eq.$parentId',
        'order': 'granted_at.asc',
      },
    ),
  ]);

  final List<dynamic> subList = responses[0].data as List<dynamic>;
  final List<dynamic> accessList = responses[1].data as List<dynamic>;

  ParentSubscription? subscription;
  if (subList.isNotEmpty) {
    final Map<String, dynamic> s = subList.first as Map<String, dynamic>;
    subscription = ParentSubscription(
      id: s['id'] as String,
      parentId: s['parent_id'] as String,
      packageId: s['package_id'] as String,
      startDate: DateTime.parse(s['start_date'] as String),
      expiryDate: DateTime.parse(s['expiry_date'] as String),
      status: ParentSubscriptionStatusX.fromString(s['status'] as String),
      autoRenew: s['auto_renew'] as bool? ?? false,
      createdAt: DateTime.parse(s['created_at'] as String),
      updatedAt: DateTime.parse(s['updated_at'] as String),
    );
  }

  final List<SubjectAccess> access = accessList.map((dynamic e) {
    final Map<String, dynamic> m = e as Map<String, dynamic>;
    return SubjectAccess(
      id: m['id'] as String,
      parentId: m['parent_id'] as String,
      subjectId: m['subject_id'] as String,
      grantedAt: DateTime.parse(m['granted_at'] as String),
      source: SubjectAccessSourceX.fromString(m['source'] as String? ?? 'manual'),
      expiresAt:
          m['expires_at'] != null ? DateTime.parse(m['expires_at'] as String) : null,
    );
  }).toList();

  return _AdminSubData(subscription: subscription, access: access);
});

// ── Screen ────────────────────────────────────────────────────────────────────

/// Admin screen for managing parent subscriptions.
///
/// Features:
/// • Search parents by email
/// • View current subscription (package, status, expiry)
/// • Assign / change subscription package
/// • Activate / deactivate subscription
/// • Extend expiry date with date picker
/// • Grant or revoke individual subject access
class AdminSubscriptionScreen extends ConsumerStatefulWidget {
  const AdminSubscriptionScreen({super.key});

  @override
  ConsumerState<AdminSubscriptionScreen> createState() =>
      _AdminSubscriptionScreenState();
}

class _AdminSubscriptionScreenState
    extends ConsumerState<AdminSubscriptionScreen> {
  late final TextEditingController _searchCtrl;

  @override
  void initState() {
    super.initState();
    _searchCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearchChanged(String v) {
    ref.read(_searchQueryProvider.notifier).state = v;
    if (ref.read(_selectedParentProvider) != null) {
      ref.read(_selectedParentProvider.notifier).state = null;
    }
  }

  void _selectParent(_Parent p) {
    ref.read(_selectedParentProvider.notifier).state = p;
  }

  void _clearSelection() {
    ref.read(_selectedParentProvider.notifier).state = null;
  }

  @override
  Widget build(BuildContext context) {
    final _Parent? selected = ref.watch(_selectedParentProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Subscription Management'),
        actions: <Widget>[
          if (selected != null)
            TextButton.icon(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 14),
              label: const Text('Search'),
              onPressed: _clearSelection,
            ),
        ],
      ),
      body: selected == null ? _SearchView(onSelect: _selectParent, searchCtrl: _searchCtrl, onSearchChanged: _onSearchChanged) : _ParentDetailView(parent: selected),
    );
  }
}

// ── Search view ───────────────────────────────────────────────────────────────

class _SearchView extends ConsumerWidget {
  const _SearchView({
    required this.onSelect,
    required this.searchCtrl,
    required this.onSearchChanged,
  });
  final ValueChanged<_Parent> onSelect;
  final TextEditingController searchCtrl;
  final ValueChanged<String> onSearchChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<_Parent>> results =
        ref.watch(_parentSearchResultsProvider);
    final String query = ref.watch(_searchQueryProvider);

    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: searchCtrl,
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'Search by email…',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: query.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded),
                      onPressed: () {
                        searchCtrl.clear();
                        onSearchChanged('');
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12)),
              filled: true,
            ),
            onChanged: onSearchChanged,
          ),
        ),
        Expanded(
          child: results.when(
            loading: () =>
                const Center(child: CircularProgressIndicator()),
            error: (err, _) => Center(child: Text('Error: $err')),
            data: (List<_Parent> list) {
              if (query.length < 3) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Icon(Icons.manage_search_rounded,
                          size: 64,
                          color: Theme.of(context)
                              .colorScheme
                              .outlineVariant),
                      const SizedBox(height: 12),
                      Text('Enter at least 3 characters to search',
                          style: Theme.of(context).textTheme.bodyMedium),
                    ],
                  ),
                );
              }
              if (list.isEmpty) {
                return Center(
                  child: Text('No parents found for "$query"'),
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: list.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (_, int i) {
                  final _Parent p = list[i];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Theme.of(context)
                          .colorScheme
                          .primaryContainer,
                      child: Text(
                        p.fullName.isNotEmpty
                            ? p.fullName[0].toUpperCase()
                            : '?',
                        style: TextStyle(
                          color: Theme.of(context)
                              .colorScheme
                              .onPrimaryContainer,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(p.fullName),
                    subtitle: Text(p.email),
                    trailing:
                        const Icon(Icons.chevron_right_rounded),
                    onTap: () => onSelect(p),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

// ── Parent detail view ────────────────────────────────────────────────────────

class _ParentDetailView extends ConsumerWidget {
  const _ParentDetailView({required this.parent});
  final _Parent parent;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<_AdminSubData> subData =
        ref.watch(_adminSubDataProvider(parent.id));
    final AsyncValue<List<SubscriptionPackage>> pkgState =
        ref.watch(subscriptionPackageControllerProvider(null));
    final AsyncValue<List<Subject>> subjectState =
        ref.watch(subjectControllerProvider);

    return subData.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text('Error loading data: $err')),
      data: (_AdminSubData data) {
        final List<SubscriptionPackage> packages =
            pkgState.valueOrNull ?? <SubscriptionPackage>[];
        final List<Subject> subjects =
            subjectState.valueOrNull ?? <Subject>[];

        return RefreshIndicator(
          onRefresh: () async {
            ref
                .read(_subDataRefreshProvider.notifier)
                .update((int n) => n + 1);
          },
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: <Widget>[
              // Parent info card
              _ParentInfoCard(parent: parent),
              const SizedBox(height: 16),

              // Subscription card
              _SubscriptionCard(
                parent: parent,
                subscription: data.subscription,
                packages: packages,
                onRefresh: () => ref
                    .read(_subDataRefreshProvider.notifier)
                    .update((int n) => n + 1),
              ),
              const SizedBox(height: 16),

              // Subject access card
              _SubjectAccessCard(
                parent: parent,
                access: data.access,
                subjects: subjects,
                onRefresh: () => ref
                    .read(_subDataRefreshProvider.notifier)
                    .update((int n) => n + 1),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Parent info card ──────────────────────────────────────────────────────────

class _ParentInfoCard extends StatelessWidget {
  const _ParentInfoCard({required this.parent});
  final _Parent parent;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: <Widget>[
            CircleAvatar(
              radius: 26,
              backgroundColor: colors.primaryContainer,
              child: Text(
                parent.fullName.isNotEmpty
                    ? parent.fullName[0].toUpperCase()
                    : '?',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: colors.onPrimaryContainer,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(parent.fullName,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(parent.email,
                      style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: 2),
                  SelectableText(
                    'ID: ${parent.id}',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: colors.outline,
                          fontFamily: 'monospace',
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Subscription card ─────────────────────────────────────────────────────────

class _SubscriptionCard extends ConsumerStatefulWidget {
  const _SubscriptionCard({
    required this.parent,
    required this.subscription,
    required this.packages,
    required this.onRefresh,
  });
  final _Parent parent;
  final ParentSubscription? subscription;
  final List<SubscriptionPackage> packages;
  final VoidCallback onRefresh;

  @override
  ConsumerState<_SubscriptionCard> createState() =>
      _SubscriptionCardState();
}

class _SubscriptionCardState extends ConsumerState<_SubscriptionCard> {
  bool _saving = false;

  // ── Actions ──────────────────────────────────────────────────────────────

  Future<void> _assignPackage(SubscriptionPackage pkg) async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      final Dio dio = ref.read(dioProvider);
      final DateTime start = DateTime.now();
      final DateTime expiry =
          start.add(Duration(days: pkg.durationDays));

      if (widget.subscription == null) {
        // Create new subscription
        await dio.post<dynamic>(
          '/parent_subscriptions',
          data: <String, dynamic>{
            'parent_id': widget.parent.id,
            'package_id': pkg.id,
            'start_date':
                '${start.year.toString().padLeft(4, '0')}-${start.month.toString().padLeft(2, '0')}-${start.day.toString().padLeft(2, '0')}',
            'expiry_date':
                '${expiry.year.toString().padLeft(4, '0')}-${expiry.month.toString().padLeft(2, '0')}-${expiry.day.toString().padLeft(2, '0')}',
            'status': 'active',
            'auto_renew': false,
          },
          options: Options(
              headers: <String, String>{'Prefer': 'return=minimal'}),
        );
      } else {
        // Update existing subscription
        await dio.patch<dynamic>(
          '/parent_subscriptions',
          queryParameters: <String, dynamic>{
            'id': 'eq.${widget.subscription!.id}',
          },
          data: <String, dynamic>{
            'package_id': pkg.id,
            'expiry_date':
                '${expiry.year.toString().padLeft(4, '0')}-${expiry.month.toString().padLeft(2, '0')}-${expiry.day.toString().padLeft(2, '0')}',
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          },
          options: Options(
              headers: <String, String>{'Prefer': 'return=minimal'}),
        );
      }
      widget.onRefresh();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Package "${pkg.name}" assigned'),
          behavior: SnackBarBehavior.floating,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _toggleStatus() async {
    if (_saving || widget.subscription == null) return;
    final bool activate =
        widget.subscription!.status != ParentSubscriptionStatus.active;
    final String newStatus = activate ? 'active' : 'cancelled';

    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(activate ? 'Activate Subscription' : 'Deactivate Subscription'),
        content: Text(activate
            ? 'Set subscription status to active?'
            : 'Set subscription status to cancelled?'),
        actions: <Widget>[
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(activate ? 'Activate' : 'Deactivate')),
        ],
      ),
    );
    if (confirm != true) return;

    setState(() => _saving = true);
    try {
      final Dio dio = ref.read(dioProvider);
      await dio.patch<dynamic>(
        '/parent_subscriptions',
        queryParameters: <String, dynamic>{
          'id': 'eq.${widget.subscription!.id}',
        },
        data: <String, dynamic>{
          'status': newStatus,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        },
        options:
            Options(headers: <String, String>{'Prefer': 'return=minimal'}),
      );
      widget.onRefresh();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Subscription ${activate ? 'activated' : 'deactivated'}'),
          behavior: SnackBarBehavior.floating,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _extendExpiry() async {
    if (widget.subscription == null) return;
    final DateTime initial = widget.subscription!.expiryDate.isAfter(DateTime.now())
        ? widget.subscription!.expiryDate
        : DateTime.now().add(const Duration(days: 1));

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
      helpText: 'Select new expiry date',
    );
    if (picked == null) return;

    setState(() => _saving = true);
    try {
      final Dio dio = ref.read(dioProvider);
      final String dateStr =
          '${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      await dio.patch<dynamic>(
        '/parent_subscriptions',
        queryParameters: <String, dynamic>{
          'id': 'eq.${widget.subscription!.id}',
        },
        data: <String, dynamic>{
          'expiry_date': dateStr,
          'status': 'active',
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        },
        options:
            Options(headers: <String, String>{'Prefer': 'return=minimal'}),
      );
      widget.onRefresh();
      if (mounted) {
        final String fmt = DateFormat('dd MMM yyyy').format(picked);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Expiry extended to $fmt'),
          behavior: SnackBarBehavior.floating,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;
    final ParentSubscription? sub = widget.subscription;

    // Find package name
    String packageName = 'Unknown';
    if (sub != null) {
      final SubscriptionPackage? pkg = widget.packages
          .where((SubscriptionPackage p) => p.id == sub.packageId)
          .firstOrNull;
      packageName = pkg?.name ?? sub.packageId.substring(0, 8);
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(Icons.card_membership_rounded,
                    color: colors.primary, size: 20),
                const SizedBox(width: 8),
                Text('Subscription',
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w600)),
              ],
            ),
            const Divider(height: 20),

            if (sub == null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text('No subscription found',
                    style: TextStyle(color: colors.outline)),
              )
            else ...<Widget>[
              _InfoRow(label: 'Package', value: packageName),
              _InfoRow(
                label: 'Status',
                valueWidget: _StatusChip(status: sub.status),
              ),
              _InfoRow(
                label: 'Expiry',
                value:
                    '${DateFormat('dd MMM yyyy').format(sub.expiryDate)}  (${sub.daysRemaining}d remaining)',
              ),
              _InfoRow(
                label: 'Start',
                value: DateFormat('dd MMM yyyy').format(sub.startDate),
              ),
            ],

            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),

            // Assign package
            Text('Assign Package',
                style: theme.textTheme.labelMedium
                    ?.copyWith(color: colors.outline)),
            const SizedBox(height: 8),
            if (widget.packages.isEmpty)
              const Text('No packages available')
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: widget.packages.map((SubscriptionPackage pkg) {
                  final bool isCurrent =
                      sub?.packageId == pkg.id;
                  return ActionChip(
                    avatar: isCurrent
                        ? Icon(Icons.check_circle_rounded,
                            size: 16, color: colors.primary)
                        : null,
                    label: Text(
                        '${pkg.name} (${_fmtPrice(pkg.priceCents)})'),
                    onPressed: _saving
                        ? null
                        : () => _assignPackage(pkg),
                    backgroundColor: isCurrent
                        ? colors.primaryContainer
                        : null,
                  );
                }).toList(),
              ),

            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),

            // Action buttons
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                if (sub != null) ...<Widget>[
                  FilledButton.tonal(
                    onPressed: _saving ? null : _toggleStatus,
                    child: _saving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2))
                        : Text(
                            sub.status ==
                                    ParentSubscriptionStatus.active
                                ? 'Deactivate'
                                : 'Activate'),
                  ),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.calendar_today_rounded,
                        size: 16),
                    label: const Text('Extend Expiry'),
                    onPressed: _saving ? null : _extendExpiry,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _fmtPrice(int cents) {
    if (cents == 0) return 'Free';
    return 'RM ${(cents / 100).toStringAsFixed(2)}';
  }
}

// ── Subject access card ───────────────────────────────────────────────────────

class _SubjectAccessCard extends ConsumerStatefulWidget {
  const _SubjectAccessCard({
    required this.parent,
    required this.access,
    required this.subjects,
    required this.onRefresh,
  });
  final _Parent parent;
  final List<SubjectAccess> access;
  final List<Subject> subjects;
  final VoidCallback onRefresh;

  @override
  ConsumerState<_SubjectAccessCard> createState() =>
      _SubjectAccessCardState();
}

class _SubjectAccessCardState extends ConsumerState<_SubjectAccessCard> {
  final Set<String> _loading = <String>{};

  Future<void> _grantAccess(Subject subject) async {
    setState(() => _loading.add(subject.subjectId));
    try {
      final Dio dio = ref.read(dioProvider);
      final DateTime expiry =
          DateTime.now().add(const Duration(days: 365));
      await dio.post<dynamic>(
        '/parent_subject_access',
        data: <String, dynamic>{
          'parent_id': widget.parent.id,
          'subject_id': subject.subjectId,
          'source': 'manual',
          'expires_at': expiry.toIso8601String(),
        },
        options: Options(headers: <String, String>{
          'Prefer': 'return=minimal,resolution=ignore-duplicates',
        }),
      );
      widget.onRefresh();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('${subject.subjectName} access granted'),
          behavior: SnackBarBehavior.floating,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } finally {
      if (mounted) setState(() => _loading.remove(subject.subjectId));
    }
  }

  Future<void> _revokeAccess(SubjectAccess access) async {
    setState(() => _loading.add(access.subjectId));
    try {
      final Dio dio = ref.read(dioProvider);
      await dio.delete<dynamic>(
        '/parent_subject_access',
        queryParameters: <String, dynamic>{'id': 'eq.${access.id}'},
      );
      widget.onRefresh();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Subject access revoked'),
          behavior: SnackBarBehavior.floating,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } finally {
      if (mounted) setState(() => _loading.remove(access.subjectId));
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;

    // Build map: subjectId → SubjectAccess
    final Map<String, SubjectAccess> accessMap = <String, SubjectAccess>{
      for (final SubjectAccess a in widget.access) a.subjectId: a,
    };

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(Icons.lock_open_rounded,
                    color: colors.tertiary, size: 20),
                const SizedBox(width: 8),
                Text('Subject Access',
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w600)),
                const Spacer(),
                Text('${widget.access.length} granted',
                    style: theme.textTheme.labelSmall
                        ?.copyWith(color: colors.outline)),
              ],
            ),
            const Divider(height: 20),

            if (widget.subjects.isEmpty)
              const Text('No subjects in catalogue yet')
            else
              ...widget.subjects.map((Subject subject) {
                final SubjectAccess? granted =
                    accessMap[subject.subjectId];
                final bool isLoading =
                    _loading.contains(subject.subjectId);
                final bool hasAccess = granted?.isValid ?? false;

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: <Widget>[
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: hasAccess
                            ? colors.tertiaryContainer
                            : colors.surfaceContainerHighest,
                        child: Text(
                          subject.icon ?? '📚',
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(subject.subjectName,
                                style: theme.textTheme.bodyMedium
                                    ?.copyWith(
                                        fontWeight: FontWeight.w500)),
                            if (granted != null)
                              Text(
                                granted.isValid
                                    ? '${granted.source.name}  •  expires ${granted.expiresAt != null ? DateFormat('dd MMM yyyy').format(granted.expiresAt!) : 'never'}'
                                    : 'Expired',
                                style:
                                    theme.textTheme.labelSmall?.copyWith(
                                  color: granted.isValid
                                      ? colors.outline
                                      : colors.error,
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2))
                          : hasAccess
                              ? OutlinedButton(
                                  onPressed: () =>
                                      _revokeAccess(granted!),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: colors.error,
                                    side: BorderSide(
                                        color: colors.error),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 4),
                                    minimumSize: Size.zero,
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                    textStyle:
                                        theme.textTheme.labelSmall,
                                  ),
                                  child: const Text('Revoke'),
                                )
                              : FilledButton(
                                  onPressed: () =>
                                      _grantAccess(subject),
                                  style: FilledButton.styleFrom(
                                    backgroundColor:
                                        colors.tertiaryContainer,
                                    foregroundColor:
                                        colors.onTertiaryContainer,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 4),
                                    minimumSize: Size.zero,
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                    textStyle:
                                        theme.textTheme.labelSmall,
                                  ),
                                  child: const Text('Grant'),
                                ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}

// ── Shared helper widgets ─────────────────────────────────────────────────────

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, this.value, this.valueWidget});
  final String label;
  final String? value;
  final Widget? valueWidget;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: <Widget>[
          SizedBox(
            width: 72,
            child: Text(label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                    )),
          ),
          const SizedBox(width: 8),
          if (valueWidget != null)
            valueWidget!
          else
            Expanded(
              child: Text(value ?? '—',
                  style: Theme.of(context).textTheme.bodySmall),
            ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});
  final ParentSubscriptionStatus status;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final Color bg;
    final Color fg;
    switch (status) {
      case ParentSubscriptionStatus.active:
        bg = colors.tertiaryContainer;
        fg = colors.onTertiaryContainer;
      case ParentSubscriptionStatus.expired:
        bg = colors.errorContainer;
        fg = colors.onErrorContainer;
      case ParentSubscriptionStatus.cancelled:
        bg = colors.surfaceContainerHighest;
        fg = colors.onSurfaceVariant;
      case ParentSubscriptionStatus.pending:
        bg = colors.secondaryContainer;
        fg = colors.onSecondaryContainer;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
          color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(status.displayLabel,
          style: Theme.of(context)
              .textTheme
              .labelSmall
              ?.copyWith(color: fg, fontWeight: FontWeight.w600)),
    );
  }
}
