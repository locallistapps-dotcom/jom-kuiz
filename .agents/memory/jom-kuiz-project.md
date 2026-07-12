---
name: Jom Kuiz Flutter project
description: Key facts about the Jom Kuiz Flutter web app — auth, DB schema, RPC functions, known patterns, quiz flow, and admin CMS decisions
---

## Infrastructure
- Flutter Web only (GitHub Pages). Builds via GitHub Actions `subosito/flutter-action@v2 channel:stable`.
- Replit environment has only Flutter 2.2.1 — cannot run `flutter analyze` locally; rely on CI.
- Push workflow: `git commit` via ShellExec, then `gitPush({branch:"main", provider:"github"})` in CodeExecution.
- Raw Dio HTTP (no Supabase Flutter SDK). `dioProvider` → PostgREST `/rest/v1`; `authDioProvider` → GoTrue `/auth/v1`.

## Auth
- Parent/admin UUID: `b561d4cd-2e7e-4f95-a7b5-b53e85bd4b72`, email: `locallistapps@gmail.com`

## DB Schema (confirmed column names)
- `subjects`: id, subject_name, display_order, is_active
- `years`: id, year_name, display_order, is_active
- `chapters`: id, subject_id, year_id, chapter_name, description, display_order, is_active
- `topics`: id, chapter_id, topic_name, description, display_order, is_active
- `questions`: id, topic_id, question_text, question_type, difficulty, option_a–d, correct_answer, explanation, explanation_image_url, explanation_video_url, question_image_url, reference, is_active, created_at, updated_at

## Current DB Data
- 1 subject: Matematik (`a0000000-…001`)
- 1 year: Tahun 1 (`…002`)
- 1 chapter: Nombor (`…003`)
- 1 topic: Tambah (`…004`)
- 102 questions
- Migration `20260712000001_kssr_matematik_tahun1_hierarchy.sql`: adds 7 more chapters + ~16 topics (idempotent, WHERE NOT EXISTS pattern).

## Key Providers
- `adminAllTopicsProvider` → `AsyncValue<Map<String, Topic>>` (all topics, for name lookup)
- `adminAllChaptersProvider` → `AsyncValue<Map<String, Chapter>>` (all chapters)
- `adminSubjectsDropdownProvider`, `adminYearsDropdownProvider`, `adminChaptersDropdownProvider({subjectId,yearId})`, `adminTopicsDropdownProvider(chapterId)`
- `adminQuestionControllerProvider` → `AsyncNotifier<List<Question>>`

## Key Service Methods
- `AdminQuestionService.importFromCsv()` / `.importFromJson()` — both return `AdminImportSummary`
- `AdminQuestionService.exportToCsvWithNames(questions, {topicsById, chaptersById, subjectsById, yearsById})` — human-readable CSV
- `AdminQuestionService.jsonImportTemplate` — static getter, returns JSON template string
- `AdminImportLookups.from(subjects, years, chapters, topics)` — builds name→id maps

## Controller Methods
- `controller.importFromCsv(csvContent:)` / `controller.importFromJson(jsonContent:)` — async, fetch all entities internally, return `AdminImportSummary`
- `controller.exportToCsv()` → `Future<String>` (async! fetches entity names, uses exportToCsvWithNames)

**Why async exportToCsv matters:** Changed from sync to async in Phase 3. Any caller must `await` it. The screen's `_exportCsv` is `static Future<void>` — call with `onPressed: () => _exportCsv(context, ref)` is fine (future fire-and-forget from button).

## web_file_download Pattern
- Two files: `lib/core/utils/web_file_download.dart` (dart:html implementation) and `web_file_download_stub.dart` (clipboard fallback).
- Import in screen with conditional: `import '.../web_file_download_stub.dart' if (dart.library.html) '.../web_file_download.dart';`
- Function signature: `Future<void> triggerFileDownload(String content, String filename, String mimeType)`

**Why:** Avoids `dart:html` in non-web compilation units while supporting real browser downloads on Flutter Web.

## Admin Screen Architecture (Phase 3 complete)
- `_FileImportDialog` replaces `_CsvImportDialog`: file_picker batch selection, progress indicator, template download button, supports both CSV and JSON via `_ImportMode` enum.
- AppBar: Templates dropdown (CSV+JSON), Import CSV, Import JSON, Export CSV, Refresh.
- `_QuestionCard`: shows Q{index+1} chip + topic-name chip (from `adminAllTopicsProvider`).
- `_QuestionPreviewDialog`: `ConsumerWidget`, shows Q{n} + topic name metadata at top.
- `AdminQuestionFormSheet`: `_hierarchyResolved` flag + `addPostFrameCallback` in build to auto-resolve Subject/Year/Chapter when editing a question.

## Hierarchy Auto-Resolution Pattern
Watch `adminAllTopicsProvider` + `adminAllChaptersProvider` in the form build. When `!_hierarchyResolved` and both maps are loaded, schedule `setState` via `addPostFrameCallback`. The `_hierarchyResolved` flag prevents multiple callbacks after the first setState.

## Import Duplicate Detection
In-batch only (topicId||questionTextLower signature). No per-row DB lookup. Batch errors prefixed with `[filename]` when showing the summary dialog.
