import 'package:flutter_test/flutter_test.dart';
import 'package:stylobuddy/app.dart';
import 'package:stylobuddy/core/router/app_router.dart';

void main() {
  testWidgets('app boots to the welcome screen', (tester) async {
    await tester.pumpWidget(StyloBuddyApp(router: createAppRouter()));
    await tester.pumpAndSettle();
    expect(find.text('Skip introduction'), findsOneWidget);
    expect(find.text('Home'), findsNothing);
  });
}
