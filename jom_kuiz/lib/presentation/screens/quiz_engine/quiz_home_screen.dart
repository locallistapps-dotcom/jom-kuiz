import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/question.dart';
import '../../../domain/repositories/question_bank_repository.dart';
import '../../controllers/quiz_engine_controller.dart';
import '../../providers/quiz_engine_providers.dart';
import '../../providers/question_bank_providers.dart';
import 'quiz_start_screen.dart';

/// Entry point for the Quiz Engine.
///
/// The user selects Subject → Year → Chapter → Topic using UUID text fields
/// (future: linked dropdowns). When a valid topic is selected the available
/// active question count is displayed. Tapping "Start Quiz" navigates to
/// [QuizStartScreen].
class QuizHomeScreen extends ConsumerStatefulWidget {
  const QuizHomeScreen({super.key});

  @override
  ConsumerState<QuizHomeScreen> createState() => _QuizHomeScreenState();
}

class _QuizHomeScreenState extends ConsumerState<QuizHomeScreen> {
  late final TextEditingController _subjectCtrl;
  late final TextEditingController _yearCtrl;
  late final TextEditingController _chapterCtrl;
  late final TextEditingController _topicCtrl;

  int? _availableCount;
  bool _countLoading = false;

  @override
  void initState() {
    super.initState();
    _subjectCtrl =
        TextEditingController(text: ref.read(quizSubjectFilterProvider));
    _yearCtrl =
        TextEditingController(text: ref.read(quizYearFilterProvider));
    _chapterCtrl =
        TextEditingController(text: ref.read(quizChapterFilterProvider));
    _topicCtrl =
        TextEditingController(text: ref.read(quizTopicFilterProvider));

    final String topicId = ref.read(quizTopicFilterProvider);
    if (topicId.isNotEmpty) _fetchCount(topicId);
  }

  @override
  void dispose() {
    _subjectCtrl.dispose();
    _yearCtrl.dispose();
    _chapterCtrl.dispose();
    _topicCtrl.dispose();
    super.dispose();
  }

  // ── Cascade helpers ────────────────────────────────────────────────────────

  void _onSubjectChanged(String v) {
    ref.read(quizSubjectFilterProvider.notifier).state = v;
    _yearCtrl.clear();
    _chapterCtrl.clear();
    _topicCtrl.clear();
    ref.read(quizYearFilterProvider.notifier).state = '';
    ref.read(quizChapterFilterProvider.notifier).state = '';
    ref.read(quizTopicFilterProvider.notifier).state = '';
    setState(() => _availableCount = null);
  }

  void _onYearChanged(String v) {
    ref.read(quizYearFilterProvider.notifier).state = v;
    _chapterCtrl.clear();
    _topicCtrl.clear();
    ref.read(quizChapterFilterProvider.notifier).state = '';
    ref.read(quizTopicFilterProvider.notifier).state = '';
    setState(() => _availableCount = null);
  }

  void _onChapterChanged(String v) {
    ref.read(quizChapterFilterProvider.notifier).state = v;
    _topicCtrl.clear();
    ref.read(quizTopicFilterProvider.notifier).state = '';
    setState(() => _availableCount = null);
  }

  void _onTopicChanged(String v) {
    ref.read(quizTopicFilterProvider.notifier).state = v;
    setState(() => _availableCount = null);
    if (v.trim().isNotEmpty) _fetchCount(v.trim());
  }

  Future<void> _fetchCount(String topicId) async {
    setState(() => _countLoading = true);
    final QuestionBankRepository repo =
        ref.read(quizQuestionBankRepositoryProvider);
    final result = await repo.getQuestions(
      topicId: topicId,
      isActive: true,
      sortOrder: QuestionSortOrder.createdAtDesc,
    );
    if (!mounted) return;
    result.when(
      success: (list) => setState(() {
        _availableCount = list.length;
        _countLoading = false;
      }),
      failure: (_) => setState(() {
        _availableCount = null;
        _countLoading = false;
      }),
    );
  }

  void _onStartQuiz() {
    final String topicId = ref.read(quizTopicFilterProvider).trim();
    if (topicId.isEmpty) return;

    // Reset any previous engine state before starting
    ref.read(quizEngineControllerProvider.notifier).reset();

    Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => QuizStartScreen(
        topicId: topicId,
        availableCount: _availableCount ?? 0,
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;
    final String topicId = ref.watch(quizTopicFilterProvider);
    final bool canStart = topicId.isNotEmpty &&
        (_availableCount == null || (_availableCount ?? 0) > 0);

    return Scaffold(
      appBar: AppBar(title: const Text('Quiz Engine')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            // ── Header card ────────────────────────────────────────────────
            Card(
              elevation: 0,
              color: colors.primaryContainer,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: <Widget>[
                    Icon(Icons.quiz_outlined,
                        size: 36, color: colors.onPrimaryContainer),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text('Start a Quiz',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: colors.onPrimaryContainer,
                              )),
                          const SizedBox(height: 4),
                          Text(
                            'Select a topic below to begin.',
                            style: theme.textTheme.bodySmall?.copyWith(
                                color: colors.onPrimaryContainer
                                    .withOpacity(0.75)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // ── Filter section ─────────────────────────────────────────────
            Text('SELECT TOPIC',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colors.onSurface.withOpacity(0.5),
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.1,
                )),
            const SizedBox(height: 12),

            _FilterField(
              controller: _subjectCtrl,
              label: 'Subject ID',
              icon: Icons.book_outlined,
              hint: 'UUID — leave blank for all',
              onChanged: _onSubjectChanged,
            ),
            const SizedBox(height: 10),
            _FilterField(
              controller: _yearCtrl,
              label: 'Year ID',
              icon: Icons.school_outlined,
              hint: 'UUID — leave blank for all',
              onChanged: _onYearChanged,
            ),
            const SizedBox(height: 10),
            _FilterField(
              controller: _chapterCtrl,
              label: 'Chapter ID',
              icon: Icons.menu_book_outlined,
              hint: 'UUID — leave blank for all',
              onChanged: _onChapterChanged,
            ),
            const SizedBox(height: 10),
            _FilterField(
              controller: _topicCtrl,
              label: 'Topic ID *',
              icon: Icons.topic_outlined,
              hint: 'UUID — required to start a quiz',
              onChanged: _onTopicChanged,
            ),
            const SizedBox(height: 4),
            Text(
              'Linked dropdowns will be available in a future release.',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: colors.onSurface.withOpacity(0.45)),
            ),
            const SizedBox(height: 20),

            // ── Available count badge ──────────────────────────────────────
            if (topicId.isNotEmpty)
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: _countLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _AvailableBadge(
                        count: _availableCount,
                      ),
              ),
            const SizedBox(height: 8),

            // ── Empty count warning ────────────────────────────────────────
            if (_availableCount == 0)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colors.errorContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: <Widget>[
                    Icon(Icons.warning_amber_rounded,
                        color: colors.onErrorContainer),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'No active questions in this topic. '
                        'Add questions in the Question Bank first.',
                        style: theme.textTheme.bodySmall?.copyWith(
                            color: colors.onErrorContainer),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 24),

            // ── Start button ───────────────────────────────────────────────
            FilledButton.icon(
              onPressed: canStart && !_countLoading ? _onStartQuiz : null,
              icon: const Icon(Icons.play_arrow_rounded),
              label: const Text('Start Quiz'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _FilterField extends StatelessWidget {
  const _FilterField({
    super.key,
    required this.controller,
    required this.label,
    required this.icon,
    required this.hint,
    required this.onChanged,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final String hint;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) => TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          border: const OutlineInputBorder(),
          prefixIcon: Icon(icon, size: 18),
          isDense: true,
        ),
        onChanged: onChanged,
      );
}

class _AvailableBadge extends StatelessWidget {
  const _AvailableBadge({super.key, required this.count});
  final int? count;

  @override
  Widget build(BuildContext context) {
    if (count == null) return const SizedBox.shrink();
    final ColorScheme colors = Theme.of(context).colorScheme;
    final bool ok = count! > 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: ok ? colors.primaryContainer : colors.errorContainer,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(
            ok ? Icons.check_circle_outline : Icons.block,
            color: ok ? colors.onPrimaryContainer : colors.onErrorContainer,
          ),
          const SizedBox(width: 8),
          Text(
            ok
                ? '$count active question${count != 1 ? 's' : ''} available'
                : 'No questions available',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: ok
                      ? colors.onPrimaryContainer
                      : colors.onErrorContainer,
                ),
          ),
        ],
      ),
    );
  }
}
