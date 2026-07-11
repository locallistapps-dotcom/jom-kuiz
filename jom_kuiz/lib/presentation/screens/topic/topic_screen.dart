import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/failure.dart';
import '../../../core/utils/result.dart';
import '../../../domain/entities/topic.dart';
import '../../controllers/topic_controller.dart';
import '../../providers/topic_providers.dart';
import 'topic_detail_screen.dart';

/// Admin screen for managing Topics.
///
/// Hierarchy: Topic → Chapter → (Subject, Year)
///
/// Filter cascade:
///   Subject filter ──┐
///                    ├─→ server-side JOIN (PostgREST embedding)
///   Year filter    ──┘
///   Chapter filter ──→ direct chapter_id = eq.{id}
///
/// When Subject or Year changes, the Chapter filter is automatically cleared
/// so stale chapter UUIDs are never sent to Supabase.
///
/// Features:
/// • View topic list with cascading Subject / Year / Chapter filters
/// • Inline search (client-side, instant)
/// • Sort by Display Order, Name A-Z, or Created Date
/// • Tap card → Topic Detail screen
/// • Add / Edit via bottom-sheet form
/// • Toggle Active inline
/// • Delete with confirmation dialog
class TopicScreen extends ConsumerStatefulWidget {
  const TopicScreen({super.key});

  @override
  ConsumerState<TopicScreen> createState() => _TopicScreenState();
}

class _TopicScreenState extends ConsumerState<TopicScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _showSearch = false;
  bool _showFilters = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ── Filter helpers ─────────────────────────────────────────────────────────

  /// Clears the Chapter filter whenever Subject or Year changes, preventing
  /// stale cross-entity filter combinations from being sent to the server.
  void _onSubjectChanged(String value) {
    ref.read(topicSubjectFilterProvider.notifier).state = value;
    ref.read(topicChapterFilterProvider.notifier).state = '';
  }

  void _onYearChanged(String value) {
    ref.read(topicYearFilterProvider.notifier).state = value;
    ref.read(topicChapterFilterProvider.notifier).state = '';
  }

  void _onChapterChanged(String value) {
    ref.read(topicChapterFilterProvider.notifier).state = value;
  }

  void _clearAllFilters() {
    ref.read(topicSubjectFilterProvider.notifier).state = '';
    ref.read(topicYearFilterProvider.notifier).state = '';
    ref.read(topicChapterFilterProvider.notifier).state = '';
  }

  bool get _hasActiveFilters {
    return ref.read(topicSubjectFilterProvider).isNotEmpty ||
        ref.read(topicYearFilterProvider).isNotEmpty ||
        ref.read(topicChapterFilterProvider).isNotEmpty;
  }

  // ── Actions ────────────────────────────────────────────────────────────────

  void _toggleSearch() {
    setState(() {
      _showSearch = !_showSearch;
      if (!_showSearch) {
        _searchController.clear();
        ref.read(topicSearchQueryProvider.notifier).state = '';
      }
    });
  }

  void _onSearchChanged(String value) {
    ref.read(topicSearchQueryProvider.notifier).state = value;
  }

  void _openDetail(Topic topic) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => TopicDetailScreen(topic: topic),
      ),
    );
  }

  Future<void> _openAddSheet() async {
    await _showTopicSheet(context, topic: null);
  }

  Future<void> _openEditSheet(Topic topic) async {
    await _showTopicSheet(context, topic: topic);
  }

  Future<void> _confirmDelete(Topic topic) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => _DeleteConfirmDialog(topicName: topic.topicName),
    );
    if (confirmed != true || !mounted) return;

    final Result<void> result = await ref
        .read(topicControllerProvider.notifier)
        .deleteTopic(topicId: topic.topicId);

    if (!mounted) return;
    result.when(
      success: (_) => _showSnack('Topic deleted'),
      failure: (Failure f) => _showSnack(f.message, isError: true),
    );
  }

  Future<void> _toggleActive(Topic topic) async {
    final Result<Topic> result = await ref
        .read(topicControllerProvider.notifier)
        .toggleActive(topicId: topic.topicId, isActive: !topic.isActive);

    if (!mounted) return;
    result.when(
      success: (Topic updated) => _showSnack(
        updated.isActive ? 'Topic activated' : 'Topic deactivated',
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

  Future<void> _showTopicSheet(BuildContext ctx, {required Topic? topic}) async {
    final String defaultChapterId = ref.read(topicChapterFilterProvider);

    await showModalBottomSheet<void>(
      context: ctx,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _TopicFormSheet(
        topic: topic,
        defaultChapterId: topic?.chapterId ?? defaultChapterId,
        onSave: (
          String chapterId,
          String name,
          String? description,
          int order,
          bool active,
        ) async {
          if (topic == null) {
            return ref
                .read(topicControllerProvider.notifier)
                .createTopic(
                  chapterId: chapterId,
                  topicName: name,
                  description: description,
                  displayOrder: order,
                );
          } else {
            return ref
                .read(topicControllerProvider.notifier)
                .updateTopic(
                  topicId: topic.topicId,
                  chapterId: chapterId,
                  topicName: name,
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
    final AsyncValue<List<Topic>> controllerState =
        ref.watch(topicControllerProvider);
    final List<Topic> topics = ref.watch(filteredTopicsProvider);
    final TopicSortOrder sort = ref.watch(topicSortOrderProvider);

    final String subjectFilter = ref.watch(topicSubjectFilterProvider);
    final String yearFilter = ref.watch(topicYearFilterProvider);
    final String chapterFilter = ref.watch(topicChapterFilterProvider);
    final bool hasFilters = subjectFilter.isNotEmpty ||
        yearFilter.isNotEmpty ||
        chapterFilter.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: _showSearch
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Search topics…',
                  border: InputBorder.none,
                ),
                onChanged: _onSearchChanged,
              )
            : const Text('Topics'),
        actions: <Widget>[
          IconButton(
            icon: Icon(_showSearch ? Icons.close : Icons.search),
            tooltip: _showSearch ? 'Close search' : 'Search',
            onPressed: _toggleSearch,
          ),
          // Filter toggle — badge shows when filters are active
          Stack(
            clipBehavior: Clip.none,
            children: <Widget>[
              IconButton(
                icon: Icon(
                  _showFilters ? Icons.filter_list_off : Icons.filter_list,
                ),
                tooltip: 'Filters',
                onPressed: () =>
                    setState(() => _showFilters = !_showFilters),
              ),
              if (hasFilters)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.error,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
          PopupMenuButton<TopicSortOrder>(
            icon: const Icon(Icons.sort),
            tooltip: 'Sort',
            initialValue: sort,
            onSelected: (TopicSortOrder value) {
              ref.read(topicSortOrderProvider.notifier).state = value;
            },
            itemBuilder: (_) => const <PopupMenuEntry<TopicSortOrder>>[
              PopupMenuItem<TopicSortOrder>(
                value: TopicSortOrder.displayOrderAsc,
                child: Text('Display Order'),
              ),
              PopupMenuItem<TopicSortOrder>(
                value: TopicSortOrder.nameAsc,
                child: Text('Name A → Z'),
              ),
              PopupMenuItem<TopicSortOrder>(
                value: TopicSortOrder.createdAtDesc,
                child: Text('Newest first'),
              ),
            ],
          ),
        ],
      ),

      body: Column(
        children: <Widget>[
          // Cascading filter bar
          if (_showFilters)
            _FilterBar(
              subjectId: subjectFilter,
              yearId: yearFilter,
              chapterId: chapterFilter,
              onSubjectChanged: _onSubjectChanged,
              onYearChanged: _onYearChanged,
              onChapterChanged: _onChapterChanged,
              onClear: _clearAllFilters,
            ),

          // Active filter chips summary
          if (hasFilters && !_showFilters)
            _ActiveFilterChips(
              subjectId: subjectFilter,
              yearId: yearFilter,
              chapterId: chapterFilter,
              onClear: _clearAllFilters,
            ),

          Expanded(
            child: controllerState.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (Object err, _) => _ErrorView(
                message: err is Failure ? err.message : err.toString(),
                onRetry: () =>
                    ref.read(topicControllerProvider.notifier).refresh(),
              ),
              data: (_) {
                if (topics.isEmpty) {
                  return _EmptyView(
                    isFiltered:
                        ref.watch(topicSearchQueryProvider).isNotEmpty ||
                            hasFilters,
                    onAdd: _openAddSheet,
                  );
                }
                return RefreshIndicator(
                  onRefresh: () =>
                      ref.read(topicControllerProvider.notifier).refresh(),
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                    itemCount: topics.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: 8),
                    itemBuilder: (_, int index) {
                      final Topic topic = topics[index];
                      return _TopicCard(
                        topic: topic,
                        onTap: () => _openDetail(topic),
                        onEdit: () => _openEditSheet(topic),
                        onDelete: () => _confirmDelete(topic),
                        onToggleActive: () => _toggleActive(topic),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddSheet,
        icon: const Icon(Icons.add),
        label: const Text('Add Topic'),
      ),
    );
  }
}

// ── Filter Bar ────────────────────────────────────────────────────────────────

class _FilterBar extends StatefulWidget {
  const _FilterBar({
    super.key,
    required this.subjectId,
    required this.yearId,
    required this.chapterId,
    required this.onSubjectChanged,
    required this.onYearChanged,
    required this.onChapterChanged,
    required this.onClear,
  });

  final String subjectId;
  final String yearId;
  final String chapterId;
  final ValueChanged<String> onSubjectChanged;
  final ValueChanged<String> onYearChanged;
  final ValueChanged<String> onChapterChanged;
  final VoidCallback onClear;

  @override
  State<_FilterBar> createState() => _FilterBarState();
}

class _FilterBarState extends State<_FilterBar> {
  late final TextEditingController _subjectCtrl;
  late final TextEditingController _yearCtrl;
  late final TextEditingController _chapterCtrl;

  @override
  void initState() {
    super.initState();
    _subjectCtrl = TextEditingController(text: widget.subjectId);
    _yearCtrl = TextEditingController(text: widget.yearId);
    _chapterCtrl = TextEditingController(text: widget.chapterId);
  }

  @override
  void dispose() {
    _subjectCtrl.dispose();
    _yearCtrl.dispose();
    _chapterCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            'FILTER BY HIERARCHY',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.5),
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.1,
                ),
          ),
          const SizedBox(height: 10),

          // Subject ID
          TextField(
            controller: _subjectCtrl,
            decoration: const InputDecoration(
              labelText: 'Subject ID',
              hintText: 'UUID — leave blank for all',
              border: OutlineInputBorder(),
              isDense: true,
              prefixIcon: Icon(Icons.book_outlined),
            ),
            onChanged: (String v) {
              widget.onSubjectChanged(v);
              // Cascade: clear chapter when subject changes
              _chapterCtrl.clear();
            },
          ),
          const SizedBox(height: 10),

          // Year ID
          TextField(
            controller: _yearCtrl,
            decoration: const InputDecoration(
              labelText: 'Year ID',
              hintText: 'UUID — leave blank for all',
              border: OutlineInputBorder(),
              isDense: true,
              prefixIcon: Icon(Icons.school_outlined),
            ),
            onChanged: (String v) {
              widget.onYearChanged(v);
              // Cascade: clear chapter when year changes
              _chapterCtrl.clear();
            },
          ),
          const SizedBox(height: 10),

          // Chapter ID — depends on Subject + Year
          TextField(
            controller: _chapterCtrl,
            decoration: const InputDecoration(
              labelText: 'Chapter ID',
              hintText: 'UUID — narrowest filter',
              border: OutlineInputBorder(),
              isDense: true,
              prefixIcon: Icon(Icons.menu_book_outlined),
              helperText:
                  'Set Subject or Year first to auto-narrow available chapters',
            ),
            onChanged: widget.onChapterChanged,
          ),
          const SizedBox(height: 10),

          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () {
                _subjectCtrl.clear();
                _yearCtrl.clear();
                _chapterCtrl.clear();
                widget.onClear();
              },
              icon: const Icon(Icons.clear_all, size: 18),
              label: const Text('Clear filters'),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Active Filter Chips (collapsed summary) ───────────────────────────────────

class _ActiveFilterChips extends StatelessWidget {
  const _ActiveFilterChips({
    super.key,
    required this.subjectId,
    required this.yearId,
    required this.chapterId,
    required this.onClear,
  });

  final String subjectId;
  final String yearId;
  final String chapterId;
  final VoidCallback onClear;

  String _short(String id) =>
      id.length > 8 ? '${id.substring(0, 8)}…' : id;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
      child: Row(
        children: <Widget>[
          const Icon(Icons.filter_list, size: 16),
          const SizedBox(width: 6),
          if (subjectId.isNotEmpty)
            _chip(context, 'Subject: ${_short(subjectId)}'),
          if (yearId.isNotEmpty)
            _chip(context, 'Year: ${_short(yearId)}'),
          if (chapterId.isNotEmpty)
            _chip(context, 'Chapter: ${_short(chapterId)}'),
          const Spacer(),
          GestureDetector(
            onTap: onClear,
            child: Text(
              'Clear',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(BuildContext ctx, String label) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: Theme.of(ctx).colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Theme.of(ctx).colorScheme.onPrimaryContainer,
          ),
        ),
      ),
    );
  }
}

// ── Topic Card ────────────────────────────────────────────────────────────────

class _TopicCard extends StatelessWidget {
  const _TopicCard({
    super.key,
    required this.topic,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleActive,
  });

  final Topic topic;
  final VoidCallback onTap;
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
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // Order badge
              _OrderBadge(order: topic.displayOrder),
              const SizedBox(width: 12),

              // Name + description + chapter tag
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      topic.topicName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (topic.description != null &&
                        topic.description!.isNotEmpty) ...<Widget>[
                      const SizedBox(height: 2),
                      Text(
                        topic.description!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.onSurface.withValues(alpha: 0.6),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 6),
                    // Chapter tag
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: colors.secondaryContainer,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Ch: ${_short(topic.chapterId)}',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: colors.onSecondaryContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Actions column
              Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  GestureDetector(
                    onTap: onToggleActive,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: topic.isActive
                            ? colors.primaryContainer
                            : colors.errorContainer,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        topic.isActive ? 'Active' : 'Inactive',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: topic.isActive
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
      ),
    );
  }

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

// ── Form Bottom Sheet ─────────────────────────────────────────────────────────

typedef _SaveCallback = Future<Result<Object?>> Function(
  String chapterId,
  String name,
  String? description,
  int displayOrder,
  bool isActive,
);

class _TopicFormSheet extends StatefulWidget {
  const _TopicFormSheet({
    super.key,
    required this.topic,
    required this.defaultChapterId,
    required this.onSave,
  });

  final Topic? topic;
  final String defaultChapterId;
  final _SaveCallback onSave;

  @override
  State<_TopicFormSheet> createState() => _TopicFormSheetState();
}

class _TopicFormSheetState extends State<_TopicFormSheet> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _chapterIdCtrl;
  late final TextEditingController _nameCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _orderCtrl;
  late bool _isActive;
  bool _saving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final Topic? t = widget.topic;
    _chapterIdCtrl = TextEditingController(
      text: t?.chapterId ?? widget.defaultChapterId,
    );
    _nameCtrl = TextEditingController(text: t?.topicName ?? '');
    _descCtrl = TextEditingController(text: t?.description ?? '');
    _orderCtrl =
        TextEditingController(text: (t?.displayOrder ?? 0).toString());
    _isActive = t?.isActive ?? true;
  }

  @override
  void dispose() {
    _chapterIdCtrl.dispose();
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
      _chapterIdCtrl.text.trim(),
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
    final bool isEdit = widget.topic != null;

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
                isEdit ? 'Edit Topic' : 'Add Topic',
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),

              // Chapter ID
              TextFormField(
                controller: _chapterIdCtrl,
                decoration: const InputDecoration(
                  labelText: 'Chapter ID *',
                  hintText: 'UUID of the parent chapter',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.menu_book_outlined),
                  helperText:
                      'Will become a filtered dropdown in a future release',
                ),
                validator: (String? v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Chapter ID is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Topic Name
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Topic Name *',
                  hintText: 'e.g. Fractions',
                  border: OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.sentences,
                validator: (String? v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Topic name is required';
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
                  hintText: 'Optional summary of this topic',
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
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(isEdit ? 'Save Changes' : 'Add Topic'),
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
              isFiltered ? Icons.search_off : Icons.topic_outlined,
              size: 64,
              color: theme.colorScheme.primary.withValues(alpha: 0.35),
            ),
            const SizedBox(height: 16),
            Text(
              isFiltered
                  ? 'No topics match your search or filters'
                  : 'No topics yet',
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            if (!isFiltered) ...<Widget>[
              const SizedBox(height: 8),
              Text(
                'Tap the button below to add the first topic.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: onAdd,
                icon: const Icon(Icons.add),
                label: const Text('Add Topic'),
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
              color: theme.colorScheme.error.withValues(alpha: 0.7),
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
  const _DeleteConfirmDialog({super.key, required this.topicName});

  final String topicName;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Delete Topic'),
      content: Text(
        'Are you sure you want to delete "$topicName"? '
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
