/// Request payloads for the Child REST endpoints.
///
/// Plain classes — no codegen required.

class UpdateChildProfileRequest {
  const UpdateChildProfileRequest({
    required this.fullName,
    this.dateOfBirth,
    this.gender,
    this.school,
    this.grade,
    this.bio,
  });

  final String fullName;
  final String? dateOfBirth; // ISO-8601 date string
  final String? gender;
  final String? school;
  final String? grade;
  final String? bio;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'full_name': fullName,
        'date_of_birth': dateOfBirth,
        'gender': gender,
        'school': school,
        'grade': grade,
        'bio': bio,
      };
}

class UpdateChildAvatarRequest {
  const UpdateChildAvatarRequest({required this.localFilePath});

  final String localFilePath;

  Map<String, dynamic> toJson() =>
      <String, dynamic>{'local_file_path': localFilePath};
}

class SubmitQuizRequest {
  const SubmitQuizRequest({
    required this.quizId,
    required this.childId,
    required this.answers,
    required this.timeTakenSeconds,
  });

  final String quizId;
  final String childId;

  /// Map of questionId → selected answer key.
  final Map<String, dynamic> answers;
  final int timeTakenSeconds;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'quiz_id': quizId,
        'child_id': childId,
        'answers': answers,
        'time_taken_seconds': timeTakenSeconds,
      };
}
