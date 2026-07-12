import 'dart:convert';

import '../../core/error/admin_error_codes.dart';
import '../../core/error/failure.dart';
import '../../core/utils/result.dart';
import '../../domain/entities/chapter.dart';
import '../../domain/entities/question.dart';
import '../../domain/entities/subject.dart';
import '../../domain/entities/topic.dart';
import '../../domain/entities/year.dart';
import '../../domain/repositories/question_bank_repository.dart';

/// Per-row outcome recorded during an import operation.
class AdminImportRowResult {
  const AdminImportRowResult({
    required this.rowNumber,
    required this.questionText,
    required this.status,
    required this.reason,
  });

  final int rowNumber;
  final String questionText;

  /// 'Imported', 'Skipped', 'Duplicate', or 'Failed'
  final String status;

  /// Empty string for successfully imported rows.
  final String reason;
}

/// Result of a CSV / JSON import operation.
class AdminImportSummary {
  const AdminImportSummary({
    required this.totalRows,
    required this.succeeded,
    required this.skipped,
    required this.errors,
    this.duplicates = 0,
    this.failed = 0,
    this.rowResults = const <AdminImportRowResult>[],
  });

  /// Total data rows parsed (excluding header).
  final int totalRows;

  /// Rows successfully created in the database.
  final int succeeded;

  /// Rows skipped due to validation errors (not counting duplicates or DB
  /// write failures).
  final int skipped;

  /// Rows skipped because the same question already exists in the database.
  final int duplicates;

  /// Rows that passed validation but failed at the DB write step.
  final int failed;

  /// Human-readable error messages per row (1-indexed).
  final List<String> errors;

  /// Per-row outcomes for generating the downloadable import report.
  final List<AdminImportRowResult> rowResults;
}

/// Dry-run result shown in the Import Preview dialog.
///
/// No questions are written to the database — this is a validation-only pass.
class AdminImportPreview {
  const AdminImportPreview({
    required this.fileName,
    required this.subjects,
    required this.years,
    required this.chapters,
    required this.topics,
    required this.rowsFound,
    required this.newQuestions,
    required this.duplicates,
    required this.invalidRows,
    required this.validationErrors,
  });

  final String fileName;

  /// Unique subject names resolved from the file (empty on header error).
  final List<String> subjects;
  final List<String> years;
  final List<String> chapters;
  final List<String> topics;

  final int rowsFound;

  /// Rows that are valid, non-duplicate — would be inserted on actual import.
  final int newQuestions;

  /// Rows skipped because the same question already exists in the database.
  final int duplicates;

  /// Rows that failed validation (wrong type, unknown subject, etc.).
  final int invalidRows;

  /// Human-readable validation error messages (shown before import).
  final List<String> validationErrors;
}

/// Admin-specific question operations that extend the base
/// [QuestionBankRepository] with bulk, CSV, and duplication capabilities.
///
/// Lives above the repository — it orchestrates multiple repository calls
/// and keeps the controller thin.
class AdminQuestionService {
  const AdminQuestionService({required QuestionBankRepository repository})
      : _repository = repository;

  final QuestionBankRepository _repository;

  static const Set<String> _mcqAnswers = <String>{'A', 'B', 'C', 'D'};
  static const Set<String> _tfAnswers = <String>{'true', 'false'};

  // ── Duplicate ──────────────────────────────────────────────────────────────

  /// Fetches [questionId] and re-creates it with "(Copy)" appended to the
  /// question text, resetting [Question.isActive] to true.
  Future<Result<Question>> duplicateQuestion({
    required String questionId,
  }) async {
    final Result<Question> fetchResult =
        await _repository.getQuestionById(questionId: questionId);

    return fetchResult.when(
      success: (Question q) => _repository.createQuestion(
        topicId: q.topicId,
        questionText: '${q.questionText} (Copy)',
        questionType: q.questionType,
        difficulty: q.difficulty,
        correctAnswer: q.correctAnswer,
        optionA: q.optionA,
        optionB: q.optionB,
        optionC: q.optionC,
        optionD: q.optionD,
        explanation: q.explanation,
        explanationImageUrl: q.explanationImageUrl,
        explanationVideoUrl: q.explanationVideoUrl,
        questionImageUrl: q.questionImageUrl,
        reference: q.reference,
      ),
      failure: (Failure f) => Future<Result<Question>>.value(
        Result<Question>.failure(
          ServerFailure(
            'Could not fetch original question: ${f.message}',
            AdminErrorCodes.duplicateFailed,
          ),
        ),
      ),
    );
  }

  // ── Bulk operations ────────────────────────────────────────────────────────

  /// Deletes every question in [questionIds] sequentially.
  /// Returns [Result.failure] only if ALL deletions fail.
  Future<Result<void>> bulkDelete({
    required Set<String> questionIds,
  }) async {
    if (questionIds.isEmpty) return const Result<void>.success(null);

    int failCount = 0;
    final List<String> errMessages = <String>[];

    for (final String id in questionIds) {
      final Result<void> r =
          await _repository.deleteQuestion(questionId: id);
      r.when(
        success: (_) {},
        failure: (Failure f) {
          failCount++;
          errMessages.add(f.message);
        },
      );
    }

    if (failCount == questionIds.length) {
      return Result<void>.failure(
        ServerFailure(
          'All deletions failed: ${errMessages.join('; ')}',
          AdminErrorCodes.bulkOperationFailed,
        ),
      );
    }
    return const Result<void>.success(null);
  }

  /// Activates or deactivates every question in [questionIds].
  Future<Result<void>> bulkSetActive({
    required Set<String> questionIds,
    required bool isActive,
  }) async {
    if (questionIds.isEmpty) return const Result<void>.success(null);

    int failCount = 0;
    final List<String> errMessages = <String>[];

    for (final String id in questionIds) {
      final Result<Question> r =
          await _repository.toggleActive(questionId: id, isActive: isActive);
      r.when(
        success: (_) {},
        failure: (Failure f) {
          failCount++;
          errMessages.add(f.message);
        },
      );
    }

    if (failCount == questionIds.length) {
      return Result<void>.failure(
        ServerFailure(
          'All status updates failed: ${errMessages.join('; ')}',
          AdminErrorCodes.bulkOperationFailed,
        ),
      );
    }
    return const Result<void>.success(null);
  }

  // ── CSV import ─────────────────────────────────────────────────────────────

  /// Parses [csvContent] and creates one question per valid row.
  ///
  /// Expected header (case-insensitive):
  /// ```
  /// Subject,Year,Chapter,Topic,Question,QuestionType,
  /// OptionA,OptionB,OptionC,OptionD,CorrectAnswer,Difficulty,
  /// Explanation,ExplanationImageUrl,Reference
  /// ```
  ///
  /// Name → UUID resolution is performed by [lookups], which applies
  /// case-insensitive, whitespace-normalized matching so that "Matematik",
  /// "matematik", and "MATEMATIK " all resolve to the same Subject UUID.
  Future<AdminImportSummary> importFromCsv({
    required String csvContent,
    required AdminImportLookups lookups,
    Set<String> existingSignatures = const <String>{},
  }) async {
    final List<String> lines = csvContent
        .split('\n')
        .map((String l) => l.trim())
        .where((String l) => l.isNotEmpty)
        .toList();

    if (lines.length < 2) {
      return const AdminImportSummary(
        totalRows: 0,
        succeeded: 0,
        skipped: 0,
        errors: <String>['CSV is empty or has no data rows'],
      );
    }

    // Parse header row into a name→index map (case-insensitive, no spaces).
    // This lets the importer tolerate any column ordering in the CSV.
    final List<String> headerCells = _parseCsvLine(lines[0]);
    final Map<String, int> colIdx = <String, int>{};
    for (int h = 0; h < headerCells.length; h++) {
      // Normalize: lowercase, strip spaces — e.g. "Question Type" == "questiontype"
      colIdx[headerCells[h].trim().toLowerCase().replaceAll(' ', '')] = h;
    }

    // Helper: read a cell by header name; returns fallback if column absent.
    String cell(List<String> cells, String name, {String fallback = ''}) {
      final int? idx = colIdx[name.toLowerCase().replaceAll(' ', '')];
      if (idx == null || idx >= cells.length) return fallback;
      return cells[idx].trim();
    }

    // Validate required headers are present.
    // Accept "question" or "questiontext" for the question body.
    final List<String> requiredHeaders = <String>[
      'subject', 'year', 'chapter', 'topic', 'correctanswer', 'questiontype',
    ];
    final bool hasQuestion =
        colIdx.containsKey('question') || colIdx.containsKey('questiontext');
    final List<String> missingHeaders = requiredHeaders
        .where((String h) => !colIdx.containsKey(h))
        .toList();
    if (!hasQuestion) missingHeaders.add('Question');
    if (missingHeaders.isNotEmpty) {
      return AdminImportSummary(
        totalRows: 0,
        succeeded: 0,
        skipped: 0,
        errors: <String>[
          'CSV header is missing required columns: ${missingHeaders.join(', ')}\n'
          '  Found columns: ${headerCells.map((String c) => c.trim()).join(', ')}',
        ],
      );
    }

    final List<String> dataLines = lines.sublist(1);
    int succeeded = 0;
    int skipped = 0;
    int duplicatesCount = 0;
    int failedCount = 0;
    final List<String> errors = <String>[];
    final List<AdminImportRowResult> rowResults = <AdminImportRowResult>[];
    // In-batch duplicate signatures: topicId||questionTextLower
    final Set<String> batchSigs = <String>{};

    for (int i = 0; i < dataLines.length; i++) {
      final int rowNum = i + 2; // 1-based, accounting for header at row 1
      final List<String> cells = _parseCsvLine(dataLines[i]);

      final String subjectName = cell(cells, 'subject');
      final String yearName = cell(cells, 'year');
      final String chapterName = cell(cells, 'chapter');
      final String topicName = cell(cells, 'topic');
      // Accept either "Question" or "QuestionText" header.
      final String questionText = colIdx.containsKey('questiontext')
          ? cell(cells, 'questiontext')
          : cell(cells, 'question');
      final String questionTypeRaw =
          cell(cells, 'questiontype').toLowerCase();
      final String optionA = cell(cells, 'optiona');
      final String optionB = cell(cells, 'optionb');
      final String optionC = cell(cells, 'optionc');
      final String optionD = cell(cells, 'optiond');
      final String correctAnswer = cell(cells, 'correctanswer');
      final String difficultyRaw =
          cell(cells, 'difficulty', fallback: 'easy').toLowerCase();
      final String explanation = cell(cells, 'explanation');
      final String explanationImageUrl = cell(cells, 'explanationimageurl');
      final String reference = cell(cells, 'reference');

      // Validate required fields
      if (questionText.isEmpty) {
        skipped++;
        errors.add('Row $rowNum: question text is required');
        rowResults.add(AdminImportRowResult(rowNumber: rowNum, questionText: '', status: 'Skipped', reason: 'Question text is required'));
        continue;
      }

      // Resolve hierarchy via normalized lookup (case-insensitive, trimmed).
      final String? subjectId =
          lookups.subjectNameToId[AdminImportLookups.normalizeKey(subjectName)];
      if (subjectId == null) {
        skipped++;
        errors.add(
          'Row $rowNum: unknown Subject\n'
          '  CSV value   : "$subjectName"\n'
          '  DB subjects : ${_fmtList(lookups.subjectNames)}\n'
          '  (matched after trim + collapse spaces + lower-case)',
        );
        rowResults.add(AdminImportRowResult(rowNumber: rowNum, questionText: questionText, status: 'Skipped', reason: 'Unknown Subject "$subjectName"'));
        continue;
      }
      final String? yearId =
          lookups.yearNameToId[AdminImportLookups.normalizeKey(yearName)];
      if (yearId == null) {
        skipped++;
        errors.add(
          'Row $rowNum: unknown Year\n'
          '  CSV value : "$yearName"\n'
          '  DB years  : ${_fmtList(lookups.yearNames)}\n'
          '  (matched after trim + collapse spaces + lower-case)',
        );
        rowResults.add(AdminImportRowResult(rowNumber: rowNum, questionText: questionText, status: 'Skipped', reason: 'Unknown Year "$yearName"'));
        continue;
      }
      final String? chapterId =
          lookups.chapterNameToId[AdminImportLookups.normalizeKey(chapterName)];
      if (chapterId == null) {
        skipped++;
        errors.add(
          'Row $rowNum: unknown Chapter\n'
          '  CSV value  : "$chapterName"\n'
          '  DB chapters: ${_fmtList(lookups.chapterNames)}\n'
          '  (matched after trim + collapse spaces + lower-case)',
        );
        rowResults.add(AdminImportRowResult(rowNumber: rowNum, questionText: questionText, status: 'Skipped', reason: 'Unknown Chapter "$chapterName"'));
        continue;
      }
      final String? topicId =
          lookups.topicNameToId[AdminImportLookups.normalizeKey(topicName)];
      if (topicId == null) {
        skipped++;
        errors.add(
          'Row $rowNum: unknown Topic\n'
          '  CSV value : "$topicName"\n'
          '  DB topics : ${_fmtList(lookups.topicNames)}\n'
          '  (matched after trim + collapse spaces + lower-case)',
        );
        rowResults.add(AdminImportRowResult(rowNumber: rowNum, questionText: questionText, status: 'Skipped', reason: 'Unknown Topic "$topicName"'));
        continue;
      }

      // Parse question type
      final QuestionType? questionType = _parseType(questionTypeRaw);
      if (questionType == null) {
        skipped++;
        final String reason = 'Unknown QuestionType "$questionTypeRaw" (expected mcq, true_false, fill_in_blank)';
        errors.add('Row $rowNum: $reason');
        rowResults.add(AdminImportRowResult(rowNumber: rowNum, questionText: questionText, status: 'Skipped', reason: reason));
        continue;
      }

      // Parse difficulty
      final QuestionDifficulty difficulty = _parseDifficulty(difficultyRaw);

      // Validate correct answer
      final String? answerErr = _validateAnswer(
        questionType: questionType,
        correctAnswer: correctAnswer,
        optionA: optionA,
        optionB: optionB,
      );
      if (answerErr != null) {
        skipped++;
        errors.add('Row $rowNum: $answerErr');
        rowResults.add(AdminImportRowResult(rowNumber: rowNum, questionText: questionText, status: 'Skipped', reason: answerErr));
        continue;
      }

      // DB-level + in-batch duplicate check.
      final String dupSig = '$topicId||${questionText.toLowerCase()}';
      if (existingSignatures.contains(dupSig) || batchSigs.contains(dupSig)) {
        duplicatesCount++;
        rowResults.add(AdminImportRowResult(rowNumber: rowNum, questionText: questionText, status: 'Duplicate', reason: 'Question already exists'));
        continue;
      }
      batchSigs.add(dupSig);

      // Create the question
      final Result<Question> result = await _repository.createQuestion(
        topicId: topicId,
        questionText: questionText,
        questionType: questionType,
        difficulty: difficulty,
        correctAnswer: correctAnswer,
        optionA: optionA.isNotEmpty ? optionA : null,
        optionB: optionB.isNotEmpty ? optionB : null,
        optionC: optionC.isNotEmpty ? optionC : null,
        optionD: optionD.isNotEmpty ? optionD : null,
        explanation: explanation.isNotEmpty ? explanation : null,
        explanationImageUrl:
            explanationImageUrl.isNotEmpty ? explanationImageUrl : null,
        reference: reference.isNotEmpty ? reference : null,
      );

      result.when(
        success: (_) {
          succeeded++;
          rowResults.add(AdminImportRowResult(rowNumber: rowNum, questionText: questionText, status: 'Imported', reason: ''));
        },
        failure: (Failure f) {
          failedCount++;
          errors.add('Row $rowNum: ${f.message}');
          rowResults.add(AdminImportRowResult(rowNumber: rowNum, questionText: questionText, status: 'Failed', reason: f.message));
        },
      );
    }

    return AdminImportSummary(
      totalRows: dataLines.length,
      succeeded: succeeded,
      skipped: skipped,
      duplicates: duplicatesCount,
      failed: failedCount,
      errors: errors,
      rowResults: rowResults,
    );
  }

  // ── JSON import ────────────────────────────────────────────────────────────

  /// Parses a JSON array and creates one question per valid object.
  ///
  /// Expected JSON schema (same fields as the CSV template):
  /// ```json
  /// [
  ///   {
  ///     "Subject": "Matematik",
  ///     "Year": "Tahun 1",
  ///     "Chapter": "Nombor Bulat hingga 100",
  ///     "Topic": "Tambah",
  ///     "Question": "Berapakah 2 + 3?",
  ///     "QuestionType": "mcq",
  ///     "OptionA": "4", "OptionB": "5", "OptionC": "6", "OptionD": "7",
  ///     "CorrectAnswer": "B",
  ///     "Difficulty": "easy",
  ///     "Explanation": "2 + 3 = 5",
  ///     "ExplanationImageUrl": "",
  ///     "Reference": "KSSR pg. 10"
  ///   }
  /// ]
  /// ```
  Future<AdminImportSummary> importFromJson({
    required String jsonContent,
    required AdminImportLookups lookups,
    Set<String> existingSignatures = const <String>{},
  }) async {
    List<dynamic> rows;
    try {
      rows = jsonDecode(jsonContent) as List<dynamic>;
    } catch (e) {
      return AdminImportSummary(
        totalRows: 0,
        succeeded: 0,
        skipped: 0,
        errors: <String>['Invalid JSON: $e'],
      );
    }

    if (rows.isEmpty) {
      return const AdminImportSummary(
        totalRows: 0,
        succeeded: 0,
        skipped: 0,
        errors: <String>['JSON array is empty'],
      );
    }

    int succeeded = 0;
    int skipped = 0;
    int duplicatesCount = 0;
    int failedCount = 0;
    final List<String> errors = <String>[];
    final List<AdminImportRowResult> rowResults = <AdminImportRowResult>[];
    // In-batch duplicate signatures: topicId||questionTextLower
    final Set<String> batchSigs = <String>{};

    for (int i = 0; i < rows.length; i++) {
      final int rowNum = i + 1;
      final dynamic rawRow = rows[i];
      if (rawRow is! Map<String, dynamic>) {
        skipped++;
        final String reason = 'Must be a JSON object, got ${rawRow.runtimeType}';
        errors.add('Row $rowNum: $reason');
        rowResults.add(AdminImportRowResult(rowNumber: rowNum, questionText: '', status: 'Skipped', reason: reason));
        continue;
      }
      final Map<String, dynamic> row = rawRow;

      final String subjectName = (row['Subject'] ?? '').toString().trim();
      final String yearName = (row['Year'] ?? '').toString().trim();
      final String chapterName = (row['Chapter'] ?? '').toString().trim();
      final String topicName = (row['Topic'] ?? '').toString().trim();
      final String questionText = (row['Question'] ?? '').toString().trim();
      final String questionTypeRaw =
          (row['QuestionType'] ?? '').toString().trim().toLowerCase();
      final String optionA = (row['OptionA'] ?? '').toString().trim();
      final String optionB = (row['OptionB'] ?? '').toString().trim();
      final String optionC = (row['OptionC'] ?? '').toString().trim();
      final String optionD = (row['OptionD'] ?? '').toString().trim();
      final String correctAnswer = (row['CorrectAnswer'] ?? '').toString().trim();
      final String difficultyRaw =
          (row['Difficulty'] ?? 'easy').toString().trim().toLowerCase();
      final String explanation = (row['Explanation'] ?? '').toString().trim();
      final String explanationImageUrl =
          (row['ExplanationImageUrl'] ?? '').toString().trim();
      final String reference = (row['Reference'] ?? '').toString().trim();

      if (questionText.isEmpty) {
        skipped++;
        errors.add('Row $rowNum: Question text is required');
        rowResults.add(AdminImportRowResult(rowNumber: rowNum, questionText: '', status: 'Skipped', reason: 'Question text is required'));
        continue;
      }

      // Resolve all four hierarchy levels via normalized lookup.
      final String? subjectId =
          lookups.subjectNameToId[AdminImportLookups.normalizeKey(subjectName)];
      if (subjectId == null) {
        skipped++;
        errors.add(
          'Row $rowNum: unknown Subject\n'
          '  JSON value  : "$subjectName"\n'
          '  DB subjects : ${_fmtList(lookups.subjectNames)}\n'
          '  (matched after trim + collapse spaces + lower-case)',
        );
        rowResults.add(AdminImportRowResult(rowNumber: rowNum, questionText: questionText, status: 'Skipped', reason: 'Unknown Subject "$subjectName"'));
        continue;
      }
      final String? yearId =
          lookups.yearNameToId[AdminImportLookups.normalizeKey(yearName)];
      if (yearId == null) {
        skipped++;
        errors.add(
          'Row $rowNum: unknown Year\n'
          '  JSON value : "$yearName"\n'
          '  DB years   : ${_fmtList(lookups.yearNames)}\n'
          '  (matched after trim + collapse spaces + lower-case)',
        );
        rowResults.add(AdminImportRowResult(rowNumber: rowNum, questionText: questionText, status: 'Skipped', reason: 'Unknown Year "$yearName"'));
        continue;
      }
      final String? chapterId =
          lookups.chapterNameToId[AdminImportLookups.normalizeKey(chapterName)];
      if (chapterId == null) {
        skipped++;
        errors.add(
          'Row $rowNum: unknown Chapter\n'
          '  JSON value : "$chapterName"\n'
          '  DB chapters: ${_fmtList(lookups.chapterNames)}\n'
          '  (matched after trim + collapse spaces + lower-case)',
        );
        rowResults.add(AdminImportRowResult(rowNumber: rowNum, questionText: questionText, status: 'Skipped', reason: 'Unknown Chapter "$chapterName"'));
        continue;
      }
      final String? topicId =
          lookups.topicNameToId[AdminImportLookups.normalizeKey(topicName)];
      if (topicId == null) {
        skipped++;
        errors.add(
          'Row $rowNum: unknown Topic\n'
          '  JSON value : "$topicName"\n'
          '  DB topics  : ${_fmtList(lookups.topicNames)}\n'
          '  (matched after trim + collapse spaces + lower-case)',
        );
        rowResults.add(AdminImportRowResult(rowNumber: rowNum, questionText: questionText, status: 'Skipped', reason: 'Unknown Topic "$topicName"'));
        continue;
      }

      // DB-level + in-batch duplicate check.
      final String dupSig = '$topicId||${questionText.toLowerCase()}';
      if (existingSignatures.contains(dupSig) || batchSigs.contains(dupSig)) {
        duplicatesCount++;
        rowResults.add(AdminImportRowResult(rowNumber: rowNum, questionText: questionText, status: 'Duplicate', reason: 'Question already exists'));
        continue;
      }
      batchSigs.add(dupSig);

      final QuestionType? questionType = _parseType(questionTypeRaw);
      if (questionType == null) {
        skipped++;
        final String reason = 'Unknown QuestionType "$questionTypeRaw" (expected mcq, true_false, fill_in_blank)';
        errors.add('Row $rowNum: $reason');
        rowResults.add(AdminImportRowResult(rowNumber: rowNum, questionText: questionText, status: 'Skipped', reason: reason));
        continue;
      }

      final QuestionDifficulty difficulty = _parseDifficulty(difficultyRaw);

      final String? answerErr = _validateAnswer(
        questionType: questionType,
        correctAnswer: correctAnswer,
        optionA: optionA,
        optionB: optionB,
      );
      if (answerErr != null) {
        skipped++;
        errors.add('Row $rowNum: $answerErr');
        rowResults.add(AdminImportRowResult(rowNumber: rowNum, questionText: questionText, status: 'Skipped', reason: answerErr));
        continue;
      }

      final Result<Question> result = await _repository.createQuestion(
        topicId: topicId,
        questionText: questionText,
        questionType: questionType,
        difficulty: difficulty,
        correctAnswer: correctAnswer,
        optionA: optionA.isNotEmpty ? optionA : null,
        optionB: optionB.isNotEmpty ? optionB : null,
        optionC: optionC.isNotEmpty ? optionC : null,
        optionD: optionD.isNotEmpty ? optionD : null,
        explanation: explanation.isNotEmpty ? explanation : null,
        explanationImageUrl:
            explanationImageUrl.isNotEmpty ? explanationImageUrl : null,
        reference: reference.isNotEmpty ? reference : null,
      );

      result.when(
        success: (_) {
          succeeded++;
          rowResults.add(AdminImportRowResult(rowNumber: rowNum, questionText: questionText, status: 'Imported', reason: ''));
        },
        failure: (Failure f) {
          failedCount++;
          errors.add('Row $rowNum: ${f.message}');
          rowResults.add(AdminImportRowResult(rowNumber: rowNum, questionText: questionText, status: 'Failed', reason: f.message));
        },
      );
    }

    return AdminImportSummary(
      totalRows: rows.length,
      succeeded: succeeded,
      skipped: skipped,
      duplicates: duplicatesCount,
      failed: failedCount,
      errors: errors,
      rowResults: rowResults,
    );
  }

  // ── Import preview (dry-run, no DB writes) ────────────────────────────────

  /// Validates [csvContent] without inserting anything.
  ///
  /// Returns an [AdminImportPreview] showing how many rows would be imported,
  /// how many are duplicates, and how many have validation errors.
  Future<AdminImportPreview> previewFromCsv({
    required String fileName,
    required String csvContent,
    required AdminImportLookups lookups,
    Set<String> existingSignatures = const <String>{},
  }) async {
    final List<String> lines = csvContent
        .split('\n')
        .map((String l) => l.trim())
        .where((String l) => l.isNotEmpty)
        .toList();

    if (lines.length < 2) {
      return AdminImportPreview(
        fileName: fileName,
        subjects: const <String>[],
        years: const <String>[],
        chapters: const <String>[],
        topics: const <String>[],
        rowsFound: 0,
        newQuestions: 0,
        duplicates: 0,
        invalidRows: 0,
        validationErrors: const <String>['CSV is empty or has no data rows'],
      );
    }

    // Parse header (same logic as importFromCsv).
    final List<String> headerCells = _parseCsvLine(lines[0]);
    final Map<String, int> colIdx = <String, int>{};
    for (int h = 0; h < headerCells.length; h++) {
      colIdx[headerCells[h].trim().toLowerCase().replaceAll(' ', '')] = h;
    }

    String cell(List<String> cells, String name, {String fallback = ''}) {
      final int? idx = colIdx[name.toLowerCase().replaceAll(' ', '')];
      if (idx == null || idx >= cells.length) return fallback;
      return cells[idx].trim();
    }

    final List<String> requiredHeaders = <String>[
      'subject', 'year', 'chapter', 'topic', 'correctanswer', 'questiontype',
    ];
    final bool hasQuestion =
        colIdx.containsKey('question') || colIdx.containsKey('questiontext');
    final List<String> missing =
        requiredHeaders.where((String h) => !colIdx.containsKey(h)).toList();
    if (!hasQuestion) missing.add('Question');
    if (missing.isNotEmpty) {
      return AdminImportPreview(
        fileName: fileName,
        subjects: const <String>[],
        years: const <String>[],
        chapters: const <String>[],
        topics: const <String>[],
        rowsFound: 0,
        newQuestions: 0,
        duplicates: 0,
        invalidRows: 0,
        validationErrors: <String>[
          'CSV header is missing required columns: ${missing.join(', ')}\n'
          '  Found columns: ${headerCells.map((String c) => c.trim()).join(', ')}',
        ],
      );
    }

    final List<String> dataLines = lines.sublist(1);
    int newQuestions = 0;
    int duplicatesCount = 0;
    int invalidRows = 0;
    final List<String> validationErrors = <String>[];
    final Set<String> subjectsSet = <String>{};
    final Set<String> yearsSet = <String>{};
    final Set<String> chaptersSet = <String>{};
    final Set<String> topicsSet = <String>{};
    final Set<String> batchSigs = <String>{};

    for (int i = 0; i < dataLines.length; i++) {
      final int rowNum = i + 2;
      final List<String> cells = _parseCsvLine(dataLines[i]);

      final String subjectName = cell(cells, 'subject');
      final String yearName = cell(cells, 'year');
      final String chapterName = cell(cells, 'chapter');
      final String topicName = cell(cells, 'topic');
      final String questionText = colIdx.containsKey('questiontext')
          ? cell(cells, 'questiontext')
          : cell(cells, 'question');
      final String questionTypeRaw = cell(cells, 'questiontype').toLowerCase();
      final String optionA = cell(cells, 'optiona');
      final String optionB = cell(cells, 'optionb');
      final String correctAnswer = cell(cells, 'correctanswer');

      if (questionText.isEmpty) {
        invalidRows++;
        validationErrors.add('Row $rowNum: question text is required');
        continue;
      }

      final String? subjectId =
          lookups.subjectNameToId[AdminImportLookups.normalizeKey(subjectName)];
      if (subjectId == null) {
        invalidRows++;
        validationErrors.add('Row $rowNum: unknown Subject "$subjectName"');
        continue;
      }
      final String? yearId =
          lookups.yearNameToId[AdminImportLookups.normalizeKey(yearName)];
      if (yearId == null) {
        invalidRows++;
        validationErrors.add('Row $rowNum: unknown Year "$yearName"');
        continue;
      }
      final String? chapterId =
          lookups.chapterNameToId[AdminImportLookups.normalizeKey(chapterName)];
      if (chapterId == null) {
        invalidRows++;
        validationErrors.add('Row $rowNum: unknown Chapter "$chapterName"');
        continue;
      }
      final String? topicId =
          lookups.topicNameToId[AdminImportLookups.normalizeKey(topicName)];
      if (topicId == null) {
        invalidRows++;
        validationErrors.add('Row $rowNum: unknown Topic "$topicName"');
        continue;
      }

      final QuestionType? questionType = _parseType(questionTypeRaw);
      if (questionType == null) {
        invalidRows++;
        validationErrors
            .add('Row $rowNum: unknown QuestionType "$questionTypeRaw"');
        continue;
      }

      final String? answerErr = _validateAnswer(
        questionType: questionType,
        correctAnswer: correctAnswer,
        optionA: optionA,
        optionB: optionB,
      );
      if (answerErr != null) {
        invalidRows++;
        validationErrors.add('Row $rowNum: $answerErr');
        continue;
      }

      // Duplicate check (DB + in-batch).
      final String dupSig = '$topicId||${questionText.toLowerCase()}';
      if (existingSignatures.contains(dupSig) || batchSigs.contains(dupSig)) {
        duplicatesCount++;
        continue;
      }
      batchSigs.add(dupSig);

      // Row is valid and non-duplicate — would be inserted.
      newQuestions++;
      subjectsSet.add(subjectName);
      yearsSet.add(yearName);
      chaptersSet.add(chapterName);
      topicsSet.add(topicName);
    }

    return AdminImportPreview(
      fileName: fileName,
      subjects: subjectsSet.toList(),
      years: yearsSet.toList(),
      chapters: chaptersSet.toList(),
      topics: topicsSet.toList(),
      rowsFound: dataLines.length,
      newQuestions: newQuestions,
      duplicates: duplicatesCount,
      invalidRows: invalidRows,
      validationErrors: validationErrors,
    );
  }

  /// Validates [jsonContent] without inserting anything.
  Future<AdminImportPreview> previewFromJson({
    required String fileName,
    required String jsonContent,
    required AdminImportLookups lookups,
    Set<String> existingSignatures = const <String>{},
  }) async {
    List<dynamic> rows;
    try {
      rows = jsonDecode(jsonContent) as List<dynamic>;
    } catch (e) {
      return AdminImportPreview(
        fileName: fileName,
        subjects: const <String>[],
        years: const <String>[],
        chapters: const <String>[],
        topics: const <String>[],
        rowsFound: 0,
        newQuestions: 0,
        duplicates: 0,
        invalidRows: 0,
        validationErrors: <String>['Invalid JSON: $e'],
      );
    }

    if (rows.isEmpty) {
      return AdminImportPreview(
        fileName: fileName,
        subjects: const <String>[],
        years: const <String>[],
        chapters: const <String>[],
        topics: const <String>[],
        rowsFound: 0,
        newQuestions: 0,
        duplicates: 0,
        invalidRows: 0,
        validationErrors: const <String>['JSON array is empty'],
      );
    }

    int newQuestions = 0;
    int duplicatesCount = 0;
    int invalidRows = 0;
    final List<String> validationErrors = <String>[];
    final Set<String> subjectsSet = <String>{};
    final Set<String> yearsSet = <String>{};
    final Set<String> chaptersSet = <String>{};
    final Set<String> topicsSet = <String>{};
    final Set<String> batchSigs = <String>{};

    for (int i = 0; i < rows.length; i++) {
      final int rowNum = i + 1;
      final dynamic rawRow = rows[i];
      if (rawRow is! Map<String, dynamic>) {
        invalidRows++;
        validationErrors.add(
            'Row $rowNum: must be a JSON object, got ${rawRow.runtimeType}');
        continue;
      }
      final Map<String, dynamic> row = rawRow;

      final String subjectName = (row['Subject'] ?? '').toString().trim();
      final String yearName = (row['Year'] ?? '').toString().trim();
      final String chapterName = (row['Chapter'] ?? '').toString().trim();
      final String topicName = (row['Topic'] ?? '').toString().trim();
      final String questionText = (row['Question'] ?? '').toString().trim();
      final String questionTypeRaw =
          (row['QuestionType'] ?? '').toString().trim().toLowerCase();
      final String optionA = (row['OptionA'] ?? '').toString().trim();
      final String optionB = (row['OptionB'] ?? '').toString().trim();
      final String correctAnswer = (row['CorrectAnswer'] ?? '').toString().trim();

      if (questionText.isEmpty) {
        invalidRows++;
        validationErrors.add('Row $rowNum: Question text is required');
        continue;
      }

      final String? subjectId =
          lookups.subjectNameToId[AdminImportLookups.normalizeKey(subjectName)];
      if (subjectId == null) {
        invalidRows++;
        validationErrors.add('Row $rowNum: unknown Subject "$subjectName"');
        continue;
      }
      final String? yearId =
          lookups.yearNameToId[AdminImportLookups.normalizeKey(yearName)];
      if (yearId == null) {
        invalidRows++;
        validationErrors.add('Row $rowNum: unknown Year "$yearName"');
        continue;
      }
      final String? chapterId =
          lookups.chapterNameToId[AdminImportLookups.normalizeKey(chapterName)];
      if (chapterId == null) {
        invalidRows++;
        validationErrors.add('Row $rowNum: unknown Chapter "$chapterName"');
        continue;
      }
      final String? topicId =
          lookups.topicNameToId[AdminImportLookups.normalizeKey(topicName)];
      if (topicId == null) {
        invalidRows++;
        validationErrors.add('Row $rowNum: unknown Topic "$topicName"');
        continue;
      }

      final QuestionType? questionType = _parseType(questionTypeRaw);
      if (questionType == null) {
        invalidRows++;
        validationErrors
            .add('Row $rowNum: unknown QuestionType "$questionTypeRaw"');
        continue;
      }

      final String? answerErr = _validateAnswer(
        questionType: questionType,
        correctAnswer: correctAnswer,
        optionA: optionA,
        optionB: optionB,
      );
      if (answerErr != null) {
        invalidRows++;
        validationErrors.add('Row $rowNum: $answerErr');
        continue;
      }

      final String dupSig = '$topicId||${questionText.toLowerCase()}';
      if (existingSignatures.contains(dupSig) || batchSigs.contains(dupSig)) {
        duplicatesCount++;
        continue;
      }
      batchSigs.add(dupSig);

      newQuestions++;
      subjectsSet.add(subjectName);
      yearsSet.add(yearName);
      chaptersSet.add(chapterName);
      topicsSet.add(topicName);
    }

    return AdminImportPreview(
      fileName: fileName,
      subjects: subjectsSet.toList(),
      years: yearsSet.toList(),
      chapters: chaptersSet.toList(),
      topics: topicsSet.toList(),
      rowsFound: rows.length,
      newQuestions: newQuestions,
      duplicates: duplicatesCount,
      invalidRows: invalidRows,
      validationErrors: validationErrors,
    );
  }

  /// Generates a downloadable import report CSV from [rowResults].
  ///
  /// Columns: Row, Question, Status, Reason
  static String generateImportReport(List<AdminImportRowResult> rowResults) {
    final StringBuffer buf = StringBuffer();
    buf.writeln('Row,Question,Status,Reason');
    for (final AdminImportRowResult r in rowResults) {
      final String q = r.questionText.replaceAll('"', '""');
      final String reason = r.reason.replaceAll('"', '""');
      buf.writeln('${r.rowNumber},"$q",${r.status},"$reason"');
    }
    return buf.toString();
  }

  // ── CSV export ─────────────────────────────────────────────────────────────

  /// Converts [questions] to a CSV string using human-readable names.
  ///
  /// The output format matches the import template exactly so the CSV is
  /// round-trip importable without any UUID editing.
  String exportToCsvWithNames(
    List<Question> questions, {
    required Map<String, Topic> topicsById,
    required Map<String, Chapter> chaptersById,
    required Map<String, Subject> subjectsById,
    required Map<String, Year> yearsById,
  }) {
    final StringBuffer buf = StringBuffer();
    buf.writeln(
      'Subject,Year,Chapter,Topic,Question,QuestionType,'
      'OptionA,OptionB,OptionC,OptionD,CorrectAnswer,Difficulty,'
      'Explanation,ExplanationImageUrl,Reference',
    );
    for (final Question q in questions) {
      final Topic? topic = topicsById[q.topicId];
      final Chapter? chapter =
          topic != null ? chaptersById[topic.chapterId] : null;
      final Subject? subject =
          chapter != null ? subjectsById[chapter.subjectId] : null;
      final Year? year =
          chapter != null ? yearsById[chapter.yearId] : null;
      buf.writeln(
        '${_esc(subject?.subjectName ?? '')},'
        '${_esc(year?.yearName ?? '')},'
        '${_esc(chapter?.chapterName ?? '')},'
        '${_esc(topic?.topicName ?? q.topicId)},'
        '${_esc(q.questionText)},'
        '${_esc(_typeLabel(q.questionType))},'
        '${_esc(q.optionA)},${_esc(q.optionB)},'
        '${_esc(q.optionC)},${_esc(q.optionD)},'
        '${_esc(q.correctAnswer)},'
        '${_esc(_diffLabel(q.difficulty))},'
        '${_esc(q.explanation)},'
        '${_esc(q.explanationImageUrl)},'
        '${_esc(q.reference)}',
      );
    }
    return buf.toString();
  }

  /// Legacy export — kept for internal use; prefer [exportToCsvWithNames].
  String exportToCsv(List<Question> questions) {
    final StringBuffer buf = StringBuffer();
    buf.writeln(
      'ID,TopicID,Question,Type,OptionA,OptionB,OptionC,OptionD,'
      'CorrectAnswer,Difficulty,Explanation,ExplanationImageUrl,'
      'ExplanationVideoUrl,QuestionImageUrl,Reference,IsActive,CreatedAt',
    );
    for (final Question q in questions) {
      buf.writeln(
        '${_esc(q.questionId)},${_esc(q.topicId)},'
        '${_esc(q.questionText)},${_esc(_typeLabel(q.questionType))},'
        '${_esc(q.optionA)},${_esc(q.optionB)},'
        '${_esc(q.optionC)},${_esc(q.optionD)},'
        '${_esc(q.correctAnswer)},${_esc(_diffLabel(q.difficulty))},'
        '${_esc(q.explanation)},${_esc(q.explanationImageUrl)},'
        '${_esc(q.explanationVideoUrl)},${_esc(q.questionImageUrl)},'
        '${_esc(q.reference)},${q.isActive},'
        '${q.createdAt.toIso8601String()}',
      );
    }
    return buf.toString();
  }

  // ── JSON template ──────────────────────────────────────────────────────────

  /// Returns a JSON template string showing the expected import format.
  static String get jsonImportTemplate => const JsonEncoder.withIndent('  ')
      .convert(<Map<String, String>>[
    <String, String>{
      'Subject': 'Matematik',
      'Year': 'Tahun 1',
      'Chapter': 'Nombor Bulat hingga 100',
      'Topic': 'Tambah',
      'Question': 'Berapakah 2 + 3?',
      'QuestionType': 'mcq',
      'OptionA': '4',
      'OptionB': '5',
      'OptionC': '6',
      'OptionD': '7',
      'CorrectAnswer': 'B',
      'Difficulty': 'easy',
      'Explanation': '2 + 3 = 5',
      'ExplanationImageUrl': '',
      'Reference': 'KSSR pg. 10',
    },
  ]);

  // ── Private helpers ────────────────────────────────────────────────────────

  /// Wraps [value] in double-quotes and escapes internal double-quotes.
  String _esc(String? value) {
    if (value == null || value.isEmpty) return '""';
    final String escaped = value.replaceAll('"', '""');
    return '"$escaped"';
  }

  /// Parses a single CSV line, respecting double-quoted fields.
  List<String> _parseCsvLine(String line) {
    final List<String> result = <String>[];
    final StringBuffer current = StringBuffer();
    bool inQuotes = false;

    for (int i = 0; i < line.length; i++) {
      final String ch = line[i];
      if (ch == '"') {
        if (inQuotes && i + 1 < line.length && line[i + 1] == '"') {
          current.write('"');
          i++;
        } else {
          inQuotes = !inQuotes;
        }
      } else if (ch == ',' && !inQuotes) {
        result.add(current.toString());
        current.clear();
      } else {
        current.write(ch);
      }
    }
    result.add(current.toString());
    return result;
  }

  QuestionType? _parseType(String raw) {
    switch (raw) {
      case 'mcq':
        return QuestionType.mcq;
      case 'true_false':
      case 'truefalse':
      case 'true/false':
      case 't/f':
        return QuestionType.trueFalse;
      case 'fill_in_blank':
      case 'fill_in_the_blank':
      case 'fill':
        return QuestionType.fillInTheBlank;
      default:
        return null;
    }
  }

  QuestionDifficulty _parseDifficulty(String raw) {
    switch (raw) {
      case 'medium':
        return QuestionDifficulty.medium;
      case 'hard':
        return QuestionDifficulty.hard;
      default:
        return QuestionDifficulty.easy;
    }
  }

  /// Formats a list of names for display in error messages.
  static String _fmtList(List<String> names) {
    if (names.isEmpty) return '(none — check DB connection)';
    return names.map((String n) => '"$n"').join(', ');
  }

  String? _validateAnswer({
    required QuestionType questionType,
    required String correctAnswer,
    required String optionA,
    required String optionB,
  }) {
    if (correctAnswer.isEmpty) return 'correct answer is required';
    switch (questionType) {
      case QuestionType.mcq:
        if (optionA.isEmpty || optionB.isEmpty) {
          return 'MCQ requires at least Option A and Option B';
        }
        if (!_mcqAnswers.contains(correctAnswer.toUpperCase())) {
          return "MCQ correct answer must be 'A', 'B', 'C', or 'D'";
        }
      case QuestionType.trueFalse:
        if (!_tfAnswers.contains(correctAnswer.toLowerCase())) {
          return "True/False correct answer must be 'true' or 'false'";
        }
      case QuestionType.fillInTheBlank:
        break;
    }
    return null;
  }

  String _typeLabel(QuestionType t) {
    switch (t) {
      case QuestionType.mcq:
        return 'mcq';
      case QuestionType.trueFalse:
        return 'true_false';
      case QuestionType.fillInTheBlank:
        return 'fill_in_blank';
    }
  }

  String _diffLabel(QuestionDifficulty d) {
    switch (d) {
      case QuestionDifficulty.easy:
        return 'easy';
      case QuestionDifficulty.medium:
        return 'medium';
      case QuestionDifficulty.hard:
        return 'hard';
    }
  }
}

/// Lookup maps derived from a set of domain entities — used by CSV/JSON import.
///
/// All map keys are **normalized** (trimmed, whitespace-collapsed, lower-cased)
/// so that "Matematik", "matematik", "MATEMATIK ", and "Matematik" all resolve
/// to the same UUID.  The original display names are kept separately so that
/// error messages can show what the database actually contains.
class AdminImportLookups {
  const AdminImportLookups({
    required this.subjectNameToId,
    required this.yearNameToId,
    required this.chapterNameToId,
    required this.topicNameToId,
    required this.subjectNames,
    required this.yearNames,
    required this.chapterNames,
    required this.topicNames,
  });

  // Normalized key (lower-case, trimmed, single-spaced) → UUID
  final Map<String, String> subjectNameToId;
  final Map<String, String> yearNameToId;
  final Map<String, String> chapterNameToId;
  final Map<String, String> topicNameToId;

  // Original display names — for human-readable error messages only.
  final List<String> subjectNames;
  final List<String> yearNames;
  final List<String> chapterNames;
  final List<String> topicNames;

  /// Normalizes a name for map key comparison:
  ///   • trim leading/trailing whitespace
  ///   • collapse internal runs of whitespace to a single space
  ///   • lower-case
  ///
  /// Applied to both map keys (in [from]) and to incoming CSV/JSON values
  /// (in [AdminQuestionService.importFromCsv] / [importFromJson]) so the
  /// comparison is always symmetric.
  static String normalizeKey(String s) =>
      s.trim().replaceAll(RegExp(r'\s+'), ' ').toLowerCase();

  factory AdminImportLookups.from({
    required List<Subject> subjects,
    required List<Year> years,
    required List<Chapter> chapters,
    required List<Topic> topics,
  }) {
    return AdminImportLookups(
      subjectNameToId: <String, String>{
        for (final Subject s in subjects)
          normalizeKey(s.subjectName): s.subjectId,
      },
      yearNameToId: <String, String>{
        for (final Year y in years) normalizeKey(y.yearName): y.yearId,
      },
      chapterNameToId: <String, String>{
        for (final Chapter c in chapters)
          normalizeKey(c.chapterName): c.chapterId,
      },
      topicNameToId: <String, String>{
        for (final Topic t in topics) normalizeKey(t.topicName): t.topicId,
      },
      subjectNames: subjects.map((Subject s) => s.subjectName).toList(),
      yearNames: years.map((Year y) => y.yearName).toList(),
      chapterNames: chapters.map((Chapter c) => c.chapterName).toList(),
      topicNames: topics.map((Topic t) => t.topicName).toList(),
    );
  }
}

