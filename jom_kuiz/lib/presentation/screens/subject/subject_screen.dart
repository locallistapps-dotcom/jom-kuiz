import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/failure.dart';
import '../../../core/utils/result.dart';
import '../../../domain/entities/subject.dart';
import '../../controllers/subject_controller.dart';
import '../../providers/subject_providers.dart';

/// Admin screen for managing the Subject catalogue.
///
/// Features:
/// • View paginated subject list
/// • Search subjects (client-side, instant)
/// • Sort A-Z or by Created Date (newest first)
/// • Add / Edit subject via bottom-sheet form
/// • Toggle Active / Inactive status inline
/// • Delete subject with confirmation dialog
class SubjectScreen extends ConsumerStatefulWidget {
  const SubjectScreen({super.key});

  @override
  ConsumerState<SubjectScreen> createState() => _SubjectScreenState();
}

class _SubjectScreenState extends ConsumerState<SubjectScreen> {
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
        ref.read(subjectSearchQueryProvider.notifier).state = '';
      }
    });
  }

  void _onSearchChanged(String value) {
    ref.read(subjectSearchQueryProvider.notifier).state = value;
  }

  Future<void> _openAddSheet() async {
    await _showSubjectSheet(context, subject: null);
  }

  Future<void> _openEditSheet(Subject subject) async {
    await _showSubjectSheet(context, subject: subject);
  }

  Future<void> _confirmDelete(Subject subject) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => _DeleteConfirmDialog(subjectName: subject.subjectName),
    );
    if (confirmed != true || !mounted) return;

    final Result<void> result = await ref
        .read(subjectControllerProvider.notifier)
        .deleteSubject(subjectId: subject.subjectId);

    if (!mounted) return;
    result.when(
      success: (_) => _showSnack('Subject deleted'),
      failure: (Failure f) => _showSnack(f.message, isError: true),
    );
  }

  Future<void> _toggleActive(Subject subject) async {
    final Result<Subject> result = await ref
        .read(subjectControllerProvider.notifier)
        .toggleActive(subjectId: subject.subjectId, isActive: !subject.isActive);

    if (!mounted) return;
    result.when(
      success: (Subject updated) => _showSnack(
        updated.isActive ? 'Subject activated' : 'Subject deactivated',
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

  Future<void> _showSubjectSheet(
    BuildContext context, {
    required Subject? subject,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _SubjectFormSheet(
        subject: subject,
        onSave: (String name, String? desc, String? icon, int order, bool active) async {
          if (subject == null) {
            return ref
                .read(subjectControllerProvider.notifier)
                .createSubject(
                  subjectName: name,
                  description: desc,
                  icon: icon,
                  displayOrder: order,
                );
          } else {
            return ref
                .read(subjectControllerProvider.notifier)
                .updateSubject(
                  subjectId: subject.subjectId,
                  subjectName: name,
                  description: desc,
                  icon: icon,
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
    final AsyncValue<List<Subject>> controllerState =
        ref.watch(subjectControllerProvider);
    final List<Subject> subjects = ref.watch(filteredSubjectsProvider);
    final SubjectSortOrder sort = ref.watch(subjectSortOrderProvider);
    final ThemeData theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: _showSearch
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Search subjects…',
                  border: InputBorder.none,
                ),
                onChanged: _onSearchChanged,
              )
            : const Text('Subjects'),
        actions: <Widget>[
          // Search toggle
          IconButton(
            icon: Icon(_showSearch ? Icons.close : Icons.search),
            tooltip: _showSearch ? 'Close search' : 'Search',
            onPressed: _toggleSearch,
          ),
          // Sort menu
          PopupMenuButton<SubjectSortOrder>(
            icon: const Icon(Icons.sort),
            tooltip: 'Sort',
            initialValue: sort,
            onSelected: (SubjectSortOrder value) {
              ref.read(subjectSortOrderProvider.notifier).state = value;
            },
            itemBuilder: (_) => const <PopupMenuEntry<SubjectSortOrder>>[
              PopupMenuItem<SubjectSortOrder>(
                value: SubjectSortOrder.nameAsc,
                child: Text('Name A → Z'),
              ),
              PopupMenuItem<SubjectSortOrder>(
                value: SubjectSortOrder.createdAtDesc,
                child: Text('Newest first'),
              ),
            ],
          ),
        ],
      ),

      // ── Body ───────────────────────────────────────────────────────────────
      body: controllerState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (Object err, _) => _ErrorView(
          message: err is Failure ? err.message : err.toString(),
          onRetry: () =>
              ref.read(subjectControllerProvider.notifier).refresh(),
        ),
        data: (_) {
          if (subjects.isEmpty) {
            return _EmptyView(
              isFiltered: ref.watch(subjectSearchQueryProvider).isNotEmpty,
              onAdd: _openAddSheet,
            );
          }
          return RefreshIndicator(
            onRefresh: () =>
                ref.read(subjectControllerProvider.notifier).refresh(),
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
              itemCount: subjects.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, int index) {
                final Subject subject = subjects[index];
                return _SubjectCard(
                  subject: subject,
                  onEdit: () => _openEditSheet(subject),
                  onDelete: () => _confirmDelete(subject),
                  onToggleActive: () => _toggleActive(subject),
                );
              },
            ),
          );
        },
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddSheet,
        icon: const Icon(Icons.add),
        label: const Text('Add Subject'),
      ),
    );
  }
}

// ── Subject Card ─────────────────────────────────────────────────────────────

class _SubjectCard extends StatelessWidget {
  const _SubjectCard({
    super.key,
    required this.subject,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleActive,
  });

  final Subject subject;
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // Icon / avatar
            _SubjectAvatar(subject: subject),
            const SizedBox(width: 12),

            // Text content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          subject.subjectName,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      // Display-order badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: colors.secondaryContainer,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '#${subject.displayOrder}',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colors.onSecondaryContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (subject.description != null &&
                      subject.description!.isNotEmpty) ...<Widget>[
                    const SizedBox(height: 2),
                    Text(
                      subject.description!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.onSurface.withOpacity(0.65),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 8),

                  // Status + actions row
                  Row(
                    children: <Widget>[
                      // Active/Inactive chip
                      GestureDetector(
                        onTap: onToggleActive,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: subject.isActive
                                ? colors.primaryContainer
                                : colors.errorContainer,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              Icon(
                                subject.isActive
                                    ? Icons.check_circle_outline
                                    : Icons.cancel_outlined,
                                size: 12,
                                color: subject.isActive
                                    ? colors.onPrimaryContainer
                                    : colors.onErrorContainer,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                subject.isActive ? 'Active' : 'Inactive',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: subject.isActive
                                      ? colors.onPrimaryContainer
                                      : colors.onErrorContainer,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const Spacer(),

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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Subject Avatar ────────────────────────────────────────────────────────────

class _SubjectAvatar extends StatelessWidget {
  const _SubjectAvatar({super.key, required this.subject});

  final Subject subject;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final String? icon = subject.icon;

    if (icon != null && icon.isNotEmpty) {
      // Render emoji or short text icon
      return Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: colors.primaryContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.center,
        child: Text(icon, style: const TextStyle(fontSize: 22)),
      );
    }

    // Fallback: first letter of subject name
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: colors.primaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.center,
      child: Text(
        subject.subjectName.isNotEmpty
            ? subject.subjectName[0].toUpperCase()
            : 'S',
        style: TextStyle(
          fontSize: 20,
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
  String? description,
  String? icon,
  int displayOrder,
  bool isActive,
);

class _SubjectFormSheet extends StatefulWidget {
  const _SubjectFormSheet({
    super.key,
    required this.subject,
    required this.onSave,
  });

  final Subject? subject;
  final _SaveCallback onSave;

  @override
  State<_SubjectFormSheet> createState() => _SubjectFormSheetState();
}

class _SubjectFormSheetState extends State<_SubjectFormSheet> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _iconCtrl;
  late final TextEditingController _orderCtrl;
  late bool _isActive;
  bool _saving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final Subject? s = widget.subject;
    _nameCtrl = TextEditingController(text: s?.subjectName ?? '');
    _descCtrl = TextEditingController(text: s?.description ?? '');
    _iconCtrl = TextEditingController(text: s?.icon ?? '');
    _orderCtrl =
        TextEditingController(text: (s?.displayOrder ?? 0).toString());
    _isActive = s?.isActive ?? true;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _iconCtrl.dispose();
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
      _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
      _iconCtrl.text.trim().isEmpty ? null : _iconCtrl.text.trim(),
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
    final bool isEdit = widget.subject != null;

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
              isEdit ? 'Edit Subject' : 'Add Subject',
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            // Subject Name
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Subject Name *',
                hintText: 'e.g. Mathematics',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.words,
              validator: (String? v) {
                if (v == null || v.trim().isEmpty) {
                  return 'Subject name is required';
                }
                if (v.trim().length > 100) {
                  return 'Must not exceed 100 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Description
            TextFormField(
              controller: _descCtrl,
              decoration: const InputDecoration(
                labelText: 'Description',
                hintText: 'Optional short description',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 16),

            // Icon
            TextFormField(
              controller: _iconCtrl,
              decoration: const InputDecoration(
                labelText: 'Icon',
                hintText: 'Emoji or icon key (e.g. 📐 or "science")',
                border: OutlineInputBorder(),
              ),
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

            // Error message
            if (_errorMessage != null) ...<Widget>[
              const SizedBox(height: 4),
              Text(
                _errorMessage!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
                textAlign: TextAlign.center,
              ),
            ],

            const SizedBox(height: 16),

            // Save button
            FilledButton(
              onPressed: _saving ? null : _submit,
              child: _saving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(isEdit ? 'Save Changes' : 'Add Subject'),
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
              isFiltered ? Icons.search_off : Icons.menu_book_outlined,
              size: 64,
              color: theme.colorScheme.primary.withOpacity(0.35),
            ),
            const SizedBox(height: 16),
            Text(
              isFiltered ? 'No subjects match your search' : 'No subjects yet',
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            if (!isFiltered) ...<Widget>[
              const SizedBox(height: 8),
              Text(
                'Tap the button below to add your first subject.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.55),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: onAdd,
                icon: const Icon(Icons.add),
                label: const Text('Add Subject'),
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
            Icon(Icons.error_outline,
                size: 56, color: theme.colorScheme.error.withOpacity(0.7)),
            const SizedBox(height: 16),
            Text(message,
                style: theme.textTheme.bodyMedium, textAlign: TextAlign.center),
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
  const _DeleteConfirmDialog({super.key, required this.subjectName});

  final String subjectName;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Delete Subject'),
      content: Text(
        'Are you sure you want to delete "$subjectName"? '
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
