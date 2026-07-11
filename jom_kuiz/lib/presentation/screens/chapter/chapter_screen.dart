import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/failure.dart';
import '../../../core/utils/result.dart';
import '../../../domain/entities/chapter.dart';
import '../../controllers/chapter_controller.dart';
import '../../providers/chapter_providers.dart';

/// Admin screen for managing Chapters.
///
/// A Chapter always belongs to exactly one Subject and one Year. The screen
/// can be scoped to a specific Subject+Year pair by setting
/// [chapterSubjectFilterProvider] and [chapterYearFilterProvider] before
/// navigating. When both are empty the screen shows all chapters (admin view).
///
/// Features:
/// • View chapter list (optionally filtered by Subject and Year)
/// • Search chapters (client-side, instant)
/// • Sort by Display Order, Name A-Z, or Created Date
/// • Add / Edit chapter via bottom-sheet form
/// • Toggle Active / Inactive status inline
/// • Delete chapter with confirmation dialog
class ChapterScreen extends ConsumerStatefulWidget {
  const ChapterScreen({super.key});

  @override
  ConsumerState<ChapterScreen> createState() => _ChapterScreenState();
}

class _ChapterScreenState extends ConsumerState<ChapterScreen> {
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
        ref.read(chapterSearchQueryProvider.notifier).state = '';
      }
    });
  }

  void _onSearchChanged(String value) {
    ref.read(chapterSearchQueryProvider.notifier).state = value;
  }

  Future<void> _openAddSheet() async {
    await _showChapterSheet(context, chapter: null);
  }

  Future<void> _openEditSheet(Chapter chapter) async {
    await _showChapterSheet(context, chapter: chapter);
  }

  Future<void> _confirmDelete(Chapter chapter) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => _DeleteConfirmDialog(chapterName: chapter.chapterName),
    );
    if (confirmed != true || !mounted) return;

    final Result<void> result = await ref
        .read(chapterControllerProvider.notifier)
        .deleteChapter(chapterId: chapter.chapterId);

    if (!mounted) return;
    result.when(
      success: (_) => _showSnack('Chapter deleted'),
      failure: (Failure f) => _showSnack(f.message, isError: true),
    );
  }

  Future<void> _toggleActive(Chapter chapter) async {
    final Result<Chapter> result = await ref
        .read(chapterControllerProvider.notifier)
        .toggleActive(
          chapterId: chapter.chapterId,
          isActive: !chapter.isActive,
        );

    if (!mounted) return;
    result.when(
      success: (Chapter updated) => _showSnack(
        updated.isActive ? 'Chapter activated' : 'Chapter deactivated',
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

  Future<void> _showChapterSheet(
    BuildContext context, {
    required Chapter? chapter,
  }) async {
    // Pre-populate subject/year filters if set.
    final String defaultSubjectId =
        ref.read(chapterSubjectFilterProvider);
    final String defaultYearId = ref.read(chapterYearFilterProvider);

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _ChapterFormSheet(
        chapter: chapter,
        defaultSubjectId:
            chapter?.subjectId ?? defaultSubjectId,
        defaultYearId: chapter?.yearId ?? defaultYearId,
        onSave: (
          String subjectId,
          String yearId,
          String name,
          String? description,
          int order,
          bool active,
        ) async {
          if (chapter == null) {
            return ref
                .read(chapterControllerProvider.notifier)
                .createChapter(
                  subjectId: subjectId,
                  yearId: yearId,
                  chapterName: name,
                  description: description,
                  displayOrder: order,
                );
          } else {
            return ref
                .read(chapterControllerProvider.notifier)
                .updateChapter(
                  chapterId: chapter.chapterId,
                  subjectId: subjectId,
                  yearId: yearId,
                  chapterName: name,
                  description: description,
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
    final AsyncValue<List<Chapter>> controllerState =
        ref.watch(chapterControllerProvider);
    final List<Chapter> chapters = ref.watch(filteredChaptersProvider);
    final ChapterSortOrder sort = ref.watch(chapterSortOrderProvider);
    final bool isFiltered =
        ref.watch(chapterSubjectFilterProvider).isNotEmpty ||
            ref.watch(chapterYearFilterProvider).isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: _showSearch
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Search chapters…',
                  border: InputBorder.none,
                ),
                onChanged: _onSearchChanged,
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Text('Chapters'),
                  if (isFiltered)
                    Text(
                      'Filtered by Subject / Year',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onPrimary
                                .withOpacity(0.75),
                          ),
                    ),
                ],
              ),
        actions: <Widget>[
          IconButton(
            icon: Icon(_showSearch ? Icons.close : Icons.search),
            tooltip: _showSearch ? 'Close search' : 'Search',
            onPressed: _toggleSearch,
          ),
          PopupMenuButton<ChapterSortOrder>(
            icon: const Icon(Icons.sort),
            tooltip: 'Sort',
            initialValue: sort,
            onSelected: (ChapterSortOrder value) {
              ref.read(chapterSortOrderProvider.notifier).state = value;
            },
            itemBuilder: (_) => const <PopupMenuEntry<ChapterSortOrder>>[
              PopupMenuItem<ChapterSortOrder>(
                value: ChapterSortOrder.displayOrderAsc,
                child: Text('Display Order'),
              ),
              PopupMenuItem<ChapterSortOrder>(
                value: ChapterSortOrder.nameAsc,
                child: Text('Name A → Z'),
              ),
              PopupMenuItem<ChapterSortOrder>(
                value: ChapterSortOrder.createdAtDesc,
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
              ref.read(chapterControllerProvider.notifier).refresh(),
        ),
        data: (_) {
          if (chapters.isEmpty) {
            return _EmptyView(
              isFiltered:
                  ref.watch(chapterSearchQueryProvider).isNotEmpty,
              onAdd: _openAddSheet,
            );
          }
          return RefreshIndicator(
            onRefresh: () =>
                ref.read(chapterControllerProvider.notifier).refresh(),
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
              itemCount: chapters.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, int index) {
                final Chapter chapter = chapters[index];
                return _ChapterCard(
                  chapter: chapter,
                  onEdit: () => _openEditSheet(chapter),
                  onDelete: () => _confirmDelete(chapter),
                  onToggleActive: () => _toggleActive(chapter),
                );
              },
            ),
          );
        },
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddSheet,
        icon: const Icon(Icons.add),
        label: const Text('Add Chapter'),
      ),
    );
  }
}

// ── Chapter Card ──────────────────────────────────────────────────────────────

class _ChapterCard extends StatelessWidget {
  const _ChapterCard({
    super.key,
    required this.chapter,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleActive,
  });

  final Chapter chapter;
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
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // Order badge
            _OrderBadge(order: chapter.displayOrder),
            const SizedBox(width: 12),

            // Name + description
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    chapter.chapterName,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (chapter.description != null &&
                      chapter.description!.isNotEmpty) ...<Widget>[
                    const SizedBox(height: 2),
                    Text(
                      chapter.description!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.onSurface.withOpacity(0.6),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 6),
                  // Relationship tags
                  Wrap(
                    spacing: 6,
                    children: <Widget>[
                      _TagChip(
                        label: 'S: ${_short(chapter.subjectId)}',
                        color: colors.secondaryContainer,
                        textColor: colors.onSecondaryContainer,
                      ),
                      _TagChip(
                        label: 'Y: ${_short(chapter.yearId)}',
                        color: colors.tertiaryContainer,
                        textColor: colors.onTertiaryContainer,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Actions column
            Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                // Status chip
                GestureDetector(
                  onTap: onToggleActive,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: chapter.isActive
                          ? colors.primaryContainer
                          : colors.errorContainer,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      chapter.isActive ? 'Active' : 'Inactive',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: chapter.isActive
                            ? colors.onPrimaryContainer
                            : colors.onErrorContainer,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    IconButton(
                      icon: const Icon(Icons.edit_outlined),
                      iconSize: 18,
                      tooltip: 'Edit',
                      visualDensity: VisualDensity.compact,
                      onPressed: onEdit,
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline),
                      iconSize: 18,
                      tooltip: 'Delete',
                      visualDensity: VisualDensity.compact,
                      color: colors.error,
                      onPressed: onDelete,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Shows the first 8 characters of a UUID for display purposes.
  String _short(String id) =>
      id.length > 8 ? id.substring(0, 8) : id;
}

// ── Order Badge ───────────────────────────────────────────────────────────────

class _OrderBadge extends StatelessWidget {
  const _OrderBadge({super.key, required this.order});

  final int order;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: colors.primaryContainer,
        borderRadius: BorderRadius.circular(10),
      ),
      alignment: Alignment.center,
      child: Text(
        '$order',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: colors.onPrimaryContainer,
        ),
      ),
    );
  }
}

// ── Tag Chip ──────────────────────────────────────────────────────────────────

class _TagChip extends StatelessWidget {
  const _TagChip({
    super.key,
    required this.label,
    required this.color,
    required this.textColor,
  });

  final String label;
  final Color color;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: textColor,
          fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}

// ── Form Bottom Sheet ─────────────────────────────────────────────────────────

typedef _SaveCallback = Future<Result<Object?>> Function(
  String subjectId,
  String yearId,
  String name,
  String? description,
  int displayOrder,
  bool isActive,
);

class _ChapterFormSheet extends StatefulWidget {
  const _ChapterFormSheet({
    super.key,
    required this.chapter,
    required this.defaultSubjectId,
    required this.defaultYearId,
    required this.onSave,
  });

  final Chapter? chapter;
  final String defaultSubjectId;
  final String defaultYearId;
  final _SaveCallback onSave;

  @override
  State<_ChapterFormSheet> createState() => _ChapterFormSheetState();
}

class _ChapterFormSheetState extends State<_ChapterFormSheet> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _subjectIdCtrl;
  late final TextEditingController _yearIdCtrl;
  late final TextEditingController _nameCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _orderCtrl;
  late bool _isActive;
  bool _saving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final Chapter? c = widget.chapter;
    _subjectIdCtrl = TextEditingController(
      text: c?.subjectId ?? widget.defaultSubjectId,
    );
    _yearIdCtrl = TextEditingController(
      text: c?.yearId ?? widget.defaultYearId,
    );
    _nameCtrl = TextEditingController(text: c?.chapterName ?? '');
    _descCtrl = TextEditingController(text: c?.description ?? '');
    _orderCtrl =
        TextEditingController(text: (c?.displayOrder ?? 0).toString());
    _isActive = c?.isActive ?? true;
  }

  @override
  void dispose() {
    _subjectIdCtrl.dispose();
    _yearIdCtrl.dispose();
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _orderCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _saving = true;
      _errorMessage = null;
    });

    final String? desc = _descCtrl.text.trim().isEmpty
        ? null
        : _descCtrl.text.trim();

    final Result<Object?> result = await widget.onSave(
      _subjectIdCtrl.text.trim(),
      _yearIdCtrl.text.trim(),
      _nameCtrl.text.trim(),
      desc,
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
    final bool isEdit = widget.chapter != null;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        24,
        24,
        MediaQuery.viewInsetsOf(context).bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
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
                isEdit ? 'Edit Chapter' : 'Add Chapter',
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),

              // Subject ID
              TextFormField(
                controller: _subjectIdCtrl,
                decoration: const InputDecoration(
                  labelText: 'Subject ID *',
                  hintText: 'UUID of the parent subject',
                  border: OutlineInputBorder(),
                  helperText: 'Will become a dropdown in a future release',
                ),
                validator: (String? v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Subject ID is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Year ID
              TextFormField(
                controller: _yearIdCtrl,
                decoration: const InputDecoration(
                  labelText: 'Year ID *',
                  hintText: 'UUID of the parent year',
                  border: OutlineInputBorder(),
                  helperText: 'Will become a dropdown in a future release',
                ),
                validator: (String? v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Year ID is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Chapter Name
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Chapter Name *',
                  hintText: 'e.g. Chapter 1: Numbers',
                  border: OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.sentences,
                validator: (String? v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Chapter name is required';
                  }
                  if (v.trim().length > 150) {
                    return 'Must not exceed 150 characters';
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
                  hintText: 'Optional summary of this chapter',
                  border: OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.sentences,
                maxLines: 3,
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
                        child:
                            CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(isEdit ? 'Save Changes' : 'Add Chapter'),
              ),
            ],
          ),
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
              isFiltered
                  ? 'No chapters match your search'
                  : 'No chapters yet',
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            if (!isFiltered) ...<Widget>[
              const SizedBox(height: 8),
              Text(
                'Tap the button below to add the first chapter.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.55),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: onAdd,
                icon: const Icon(Icons.add),
                label: const Text('Add Chapter'),
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
  const _ErrorView({
    super.key,
    required this.message,
    required this.onRetry,
  });

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
  const _DeleteConfirmDialog({super.key, required this.chapterName});

  final String chapterName;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Delete Chapter'),
      content: Text(
        'Are you sure you want to delete "$chapterName"? '
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
