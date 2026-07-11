import '../../core/utils/result.dart';
import '../../domain/entities/parent_profile.dart';
import '../../domain/repositories/parent_repository.dart';
import 'session_manager.dart';

/// Orchestrates the Parent module's business flows.
///
/// Thin for now (mostly pass-through to [ParentRepository]) -- the one
/// piece of cross-cutting behavior is `deleteAccount`, which also clears the
/// local session via [SessionManager] since a deleted account must not stay
/// signed in on the device.
class ParentService {
  ParentService({
    required ParentRepository repository,
    required SessionManager sessionManager,
  })  : _repository = repository,
        _sessionManager = sessionManager;

  final ParentRepository _repository;
  final SessionManager _sessionManager;

  Future<Result<ParentProfile>> getProfile() => _repository.getProfile();

  Future<Result<ParentProfile>> updateProfile({
    required String fullName,
    String? phoneNumber,
    String? country,
    String? state,
    String? city,
    String? gender,
    DateTime? dateOfBirth,
    String? language,
    String? bio,
  }) {
    return _repository.updateProfile(
      fullName: fullName,
      phoneNumber: phoneNumber,
      country: country,
      state: state,
      city: city,
      gender: gender,
      dateOfBirth: dateOfBirth,
      language: language,
      bio: bio,
    );
  }

  /// [localFilePath] is a placeholder for a real image picker result -- no
  /// actual file upload wiring exists yet (see module scope notes).
  Future<Result<ParentProfile>> updateAvatar({required String localFilePath}) {
    return _repository.updateAvatar(localFilePath: localFilePath);
  }

  Future<Result<void>> updatePassword({
    required String currentPassword,
    required String newPassword,
  }) {
    return _repository.updatePassword(currentPassword: currentPassword, newPassword: newPassword);
  }

  Future<Result<ParentProfile>> updateSettings({
    String? language,
    bool? notificationEnabled,
  }) {
    return _repository.updateSettings(language: language, notificationEnabled: notificationEnabled);
  }

  /// Deletes the account server-side. The local session is only cleared once
  /// the server confirms deletion -- on failure the parent stays signed in
  /// so they can see the error and retry, rather than being force-logged-out
  /// of an account that still exists.
  Future<Result<void>> deleteAccount() async {
    final Result<void> result = await _repository.deleteAccount();
    return result.when(
      success: (_) async {
        await _sessionManager.endSession();
        return const Result<void>.success(null);
      },
      failure: (failure) async => Result<void>.failure(failure),
    );
  }
}
