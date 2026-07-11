import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/failure.dart';
import '../../../core/utils/result.dart';
import '../../../domain/entities/question.dart';
import '../../controllers/question_bank_controller.dart';
import '../../providers/question_bank_providers.dart';
import 'question_detail_screen.dart';

/// Admin screen for the Question Bank.
///
/// Hierarchy: Question → Topic → Chapter → (Subject, Year)
///
/// Cascading filter chain (each level clears all children on change):
///   Subject → Year → Chapter → Topic
///
/// Quick-filter chips for Question Type and Difficulty sit below the
/// cascading filters and combine with them server-side.
class QuestionBankScreen extends ConsumerStatefulWidget {
  const QuestionBankScreen({super.key});

  @override
  ConsumerState<QuestionBankScreen> createState() =>
      _QuestionBankScreenState();
}

class _QuestionBankScreenState extends ConsumerState<QuestionBankScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _showSearch = false;
  bool _showFilters = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ── Cascade helpers ────────────────────────────────────────────────────────

  void _onSubjectChanged(String v) {
    ref.read(questionSubjectFilterProvider.notifier).state = v;
    ref.read(questionYearFilterProvider.notifier).state = '';
    ref.read(questionChapterFilterProvider.notifier).state = '';
    ref.read(questionTopicFilterProvider.notifier).state = '';
  }

  void _onYearChanged(String v) {
    ref.read(questionYearFilterProvider.notifier).state = v;
    ref.read(questionChapterFilterProvider.notifier).state = '';
    ref.read(questionTopicFilterProvider.notifier).state = '';
  }

  void _onChapterChanged(String v) {
    ref.read(questionChapterFilterProvider.notifier).state = v;
    ref.read(questionTopicFilterProvider.notifier).state = '';
  }

  void _onTopicChanged(String v) {
    ref.read(questionTopicFilterProvider.notifier).state = v;
  }

  void _clearAllFilters() {
    ref.read(questionSubjectFilterProvider.notifier).state = '';
    ref.read(questionYearFilterProvider.notifier).state = '';
    ref.read(questionChapterFilterProvider.notifier).state = '';
    ref.read(questionTopicFilterProvider.notifier).state = '';
    ref.read(questionTypeFilterProvider.notifier).state = null;
    ref.read(questionDifficultyFilterProvider.notifier).state = null;
  }

  bool get _hasActiveFilters =>
      ref.read(questionSubjectFilterProvider).isNotEmpty ||
      ref.read(questionYearFilterProvider).isNotEmpty ||
      ref.read(questionChapterFilterProvider).isNotEmpty ||
      ref.read(questionTopicFilterProvider).isNotEmpty ||
      ref.read(questionTypeFilterProvider) != null ||
      ref.read(questionDifficultyFilterProvider) != null;

  // ── Actions ────────────────────────────────────────────────────────────────

  void _toggleSearch() {
    setState(() {
      _showSearch = !_showSearch;
      if (!_showSearch) {
        _searchController.clear();
        ref.read(questionSearchQueryProvider.notifier).state = '';
      }
    });
  }

  void _openDetail(Question q) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => QuestionDetailScreen(question: q),
      ),
    );
  }

  Future<void> _openAddSheet() async {
    await _showQuestionSheet(context, question: null);
  }

  Future<void> _openEditSheet(Question q) async {
    await _showQuestionSheet(context, question: q);
  }

  Future<void> _confirmDelete(Question q) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => _DeleteConfirmDialog(preview: q.questionText),
    );
    if (confirmed != true || !mounted) return;

    final Result<void> result = await ref
        .read(questionBankControllerProvider.notifier)
        .deleteQuestion(questionId: q.questionId);

    if (!mounted) return;
    result.when(
      success: (_) => _snack('Question deleted'),
      failure: (Failure f) => _snack(f.message, error: true),
    );
  }

  Future<void> _toggleActive(Question q) async {
    final Result<Question> result = await ref
        .read(questionBankControllerProvider.notifier)
        .toggleActive(questionId: q.questionId, isActive: !q.isActive);
    if (!mounted) return;
    result.when(
      success: (Question u) =>
          _snack(u.isActive ? 'Question activated' : 'Question deactivated'),
      failure: (Failure f) => _snack(f.message, error: true),
    );
  }

  void _snack(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor:
          error ? Theme.of(context).colorScheme.error : null,
      behavior: SnackBarBehavior.floating,
    ));
  }

  Future<void> _showQuestionSheet(BuildContext ctx,
      {required Question? question}) async {
    final String defaultTopic = ref.read(questionTopicFilterProvider);

    await showModalBottomSheet<void>(
      context: ctx,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _QuestionFormSheet(
        question: question,
        defaultTopicId: question?.topicId ?? defaultTopic,
        onSave: (
          String topicId,
          String questionText,
          QuestionType type,
          QuestionDifficulty diff,
          String correctAnswer,
          String? optA,
          String? optB,
          String? optC,
          String? optD,
          String? explanation,
          bool isActive,
        ) async {
          if (question == null) {
            return ref
                .read(questionBankControllerProvider.notifier)
                .createQuestion(
                  topicId: topicId,
                  questionText: questionText,
                  questionType: type,
                  difficulty: diff,
                  correctAnswer: correctAnswer,
                  optionA: optA,
                  optionB: optB,
                  optionC: optC,
                  optionD: optD,
                  explanation: explanation,
                );
          } else {
            return ref
                .read(questionBankControllerProvider.notifier)
                .updateQuestion(
                  questionId: question.questionId,
                  topicId: topicId,
                  questionText: questionText,
                  questionType: type,
                  difficulty: diff,
                  correctAnswer: correctAnswer,
                  optionA: optA,
                  optionB: optB,
                  optionC: optC,
                  optionD: optD,
                  explanation: explanation,
                  isActive: isActive,
                );
          }
        },
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<Question>> ctrl =
        ref.watch(questionBankControllerProvider);
    final List<Question> questions = ref.watch(filteredQuestionsProvider);
    final QuestionSortOrder sort = ref.watch(questionSortOrderProvider);

    final String subjectF = ref.watch(questionSubjectFilterProvider);
    final String yearF = ref.watch(questionYearFilterProvider);
    final String chapterF = ref.watch(questionChapterFilterProvider);
    final String topicF = ref.watch(questionTopicFilterProvider);
    final QuestionType? typeF = ref.watch(questionTypeFilterProvider);
    final QuestionDifficulty? diffF =
        ref.watch(questionDifficultyFilterProvider);
    final bool hasFilters = subjectF.isNotEmpty ||
        yearF.isNotEmpty ||
        chapterF.isNotEmpty ||
        topicF.isNotEmpty ||
        typeF != null ||
        diffF != null;

    return Scaffold(
      appBar: AppBar(
        title: _showSearch
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Search questions…',
                  border: InputBorder.none,
                ),
                onChanged: (String v) =>
                    ref.read(questionSearchQueryProvider.notifier).state = v,
              )
            : const Text('Question Bank'),
        actions: <Widget>[
          IconButton(
            icon: Icon(_showSearch ? Icons.close : Icons.search),
            onPressed: _toggleSearch,
          ),
          Stack(
            clipBehavior: Clip.none,
            children: <Widget>[
              IconButton(
                icon: Icon(_showFilters
                    ? Icons.filter_list_off
                    : Icons.filter_list),
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
          PopupMenuButton<QuestionSortOrder>(
            icon: const Icon(Icons.sort),
            tooltip: 'Sort',
            initialValue: sort,
            onSelected: (QuestionSortOrder v) =>
                ref.read(questionSortOrderProvider.notifier).state = v,
            itemBuilder: (_) =>
                const <PopupMenuEntry<QuestionSortOrder>>[
              PopupMenuItem<QuestionSortOrder>(
                value: QuestionSortOrder.createdAtDesc,
                child: Text('Newest first'),
              ),
              PopupMenuItem<QuestionSortOrder>(
                value: QuestionSortOrder.textAsc,
                child: Text('Text A → Z'),
              ),
              PopupMenuItem<QuestionSortOrder>(
                value: QuestionSortOrder.difficultyAsc,
                child: Text('Easy → Hard'),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: <Widget>[
          if (_showFilters)
            _FilterPanel(
              subjectId: subjectF,
              yearId: yearF,
              chapterId: chapterF,
              topicId: topicF,
              typeFilter: typeF,
              diffFilter: diffF,
              onSubjectChanged: _onSubjectChanged,
              onYearChanged: _onYearChanged,
              onChapterChanged: _onChapterChanged,
              onTopicChanged: _onTopicChanged,
              onTypeChanged: (QuestionType? v) =>
                  ref.read(questionTypeFilterProvider.notifier).state = v,
              onDiffChanged: (QuestionDifficulty? v) =>
                  ref
                      .read(questionDifficultyFilterProvider.notifier)
                      .state = v,
              onClear: _clearAllFilters,
            ),
          if (hasFilters && !_showFilters)
            _ActiveFilterSummary(
              subjectId: subjectF,
              yearId: yearF,
              chapterId: chapterF,
              topicId: topicF,
              typeFilter: typeF,
              diffFilter: diffF,
              onClear: _clearAllFilters,
            ),
          Expanded(
            child: ctrl.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (Object err, _) => _ErrorView(
                message: err is Failure ? err.message : err.toString(),
                onRetry: () =>
                    ref.read(questionBankControllerProvider.notifier).refresh(),
              ),
              data: (_) {
                if (questions.isEmpty) {
                  return _EmptyView(
                    isFiltered: ref
                            .watch(questionSearchQueryProvider)
                            .isNotEmpty ||
                        hasFilters,
                    onAdd: _openAddSheet,
                  );
                }
                return RefreshIndicator(
                  onRefresh: () => ref
                      .read(questionBankControllerProvider.notifier)
                      .refresh(),
                  child: ListView.separated(
                    padding:
                        const EdgeInsets.fromLTRB(16, 8, 16, 100),
                    itemCount: questions.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: 8),
                    itemBuilder: (_, int i) {
                      final Question q = questions[i];
                      return _QuestionCard(
                        question: q,
                        onTap: () => _openDetail(q),
                        onEdit: () => _openEditSheet(q),
                        onDelete: () => _confirmDelete(q),
                        onToggleActive: () => _toggleActive(q),
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
        label: const Text('Add Question'),
      ),
    );
  }
}

// ── Filter Panel ──────────────────────────────────────────────────────────────

class _FilterPanel extends StatefulWidget {
  const _FilterPanel({
    super.key,
    required this.subjectId,
    required this.yearId,
    required this.chapterId,
    required this.topicId,
    required this.typeFilter,
    required this.diffFilter,
    required this.onSubjectChanged,
    required this.onYearChanged,
    required this.onChapterChanged,
    required this.onTopicChanged,
    required this.onTypeChanged,
    required this.onDiffChanged,
    required this.onClear,
  });

  final String subjectId;
  final String yearId;
  final String chapterId;
  final String topicId;
  final QuestionType? typeFilter;
  final QuestionDifficulty? diffFilter;
  final ValueChanged<String> onSubjectChanged;
  final ValueChanged<String> onYearChanged;
  final ValueChanged<String> onChapterChanged;
  final ValueChanged<String> onTopicChanged;
  final ValueChanged<QuestionType?> onTypeChanged;
  final ValueChanged<QuestionDifficulty?> onDiffChanged;
  final VoidCallback onClear;

  @override
  State<_FilterPanel> createState() => _FilterPanelState();
}

class _FilterPanelState extends State<_FilterPanel> {
  late final TextEditingController _subjectCtrl;
  late final TextEditingController _yearCtrl;
  late final TextEditingController _chapterCtrl;
  late final TextEditingController _topicCtrl;

  @override
  void initState() {
    super.initState();
    _subjectCtrl = TextEditingController(text: widget.subjectId);
    _yearCtrl = TextEditingController(text: widget.yearId);
    _chapterCtrl = TextEditingController(text: widget.chapterId);
    _topicCtrl = TextEditingController(text: widget.topicId);
  }

  @override
  void dispose() {
    _subjectCtrl.dispose();
    _yearCtrl.dispose();
    _chapterCtrl.dispose();
    _topicCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;

    return Container(
      color: colors.surfaceContainerLow,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            'FILTER BY HIERARCHY',
            style: theme.textTheme.labelSmall?.copyWith(
              color: colors.onSurface.withOpacity(0.5),
              fontWeight: FontWeight.w700,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 10),

          // Subject
          TextField(
            controller: _subjectCtrl,
            decoration: const InputDecoration(
              labelText: 'Subject ID',
              hintText: 'UUID — leave blank for all',
              border: OutlineInputBorder(),
              isDense: true,
              prefixIcon: Icon(Icons.book_outlined, size: 18),
            ),
            onChanged: (String v) {
              widget.onSubjectChanged(v);
              _yearCtrl.clear();
              _chapterCtrl.clear();
              _topicCtrl.clear();
            },
          ),
          const SizedBox(height: 8),

          // Year
          TextField(
            controller: _yearCtrl,
            decoration: const InputDecoration(
              labelText: 'Year ID',
              hintText: 'UUID — leave blank for all',
              border: OutlineInputBorder(),
              isDense: true,
              prefixIcon: Icon(Icons.school_outlined, size: 18),
            ),
            onChanged: (String v) {
              widget.onYearChanged(v);
              _chapterCtrl.clear();
              _topicCtrl.clear();
            },
          ),
          const SizedBox(height: 8),

          // Chapter
          TextField(
            controller: _chapterCtrl,
            decoration: const InputDecoration(
              labelText: 'Chapter ID',
              hintText: 'UUID — leave blank for all',
              border: OutlineInputBorder(),
              isDense: true,
              prefixIcon: Icon(Icons.menu_book_outlined, size: 18),
            ),
            onChanged: (String v) {
              widget.onChapterChanged(v);
              _topicCtrl.clear();
            },
          ),
          const SizedBox(height: 8),

          // Topic
          TextField(
            controller: _topicCtrl,
            decoration: const InputDecoration(
              labelText: 'Topic ID',
              hintText: 'UUID — narrowest filter',
              border: OutlineInputBorder(),
              isDense: true,
              prefixIcon: Icon(Icons.topic_outlined, size: 18),
            ),
            onChanged: widget.onTopicChanged,
          ),
          const SizedBox(height: 12),

          // Quick filters row
          Text(
            'QUICK FILTERS',
            style: theme.textTheme.labelSmall?.copyWith(
              color: colors.onSurface.withOpacity(0.5),
              fontWeight: FontWeight.w700,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: <Widget>[
                // Type chips
                ...QuestionType.values.map((QuestionType t) {
                  final bool sel = widget.typeFilter == t;
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: FilterChip(
                      label: Text(_typeLabel(t)),
                      selected: sel,
                      onSelected: (_) =>
                          widget.onTypeChanged(sel ? null : t),
                    ),
                  );
                }),
                const SizedBox(width: 8),
                // Difficulty chips
                ...QuestionDifficulty.values
                    .map((QuestionDifficulty d) {
                  final bool sel = widget.diffFilter == d;
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: FilterChip(
                      label: Text(_diffLabel(d)),
                      selected: sel,
                      onSelected: (_) =>
                          widget.onDiffChanged(sel ? null : d),
                    ),
                  );
                }),
              ],
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () {
                _subjectCtrl.clear();
                _yearCtrl.clear();
                _chapterCtrl.clear();
                _topicCtrl.clear();
                widget.onClear();
              },
              icon: const Icon(Icons.clear_all, size: 16),
              label: const Text('Clear all'),
            ),
          ),
        ],
      ),
    );
  }

  String _typeLabel(QuestionType t) {
    switch (t) {
      case QuestionType.mcq:
        return 'MCQ';
      case QuestionType.trueFalse:
        return 'True/False';
      case QuestionType.fillInTheBlank:
        return 'Fill Blank';
    }
  }

  String _diffLabel(QuestionDifficulty d) {
    switch (d) {
      case QuestionDifficulty.easy:
        return 'Easy';
      case QuestionDifficulty.medium:
        return 'Medium';
      case QuestionDifficulty.hard:
        return 'Hard';
    }
  }
}

// ── Active filter summary row ─────────────────────────────────────────────────

class _ActiveFilterSummary extends StatelessWidget {
  const _ActiveFilterSummary({
    super.key,
    required this.subjectId,
    required this.yearId,
    required this.chapterId,
    required this.topicId,
    required this.typeFilter,
    required this.diffFilter,
    required this.onClear,
  });

  final String subjectId;
  final String yearId;
  final String chapterId;
  final String topicId;
  final QuestionType? typeFilter;
  final QuestionDifficulty? diffFilter;
  final VoidCallback onClear;

  String _s(String id) => id.length > 8 ? '${id.substring(0, 8)}…' : id;

  String _typeLabel(QuestionType t) {
    switch (t) {
      case QuestionType.mcq:
        return 'MCQ';
      case QuestionType.trueFalse:
        return 'T/F';
      case QuestionType.fillInTheBlank:
        return 'Fill';
    }
  }

  String _diffLabel(QuestionDifficulty d) {
    switch (d) {
      case QuestionDifficulty.easy:
        return 'Easy';
      case QuestionDifficulty.medium:
        return 'Med';
      case QuestionDifficulty.hard:
        return 'Hard';
    }
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final List<String> chips = <String>[
      if (subjectId.isNotEmpty) 'Subj: ${_s(subjectId)}',
      if (yearId.isNotEmpty) 'Year: ${_s(yearId)}',
      if (chapterId.isNotEmpty) 'Ch: ${_s(chapterId)}',
      if (topicId.isNotEmpty) 'Topic: ${_s(topicId)}',
      if (typeFilter != null) _typeLabel(typeFilter!),
      if (diffFilter != null) _diffLabel(diffFilter!),
    ];

    return Container(
      color: colors.surfaceContainerLow,
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
      child: Row(
        children: <Widget>[
          const Icon(Icons.filter_list, size: 16),
          const SizedBox(width: 6),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: chips
                    .map((String c) => Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: colors.primaryContainer,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(c,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: colors.onPrimaryContainer,
                                )),
                          ),
                        ))
                    .toList(),
              ),
            ),
          ),
          GestureDetector(
            onTap: onClear,
            child: Text('Clear',
                style: TextStyle(
                  fontSize: 12,
                  color: colors.primary,
                  fontWeight: FontWeight.w600,
                )),
          ),
        ],
      ),
    );
  }
}

// ── Question Card ─────────────────────────────────────────────────────────────

class _QuestionCard extends StatelessWidget {
  const _QuestionCard({
    super.key,
    required this.question,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleActive,
  });

  final Question question;
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
          padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // Difficulty indicator strip
              Container(
                width: 4,
                height: 60,
                decoration: BoxDecoration(
                  color: _diffColor(question.difficulty),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    // Question text preview
                    Text(
                      question.questionText,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 6),
                    // Badges row
                    Wrap(
                      spacing: 6,
                      children: <Widget>[
                        _SmallBadge(
                          label: _typeShort(question.questionType),
                          bg: colors.secondaryContainer,
                          fg: colors.onSecondaryContainer,
                        ),
                        _SmallBadge(
                          label: _diffLabel(question.difficulty),
                          bg: _diffBg(question.difficulty),
                          fg: _diffFg(question.difficulty),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Actions
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
                        color: question.isActive
                            ? colors.primaryContainer
                            : colors.errorContainer,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        question.isActive ? 'Active' : 'Inactive',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: question.isActive
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
                        visualDensity: VisualDensity.compact,
                        onPressed: onEdit,
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline),
                        iconSize: 18,
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

  Color _diffColor(QuestionDifficulty d) {
    switch (d) {
      case QuestionDifficulty.easy:
        return Colors.green;
      case QuestionDifficulty.medium:
        return Colors.orange;
      case QuestionDifficulty.hard:
        return Colors.red;
    }
  }

  Color _diffBg(QuestionDifficulty d) {
    switch (d) {
      case QuestionDifficulty.easy:
        return Colors.green.shade100;
      case QuestionDifficulty.medium:
        return Colors.orange.shade100;
      case QuestionDifficulty.hard:
        return Colors.red.shade100;
    }
  }

  Color _diffFg(QuestionDifficulty d) {
    switch (d) {
      case QuestionDifficulty.easy:
        return Colors.green.shade800;
      case QuestionDifficulty.medium:
        return Colors.orange.shade800;
      case QuestionDifficulty.hard:
        return Colors.red.shade800;
    }
  }

  String _diffLabel(QuestionDifficulty d) {
    switch (d) {
      case QuestionDifficulty.easy:
        return 'Easy';
      case QuestionDifficulty.medium:
        return 'Medium';
      case QuestionDifficulty.hard:
        return 'Hard';
    }
  }

  String _typeShort(QuestionType t) {
    switch (t) {
      case QuestionType.mcq:
        return 'MCQ';
      case QuestionType.trueFalse:
        return 'T / F';
      case QuestionType.fillInTheBlank:
        return 'Fill';
    }
  }
}

class _SmallBadge extends StatelessWidget {
  const _SmallBadge(
      {super.key,
      required this.label,
      required this.bg,
      required this.fg});
  final String label;
  final Color bg;
  final Color fg;
  @override
  Widget build(BuildContext context) => Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
            color: bg, borderRadius: BorderRadius.circular(20)),
        child: Text(label,
            style: TextStyle(
                fontSize: 10, fontWeight: FontWeight.w700, color: fg)),
      );
}

// ── Question Form Sheet ───────────────────────────────────────────────────────

typedef _SaveCallback = Future<Result<Object?>> Function(
  String topicId,
  String questionText,
  QuestionType type,
  QuestionDifficulty difficulty,
  String correctAnswer,
  String? optA,
  String? optB,
  String? optC,
  String? optD,
  String? explanation,
  bool isActive,
);

class _QuestionFormSheet extends StatefulWidget {
  const _QuestionFormSheet({
    super.key,
    required this.question,
    required this.defaultTopicId,
    required this.onSave,
  });

  final Question? question;
  final String defaultTopicId;
  final _SaveCallback onSave;

  @override
  State<_QuestionFormSheet> createState() => _QuestionFormSheetState();
}

class _QuestionFormSheetState extends State<_QuestionFormSheet> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  late final TextEditingController _topicCtrl;
  late final TextEditingController _textCtrl;
  late final TextEditingController _optACtrl;
  late final TextEditingController _optBCtrl;
  late final TextEditingController _optCCtrl;
  late final TextEditingController _optDCtrl;
  late final TextEditingController _correctCtrl;
  late final TextEditingController _explanationCtrl;

  late QuestionType _type;
  late QuestionDifficulty _difficulty;
  late bool _isActive;

  // MCQ correct answer dropdown
  String? _mcqCorrect; // 'A' | 'B' | 'C' | 'D'
  // T/F correct answer
  String _tfCorrect = 'true';

  bool _saving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final Question? q = widget.question;
    _topicCtrl =
        TextEditingController(text: q?.topicId ?? widget.defaultTopicId);
    _textCtrl = TextEditingController(text: q?.questionText ?? '');
    _optACtrl = TextEditingController(text: q?.optionA ?? '');
    _optBCtrl = TextEditingController(text: q?.optionB ?? '');
    _optCCtrl = TextEditingController(text: q?.optionC ?? '');
    _optDCtrl = TextEditingController(text: q?.optionD ?? '');
    _explanationCtrl =
        TextEditingController(text: q?.explanation ?? '');
    _type = q?.questionType ?? QuestionType.mcq;
    _difficulty = q?.difficulty ?? QuestionDifficulty.easy;
    _isActive = q?.isActive ?? true;
    _correctCtrl = TextEditingController(
      text: _type == QuestionType.fillInTheBlank
          ? (q?.correctAnswer ?? '')
          : '',
    );

    if (_type == QuestionType.mcq) {
      _mcqCorrect = q?.correctAnswer.toUpperCase();
    } else if (_type == QuestionType.trueFalse) {
      _tfCorrect = q?.correctAnswer.toLowerCase() ?? 'true';
    }
  }

  @override
  void dispose() {
    _topicCtrl.dispose();
    _textCtrl.dispose();
    _optACtrl.dispose();
    _optBCtrl.dispose();
    _optCCtrl.dispose();
    _optDCtrl.dispose();
    _correctCtrl.dispose();
    _explanationCtrl.dispose();
    super.dispose();
  }

  String _resolvedCorrectAnswer() {
    switch (_type) {
      case QuestionType.mcq:
        return _mcqCorrect ?? '';
      case QuestionType.trueFalse:
        return _tfCorrect;
      case QuestionType.fillInTheBlank:
        return _correctCtrl.text.trim();
    }
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _saving = true;
      _errorMessage = null;
    });

    final String? optA =
        _type == QuestionType.mcq ? _n(_optACtrl.text) : null;
    final String? optB =
        _type == QuestionType.mcq ? _n(_optBCtrl.text) : null;
    final String? optC =
        _type == QuestionType.mcq ? _n(_optCCtrl.text) : null;
    final String? optD =
        _type == QuestionType.mcq ? _n(_optDCtrl.text) : null;
    final String? explanation = _n(_explanationCtrl.text);

    final Result<Object?> result = await widget.onSave(
      _topicCtrl.text.trim(),
      _textCtrl.text.trim(),
      _type,
      _difficulty,
      _resolvedCorrectAnswer(),
      optA,
      optB,
      optC,
      optD,
      explanation,
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

  String? _n(String s) => s.trim().isEmpty ? null : s.trim();

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isEdit = widget.question != null;

    return Padding(
      padding: EdgeInsets.fromLTRB(
          24, 24, 24, MediaQuery.viewInsetsOf(context).bottom + 24),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              // Handle
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
                isEdit ? 'Edit Question' : 'Add Question',
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),

              // Topic ID
              TextFormField(
                controller: _topicCtrl,
                decoration: const InputDecoration(
                  labelText: 'Topic ID *',
                  hintText: 'UUID of the parent topic',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.topic_outlined),
                  helperText:
                      'Will become a filtered dropdown in a future release',
                ),
                validator: (String? v) =>
                    (v == null || v.trim().isEmpty)
                        ? 'Topic ID is required'
                        : null,
              ),
              const SizedBox(height: 16),

              // Question Text
              TextFormField(
                controller: _textCtrl,
                decoration: const InputDecoration(
                  labelText: 'Question Text *',
                  hintText:
                      'Type the full question here…',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
                validator: (String? v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Question text is required';
                  }
                  if (v.trim().length > 1000) {
                    return 'Must not exceed 1000 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Question Type selector
              Row(
                children: <Widget>[
                  Text('Type',
                      style: theme.textTheme.labelLarge),
                  const SizedBox(width: 16),
                  Expanded(
                    child: SegmentedButton<QuestionType>(
                      segments: const <ButtonSegment<QuestionType>>[
                        ButtonSegment<QuestionType>(
                            value: QuestionType.mcq, label: Text('MCQ')),
                        ButtonSegment<QuestionType>(
                            value: QuestionType.trueFalse,
                            label: Text('T / F')),
                        ButtonSegment<QuestionType>(
                            value: QuestionType.fillInTheBlank,
                            label: Text('Fill')),
                      ],
                      selected: <QuestionType>{_type},
                      onSelectionChanged: (Set<QuestionType> s) =>
                          setState(() => _type = s.first),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Difficulty
              Row(
                children: <Widget>[
                  Text('Difficulty',
                      style: theme.textTheme.labelLarge),
                  const SizedBox(width: 16),
                  Expanded(
                    child: SegmentedButton<QuestionDifficulty>(
                      segments: const <ButtonSegment<QuestionDifficulty>>[
                        ButtonSegment<QuestionDifficulty>(
                            value: QuestionDifficulty.easy,
                            label: Text('Easy')),
                        ButtonSegment<QuestionDifficulty>(
                            value: QuestionDifficulty.medium,
                            label: Text('Med')),
                        ButtonSegment<QuestionDifficulty>(
                            value: QuestionDifficulty.hard,
                            label: Text('Hard')),
                      ],
                      selected: <QuestionDifficulty>{_difficulty},
                      onSelectionChanged: (Set<QuestionDifficulty> s) =>
                          setState(() => _difficulty = s.first),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // ── MCQ options ────────────────────────────────────────────────
              if (_type == QuestionType.mcq) ...<Widget>[
                _SectionHeader(label: 'Answer Options'),
                const SizedBox(height: 10),
                _OptionField(ctrl: _optACtrl, label: 'Option A *', required: true),
                const SizedBox(height: 10),
                _OptionField(ctrl: _optBCtrl, label: 'Option B *', required: true),
                const SizedBox(height: 10),
                _OptionField(ctrl: _optCCtrl, label: 'Option C'),
                const SizedBox(height: 10),
                _OptionField(ctrl: _optDCtrl, label: 'Option D'),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _mcqCorrect,
                  decoration: const InputDecoration(
                    labelText: 'Correct Answer *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.check_circle_outline),
                  ),
                  items: const <DropdownMenuItem<String>>[
                    DropdownMenuItem<String>(value: 'A', child: Text('A')),
                    DropdownMenuItem<String>(value: 'B', child: Text('B')),
                    DropdownMenuItem<String>(value: 'C', child: Text('C')),
                    DropdownMenuItem<String>(value: 'D', child: Text('D')),
                  ],
                  onChanged: (String? v) => setState(() => _mcqCorrect = v),
                  validator: (String? v) =>
                      (v == null || v.isEmpty)
                          ? 'Select the correct option'
                          : null,
                ),
                const SizedBox(height: 16),
              ],

              // ── True / False ───────────────────────────────────────────────
              if (_type == QuestionType.trueFalse) ...<Widget>[
                _SectionHeader(label: 'Correct Answer'),
                const SizedBox(height: 8),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: RadioListTile<String>(
                        title: const Text('True'),
                        value: 'true',
                        groupValue: _tfCorrect,
                        onChanged: (String? v) =>
                            setState(() => _tfCorrect = v!),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    Expanded(
                      child: RadioListTile<String>(
                        title: const Text('False'),
                        value: 'false',
                        groupValue: _tfCorrect,
                        onChanged: (String? v) =>
                            setState(() => _tfCorrect = v!),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],

              // ── Fill In The Blank ──────────────────────────────────────────
              if (_type == QuestionType.fillInTheBlank) ...<Widget>[
                TextFormField(
                  controller: _correctCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Correct Answer *',
                    hintText: 'Expected answer text',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.edit_note),
                  ),
                  textCapitalization: TextCapitalization.sentences,
                  validator: (String? v) =>
                      (v == null || v.trim().isEmpty)
                          ? 'Correct answer is required'
                          : null,
                ),
                const SizedBox(height: 16),
              ],

              // Explanation
              TextFormField(
                controller: _explanationCtrl,
                decoration: const InputDecoration(
                  labelText: 'Explanation',
                  hintText: 'Optional — shown after answering',
                  border: OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.sentences,
                maxLines: 3,
              ),
              const SizedBox(height: 8),

              // Is Active
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Active'),
                subtitle: const Text('Visible in quizzes'),
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
                    : Text(isEdit ? 'Save Changes' : 'Add Question'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Option Field ──────────────────────────────────────────────────────────────

class _OptionField extends StatelessWidget {
  const _OptionField({
    super.key,
    required this.ctrl,
    required this.label,
    this.required = false,
  });

  final TextEditingController ctrl;
  final String label;
  final bool required;

  @override
  Widget build(BuildContext context) => TextFormField(
        controller: ctrl,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          isDense: true,
        ),
        textCapitalization: TextCapitalization.sentences,
        validator: required
            ? (String? v) =>
                (v == null || v.trim().isEmpty) ? '$label is required' : null
            : null,
      );
}

// ── Section header ────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({super.key, required this.label});
  final String label;
  @override
  Widget build(BuildContext context) => Text(
        label,
        style: Theme.of(context)
            .textTheme
            .labelLarge
            ?.copyWith(fontWeight: FontWeight.w600),
      );
}

// ── Empty / Error views ───────────────────────────────────────────────────────

class _EmptyView extends StatelessWidget {
  const _EmptyView(
      {super.key, required this.isFiltered, required this.onAdd});
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
              isFiltered ? Icons.search_off : Icons.quiz_outlined,
              size: 64,
              color: theme.colorScheme.primary.withOpacity(0.35),
            ),
            const SizedBox(height: 16),
            Text(
              isFiltered
                  ? 'No questions match your filters'
                  : 'No questions yet',
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            if (!isFiltered) ...<Widget>[
              const SizedBox(height: 8),
              Text(
                'Tap the button below to add the first question.',
                style: theme.textTheme.bodyMedium?.copyWith(
                    color:
                        theme.colorScheme.onSurface.withOpacity(0.55)),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: onAdd,
                icon: const Icon(Icons.add),
                label: const Text('Add Question'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView(
      {super.key, required this.message, required this.onRetry});
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
                size: 56,
                color: theme.colorScheme.error.withOpacity(0.7)),
            const SizedBox(height: 16),
            Text(message,
                style: theme.textTheme.bodyMedium,
                textAlign: TextAlign.center),
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

// ── Delete confirmation ───────────────────────────────────────────────────────

class _DeleteConfirmDialog extends StatelessWidget {
  const _DeleteConfirmDialog({super.key, required this.preview});
  final String preview;

  @override
  Widget build(BuildContext context) {
    final String short = preview.length > 60
        ? '${preview.substring(0, 60)}…'
        : preview;
    return AlertDialog(
      title: const Text('Delete Question'),
      content: Text(
          'Are you sure you want to delete "$short"? This cannot be undone.'),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error),
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Delete'),
        ),
      ],
    );
  }
}
