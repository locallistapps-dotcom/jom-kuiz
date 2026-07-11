import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/failure.dart';
import '../../../core/utils/result.dart';
import '../../../domain/entities/question.dart';
import '../../controllers/question_bank_controller.dart';

/// Read-only detail view for a single Question.
///
/// Pushed from [QuestionBankScreen] when the user taps a question card.
/// The Edit and Delete actions delegate back to [QuestionBankController].
class QuestionDetailScreen extends ConsumerWidget {
  const QuestionDetailScreen({super.key, required this.question});

  final Question question;

  void _showSnack(BuildContext context, String message,
      {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor:
            isError ? Theme.of(context).colorScheme.error : null,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Question'),
        content: const Text(
          'Are you sure you want to delete this question? '
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
      ),
    );

    if (confirmed != true || !context.mounted) return;

    final Result<void> result = await ref
        .read(questionBankControllerProvider.notifier)
        .deleteQuestion(questionId: question.questionId);

    if (!context.mounted) return;
    result.when(
      success: (_) {
        Navigator.of(context).pop();
        _showSnack(context, 'Question deleted');
      },
      failure: (Failure f) => _showSnack(context, f.message, isError: true),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Question Detail'),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Delete',
            color: colors.error,
            onPressed: () => _confirmDelete(context, ref),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: <Widget>[
          // Type + Difficulty + Status badges
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              _TypeBadge(type: question.questionType),
              _DifficultyBadge(difficulty: question.difficulty),
              _StatusBadge(isActive: question.isActive),
            ],
          ),
          const SizedBox(height: 16),

          // Question text card
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: colors.outlineVariant),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                question.questionText,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  height: 1.5,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Options (MCQ / True-False)
          if (question.questionType == QuestionType.mcq)
            _McqOptionsCard(question: question),

          if (question.questionType == QuestionType.trueFalse)
            _TrueFalseCard(correctAnswer: question.correctAnswer),

          if (question.questionType == QuestionType.fillInTheBlank) ...<Widget>[
            _SectionTitle(label: 'Expected Answer'),
            const SizedBox(height: 8),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: colors.outlineVariant),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  question.correctAnswer,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colors.primary,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Explanation
          if (question.explanation != null &&
              question.explanation!.isNotEmpty) ...<Widget>[
            _SectionTitle(label: 'Explanation'),
            const SizedBox(height: 8),
            Card(
              elevation: 0,
              color: colors.surfaceContainerLow,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  question.explanation!,
                  style: theme.textTheme.bodyMedium,
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Metadata
          _SectionTitle(label: 'Metadata'),
          const SizedBox(height: 8),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: colors.outlineVariant),
            ),
            child: Column(
              children: <Widget>[
                _MetaRow(label: 'Question ID', value: question.questionId, mono: true),
                const Divider(height: 1),
                _MetaRow(label: 'Topic ID', value: question.topicId, mono: true),
                const Divider(height: 1),
                _MetaRow(label: 'Created', value: _fmtDate(question.createdAt)),
                const Divider(height: 1),
                _MetaRow(label: 'Updated', value: _fmtDate(question.updatedAt)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _fmtDate(DateTime dt) =>
      '${dt.year}-${_p(dt.month)}-${_p(dt.day)} ${_p(dt.hour)}:${_p(dt.minute)}';
  String _p(int n) => n.toString().padLeft(2, '0');
}

// ── MCQ options card ──────────────────────────────────────────────────────────

class _McqOptionsCard extends StatelessWidget {
  const _McqOptionsCard({super.key, required this.question});

  final Question question;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final Map<String, String?> opts = <String, String?>{
      'A': question.optionA,
      'B': question.optionB,
      'C': question.optionC,
      'D': question.optionD,
    };
    final String correct = question.correctAnswer.toUpperCase();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _SectionTitle(label: 'Options'),
        const SizedBox(height: 8),
        ...opts.entries
            .where((MapEntry<String, String?> e) =>
                e.value != null && e.value!.isNotEmpty)
            .map((MapEntry<String, String?> e) {
          final bool isCorrect = e.key == correct;
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isCorrect ? colors.primaryContainer : colors.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isCorrect ? colors.primary : colors.outlineVariant,
                width: isCorrect ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: <Widget>[
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: isCorrect ? colors.primary : colors.surfaceContainerHigh,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    e.key,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: isCorrect
                          ? colors.onPrimary
                          : colors.onSurface,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    e.value!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight:
                              isCorrect ? FontWeight.w600 : FontWeight.normal,
                        ),
                  ),
                ),
                if (isCorrect)
                  Icon(Icons.check_circle, color: colors.primary, size: 20),
              ],
            ),
          );
        }),
        const SizedBox(height: 8),
      ],
    );
  }
}

// ── True-False card ───────────────────────────────────────────────────────────

class _TrueFalseCard extends StatelessWidget {
  const _TrueFalseCard({super.key, required this.correctAnswer});

  final String correctAnswer;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final bool isTrue = correctAnswer.toLowerCase() == 'true';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _SectionTitle(label: 'Correct Answer'),
        const SizedBox(height: 8),
        Row(
          children: <Widget>[
            _TFChip(label: 'True', selected: isTrue, colors: colors),
            const SizedBox(width: 12),
            _TFChip(label: 'False', selected: !isTrue, colors: colors),
          ],
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

class _TFChip extends StatelessWidget {
  const _TFChip({
    super.key,
    required this.label,
    required this.selected,
    required this.colors,
  });

  final String label;
  final bool selected;
  final ColorScheme colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      decoration: BoxDecoration(
        color: selected ? colors.primaryContainer : colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: selected ? colors.primary : colors.outlineVariant,
          width: selected ? 1.5 : 1,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontWeight: selected ? FontWeight.bold : FontWeight.normal,
          color: selected ? colors.onPrimaryContainer : colors.onSurface,
        ),
      ),
    );
  }
}

// ── Shared sub-widgets ────────────────────────────────────────────────────────

class _TypeBadge extends StatelessWidget {
  const _TypeBadge({super.key, required this.type});

  final QuestionType type;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: colors.secondaryContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: colors.onSecondaryContainer,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

class _DifficultyBadge extends StatelessWidget {
  const _DifficultyBadge({super.key, required this.difficulty});

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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: fg,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({super.key, required this.isActive});

  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isActive ? colors.primaryContainer : colors.errorContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        isActive ? 'Active' : 'Inactive',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: isActive
                  ? colors.onPrimaryContainer
                  : colors.onErrorContainer,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({super.key, required this.label});
  final String label;
  @override
  Widget build(BuildContext context) => Text(
        label.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color:
                  Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
              fontWeight: FontWeight.w700,
              letterSpacing: 1.1,
            ),
      );
}

class _MetaRow extends StatelessWidget {
  const _MetaRow(
      {super.key,
      required this.label,
      required this.value,
      this.mono = false});
  final String label;
  final String value;
  final bool mono;
  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 90,
            child: Text(label,
                style: theme.textTheme.bodySmall?.copyWith(
                    color:
                        theme.colorScheme.onSurface.withValues(alpha: 0.55))),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: mono
                  ? theme.textTheme.bodySmall
                      ?.copyWith(fontFamily: 'monospace', fontSize: 11)
                  : theme.textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}
