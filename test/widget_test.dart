// Basic widget test for the Ymir app
//
// Tests the app's basic functionality and UI components

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ymir/main.dart';

void main() {
  testWidgets('Ymir app smoke test', (WidgetTester tester) async {
    // Build the app and trigger a frame
    await tester.pumpWidget(const MyApp());

    // Verify that the app starts successfully
    expect(find.byType(MaterialApp), findsOneWidget);
    
    // Wait for the app to finish loading
    await tester.pumpAndSettle();
  });
}
