import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ngames/screens/home/home_screen.dart';

void main() {
  testWidgets('HomeScreen has a title and welcome message', (
    WidgetTester tester,
  ) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));

    // Verify that the title and welcome message are present.
    expect(find.text('NGames Home'), findsOneWidget);
    expect(find.text('Welcome to NGames!'), findsOneWidget);
  });
}
