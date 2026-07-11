import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/quiz_engine.dart';
import '../../controllers/quiz_engine_controller.dart';
import 'quiz_screen.dart';

/// Lets the user choose how many questions to include in the quiz.
///
/// Passed [availableCount] from [QuizHomeScreen] so that options exceeding
/// the pool are greyed out automatically. "All" always shows the full pool.
class QuizStartScreen extends ConsumerStatefulWidget {
  const QuizStartScreen({
    super.key,
    required this.topicId,
    required this.availableCount,
  });

  final String topicId;
  final int availableCount;

  @override
  ConsumerState<QuizStartScreen> createState() => _QuizStartScreenState();
}

class _QuizStartScreenState extends ConsumerState<QuizStartScreen> {
  static const List<int> _presets = <int>[5, 10, 20];

  /// 0 = All questions
  int _selected = 0;
  bool _starting = false;

  String _labelFor(int count) {
    if (count == 0) {
      return 'All (${widget.availableCount})';
    }
    return count.toString();
  }

  bool _isDisabled(int count) {
    if (count == 0) return false; // All is always enabled if pool > 0
    return count > widget.availableCount;
  }

  Future<void> _begin() async {
    setState(() => _starting = true);

    await ref.read(quizEngineControllerProvider.notifier).startQuiz(
          topicId: widget.topicId,
          count: _selected,
        );

    if (!mounted) return;
    final QuizEnginePhase phase =
        ref.read(quizEngineControllerProvider);

    if (phase is QuizPlaying) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(builder: (_) => const QuizScreen()),
      );
    } else if (phase is QuizEngineError) {
      setState(() => _starting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(phase.message),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      setState(() => _starting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Quiz Setup')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            // Topic info chip
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: colors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: colors.outlineVariant),
              ),
              child: Row(
                children: <Widget>[
                  Icon(Icons.topic_outlined,
                      size: 16, color: colors.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Topic: ${_short(widget.topicId)}',
                      style: theme.textTheme.bodySmall
                          ?.copyWith(fontFamily: 'monospace'),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: colors.primaryContainer,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${widget.availableCount} questions',
                      style: theme.textTheme.labelSmall?.copyWith(
                          color: colors.onPrimaryContainer,
                          fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            Text(
              'How many questions?',
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              'Questions are randomized automatically.',
              style: theme.textTheme.bodyMedium?.copyWith(
                  color: colors.onSurface.withValues(alpha: 0.55)),
            ),
            const SizedBox(height: 20),

            // ── Preset tiles ───────────────────────────────────────────────
            ...(<int>[..._presets, 0]).map((int count) {
              final bool disabled = _isDisabled(count);
              final bool selected = _selected == count;
              return GestureDetector(
                onTap: disabled ? null : () => setState(() => _selected = count),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 16),
                  decoration: BoxDecoration(
                    color: selected
                        ? colors.primaryContainer
                        : disabled
                            ? colors.surfaceContainerLow
                            : colors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: selected
                          ? colors.primary
                          : disabled
                              ? colors.outlineVariant
                              : colors.outline,
                      width: selected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: <Widget>[
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: selected ? colors.primary : Colors.transparent,
                          border: Border.all(
                            color: selected
                                ? colors.primary
                                : disabled
                                    ? colors.outlineVariant
                                    : colors.outline,
                            width: 2,
                          ),
                        ),
                        child: selected
                            ? Icon(Icons.check,
                                size: 14, color: colors.onPrimary)
                            : null,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          count == 0
                              ? 'All Questions'
                              : '$count Questions',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: selected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: disabled
                                ? colors.onSurface.withValues(alpha: 0.35)
                                : selected
                                    ? colors.onPrimaryContainer
                                    : colors.onSurface,
                          ),
                        ),
                      ),
                      Text(
                        _labelFor(count),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: disabled
                              ? colors.onSurface.withValues(alpha: 0.35)
                              : colors.onSurface.withValues(alpha: 0.55),
                        ),
                      ),
                      if (disabled) ...<Widget>[
                        const SizedBox(width: 6),
                        Icon(Icons.lock_outline,
                            size: 14,
                            color: colors.onSurface.withValues(alpha: 0.35)),
                      ],
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 28),

            FilledButton.icon(
              onPressed:
                  (!_starting && widget.availableCount > 0) ? _begin : null,
              icon: _starting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.play_arrow_rounded),
              label: Text(_starting ? 'Loading…' : 'Begin Quiz'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _short(String id) =>
      id.length > 20 ? '${id.substring(0, 20)}…' : id;
}
