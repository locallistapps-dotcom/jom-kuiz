import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/quiz_engine.dart';
import '../../controllers/quiz_engine_controller.dart';
import 'quiz_home_screen.dart';
import 'quiz_review_screen.dart';
import 'quiz_start_screen.dart';

/// Displays the aggregated outcome of a completed quiz attempt.
///
/// Shows:
/// - Score % (large, colour-coded)
/// - Pass / Fail label
/// - Stat tiles: Total, Correct, Wrong, Skipped, Time
///
/// Actions:
/// - Review Answers → pushes [QuizReviewScreen]
/// - Restart Quiz   → resets engine, pushes [QuizStartScreen] with same topic
/// - Back to Home   → pops to [QuizHomeScreen]
class QuizResultScreen extends ConsumerWidget {
  const QuizResultScreen({super.key, required this.result});

  final QuizEngineResult result;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;
    final bool passed = result.isPassed;
    final Color scoreColor =
        passed ? Colors.green.shade700 : colors.error;
    final Color scoreBg =
        passed ? Colors.green.shade50 : colors.errorContainer;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quiz Result'),
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.home_outlined),
          tooltip: 'Back to Home',
          onPressed: () {
            ref
                .read(quizEngineControllerProvider.notifier)
                .reset();
            Navigator.of(context).popUntil(
              (Route<dynamic> r) => r.isFirst,
            );
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            // ── Score hero ─────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(vertical: 32),
              decoration: BoxDecoration(
                color: scoreBg,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: <Widget>[
                  Icon(
                    passed ? Icons.emoji_events_rounded : Icons.sentiment_dissatisfied_rounded,
                    size: 56,
                    color: scoreColor,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '${result.percentage.toStringAsFixed(1)} %',
                    style: theme.textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: scoreColor,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 4),
                    decoration: BoxDecoration(
                      color:
                          passed ? Colors.green.shade200 : colors.error,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      passed ? 'PASSED' : 'KEEP PRACTISING',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: passed ? Colors.green.shade900 : colors.onError,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── Stat grid ──────────────────────────────────────────────────
            _StatGrid(result: result),
            const SizedBox(height: 24),

            // ── Buttons ────────────────────────────────────────────────────
            FilledButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) =>
                      QuizReviewScreen(answers: result.answers),
                ),
              ),
              icon: const Icon(Icons.list_alt_rounded),
              label: const Text('Review Answers'),
              style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14)),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () {
                ref
                    .read(quizEngineControllerProvider.notifier)
                    .reset();
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute<void>(
                    builder: (_) => QuizStartScreen(
                      topicId: result.topicId,
                      availableCount: result.totalQuestions,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.replay_rounded),
              label: const Text('Restart Quiz'),
              style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14)),
            ),
            const SizedBox(height: 10),
            TextButton.icon(
              onPressed: () {
                ref
                    .read(quizEngineControllerProvider.notifier)
                    .reset();
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute<void>(
                      builder: (_) => const QuizHomeScreen()),
                  (Route<dynamic> r) => r.isFirst,
                );
              },
              icon: const Icon(Icons.home_outlined),
              label: const Text('Back to Home'),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Stat Grid ─────────────────────────────────────────────────────────────────

class _StatGrid extends StatelessWidget {
  const _StatGrid({super.key, required this.result});
  final QuizEngineResult result;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
                child: _StatTile(
              label: 'Total',
              value: result.totalQuestions.toString(),
              icon: Icons.quiz_outlined,
              color: Colors.blue,
            )),
            const SizedBox(width: 10),
            Expanded(
                child: _StatTile(
              label: 'Correct',
              value: result.correctCount.toString(),
              icon: Icons.check_circle_outline,
              color: Colors.green,
            )),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: <Widget>[
            Expanded(
                child: _StatTile(
              label: 'Wrong',
              value: result.wrongCount.toString(),
              icon: Icons.cancel_outlined,
              color: Colors.red,
            )),
            const SizedBox(width: 10),
            Expanded(
                child: _StatTile(
              label: 'Skipped',
              value: result.skippedCount.toString(),
              icon: Icons.remove_circle_outline,
              color: Colors.orange,
            )),
          ],
        ),
        const SizedBox(height: 10),
        _StatTile(
          label: 'Time Taken',
          value: result.timeTakenFormatted,
          icon: Icons.timer_outlined,
          color: Colors.purple,
          wide: true,
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.wide = false,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Row(
        mainAxisAlignment:
            wide ? MainAxisAlignment.center : MainAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(label,
                  style: theme.textTheme.labelSmall?.copyWith(
                      color:
                          colors.onSurface.withValues(alpha: 0.55))),
              Text(value,
                  style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }
}
