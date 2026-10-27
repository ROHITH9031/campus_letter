// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:campus_letter/main.dart';

void main() {
  testWidgets('shows the two letter formats and opens the editor', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const CampusLetterApp());

    expect(find.text('Campus Letter'), findsOneWidget);
    expect(find.text('Language Nest Letter'), findsOneWidget);
    expect(find.text('Normal Letter'), findsOneWidget);
    expect(find.text('Add event details'), findsOneWidget);

    await tester.tap(find.text('Language Nest Letter'));
    await tester.pumpAndSettle();

    expect(find.text('Language Nest Letter'), findsWidgets);
    expect(find.text('Event name'), findsOneWidget);
    expect(find.text('Event description'), findsOneWidget);
  });
}
