import 'package:flutter_test/flutter_test.dart';
import 'package:jom_kuiz/core/error/failure.dart';
import 'package:jom_kuiz/data/services/parent_service.dart';
import 'package:jom_kuiz/data/services/session_manager.dart';
import 'package:jom_kuiz/data/services/token_manager.dart';
import 'package:jom_kuiz/core/utils/result.dart';
import 'package:jom_kuiz/domain/entities/parent_profile.dart';
import 'package:jom_kuiz/domain/repositories/parent_repository.dart';

import '../helpers/fake_token_storage.dart';

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
  Future<Result<void>> deleteAccount() async => deleteAccountResult ?? const Result<void>.success(null);
}

ParentProfile _profile() {
  final DateTime now = DateTime(2026, 1, 1);
  return ParentProfile(
    parentId: 'p1',
    fullName: 'Ali Bin Abu',
    email: 'ali@example.com',
    emailVerified: true,
    accountStatus: AccountStatus.active,
    notificationEnabled: true,
    createdAt: now,
    updatedAt: now,
  );
}

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

  test('getProfile passes through the repository result', () async {
    repository.getProfileResult = Result<ParentProfile>.success(_profile());

    final result = await service.getProfile();

    expect(result, isA<Success<ParentProfile>>());
  });

  test('deleteAccount clears the local session even though the repo has no tokens to begin with', () async {
    repository.deleteAccountResult = const Result<void>.success(null);

    final result = await service.deleteAccount();

    expect(result, isA<Success<void>>());
    expect(await tokenManager.hasValidSession, isFalse);
  });

  test('deleteAccount keeps the local session intact when the server call fails', () async {
    await tokenManager.saveTokens(
      accessToken: 'access',
      refreshToken: 'refresh',
      expiresAt: DateTime.now().add(const Duration(minutes: 30)),
    );
    repository.deleteAccountResult = const Result<void>.failure(ServerFailure('boom'));

    final result = await service.deleteAccount();

    // A failed deletion must not force-logout a parent whose account still
    // exists -- they need to stay signed in to see the error and retry.
    expect(result, isA<ResultFailure<void>>());
    expect(await tokenManager.hasValidSession, isTrue);
  });
}
