import '../../domain/entities/question.dart';

// ── Enum helpers ──────────────────────────────────────────────────────────────

extension QuestionTypeX on QuestionType {
  String toJson() {
    switch (this) {
      case QuestionType.mcq:
        return 'mcq';
      case QuestionType.trueFalse:
        return 'true_false';
      case QuestionType.fillInTheBlank:
        return 'fill_in_blank';
    }
  }

  static QuestionType fromJson(String raw) {
    switch (raw) {
      case 'mcq':
        return QuestionType.mcq;
      case 'true_false':
        return QuestionType.trueFalse;
      case 'fill_in_blank':
        return QuestionType.fillInTheBlank;
      default:
        return QuestionType.mcq;
    }
  }
}

extension QuestionDifficultyX on QuestionDifficulty {
  String toJson() {
    switch (this) {
      case QuestionDifficulty.easy:
        return 'easy';
      case QuestionDifficulty.medium:
        return 'medium';
      case QuestionDifficulty.hard:
        return 'hard';
    }
  }

  static QuestionDifficulty fromJson(String raw) {
    switch (raw) {
      case 'easy':
        return QuestionDifficulty.easy;
      case 'medium':
        return QuestionDifficulty.medium;
      case 'hard':
        return QuestionDifficulty.hard;
      default:
        return QuestionDifficulty.easy;
    }
  }
}

// ── Model ─────────────────────────────────────────────────────────────────────

/// Wire-format DTO for a Question row returned by the Supabase REST API.
///
/// Supabase (PostgREST) returns snake_case JSON keys. Hand-written
/// [fromJson]/[toJson] — no codegen required.
class QuestionModel {
  const QuestionModel({
    required this.questionId,
    required this.topicId,
    required this.questionText,
    required this.questionType,
    required this.difficulty,
    required this.correctAnswer,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    this.optionA,
    this.optionB,
    this.optionC,
    this.optionD,
    this.explanation,
  });

  final String questionId;
  final String topicId;
  final String questionText;
  final QuestionType questionType;
  final QuestionDifficulty difficulty;
  final String? optionA;
  final String? optionB;
  final String? optionC;
  final String? optionD;
  final String correctAnswer;
  final String? explanation;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory QuestionModel.fromJson(Map<String, dynamic> json) {
    return QuestionModel(
      questionId: json['id'] as String,
      topicId: json['topic_id'] as String,
      questionText: json['question_text'] as String,
      questionType:
          QuestionTypeX.fromJson(json['question_type'] as String? ?? 'mcq'),
      difficulty: QuestionDifficultyX.fromJson(
          json['difficulty'] as String? ?? 'easy'),
      optionA: json['option_a'] as String?,
      optionB: json['option_b'] as String?,
      optionC: json['option_c'] as String?,
      optionD: json['option_d'] as String?,
      correctAnswer: json['correct_answer'] as String,
      explanation: json['explanation'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': questionId,
        'topic_id': topicId,
        'question_text': questionText,
        'question_type': questionType.toJson(),
        'difficulty': difficulty.toJson(),
        'option_a': optionA,
        'option_b': optionB,
        'option_c': optionC,
        'option_d': optionD,
        'correct_answer': correctAnswer,
        'explanation': explanation,
        'is_active': isActive,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  Question toEntity() {
    return Question(
      questionId: questionId,
      topicId: topicId,
      questionText: questionText,
      questionType: questionType,
      difficulty: difficulty,
      optionA: optionA,
      optionB: optionB,
      optionC: optionC,
      optionD: optionD,
      correctAnswer: correctAnswer,
      explanation: explanation,
      isActive: isActive,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

// ── Request bodies ────────────────────────────────────────────────────────────

class CreateQuestionRequest {
  const CreateQuestionRequest({
    required this.topicId,
    required this.questionText,
    required this.questionType,
    required this.difficulty,
    required this.correctAnswer,
    this.optionA,
    this.optionB,
    this.optionC,
    this.optionD,
    this.explanation,
  });

  final String topicId;
  final String questionText;
  final QuestionType questionType;
  final QuestionDifficulty difficulty;
  final String? optionA;
  final String? optionB;
  final String? optionC;
  final String? optionD;
  final String correctAnswer;
  final String? explanation;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'topic_id': topicId,
        'question_text': questionText,
        'question_type': questionType.toJson(),
        'difficulty': difficulty.toJson(),
        'option_a': optionA,
        'option_b': optionB,
        'option_c': optionC,
        'option_d': optionD,
        'correct_answer': correctAnswer,
        if (explanation != null && explanation!.isNotEmpty)
          'explanation': explanation,
        'is_active': true,
      };
}

class UpdateQuestionRequest {
  const UpdateQuestionRequest({
    required this.topicId,
    required this.questionText,
    required this.questionType,
    required this.difficulty,
    required this.correctAnswer,
    required this.isActive,
    this.optionA,
    this.optionB,
    this.optionC,
    this.optionD,
    this.explanation,
  });

  final String topicId;
  final String questionText;
  final QuestionType questionType;
  final QuestionDifficulty difficulty;
  final String? optionA;
  final String? optionB;
  final String? optionC;
  final String? optionD;
  final String correctAnswer;
  final String? explanation;
  final bool isActive;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'topic_id': topicId,
        'question_text': questionText,
        'question_type': questionType.toJson(),
        'difficulty': difficulty.toJson(),
        'option_a': optionA,
        'option_b': optionB,
        'option_c': optionC,
        'option_d': optionD,
        'correct_answer': correctAnswer,
        'explanation':
            (explanation != null && explanation!.isNotEmpty) ? explanation : null,
        'is_active': isActive,
      };
}

class ToggleQuestionActiveRequest {
  const ToggleQuestionActiveRequest({required this.isActive});

  final bool isActive;

  Map<String, dynamic> toJson() => <String, dynamic>{'is_active': isActive};
}
