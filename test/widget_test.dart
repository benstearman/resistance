import 'package:flutter_test/flutter_test.dart';

import 'package:resistance/main.dart';

void main() {
  testWidgets('App root renders smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const AppRoot());

    // Verify that the app starts without crashing.
    expect(find.byType(AppRoot), findsOneWidget);
  });
}
