import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/failure.dart';
import '../../../core/utils/result.dart';
import '../../../domain/entities/year.dart';
import '../../controllers/year_controller.dart';
import '../../providers/year_providers.dart';

/// Admin screen for managing academic Year levels.
///
/// Features:
/// • View year list
/// • Search years (client-side, instant)
/// • Sort by Name A-Z, Display Order, or Created Date
/// • Add / Edit year via bottom-sheet form
/// • Toggle Active / Inactive status inline
/// • Delete year with confirmation dialog
class YearScreen extends ConsumerStatefulWidget {
  const YearScreen({super.key});

  @override
  ConsumerState<YearScreen> createState() => _YearScreenState();
}

class _YearScreenState extends ConsumerState<YearScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _showSearch = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ── Actions ────────────────────────────────────────────────────────────────

  void _toggleSearch() {
    setState(() {
      _showSearch = !_showSearch;
      if (!_showSearch) {
        _searchController.clear();
        ref.read(yearSearchQueryProvider.notifier).state = '';
      }
    });
  }

  void _onSearchChanged(String value) {
    ref.read(yearSearchQueryProvider.notifier).state = value;
  }

  Future<void> _openAddSheet() async {
    await _showYearSheet(context, year: null);
  }

  Future<void> _openEditSheet(Year year) async {
    await _showYearSheet(context, year: year);
  }

  Future<void> _confirmDelete(Year year) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => _DeleteConfirmDialog(yearName: year.yearName),
    );
    if (confirmed != true || !mounted) return;

    final Result<void> result = await ref
        .read(yearControllerProvider.notifier)
        .deleteYear(yearId: year.yearId);

    if (!mounted) return;
    result.when(
      success: (_) => _showSnack('Year deleted'),
      failure: (Failure f) => _showSnack(f.message, isError: true),
    );
  }

  Future<void> _toggleActive(Year year) async {
    final Result<Year> result = await ref
        .read(yearControllerProvider.notifier)
        .toggleActive(yearId: year.yearId, isActive: !year.isActive);

    if (!mounted) return;
    result.when(
      success: (Year updated) => _showSnack(
        updated.isActive ? 'Year activated' : 'Year deactivated',
      ),
      failure: (Failure f) => _showSnack(f.message, isError: true),
    );
  }

  void _showSnack(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor:
            isError ? Theme.of(context).colorScheme.error : null,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _showYearSheet(
    BuildContext context, {
    required Year? year,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _YearFormSheet(
        year: year,
        onSave: (String name, int order, bool active) async {
          if (year == null) {
            return ref
                .read(yearControllerProvider.notifier)
                .createYear(yearName: name, displayOrder: order);
          } else {
            return ref
                .read(yearControllerProvider.notifier)
                .updateYear(
                  yearId: year.yearId,
                  yearName: name,
                  displayOrder: order,
                  isActive: active,
                );
          }
        },
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<Year>> controllerState =
        ref.watch(yearControllerProvider);
    final List<Year> years = ref.watch(filteredYearsProvider);
    final YearSortOrder sort = ref.watch(yearSortOrderProvider);

    return Scaffold(
      appBar: AppBar(
        title: _showSearch
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Search years…',
                  border: InputBorder.none,
                ),
                onChanged: _onSearchChanged,
              )
            : const Text('Year Levels'),
        actions: <Widget>[
          IconButton(
            icon: Icon(_showSearch ? Icons.close : Icons.search),
            tooltip: _showSearch ? 'Close search' : 'Search',
            onPressed: _toggleSearch,
          ),
          PopupMenuButton<YearSortOrder>(
            icon: const Icon(Icons.sort),
            tooltip: 'Sort',
            initialValue: sort,
            onSelected: (YearSortOrder value) {
              ref.read(yearSortOrderProvider.notifier).state = value;
            },
            itemBuilder: (_) => const <PopupMenuEntry<YearSortOrder>>[
              PopupMenuItem<YearSortOrder>(
                value: YearSortOrder.displayOrderAsc,
                child: Text('Display Order'),
              ),
              PopupMenuItem<YearSortOrder>(
                value: YearSortOrder.nameAsc,
                child: Text('Name A → Z'),
              ),
              PopupMenuItem<YearSortOrder>(
                value: YearSortOrder.createdAtDesc,
                child: Text('Newest first'),
              ),
            ],
          ),
        ],
      ),

      body: controllerState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (Object err, _) => _ErrorView(
          message: err is Failure ? err.message : err.toString(),
          onRetry: () =>
              ref.read(yearControllerProvider.notifier).refresh(),
        ),
        data: (_) {
          if (years.isEmpty) {
            return _EmptyView(
              isFiltered:
                  ref.watch(yearSearchQueryProvider).isNotEmpty,
              onAdd: _openAddSheet,
            );
          }
          return RefreshIndicator(
            onRefresh: () =>
                ref.read(yearControllerProvider.notifier).refresh(),
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
              itemCount: years.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, int index) {
                final Year year = years[index];
                return _YearCard(
                  year: year,
                  onEdit: () => _openEditSheet(year),
                  onDelete: () => _confirmDelete(year),
                  onToggleActive: () => _toggleActive(year),
                );
              },
            ),
          );
        },
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddSheet,
        icon: const Icon(Icons.add),
        label: const Text('Add Year'),
      ),
    );
  }
}

// ── Year Card ─────────────────────────────────────────────────────────────────

class _YearCard extends StatelessWidget {
  const _YearCard({
    super.key,
    required this.year,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleActive,
  });

  final Year year;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onToggleActive;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colors.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: <Widget>[
            // Avatar: display order number
            _YearAvatar(displayOrder: year.displayOrder),
            const SizedBox(width: 12),

            // Name
            Expanded(
              child: Text(
                year.yearName,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            // Status chip
            GestureDetector(
              onTap: onToggleActive,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: year.isActive
                      ? colors.primaryContainer
                      : colors.errorContainer,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Icon(
                      year.isActive
                          ? Icons.check_circle_outline
                          : Icons.cancel_outlined,
                      size: 12,
                      color: year.isActive
                          ? colors.onPrimaryContainer
                          : colors.onErrorContainer,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      year.isActive ? 'Active' : 'Inactive',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: year.isActive
                            ? colors.onPrimaryContainer
                            : colors.onErrorContainer,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 4),

            // Edit
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              iconSize: 20,
              tooltip: 'Edit',
              visualDensity: VisualDensity.compact,
              onPressed: onEdit,
            ),

            // Delete
            IconButton(
              icon: const Icon(Icons.delete_outline),
              iconSize: 20,
              tooltip: 'Delete',
              visualDensity: VisualDensity.compact,
              color: colors.error,
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Year Avatar ───────────────────────────────────────────────────────────────

class _YearAvatar extends StatelessWidget {
  const _YearAvatar({super.key, required this.displayOrder});

  final int displayOrder;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: colors.primaryContainer,
        borderRadius: BorderRadius.circular(10),
      ),
      alignment: Alignment.center,
      child: Text(
        '$displayOrder',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: colors.onPrimaryContainer,
        ),
      ),
    );
  }
}

// ── Form Bottom Sheet ─────────────────────────────────────────────────────────

typedef _SaveCallback = Future<Result<Object?>> Function(
  String name,
  int displayOrder,
  bool isActive,
);

class _YearFormSheet extends StatefulWidget {
  const _YearFormSheet({
    super.key,
    required this.year,
    required this.onSave,
  });

  final Year? year;
  final _SaveCallback onSave;

  @override
  State<_YearFormSheet> createState() => _YearFormSheetState();
}

class _YearFormSheetState extends State<_YearFormSheet> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _orderCtrl;
  late bool _isActive;
  bool _saving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final Year? y = widget.year;
    _nameCtrl = TextEditingController(text: y?.yearName ?? '');
    _orderCtrl =
        TextEditingController(text: (y?.displayOrder ?? 0).toString());
    _isActive = y?.isActive ?? true;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _orderCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _saving = true;
      _errorMessage = null;
    });

    final Result<Object?> result = await widget.onSave(
      _nameCtrl.text.trim(),
      int.tryParse(_orderCtrl.text.trim()) ?? 0,
      _isActive,
    );

    if (!mounted) return;
    result.when(
      success: (_) => Navigator.of(context).pop(),
      failure: (Failure f) => setState(() {
        _saving = false;
        _errorMessage = f.message;
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isEdit = widget.year != null;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        24,
        24,
        MediaQuery.viewInsetsOf(context).bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            Text(
              isEdit ? 'Edit Year Level' : 'Add Year Level',
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            // Year Name
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Year Name *',
                hintText: 'e.g. Year 1',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.words,
              validator: (String? v) {
                if (v == null || v.trim().isEmpty) {
                  return 'Year name is required';
                }
                if (v.trim().length > 100) {
                  return 'Must not exceed 100 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Display Order
            TextFormField(
              controller: _orderCtrl,
              decoration: const InputDecoration(
                labelText: 'Display Order',
                hintText: '0',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              inputFormatters: <TextInputFormatter>[
                FilteringTextInputFormatter.digitsOnly,
              ],
              validator: (String? v) {
                final int? n = int.tryParse(v ?? '');
                if (n == null || n < 0) return 'Enter a number ≥ 0';
                return null;
              },
            ),
            const SizedBox(height: 8),

            // Is Active
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Active'),
              subtitle: const Text('Visible to children and teachers'),
              value: _isActive,
              onChanged: (bool v) => setState(() => _isActive = v),
            ),

            if (_errorMessage != null) ...<Widget>[
              const SizedBox(height: 4),
              Text(
                _errorMessage!,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.error),
                textAlign: TextAlign.center,
              ),
            ],

            const SizedBox(height: 16),

            FilledButton(
              onPressed: _saving ? null : _submit,
              child: _saving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(isEdit ? 'Save Changes' : 'Add Year'),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Empty View ────────────────────────────────────────────────────────────────

class _EmptyView extends StatelessWidget {
  const _EmptyView({
    super.key,
    required this.isFiltered,
    required this.onAdd,
  });

  final bool isFiltered;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              isFiltered ? Icons.search_off : Icons.school_outlined,
              size: 64,
              color: theme.colorScheme.primary.withOpacity(0.35),
            ),
            const SizedBox(height: 16),
            Text(
              isFiltered
                  ? 'No year levels match your search'
                  : 'No year levels yet',
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            if (!isFiltered) ...<Widget>[
              const SizedBox(height: 8),
              Text(
                'Tap the button below to add your first year level.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.55),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: onAdd,
                icon: const Icon(Icons.add),
                label: const Text('Add Year Level'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Error View ────────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  const _ErrorView({super.key, required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              Icons.error_outline,
              size: 56,
              color: theme.colorScheme.error.withOpacity(0.7),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Delete Confirmation Dialog ────────────────────────────────────────────────

class _DeleteConfirmDialog extends StatelessWidget {
  const _DeleteConfirmDialog({super.key, required this.yearName});

  final String yearName;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Delete Year Level'),
      content: Text(
        'Are you sure you want to delete "$yearName"? '
        'This action cannot be undone.',
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Delete'),
        ),
      ],
    );
  }
}
