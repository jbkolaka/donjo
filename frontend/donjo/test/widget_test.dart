import 'package:flutter_test/flutter_test.dart';

import 'package:donjo/main.dart';

void main() {
  testWidgets('App boots into initial screen', (WidgetTester tester) async {
    await tester.pumpWidget(const DonjoApp());
    await tester.pumpAndSettle();

    expect(find.text('Sign in to account'), findsOneWidget);
  });
}
