import 'package:equatable/equatable.dart';

/// The format / interaction type of a question.
enum QuestionType {
  /// Multiple-choice with up to four labelled options (A–D).
  /// At least two options are required.
  mcq,

  /// Binary choice — the answer is either `true` or `false`.
  trueFalse,

  /// The learner types a free-text answer; no MCQ options are stored.
  fillInTheBlank,
}

/// Difficulty level of a question.
enum QuestionDifficulty {
  easy,
  medium,
  hard,
}

/// Sort options available in the Question Bank screen.
enum QuestionSortOrder {
  /// Newest first by [Question.createdAt].
  createdAtDesc,

  /// Alphabetical A → Z by [Question.questionText].
  textAsc,

  /// Easy → Medium → Hard.
  difficultyAsc,
}

/// A single question in the question bank.
///
/// Hierarchy:  Question → Topic → Chapter → (Subject, Year)
///
/// Type rules enforced at the service layer:
/// • [QuestionType.mcq]           — [optionA] and [optionB] required;
///                                   [optionC] and [optionD] optional;
///                                   [correctAnswer] = 'A' | 'B' | 'C' | 'D'
/// • [QuestionType.trueFalse]     — options ignored;
///                                   [correctAnswer] = 'true' | 'false'
/// • [QuestionType.fillInTheBlank]— options ignored;
///                                   [correctAnswer] = any non-empty string
class Question extends Equatable {
  const Question({
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

  /// Primary key — UUID supplied by Supabase.
  final String questionId;

  /// Foreign key → topics.id
  final String topicId;

  /// The full text of the question.
  final String questionText;

  final QuestionType questionType;
  final QuestionDifficulty difficulty;

  // MCQ options — null for non-MCQ types.
  final String? optionA;
  final String? optionB;
  final String? optionC;
  final String? optionD;

  /// Correct answer:
  ///   MCQ         → 'A' | 'B' | 'C' | 'D'
  ///   True/False  → 'true' | 'false'
  ///   Fill Blank  → the expected answer text
  final String correctAnswer;

  /// Optional explanation shown after answering (only in Review screen).
  final String? explanation;

  /// Optional URL to an image that supplements the explanation.
  /// Displayed in the Review screen below the explanation text.
  final String? explanationImageUrl;

  /// Optional URL to a video that supplements the explanation.
  final String? explanationVideoUrl;

  /// Optional URL to an image shown alongside the question text.
  final String? questionImageUrl;

  /// Optional textbook / curriculum reference (e.g. "KSSR Semakan, pg. 42").
  final String? reference;

  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  Question copyWith({
    String? questionId,
    String? topicId,
    String? questionText,
    QuestionType? questionType,
    QuestionDifficulty? difficulty,
    String? optionA,
    String? optionB,
    String? optionC,
    String? optionD,
    String? correctAnswer,
    String? explanation,
    String? explanationImageUrl,
    String? explanationVideoUrl,
    String? questionImageUrl,
    String? reference,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Question(
      questionId: questionId ?? this.questionId,
      topicId: topicId ?? this.topicId,
      questionText: questionText ?? this.questionText,
      questionType: questionType ?? this.questionType,
      difficulty: difficulty ?? this.difficulty,
      optionA: optionA ?? this.optionA,
      optionB: optionB ?? this.optionB,
      optionC: optionC ?? this.optionC,
      optionD: optionD ?? this.optionD,
      correctAnswer: correctAnswer ?? this.correctAnswer,
      explanation: explanation ?? this.explanation,
      explanationImageUrl: explanationImageUrl ?? this.explanationImageUrl,
      explanationVideoUrl: explanationVideoUrl ?? this.explanationVideoUrl,
      questionImageUrl: questionImageUrl ?? this.questionImageUrl,
      reference: reference ?? this.reference,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => <Object?>[
        questionId,
        topicId,
        questionText,
        questionType,
        difficulty,
        optionA,
        optionB,
        optionC,
        optionD,
        correctAnswer,
        explanation,
        explanationImageUrl,
        explanationVideoUrl,
        questionImageUrl,
        reference,
        isActive,
        createdAt,
        updatedAt,
      ];
}
