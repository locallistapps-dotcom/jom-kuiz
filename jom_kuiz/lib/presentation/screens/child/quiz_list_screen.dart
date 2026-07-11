import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routing/app_routes.dart';
import '../../../domain/entities/quiz.dart';
import '../../controllers/quiz_controller.dart';
import '../../widgets/feedback/app_error_widget.dart';
import '../../widgets/feedback/empty_widget.dart';
import '../../widgets/feedback/loading_widget.dart';

/// Lists all quizzes available for the child to attempt.
class QuizListScreen extends ConsumerWidget {
  const QuizListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<Quiz>> state = ref.watch(quizControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Quizzes')),
      body: state.when(
        loading: () => const LoadingWidget(message: 'Loading quizzes...'),
        error: (Object error, _) => AppErrorWidget(
          message: error.toString(),
          onRetry: () => ref.read(quizControllerProvider.notifier).refresh(),
        ),
        data: (List<Quiz> quizzes) {
          if (quizzes.isEmpty) {
            return const EmptyWidget(message: 'No quizzes available yet');
          }
          return RefreshIndicator(
            onRefresh: () =>
                ref.read(quizControllerProvider.notifier).refresh(),
            child: ListView.separated(
              padding: const EdgeInsets.all(8),
              itemCount: quizzes.length,
              separatorBuilder: (_, __) => const SizedBox(height: 4),
              itemBuilder: (_, int index) =>
                  _QuizCard(quiz: quizzes[index]),
            ),
          );
        },
      ),
    );
  }
}

class _QuizCard extends StatelessWidget {
  const _QuizCard({super.key, required this.quiz});
  final Quiz quiz;

  Color _difficultyColor(BuildContext context) {
    switch (quiz.difficulty) {
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
    final Color diffColor = _difficultyColor(context);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: diffColor.withOpacity(0.15),
          child: Icon(Icons.quiz_outlined, color: diffColor),
        ),
        title: Text(quiz.title),
        subtitle: Text(
          '${quiz.subject} · ${quiz.questionCount} Qs · '
          '${quiz.durationMinutes} min',
        ),
        trailing: Chip(
          label: Text(quiz.difficulty.name),
          visualDensity: VisualDensity.compact,
          backgroundColor: diffColor.withOpacity(0.12),
          labelStyle: TextStyle(color: diffColor, fontSize: 11),
        ),
        onTap: () =>
            context.push(AppRoutes.childQuizDetail, extra: quiz),
      ),
    );
  }
}
