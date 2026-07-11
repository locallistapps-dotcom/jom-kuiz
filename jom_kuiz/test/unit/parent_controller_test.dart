import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jom_kuiz/core/error/failure.dart';
import 'package:jom_kuiz/core/utils/result.dart';
import 'package:jom_kuiz/data/services/session_manager.dart';
import 'package:jom_kuiz/data/services/token_manager.dart';
import 'package:jom_kuiz/domain/entities/parent_profile.dart';
import 'package:jom_kuiz/domain/repositories/parent_repository.dart';
import 'package:jom_kuiz/presentation/controllers/parent_controller.dart';
import 'package:jom_kuiz/presentation/providers/parent_providers.dart';

import '../helpers/fake_token_storage.dart';

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

void main() {
  late _FakeParentRepository repository;

  ProviderContainer buildContainer() {
    return ProviderContainer(
      overrides: <Override>[
        parentRepositoryProvider.overrideWithValue(repository),
      ],
    );
  }

  setUp(() {
    repository = _FakeParentRepository();
  });

  test('build() loads the profile from the service on first read', () async {
    repository.getProfileResult = Result<ParentProfile>.success(_profile());
    final ProviderContainer container = buildContainer();
    addTearDown(container.dispose);

    final ParentProfile? profile = await container.read(parentControllerProvider.future);

    expect(profile?.fullName, 'Ali Bin Abu');
  });

  test('updateProfile updates state with the new profile on success', () async {
    repository.getProfileResult = Result<ParentProfile>.success(_profile());
    repository.updateProfileResult = Result<ParentProfile>.success(_profile(fullName: 'Ali Updated'));
    final ProviderContainer container = buildContainer();
    addTearDown(container.dispose);
    await container.read(parentControllerProvider.future);

    final result = await container.read(parentControllerProvider.notifier).updateProfile(
          fullName: 'Ali Updated',
        );

    expect(result, isA<Success<ParentProfile>>());
    expect(container.read(parentControllerProvider).valueOrNull?.fullName, 'Ali Updated');
  });

  test('updateProfile surfaces a failure without discarding the previous profile value', () async {
    repository.getProfileResult = Result<ParentProfile>.success(_profile());
    repository.updateProfileResult = const Result<ParentProfile>.failure(ValidationFailure('bad phone'));
    final ProviderContainer container = buildContainer();
    addTearDown(container.dispose);
    await container.read(parentControllerProvider.future);

    final result = await container.read(parentControllerProvider.notifier).updateProfile(
          fullName: 'Ali Updated',
        );

    expect(result, isA<ResultFailure<ParentProfile>>());
    // The previous profile must still be intact -- a failed mutation should
    // never blank the screen or leave it stuck showing a loading spinner.
    expect(container.read(parentControllerProvider).valueOrNull?.fullName, 'Ali Bin Abu');
    expect(container.read(parentControllerProvider).hasError, isFalse);
  });
}
