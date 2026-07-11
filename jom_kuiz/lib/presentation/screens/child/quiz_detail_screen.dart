import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/result.dart';
import '../../../domain/entities/quiz.dart';
import '../../controllers/quiz_controller.dart';
import '../../widgets/buttons/primary_button.dart';

/// Displays quiz details and a "Start Quiz" action.
///
/// The [Quiz] entity is received via GoRouter's `extra` parameter.
///
/// **Note:** Actual quiz-question rendering is out of scope for the Child
/// Module milestone — "Start Quiz" is a prepared extension point that will
/// be wired to the quiz engine in a future prompt.
class QuizDetailScreen extends ConsumerStatefulWidget {
  const QuizDetailScreen({super.key});

  @override
  ConsumerState<QuizDetailScreen> createState() => _QuizDetailScreenState();
}

class _QuizDetailScreenState extends ConsumerState<QuizDetailScreen> {
  bool _isStarting = false;

  /// Placeholder submission with empty answers for the "Start Quiz" button.
  Future<void> _startQuiz(Quiz quiz) async {
    setState(() => _isStarting = true);

    final Result<QuizResult> result =
        await ref.read(quizControllerProvider.notifier).submitQuiz(
              quizId: quiz.quizId,
              answers: const <String, dynamic>{},
              timeTakenSeconds: 0,
            );

    if (!mounted) return;
    setState(() => _isStarting = false);

    result.when(
      success: (QuizResult quizResult) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Quiz submitted! Score: '
              '${quizResult.score}/${quizResult.totalQuestions}',
            ),
          ),
        );
      },
      failure: (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Quiz engine is not yet available. '
              'This feature is coming soon.',
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final Quiz? quiz = GoRouterState.of(context).extra as Quiz?;

    if (quiz == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Quiz')),
        body: const Center(child: Text('Quiz not found')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(quiz.title)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          _DifficultyBanner(difficulty: quiz.difficulty),
          const SizedBox(height: 16),
          Text(
            quiz.title,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 4),
          Text(
            quiz.subject,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
          ),
          const SizedBox(height: 16),
          if (quiz.description != null && quiz.description!.isNotEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(quiz.description!),
              ),
            ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text('Details',
                      style: Theme.of(context).textTheme.titleSmall),
                  const Divider(height: 16),
                  _QuizStat(
                    icon: Icons.help_outline,
                    label: 'Questions',
                    value: '${quiz.questionCount}',
                  ),
                  const SizedBox(height: 8),
                  _QuizStat(
                    icon: Icons.timer_outlined,
                    label: 'Time Limit',
                    value: '${quiz.durationMinutes} minutes',
                  ),
                  const SizedBox(height: 8),
                  _QuizStat(
                    icon: Icons.bar_chart_outlined,
                    label: 'Difficulty',
                    value: quiz.difficulty.name,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          PrimaryButton(
            label: 'Start Quiz',
            isLoading: _isStarting,
            onPressed: () => _startQuiz(quiz),
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(
              'Quiz engine coming in a future update.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DifficultyBanner extends StatelessWidget {
  const _DifficultyBanner({super.key, required this.difficulty});
  final QuizDifficulty difficulty;

  Color _color(BuildContext context) {
    switch (difficulty) {
      case QuizDifficulty.easy:
        return Colors.green;
      case QuizDifficulty.medium:
        return Colors.orange;
      case QuizDifficulty.hard:
        return Theme.of(context).colorScheme.error;
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color c = _color(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: c.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        difficulty.name.toUpperCase(),
        style: TextStyle(color: c, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _QuizStat extends StatelessWidget {
  const _QuizStat({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Icon(icon, size: 18, color: Theme.of(context).colorScheme.outline),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
        ),
        Text(value, style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }
}
