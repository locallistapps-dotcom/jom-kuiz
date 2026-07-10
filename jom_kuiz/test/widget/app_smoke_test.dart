import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jom_kuiz/jom_kuiz_app.dart';

void main() {
  testWidgets('App boots and shows the splash screen', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: JomKuizApp()),
    );
    await tester.pump();

    expect(find.text('Jom Kuiz'), findsOneWidget);
  });
}
