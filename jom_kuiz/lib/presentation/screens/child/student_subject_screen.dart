import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/subject.dart';
import '../../providers/subject_providers.dart';
import '../../widgets/feedback/app_error_widget.dart';
import '../../widgets/feedback/empty_widget.dart';
import '../../widgets/feedback/loading_widget.dart';
import 'student_chapter_screen.dart';

/// Student-facing subject browser.
///
/// Lists every active [Subject] loaded from Supabase. Tapping a card
/// navigates forward to [StudentChapterScreen] for that subject.
class StudentSubjectScreen extends ConsumerWidget {
  const StudentSubjectScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<Subject>> subjects =
        ref.watch(activeSubjectsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Choose a Subject')),
      body: subjects.when(
        loading: () => const LoadingWidget(message: 'Loading subjects…'),
        error: (Object e, _) => AppErrorWidget(
          message: e.toString(),
          onRetry: () => ref.invalidate(activeSubjectsProvider),
        ),
        data: (List<Subject> list) {
          if (list.isEmpty) {
            return const EmptyWidget(
                message: 'No subjects available yet. Ask your admin.');
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: list.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, int i) => _SubjectCard(subject: list[i]),
          );
        },
      ),
    );
  }
}

class _SubjectCard extends StatelessWidget {
  const _SubjectCard({super.key, required this.subject});
  final Subject subject;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;

    // Use the stored icon string (emoji or text), fall back to a book emoji.
    final String iconText = (subject.icon != null && subject.icon!.isNotEmpty)
        ? subject.icon!
        : '📚';

    return Card(
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        leading: CircleAvatar(
          backgroundColor: colors.primaryContainer,
          radius: 24,
          child: Text(iconText, style: const TextStyle(fontSize: 20)),
        ),
        title: Text(
          subject.subjectName,
          style:
              theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        subtitle: subject.description != null
            ? Text(
                subject.description!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              )
            : null,
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => StudentChapterScreen(subject: subject),
          ),
        ),
      ),
    );
  }
}
