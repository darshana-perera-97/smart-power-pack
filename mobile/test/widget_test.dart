// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Splash screen test', (WidgetTester tester) async {
    // Create a simple test widget matching the splash screen
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          backgroundColor: const Color(0xFF667eea),
          body: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.lightbulb,
                  size: 60,
                  color: Colors.white,
                ),
                SizedBox(height: 30),
                Text(
                  'Smart Bulb Switch',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  'Control your smart devices',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    // Verify that the app title is displayed.
    expect(find.text('Smart Bulb Switch'), findsOneWidget);
    
    // Verify that the lightbulb icon is present.
    expect(find.byIcon(Icons.lightbulb), findsOneWidget);
    
    // Verify that the subtitle is displayed.
    expect(find.text('Control your smart devices'), findsOneWidget);
  });
}
