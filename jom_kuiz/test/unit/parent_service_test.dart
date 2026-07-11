import 'package:flutter_test/flutter_test.dart';
import 'package:jom_kuiz/core/error/failure.dart';
import 'package:jom_kuiz/core/utils/result.dart';
import 'package:jom_kuiz/data/services/parent_service.dart';
import 'package:jom_kuiz/data/services/session_manager.dart';
import 'package:jom_kuiz/data/services/token_manager.dart';
import 'package:jom_kuiz/domain/entities/parent_profile.dart';
import 'package:jom_kuiz/domain/repositories/parent_repository.dart';

import '../helpers/fake_token_storage.dart';

// ---------------------------------------------------------------------------
// Fake repository
// ---------------------------------------------------------------------------

class _FakeParentRepository implements ParentRepository {
  Result<ParentProfile>? getProfileResult;
  Result<ParentProfile>? updateProfileResult;
  Result<ParentProfile>? updateAvatarResult;
  Result<void>? updatePasswordResult;
  Result<ParentProfile>? updateSettingsResult;
  Result<void>? deleteAccountResult;

  @override
  Future<Result<ParentProfile>> getProfile() async => getProfileResult!;

  @override
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
  }) async =>
      updateProfileResult!;

  @override
  Future<Result<ParentProfile>> updateAvatar({required String localFilePath}) async =>
      updateAvatarResult!;

  @override
  Future<Result<void>> updatePassword({
    required String currentPassword,
    required String newPassword,
  }) async =>
      updatePasswordResult ?? const Result<void>.success(null);

  @override
  Future<Result<ParentProfile>> updateSettings({
    String? language,
    bool? notificationEnabled,
  }) async =>
      updateSettingsResult!;

  @override
  Future<Result<void>> deleteAccount() async =>
      deleteAccountResult ?? const Result<void>.success(null);
}

// ---------------------------------------------------------------------------
// Helper
// ---------------------------------------------------------------------------

ParentProfile _profile() {
  final DateTime ts = DateTime(2026, 1, 1);
  return ParentProfile(
    parentId: 'p1',
    fullName: 'Ali Bin Abu',
    email: 'ali@example.com',
    emailVerified: true,
    accountStatus: AccountStatus.active,
    notificationEnabled: true,
    createdAt: ts,
    updatedAt: ts,
  );
}

/// Fixed future expiry used in token-persistence tests so the value is
/// deterministic (avoids flakiness from wall-clock comparisons).
final DateTime _futureExpiry = DateTime(2027, 1, 1);

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  late _FakeParentRepository repository;
  late TokenManager tokenManager;
  late ParentService service;

  setUp(() {
    repository = _FakeParentRepository();
    tokenManager = TokenManager(FakeTokenStorage());
    service = ParentService(
      repository: repository,
      sessionManager: SessionManager(tokenManager),
    );
  });

  // ---- getProfile -----------------------------------------------------------

  test('getProfile passes through a successful repository result', () async {
    repository.getProfileResult = Result<ParentProfile>.success(_profile());

    final Result<ParentProfile> result = await service.getProfile();

    expect(result, isA<Success<ParentProfile>>());
    expect((result as Success<ParentProfile>).data.fullName, 'Ali Bin Abu');
  });

  test('getProfile passes through a failure result unchanged', () async {
    repository.getProfileResult =
        const Result<ParentProfile>.failure(ServerFailure('not found'));

    final Result<ParentProfile> result = await service.getProfile();

    expect(result, isA<ResultFailure<ParentProfile>>());
  });

  // ---- deleteAccount --------------------------------------------------------

  test('deleteAccount clears the local session on server success', () async {
    await tokenManager.saveTokens(
      accessToken: 'access',
      refreshToken: 'refresh',
      expiresAt: _futureExpiry,
    );
    repository.deleteAccountResult = const Result<void>.success(null);

    final Result<void> result = await service.deleteAccount();

    expect(result, isA<Success<void>>());
    // Session must be gone so RouteGuard can redirect to login.
    expect(await tokenManager.hasValidSession, isFalse);
  });

  test('deleteAccount keeps the local session when the server call fails', () async {
    await tokenManager.saveTokens(
      accessToken: 'access',
      refreshToken: 'refresh',
      expiresAt: _futureExpiry,
    );
    repository.deleteAccountResult =
        const Result<void>.failure(ServerFailure('server error'));

    final Result<void> result = await service.deleteAccount();

    // A failed deletion must NOT sign the parent out — their account still
    // exists and they need to stay authenticated to see the error and retry.
    expect(result, isA<ResultFailure<void>>());
    expect(await tokenManager.hasValidSession, isTrue);
  });

  test('deleteAccount on an empty session succeeds without throwing', () async {
    // No tokens were ever stored — deleteAccount should still complete cleanly.
    repository.deleteAccountResult = const Result<void>.success(null);

    final Result<void> result = await service.deleteAccount();

    expect(result, isA<Success<void>>());
    expect(await tokenManager.hasValidSession, isFalse);
  });

  // ---- updatePassword -------------------------------------------------------

  test('updatePassword passes through the repository result', () async {
    repository.updatePasswordResult = const Result<void>.success(null);

    final Result<void> result = await service.updatePassword(
      currentPassword: 'oldPass1!',
      newPassword: 'newPass1!',
    );

    expect(result, isA<Success<void>>());
  });
}
