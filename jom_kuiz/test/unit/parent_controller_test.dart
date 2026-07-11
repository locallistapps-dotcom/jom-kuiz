import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jom_kuiz/core/di/providers.dart';
import 'package:jom_kuiz/core/error/failure.dart';
import 'package:jom_kuiz/core/utils/result.dart';
import 'package:jom_kuiz/domain/entities/parent_profile.dart';
import 'package:jom_kuiz/domain/repositories/parent_repository.dart';
import 'package:jom_kuiz/presentation/controllers/parent_controller.dart';
import 'package:jom_kuiz/presentation/providers/parent_providers.dart';

import '../helpers/fake_token_storage.dart';

// ---------------------------------------------------------------------------
// Fake repository
// ---------------------------------------------------------------------------

class _FakeParentRepository implements ParentRepository {
  Result<ParentProfile>? getProfileResult;
  Result<ParentProfile>? updateProfileResult;

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
      throw UnimplementedError();

  @override
  Future<Result<void>> updatePassword({
    required String currentPassword,
    required String newPassword,
  }) async =>
      throw UnimplementedError();

  @override
  Future<Result<ParentProfile>> updateSettings({
    String? language,
    bool? notificationEnabled,
  }) async =>
      throw UnimplementedError();

  @override
  Future<Result<void>> deleteAccount() async => throw UnimplementedError();
}

// ---------------------------------------------------------------------------
// Helper
// ---------------------------------------------------------------------------

ParentProfile _profile({String fullName = 'Ali Bin Abu'}) {
  final DateTime now = DateTime(2026, 1, 1);
  return ParentProfile(
    parentId: 'p1',
    fullName: fullName,
    email: 'ali@example.com',
    emailVerified: true,
    accountStatus: AccountStatus.active,
    notificationEnabled: true,
    createdAt: now,
    updatedAt: now,
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  late _FakeParentRepository repository;

  /// Builds a [ProviderContainer] with:
  ///   - [tokenStorageProvider] → [FakeTokenStorage] (avoids flutter_secure_storage
  ///     plugin which throws [MissingPluginException] outside a real device)
  ///   - [parentRepositoryProvider] → fake repository for behaviour control
  ProviderContainer buildContainer() {
    return ProviderContainer(
      overrides: <Override>[
        tokenStorageProvider.overrideWithValue(FakeTokenStorage()),
        parentRepositoryProvider.overrideWithValue(repository),
      ],
    );
  }

  setUp(() {
    repository = _FakeParentRepository();
  });

  test('build() loads the profile on first read', () async {
    repository.getProfileResult = Result<ParentProfile>.success(_profile());
    final ProviderContainer container = buildContainer();
    addTearDown(container.dispose);

    final ParentProfile? profile = await container.read(parentControllerProvider.future);

    expect(profile?.fullName, 'Ali Bin Abu');
  });

  test('updateProfile updates state with the new profile on success', () async {
    repository.getProfileResult = Result<ParentProfile>.success(_profile());
    repository.updateProfileResult =
        Result<ParentProfile>.success(_profile(fullName: 'Ali Updated'));
    final ProviderContainer container = buildContainer();
    addTearDown(container.dispose);
    await container.read(parentControllerProvider.future);

    final Result<ParentProfile> result =
        await container.read(parentControllerProvider.notifier).updateProfile(
              fullName: 'Ali Updated',
            );

    expect(result, isA<Success<ParentProfile>>());
    expect(container.read(parentControllerProvider).valueOrNull?.fullName, 'Ali Updated');
  });

  test('updateProfile failure leaves prior state intact — no spinner, no data loss', () async {
    repository.getProfileResult = Result<ParentProfile>.success(_profile());
    repository.updateProfileResult =
        const Result<ParentProfile>.failure(ValidationFailure('bad phone'));
    final ProviderContainer container = buildContainer();
    addTearDown(container.dispose);
    await container.read(parentControllerProvider.future);

    final Result<ParentProfile> result =
        await container.read(parentControllerProvider.notifier).updateProfile(
              fullName: 'Ali Updated',
            );

    expect(result, isA<ResultFailure<ParentProfile>>());
    // The original profile value must survive the failed mutation.
    expect(container.read(parentControllerProvider).valueOrNull?.fullName, 'Ali Bin Abu');
    expect(container.read(parentControllerProvider).hasError, isFalse);
  });

  test('refresh() reloads the profile from the service', () async {
    repository.getProfileResult = Result<ParentProfile>.success(_profile());
    final ProviderContainer container = buildContainer();
    addTearDown(container.dispose);
    await container.read(parentControllerProvider.future);

    repository.getProfileResult =
        Result<ParentProfile>.success(_profile(fullName: 'Ali Refreshed'));
    await container.read(parentControllerProvider.notifier).refresh();

    expect(container.read(parentControllerProvider).valueOrNull?.fullName, 'Ali Refreshed');
  });
}
