import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/education_level.dart';
import '../controllers/child_profile_controller.dart';

/// The authenticated child's education level; `null` if not in a child
/// session or the profile has not loaded yet.
///
/// Used by the Quiz Engine home screen to show only subjects relevant to
/// the child's year / grade.
final Provider<EducationLevel?> childEducationLevelProvider =
    Provider<EducationLevel?>((Ref ref) {
  return ref
      .watch(childProfileControllerProvider)
      .valueOrNull
      ?.educationLevel;
});

/// The authenticated child's year / grade string (e.g. `"Year 3"`).
/// `null` if not available.
final Provider<String?> childYearGradeProvider =
    Provider<String?>((Ref ref) {
  return ref
      .watch(childProfileControllerProvider)
      .valueOrNull
      ?.yearGrade;
});
