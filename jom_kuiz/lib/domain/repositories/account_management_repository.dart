import '../../core/utils/result.dart';
import '../entities/education_level.dart';
import '../../data/models/account_management_models.dart';

/// Account Management repository contract — parent CRUD over child accounts.
///
/// All mutations return [Result]<T> so the presentation layer can handle
/// errors without exception propagation.
abstract class AccountManagementRepository {
  /// Returns all children belonging to the authenticated parent, ordered by
  /// creation date ascending.
  Future<Result<List<ChildManagementModel>>> getChildren();

  /// Returns a single child record.
  Future<Result<ChildManagementModel>> getChild(String childId);

  /// Creates a child account. The server generates the student ID and hashes
  /// the password — the client never sends or stores them in plain text.
  Future<Result<ChildManagementModel>> createChild({
    required String fullName,
    required String username,
    required String password,
    required EducationLevel educationLevel,
    required String yearGrade,
  });

  /// Updates editable child fields. Pass [password] to change it; `null`
  /// leaves the existing password unchanged.
  Future<Result<ChildManagementModel>> updateChild({
    required String childId,
    required String fullName,
    required String username,
    String? password,
    required EducationLevel educationLevel,
    required String yearGrade,
  });

  /// Enables or disables a child account. A disabled child cannot log in but
  /// their quiz history is preserved.
  Future<Result<ChildManagementModel>> setChildStatus({
    required String childId,
    required ChildAccountStatus status,
  });

  /// Resets a child's password. Only the linked parent may call this.
  Future<Result<void>> resetChildPassword({
    required String childId,
    required String newPassword,
  });

  /// Returns `true` if [username] is not already taken.
  Future<Result<bool>> isUsernameAvailable(String username);

  /// Permanently deletes a child account.
  ///
  /// The server verifies that the caller is the child's parent before
  /// performing the hard delete. Quiz history and related data will be
  /// removed according to the database cascade rules.
  Future<Result<void>> deleteChild({required String childId});
}
