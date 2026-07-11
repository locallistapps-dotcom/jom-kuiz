import '../../core/error/failure.dart';
import '../../core/utils/result.dart';
import '../../data/models/account_management_models.dart';
import '../../domain/entities/education_level.dart';
import '../../domain/repositories/account_management_repository.dart';

/// Orchestrates parent CRUD over child accounts.
///
/// Enforces client-side business rules (non-empty fields, password length,
/// year-grade consistency) before delegating to the repository. This keeps
/// validation logic out of controllers and screens.
class AccountManagementService {
  const AccountManagementService({required AccountManagementRepository repo})
      : _repo = repo;

  final AccountManagementRepository _repo;

  static const int _minPasswordLength = 6;
  static const int _minNameLength = 2;
  static const int _minUsernameLength = 3;

  // ── Reads ────────────────────────────────────────────────────────────────

  Future<Result<List<ChildManagementModel>>> getChildren() =>
      _repo.getChildren();

  Future<Result<ChildManagementModel>> getChild(String childId) =>
      _repo.getChild(childId);

  // ── Mutations ────────────────────────────────────────────────────────────

  Future<Result<ChildManagementModel>> createChild({
    required String fullName,
    required String username,
    required String password,
    required EducationLevel educationLevel,
    required String yearGrade,
  }) async {
    final String? err = _validateCreate(
      fullName: fullName,
      username: username,
      password: password,
      educationLevel: educationLevel,
      yearGrade: yearGrade,
    );
    if (err != null) {
      return Result<ChildManagementModel>.failure(
          ValidationFailure(err, 'ACCT-VAL'));
    }

    // Check username availability before hitting the server.
    final Result<bool> availResult =
        await _repo.isUsernameAvailable(username.trim().toLowerCase());
    final bool available = availResult.when(
      success: (bool v) => v,
      failure: (_) => true, // let server decide on error
    );
    if (!available) {
      return const Result<ChildManagementModel>.failure(
        ValidationFailure(
            'Username is already taken', 'ACCT-001'),
      );
    }

    return _repo.createChild(
      fullName: fullName.trim(),
      username: username.trim().toLowerCase(),
      password: password,
      educationLevel: educationLevel,
      yearGrade: yearGrade,
    );
  }

  Future<Result<ChildManagementModel>> updateChild({
    required String childId,
    required String currentUsername,
    required String fullName,
    required String username,
    String? password,
    required EducationLevel educationLevel,
    required String yearGrade,
  }) async {
    final String? err = _validateUpdate(
      fullName: fullName,
      username: username,
      password: password,
      educationLevel: educationLevel,
      yearGrade: yearGrade,
    );
    if (err != null) {
      return Result<ChildManagementModel>.failure(
          ValidationFailure(err, 'ACCT-VAL'));
    }

    // Check username uniqueness only if it changed.
    final String trimmedUsername = username.trim().toLowerCase();
    if (trimmedUsername != currentUsername.toLowerCase()) {
      final Result<bool> availResult =
          await _repo.isUsernameAvailable(trimmedUsername);
      final bool available = availResult.when(
        success: (bool v) => v,
        failure: (_) => true,
      );
      if (!available) {
        return const Result<ChildManagementModel>.failure(
          ValidationFailure('Username is already taken', 'ACCT-001'),
        );
      }
    }

    return _repo.updateChild(
      childId: childId,
      fullName: fullName.trim(),
      username: trimmedUsername,
      password: password,
      educationLevel: educationLevel,
      yearGrade: yearGrade,
    );
  }

  Future<Result<ChildManagementModel>> setChildStatus({
    required String childId,
    required ChildAccountStatus status,
  }) =>
      _repo.setChildStatus(childId: childId, status: status);

  Future<Result<void>> resetChildPassword({
    required String childId,
    required String newPassword,
  }) {
    if (newPassword.length < _minPasswordLength) {
      return Future<Result<void>>.value(
        Result<void>.failure(
          ValidationFailure(
            'Password must be at least $_minPasswordLength characters',
            'ACCT-VAL',
          ),
        ),
      );
    }
    return _repo.resetChildPassword(
        childId: childId, newPassword: newPassword);
  }

  Future<Result<bool>> isUsernameAvailable(String username) =>
      _repo.isUsernameAvailable(username);

  // ── Auto-generate username ───────────────────────────────────────────────

  /// Generates a candidate username from [name] + 4 random digits.
  ///
  /// Callers should still call [isUsernameAvailable] before presenting it to
  /// the user, since no uniqueness check is performed here.
  static String generateUsername(String name) {
    final String base = name
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]'), '')
        .substring(0, name.length.clamp(1, 6));
    final int suffix = DateTime.now().microsecond % 10000;
    return '$base${suffix.toString().padLeft(4, '0')}';
  }

  // ── Validation ───────────────────────────────────────────────────────────

  String? _validateCreate({
    required String fullName,
    required String username,
    required String password,
    required EducationLevel educationLevel,
    required String yearGrade,
  }) {
    if (fullName.trim().length < _minNameLength) {
      return 'Full name must be at least $_minNameLength characters';
    }
    if (username.trim().length < _minUsernameLength) {
      return 'Username must be at least $_minUsernameLength characters';
    }
    if (password.length < _minPasswordLength) {
      return 'Password must be at least $_minPasswordLength characters';
    }
    return _validateYearGrade(educationLevel, yearGrade);
  }

  String? _validateUpdate({
    required String fullName,
    required String username,
    String? password,
    required EducationLevel educationLevel,
    required String yearGrade,
  }) {
    if (fullName.trim().length < _minNameLength) {
      return 'Full name must be at least $_minNameLength characters';
    }
    if (username.trim().length < _minUsernameLength) {
      return 'Username must be at least $_minUsernameLength characters';
    }
    if (password != null && password.length < _minPasswordLength) {
      return 'Password must be at least $_minPasswordLength characters';
    }
    return _validateYearGrade(educationLevel, yearGrade);
  }

  String? _validateYearGrade(EducationLevel level, String yearGrade) {
    final List<String> options = EducationLevelHelper.yearGradeOptions(level);
    if (!options.contains(yearGrade)) {
      return 'Year / Grade "$yearGrade" is not valid for '
          '${EducationLevelHelper.labelFor(level)}';
    }
    return null;
  }
}
