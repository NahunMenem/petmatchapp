import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('test harness renders a widget', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Text('PawMatch'),
        ),
      ),
    );

    expect(find.text('PawMatch'), findsOneWidget);
  });
}
