import 'package:flutter/material.dart';

import '../../../domain/entities/question.dart';
import '../../../domain/entities/quiz_engine.dart';

/// Shows every answered (or skipped) question after quiz submission.
///
/// For each question displays:
///   - Question text
///   - User's answer (green if correct, red if wrong, grey if skipped)
///   - Correct answer (always green)
///   - Explanation text (if present; never shown during the quiz)
///   - Explanation image (if explanationImageUrl is set)
///   - "No explanation provided." fallback
///
/// Explanation is deliberately hidden while the quiz is in progress
/// and only revealed on this post-submission screen.
class QuizReviewScreen extends StatelessWidget {
  const QuizReviewScreen({super.key, required this.answers});

  final List<QuizEngineAnswer> answers;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Review (${answers.length} questions)'),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        itemCount: answers.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (BuildContext ctx, int i) =>
            _ReviewCard(index: i, answer: answers[i]),
      ),
    );
  }
}

// ── Review Card ───────────────────────────────────────────────────────────────

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({
    super.key,
    required this.index,
    required this.answer,
  });

  final int index;
  final QuizEngineAnswer answer;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;
    final bool skipped = answer.givenAnswer == null;
    final bool correct = answer.isCorrect;

    // Card border colour
    final Color borderColor = skipped
        ? colors.outlineVariant
        : correct
            ? Colors.green.shade400
            : Colors.red.shade400;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: borderColor, width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // ── Header row ─────────────────────────────────────────────────
            Row(
              children: <Widget>[
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: skipped
                        ? colors.surfaceContainerHigh
                        : correct
                            ? Colors.green.shade100
                            : Colors.red.shade100,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: skipped
                      ? Icon(Icons.remove,
                          size: 14, color: colors.onSurface.withValues(alpha: 0.5))
                      : Icon(
                          correct ? Icons.check : Icons.close,
                          size: 14,
                          color: correct
                              ? Colors.green.shade700
                              : Colors.red.shade700,
                        ),
                ),
                const SizedBox(width: 10),
                Text(
                  'Question ${index + 1}',
                  style: theme.textTheme.labelLarge
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const Spacer(),
                _TypeBadge(type: answer.question.questionType),
              ],
            ),
            const SizedBox(height: 12),

            // ── Question text ──────────────────────────────────────────────
            Text(
              answer.question.questionText,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 14),

            // ── Answer comparison ──────────────────────────────────────────
            if (skipped)
              _AnswerRow(
                label: 'Your Answer',
                value: '— skipped —',
                color: colors.onSurface.withValues(alpha: 0.45),
                bg: colors.surfaceContainerLow,
              )
            else
              _AnswerRow(
                label: 'Your Answer',
                value: _displayAnswer(
                    answer.givenAnswer!, answer.question),
                color: correct
                    ? Colors.green.shade800
                    : Colors.red.shade800,
                bg: correct
                    ? Colors.green.shade50
                    : Colors.red.shade50,
                icon: correct ? Icons.check_circle : Icons.cancel,
              ),
            const SizedBox(height: 6),
            _AnswerRow(
              label: 'Correct Answer',
              value: _displayAnswer(
                  answer.correctAnswer, answer.question),
              color: Colors.green.shade800,
              bg: Colors.green.shade50,
              icon: Icons.check_circle,
            ),
            const SizedBox(height: 14),
            const Divider(height: 1),
            const SizedBox(height: 14),

            // ── Explanation ────────────────────────────────────────────────
            Text(
              'EXPLANATION',
              style: theme.textTheme.labelSmall?.copyWith(
                color: colors.onSurface.withValues(alpha: 0.5),
                fontWeight: FontWeight.w700,
                letterSpacing: 1.1,
              ),
            ),
            const SizedBox(height: 8),

            if (answer.question.explanation != null &&
                answer.question.explanation!.isNotEmpty) ...<Widget>[
              Text(
                answer.question.explanation!,
                style: theme.textTheme.bodySmall
                    ?.copyWith(height: 1.6),
              ),
              // ── Explanation image ────────────────────────────────────────
              if (answer.question.explanationImageUrl != null &&
                  answer.question.explanationImageUrl!.isNotEmpty) ...<Widget>[
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    answer.question.explanationImageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      height: 80,
                      decoration: BoxDecoration(
                        color: colors.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      alignment: Alignment.center,
                      child: Icon(Icons.broken_image_outlined,
                          color: colors.outline),
                    ),
                  ),
                ),
              ],
            ] else
              Text(
                'No explanation provided.',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontStyle: FontStyle.italic,
                  color: colors.onSurface.withValues(alpha: 0.45),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Converts a stored answer key to a human-readable string.
  ///
  /// MCQ: 'A' → 'A. [option text]'
  /// T/F: 'true' → 'True'
  /// Fill: returns as-is
  String _displayAnswer(String answer, Question q) {
    switch (q.questionType) {
      case QuestionType.mcq:
        final Map<String, String?> opts = <String, String?>{
          'A': q.optionA,
          'B': q.optionB,
          'C': q.optionC,
          'D': q.optionD,
        };
        final String? text = opts[answer.toUpperCase()];
        return text != null && text.isNotEmpty
            ? '${answer.toUpperCase()}. $text'
            : answer.toUpperCase();
      case QuestionType.trueFalse:
        return answer.toLowerCase() == 'true' ? 'True' : 'False';
      case QuestionType.fillInTheBlank:
        return answer;
    }
  }
}

// ── Answer Row ────────────────────────────────────────────────────────────────

class _AnswerRow extends StatelessWidget {
  const _AnswerRow({
    super.key,
    required this.label,
    required this.value,
    required this.color,
    required this.bg,
    this.icon,
  });

  final String label;
  final String value;
  final Color color;
  final Color bg;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (icon != null) ...<Widget>[
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 8),
          ],
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                    color: color.withValues(alpha: 0.75)),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Type Badge ────────────────────────────────────────────────────────────────

class _TypeBadge extends StatelessWidget {
  const _TypeBadge({super.key, required this.type});
  final QuestionType type;
  @override
  Widget build(BuildContext context) {
    final String label;
    switch (type) {
      case QuestionType.mcq:
        label = 'MCQ';
        break;
      case QuestionType.trueFalse:
        label = 'T / F';
        break;
      case QuestionType.fillInTheBlank:
        label = 'Fill';
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
