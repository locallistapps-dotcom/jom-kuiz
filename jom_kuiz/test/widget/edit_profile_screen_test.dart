import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jom_kuiz/core/di/providers.dart';
import 'package:jom_kuiz/core/utils/result.dart';
import 'package:jom_kuiz/domain/entities/parent_profile.dart';
import 'package:jom_kuiz/domain/repositories/parent_repository.dart';
import 'package:jom_kuiz/presentation/providers/parent_providers.dart';
import 'package:jom_kuiz/presentation/screens/parent/edit_profile_screen.dart';

import '../helpers/fake_token_storage.dart';

// ---------------------------------------------------------------------------
// Fake repository
// ---------------------------------------------------------------------------

class _FakeParentRepository implements ParentRepository {
  ParentProfile profile = ParentProfile(
    parentId: 'p1',
    fullName: 'Ali Bin Abu',
    email: 'ali@example.com',
    emailVerified: true,
    accountStatus: AccountStatus.active,
    notificationEnabled: true,
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
  );

  Result<ParentProfile>? updateProfileResult;

  @override
  Future<Result<ParentProfile>> getProfile() async =>
      Result<ParentProfile>.success(profile);

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
      updateProfileResult ?? Result<ParentProfile>.success(profile);

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

/// Finds the [TextField] whose InputDecoration labelText equals [label].
/// This is more precise than [find.widgetWithText] when multiple TextFields
/// are present and the label text may also appear elsewhere (e.g. as a value
/// in another field).
Finder _fieldByLabel(String label) => find.byWidgetPredicate(
      (Widget widget) =>
          widget is TextField && widget.decoration?.labelText == label,
    );

/// Builds the screen under test with both required provider overrides:
///   1. [tokenStorageProvider] → [FakeTokenStorage] so [flutter_secure_storage]
///      is never reached (it throws [MissingPluginException] in unit/widget
///      tests that run outside a real device).
///   2. [parentRepositoryProvider] → fake for data control.
Widget _buildScreen(_FakeParentRepository repo) => ProviderScope(
      overrides: <Override>[
        tokenStorageProvider.overrideWithValue(FakeTokenStorage()),
        parentRepositoryProvider.overrideWithValue(repo),
      ],
      child: const MaterialApp(home: EditProfileScreen()),
    );

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  testWidgets('form is pre-populated with the loaded profile data',
      (WidgetTester tester) async {
    await tester.pumpWidget(_buildScreen(_FakeParentRepository()));
    await tester.pumpAndSettle();

    // The Full Name field's EditableText should contain the profile value.
    expect(find.widgetWithText(TextField, 'Ali Bin Abu'), findsOneWidget);
  });

  testWidgets('email field is disabled (read-only)', (WidgetTester tester) async {
    await tester.pumpWidget(_buildScreen(_FakeParentRepository()));
    await tester.pumpAndSettle();

    final TextField emailField = tester.widget<TextField>(_fieldByLabel('Email'));
    expect(emailField.enabled, isFalse);
  });

  testWidgets('shows validation error when full name is cleared',
      (WidgetTester tester) async {
    await tester.pumpWidget(_buildScreen(_FakeParentRepository()));
    await tester.pumpAndSettle();

    // Clear the full name and attempt to save.
    await tester.enterText(_fieldByLabel('Full Name'), '');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Save Changes'));
    await tester.pump();

    expect(find.text('Full name must be at least 2 characters'), findsOneWidget);
  });

  testWidgets('shows validation error for an invalid phone number',
      (WidgetTester tester) async {
    await tester.pumpWidget(_buildScreen(_FakeParentRepository()));
    await tester.pumpAndSettle();

    await tester.enterText(_fieldByLabel('Phone Number'), 'not-a-phone');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Save Changes'));
    await tester.pump();

    expect(find.text('Enter a valid phone number'), findsOneWidget);
  });

  testWidgets('avatar camera button shows a "coming soon" snackbar',
      (WidgetTester tester) async {
    await tester.pumpWidget(_buildScreen(_FakeParentRepository()));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.camera_alt_outlined));
    await tester.pump();

    expect(find.text('Avatar upload is coming soon'), findsOneWidget);
  });
}
