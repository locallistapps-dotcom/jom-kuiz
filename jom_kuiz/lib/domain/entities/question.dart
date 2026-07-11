import 'package:equatable/equatable.dart';

/// The format of a question.
enum QuestionType { multipleChoice, trueFalse, shortAnswer }

/// A single item in the question bank.
class Question extends Equatable {
  const Question({
    required this.questionId,
    required this.topicId,
    required this.text,
    required this.type,
    required this.difficulty,
    required this.correctAnswer,
    this.options = const <String>[],
    this.explanation,
  });

  final String questionId;
  final String topicId;
  final String text;
  final QuestionType type;

  /// Mirrors [QuizDifficulty] from quiz.dart — kept separate to avoid coupling
  /// the question bank to the quiz presentation layer.
  final String difficulty;

  /// The correct answer string (option text or short-answer value).
  final String correctAnswer;

  /// Answer options for [QuestionType.multipleChoice].
  final List<String> options;

  /// Optional explanation shown after answering.
  final String? explanation;

  @override
  List<Object?> get props => <Object?>[
        questionId,
        topicId,
        text,
        type,
        difficulty,
        correctAnswer,
        options,
        explanation,
      ];
}
