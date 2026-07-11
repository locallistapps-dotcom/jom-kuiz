import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/chapter.dart';
import '../../../domain/entities/question.dart';
import '../../../domain/entities/topic.dart';
import '../../controllers/quiz_engine_controller.dart';
import '../../providers/quiz_engine_providers.dart';
import '../../providers/topic_providers.dart';
import '../../widgets/feedback/app_error_widget.dart';
import '../../widgets/feedback/empty_widget.dart';
import '../../widgets/feedback/loading_widget.dart';
import '../quiz_engine/quiz_start_screen.dart';

/// Student-facing topic browser for a specific [Chapter].
///
/// Loads all active topics for [chapter.chapterId]. Tapping "Start" on a
/// topic checks its question count, then navigates to [QuizStartScreen].
class StudentTopicScreen extends ConsumerStatefulWidget {
  const StudentTopicScreen({
    super.key,
    required this.chapter,
    required this.subjectName,
  });
  final Chapter chapter;
  final String subjectName;

  @override
  ConsumerState<StudentTopicScreen> createState() => _StudentTopicScreenState();
}

class _StudentTopicScreenState extends ConsumerState<StudentTopicScreen> {
  /// The topicId currently being loaded (null = none).
  String? _loadingTopicId;

  Future<void> _onTopicTapped(Topic topic) async {
    if (_loadingTopicId != null) return;
    setState(() => _loadingTopicId = topic.topicId);

    // Fetch the question count for this topic before launching the quiz.
    final result = await ref
        .read(quizQuestionBankRepositoryProvider)
        .getQuestions(
          topicId: topic.topicId,
          isActive: true,
          sortOrder: QuestionSortOrder.createdAtDesc,
        );

    if (!mounted) return;
    setState(() => _loadingTopicId = null);

    final int count = result.when(
      success: (list) => list.length,
      failure: (_) => 0,
    );

    if (count == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('No questions available for this topic yet. Try again later.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // Reset any previous engine state before entering a new quiz.
    ref.read(quizEngineControllerProvider.notifier).reset();
    if (!mounted) return;

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            QuizStartScreen(topicId: topic.topicId, availableCount: count),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<Topic>> topics =
        ref.watch(topicsByChapterProvider(widget.chapter.chapterId));

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              widget.chapter.chapterName,
              style: const TextStyle(fontSize: 16),
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              widget.subjectName,
              style: const TextStyle(fontSize: 12, color: Colors.white70),
            ),
          ],
        ),
      ),
      body: topics.when(
        loading: () => const LoadingWidget(message: 'Loading topics…'),
        error: (Object e, _) => AppErrorWidget(
          message: e.toString(),
          onRetry: () => ref.invalidate(
            topicsByChapterProvider(widget.chapter.chapterId),
          ),
        ),
        data: (List<Topic> list) {
          if (list.isEmpty) {
            return const EmptyWidget(
                message: 'No topics available for this chapter yet.');
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: list.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, int i) {
              final Topic topic = list[i];
              final bool isLoading = _loadingTopicId == topic.topicId;
              return _TopicCard(
                topic: topic,
                isLoading: isLoading,
                isAnyLoading: _loadingTopicId != null,
                onTap: () => _onTopicTapped(topic),
              );
            },
          );
        },
      ),
    );
  }
}

class _TopicCard extends StatelessWidget {
  const _TopicCard({
    super.key,
    required this.topic,
    required this.isLoading,
    required this.isAnyLoading,
    required this.onTap,
  });

  final Topic topic;
  final bool isLoading;
  final bool isAnyLoading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;

    return Card(
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        leading: CircleAvatar(
          backgroundColor: colors.tertiaryContainer,
          radius: 24,
          child: Icon(Icons.topic_outlined, color: colors.onTertiaryContainer),
        ),
        title: Text(
          topic.topicName,
          style:
              theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        subtitle: topic.description != null
            ? Text(
                topic.description!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              )
            : null,
        trailing: isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              )
            : FilledButton.icon(
                onPressed: isAnyLoading ? null : onTap,
                icon: const Icon(Icons.play_arrow_rounded, size: 16),
                label: const Text('Start'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 6),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  textStyle: theme.textTheme.labelMedium,
                ),
              ),
        onTap: isAnyLoading ? null : onTap,
      ),
    );
  }
}
