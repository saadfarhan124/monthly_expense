// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:monthly_expense_app/main.dart';

void main() {
  testWidgets('Monthly Expense App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MonthlyExpenseApp());

    // Verify that our app title is displayed.
    expect(find.text('Monthly Expense Tracker'), findsOneWidget);
    expect(find.text('Welcome to Monthly Expense Tracker'), findsOneWidget);
    expect(find.text('Your personal finance companion'), findsOneWidget);

    // Verify that the floating action button is present.
    expect(find.byIcon(Icons.add), findsOneWidget);

    // Tap the floating action button and trigger a frame.
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();

    // Verify that the snackbar appears with the expected message.
    expect(find.text('Add expense feature coming soon!'), findsOneWidget);
  });
}
