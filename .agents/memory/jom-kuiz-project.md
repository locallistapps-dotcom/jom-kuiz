---
name: Jom Kuiz project
description: Key facts about the Jom Kuiz Flutter web app — auth, DB schema, RPC functions, known bugs fixed, quiz flow, and important implementation decisions.
---

## Stack
- Flutter web app (Flutter 2.2.1 on Replit) — cannot run `flutter analyze` locally; Dart analysis in CI (GitHub Actions)
- Raw Dio HTTP to Supabase PostgREST (no Flutter Supabase SDK)
- Riverpod for state management
- Parent admin account: locallistapps@gmail.com

## Push workflow
- `git commit` via ShellExec + `gitPush({branch:"main", provider:"github"})` in CodeExecution

## DB schema (no UUID/API/DB structure changes per user rule)
- subjects, years, chapters, topics, questions tables
- Hierarchy: subject → year → chapter → topic → question
- Questions: topic_id FK, question_text, question_type (mcq/true_false/fill_in_blank), difficulty (easy/medium/hard), correct_answer, options A-D, explanation, explanation_image_url, reference, is_active, created_at

## Known bugs fixed
- Subject lookup normalization (trim + lowercase) — commit a58fb38
- CSV column-mapping by header name (not fixed position) — commit a58fb38
- `unknown question type "easy"` symptom: Difficulty was at position 5 in user's CSV while parser hardcoded QuestionType at position 5

## Admin Question Management — 8-item spec (commit 4998667)
1. **Import Preview** — dry-run before any DB writes; shows AdminImportPreview (file, subject/year/chapter/topic, rowsFound, newQuestions, duplicates, invalidRows, validationErrors)
2. **Duplicate Check** — controller fetches all questions (limit 99999, isActive: null), builds Set<String> of "topicId||questionTextLower" signatures as existingSignatures; passed to service
3. **Import Validation** — all fields validated in preview pass; errors shown in preview dialog
4. **Import Summary** — AdminImportSummary now has: totalRows, succeeded, skipped, duplicates, failed, errors, rowResults
5. **Download Report** — AdminQuestionService.generateImportReport(rowResults) produces CSV (Row, Question, Status, Reason); triggered from summary dialog
6. **Export Filename** — _buildExportFilename(ref) reads active filter providers → builds e.g. Matematik_Tahun1_Bab1_Tambah.csv; direct download on web, no popup
7. **Hierarchy Sort** — QuestionSortOrder.hierarchyAsc → `topic_id.asc,created_at.asc` at PostgREST; default sort for admin screen
8. **Safety** — no UUID/API/DB structure changes

## Key classes (admin_question_service.dart)
- `AdminImportRowResult` — per-row outcome (rowNumber, questionText, status, reason)
- `AdminImportSummary` — import result with 5 counts + rowResults
- `AdminImportPreview` — dry-run result (no DB writes)
- `AdminImportLookups` — name→UUID maps for subject/year/chapter/topic
- `generateImportReport()` — static, produces downloadable CSV from rowResults
- `previewFromCsv()` / `previewFromJson()` — dry-run validation methods

## Key screen widgets (admin_question_screen.dart)
- `_ImportPreviewDialog` — ConsumerStatefulWidget; loads preview in initState, shows counts, Import button disabled if newQuestions == 0
- `_PreviewRow` — label/value row for preview dialog
- `_FileImportDialog` — now has `actionLabel` param (default 'Import', set to 'Preview' for admin flow)
- `_SortDropdown` — includes Hierarchy option; Hierarchy is default

## Outstanding deferred items
- `_FilterBar` in topic_screen.dart still uses plain UUID text inputs (deferred, not blocking)
- Confirm CSV column-fix (commit a58fb38) works in user's production import — user hasn't confirmed the Import button post-fix
