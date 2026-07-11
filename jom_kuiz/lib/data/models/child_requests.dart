/// Request payloads for the Child REST endpoints.
///
/// Self-edit fields (bio, gender, dateOfBirth) are child-editable.
/// Education level, year/grade, username, and password are parent-only.
/// School and grade fields have been removed — replaced by structured
/// education level + year/grade managed via AccountManagementService.

class UpdateChildProfileRequest {
  const UpdateChildProfileRequest({
    required this.fullName,
    this.dateOfBirth,
    this.gender,
    this.bio,
  });

  final String fullName;
  final String? dateOfBirth; // ISO-8601 date string
  final String? gender;
  final String? bio;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'full_name': fullName,
        'date_of_birth': dateOfBirth,
        'gender': gender,
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
