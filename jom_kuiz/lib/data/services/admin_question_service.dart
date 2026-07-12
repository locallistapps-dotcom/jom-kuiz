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

/// Result of a CSV import operation.
class AdminImportSummary {
  const AdminImportSummary({
    required this.totalRows,
    required this.succeeded,
    required this.skipped,
    required this.errors,
  });

  /// Total data rows parsed (excluding header).
  final int totalRows;

  /// Rows successfully created in the database.
  final int succeeded;

  /// Rows skipped due to validation errors.
  final int skipped;

  /// Human-readable error messages per row (1-indexed).
  final List<String> errors;
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

    // Skip header row (index 0).
    final List<String> dataLines = lines.sublist(1);
    int succeeded = 0;
    int skipped = 0;
    final List<String> errors = <String>[];

    for (int i = 0; i < dataLines.length; i++) {
      final int rowNum = i + 2; // 1-based, accounting for header at row 1
      final List<String> cells = _parseCsvLine(dataLines[i]);

      if (cells.length < 11) {
        skipped++;
        errors.add('Row $rowNum: insufficient columns (expected ≥11, got ${cells.length})');
        continue;
      }

      final String subjectName = cells[0].trim();
      final String yearName = cells[1].trim();
      final String chapterName = cells[2].trim();
      final String topicName = cells[3].trim();
      final String questionText = cells[4].trim();
      final String questionTypeRaw = cells[5].trim().toLowerCase();
      final String optionA = cells.length > 6 ? cells[6].trim() : '';
      final String optionB = cells.length > 7 ? cells[7].trim() : '';
      final String optionC = cells.length > 8 ? cells[8].trim() : '';
      final String optionD = cells.length > 9 ? cells[9].trim() : '';
      final String correctAnswer = cells[10].trim();
      final String difficultyRaw =
          cells.length > 11 ? cells[11].trim().toLowerCase() : 'easy';
      final String explanation =
          cells.length > 12 ? cells[12].trim() : '';
      final String explanationImageUrl =
          cells.length > 13 ? cells[13].trim() : '';
      final String reference =
          cells.length > 14 ? cells[14].trim() : '';

      // Validate required fields
      if (questionText.isEmpty) {
        skipped++;
        errors.add('Row $rowNum: question text is required');
        continue;
      }

      // Resolve topic ID via normalized lookup (case-insensitive, trimmed).
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
        continue;
      }

      // Parse question type
      final QuestionType? questionType = _parseType(questionTypeRaw);
      if (questionType == null) {
        skipped++;
        errors.add(
            'Row $rowNum: unknown question type "$questionTypeRaw" '
            '(expected mcq, true_false/truefalse, or fill_in_blank/fill)');
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
        continue;
      }

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
        success: (_) => succeeded++,
        failure: (Failure f) {
          skipped++;
          errors.add('Row $rowNum: ${f.message}');
        },
      );
    }

    return AdminImportSummary(
      totalRows: dataLines.length,
      succeeded: succeeded,
      skipped: skipped,
      errors: errors,
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
    final List<String> errors = <String>[];
    // In-batch duplicate signatures: topicId||questionTextLower
    final Set<String> batchSigs = <String>{};

    for (int i = 0; i < rows.length; i++) {
      final int rowNum = i + 1;
      final dynamic rawRow = rows[i];
      if (rawRow is! Map<String, dynamic>) {
        skipped++;
        errors.add('Row $rowNum: must be a JSON object, got ${rawRow.runtimeType}');
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
        continue;
      }

      // In-batch duplicate check
      final String sig = '$topicId||${questionText.toLowerCase()}';
      if (batchSigs.contains(sig)) {
        skipped++;
        errors.add('Row $rowNum: duplicate question in this import batch (skipped)');
        continue;
      }
      batchSigs.add(sig);

      final QuestionType? questionType = _parseType(questionTypeRaw);
      if (questionType == null) {
        skipped++;
        errors.add('Row $rowNum: unknown QuestionType "$questionTypeRaw"');
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
        success: (_) => succeeded++,
        failure: (Failure f) {
          skipped++;
          errors.add('Row $rowNum: ${f.message}');
        },
      );
    }

    return AdminImportSummary(
      totalRows: rows.length,
      succeeded: succeeded,
      skipped: skipped,
      errors: errors,
    );
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

