/// Education level for a child account.
///
/// Maps directly to the `education_level` column in the `children` table.
enum EducationLevel { preschool, primary, secondary }

/// Account status for a child.
enum ChildAccountStatus { active, disabled }

/// Helpers for education level display labels and year-grade option lists.
abstract final class EducationLevelHelper {
  static String labelFor(EducationLevel level) => switch (level) {
        EducationLevel.preschool => 'Preschool',
        EducationLevel.primary => 'Primary School',
        EducationLevel.secondary => 'Secondary School',
      };

  static List<String> yearGradeOptions(EducationLevel level) => switch (level) {
        EducationLevel.preschool => <String>['Preschool'],
        EducationLevel.primary => <String>[
            'Year 1',
            'Year 2',
            'Year 3',
            'Year 4',
            'Year 5',
            'Year 6',
          ],
        EducationLevel.secondary => <String>[
            'Form 1',
            'Form 2',
            'Form 3',
            'Form 4',
            'Form 5',
          ],
      };

  /// Parses the stored snake_case string (e.g. `"primary"`) back to enum.
  static EducationLevel fromString(String raw) =>
      EducationLevel.values.firstWhere(
        (EducationLevel e) => e.name == raw,
        orElse: () => EducationLevel.primary,
      );

  static ChildAccountStatus statusFromString(String raw) =>
      ChildAccountStatus.values.firstWhere(
        (ChildAccountStatus s) => s.name == raw,
        orElse: () => ChildAccountStatus.active,
      );
}
