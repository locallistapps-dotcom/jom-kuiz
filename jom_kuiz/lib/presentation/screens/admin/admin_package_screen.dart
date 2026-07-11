import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/subject.dart';
import '../../../domain/entities/subscription_package.dart';
import '../../controllers/subject_controller.dart';
import '../../controllers/subscription_package_controller.dart';
import '../../widgets/feedback/app_error_widget.dart';
import '../../widgets/feedback/loading_widget.dart';

/// Admin screen for CRUD management of Subscription Packages.
///
/// Features:
/// • List all packages (active + inactive)
/// • Toggle active / inactive inline
/// • Edit package via bottom sheet
/// • Delete package with confirmation
/// • FAB → create new package
class AdminPackageScreen extends ConsumerWidget {
  const AdminPackageScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // null = all packages (admin view)
    final state = ref.watch(subscriptionPackageControllerProvider(null));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Packages'),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.refresh_outlined),
            tooltip: 'Refresh',
            onPressed: () => ref
                .read(subscriptionPackageControllerProvider(null).notifier)
                .refresh(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('New Package'),
        onPressed: () => _showPackageForm(context, ref, null),
      ),
      body: state.when(
        loading: () => const LoadingWidget(message: 'Loading packages...'),
        error: (err, _) => AppErrorWidget(
          message: err.toString(),
          onRetry: () => ref
              .read(subscriptionPackageControllerProvider(null).notifier)
              .refresh(),
        ),
        data: (List<SubscriptionPackage> packages) {
          if (packages.isEmpty) {
            return const Center(
              child: Text('No packages yet. Tap + to create one.'),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            itemCount: packages.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (BuildContext context, int index) =>
                _PackageTile(package: packages[index]),
          );
        },
      ),
    );
  }

  void _showPackageForm(BuildContext context, WidgetRef ref,
      SubscriptionPackage? existing) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _PackageFormSheet(existing: existing),
    );
  }
}

// ── Package tile ──────────────────────────────────────────────────────────────

class _PackageTile extends ConsumerWidget {
  const _PackageTile({super.key, required this.package});
  final SubscriptionPackage package;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: Text(package.name,
                                style:
                                    Theme.of(context).textTheme.titleSmall),
                          ),
                          Switch(
                            value: package.isActive,
                            onChanged: (bool v) async {
                              final result = await ref
                                  .read(subscriptionPackageControllerProvider(
                                          null)
                                      .notifier)
                                  .toggleActive(package.id, v);
                              result.when(
                                success: (_) {},
                                failure: (f) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text(f.toString())),
                                    );
                                  }
                                },
                              );
                            },
                          ),
                        ],
                      ),
                      if (package.description != null)
                        Text(
                          package.description!,
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(
                                color:
                                    Theme.of(context).colorScheme.outline,
                              ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              children: <Widget>[
                _Stat(label: 'Price', value: package.priceDisplay),
                _Stat(
                    label: 'Duration',
                    value: '${package.durationDays} days'),
                _Stat(
                    label: 'Children',
                    value: 'Max ${package.maxChildren}'),
                _Stat(
                    label: 'Subjects',
                    value:
                        '${package.includedSubjectIds.length} included'),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: <Widget>[
                TextButton.icon(
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  label: const Text('Edit'),
                  onPressed: () =>
                      _showEditSheet(context, ref, package),
                ),
                TextButton.icon(
                  icon: Icon(Icons.delete_outlined,
                      size: 16,
                      color: Theme.of(context).colorScheme.error),
                  label: Text('Delete',
                      style: TextStyle(
                          color:
                              Theme.of(context).colorScheme.error)),
                  onPressed: () => _confirmDelete(context, ref),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showEditSheet(
      BuildContext context, WidgetRef ref, SubscriptionPackage pkg) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _PackageFormSheet(existing: pkg),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: const Text('Delete Package?'),
        content: Text(
            'Delete "${package.name}"? This cannot be undone. Packages with active subscribers cannot be deleted.'),
        actions: <Widget>[
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;

    final result = await ref
        .read(subscriptionPackageControllerProvider(null).notifier)
        .deletePackage(package.id);
    if (!context.mounted) return;
    result.when(
      success: (_) => ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Package deleted'))),
      failure: (f) => ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(f.toString()))),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({super.key, required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        style: Theme.of(context).textTheme.bodySmall,
        children: <TextSpan>[
          TextSpan(
              text: '$label: ',
              style: TextStyle(
                  color: Theme.of(context).colorScheme.outline)),
          TextSpan(
              text: value,
              style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

// ── Package form sheet ────────────────────────────────────────────────────────

class _PackageFormSheet extends ConsumerStatefulWidget {
  const _PackageFormSheet({super.key, this.existing});
  final SubscriptionPackage? existing;

  @override
  ConsumerState<_PackageFormSheet> createState() => _PackageFormSheetState();
}

class _PackageFormSheetState extends ConsumerState<_PackageFormSheet> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _descCtrl = TextEditingController();
  final TextEditingController _priceCtrl = TextEditingController();
  final TextEditingController _durationCtrl = TextEditingController();
  final TextEditingController _maxChildrenCtrl = TextEditingController();

  Set<String> _selectedSubjectIds = <String>{};
  bool _isActive = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final SubscriptionPackage? p = widget.existing;
    if (p != null) {
      _nameCtrl.text = p.name;
      _descCtrl.text = p.description ?? '';
      _priceCtrl.text = (p.priceCents / 100).toStringAsFixed(2);
      _durationCtrl.text = p.durationDays.toString();
      _maxChildrenCtrl.text = p.maxChildren.toString();
      _selectedSubjectIds = Set<String>.from(p.includedSubjectIds);
      _isActive = p.isActive;
    } else {
      _priceCtrl.text = '0.00';
      _durationCtrl.text = '30';
      _maxChildrenCtrl.text = '5';
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    _durationCtrl.dispose();
    _maxChildrenCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);

    final int priceCents =
        ((double.tryParse(_priceCtrl.text) ?? 0) * 100).round();
    final int duration = int.tryParse(_durationCtrl.text) ?? 30;
    final int maxChildren = int.tryParse(_maxChildrenCtrl.text) ?? 5;

    final notifier =
        ref.read(subscriptionPackageControllerProvider(null).notifier);

    final result = widget.existing == null
        ? await notifier.createPackage(
            name: _nameCtrl.text.trim(),
            description:
                _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
            maxChildren: maxChildren,
            includedSubjectIds: _selectedSubjectIds.toList(),
            priceCents: priceCents,
            durationDays: duration,
          )
        : await notifier.updatePackage(
            id: widget.existing!.id,
            name: _nameCtrl.text.trim(),
            description:
                _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
            maxChildren: maxChildren,
            includedSubjectIds: _selectedSubjectIds.toList(),
            priceCents: priceCents,
            durationDays: duration,
            isActive: _isActive,
          );

    if (!mounted) return;
    setState(() => _saving = false);

    result.when(
      success: (_) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(widget.existing == null
                  ? 'Package created'
                  : 'Package updated')),
        );
      },
      failure: (f) => ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(f.toString()))),
    );
  }

  @override
  Widget build(BuildContext context) {
    final subjectsState = ref.watch(subjectControllerProvider);

    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                widget.existing == null
                    ? 'New Package'
                    : 'Edit Package',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(labelText: 'Package Name *'),
                validator: (v) =>
                    (v == null || v.trim().length < 2)
                        ? 'Name must be at least 2 characters'
                        : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descCtrl,
                decoration:
                    const InputDecoration(labelText: 'Description (optional)'),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              Row(
                children: <Widget>[
                  Expanded(
                    child: TextFormField(
                      controller: _priceCtrl,
                      decoration:
                          const InputDecoration(labelText: 'Price (RM) *'),
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      validator: (v) =>
                          (double.tryParse(v ?? '') == null)
                              ? 'Enter a valid price'
                              : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _durationCtrl,
                      decoration:
                          const InputDecoration(labelText: 'Duration (days) *'),
                      keyboardType: TextInputType.number,
                      validator: (v) =>
                          (int.tryParse(v ?? '') == null ||
                                  int.parse(v!) < 1)
                              ? 'Enter days ≥ 1'
                              : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _maxChildrenCtrl,
                decoration:
                    const InputDecoration(labelText: 'Max Children *'),
                keyboardType: TextInputType.number,
                validator: (v) =>
                    (int.tryParse(v ?? '') == null || int.parse(v!) < 1)
                        ? 'Enter 1 or more'
                        : null,
              ),
              const SizedBox(height: 16),

              // ── Subject picker ──────────────────────────────────────────
              Text('Included Subjects',
                  style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              subjectsState.when(
                loading: () =>
                    const LoadingWidget(message: 'Loading subjects...'),
                error: (err, _) => Text('Error: $err'),
                data: (List<Subject> subjects) {
                  final List<Subject> active =
                      subjects.where((Subject s) => s.isActive).toList();
                  if (active.isEmpty) {
                    return const Text('No active subjects available.');
                  }
                  return Wrap(
                    spacing: 8,
                    children: active.map((Subject s) {
                      final bool selected =
                          _selectedSubjectIds.contains(s.subjectId);
                      return FilterChip(
                        label: Text(s.subjectName),
                        selected: selected,
                        onSelected: (bool v) {
                          setState(() {
                            if (v) {
                              _selectedSubjectIds.add(s.subjectId);
                            } else {
                              _selectedSubjectIds.remove(s.subjectId);
                            }
                          });
                        },
                      );
                    }).toList(),
                  );
                },
              ),
              const SizedBox(height: 16),

              if (widget.existing != null) ...<Widget>[
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Active'),
                  subtitle: const Text(
                      'Inactive packages are hidden from parents'),
                  value: _isActive,
                  onChanged: (bool v) => setState(() => _isActive = v),
                ),
                const SizedBox(height: 8),
              ],

              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(widget.existing == null ? 'Create' : 'Save'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
