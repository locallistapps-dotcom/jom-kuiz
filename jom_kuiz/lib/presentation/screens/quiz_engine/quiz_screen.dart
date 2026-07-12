import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/question.dart';
import '../../../domain/entities/quiz_engine.dart';
import '../../controllers/quiz_engine_controller.dart';
import 'quiz_result_screen.dart';

/// The active quiz-taking screen.
///
/// Displays one question at a time with:
/// - A linear progress bar + "X of Y" counter
/// - The question text card
/// - Type-appropriate answer UI:
///     MCQ          → tappable option tiles (A / B / C / D)
///     True/False   → two large buttons
///     Fill Blank   → text field (auto-saves on change)
/// - Previous / Next / Finish navigation
///
/// Answers are recorded immediately via [QuizEngineController.recordAnswer].
/// Explanation is intentionally hidden while the quiz is in progress.
///
/// Transitions to [QuizResultScreen] after [QuizEngineController.finishQuiz].
class QuizScreen extends ConsumerStatefulWidget {
  const QuizScreen({super.key});

  @override
  ConsumerState<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends ConsumerState<QuizScreen> {
  // Controller for fill-in-the-blank questions
  final TextEditingController _fillCtrl = TextEditingController();
  int _lastIndex = -1;

  @override
  void dispose() {
    _fillCtrl.dispose();
    super.dispose();
  }

  // ── Navigation to result ───────────────────────────────────────────────────

  void _listenForFinish(BuildContext context, QuizEnginePhase? prev,
      QuizEnginePhase next) {
    if (next is QuizFinished) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => QuizResultScreen(result: next.result),
        ),
      );
    }
  }

  // ── Answer helpers ─────────────────────────────────────────────────────────

  void _record(String questionId, String answer) {
    ref
        .read(quizEngineControllerProvider.notifier)
        .recordAnswer(questionId: questionId, answer: answer);
  }

  Future<void> _finish(QuizEngineSession session) async {
    final int unanswered =
        session.totalQuestions - session.answeredCount;
    if (unanswered > 0) {
      final bool? ok = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Finish Quiz?'),
          content: Text(
            unanswered == 1
                ? '1 question has not been answered. Do you still want to finish?'
                : '$unanswered questions have not been answered. Do you still want to finish?',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Keep Going'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Finish Anyway'),
            ),
          ],
        ),
      );
      if (ok != true || !mounted) return;
    }
    await ref
        .read(quizEngineControllerProvider.notifier)
        .finishQuiz();
  }

  @override
  Widget build(BuildContext context) {
    // Listen for state transitions → navigate to result
    ref.listen<QuizEnginePhase>(
      quizEngineControllerProvider,
      (QuizEnginePhase? prev, QuizEnginePhase next) =>
          _listenForFinish(context, prev, next),
    );

    final QuizEnginePhase phase =
        ref.watch(quizEngineControllerProvider);

    if (phase is QuizLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (phase is QuizEngineError) {
      return Scaffold(
        appBar: AppBar(title: const Text('Quiz')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const Icon(Icons.error_outline, size: 56, color: Colors.red),
                const SizedBox(height: 16),
                Text(phase.message, textAlign: TextAlign.center),
                const SizedBox(height: 20),
                OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Go Back'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (phase is! QuizPlaying) {
      return const Scaffold(
        body: Center(child: Text('No active quiz session.')),
      );
    }

    final QuizEngineSession session = phase.session;
    final Question q = session.currentQuestion;
    final String? current = session.answerFor(q.questionId);
    final int idx = session.currentIndex;

    // ── IMAGE DEBUG ── remove after diagnosis ──────────────────────────────
    debugPrint(
      '[QuizScreen] Q${idx + 1} id=${q.questionId} '
      'questionImageUrl=${q.questionImageUrl ?? "NULL"}',
    );
    // ─────────────────────────────────────────────────────────────────────

    // Sync fill-blank text field when question changes
    if (idx != _lastIndex) {
      _lastIndex = idx;
      if (q.questionType == QuestionType.fillInTheBlank) {
        final String text = current ?? '';
        if (_fillCtrl.text != text) {
          _fillCtrl.text = text;
          _fillCtrl.selection =
              TextSelection.collapsed(offset: text.length);
        }
      }
    }

    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text('Question ${idx + 1} of ${session.totalQuestions}'),
        automaticallyImplyLeading: false,
        actions: <Widget>[
          TextButton(
            onPressed: () async {
              final bool? quit = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('Quit Quiz?'),
                  content: const Text(
                      'Your progress will be lost. Are you sure?'),
                  actions: <Widget>[
                    TextButton(
                      onPressed: () =>
                          Navigator.of(context).pop(false),
                      child: const Text('Continue'),
                    ),
                    FilledButton(
                      style: FilledButton.styleFrom(
                          backgroundColor: colors.error),
                      onPressed: () =>
                          Navigator.of(context).pop(true),
                      child: const Text('Quit'),
                    ),
                  ],
                ),
              );
              if (quit == true && mounted) {
                ref
                    .read(quizEngineControllerProvider.notifier)
                    .reset();
                Navigator.of(context).pop();
              }
            },
            child: const Text('Quit'),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(6),
          child: LinearProgressIndicator(
            value: session.progress,
            backgroundColor:
                colors.surfaceContainerHighest,
          ),
        ),
      ),
      body: Column(
        children: <Widget>[
          // ── Progress dots ────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            color: colors.surfaceContainerLow,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: List<Widget>.generate(
                  session.totalQuestions,
                  (int i) {
                    final bool answered = session.answers
                        .containsKey(session.questions[i].questionId);
                    final bool active = i == idx;
                    return GestureDetector(
                      onTap: () => ref
                          .read(quizEngineControllerProvider.notifier)
                          .goToIndex(i),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        width: active ? 20 : 10,
                        height: 10,
                        margin:
                            const EdgeInsets.symmetric(horizontal: 3),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(5),
                          color: active
                              ? colors.primary
                              : answered
                                  ? colors.primary.withValues(alpha: 0.5)
                                  : colors.outline.withValues(alpha: 0.3),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),

          // ── Question body ────────────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  // Question text
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: colors.outlineVariant),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Row(
                            children: <Widget>[
                              _TypeChip(type: q.questionType),
                              const SizedBox(width: 8),
                              _DiffChip(
                                  difficulty: q.difficulty),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            q.questionText,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                              height: 1.5,
                            ),
                          ),
                          if (q.questionImageUrl != null &&
                              q.questionImageUrl!.isNotEmpty) ...<Widget>[
                            const SizedBox(height: 16),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                q.questionImageUrl!,
                                fit: BoxFit.contain,
                                width: double.infinity,
                                loadingBuilder: (BuildContext ctx,
                                    Widget child,
                                    ImageChunkEvent? loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  final int? total =
                                      loadingProgress.expectedTotalBytes;
                                  final double? pct = total != null
                                      ? loadingProgress
                                              .cumulativeBytesLoaded /
                                          total
                                      : null;
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 20),
                                    child: Center(
                                      child: CircularProgressIndicator(
                                          value: pct),
                                    ),
                                  );
                                },
                                errorBuilder: (BuildContext ctx,
                                    Object error, StackTrace? _) {
                                  return Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: colors.errorContainer,
                                      borderRadius:
                                          BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      children: <Widget>[
                                        Icon(Icons.broken_image_rounded,
                                            color: colors.onErrorContainer),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            'Image failed to load: $error',
                                            style: TextStyle(
                                                color:
                                                    colors.onErrorContainer,
                                                fontSize: 12),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── Answer area ──────────────────────────────────────────
                  if (q.questionType == QuestionType.mcq)
                    _McqOptions(
                      question: q,
                      selected: current,
                      onSelected: (String answer) =>
                          _record(q.questionId, answer),
                    ),

                  if (q.questionType == QuestionType.trueFalse)
                    _TrueFalseOptions(
                      selected: current,
                      onSelected: (String answer) =>
                          _record(q.questionId, answer),
                    ),

                  if (q.questionType ==
                      QuestionType.fillInTheBlank)
                    _FillBlankInput(
                      controller: _fillCtrl,
                      onChanged: (String v) {
                        if (v.trim().isEmpty) {
                          ref
                              .read(quizEngineControllerProvider.notifier)
                              .clearAnswer(questionId: q.questionId);
                        } else {
                          _record(q.questionId, v.trim());
                        }
                      },
                    ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),

          // ── Navigation row ───────────────────────────────────────────────
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Row(
                children: <Widget>[
                  OutlinedButton.icon(
                    onPressed: session.isFirst
                        ? null
                        : () => ref
                            .read(quizEngineControllerProvider.notifier)
                            .goToPrevious(),
                    icon: const Icon(Icons.chevron_left),
                    label: const Text('Prev'),
                  ),
                  const Spacer(),
                  if (session.isLast)
                    FilledButton.icon(
                      onPressed: () => _finish(session),
                      icon: const Icon(Icons.check_circle_outline),
                      label: const Text('Finish'),
                    )
                  else
                    FilledButton.icon(
                      onPressed: () => ref
                          .read(quizEngineControllerProvider.notifier)
                          .goToNext(),
                      icon: const Icon(Icons.chevron_right),
                      label: const Text('Next'),
                      iconAlignment: IconAlignment.end,
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── MCQ Options ───────────────────────────────────────────────────────────────

class _McqOptions extends StatelessWidget {
  const _McqOptions({
    super.key,
    required this.question,
    required this.selected,
    required this.onSelected,
  });

  final Question question;
  final String? selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final Map<String, String?> opts = <String, String?>{
      'A': question.optionA,
      'B': question.optionB,
      'C': question.optionC,
      'D': question.optionD,
    };
    return Column(
      children: opts.entries
          .where((MapEntry<String, String?> e) =>
              e.value != null && e.value!.isNotEmpty)
          .map((MapEntry<String, String?> e) => _OptionTile(
                label: e.key,
                text: e.value!,
                selected: selected == e.key,
                onTap: () => onSelected(e.key),
              ))
          .toList(),
    );
  }
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    super.key,
    required this.label,
    required this.text,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String text;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: selected ? colors.primaryContainer : colors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? colors.primary : colors.outlineVariant,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: <Widget>[
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color:
                    selected ? colors.primary : colors.surfaceContainerHigh,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: selected ? colors.onPrimary : colors.onSurface,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                text,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight:
                          selected ? FontWeight.w600 : FontWeight.normal,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── True/False Options ────────────────────────────────────────────────────────

class _TrueFalseOptions extends StatelessWidget {
  const _TrueFalseOptions({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final String? selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: _TFButton(
            label: 'True',
            value: 'true',
            selected: selected == 'true',
            onTap: () => onSelected('true'),
            icon: Icons.check_circle_outline,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _TFButton(
            label: 'False',
            value: 'false',
            selected: selected == 'false',
            onTap: () => onSelected('false'),
            icon: Icons.cancel_outlined,
          ),
        ),
      ],
    );
  }
}

class _TFButton extends StatelessWidget {
  const _TFButton({
    super.key,
    required this.label,
    required this.value,
    required this.selected,
    required this.onTap,
    required this.icon,
  });

  final String label;
  final String value;
  final bool selected;
  final VoidCallback onTap;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          color: selected ? colors.primaryContainer : colors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? colors.primary : colors.outlineVariant,
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          children: <Widget>[
            Icon(icon,
                size: 32,
                color: selected ? colors.primary : colors.outline),
            const SizedBox(height: 8),
            Text(
              label,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight:
                        selected ? FontWeight.bold : FontWeight.normal,
                    color: selected
                        ? colors.onPrimaryContainer
                        : colors.onSurface,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Fill in the Blank ─────────────────────────────────────────────────────────

class _FillBlankInput extends StatelessWidget {
  const _FillBlankInput({
    super.key,
    required this.controller,
    required this.onChanged,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) => TextField(
        controller: controller,
        decoration: const InputDecoration(
          labelText: 'Your Answer',
          hintText: 'Type your answer here…',
          border: OutlineInputBorder(),
          prefixIcon: Icon(Icons.edit_note),
        ),
        textCapitalization: TextCapitalization.sentences,
        maxLines: 3,
        onChanged: onChanged,
      );
}

// ── Badge helpers ─────────────────────────────────────────────────────────────

class _TypeChip extends StatelessWidget {
  const _TypeChip({super.key, required this.type});
  final QuestionType type;
  @override
  Widget build(BuildContext context) {
    final String label;
    switch (type) {
      case QuestionType.mcq:
        label = 'MCQ';
        break;
      case QuestionType.trueFalse:
        label = 'True / False';
        break;
      case QuestionType.fillInTheBlank:
        label = 'Fill in the Blank';
        break;
    }
    final ColorScheme c = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
          color: c.secondaryContainer,
          borderRadius: BorderRadius.circular(20)),
      child: Text(label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: c.onSecondaryContainer,
              fontWeight: FontWeight.w700)),
    );
  }
}

class _DiffChip extends StatelessWidget {
  const _DiffChip({super.key, required this.difficulty});
  final QuestionDifficulty difficulty;
  @override
  Widget build(BuildContext context) {
    final Color bg;
    final Color fg;
    final String label;
    switch (difficulty) {
      case QuestionDifficulty.easy:
        bg = Colors.green.shade100;
        fg = Colors.green.shade800;
        label = 'Easy';
        break;
      case QuestionDifficulty.medium:
        bg = Colors.orange.shade100;
        fg = Colors.orange.shade800;
        label = 'Medium';
        break;
      case QuestionDifficulty.hard:
        bg = Colors.red.shade100;
        fg = Colors.red.shade800;
        label = 'Hard';
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(label,
          style: Theme.of(context)
              .textTheme
              .labelSmall
              ?.copyWith(color: fg, fontWeight: FontWeight.w700)),
    );
  }
}
