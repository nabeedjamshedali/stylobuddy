// Smoke test: app boots to the splash screen without throwing.

import 'package:flutter_test/flutter_test.dart';

import 'package:stylobuddy/main.dart';

void main() {
  testWidgets('App boots and shows splash screen', (WidgetTester tester) async {
    await tester.pumpWidget(const StyloBuddyApp());
    await tester.pump();

    expect(find.text('STYLOBUDDY'), findsOneWidget);

    // Let the splash screen's auto-navigate timer finish so no pending
    // timer leaks past the end of the test.
    await tester.pumpAndSettle(const Duration(milliseconds: 1700));
  });
}
