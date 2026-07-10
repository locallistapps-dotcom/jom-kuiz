import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jom_kuiz/core/di/providers.dart';
import 'package:jom_kuiz/core/storage/token_storage.dart';
import 'package:jom_kuiz/jom_kuiz_app.dart';

import '../helpers/fake_token_storage.dart';

void main() {
  testWidgets('App boots and shows the splash screen', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        // The splash screen triggers a session check on boot, which reads
        // token storage -- override with an in-memory fake so this test
        // never touches the real `flutter_secure_storage` plugin.
        overrides: <Override>[
          tokenStorageProvider.overrideWith((ref) => FakeTokenStorage()),
        ],
        child: const JomKuizApp(),
      ),
    );
    await tester.pump();

    expect(find.text('Jom Kuiz'), findsOneWidget);
  });
}
