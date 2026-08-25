import 'package:flutter_test/flutter_test.dart';

import 'package:donjo/main.dart';

void main() {
  testWidgets('App boots into splash screen', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('Donjo'), findsOneWidget);
  });
}
