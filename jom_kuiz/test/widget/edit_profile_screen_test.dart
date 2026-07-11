import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jom_kuiz/core/utils/result.dart';
import 'package:jom_kuiz/domain/entities/parent_profile.dart';
import 'package:jom_kuiz/domain/repositories/parent_repository.dart';
import 'package:jom_kuiz/presentation/providers/parent_providers.dart';
import 'package:jom_kuiz/presentation/screens/parent/edit_profile_screen.dart';
import 'package:jom_kuiz/presentation/widgets/buttons/primary_button.dart';

class _FakeParentRepository implements ParentRepository {
  @override
  Future<Result<ParentProfile>> getProfile() async {
    final DateTime now = DateTime(2026, 1, 1);
    return Result<ParentProfile>.success(
      ParentProfile(
        parentId: 'p1',
        fullName: 'Ali Bin Abu',
        email: 'ali@example.com',
        emailVerified: true,
        accountStatus: AccountStatus.active,
        notificationEnabled: true,
        createdAt: now,
        updatedAt: now,
      ),
    );
  }

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
      throw UnimplementedError();

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

void main() {
  testWidgets('shows a validation error when full name is cleared', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          parentRepositoryProvider.overrideWithValue(_FakeParentRepository()),
        ],
        child: const MaterialApp(home: EditProfileScreen()),
      ),
    );

    // Let the profile load resolve and hydrate the form.
    await tester.pumpAndSettle();

    final Finder fullNameField = find.widgetWithText(TextField, 'Full Name');
    await tester.enterText(fullNameField, '');
    await tester.tap(find.widgetWithText(PrimaryButton, 'Save Changes'));
    await tester.pump();

    expect(find.text('Full name must be at least 2 characters'), findsOneWidget);
  });

  testWidgets('email field is read-only', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          parentRepositoryProvider.overrideWithValue(_FakeParentRepository()),
        ],
        child: const MaterialApp(home: EditProfileScreen()),
      ),
    );
    await tester.pumpAndSettle();

    final TextField emailField = tester.widget<TextField>(find.widgetWithText(TextField, 'Email'));
    expect(emailField.enabled, isFalse);
  });
}
