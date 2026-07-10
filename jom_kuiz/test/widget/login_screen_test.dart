import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jom_kuiz/presentation/screens/auth/login_screen.dart';
import 'package:jom_kuiz/presentation/widgets/buttons/primary_button.dart';

void main() {
  testWidgets('shows validation errors for empty email and password', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: LoginScreen()),
      ),
    );

    await tester.tap(find.widgetWithText(PrimaryButton, 'Login'));
    await tester.pump();

    expect(find.text('Email is required'), findsOneWidget);
    expect(find.text('Password is required'), findsOneWidget);
  });

  testWidgets('shows an invalid-email error for malformed input', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: LoginScreen()),
      ),
    );

    await tester.enterText(find.byType(TextField).first, 'not-an-email');
    await tester.tap(find.widgetWithText(PrimaryButton, 'Login'));
    await tester.pump();

    expect(find.text('Enter a valid email address'), findsOneWidget);
  });
}
