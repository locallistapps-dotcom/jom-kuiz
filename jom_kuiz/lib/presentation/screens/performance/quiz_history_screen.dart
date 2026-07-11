import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../domain/entities/performance_entities.dart';
import '../../../domain/entities/quiz_engine.dart';
import '../../providers/performance_providers.dart';
import '../quiz_engine/quiz_review_screen.dart';

/// Displays the student's complete quiz history with filtering.
///
/// Each item shows: Subject, Year, Chapter, Topic, Date, Score, Time.
/// Tapping an item loads the session's answers and pushes
/// [QuizReviewScreen] (reused from the Quiz Engine module).
class QuizHistoryScreen extends ConsumerStatefulWidget {
  const QuizHistoryScreen({super.key, required this.history});

  final List<QuizHistoryItem> history;

  @override
  ConsumerState<QuizHistoryScreen> createState() =>
      _QuizHistoryScreenState();
}

class _QuizHistoryScreenState
    extends ConsumerState<QuizHistoryScreen> {
  String _search = '';
  String? _filterSubject;
  DateTimeRange? _dateRange;

  List<QuizHistoryItem> get _filtered {
    return widget.history.where((QuizHistoryItem item) {
      final bool matchesSearch = _search.isEmpty ||
          item.topicName.toLowerCase().contains(_search.toLowerCase()) ||
          item.subjectName.toLowerCase().contains(_search.toLowerCase()) ||
          item.chapterName.toLowerCase().contains(_search.toLowerCase());
      final bool matchesSubject = _filterSubject == null ||
          item.subjectName == _filterSubject;
      final bool matchesDate = _dateRange == null ||
          (!item.completedAt.isBefore(_dateRange!.start) &&
              !item.completedAt.isAfter(_dateRange!.end));
      return matchesSearch && matchesSubject && matchesDate;
    }).toList();
  }

  List<String> get _subjects {
    final Set<String> seen = <String>{};
    return widget.history
        .map((QuizHistoryItem h) => h.subjectName)
        .where(seen.add)
        .toList()
      ..sort();
  }

  Future<void> _pickDateRange(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _dateRange,
    );
    if (picked != null) setState(() => _dateRange = picked);
  }

  void _openReview(BuildContext context, QuizHistoryItem item) {
    Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (BuildContext ctx) =>
          _ReviewLoader(sessionId: item.sessionId),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;
    final List<QuizHistoryItem> displayed = _filtered;

    return Scaffold(
      appBar: AppBar(
        title: Text('Quiz History (${widget.history.length})'),
        actions: <Widget>[
          if (_dateRange != null)
            IconButton(
              icon: const Icon(Icons.date_range),
              tooltip: 'Clear date filter',
              onPressed: () => setState(() => _dateRange = null),
              color: colors.primary,
            )
          else
            IconButton(
              icon: const Icon(Icons.date_range_outlined),
              tooltip: 'Filter by date',
              onPressed: () => _pickDateRange(context),
            ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search history…',
                prefixIcon: const Icon(Icons.search, size: 18),
                isDense: true,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10)),
                filled: true,
                fillColor: colors.surfaceContainerLow,
              ),
              onChanged: (String v) => setState(() => _search = v),
            ),
          ),
        ),
      ),
      body: Column(
        children: <Widget>[
          // ── Subject filter chips ──────────────────────────────────────────
          if (_subjects.length > 1)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Row(
                children: <Widget>[
                  _FilterChip(
                    label: 'All',
                    selected: _filterSubject == null,
                    onTap: () => setState(() => _filterSubject = null),
                  ),
                  ..._subjects.map((String s) => _FilterChip(
                        label: s,
                        selected: _filterSubject == s,
                        onTap: () =>
                            setState(() => _filterSubject = s),
                      )),
                ],
              ),
            ),

          // ── Date range indicator ──────────────────────────────────────────
          if (_dateRange != null)
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 6),
              color: colors.primaryContainer.withOpacity(0.4),
              child: Row(
                children: <Widget>[
                  Icon(Icons.calendar_today,
                      size: 14, color: colors.primary),
                  const SizedBox(width: 6),
                  Text(
                    '${DateFormat('d MMM y').format(_dateRange!.start)} – '
                    '${DateFormat('d MMM y').format(_dateRange!.end)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.primary),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => setState(() => _dateRange = null),
                    child: Icon(Icons.close,
                        size: 14, color: colors.primary),
                  ),
                ],
              ),
            ),

          // ── History list ──────────────────────────────────────────────────
          Expanded(
            child: displayed.isEmpty
                ? Center(
                    child: Text(
                      'No quiz history matches your filters.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                          color:
                              colors.onSurface.withOpacity(0.55)),
                    ),
                  )
                : ListView.separated(
                    padding:
                        const EdgeInsets.fromLTRB(16, 8, 16, 32),
                    itemCount: displayed.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: 8),
                    itemBuilder: (BuildContext ctx, int i) =>
                        _HistoryTile(
                          item: displayed[i],
                          onTap: () =>
                              _openReview(context, displayed[i]),
                        ),
                  ),
          ),
        ],
      ),
    );
  }
}

// ── History tile ──────────────────────────────────────────────────────────────

class _HistoryTile extends StatelessWidget {
  const _HistoryTile(
      {super.key, required this.item, required this.onTap});

  final QuizHistoryItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;
    final Color scoreColor = item.score >= 70
        ? Colors.green.shade700
        : item.score >= 50
            ? Colors.orange.shade700
            : colors.error;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: colors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colors.outlineVariant),
        ),
        child: Row(
          children: <Widget>[
            // Score circle
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: scoreColor.withOpacity(0.1),
                shape: BoxShape.circle,
                border: Border.all(color: scoreColor, width: 2),
              ),
              alignment: Alignment.center,
              child: Text(
                '${item.score.toStringAsFixed(0)}%',
                style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold, color: scoreColor),
              ),
            ),
            const SizedBox(width: 12),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    item.topicName,
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${item.subjectName} › ${item.yearName} › ${item.chapterName}',
                    style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.onSurface.withOpacity(0.5)),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: <Widget>[
                      Icon(Icons.calendar_today_outlined,
                          size: 12,
                          color: colors.onSurface.withOpacity(0.45)),
                      const SizedBox(width: 3),
                      Text(
                        DateFormat('d MMM y')
                            .format(item.completedAt),
                        style: theme.textTheme.bodySmall?.copyWith(
                            color:
                                colors.onSurface.withOpacity(0.45)),
                      ),
                      const SizedBox(width: 10),
                      Icon(Icons.timer_outlined,
                          size: 12,
                          color: colors.onSurface.withOpacity(0.45)),
                      const SizedBox(width: 3),
                      Text(
                        item.timeTakenFormatted,
                        style: theme.textTheme.bodySmall?.copyWith(
                            color:
                                colors.onSurface.withOpacity(0.45)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right, color: colors.outline),
          ],
        ),
      ),
    );
  }
}

// ── Review loader ─────────────────────────────────────────────────────────────

/// Loads session answers asynchronously, then delegates to [QuizReviewScreen].
class _ReviewLoader extends ConsumerWidget {
  const _ReviewLoader({super.key, required this.sessionId});
  final String sessionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<QuizAnswerReview>> async =
        ref.watch(sessionAnswersProvider(sessionId));

    return async.when(
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('Loading Review…')),
        body:
            const Center(child: CircularProgressIndicator()),
      ),
      error: (Object e, _) => Scaffold(
        appBar: AppBar(title: const Text('Review Answers')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const Icon(Icons.error_outline,
                    size: 48, color: Colors.red),
                const SizedBox(height: 12),
                Text(e.toString().replaceFirst('Exception: ', ''),
                    textAlign: TextAlign.center),
                const SizedBox(height: 16),
                OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Go Back')),
              ],
            ),
          ),
        ),
      ),
      data: (List<QuizAnswerReview> answers) {
        // Map PerformanceData QuizAnswerReview → QuizEngineAnswer
        final List<QuizEngineAnswer> engineAnswers = answers
            .map((QuizAnswerReview a) => QuizEngineAnswer(
                  question: a.question,
                  givenAnswer: a.givenAnswer,
                  correctAnswer: a.correctAnswer,
                  isCorrect: a.isCorrect,
                ))
            .toList();
        return QuizReviewScreen(answers: engineAnswers);
      },
    );
  }
}

// ── Filter chip (local) ───────────────────────────────────────────────────────

class _FilterChip extends StatelessWidget {
  const _FilterChip(
      {super.key,
      required this.label,
      required this.selected,
      required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(right: 6),
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color:
              selected ? colors.primaryContainer : colors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? colors.primary : colors.outlineVariant,
          ),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: selected
                    ? colors.onPrimaryContainer
                    : colors.onSurface,
                fontWeight:
                    selected ? FontWeight.bold : FontWeight.normal,
              ),
        ),
      ),
    );
  }
}
