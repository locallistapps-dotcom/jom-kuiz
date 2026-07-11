import '../../domain/entities/question.dart';

// ── Enum helpers ──────────────────────────────────────────────────────────────

extension QuestionTypeX on QuestionType {
  /// Returns the canonical string value accepted by the PostgreSQL CHECK
  /// constraint: questions_question_type_check
  ///   ARRAY['multiple_choice', 'true_false', 'short_answer']
  String toJson() {
    switch (this) {
      case QuestionType.mcq:
        return 'multiple_choice'; // was 'mcq' — DB requires 'multiple_choice'
      case QuestionType.trueFalse:
        return 'true_false';
      case QuestionType.fillInTheBlank:
        return 'short_answer'; // was 'fill_in_blank' — DB requires 'short_answer'
    }
  }

  static QuestionType fromJson(String raw) {
    switch (raw) {
      case 'mcq':
      case 'multiple_choice': // DB uses 'multiple_choice' (CHECK constraint)
        return QuestionType.mcq;
      case 'true_false':
        return QuestionType.trueFalse;
      case 'fill_in_blank':
      case 'short_answer': // DB CHECK allows 'short_answer' as fill-in variant
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
    this.explanationImageUrl,
    this.explanationVideoUrl,
    this.questionImageUrl,
    this.reference,
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
  final String? explanationImageUrl;
  final String? explanationVideoUrl;
  final String? questionImageUrl;
  final String? reference;
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
      explanationImageUrl: json['explanation_image_url'] as String?,
      explanationVideoUrl: json['explanation_video_url'] as String?,
      questionImageUrl: json['question_image_url'] as String?,
      reference: json['reference'] as String?,
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
        'explanation_image_url': explanationImageUrl,
        'explanation_video_url': explanationVideoUrl,
        'question_image_url': questionImageUrl,
        'reference': reference,
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
      explanationImageUrl: explanationImageUrl,
      explanationVideoUrl: explanationVideoUrl,
      questionImageUrl: questionImageUrl,
      reference: reference,
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
    this.explanationImageUrl,
    this.explanationVideoUrl,
    this.questionImageUrl,
    this.reference,
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
  final String? explanationImageUrl;
  final String? explanationVideoUrl;
  final String? questionImageUrl;
  final String? reference;

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
        if (explanationImageUrl != null && explanationImageUrl!.isNotEmpty)
          'explanation_image_url': explanationImageUrl,
        if (explanationVideoUrl != null && explanationVideoUrl!.isNotEmpty)
          'explanation_video_url': explanationVideoUrl,
        if (questionImageUrl != null && questionImageUrl!.isNotEmpty)
          'question_image_url': questionImageUrl,
        if (reference != null && reference!.isNotEmpty) 'reference': reference,
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
    this.explanationImageUrl,
    this.explanationVideoUrl,
    this.questionImageUrl,
    this.reference,
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
  final String? explanationImageUrl;
  final String? explanationVideoUrl;
  final String? questionImageUrl;
  final String? reference;
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
        'explanation_image_url': (explanationImageUrl != null &&
                explanationImageUrl!.isNotEmpty)
            ? explanationImageUrl
            : null,
        'explanation_video_url': (explanationVideoUrl != null &&
                explanationVideoUrl!.isNotEmpty)
            ? explanationVideoUrl
            : null,
        'question_image_url':
            (questionImageUrl != null && questionImageUrl!.isNotEmpty)
                ? questionImageUrl
                : null,
        'reference':
            (reference != null && reference!.isNotEmpty) ? reference : null,
        'is_active': isActive,
      };
}

class ToggleQuestionActiveRequest {
  const ToggleQuestionActiveRequest({required this.isActive});

  final bool isActive;

  Map<String, dynamic> toJson() => <String, dynamic>{'is_active': isActive};
}
