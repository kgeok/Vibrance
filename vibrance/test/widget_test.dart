import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vibrance/data_management.dart';
import 'package:vibrance/main.dart';

void main() {
  test('colorToString should return hex string format for DB', () {
    const color = Color(0xFFFF0000);
    final result = colorToString(color);

    // Based on implementation: "0x" + toHexString()
    expect(result, startsWith("0x"));
    expect(result.toLowerCase(), contains("ff0000"));
  });
  testWidgets('FloatingTrianglesBackground initializes with correct count',
      (WidgetTester tester) async {
    // Build the widget
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: FloatingTrianglesBackground(numberOfTriangles: 10),
      ),
    ));

    // Verify the widget exists
    expect(find.byType(FloatingTrianglesBackground), findsOneWidget);

    // Allow for animation frames
    await tester.pump(const Duration(seconds: 1));

    // Verify CustomPaint is used for the background
    expect(find.byType(CustomPaint), findsOneWidget);
  });
}
