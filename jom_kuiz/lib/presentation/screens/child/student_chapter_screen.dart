import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/chapter.dart';
import '../../../domain/entities/subject.dart';
import '../../providers/chapter_providers.dart';
import '../../widgets/feedback/app_error_widget.dart';
import '../../widgets/feedback/empty_widget.dart';
import '../../widgets/feedback/loading_widget.dart';
import 'student_topic_screen.dart';

/// Student-facing chapter browser for a specific [Subject].
///
/// Loads all active chapters for [subject.subjectId] from Supabase and
/// presents them as tappable cards. Tapping navigates to [StudentTopicScreen].
class StudentChapterScreen extends ConsumerWidget {
  const StudentChapterScreen({super.key, required this.subject});
  final Subject subject;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<Chapter>> chapters =
        ref.watch(chaptersBySubjectProvider(subject.subjectId));

    return Scaffold(
      appBar: AppBar(title: Text(subject.subjectName)),
      body: chapters.when(
        loading: () => const LoadingWidget(message: 'Loading chapters…'),
        error: (Object e, _) => AppErrorWidget(
          message: e.toString(),
          onRetry: () =>
              ref.invalidate(chaptersBySubjectProvider(subject.subjectId)),
        ),
        data: (List<Chapter> list) {
          if (list.isEmpty) {
            return const EmptyWidget(
                message: 'No chapters available for this subject yet.');
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: list.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, int i) => _ChapterCard(
              chapter: list[i],
              subjectName: subject.subjectName,
            ),
          );
        },
      ),
    );
  }
}

class _ChapterCard extends StatelessWidget {
  const _ChapterCard({
    super.key,
    required this.chapter,
    required this.subjectName,
  });
  final Chapter chapter;
  final String subjectName;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;

    return Card(
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        leading: CircleAvatar(
          backgroundColor: colors.secondaryContainer,
          radius: 24,
          child: Icon(Icons.menu_book_outlined,
              color: colors.onSecondaryContainer),
        ),
        title: Text(
          chapter.chapterName,
          style:
              theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        subtitle: chapter.description != null
            ? Text(
                chapter.description!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              )
            : null,
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => StudentTopicScreen(
              chapter: chapter,
              subjectName: subjectName,
            ),
          ),
        ),
      ),
    );
  }
}
